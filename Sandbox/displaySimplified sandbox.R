# Simplified view

displaySimplified <- function(mainFont = "Bahnschrift", 
                            subFont = "Segoe UI",
                            textColor = "slateblue4",
                            arrowColor = "steelblue3",
                            rectColor = "bisque",
                            clusterColors = c("darkorange", "steelblue", "purple3", "turquoise3")){
  
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

  # Simplified findings
  text(0.02, 0.92, "Phase 2 sneak preview", 
       cex = 2.5, 
       col = textColor, 
       font = 2, 
       family = mainFont,
       adj = c(0,0))

  
  # Prior knowledge
  text(0.05, 0.8, "", 
       cex = 2, 
       col = textColor, 
       font = 2, 
       family = mainFont,
       adj = c(0,0))
  
  text(0.365, 0.7, "Test scores*", 
       cex = 1.381, 
       col = textColor, 
       font = 2, 
       family = subFont,
       adj = c(1,1))
 
  text(0.02, 0.025, 
       #"*Predictors of course selection are explored in Phase 2", 
       "*Phase 2 found that test scores predicted course selection",
       cex = 1.25, 
       col = textColor, 
       font = 3, 
       family = subFont,
       adj = c(0,0))
   
  text(0.98, 0.025, 
       #"*Predictors of course selection are explored in Phase 2", 
       "**Phase 1 finding",
       # "*Phase 1 found that high school GPA predicted performance",
       cex = 1.25, 
       col = textColor, 
       font = 3, 
       family = subFont,
       adj = c(1,0))  
  
  
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
  
  text(0.5375, 0.8, 
       c("\nElite","\n\n\nAdvanced","\n\n\n\n\nIntermediate","\n\n\n\n\n\n\nBasic"), 
       cex = 1.7, #  1.381, 
       col = rev(clusterColors),   #textColor, 
       font = 2, 
       family = subFont, 
       adj = c(0.5,1))  
  
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
       border = "gray50",
       lty = 2,
       lwd = 4,
       col = NULL)
  
  # rectangle text
  text(0.68, 0.22, "GRAY BOX",
       col = "grey50",
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
  
  
  text(0.71, 0.7, 
       "Hi. Sch. GPA**", 
       cex = 1.381, 
       col = textColor, 
       font = 2, 
       family = subFont,
       adj = c(0,1))
  
  
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