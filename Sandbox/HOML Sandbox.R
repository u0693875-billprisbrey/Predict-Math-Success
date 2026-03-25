# HOML sandbox

# PURPOSE:  Duplicate the anlaysis from Hands On Machine Learning (Boehmke)

library(rsample)
library(xgboost)
library(gbm3)
library(recipes)
library(rBayesianOptimization)
library(vip)

# 2.1

# Ames housing data
ames <- AmesHousing::make_ames()
# ames.h2o <- as.h2o(ames)

# 2.7

set.seed(123)
split <- initial_split(ames, prop = 0.7, 
                       strata = "Sale_Price")
ames_train  <- training(split)
ames_test   <- testing(split)

# 12.3.2

startTime <- Sys.time()
set.seed(123)  # for reproducibility
ames_gbm1 <- gbm(
  formula = Sale_Price ~ .,
  data = ames_train,
  distribution = "gaussian",  # SSE loss function
  n.trees = 5000,
  shrinkage = 0.1,
  interaction.depth = 3,
  n.minobsinnode = 10,
  cv.folds = 10
)
endTime <- Sys.time()

# find index for number trees with minimum CV error
best <- which.min(ames_gbm1$cv.error)

# get MSE and compute RMSE
sqrt(ames_gbm1$cv.error[best])

gbm.perf(ames_gbm1, method = "cv")

# 12.5.2

xgb_prep <- recipe(Sale_Price ~ ., data = ames_train) |>
  step_integer(all_nominal()) |>
  prep(training = ames_train, retain = TRUE) |>
  bake(new_data=NULL)

X <- xgb_prep[setdiff(names(xgb_prep), "Sale_Price")]
Y <- xgb_prep$Sale_Price

dTrain <- xgb.DMatrix(data = X, label = Y)

startTime <- Sys.time()
set.seed(123)
system.time({
ames_xgb <- xgb.cv(
  data = dTrain,
  nrounds = 6000,
  early_stopping_rounds = 50, 
  nfold = 10,
  params = list(
    objective = "reg:squarederror",
    eta = 0.1,
    max_depth = 3,
    min_child_weight = 3,
    subsample = 0.8,
    colsample_bytree = 1.0),
  verbose = 0
)  
})
endTime <- Sys.time()

# minimum test CV RMSE
min(ames_xgb$evaluation_log$test_rmse_mean)
## [1] 20488 # textbook
# [1] 22404 # what I got --- different seed maybe?

# Bayesian search

startTime <- Sys.time()

# Define the objective function
xgb_cv_bayes <- function(eta, max_depth, min_child_weight, 
                         subsample, colsample_bytree,
                         gamma, lambda, alpha) {
  set.seed(123)
  m <- xgb.cv(
    data = dTrain,
    nrounds = 4000,
    early_stopping_rounds = 50,
    nfold = 10,
    verbose = 0,
    params = list(
      objective = "reg:squarederror",
      eta = eta,
      max_depth = as.integer(max_depth),
      min_child_weight = as.integer(min_child_weight),
      subsample = subsample,
      colsample_bytree = colsample_bytree,
      gamma = gamma,
      lambda = lambda,
      alpha = alpha
    )
  )
  
  list(
    Score = -min(m$evaluation_log$test_rmse_mean),  # negative because BayesianOptimization maximizes
    Pred = m$best_iteration
  )
}

# Define search bounds
bounds <- list(
  eta               = c(0.01, 0.3),
  max_depth         = c(2L, 8L),
  min_child_weight  = c(1L, 10L),
  subsample         = c(0.5, 1.0),
  colsample_bytree  = c(0.5, 1.0),
  gamma             = c(0, 1000),
  lambda            = c(0, 10000),
  alpha             = c(0, 10000)
)

# Run Bayesian optimization
set.seed(123)
system.time({
bayes_result <- BayesianOptimization(
  FUN = xgb_cv_bayes,
  bounds = bounds,
  init_points = 10,    # random exploration before Bayesian kicks in
  n_iter = 30,         # Bayesian iterations after init
  acq = "ucb",         # acquisition function
  kappa = 2.576,       # exploration/exploitation tradeoff
  verbose = TRUE
)
})
endTime <- Sys.time()

# > endTime -startTime
# Time difference of 1.621206 hours

# Extract best params
> bayes_result$Best_Par
eta        max_depth 
8.910011e-02     4.000000e+00 
min_child_weight        subsample 
1.000000e+00     9.066459e-01 
colsample_bytree            gamma 
7.523031e-01     4.149265e+01 
lambda            alpha 
2.220446e-16     8.590669e+02 
> bayes_result$Best_Value  # remember this is negated RMSE
[1] -21862.39

# Why is that negated RMSE?

# but that's pretty incredibly god !

# And honestly this seems pretty straightforward and easy.

# Now I train the whole train sample on this -- right?
# And apply to the test ?

# Determine the number of rounds:

# Recall 
# dTrain <- xgb.DMatrix(data = X, label = Y)

best_params <- list(
  eta              = bayes_result$Best_Par["eta"],
  max_depth        = as.integer(bayes_result$Best_Par["max_depth"]),
  min_child_weight = as.integer(bayes_result$Best_Par["min_child_weight"]),
  subsample        = bayes_result$Best_Par["subsample"],
  colsample_bytree = bayes_result$Best_Par["colsample_bytree"],
  gamma            = bayes_result$Best_Par["gamma"],
  lambda           = bayes_result$Best_Par["lambda"],
  alpha            = bayes_result$Best_Par["alpha"],
  objective        = "reg:squarederror" 
)

cv_final <- xgb.cv(
  params = best_params,
  data = dTrain,
  nfold = 5,
  nrounds = 6000,
  early_stopping_rounds = 50,
  # objective = "reg:squarederror", # "reg:linear",
  verbose = 0
)




# params <- list(
#  eta = 8.910011e-02,
#  max_depth = 4,
#  min_child_weight = 1,
#  subsample = 9.066459e-01,
#  colsample_bytree = 7.523031e-01
#  gamma = 4.149265e+01,
#  lambda = 2.220446e-16,
#  alpha = 8.590669e+02
# )

xgb.fit.final <- xgb.train(
  params = best_params,
  data = dTrain,
  nrounds = 474,
  verbose = 0
)

vip::vip(xgb.fit.final) 


# o.k., nice

# let's see if I can do the ShAP values
# Copying from HOML

# Try to re-scale features (low to high)
feature_values <- X %>%
  as.data.frame() %>%
  mutate_all(scale) %>%
  gather(feature, feature_value) %>% 
  pull(feature_value)

# Compute SHAP values, wrangle a bit, compute SHAP-based importance, etc.
shap_df <- xgb.fit.final %>%
  predict(newdata = X, predcontrib = TRUE) %>%
  as.data.frame() %>%
  select(-last_col()) %>%
  gather(feature, shap_value) %>%
  mutate(feature_value = feature_values) %>%
  group_by(feature) %>%
  mutate(shap_importance = mean(abs(shap_value)))

# SHAP contribution plot
p1 <- ggplot(shap_df, aes(x = shap_value, y = reorder(feature, shap_importance))) +
  ggbeeswarm::geom_quasirandom(groupOnX = FALSE, varwidth = TRUE, size = 0.4, alpha = 0.25) +
  xlab("SHAP value") +
  ylab(NULL)

# SHAP importance plot
p2 <- shap_df %>% 
  select(feature, shap_importance) %>%
  filter(row_number() == 1) %>%
  ggplot(aes(x = reorder(feature, shap_importance), y = shap_importance)) +
  geom_col() +
  coord_flip() +
  xlab(NULL) +
  ylab("mean(|SHAP value|)")

# Combine plots
gridExtra::grid.arrange(p1, p2, nrow = 1)

shap_df %>% 
  filter(feature %in% c("Overall_Qual", "Gr_Liv_Area")) %>%
  ggplot(aes(x = feature_value, y = shap_value)) +
  geom_point(aes(color = shap_value)) +
  scale_colour_viridis_c(name = "Feature value\n(standardized)", option = "C") +
  facet_wrap(~ feature, scales = "free") +
  scale_y_continuous('Shapley value', labels = scales::comma) +
  xlab('Normalized feature value')


# Let's look at interactions (copying and pasting from Claude)

# First get the raw feature values (unscaled) for coloring
feature_matrix <- as.data.frame(X)

# Overall_Qual SHAP colored by Gr_Liv_Area
shap_df %>%
  filter(feature == "Overall_Qual") %>%
  mutate(color_var = feature_matrix$Gr_Liv_Area) %>%
  ggplot(aes(x = feature_value, y = shap_value, color = color_var)) +
  geom_point(alpha = 0.5) +
  scale_colour_viridis_c(name = "Gr_Liv_Area") +
  scale_y_continuous('Shapley value', labels = scales::comma) +
  xlab('Overall_Qual (standardized)') +
  ggtitle('Overall_Qual SHAP values, colored by Gr_Liv_Area')

# Overall_Qual SHAP colored by Total_Bsmt_SF
shap_df %>%
  filter(feature == "Overall_Qual") %>%
  mutate(color_var = feature_matrix$Total_Bsmt_SF) %>%
  ggplot(aes(x = feature_value, y = shap_value, color = color_var)) +
  geom_point(alpha = 0.5) +
  scale_colour_viridis_c(name = "Total_Bsmt_SF") +
  scale_y_continuous('Shapley value', labels = scales::comma) +
  xlab('Overall_Qual (standardized)') +
  ggtitle('Overall_Qual SHAP values, colored by Total_Bsmt_SF')

# Another one from Claude

# Compute SHAP interaction matrix
shap_interact <- predict(xgb.fit.final, newdata = X, predinteraction = TRUE)
# Result is a 3D array: [observations x features x features]
# Diagonal = main effects, off-diagonal = interaction effects
dim(shap_interact)

# Average absolute interaction value across all observations
n_features <- dim(shap_interact)[2] - 1  # exclude intercept
feature_names <- dimnames(shap_interact)[[2]][1:n_features]

# Mean absolute interaction matrix
interact_matrix <- apply(shap_interact[, 1:n_features, 1:n_features], 
                         c(2,3), 
                         function(x) mean(abs(x)))

# Convert to long format and get top pairs
interact_df <- as.data.frame(interact_matrix) %>%
  rownames_to_column("feature1") %>%
  gather(feature2, interaction_strength, -feature1) %>%
  filter(feature1 < feature2) %>%  # remove duplicates and diagonal
  arrange(desc(interaction_strength))

head(interact_df, 10)  # top 10 interacting pairs


# Example: top interacting pair
top_pair <- interact_df[1, ]
main_feature <- top_pair$feature1
color_feature <- top_pair$feature2

# Pull the actual pairwise interaction values for this pair
interaction_vals <- shap_interact[, main_feature, color_feature]

data.frame(
  x     = feature_matrix[[main_feature]],
  y     = interaction_vals,
  color = feature_matrix[[color_feature]]
) %>%
  ggplot(aes(x = x, y = y, color = color)) +
  geom_point(alpha = 0.5) +
  scale_color_viridis_c(name = color_feature) +
  xlab(main_feature) +
  ylab("SHAP interaction value") +
  ggtitle(paste("Interaction:", main_feature, "×", color_feature))


data.frame(
  x     = feature_matrix[["Overall_Qual"]],
  y     = shap_interact[, "Overall_Qual", "Gr_Liv_Area"],
  color = feature_matrix[["Gr_Liv_Area"]]
) %>%
  ggplot(aes(x = x, y = y, color = color)) +
  geom_point(alpha = 0.5) +
  scale_color_viridis_c(name = "Gr_Liv_Area") +
  xlab("Overall_Qual") +
  ylab("SHAP interaction value") +
  ggtitle("Interaction: Overall_Qual × Gr_Liv_Area")



# Bin Gr_Liv_Area into low/medium/high thirds
data.frame(
  Overall_Qual = factor(feature_matrix[["Overall_Qual"]]),
  Gr_Liv_Area  = cut(feature_matrix[["Gr_Liv_Area"]], 
                     breaks = 3, 
                     labels = c("Low", "Medium", "High")),
  interaction  = shap_interact[, "Overall_Qual", "Gr_Liv_Area"]
) %>%
  ggplot(aes(x = Overall_Qual, y = interaction, fill = Gr_Liv_Area)) +
  geom_boxplot() +
  scale_fill_viridis_d(name = "Gr_Liv_Area") +
  xlab("Overall Quality") +
  ylab("SHAP interaction value") +
  ggtitle("Interaction: Overall_Qual × Gr_Liv_Area")