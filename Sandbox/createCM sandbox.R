# createCM sandbox

# PURPOSE:  This accepts the output of alignPrediction, and whatever user-specified cut,
# and returns a confusion matrix.

createCM <- function(data, cuts=NA, cap=TRUE){
  
  if(any(is.na(cuts))){
    cuts <- 0:4
  }
  
  
  # Possibly cap maximum prediction
  if(cap){
    data$pred <- pmin(pmax(data$pred, 0), 4)
  }
  
  # Expand to include the maximum prediction
  if(max(data$pred, na.rm = TRUE) > max(cuts)){
    
    cuts <- c(cuts,max(data$pred, na.rm = TRUE))
    
  }
  
  data$pred_cut <- cut(data$pred, cuts, include.lowest = TRUE)
  data$ref_cut <- cut(data$GRADEGPA, cuts, include.lowest = TRUE)
  
  cm <- confusionMatrix(data$pred_cut, data$ref_cut, mode = "everything")
  
  return(cm)
  
}



