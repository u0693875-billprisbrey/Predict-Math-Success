# courseScatter in plotly sandbox

# plotly
courseScatterPlotly <- function(
    data,
    clusterColumn = NA,
    showCourse = FALSE,
    ellipseFilter = NA,
    clusterFilter = NA,
    featureMaps = list(courseMap = NA,
                       yearMap = NA,
                       clusterMap = NA),
    dist_params = list(),
    hclust_params = list(),
    cutree_params = list(),
    ellipse_npoints = 50,
    plot_title = NULL,
    xaxis_title = "HSGPA",
    yaxis_title = "ACT MATH"
) {
  
  library(plotly)
  
  #############  
  ## CLUSTER ##
  #############  
  
  
  data$clust <- NA
  
  if (is.na(clusterColumn)) {
    for (yr in unique(data$class_year)) {
      yearFilter <- data$class_year == yr
      features <- data[yearFilter, c("HSGPA.median", "HSGPA.IQR", "ACTMATH.median", "ACTMATH.IQR")]
      
      theDistance <- do.call(dist, modifyList(list(x = features, method = "euclidean"), dist_params))
      theHclust <- do.call(hclust, modifyList(list(d = theDistance, method = "complete"), hclust_params))
      clusters <- do.call(cutree, modifyList(list(tree = theHclust, k = 3), cutree_params))
      
      data$clust[yearFilter] <- clusters
    }
  } else {
    data$clust <- data[, clusterColumn]
    clusters <- unique(data[, clusterColumn])
  }
  
  ##################
  ## FEATURE MAPS ##
  ##################
  
  if (any(is.na(featureMaps))) {
    
    if (is.na(featureMaps[["courseMap"]])) {
      mainCourses <- data.frame(
        color = c("steelblue4", "skyblue", "tan4", "goldenrod4", "rosybrown4",
                  "darkseagreen4", "lightgoldenrod4", "tan4", "thistle4", 
                  "lightskyblue4", "paleturquoise4", "plum4", "darkseagreen", "burlywood4"),
        course = c("MATH_1010", "MATH_1050", "MATH_1210", "MATH_1030", "MATH_1090",
                   "MATH_1070", "MATH_1220", "MATH_1080", "MATH_1060", "MATH_1310",
                   "MATH_2210", "MATH_990", "MATH_1100", "MATH_1250"),
        stringsAsFactors = FALSE
      )
      
      extraCourses <- setdiff(unique(data$course), mainCourses$course)
      if (length(extraCourses) > 0) {
        extraCourses <- data.frame(
          color = rep("darkorange3", length(extraCourses)),
          course = extraCourses,
          stringsAsFactors = FALSE
        )
        featureMaps[["courseMap"]] <- rbind(mainCourses, extraCourses)
      } else {
        featureMaps[["courseMap"]] <- mainCourses
      }
    }
    
    if (is.na(featureMaps[["yearMap"]])) {
      # Plotly symbols: circle, square, diamond, cross, x, triangle-up, etc.
      featureMaps[["yearMap"]] <- data.frame(
        symbol = c("circle", "square", "diamond", "triangle-up", "triangle-down",
                   "cross", "x", "star", "hexagon", "pentagon",
                   "circle-open", "square-open", "diamond-open", "triangle-up-open",
                   "triangle-down-open", "cross-open", "x-open", "star-open",
                   "hexagon-open", "pentagon-open", "circle-dot"),
        class_year = 2025:2005,
        stringsAsFactors = FALSE
      )
    }
    
    if (is.na(featureMaps[["clusterMap"]])) {
      colors <- c("darkorange", "steelblue", "purple3", "turquoise3", 
                  "magenta", "forestgreen", "brown", "pink", "sienna")
      featureMaps[["clusterMap"]] <- data.frame(
        color = colors[seq_along(unique(data$clust))],
        clust = unique(data$clust),
        stringsAsFactors = FALSE
      )
    }
  }
  
  # Merge maps to data
  data <- merge(data, featureMaps[["yearMap"]], by = "class_year")
  
  if (showCourse) {
    data <- merge(data, featureMaps[["courseMap"]], by = "course")
  } else {
    data <- merge(data, featureMaps[["clusterMap"]], by = "clust")
  }
  
  returnData <- data
  
  # Filter to cluster if specified
  if (!any(is.na(clusterFilter))) {
    data <- data[data$clust %in% clusterFilter, ]
  }
  
  ####################
  ## ELLIPSE HELPER ##
  ####################
  
  make_ellipse <- function(cx, cy, rx, ry, npoints = 50) {
    theta <- seq(0, 2 * pi, length.out = npoints)
    list(
      x = cx + rx * cos(theta),
      y = cy + ry * sin(theta)
    )
  }
  
  ##########  
  ## PLOT ##
  ##########  
  
  # Dynamic title
  if (is.null(plot_title)) {
    plot_title <- paste("Course medians in", paste(unique(data$class_year), collapse = ", "))
  }
  
  # Determine grouping variable for legend
  group_var <- if (showCourse) "course" else "clust"
  
  # Build base plot
  p <- plot_ly()
  
  # Add points by group (for proper legend)
  groups <- unique(data[[group_var]])
  
  for (g in groups) {
    gdata <- data[data[[group_var]] == g, ]
    
    p <- p %>% add_trace(
      data = gdata,
      x = ~HSGPA.median,
      y = ~ACTMATH.median,
      type = "scatter",
      mode = "markers",
      marker = list(
        color = gdata$color[1],
        symbol = gdata$symbol,
        size = 10,
        line = list(width = 1, color = "white")
      ),
      name = as.character(g),
      text = ~paste0(
        "Course: ", course, "<br>",
        "Year: ", class_year, "<br>",
        "HSGPA: ", round(HSGPA.median, 2), " (IQR: ", round(HSGPA.IQR, 2), ")<br>",
        "ACT Math: ", round(ACTMATH.median, 1), " (IQR: ", round(ACTMATH.IQR, 1), ")"
      ),
      hoverinfo = "text",
      legendgroup = as.character(g)
    )
  }
  
  #############
  ## ELLIPSE ##
  #############  
  
  if (all(is.na(ellipseFilter))) {
    ellipseFilter <- rep(TRUE, nrow(data))
  }
  
  ellipse_data <- data[ellipseFilter, ]
  
  if (nrow(ellipse_data) > 0) {
    for (i in seq_len(nrow(ellipse_data))) {
      ell <- make_ellipse(
        cx = ellipse_data$HSGPA.median[i],
        cy = ellipse_data$ACTMATH.median[i],
        rx = 0.5 * ellipse_data$HSGPA.IQR[i],
        ry = 0.5 * ellipse_data$ACTMATH.IQR[i],
        npoints = ellipse_npoints
      )
      
      p <- p %>% add_trace(
        x = ell$x,
        y = ell$y,
        type = "scatter",
        mode = "lines",
        line = list(color = ellipse_data$color[i], width = 1.5),
        showlegend = FALSE,
        hoverinfo = "skip"
      )
    }
  }
  
  ##############
  ## LAYOUT ##
  ##############
  
  p <- p %>% layout(
    title = list(text = plot_title, font = list(size = 18)),
    xaxis = list(
      title = xaxis_title,
      gridcolor = "white",
      zerolinecolor = "white"
    ),
    yaxis = list(
      title = yaxis_title,
      gridcolor = "white",
      zerolinecolor = "white"
    ),
    plot_bgcolor = "grey90",
    paper_bgcolor = "ivory",
    legend = list(
      x = 1.02,
      y = 1,
      bgcolor = "snow",
      bordercolor = "gray",
      borderwidth = 1
    ),
    hovermode = "closest"
  )
  
  # Return both plot and data
  structure(
    list(plot = p, data = returnData),
    class = "courseScatterPlotly"
  )
}

# Print method to display just the plot
print.courseScatterPlotly <- function(x, ...) {
  print(x$plot)
}


# original
courseScatter <- function(
    data,
    clusterColumn = NA,
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
    qrect_params = list(),
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
  # ellipseFilter isn't very intuitive and is difficult to make this work; needs some more thinking 
  
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
  
  if(is.na(clusterColumn)) {
    
    for(yr in unique(data$class_year)){
      
      yearFilter <- data$class_year == yr
      
      features <- data[yearFilter , c("HSGPA.median","HSGPA.IQR","ACTMATH.median","ACTMATH.IQR") ]
      
      theDistance <- do.call(dist, modifyList(list(x=features, method="euclidean"), dist_params))
      theHclust <- do.call(hclust, modifyList(list(d=theDistance, method = "complete"), hclust_params))
      clusters <- do.call(cutree, modifyList(list(tree=theHclust, k=3), cutree_params))
      
      data$clust[yearFilter] <- clusters
      
    }
  } else {
    
    data$clust <- data[,clusterColumn]
    clusters <- unique(data[,clusterColumn])
    
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
      
      colors <- c("darkorange", "steelblue",   "purple3", "turquoise3", "magenta", "forestgreen", "brown", "pink", "sienna")
      
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
  
  returnData <- data
  
  # Filter to cluster if specified
  
  if(!any(is.na(clusterFilter))) {
    data <- data[data$clust %in% clusterFilter, ]
  }
  
  ##########  
  ## PLOT ##
  ##########  
  
  incoming.par <- par(mar = c(5.1,4.1,4.1,2.1))
  on.exit(par(incoming.par))
  
  par_params_default <- list(mfrow=c(1,1), mar = c(0,2.5,3,7), oma = c(4,2,0,0), fg = "gray20", bg = "ivory", xpd=TRUE)  
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
    radius.x = 0.5*data$HSGPA.IQR[ellipseFilter],
    radius.y = 0.5*data$ACTMATH.IQR[ellipseFilter],
    col = NA,
    border = data$color[ellipseFilter] 
    
  )
  ellipse_params <- modifyList(default_ellipse_params, ellipse_params)
  do.call(DrawEllipse, ellipse_params)
  
  #########################
  ## QUARTILE RECTANGLES ##
  #########################
  
  # Instead of an ellipse around each point, this would plot a box 
  # I'd need to pass the quartiles in
  # An interesting alternative to the ellipse, but improved accuracy means loss of interpretability
  
  default_qrect_params <- list(
    xleft = data$HSGPA.Q.25[ellipseFilter],
    xright = data$HSGPA.Q.75[ellipseFilter],
    ybottom = data$ACTMATH.Q.25[ellipseFilter],
    ytop = data$ACTMATH.Q.75[ellipseFilter],
    col = NA,
    border = data$color[ellipseFilter]
  )
  
  qrect_params <- modifyList(default_qrect_params, qrect_params)
  do.call(rect, qrect_params)
  
  #  rect(xleft = data$HSGPA.Q1[i],
  #       xright = data$HSGPA.Q3[i],
  #       ybottom = data$ACTMATH.Q1[i],
  #       ytop = data$ACTMATH.Q3[i],
  #       border = data$color[i],
  #       col = NA)
  
  
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
  
  invisible(returnData)
  
}