# Pipeline graphic

displayPipeline <- function(mainFont = "Bahnschrift", 
                            subFont = "Segoe UI",
                            textColor = "slateblue4",
                            arrowColor = "steelblue3",
                            rectColor = "bisque"){
  
  #  library(extrafont)
  #  loadfonts()
  
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