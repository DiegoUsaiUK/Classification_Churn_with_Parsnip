# Modelling with Tidymodels and Parsnip

## A Tidy Approach to a Classification Problem

22 June 2019

Recently I have completed the [__Business Analysis With R__](https://university.business-science.io/p/ds4b-101-r-business-analysis-r) online course focused on _applied data and business science with R_, which introduced me to a couple of new modelling concepts and approaches. One that especially captured my attention is `parsnip` and its attempt to implement a unified modelling and analysis interface (similar to __python's__ `scikit-learn`) to seamlessly access several modelling platforms in R. 

`parsnip` is the brainchild of RStudio's [__Max Khun__](https://twitter.com/topepos) (of `caret` fame) and [__Davis Vaughan__](https://twitter.com/dvaughan32) and forms part of `tidymodels`, a growing ensemble of tools to explore and iterate modelling tasks that shares a common philosophy (and a few libraries) with the `tidyverse`. 

Although there are a number of packages at different stages in their development, I have decided to take `tidymodels` "for a spin", so to speak, and create and execute a "tidy" modelling workflow to tackle a __classification__ problem. My aim is to show how easy it is to fit a simple __logistic regression__ in R's `glm` and quickly switch to a cross-validated __random forest__ using the `ranger` engine by changing only a few lines of code.

For this post in particular I'm focusing on four different libraries from the `tidymodels` suite: `rsample` for data sampling and cross-validation, `recipes` for data preprocessing, `parsnip` for model set up and estimation, and `yardstick` for model assessment.

### Links

You can find the final article on __my website__ - 
https://diegousai.io/2019/09/modelling-with-tidymodels-and-parsnip/

I've also published the article on __Towards Data Science__ - 
https://towardsdatascience.com/modelling-with-tidymodels-and-parsnip-bae2c01c131c
