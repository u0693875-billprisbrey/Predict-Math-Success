# Prediction Map Sandbox

predictionMap <- function(data,
                          plot_title = NA) {
  
  # This needs to be improved by accepting "grade_quad" instead of "GRADEGPA" as a column name
  
  
  # where "data" is the output of "alignPrediction" where a "pred" column has been
  # added to the reference "test" data
  
  # This creates two side-by-side hexbin plots.
  # Both plots have "ACTMATH" on the y-axis, 
  # and "HSGPA" on the x-axis.
  # Plot on the left is colored by predicted grade,
  # and plot on the right is colored by actual grade
  
  
  # Check for required packages
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required but not installed.")
  }
  if(!requireNamespace("patchwork", quietly = TRUE)) {
    stop("Package 'patchwork' is required but not installed.")
  }
  
  df <- data[,c("HSGPA","ACTMATH", "GRADEGPA", "pred")] 
  
  
  # Create a simple dataframe
  # df <- data.frame(HSGPA = HSGPA, 
  #                 ACTMATH = ACTMATH, 
  #                 GRADEGPA = GRADEGPA)
  
  # Establish title
  
  if(is.na(plot_title)){ 
 plot_title <- "Add title"
  }
    

  # Plot 1: Predicted Median GRADEGPA
  p1 <- ggplot(df, aes(x = HSGPA, y = ACTMATH, z = pred)) +
    stat_summary_hex(fun = median, bins = 30) +
    scale_fill_gradientn(colors = c("darkblue", "cyan", "yellow", "red"),
                         name = "Median\nGRADEGPA") +
    theme_minimal() +
    labs(
      x = "HSGPA", 
      y = "ACTMATH") + 
    ggtitle("Predicted")
  
  
  # Plot 2: Actual Median GRADEGPA
  p2 <- ggplot(df, aes(x = HSGPA, y = ACTMATH, z = GRADEGPA)) +
    stat_summary_hex(fun = median, bins = 30) +
    scale_fill_gradientn(colors = c("darkblue", "cyan", "yellow", "red"),
                         name = "Median\nGRADEGPA") +
    theme_minimal() +
    labs(
      x = "HSGPA", 
      y = "ACTMATH") + 
    ggtitle("Actual")
  
  # Display both plots side by side
  (p1 + p2) + 
    plot_annotation(title = plot_title,
                    theme = theme(plot.title = element_text(hjust = 0.5, size = 14)))
  
  
}