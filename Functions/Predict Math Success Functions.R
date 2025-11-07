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
  
  
  incoming.par <- par(mar = NA, oma = NA)
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
  
  text(0.58, 0.76, "1010\n1050\n1210\n1030\n1090\netc", 
       cex = 1.381, 
       col = textColor, 
       font = 2, 
       family = subFont, 
       adj = c(0,1))
  
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
  
  text(0.9, 0.76, "A\nB\nC\nD\nF", 
       cex = 1.381,
       col = textColor, 
       font = 2, 
       family = subFont, 
       adj = c(0,1))
  
}
