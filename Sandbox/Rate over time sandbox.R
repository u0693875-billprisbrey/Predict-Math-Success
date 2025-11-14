# Rate Over Time sandbox

# PURPOSE:  This creates a function similar to "overTime" except it calculates rates over time.

ratesOverTime <- function(data, 
                          title = NA,
                          variable = "ACTMATH",
                          denominator_variable = "EMPLID",
                          by = "course",
                          agg = length, 
                          featureMap = NA,
                          showOther = TRUE,
                          plot_params_list = list(),
                          legend_params_list = list(),
                          ... ) {
  
  # This accepts data and a variable to aggregate by.
  
  # It produces a line plot, one point per year, one line per value of "by".
  
  # The line is a rate, always scaled to the number of EMPLID
  
  if(is.na(title) & deparse(substitute(agg)) == "length"){
    
    title <- paste("Rate of", variable, "submission over time by", by, sep =" ")
    
    # agg_name <- deparse(substitute(agg))
    # title <- paste(str_to_title(agg_name), variable, "per", by, "over time", sep=" ")
    
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
    lty = c(rep(3,5), rep(4:6,3)[1:9]),
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
                             lty = rep(3, length(unique(data[,by]))) ,
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
  
  
  # Build formulas dynamically
  by_vars <- paste(by, collapse = " + ")
  formula_str <- paste(variable, "~", by_vars, "+ class_year")
  formula_obj <- as.formula(formula_str)
  
  # Aggregate
  theAgg <- aggregate(formula_obj, data = data, FUN = agg, ...)
  
  # Build formulas dynamically
  formula_str_denom <- paste(denominator_variable, "~", by_vars, "+ class_year")
  formula_obj_denom <- as.formula(formula_str_denom)
  
  # Aggregate
  denominatorAgg <- aggregate(formula_obj_denom, data = data, FUN = agg, ...)
  
  # Merge aggregations
  
  rateAgg <- merge(theAgg, denominatorAgg, by = c(by, "class_year") , all = TRUE)
  
  # Calculate rate
  
  rateAgg$rate <- rateAgg[,variable]/rateAgg[,denominator_variable]
  
  # merge in feature map
  if(by == "course") {
    rateAgg <- merge(rateAgg, featureMap, by = "course", all.x = TRUE)
  } else {
    rateAgg <- merge(rateAgg, featureMap, by.x = by, by.y = "by", all.x = TRUE)
  }
  
  rateAgg <- rateAgg[order(rateAgg$class_year),]
  
  # Erase features not specified in the featureMap
  rateAgg <- rateAgg[complete.cases(theAgg),]
  
  plot(median(rateAgg[,3]),
       xlim = range(rateAgg[,2]),
       ylim = range(rateAgg[,"rate"]), 
       xlab = "",
       ylab = "",
       xaxt = "n",
       # yaxt = "n",
       type = "n",
       las = 2,
       main = title
  )
  
  if(by == "course") {
    lapply(unique(rateAgg$course), function(crse){
      
      filter <- rateAgg[,1] == crse
      
      lines(y = rateAgg[,"rate"][filter],
            x = rateAgg[,2][filter],
            col = rateAgg[filter,"color"],
            lwd = rateAgg[filter,"lwd"],
            lty = rateAgg[filter,"lty"],
      )
      
    })
  } else {
    lapply(unique(rateAgg[,by]), function(by_value){
      
      filter <- rateAgg[,1] == by_value
      
      lines(y = rateAgg[filter,"rate"],
            x = rateAgg[filter,2],
            col = rateAgg[filter,"color"],
            lwd = rateAgg[filter,"lwd"],
            lty = rateAgg[filter,"lty"],
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
    
    forLegend <- unique(rateAgg[,c("course", "color", "lwd", "lty")])
    legend_params_default <- list(x = "topright",
                                  legend = gsub("MATH_","",forLegend[,"course"]),
                                  lty = forLegend[,"lty"],
                                  lwd = forLegend[,"lwd"],
                                  col = forLegend[,"color"],
                                  xpd = TRUE,
                                  inset = c(-0.15,0)
    )
  } else {
    forLegend <- unique(rateAgg[,c(by, "color", "lwd", "lty")])
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
  
  invisible(rateAgg)
  
  
}