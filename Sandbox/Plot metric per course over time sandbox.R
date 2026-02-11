# Plot course metric sandbox
# Debugging formula used in "Evaluate Grade Decision Trees Over Time vQ0


plot_course_metric <- function(metric_df, metric_name = NULL) {
  library(plotly)
  
  # Get metric name from list if not provided
  if(is.null(metric_name)) {
    metric_name <- "Metric"
  }
  
  # Get courses and years
  courses <- rownames(metric_df)
  years <- as.numeric(colnames(metric_df))
  
  # Initialize plot
  p <- plot_ly()
  
  # Add a line for each course
  for(course in courses) {
    p <- p %>%
      add_trace(x = years,
                y = as.numeric(metric_df[course, ]),
                name = course,
                type = 'scatter',
                mode = 'lines+markers')
  }
  
  # Add layout
  p <- p %>%
    layout(title = paste(metric_name, "by Course Over Years"),
           xaxis = list(title = "Year"),
           yaxis = list(title = metric_name),
           hovermode = "closest")
  
  return(p)
}