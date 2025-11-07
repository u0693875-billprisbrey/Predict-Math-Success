# Performance graphic sandbox
# I'll get there


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
  text(0.5, 0.5, "performance equals motivation x ability", 
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
  text(0.97, 0.30, 
       "Math ability \n (ACT MATH)", 
       cex = 1.5, 
       col = "white",
       adj = c(1,0))
  
  text(0.97, 0.15, 
       "Study ability \n (HS GPA)", 
       cex = 1.5, 
       col = "white",
       adj = c(1,0))
  
}
