# Playing with confusion matrices

source(here::here("Functions", "Draw Confusion Matrix vC5.R"))

# Prediction
set.seed(42)
reference <- sample(0:1, 1000, replace = TRUE, prob = c(0.2, 0.8)) |> factor()
prediction <- sample(0:1, 1000, replace = TRUE, prob = c(0.2, 0.8)) |> factor()

cm1 <- confusionMatrix(data = prediction, reference = reference, positive = "1", mode = "everything")
cm2 <- confusionMatrix(data = prediction, reference = reference, positive = "0", mode = "everything")  

drawCM(cm1, title = "Positive is 1")
drawCM(cm2, title = "Positive is 0")

# We either want to specify that "Positive is 0"
# or we want to focus on the metrics, "Negative Predictive Value"
# and "Specificity"

