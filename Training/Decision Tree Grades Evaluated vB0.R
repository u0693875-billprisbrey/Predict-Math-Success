# Decision Tree Grades vB0 Evaluated

# PURPOSE:  Load in the models trained on 2% of the data;
# look at accuracy metrics; confirm before running a larger set

##########
## LOAD ##
##########

target_classes <- c("wdraw_binary", "grade_binary", "grade_trinary", "grade_quad", "GRADEGPA")

# Build file paths
model_files <- here::here("Models", paste0("Decision Tree vB0 ", target_classes, " model.rds"))

# Read each model into a named list
model_list <- setNames(
  lapply(model_files, readRDS),
  target_classes
)

# Build file paths
data_files <- here::here("Models", paste0("Decision Tree vB0 ", target_classes, " Data.rds"))

# Read each model into a named list
data_list <- setNames(
  lapply(data_files, readRDS),
  target_classes
)

#########################
## VARIABLE IMPORTANCE ##
#########################

par(mar = c(0,3,5,0))
lapply(names(model_list), function(x){plot(varImp(model_list[[x]]), main = x)})

# This is probably why they want math earlier
# ...but is that a PREDICTOR or a CAUSE ?

################
## PREDICTION ##
################

library(caret)

predict(model_list[[1]], newdata = data_list[[1]][["testing"]][,"wdraw_binary"]) 

predict(model_list[[ target_classes[[3]] ]], 
        newdata =  data_list[[  target_classes[[3]]   ]][["testing"]]       
          ) |> table()


thePredictions <- lapply(target_classes, function(x) {
  
  predict(model_list[[x]],
          newdata = data_list[[x]][["testing"]])
  
} )
names(thePredictions) <- target_classes


lapply(thePredictions[-5], table)

hist(thePredictions[[5]])



##############
## ACCURACY ##
##############



theCMs <- lapply(target_classes[-5], function(x) {
  
  confusionMatrix(data = thePredictions[[x]],
                  reference = factor(data_list[[x]][["testing"]][,x]) ,
                  mode = "everything")
  
  
})
names(theCMs) <- target_classes[-5]

sapply(theCMs, function(x){ 
  
  x[["overall"]]["Kappa"]
  
  })


# Now for the regression

regression_diagnostics <- function(pred, reference, plot_title = "Predicted vs Actual") {
  if (length(pred) != length(reference)) {
    stop("`pred` and `reference` must be the same length.")
  }
  
  # Compute metrics
  rmse <- sqrt(mean((pred - reference)^2))
  mae  <- mean(abs(pred - reference))
  r2   <- 1 - sum((pred - reference)^2) / sum((reference - mean(reference))^2)
  
  # Print metrics
  cat("Regression diagnostics:\n")
  cat(sprintf("RMSE: %.4f\n", rmse))
  cat(sprintf("MAE:  %.4f\n", mae))
  cat(sprintf("R-squared: %.4f\n", r2))
  
  # Scatter plot
  plot(reference, pred,
       xlab = "Actual",
       ylab = "Predicted",
       main = plot_title,
       pch = 19, col = "steelblue")
  abline(a = 0, b = 1, col = "red", lwd = 2)  # 45-degree reference line
  grid()
  
  # Return metrics invisibly as a list
  invisible(list(RMSE = rmse, MAE = mae, R2 = r2))
}

regression_diagnostics(pred = thePredictions[["GRADEGPA"]] ,
                       reference = data_list[["GRADEGPA"]][["testing"]][,"GRADEGPA"])


pred <- thePredictions[["GRADEGPA"]]
reference <- data_list[["GRADEGPA"]][["testing"]][,"GRADEGPA"]
# pred = your predicted values
# reference = your true grades
errors <- pred - reference

# Scatter plot of errors by true grade
plot(reference, errors,
     xlab = "True Grade",
     ylab = "Prediction Error (Predicted - True)",
     main = "Prediction Errors by True Grade",
     pch = 19, col = "steelblue")
abline(h = 0, col = "red", lwd = 2)  # reference line: perfect prediction
grid()

# Optional: add a boxplot per true grade for clarity
boxplot(errors ~ reference,
        xlab = "True Grade",
        ylab = "Prediction Error",
        main = "Error Distribution by True Grade",
        col = "lightblue")
abline(h = 0, col = "red", lwd = 2)


How to interpret

Scatter plot:
  
  Points above the red line → model overpredicts.

Points below the red line → model underpredicts.

Wide vertical spread → high error for that true grade.

Boxplot by grade:
  
  Median line far from 0 → systematic bias.

Tall boxes / long whiskers → large variance in errors.

Compare grades 0, 1, 2, 3, 4 to see which grades the model struggles with most.

