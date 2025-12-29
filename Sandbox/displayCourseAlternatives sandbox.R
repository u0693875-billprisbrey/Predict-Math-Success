# counterfactual sandbox
# display course alternatives


displayCourseAlternatives <- function(data,
                                      unid = NA,
                                      par_params = list(),
                                      plot_params = list(),
                                      rect_params = list(),
                                      axis_params = list(list()),
                                      point_params = list(
                                        list(),
                                        list() #,
                                        # list(),  
                                      ),
                                      legend_params = list(),
                                      mtext_params = list()
){
  
  # where data is trainingGround  
  
  
  incoming.par <- par(mar = c(4,2,2,1))
  on.exit(par(incoming.par))
  
  # randomly assign a unid if not specified
  
  if(is.na(unid)){
    unid <- sample(data[,"EMPLID"],1)
  }
  
  plotFilter <- data$EMPLID == unid
  
  # Plot parameters
  default_par_params <- list(mar=c(4,7,3,10), bg = "bisque", fg = "grey20")
  par_params <- modifyList(default_par_params, par_params)
  do.call(par, par_params)
  
  # Empty plot
  n_courses <- nlevels(data$course)   # number of courses
  
  # Establish the xlim range
  xLim <- range(data[plotFilter,c("pred.vH3", "GRADEGPA")], na.rm=TRUE) # "pred.vK0",
  
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
      x = data[plotFilter,"pred.vH3"],
      y = as.numeric(data[plotFilter, "course"]), 
      pch = 9, 
      col = "mediumpurple3"
    ),
    #    list(x = data[plotFilter,"pred.vK0"],
    #         y = as.numeric(data[plotFilter, "course"]), 
    #         pch = 1, 
    #         col = "seagreen"
    #    ),
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
                                col = c("mediumpurple3",  "darkorange2"), # "seagreen",
                                pch = c(9,1,13),
                                pt.lwd = c(1,1,2),
                                pt.cex = c(1,1,1.6),
                                legend = c("Predicted (vH3)",  "Actual"), # "No test score (vK0)",
                                xpd = TRUE,
                                inset = c(-0.50,0))
  legend_params <- modifyList(default_legend_params, legend_params)  
  do.call(legend, legend_params) 
  
  default_mtext_params <- list(
    side = c(1,3,3),
    text = c("GPA", unid,  "Grade predictions per course"),
    line = c(2.3, 1.2,  0.4),
    outer = c(FALSE, FALSE, FALSE),
    cex = c(1,1.25,0.95),
    font = c(1,2,2)
  )
  
  mtext_params <- modifyList(default_mtext_params, mtext_params)
  do.call(mtext, mtext_params)
  
}