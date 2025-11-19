alignPrediction <- function(prediction_list, reference_list) {
  
  # This accepts the list of predictions and the list of references,
  # and returns the testing data with the prediction as a column
  
  # Extract list names
  
  pred_names <- names(prediction_list)
  target_names <- names(reference_list)
  
  # Confirm match or exit function
  if(!identical(pred_names, target_names)){
    
    stop("Prediction and reference lists have different names")
    
  }
  
  align_list <- lapply(pred_names, function(align_target) { 
    
    # Identify mis-match in courses between training and testing sets
    missing <- setdiff(reference_list[[align_target]][["testing"]][["course"]],reference_list[[align_target]][["training"]][["course"]])
    missingFilter <- !reference_list[[align_target]][["testing"]][["course"]] %in% missing
    
    # Add the prediction to the data set
    reference_list[[align_target]][["testing"]]$pred[missingFilter] <- prediction_list[[align_target]]  
    
    return(reference_list[[align_target]][["testing"]])
    
  })
  names(align_list) <- pred_names  
 return(align_list) 
}