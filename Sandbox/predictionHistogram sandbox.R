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

# Float a large "RECALL" or "PRECISION" number to the right on each histogram

# Label x-axis as "ACTUAL" or "PREDICTED" GPA
# Figure out a legend for the reference rectangle

predictionHistogram <- function(data, 
                                cuts = NA, 
                                show = "prediction",
                                title = NA,
                                plot_params = list(),
                                legend_params = list(),
                                mtext_params = list(),
                                rect_params = list(),
                                background_params = list(),
                                hist_params = list()
                                ) {
  
  # where data is the output of alignPrediction
  
  # background colors: "ivory", "bisque",  "linen", "honeydew", "seashell" ,"lavenderblush" ,"mintcream", "ghostwhite"

  incoming.par <- par(mar = c(0,3,3,7), oma = c(4,2,0,0))
  on.exit(par(incoming.par))
  
  if(any(is.na(cuts))){
    cuts <- 0:4
    
  }
  
  if(is.na(title)){ 
    title <- tools::toTitleCase(show)
    }
  
  # Expand to include the maximum prediction
  if(max(data$pred, na.rm = TRUE) > max(cuts)){
    
    cuts <- c(cuts,max(data$pred, na.rm = TRUE))
    
  }
    
  data$pred_cut <- cut(data$pred, cuts, include.lowest = TRUE)
  data$ref_cut <- cut(data$GRADEGPA, cuts, include.lowest = TRUE)
  
  cm <- confusionMatrix(data$pred_cut, data$ref_cut)

  # Create color gradient
  color_gradient <- colorRampPalette(c("darkblue", "cyan", "yellow", "red"))
  
  # Create histogram breaks
  hist_breaks <- c(0.0, 0.7, 1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, max(data$pred, na.rm = TRUE))
  
  # Calculate bin midpoints
  bin_midpoints <- (hist_breaks[-length(hist_breaks)] + hist_breaks[-1]) / 2
  
  # Map midpoints to colors (normalize to 0-1 range, then get colors)
  normalized_midpoints <- (bin_midpoints - 0) / (4 - 0)
  bin_colors <- color_gradient(100)[pmax(1, pmin(100, round(normalized_midpoints * 99 + 1)))]
  
  default_plot_params <- list(mfrow = c(length(levels(data$pred_cut)),1),
                              mar = c(1,4,1,0),
                              oma = c(2,0,4,1), 
                              bg = "aliceblue", # "bisque",
                              fg = "gray20")
  plot_params <- modifyList(default_plot_params, plot_params)
  do.call(par, plot_params)
  
  
  # Plot
  
  if(grepl(show, "actual precision")) {
    

    
  counter <-0  
  for(theCut in levels(data$pred_cut)){
    
    
    counter <- counter + 1
    
    # Plot histogram
    default_hist_params <- list(
      x = data[data$pred_cut == theCut,"GRADEGPA"],
      breaks = hist_breaks,
      freq = FALSE,
      col = bin_colors,
      las = 2,
      xaxt = "n",
      yaxt = "n",
      ylab = "",
      xlab = "",
      main = ""
    )
    
    current_hist_params <- modifyList(default_hist_params, hist_params)
    do.call(hist, current_hist_params)
    
    # Over-write histogram with a background rect of chosen color
    default_background_params <- list(xleft = par("usr")[1],
                                      ybottom = par("usr")[3],
                                      xright = par("usr")[2],
                                      ytop = par("usr")[4],
                                      border = NA,
                                      col = "gray80"
    )
    
    current_background_params <- modifyList(default_background_params, background_params)
    do.call(rect, current_background_params)
    
    # Re-write histogram
    current_hist_params <- modifyList(current_hist_params, list(add = TRUE))
    do.call(hist, current_hist_params)
    
    
  #  theHist <- hist(data[data$pred_cut == theCut,"GRADEGPA"],
  #                  breaks = hist_breaks,
  #                  freq = FALSE,
  #                  col = bin_colors,
  #                  # border = "white",
  #                  las = 2,
  #                  xaxt = "n",
  #                  yaxt = "n",
  #                  ylab = "",
  #                  xlab = "",
  #                  main = "")
    
   
    
    axis(side = 2, at = axTicks(2), las = 2, font = 2)
    
    if(counter == 1  ) {
      axis(side = 3, at = 0:4, labels = TRUE, tick = TRUE, font = 2)
    }
    
    if(counter == length(levels(data$pred_cut))  ) {
      axis(side = 1, at = 0:4, labels = TRUE, tick = TRUE, font = 2)
    }
    
    
    
    xInterval <- theCut |>
      as.character() |>
      (\(x){gsub("[^0-9.,]", "",x) })() |>
      (\(x){as.numeric(strsplit(x, ",")[[1]])})()
    
    default_rect_params <- list(xleft = xInterval[1],
                                ybottom = par("usr")[3],
                                xright = xInterval[2],
                                ytop = par("usr")[4]*0.618,
                                border = bin_colors[max(which(bin_midpoints < max(xInterval) ))],
                                lty =2,
                                lwd = 3
                                )
    current_rect_params <- modifyList(default_rect_params, rect_params)
    do.call(rect, current_rect_params)
   
    default_legend_params <- list(x = "topleft",
                                  legend = paste(theCut, " Predicted"),
                                  bg = "ivory",
                                  pch = 22,
                                  pt.cex = 3,
                                  pt.lwd = 2,
                                  pt.bg = NA,
                                  lty = 0,
                                  col = bin_colors[max(which(bin_midpoints < max(xInterval) ))]
    )
    current_legend_params <- modifyList(default_legend_params, legend_params)
    do.call(legend, current_legend_params)
     
  }
  
  }
  
  
  if(grepl(show, "prediction recall")) {
  
    counter <-0  
    for(theCut in levels(data$ref_cut)){ 
      counter <- counter + 1
      theHist <- hist(data[data$ref_cut == theCut,"pred"],
                      breaks = hist_breaks,
                      freq = FALSE,
                      col = bin_colors,
                      border = "white",
                      las = 2,
                      xaxt = "n",
                      main = "")
      default_legend_params <- list(x = "topleft",
                                    legend = paste("Actual values for predicted ", theCut),
                                    bg = "ivory")
      current_legend_params <- modifyList(default_legend_params, legend_params)
      do.call(legend, current_legend_params)
      # legend("topleft", legend = paste("Predicted values for actual ", theCut)  )
      
      if(counter == 1  ) {
        axis(side = 3, at = 0:4, labels = TRUE, tick = TRUE)
      }
      
      if(counter == length(levels(data$pred_cut))  ) {
        axis(side = 1, at = 0:4, labels = TRUE, tick = TRUE)
      }
      
      xInterval <- theCut |>
        as.character() |>
        (\(x){gsub("[^0-9.,]", "",x) })() |>
        (\(x){as.numeric(strsplit(x, ",")[[1]])})()
      
      rect(xleft = xInterval[1],
           ybottom = par("usr")[3],
           xright = xInterval[2],
           ytop = par("usr")[4]*0.618,
           border = "red",
           lty =2,
           lwd = 3
      )  
      
      
    }
    

    
  }
  
  
  default_mtext_params <- list(side = 3,
                               font = 2,
                               cex = 1.5,
                               text = title,
                               outer = TRUE,
                               line = 0.31)
  mtext_params <- modifyList(default_mtext_params, mtext_params)
  do.call(mtext, mtext_params)
  
}


predictionHistogram2 <- function(data, cuts = NA, show = "prediction"){
  
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
  
#  lapply(levels(data$cut), function(theCut){
counter <-0  
 for(theCut in levels(data$cut)){ 
    counter <- counter + 1
  theHist <- hist(data[data$cut == theCut,"pred"],
       breaks = hist_breaks,
       freq = FALSE,
       col = bin_colors,
       border = "white",
       las = 2,
       xaxt = "n",
       main = "")
    legend("topleft", legend = paste("Predicted values for actual ", theCut)  )
    
  #  if(which(theCut %in% levels(data$cut)) == 1  ) {
      if(counter == 1  ) {
    axis(side = 3, at = 0:4, labels = TRUE, tick = TRUE)
    }
     
   # if(which(theCut %in% levels(data$cut)) == length(levels(data$cut))  ) {
    if(counter == length(levels(data$cut))  ) {
          axis(side = 1, at = 0:4, labels = TRUE, tick = TRUE)
    }
     
    xInterval <- theCut |>
      as.character() |>
      (\(x){gsub("[^0-9.,]", "",x) })() |>
      (\(x){as.numeric(strsplit(x, ",")[[1]])})()
      
  rect(xleft = xInterval[1],
       ybottom = par("usr")[3],
       xright = xInterval[2],
       ytop = par("usr")[4]*0.618,
       border = "red",
       lty =2,
       lwd = 3
       )  
    
    
  }
  #)
  
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
