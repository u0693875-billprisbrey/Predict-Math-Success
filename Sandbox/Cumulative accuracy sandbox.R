# Cumulative accuracy sandbox

# PURPOSE: I'd like to explore calculating precision and recall on the basis of everything
# less than or equal to my prediction (vH2).  If I am predicting a low grade, then I consider everyone
# who got even lower as correct/accurate

# Or I can just do this -- 

createCM(aligned[["GRADEGPA"]], cuts = c(0,1.7,4)) |> drawCM()

# I guess I ... ok, here

cumAcc <- lapply(seq(from = 0.1, to = 3.9, by = 0.1), function(x){
  
  createCM(aligned[["GRADEGPA"]], cuts = c(0,x,4))
  
})

sapply(cumAcc, function(x) {x[["overall"]][["Kappa"]]}) |> plot()

# I am not understanding why I am getting different results in my list and in a direct function call

> sapply(cumAcc, function(x) {x[["overall"]][["Kappa"]]}) |> (\(x){which(x==max(x))})()
[1] 23
> cumAcc[[23]]
Confusion Matrix and Statistics

Reference
Prediction [0,2.3] (2.3,4]
[0,2.3]     277     272
(2.3,4]     176    1278

Accuracy : 0.7763          
95% CI : (0.7574, 0.7944)
No Information Rate : 0.7738          
P-Value [Acc > NIR] : 0.4068          

Kappa : 0.4056          

Mcnemar's Test P-Value : 7.178e-06       
                                          
            Sensitivity : 0.6115          
            Specificity : 0.8245          
         Pos Pred Value : 0.5046          
         Neg Pred Value : 0.8790          
              Precision : 0.5046          
                 Recall : 0.6115          
                     F1 : 0.5529          
             Prevalence : 0.2262          
         Detection Rate : 0.1383          
   Detection Prevalence : 0.2741          
      Balanced Accuracy : 0.7180          
                                          
       'Positive' Class : [0,2.3]         
                                          
> createCM(aligned[["GRADEGPA"]], cuts = c(0,2.3,4))

Confusion Matrix and Statistics

          Reference
Prediction [0,2.3] (2.3,4]
   [0,2.3]     236     313
   (2.3,4]     146    1308
                                          
               Accuracy : 0.7708          
                 95% CI : (0.7518, 0.7891)
    No Information Rate : 0.8093          
    P-Value [Acc > NIR] : 1               
                                          
                  Kappa : 0.3639          
                                          
 Mcnemar's Test P-Value : 9.319e-15       

Sensitivity : 0.6178          
Specificity : 0.8069          
Pos Pred Value : 0.4299          
Neg Pred Value : 0.8996          
Precision : 0.4299          
Recall : 0.6178          
F1 : 0.5070          
Prevalence : 0.1907          
Detection Rate : 0.1178          
Detection Prevalence : 0.2741          
Balanced Accuracy : 0.7124          

'Positive' Class : [0,2.3]    

cumAcc2 <- lapply(seq(from = 0.1, to = 3.9, by = 0.1), function(x){
  
  createCM(aligned[["GRADEGPA"]], cuts = c(0,x,4))
  
})

cumAcc3 <- lapply(round(seq(from = 0.1, to = 3.9, by = 0.1),1), function(x){
  
  createCM(aligned[["GRADEGPA"]], cuts = c(0,x,4))
  
})

sapply(cumAcc3, function(x) {x[["overall"]][["Kappa"]]}) |> (\(x){which(x==max(x))})() #24 


sapply(cumAcc3, function(x) {x[["overall"]][["Kappa"]]}) |> plot()
sapply(cumAcc3, function(x) {x[["byClass"]][["Precision"]]}) |> plot()
sapply(cumAcc3, function(x) {x[["byClass"]][["Recall"]]}) |> plot()

# It's an interesting graphic.
# I should add it to my report.

plot(x = 0.5,
  ylim = c(0,1),
     xlim = c(0,length(cumAcc3)),
  xaxt = "n",
  las = 2,
     ylab = "",
     xlab = "",
  type = "n")

sapply(cumAcc3, function(x) {x[["overall"]][["Kappa"]]}) |> lines(col = "firebrick", lwd = 2)
sapply(cumAcc3, function(x) {x[["byClass"]][["Precision"]]}) |> lines(col = "dodgerblue", lwd = 2)
sapply(cumAcc3, function(x) {x[["byClass"]][["Recall"]]}) |> lines(col = "gold", lwd = 2)
# sapply(cumAcc3, function(x) {x[["byClass"]][["F1"]]}) |> lines(col = "black", lwd = 2)

axis(side = 1, at = 1:(length(cumAcc3)+1), labels = round(seq(from = 0.1, to = 4.0, by = 0.1),1))

legend("topleft",
       col = c("firebrick","dodgerblue","gold"),
       legend = c("Kappa","Precision","Recall"),
       lwd =4)

mtext(side=3, font = 2, cex = 1.619, line = 1.619, text = "Confusion matrix metrics from binary discretization")
mtext(side=1, line = 3, "Upper GPA Bound")

points(x = sapply(cumAcc3, function(x) {x[["byClass"]][["Precision"]]}) |> (\(x){which(x == max(x, na.rm = TRUE))})(),
         y = sapply(cumAcc3, function(x) {x[["byClass"]][["Precision"]]}) |> max(na.rm=TRUE),
         col = "dodgerblue",
       pch = 16,
       cex = 1.1
)

text(x = sapply(cumAcc3, function(x) {x[["byClass"]][["Precision"]]}) |> (\(x){which(x == max(x, na.rm = TRUE))})(),
     y = sapply(cumAcc3, function(x) {x[["byClass"]][["Precision"]]}) |> max(na.rm=TRUE),
  labels = "Admission 'mistake' candidates\n     (predictably failed)",
  pos = 4)


points(x = sapply(cumAcc3, function(x) {x[["overall"]][["Kappa"]]}) |> (\(x){which(x == max(x, na.rm = TRUE))})(),
       y = sapply(cumAcc3, function(x) {x[["overall"]][["Kappa"]]}) |> max(na.rm=TRUE),
       col = "firebrick",
       pch = "|",
       cex = 1.319
)

text(x = sapply(cumAcc3, function(x) {x[["overall"]][["Kappa"]]}) |> (\(x){which(x == max(x, na.rm = TRUE))})(),
     y = sapply(cumAcc3, function(x) {x[["overall"]][["Kappa"]]}) |> max(na.rm=TRUE),
     labels = "Optimum",
     pos = 1)


