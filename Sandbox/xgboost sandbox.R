# xgboost sandbox

# PURPOSE:  The purpose of this document is to experiment with
# training models using xgboost without caret.

# I'd like to also apply SHAP values.

# I want to avoid tidymodels, mostly because I find it annoying

#############
## LIBRARY ## 
#############

library(xgboost)
library(tidymodels)
library(rsample)

##########
## LOAD ## 
##########

ftfData <- readRDS(here::here("Data","Freshman_data.rds"))


# I really need to convert my function to a package
source(here::here("Functions", "Draw Confusion Matrix vC6.R"))

###############
## PARTITION ##
###############


predictorColumns <- c("AGE", 
                      "SEX", 
                      "FIRST_GEN_STATUS_CD", 
                      "FIRST_GEN_STATUS",
                      "ETHNICITY",
                      "ZIPCDPERM",
                      "RESSTAT",
                      "FA_PELL",
                      "APCREDIT",
                      "HSGPA",
                      "ACTCOMP",                
                      "ACTENGL",                
                      "ACTMATH",                
                      "ACTSCI" 
                      )


set.seed(42)
# Take ten percent of the data as a stratified sample
split_sample <- initial_split(ftfData[,c(predictorColumns, "HSPRIVATE")], prop = 0.1, strata = "HSPRIVATE")
sampleData <- training(split_sample)

# Partition the data for training

train_split <- initial_split(sampleData, prop = 0.8, strata = "HSPRIVATE")

trainData <- training(train_split)
testData <- testing(train_split)

##########
## PREP ##
##########

# Convert to factors

tData <- lapply(colnames(trainData), function(x) { # Convert character columsn to factors
  if( is.character(trainData[,x] )) { 
    return_vector <- factor(trainData[,x])
  } else { return_vector <- trainData[,x] }
  
  return(return_vector)
  
  }) |>
  (\(x){do.call(cbind,x)})() |> # Convert back to a dataframe
  (\(x){xgb.DMatrix(data = x, 
                    label="HSPRIVATE") })() # Convert to an xgb matrix
  


char_cols <- sapply(trainData, is.character)
trainData[char_cols] <- lapply(trainData[char_cols], factor)

tData <- trainData |>
  (\(x){xgb.DMatrix(data = x[, setdiff(colnames(x), "HSPRIVATE")], 
                  label= as.numeric(x$HSPRIVATE) - 1) })() # Convert to an xgb matrix



cv_result <- xgb.cv(
  data = tData,
  params = xgb.params(
    objective = "binary:logistic",
    eval_metric      = "auc"
  ),
  nfold = 5,
  nrounds = 200,
  early_stopping_rounds = 20
  )


final_model <- xgb.train(
  data    = tData,
  params  = xgb.params(
    objective = "binary:logistic",
    eval_metric      = "auc"
  ),
  nrounds = which.max(cv_result$evaluation_log$test_auc_mean) #cv_result$best_iteration
)

# Convert test data to an xgb.DMatrix

char_cols <- sapply(testData, is.character)
testData[char_cols] <- lapply(testData[char_cols], factor)

tData_test <- testData |>
  (\(x){xgb.DMatrix(data = x[, setdiff(colnames(x), "HSPRIVATE")], 
                    label= as.numeric(x$HSPRIVATE) - 1) })() # Convert to an xgb matrix

# Prediction

pred_probs <- predict(final_model, tData_test)

# Pick a threshold

library(pROC)
roc_obj <- roc(testData$HSPRIVATE, pred_probs)
plot(roc_obj)
auc(roc_obj)

best_thresh <- coords(roc_obj, "best", best.method = "youden")
best_thresh <- coords(roc_obj, "best", best.method = "closest.topleft")

points(
  x = 1 - 0.5509326,   # 1 - specificity (closest.topleft)
  y = 0.7410072,        # sensitivity
  pch = 19, col = "red", cex = 2
)

pred_class <- as.integer(pred_probs > 0.05)

cm <- caret::confusionMatrix(
  factor(pred_class), 
  factor(as.numeric(testData$HSPRIVATE) - 1),
  positive = "1"
)

drawCM(cm)

# let's look at tidymodels

library(yardstick)
ys_confMat <- conf_mat(data.frame(truth = factor(as.numeric(testData$HSPRIVATE) - 1), 
                    estimate = factor(pred_class)), 
         truth, estimate)

autoplot(ys_confMat, type = "heatmap") # wow that's awful
autoplot(ys_confMat, type = "mosaic") # not much better


summary(ys_confMat) # you are on your own to display this

xgb.importance(model = final_model) |> xgb.plot.importance(measure="Gain")
xgb.importance(model = final_model) |> xgb.plot.importance(measure="Cover")
xgb.importance(model = final_model) |> xgb.plot.importance(measure="Frequency")


# Test Save
xgb.save(final_model, here::here("Data", "test_model.ubj"))

# Load
loaded_model <- xgb.load(here::here("Data", "test_model.ubj"))

xgb.importance(model = loaded_model) |> xgb.plot.importance(measure="Gain")

# Looks like it loaded o.k.

################# 
## SHAP VALUES ##
################# 

# I'm not able to interpret this
xgb.plot.shap(
  data = trainData[,predictorColumns],
  model = final_model
  )

library(shapviz)
shap_obj <- shapviz(
  object = final_model,
  X_pred  = tData,
  X       = trainData[, predictorColumns]
)

sv_importance(shap_obj, kind = "beeswarm")
sv_importance(shap_obj, kind = "bar")
sv_dependence(shap_obj, v = "ACTMATH")
sv_dependence2D(shap_obj, y = "ACTMATH", x="HSGPA" )
sv_waterfall(shap_obj, row_id = 1)
sv_force(shap_obj, row_id = 2)

############################ 
## TUNING HYPERPARAMETERS ## 
############################ 

install.packages("rBayesianOptimization")
library(rBayesianOptimization)

scoring_function <- function(max_depth, eta, min_child_weight, subsample) {
  params <- xgb.params(
    objective        = "binary:logistic",
    eval_metric      = "aucpr",
    scale_pos_weight = 9,
    max_depth        = as.integer(max_depth),
    eta              = eta,
    min_child_weight = as.integer(min_child_weight),
    subsample        = subsample
  )
  cv <- xgb.cv(
    data                  = tData,
    params                = params,
    nfold                 = 5,
    nrounds               = 200,
    early_stopping_rounds = 20,
    verbose               = 0
  )
  list(Score = max(cv$evaluation_log$test_aucpr_mean),
       nrounds = cv$best_iteration)
}

bounds <- list(
  max_depth        = c(3L, 8L),
  eta              = c(0.01, 0.3),
  min_child_weight = c(1L, 20L),
  subsample        = c(0.5, 1.0)
)

bayes_result_pr <- BayesianOptimization(
  FUN        = scoring_function,
  bounds     = bounds,
  init_points = 10,
  n_iter      = 30,
  verbose    = TRUE
)

# now let's see what we got

# Best params from Bayesian optimization
final_params <- xgb.params(
  objective        = "binary:logistic",
  eval_metric      = "auc",
  scale_pos_weight = 9,
  max_depth        = 6L,
  eta              = 0.03923825,
  min_child_weight = 13L,
  subsample        = 0.92913918
)

# But first -- get the best nrounds for these params via CV
cv_final <- xgb.cv(
  data                  = tData,  # training DMatrix only
  params                = final_params,
  nfold                 = 5,
  nrounds               = 500,
  early_stopping_rounds = 20,
  verbose               = 1
)

# Then train final model on all training data
final_model <- xgb.train(
  data    = tData,
  params  = final_params,
  nrounds = which.max(cv_final_pr$evaluation_log$test_aucpr_mean) # cv_final$best_iteration
)



# Best params from Bayesian optimization
final_params_pr <- xgb.params(
  objective        = "binary:logistic",
  eval_metric      = "aucpr",
  scale_pos_weight = 9,
  max_depth        = 4L,
  eta              = 0.01695595,
  min_child_weight = 11L,
  subsample        = 0.84698952
)

# But first -- get the best nrounds for these params via CV
cv_final_pr <- xgb.cv(
  data                  = tData,  # training DMatrix only
  params                = final_params_pr,
  nfold                 = 5,
  nrounds               = 500,
  early_stopping_rounds = 20,
  verbose               = 1
)

# Then train final model on all training data
final_model_pr <- xgb.train(
  data    = tData,
  params  = final_params_pr,
  nrounds = which.max(cv_final_pr$evaluation_log$test_aucpr_mean) #cv_final_pr$best_iteration
)

# now let's compare them

pred_probs <- predict(final_model, tData_test)

pred_probs_by <- predict(final_model, tData_test)

pred_probs_pr <- predict(final_model_pr, tData_test)

# Direct comparison

plot(pred_probs_by, pred_probs_pr,
     xlab = "AUC model",
     ylab = "AUCPR model",
     main = "Predicted probabilities: AUC vs AUCPR",
     pch  = 16, cex = 0.5, alpha = 0.3)
abline(0, 1, col = "red")  # 45-degree line = perfect agreement



# pick threshold

roc_obj <- roc(testData$HSPRIVATE, pred_probs)
plot(roc_obj)
auc(roc_obj)

best_thresh <- coords(roc_obj, "best", best.method = "youden")
best_thresh <- coords(roc_obj, "best", best.method = "closest.topleft")



# direct comparison

pred_class <- as.integer(pred_probs > 0.05)
pred_class_by <- as.integer(pred_probs_by > 0.05)
pred_class_pr <- as.integer(pred_probs_pr > 0.05)

cm <- caret::confusionMatrix(
  factor(pred_class_by), 
  factor(pred_class_pr),
  # factor(as.numeric(testData$HSPRIVATE) - 1),
  positive = "1"
)

drawCM(cm)
