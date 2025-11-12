# Predictors over time using plotly


overTimePlotly <- function(data, 
                           title = NA,
                           variable = "ACTMATH",
                           by = "course",
                           agg = median, 
                           featureMap = NA,
                           showOther = TRUE,
                           ...){
  
  library(plotly)
  library(stringr)
  
  # Generate title if not provided
  if(is.na(title)){
    agg_name <- deparse(substitute(agg))
    title <- paste(str_to_title(agg_name), variable, "per", by, "over time", sep=" ")
  }
  
  # Set up default featureMap for courses
  if(by == "course" & is.na(featureMap)){
    featureMap <- data.frame(
      color = c(c("lightsteelblue", "powderblue", "beige", "moccasin", "rosybrown"), 
                c("darkseagreen3", "lightgoldenrod3", "tan3", "thistle3", 
                  "lightskyblue3", "paleturquoise3", "plum3", 
                  "darkseagreen4", "burlywood3")),
      dash = c(rep("solid", 5), rep(c("dash", "dot", "dashdot"), 3)[1:9]),
      course = c("MATH_1010", "MATH_1050", "MATH_1210", "MATH_1030", "MATH_1090", 
                 "MATH_1070", "MATH_1220", "MATH_1080", "MATH_1060", "MATH_1310",
                 "MATH_2210", "MATH_990", "MATH_1100", "MATH_1250"),
      width = c(rep(3, 5), rep(2, 9))
    )
  } else if(is.na(featureMap)) {
    featureMap <- data.frame(
      color = c("darkseagreen3", "lightgoldenrod3", "tan3", "thistle3", 
                "lightskyblue3", "paleturquoise3", "plum3", 
                "darkseagreen4", "burlywood3")[1:length(unique(data[,by]))],
      by = unique(data[,by]),
      dash = rep("solid", length(unique(data[,by]))),
      width = rep(3, length(unique(data[,by])))
    )
  }
  
  # Handle "other" category for courses
  if(by == "course" & showOther){
    levels(data$course) <- c(levels(data$course), "other")
    data$course[!data$course %in% featureMap$course] <- "other"
    
    featureMap <- rbind(featureMap, 
                        data.frame(color = "red",
                                   dash = "longdashdot",
                                   course = "other",
                                   width = 4))
  }
  
  # Build formula dynamically
  by_vars <- paste(by, collapse = " + ")
  formula_str <- paste(variable, "~", by_vars, "+ class_year")
  formula_obj <- as.formula(formula_str)
  
  # Aggregate data
  theAgg <- aggregate(formula_obj, data = data, FUN = agg, ...)
  
  # Merge with feature map
  if(by == "course") {
    theAgg <- merge(theAgg, featureMap, by = "course", all.x = TRUE)
  } else {
    theAgg <- merge(theAgg, featureMap, by.x = by, by.y = "by", all.x = TRUE)
  }
  
  # Sort and filter
  theAgg <- theAgg[order(theAgg$class_year),]
  theAgg <- theAgg[complete.cases(theAgg),]
  
  # Initialize plotly
  p <- plot_ly()
  
  # Add traces for each group
  if(by == "course") {
    for(crse in unique(theAgg$course)) {
      filter <- theAgg$course == crse
      subset_data <- theAgg[filter, ]
      
      p <- p %>%
        add_trace(x = subset_data$class_year,
                  y = subset_data[, 3],
                  name = gsub("MATH_", "", crse),
                  type = 'scatter',
                  mode = 'lines+markers',
                  line = list(color = subset_data$color[1],
                              width = subset_data$width[1],
                              dash = subset_data$dash[1]),
                  marker = list(color = subset_data$color[1]))
    }
  } else {
    for(by_value in unique(theAgg[, by])) {
      filter <- theAgg[, by] == by_value
      subset_data <- theAgg[filter, ]
      
      p <- p %>%
        add_trace(x = subset_data$class_year,
                  y = subset_data[, 3],
                  name = as.character(by_value),
                  type = 'scatter',
                  mode = 'lines+markers',
                  line = list(color = subset_data$color[1],
                              width = subset_data$width[1],
                              dash = subset_data$dash[1]),
                  marker = list(color = subset_data$color[1]))
    }
  }
  
  # Add layout
  p <- p %>%
    layout(title = title,
           xaxis = list(title = "Year"),
           yaxis = list(title = variable),
           hovermode = "closest",
           legend = list(orientation = "v",
                         x = 1.02,
                         y = 1,
                         xanchor = "left"))
  
  invisible(list(plot = p, data = theAgg))
  #return(p)
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
  
  if(length(by) == 1 & "course" %in% by & all(is.na(featureMap))){
    
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
  } else if(all(is.na(featureMap))) {
    
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
  
  
  
  
  if(length(by) == 1 & "course" %in% by & showOther){
    
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
  
  invisible(theAgg)
  
}