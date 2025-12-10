# Functions for Predict Math Success

plotHex <- function(data, title = NA){
  
  # This creates two side-by-side hexbin plots.
  # Both plots have "ACTMATH" on the y-axis, 
  # and "HSGPA" on the x-axis.
  # Plot on the left is colored by grade,
  # and plot on the right is colored by count
  

  # Check for required packages
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required but not installed.")
  }
  if(!requireNamespace("patchwork", quietly = TRUE)) {
    stop("Package 'patchwork' is required but not installed.")
  }
  
  df <- data[,c("HSGPA","ACTMATH","GRADEGPA")] 
  
  # Create a simple dataframe
  # df <- data.frame(HSGPA = HSGPA, 
  #                 ACTMATH = ACTMATH, 
  #                 GRADEGPA = GRADEGPA)
  
  # Establish title
  
  if(is.na(title)){ 
    if(length(unique(data$course)) <= 5) {
      
      title <- paste(unique(data$course), collapse = ", ")
      
    } else {title <- "Multiple courses"}
    
  }
  
  
  # Plot 1: Median GRADEGPA
  p1 <- ggplot(df, aes(x = HSGPA, y = ACTMATH, z = GRADEGPA)) +
    stat_summary_hex(fun = median, bins = 30) +
    scale_fill_gradientn(colors = c("darkblue", "cyan", "yellow", "red"),
                         name = "Median\nGRADEGPA") +
    theme_minimal() +
    labs(
      x = "HSGPA", 
      y = "ACTMATH")
  
  # Plot 2: Counts per cell
  p2 <- ggplot(df, aes(x = HSGPA, y = ACTMATH)) +
    geom_hex(bins = 30) +
    scale_fill_gradientn(colors = c("lightblue", "yellow", "orange", "red"),
                         name = "Count") +
    theme_minimal() +
    labs(
      x = "HSGPA", 
      y = "ACTMATH")
  
  # Display both plots side by side
  (p2 + p1) + 
    plot_annotation(title = title,
                    theme = theme(plot.title = element_text(hjust = 0.5, size = 14)))
}

overTime <- function(data, 
                     title = NA,
                     variable = "ACTMATH",
                     by = "course",
                     agg = median, 
                     featureMap = NA,
                     showOther = TRUE,
                     plot_params_list = list(),
                     legend_params_list = list(),
                     ...){
  
  # This accepts data, a variable to aggregate, a variable to aggregate by,
  # and an aggregation method.
  
  # Then it produces a line plot, one point per year.
  
  # I'd like to make a plotly version.  
  
  # I'd like to expand it to accept a vector of multiple "by" arguments
  
  # where data is suggested as cleanData[cleanData$vol_cluster == "hi_vol",]
  
  
  if(is.na(title)){
    
    agg_name <- deparse(substitute(agg))
    title <- paste(str_to_title(agg_name), variable, "per", by, "over time", sep=" ")
    
  }
  
  if(by == "course" & is.na(featureMap)){
    
    featureMap <- data.frame(color = c( c("lightsteelblue", "powderblue", "beige", "moccasin", "rosybrown"), c( 
      "darkseagreen3",   
      "lightgoldenrod3", 
      "tan3",            
      "thistle3",        
      "lightskyblue3",   
      "paleturquoise3", #"wheat3",          
      "plum3",           
      "darkseagreen4",   
      "burlywood3"
    )),
    lty = c(rep(1,5), rep(2:5,3)[1:9]),
    course = c(
      "MATH_1010", "MATH_1050", "MATH_1210", "MATH_1030", "MATH_1090", "MATH_1070", "MATH_1220", "MATH_1080", "MATH_1060", "MATH_1310",
      "MATH_2210", "MATH_990",  "MATH_1100", "MATH_1250"
    ),
    lwd = c(rep(3,5), rep(2,9))
    )
  } else if(is.na(featureMap)) {
    
    featureMap <- data.frame(color = c( "darkseagreen3",   
                                        "lightgoldenrod3", 
                                        "tan3",            
                                        "thistle3",        
                                        "lightskyblue3",   
                                        "paleturquoise3", #  "wheat3",          
                                        "plum3",           
                                        "darkseagreen4",   
                                        "burlywood3")[1:length(unique(data[,by]))],
                             by = unique(data[,by]),
                             lty = rep(1, length(unique(data[,by]))) ,
                             lwd = rep(3, length(unique(data[,by])))
                             
    )
    
  }
  
  
  
  
  if(by == "course" & showOther){
    
    levels(data$course) <- c(levels(data$course),"other")
    data$course[!data$course %in% featureMap$course] <- "other"
    
    featureMap <- rbind(featureMap, data.frame(color = "red",
                                               lty = 6,
                                               course = "other",
                                               lwd = 4
    ))
  }
  
  
  incoming.par <- par(mar = c(0,3,3,7), oma = c(4,2,0,0))
  on.exit(par(incoming.par))
  
  plot_params_default <- list(mfrow=c(1,1), mar = c(0,3,3,7), oma = c(4,2,0,0))  
  plot_params_list <- modifyList(plot_params_default, plot_params_list)
  do.call(par, plot_params_list)
  
  
  # Build formula dynamically
  by_vars <- paste(by, collapse = " + ")
  formula_str <- paste(variable, "~", by_vars, "+ class_year")
  formula_obj <- as.formula(formula_str)
  
  
  theAgg <- aggregate(formula_obj, data = data, FUN = agg, ...)
  
  # merge 
  if(by == "course") {
    theAgg <- merge(theAgg, featureMap, by = "course", all.x = TRUE)
  } else {
    theAgg <- merge(theAgg, featureMap, by.x = by, by.y = "by", all.x = TRUE)
  }
  
  
  
  theAgg <- theAgg[order(theAgg$class_year),]
  
  # Erase features not specified in the featureMap
  theAgg <- theAgg[complete.cases(theAgg),]
  
  plot(median(theAgg[,3]),
       xlim = range(theAgg[,2]),
       ylim = range(theAgg[,3]), 
       xlab = "",
       ylab = "",
       xaxt = "n",
       # yaxt = "n",
       type = "n",
       las = 2,
       main = title
  )
  
  if(by == "course") {
    lapply(unique(theAgg$course), function(crse){
      
      filter <- theAgg[,1] == crse
      
      lines(y = theAgg[,3][filter],
            x = theAgg[,2][filter],
            col = theAgg[filter,"color"],
            lwd = theAgg[filter,"lwd"],
            lty = theAgg[filter,"lty"],
      )
      
    })
  } else {
    lapply(unique(theAgg[,by]), function(by_value){
      
      filter <- theAgg[,1] == by_value
      
      lines(y = theAgg[filter,3],
            x = theAgg[filter,2],
            col = theAgg[filter,"color"],
            lwd = theAgg[filter,"lwd"],
            lty = theAgg[filter,"lty"],
      )
    })
  }
  
  axis(side = 1,
       at = 2005:2025,
       labels = 2005:2025,
       las = 2,
       font = 1,
       cex.axis = 1.2
  )
  
  if(by == "course") {
    
    forLegend <- unique(theAgg[,c("course", "color", "lwd", "lty")])
    legend_params_default <- list(x = "topright",
                                  legend = gsub("MATH_","",forLegend[,"course"]),
                                  lty = forLegend[,"lty"],
                                  lwd = forLegend[,"lwd"],
                                  col = forLegend[,"color"],
                                  xpd = TRUE,
                                  inset = c(-0.15,0)
    )
  } else {
    forLegend <- unique(theAgg[,c(by, "color", "lwd", "lty")])
    legend_params_default <- list(x = "topright",
                                  legend = forLegend[,by],
                                  lty = forLegend[,"lty"],
                                  lwd = forLegend[,"lwd"],
                                  col = forLegend[,"color"],
                                  xpd = TRUE,
                                  title = by,
                                  inset = c(-0.15,0)
    ) 
    
  }
  
  legend_params_list <- modifyList(legend_params_default, legend_params_list)
  do.call(legend, legend_params_list)
  
}


displayPerformance <- function(){
  
  #  library(extrafont)
  #  loadfonts()
  
  incoming.par <- par(mar = c(0, 0, 0, 0), oma = c(0,0,0,0))  # Remove margins
  on.exit(par(incoming.par))
  
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1), asp = NA)
  
  # Add a background color (optional)
  rect(0, 0, 1, 1, col = "steelblue", border = NA)
  
  # Add text
  text(0.5, 0.619, "performance equals motivation x ability", 
       cex = 3, col = "white", font = 2, family = "Century Gothic")
  
  # Add sub-set arrows  
  #  arrows(x0 = 0.75,
  #         y0 = 0.4,
  #         x1 = 0.65,
  #         y1 = 0.3,
  #         lwd = 2,
  #         col = "white")
  
  #  arrows(x0 = 0.85,
  #         y0 = 0.4,
  #         x1 = 0.95,
  #         y1 = 0.3,
  #         lwd = 2,
  #         col = "white")
  
  # Add sub-text
  text(0.97, 0.419, 
       "Math ability \n (ACT MATH)", 
       cex = 1.5, 
       col = "white",
       adj = c(1,0))
  
  text(0.97, 0.269, 
       "Study ability \n (HS GPA)", 
       cex = 1.5, 
       col = "white",
       adj = c(1,0))
  
}

displayPipeline <- function(mainFont = "Bahnschrift", 
                            subFont = "Segoe UI",
                            textColor = "slateblue4",
                            arrowColor = "steelblue3",
                            rectColor = "bisque"){
  
  #  library(extrafont)
  #  loadfonts()
  # I could turn each of these graphic items into the do.call(list)
  # format for maximum user control
  
  incoming.par <- par(mar = c(0, 0, 0, 0), oma = c(0,0,0,0))  # Remove margins
  on.exit(par(incoming.par))
  
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1), asp = NA)
  
  # Add a background color (optional)
  rect(0, 0, 1, 1, col = rectColor, border = NA, xpd = TRUE)
  
  # Prior knowledge
  text(0.05, 0.8, "prior knowledge", 
       cex = 2, 
       col = textColor, 
       font = 2, 
       family = mainFont,
       adj = c(0,0))
  
  text(0.3, 0.76, "Test scores\nHigh school performance\n(GPA, AP credits)\nDemographics", 
       cex = 1.381, 
       col = textColor, 
       font = 2, 
       family = subFont,
       adj = c(1,1))
  
  
  # Add arrow  
  arrows(x0 = 0.325,
         y0 = 0.619,
         x1 = 0.425,
         y1 = 0.619,
         lwd = 10,
         col = arrowColor)
  
  # Course selection
  text(0.5, 0.8, "course selection", 
       cex = 2, 
       col = textColor, 
       font = 2, 
       family = mainFont, 
       adj = c(0.4,0))

  text(0.67, 0.76, "Counselor guidance\nPlacement tests\nWord of mouth", 
       cex = 1.381, 
       col = textColor, 
       font = 2, 
       family = subFont, 
       adj = c(1,1))  
  
#  text(0.62, 0.76, "1010\n1050\n1210\n1030\n1090\netc", 
#       cex = 1.381, 
#       col = textColor, 
#       font = 2, 
#       family = subFont, 
#       adj = c(0,1))
  
  # black box
  rect(xleft = 0.375, 
       ybottom = 0.2,
       xright = 0.7,
       ytop = 0.9,
       border = "black",
       lty = 2,
       lwd = 4,
       col = NULL)
  
  # rectangle text
  text(0.68, 0.22, "BLACK BOX",
       col = "black",
       cex = 1.25,
       family = "Calibri",
       font = 4,
       adj = c(0.9,0.1))
  
  # Add arrow  
  arrows(x0 = 0.675,
         y0 = 0.619,
         x1 = 0.775,
         y1 = 0.619,
         lwd = 10,
         col = arrowColor)
  
  # Performance
  text(0.75, 0.8, "performance", 
       cex = 2, 
       col = textColor, 
       font = 2, 
       family = mainFont, 
       adj = c(0,0))
  
  text(0.9, 0.76, "A\nB\nC\nD\nE,EU", 
       cex = 1.381,
       col = textColor, 
       font = 2, 
       family = subFont, 
       adj = c(0,1))
  
}

predictionHistogram <- function(data, 
                                cuts = NA, 
                                show = "prediction",
                                title = NA,
                                cap = TRUE,
                                plot_params = list(),
                                legend_params = list(),
                                mtext_params = list(),
                                rect_params = list(),
                                background_params = list(),
                                hist_params = list()
) {
  
  # where data is the output of alignPrediction
  # where "show" determines if I am showing precision or recall, actual values or predicted values
  # where "cap" determines if I cap the data between 0 and 4.0 or not
  
  # Currently only works with "GRADEGPA"
  
  # background colors: "ivory", "bisque",  "linen", "honeydew", "seashell" ,"lavenderblush" ,"mintcream", "ghostwhite"
  
  incoming.par <- par(mar = c(4,3,3,5), oma = c(0,0,0,0), mfrow = c(1,1))
  on.exit(par(incoming.par))
  
  if(any(is.na(cuts))){
    cuts <- 0:4
    
  }
  
  if(is.na(title)){ 
    # title <- tools::toTitleCase(show)
    if(grepl(show, "actual precision")) {
      title <- "Range of actual grades compared to the prediction"
    } else if (grepl(show, "predict predicted prediction recall")){
      title <- "Range of predicted grades compared to actual"
    } else {
      title <- tools::toTitleCase(show)
    }
  }
  
  # Possibly cap prediction to a min of 0 and max of 4
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
  
  # Create color gradient
  color_gradient <- colorRampPalette(c("darkblue", "cyan", "yellow", "red"))
  
  # Create histogram breaks
  hist_breaks <- unique(c(0.0, 0.7, 1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, max(data$pred, na.rm = TRUE)))
  
  # Calculate bin midpoints
  bin_midpoints <- (hist_breaks[-length(hist_breaks)] + hist_breaks[-1]) / 2
  
  # Map midpoints to colors (normalize to 0-1 range, then get colors)
  normalized_midpoints <- (bin_midpoints - 0) / (4 - 0)
  bin_colors <- color_gradient(100)[pmax(1, pmin(100, round(normalized_midpoints * 99 + 1)))]
  
  
  # Plot
  
  if(grepl(show, "actual precision")) {
    
    default_plot_params <- list(mfrow = c(length(levels(data$pred_cut)),1),
                                mar = c(1,4,1,0),
                                oma = c(2,0,4,1), 
                                bg = "aliceblue", # "bisque",
                                fg = "gray20")
    plot_params <- modifyList(default_plot_params, plot_params)
    do.call(par, plot_params)
    
    
    
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
      
      default_legend_params <- list(x = "topright",
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
  
  
  if(grepl(show, "predict predicted prediction recall")) {
    
    
    if(sum(data$ref_cut == levels(data$ref_cut)[length(levels(data$ref_cut))]) == 0){
      
      default_plot_params <- list(mfrow = c(length(levels(data$ref_cut))-1,1),
                                  mar = c(1,4,1,0),
                                  oma = c(2,0,4,1), 
                                  bg = "aliceblue", # "bisque",
                                  fg = "gray20")
      plot_params <- modifyList(default_plot_params, plot_params)
      do.call(par, plot_params)
      
    } else {
      
      default_plot_params <- list(mfrow = c(length(levels(data$ref_cut)),1),
                                  mar = c(1,4,1,0),
                                  oma = c(2,0,4,1), 
                                  bg = "aliceblue", # "bisque",
                                  fg = "gray20")
      plot_params <- modifyList(default_plot_params, plot_params)
      do.call(par, plot_params)  
      
      
    }
    
    counter <-0  
    for(theCut in levels(data$ref_cut)){ 
      
      counter <- counter + 1
      
      if(nrow(data[data$ref_cut == theCut,]) == 0 ){next}
      
      # Plot histogram
      default_hist_params <- list(
        x = data[data$ref_cut == theCut,"pred"],
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
      
      # Axis
      
      axis(side = 2, at = axTicks(2), las = 2, font = 2)
      
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
      
      default_legend_params <- list(x = "topright",
                                    legend = paste(theCut, " Actual"),
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
  
  
  default_mtext_params <- list(side = 3,
                               font = 2,
                               cex = 1.5,
                               text = title,
                               outer = TRUE,
                               line = 1.3)
  mtext_params <- modifyList(default_mtext_params, mtext_params)
  do.call(mtext, mtext_params)
  
}

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


createCM <- function(data, target = "GRADEGPA", cuts=NA, cap=TRUE){
  
  # This accepts the output of "alignPrediction" and returns a confusion matrix
  # based on the specified cuts.
  
  # where data is the output of alignPrediction
  # where "cap" determines if I cap the data between 0 and 4.0 or not
  
  if(any(is.na(cuts))){
    cuts <- 0:4
  }
  
  
  # Possibly cap maximum prediction
  if(cap){
    data$pred <- pmin(pmax(data$pred, 0), max(cuts))
  }
  
  # Expand to include the maximum prediction
  if(max(data$pred, na.rm = TRUE) > max(cuts)){
    
    cuts <- c(cuts,max(data$pred, na.rm = TRUE))
    
  }
  
  data$pred_cut <- cut(data$pred, cuts, include.lowest = TRUE)
  data$ref_cut <- cut(data[,target], cuts, include.lowest = TRUE)
  
  cm <- confusionMatrix(data$pred_cut, data$ref_cut, mode = "everything")
  
  return(cm)
  
}



displayCourseAlternatives <- function(data,
                                      unid = NA,
                                      par_params = list(),
                                      plot_params = list(),
                                      rect_params = list(),
                                      axis_params = list(list()),
                                      point_params = list(
                                        list(),
                                        list(),
                                        list()
                                      ),
                                      legend_params = list(),
                                      mtext_params = list()
){
  
  # where data is trainingGround  
  
  
  incoming.par <- par(mar = c(4,2,2,1))
  on.exit(par(incoming.par))
  
  # randomly assign a unid if not specified
  
  if(is.na(unid)){
    unid <- sample(data[,"unid"],1)
  }
  
  plotFilter <- testingGround$unid == unid
  
  # Plot parameters
  default_par_params <- list(mar=c(4,7,3,10), bg = "bisque", fg = "grey20")
  par_params <- modifyList(default_par_params, par_params)
  do.call(par, par_params)
  
  # Empty plot
  n_courses <- nlevels(data$course)   # number of courses
  
  # Establish the xlim range
  xLim <- range(data[plotFilter,c("pred.vH2","pred.vK0", "GRADEGPA")], na.rm=TRUE)
  
  default_plot_params <- list(
    x = NULL,
    y = NULL,
    xlim = xLim,
    ylim = c(1, n_courses),
    xlab = "",
    ylab = "",
    yaxt = "n"
  )
  
  plot_params <- modifyList(default_plot_params, plot_params)
  do.call(plot, plot_params)
  
  # Background rectangle
  #  default_rect_params <- list(xleft = par("usr")[1],
  #                              ybottom = par("usr")[3],
  #                              xright = par("usr")[2],
  #                              ytop = par("usr")[4],
  #                              col = "gray90",
  #                              border = NULL
  #                              )
  #  rect_params <- modifyList(default_rect_params,
  #                            rect_params
  #                            )
  #  do.call(rect, rect_params)
  
  default_rect_params <- list(
    colors = c("gray92", "gray97"),  # Alternating colors
    border = NA
  )
  rect_params <- modifyList(default_rect_params, rect_params)
  
  # Draw one rectangle per course level
  for (i in 1:n_courses) {
    color_index <- ((i - 1) %% length(rect_params$colors)) + 1
    rect(
      xleft = par("usr")[1],
      ybottom = i - 0.5,
      xright = par("usr")[2],
      ytop = i + 0.5,
      col = rect_params$colors[color_index],
      border = rect_params$border
    )
  }
  
  # axis
  default_axis_params <- list(
    list(side =2, 
         at = 1:n_courses, 
         labels = levels(data[,"course"]), 
         las = 1,
         tick = FALSE)
  )
  
  # Merge axis params sequentially
  for (i in seq_along(axis_params)) {
    if (i <= length(default_axis_params)) {
      axis_params[[i]] <- modifyList(default_axis_params[[i]], axis_params[[i]])
    }
  }
  
  # Call axis
  for (params in axis_params) {
    do.call(axis, params)
  }
  
  # points
  default_point_params <- list(
    list(
      x = data[plotFilter,"pred.vH2"],
      y = as.numeric(data[plotFilter, "course"]), 
      pch = 9, 
      col = "mediumpurple3"
    ),
    list(x = data[plotFilter,"pred.vK0"],
         y = as.numeric(data[plotFilter, "course"]), 
         pch = 1, 
         col = "seagreen"
    ),
    list(
      x = unique(data$GRADEGPA[plotFilter]),
      y = as.numeric(unique(data$course_orig[plotFilter])),  
      pch = 13,
      lwd = 2,
      cex = 2,
      col = "red"
    )
  )
  
  
  # Merge point params sequentially
  for (i in seq_along(point_params)) {
    if (i <= length(default_point_params)) {
      point_params[[i]] <- modifyList(default_point_params[[i]], point_params[[i]])
    }
  }
  
  # Plot all point sets
  for (params in point_params) {
    do.call(points, params)
  }
  
  # legend
  default_legend_params <- list("topright",
                                bg = "ivory",
                                col = c("mediumpurple3", "seagreen", "darkorange2"),
                                pch = c(9,1,13),
                                pt.lwd = c(1,1,2),
                                pt.cex = c(1,1,1.6),
                                legend = c("Test score (vH2)", "No test score (vK0)", "Actual"),
                                xpd = TRUE,
                                inset = c(-0.50,0))
  legend_params <- modifyList(default_legend_params, legend_params)  
  do.call(legend, legend_params) 
  
  default_mtext_params <- list(
    side = c(1,3),
    text = c("GPA", "Individual course predictions"),
    line = c(2.3, 1),
    outer = c(FALSE, FALSE),
    cex = c(1,1.5),
    font = c(1,2)
  )
  
  mtext_params <- modifyList(default_mtext_params, mtext_params)
  do.call(mtext, mtext_params)
  
}


courseScatter <- function(
    data,
    showCourse = FALSE,
    ellipseFilter = NA,
    clusterFilter = NA,
    featureMaps = list(courseMap = NA,
                       yearMap = NA,
                       clusterMap = NA
    ),
    dist_params = list(),
    hclust_params = list(),
    cutree_params = list(),
    par_params = list(),
    rect_params = list(),
    grid_params = list(),
    plot_params = list(),
    point_params = list(),
    ellipse_params = list(),
    axis_params_x = list(),
    axis_params_y = list(),
    mtext_params = list(),
    legend_params = list()
) {
  
  # where data is an aggregation from cleanData as follows:
  
  # hiGrades <- aggregate(cbind(HSGPA,ACTMATH) ~ course + class_year, 
  #                      data = cleanData[cleanData$GRADEGPA > 2.4,], function(x){
  #                        c(median = median(x),
  #                          IQR = IQR(x),
  #                          stdev = sd(x)
  #                        ) 
  #                      }) |>
  #  (\(x){
  #    do.call(data.frame,x)
  #  })()
  
  # Ellipse plotting:
  
  # prevents ellipses from plotting
  # ellipse_params =list(plot = FALSE) 
  
  # plot selected ellipses
  # courseScatter(hiGrades[hiGrades$class_year == 2023,], ellipseFilter = hiGrades[hiGrades$class_year == 2023,]$course %in% c("MATH_1050", "MATH_1010"), cutree_params = list(k=4), plot_params=list(xlim = c(3.5,4)))
  
  # You must be sure to correctly align the clusterFilter and ellipseFilter, or plot is in error
  
  # Modifications:
  
  # Needs to be plotly
  # Ellipses don't look right when I am filtering on cluster and ellipse  
  # Course colors may be off (if I ever use that)
  # A side-by-side with an arrow (this again?) of low-and-high (?)
  
  # But first, I need to calculate the distance between the students and these courses in st dev
  # And, add students to this plot
  
  
  #############  
  ## CLUSTER ##
  #############  
  
  data$clust <- NA
  
  for(yr in unique(data$class_year)){
    
    yearFilter <- data$class_year == yr
    
    features <- data[yearFilter , c("HSGPA.median","HSGPA.IQR","ACTMATH.median","ACTMATH.IQR") ]
    
    theDistance <- do.call(dist, modifyList(list(x=features, method="euclidean"), dist_params))
    theHclust <- do.call(hclust, modifyList(list(d=theDistance, method = "complete"), hclust_params))
    clusters <- do.call(cutree, modifyList(list(tree=theHclust, k=3), cutree_params))
    
    data$clust[yearFilter] <- clusters
    
  }
  
  ##################
  ## FEAUTURE MAP ##
  ##################
  
  # actually it's more like feature maps
  # maybe feed that in a list ?
  
  if(any(is.na(featureMaps))){
    
    courseCount <- length(unique(data$course))
    
    if(is.na(featureMaps[["courseMap"]])){
      
      # darker versions of the default color maps used elsewhere
      
      mainCourses <- data.frame(color = c( c("steelblue4", "skyblue", "tan4", "goldenrod4", "rosybrown4"), c( 
        "darkseagreen4",   
        "lightgoldenrod4", 
        "tan4",            
        "thistle4",        
        "lightskyblue4",   
        "paleturquoise4", #"wheat3",          
        "plum4",           
        "darkseagreen",   
        "burlywood4"
      )),
      course = c(
        "MATH_1010", "MATH_1050", "MATH_1210", "MATH_1030", "MATH_1090", "MATH_1070", "MATH_1220", "MATH_1080", "MATH_1060", "MATH_1310",
        "MATH_2210", "MATH_990",  "MATH_1100", "MATH_1250"
      )
      )
      
      # Additional courses
      
      extraCourses <- setdiff(unique(data$course), unique(mainCourses$course))
      
      if(length(extraCourses)>0){ 
        
        extraCourses <- data.frame(
          color = rep("darkorange3", length(extraCourses) ),
          course = extraCourses
        )
        
        featureMaps[["courseMap"]] <- rbind(mainCourses, extraCourses)
        
      } else {featureMaps[["courseMap"]] <- mainCourses } 
      
    }
    
    if(is.na(featureMaps[["yearMap"]])){
      
      featureMaps[["yearMap"]] <- data.frame(pch = c(c(13,19,18,17,15,14,12:0), rep(0, 2)),
                                             class_year = c(2025:2005)
      )  
    }
    
    if(is.na(featureMaps[["clusterMap"]])){
      
      colors <- c("tomato", "dodgerblue", "forestgreen", "purple3", "orange2", "brown", "pink", "cyan", "sienna","magenta" )
      
      featureMaps[["clusterMap"]] <- data.frame(color = colors[unique(clusters)],
                                                clust = unique(clusters)
      )
      
    }
  }
  
  # Merge the maps to the data
  data <- merge(data, featureMaps[["yearMap"]], by = "class_year")
  
  if(showCourse){
    data <- merge(data, featureMaps[["courseMap"]], by = "course")
  } else {
    data <- merge(data, featureMaps[["clusterMap"]], by = "clust")  
  }
  
  # Filter to cluster if specified
  
  if(!any(is.na(clusterFilter))) {
    data <- data[data$clust %in% clusterFilter, ]
  }
  
  ##########  
  ## PLOT ##
  ##########  
  
  incoming.par <- par(mar = c(0,3,3,7), oma = c(4,2,0,0))
  on.exit(par(incoming.par))
  
  par_params_default <- list(mfrow=c(1,1), mar = c(0,2.5,3,7), oma = c(4,2,0,0), fg = "gray20", bg = "ivory")  
  par_params <- modifyList(par_params_default, par_params)
  do.call(par, par_params)
  
  plot_params_default <- list(
    x = data$HSGPA.median,
    y = data$ACTMATH.median,
    #  ylim = c(10,36),
    #  xlim = c(2,4),
    xlab = "",
    ylab = "",
    xaxt = "n",
    yaxt = "n",
    las = 1,
    main = "",
    type = "n"
  )
  
  plot_params <- modifyList(plot_params_default, plot_params)
  do.call(plot, plot_params)
  
  ##########
  ## RECT ##
  ##########  
  
  default_rect_params <- list(
    xleft = par("usr")[1],
    ybottom = par("usr")[3],
    xright = par("usr")[2],
    ytop = par("usr")[4],
    col = "grey90"
  )
  
  rect_params <- modifyList(default_rect_params, rect_params)
  do.call(rect, rect_params)
  
  ##########
  ## GRID ##
  ##########
  
  default_grid_params <- list(col = "grey95", lwd = 1.3, lty = 1)
  grid_params <- modifyList(default_grid_params, grid_params)
  do.call(grid, grid_params)
  
  ############
  ## POINTS ##
  ############  
  
  
  default_point_params <- list(
    x = data$HSGPA.median,
    y = data$ACTMATH.median,
    col = data$color,
    pch = data$pch
  )
  
  point_params <- modifyList(default_point_params, point_params)  
  do.call(points, point_params)
  
  
  ##########
  ## AXIS ##
  ##########  
  
  default_axis_params_x <- list(side=1,
                                at = NULL,
                                labels = TRUE,
                                las = 1)
  axis_params_x <- modifyList(default_axis_params_x, axis_params_x)
  do.call(axis, axis_params_x)
  
  
  default_axis_params_y <- list(side=2,
                                at = NULL,
                                labels = TRUE,
                                las = 1)
  axis_params_y <- modifyList(default_axis_params_y, axis_params_y)
  do.call(axis, axis_params_y)
  
  #################
  ## MARGIN TEXT ##
  #################
  
  default_mtext_params <- list(side = c(1:3),
                               font = c(1,1,2),
                               cex = c(1.3,1.3,2.5),
                               line = c(2.3, 2.3, 0.25),
                               text = c("HSGPA","ACT MATH", paste("Course medians in ", unique(data$class_year)))
  )
  mtext_params <- modifyList(default_mtext_params, mtext_params)
  do.call(mtext, mtext_params)
  
  #############
  ## ELLIPSE ##
  #############  
  
  if(all(is.na(ellipseFilter))) {
    
    ellipseFilter <- rep(TRUE, nrow(data))
    
  }
  
  default_ellipse_params <- list(
    x= data$HSGPA.median[ellipseFilter],
    y = data$ACTMATH.median[ellipseFilter],
    radius.x = data$HSGPA.IQR[ellipseFilter],
    radius.y = data$ACTMATH.IQR[ellipseFilter],
    col = NA,
    border = data$color[ellipseFilter] 
    
  )
  ellipse_params <- modifyList(default_ellipse_params, ellipse_params)
  do.call(DrawEllipse, ellipse_params)
  
  ############
  ## LEGEND ##
  ############ 
  
  legendValues <- unique(data[,c("course","color","pch")])
  
  default_legend_params <- list(
    x="topright",
    legend = c(as.character(legendValues$course),"IQR"),
    pt.cex = 2,
    col = c(legendValues$color,"gray") ,
    pch = c(legendValues$pch, 1),
    inset = c(-0.195,0),
    xpd = TRUE,
    bg = "snow"
  )
  
  legend_params <- modifyList(default_legend_params, legend_params)
  do.call(legend, legend_params)
  
  
}

