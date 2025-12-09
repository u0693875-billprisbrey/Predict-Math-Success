# courseScatter sandbox

# Let's build the cluster inside the plot function
# I want extensibility and control
# Col and shape by whichever I specify
# Use the feature map colors that I've already created

# Needs to be plotly
# Ellipses don't look right when I am filtering on cluster and ellipse  
# Course colors may be off (if I ever use that)
# A side-by-side with an arrow (this again?) of low-and-high (?)

# But first, I need to calculate the distance between the students and these courses in st dev
# And, add students to this plot

# showCourse = TRUE doesn't look right/colors look off
# I have no ability to filter by cluster # FIXED
# And I really want this by plotly
# Add axis and labels # DONE 
# I want to fix the automatic scaling of the axis # DONE
# It would be nice to only plot some of the ellipses # DONE
# It would be nice to plot both high and low per course
# I need to add the axis  # DONE

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
  #                          IQR = IQR(x)
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
      
    mainCourses <- data.frame(color = c( c("lightsteelblue", "powderblue", "beige", "moccasin", "rosybrown"), c( 
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

# default_par_params

# Filter
# plotFilter <- gofer$class_year == 2024 # & gofer$clust == 1

# plot(x= gofer$HSGPA.median[plotFilter],
#     y = gofer$ACTMATH.median[plotFilter],
#     pch = 19,
#     col = c("dodgerblue","gold4","forestgreen","purple", "red", "aquamarine3" )[gofer$clust[plotFilter]],
#     xlim = c(3,4),
#     ylim = c(10,36)
# )


# plot(median(theAgg[,3]),
#     xlim = range(theAgg[,2]),
#     ylim = range(theAgg[,3]), 
#     xlab = "",
#     ylab = "",
#     xaxt = "n",
#     # yaxt = "n",
#     type = "n",
#     las = 2,
#     main = title
# )

