#I load the packages 

library(tidymodels)
library(skimr)
library(tibble)

# Data: Telco Customer Churn from IBM Watson Analytics
# (https://www.ibm.com/communities/analytics/watson-analytics-blog/
# predictive-insights-in-the-telco-customer-churn-data-set/)


telco <- readr::read_csv("WA_Fn-UseC_-Telco-Customer-Churn.csv")

# take a look at the data
telco %>% 
   skimr::skim()

# remove NAs and unselect customerID
telco <- telco %>%
   select(-customerID) %>%
   drop_na()


## Modelling with `tidymodels`

### Train and test split with `rsample` 

set.seed(seed = 1972) # to insure reproducible random processes

train_test_split <-
   rsample::initial_split(
      data = telco, # data to split
      prop = 0.80   # proportion of split
   ) 


#I save them as `train_tbl` and `test_tbl`.

train_tbl <- train_test_split %>% training() # saving train obj
test_tbl <- train_test_split %>% testing() # saving test obj


### A simple recipe

recipe_simple <- function(dataset) {
   recipe(Churn ~ ., data = dataset) %>%
      step_string2factor(all_nominal(), -all_outcomes()) %>%
      prep(data = dataset)
}

# Prepping the recipe
recipe_prepped <- recipe_simple(dataset = train_tbl)

# Baking the recipe
train_baked <- bake(recipe_prepped, new_data = train_tbl)
test_baked  <- bake(recipe_prepped, new_data = test_tbl)

### Fit the model with parsnip 


logistic_glm <-
  logistic_reg(mode = "classification") %>%
  set_engine("glm") %>%
  fit(Churn ~ ., data = train_baked)

### Performance assessment with yardstick

# calculate  predictions
predictions_glm <- logistic_glm %>%
   predict(new_data = test_baked) %>%
   bind_cols(test_baked %>% select(Churn))


# Confucion matrix plot
predictions_glm %>%
  conf_mat(Churn, .pred_class) %>%
  pluck(1) %>%
  as_tibble() %>%
  ggplot(aes(Prediction, Truth, alpha = n)) +
  geom_tile(show.legend = FALSE) +
  geom_text(aes(label = n), colour = "white", alpha = 1, size = 8)


# Accuracy
predictions_glm %>%
   metrics(Churn, .pred_class) %>%
   select(-.estimator) %>%
   filter(.metric == "accuracy") %>%
   kable()


# Precision & Recall
tibble(
   "precision" = 
      precision(predictions_glm, Churn, .pred_class) %>%
      select(.estimate),
   "recall" = 
      recall(predictions_glm, Churn, .pred_class) %>%
      select(.estimate)
) %>%
   unnest() %>%
   kable()


# F1 Score
predictions_glm %>%
   f_meas(Churn, .pred_class) %>%
   select(-.estimator) %>%
   kable()


## A Random Forest with Cross-validation
cross_val_tbl <- 
   vfold_cv(train_tbl, v = 10)

# check data split
cross_val_tbl$splits %>%
  pluck(1)

### Update the recipe

recipe_rf <- function(dataset) {
  recipe(Churn ~ ., data = dataset) %>%
    step_string2factor(all_nominal(), -all_outcomes()) %>%
    step_dummy(all_nominal(), -all_outcomes()) %>%
    step_center(all_numeric()) %>%
    step_scale(all_numeric()) %>%
    prep(data = dataset)
}


### Estimate the model

rf_fun <- function(split, id, try, tree) {
   
  analysis_set <- split %>% analysis()
  analysis_prepped <- analysis_set %>% recipe_rf()
  analysis_baked <- analysis_prepped %>% bake(new_data = analysis_set)

  model_rf <-
    rand_forest(
      mode = "classification",
      mtry = try,
      trees = tree
    ) %>%
    set_engine("ranger",
      importance = "impurity"
    ) %>%
    fit(Churn ~ ., data = analysis_baked)

  assessment_set <- split %>% assessment()
  assessment_prepped <- assessment_set %>% recipe_rf()
  assessment_baked <- assessment_prepped %>% bake(new_data = assessment_set)

  tibble(
    "id" = id,
    "truth" = assessment_baked$Churn,
    "prediction" = model_rf %>%
      predict(new_data = assessment_baked) %>%
      unlist()
  )
  
}

### Performance assessment

pred_rf <- map2_df(
  .x = cross_val_tbl$splits,
  .y = cross_val_tbl$id,
  ~ rf_fun(split = .x, id = .y, try = 3, tree = 200)
)

# Check performance metrics

 pred_rf %>%
    conf_mat(truth, prediction) %>%
    summary() %>%
    select(-.estimator) %>%
    filter(.metric %in%
              c("accuracy", "precision", "recall", "f_meas")) %>%
    kable()
 
