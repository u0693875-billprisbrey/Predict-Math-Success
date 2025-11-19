# Prediction accuracy histograms sandbox

# PURPOSE:  I want to take the output of "alignPrediction", and create a plot with terraced histograms.
# One version shows the histogram of actual values given a cut of prediction values,
# and another version shows the histogram of predicted values given an actual value.

# honestly, this isn't bad.
# I'd like to use the same color as the heatmaps, though

# color coding will be fun, as I need to use background colors

# I don't like the harsh white background

# I'd like to put a dotted box around the reference
# I'd like to specify the count and percentage below a value like 1 or 2
# I'd like to increase the flexibility of parameters with the "list" method
# I'd like to rotate the y-axis labels, andmake them larger and bolder
# I'd like to put the x-axis on top

# I need to fix the cuts on "prediction"
# I might not need to repeat the "hist" function

predictionHistogram <- function(data, cuts = NA, show = "prediction"){
  
  # where data is the output of alignPrediction
  
  if(show == "prediction") {
  
  if(any(is.na(cuts))){
    cuts <- c(0.0, 0.7, 1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0)
    
  }

  # Expand to include the maximum prediction
  if(max(data$pred, na.rm = TRUE) > max(cuts)){
    
    cuts <- c(cuts,max(data$pred, na.rm = TRUE))
    
  }
  
  data$cut <- cut(data$GRADEGPA, cuts, include.lowest = TRUE)
  
  # Create color gradient
  color_gradient <- colorRampPalette(c("darkblue", "cyan", "yellow", "red"))
  
  # Create histogram breaks
  hist_breaks <- c(0.0, 0.7, 1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, max(data$pred, na.rm = TRUE))
  
  # Calculate bin midpoints
  bin_midpoints <- (hist_breaks[-length(hist_breaks)] + hist_breaks[-1]) / 2
  
  # Map midpoints to colors (normalize to 0-1 range, then get colors)
  normalized_midpoints <- (bin_midpoints - 0) / (4 - 0)
  bin_colors <- color_gradient(100)[pmax(1, pmin(100, round(normalized_midpoints * 99 + 1)))]
  
  
  par(mfrow = c(length(levels(data$cut)),1), mar = c(0,2,0,0), oma = c(2,0,4,1), bg = "bisque")
  
  lapply(levels(data$cut), function(theCut){
  
    
  hist(data[data$cut == theCut,"pred"],
       breaks = hist_breaks,
       freq = FALSE,
       col = bin_colors,
       border = "white",
       main = "")
    legend("topleft", legend = paste("Predicted values for actual ", theCut)  )
    
  })
  
  }
  
  if(show == "actual") {
    
    if(any(is.na(cuts))){
      cuts <- c(0.0, 0.7, 1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0)
      
    }
    
    # Expand to include the maximum prediction
    if(max(data$pred, na.rm = TRUE) > max(cuts)){
      
      cuts <- c(cuts,max(data$pred, na.rm = TRUE))
      
    }
    
    data$cut <- cut(data$pred, cuts, include.lowest = TRUE)
    # Create color gradient
    color_gradient <- colorRampPalette(c("darkblue", "cyan", "yellow", "red"))
    
    # Create histogram breaks
    hist_breaks <- c(0.0, 0.7, 1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, max(data$pred, na.rm = TRUE))
    
    # Calculate bin midpoints
    bin_midpoints <- (hist_breaks[-length(hist_breaks)] + hist_breaks[-1]) / 2
    
    # Map midpoints to colors (normalize to 0-1 range, then get colors)
    normalized_midpoints <- (bin_midpoints - 0) / (4 - 0)
    bin_colors <- color_gradient(100)[pmax(1, pmin(100, round(normalized_midpoints * 99 + 1)))]
    
    
    par(mfrow = c(length(levels(data$cut)),1), mar = c(0,2,0,0), oma = c(2,0,4,1), bg = "bisque")
    
    
    lapply(levels(data$cut), function(theCut){
      
      
      hist(data[data$cut == theCut,"GRADEGPA"],
           breaks = hist_breaks,
           freq = FALSE,
           col = bin_colors,
           main = "")
      legend("topleft", legend = paste("Actual values for predicted ", theCut), bg = "ivory"  )
      
    })
    
  }
  
}
