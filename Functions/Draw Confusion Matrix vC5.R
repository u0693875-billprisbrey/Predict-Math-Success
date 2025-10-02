# Draw Confusion Matrix vC5

# Copied from "/home/Prisbrey/Projects/ST ANDRE/Course Feedback Jan 2023/Function scripts/Draw Confusion Matrix vC4.R"
# 17 Sept 2024

# Copied from "/home/bill/JoyofR/MVP/Rfiles/RsqlFunctionsC13.r"
# 29 April 2022

# vC5 restores parameter settings to whatever they were when the function was called

# Version C4 modifies some of the language on the confusion matrix

# Version C0 and onward adjusts this presentation to accommodate changing labels.
# The presentation of multiple classes is satisfactory:
# however X1 - X3 class labels is confusing.
# I'd like to be able to change the presentation labels
# without messing with the column labels

# Version C1 and onward gives the user the option of displaying percentage
# using row totals ("precision") or column totals ("recall") as the basis.
# I don't think the coloring using "precision" or rows is working in drawCM

dummyCM <- function(classCount = 3, balance = NA, accuracy = 0.8){
  # This function creates a dummy matrix with specified number of classes, class balance, and accuracy
  # where classCount is how many classes will appear in the confusion matrix
  # where balance is a vector to be used in sample as the class probabilities
  #       balance must be the same length as the number of classes.
  #       if balance = NA then it assumes balanced probabilities across the classes
  # where accuracy is the desired accuracy of the confusion matrix and is used to identify
  #   how much of the reference vector is scrambled to make the prediction vector
  # Examples: 
  #  dummyCM(classCount = 2, balance = c(0.2, 0.8))
  #  dummyCM(classCount = 5, balance = c(0.2, 0.2, 0.3, 0.1, 0.2), accuracy = 0.6)
  #  dummyCM(classCount = 5, balance = c(0.2, 0.2, 0.3, 0.1, 0.2), accuracy = 0.1)
  
  # This requires library(caret)
  
  if (any(is.na(balance))) {
    
    balance <- rep(1/classCount, classCount)
    
  }
  
  # Establish the reference vector
  #  reference <- factor(sample(c("Yes", rep("No", balance) ), 100, replace=TRUE ), levels = c("Yes","No"))
  
  letterClasses <- LETTERS[1:classCount] # define the classes
  
  reference <- factor(sample(letterClasses, 100, replace=TRUE, prob = balance), levels = letterClasses)
  
  # Create a prediction vector
  
  prediction <- reference # identify the prediction as identical to the reference
  swapCount <- round(length(reference) * (1-accuracy)) # identify how many values will be swapped to achieve the randomness target
  toSwap <- sample(1:length(reference), swapCount, replace = FALSE) # identify random index numbers of positions to swap
  
  # loop I guess.  Is there a lapply solution, maybe?
  
  for (letter in letterClasses) {
    
    suppressWarnings(
      prediction[toSwap][reference[toSwap] == letter] <- sample(letterClasses[letterClasses != letter]) # sample something else
    )
    
    # it throws a warning but table(prediction[toSwap], reference[toSwap]) is pretty much exactly what I want
    # warnings are now suppressed
  }
  
  cm <- confusionMatrix(prediction, reference, 
                        mode = "everything")
  
  
  return(cm)
  
}

changeDisplay <- function(cm, nameReplacement) {
  # this function does two things:
  #  (1)  Changes the display row and column names
  #  (2)  Changes the confusion matrix order
  
  # it returns the confusion matrix table with the
  # desired display names and order
  
  # where cm is a confusion matrix
  # where nameReplacement is a matrix like
  # nameReplacement <- cbind(original = c("C","B","A"), display = c("Charlie", "Bob", "Ann"))
  # note that nameReplacement has to match AND be in the correct order!
  
  theTable <- cm$table
  
  # match the replacement order
  replacementOrder <- match(nameReplacement[,"original"], colnames(theTable))
  
  # create the replacement vector, matching the order
  replacementVector <- replace(colnames(theTable), replacementOrder,
                               nameReplacement[,"display"])
  
  # replace the row and columns
  colnames(theTable) <- replacementVector
  rownames(theTable) <- replacementVector
  
  # put the table in the desired order
  theTable <- theTable[replacementOrder, replacementOrder]
  
  return(theTable)
  
}

drawCM <- function(cm, 
                   title = "Confusion Matrix", 
                   fillColor = rgb(0/255,34/255,64/255), 
                   fontColor = "gray90", 
                   percentage = FALSE,
                   basis = "recall",
                   metrics = NA,
                   metricsClass = NA, 
                   nameMatrix = NA) {
  # recommend fillColor = rgb(0/255,34/255,64/255) and fontColor = "gray90"
  #        or fillColor = "white"  or "ivory"      and fontColor = "gray20"
  
  # Cobalt background is #00240 or rgb(0,34,64) for the dark blue color
  #193853 or rgb(25,56,83) for the lighter blue color (behind this font)
  
  # This handles up to 20 classes o.k.
  # the labels work up to about 10 with a single letter class label
  
  
  
  # where cm is a confusion matrix output
  # where nameMatrix describes different display names 
  # for the display.
  # It is defined as nameMatrix <- cbind(original = c("C","B","A"), display = c("Charlie", "Bob", "Ann"))
  # where it must align with the column names already in the 
  # confusion matrix AND it must show the desired display order (left to right and top to bottom.)
  
  # where basis (formerly color.or.percent.basis) is one of "all", "precision", "recall", "row", or "column".  It defines
  # how the percentage and color gradation will be calculated.  "precision" and "row" have the same result,
  # an "recall" and "column" have the same result.  Default is "all", and if percentage = FALSE then
  # it will only affect the color.
  
  # Establish incoming graphical parameters
  incomingPar <- par()
  
  # Exclude read-only parameters
  incomingPar <- incomingPar[!names(incomingPar) %in% c("cin", "cra", "csi", "cxy", "din", "page")]
  
  
  
  if (is.na(metrics)) { metrics <- c("Precision", "Recall",
                                     "Pos Pred Value", "Neg Pred Value",
                                     "Sensitivity", "Specificity",         
                                     "Prevalence", "Detection Prevalence")     
  
  # "F1", # "Detection Rate", "Balanced Accuracy" 
  }
  
  if (!is.na(nameMatrix[1])) {theTable <- changeDisplay(cm = cm, nameReplacement = nameMatrix) } else {theTable <- cm$table}  # assign for additional manipulation
  
  
  # reverse the cm$table if needed for a 2-class matrix
  if (any(colnames(theTable) %in% c("No","Yes","Negative","Positive") ) ) {
    
    if (all(colnames(theTable) == c("No","Yes")) ) {
      theTable <- theTable[c(2,1), c(2,1)] #reverse things to put positive in the upper left position
    }
    
    if (all(colnames(theTable) == c("Negative","Positive")) ) {
      theTable <- theTable[c(2,1), c(2,1)] #reverse things to put positive in the upper left position
    }
  }
  
  
  # Establish the base for percentages and coloring
  # toggle with basis from one of ("precision", "row", "recall", "column", "all")
  
  total <- sum(theTable)
  res <- as.numeric(t(theTable))
  
  
  if (tolower(basis) %in% c("precision", "row")) {prediction.total <- rowSums(theTable); 
  percentage.denominator <- rep(prediction.total, each = length(prediction.total))
  color.denominators <- rep(prediction.total, times = length(prediction.total))
  basis.subtitle <- "Color or percentage is precision, or row total." 
  }
  if (tolower(basis) %in% c("recall", "column")) {actual.total <- colSums(theTable); 
  percentage.denominator <- rep(actual.total, times = length(actual.total))
  color.denominators <- rep(actual.total, times = length(actual.total))
  basis.subtitle <- "Color or percentage is recall, or column total."
  } # coloring is now based on recall as a default setting
  
  if (tolower(basis) %in% c("all")) {actual.total <- colSums(theTable); 
  percentage.denominator <- total;
  color.denominators <- total # rep(actual.total, times = length(actual.total));
  basis.subtitle <- "Color or percentage is recall, or column total."
  }
  
  
  # Establish subtitles
  
  # ALL
  if (tolower(basis) %in% c("all") & percentage == TRUE) {
    basis.subtitle <- "Color shows alphabet"
  }
  
  if (tolower(basis) %in% c("all") & percentage == FALSE) {
    basis.subtitle <- "Color shows recall, or does it?"
  }
  
  # PRECISION OR ROW
  if (tolower(basis) %in% c("precision", "row") & percentage == TRUE) {
    basis.subtitle <- "Color and percent shows precision (using row totals)"
  }
  
  if (tolower(basis) %in% c("precision", "row") & percentage == FALSE) {
    basis.subtitle <- "Color shows precision"
  }
  
  # RECALL OR COLUMN
  if (tolower(basis) %in% c("recall", "column") & percentage == TRUE) {
    basis.subtitle <- "Color and percent shows recall (using column totals)"
  }
  
  if (tolower(basis) %in% c("recall", "column") & percentage == FALSE) {
    basis.subtitle <- "Color shows recall"
  }
  
  # if (tolower(basis) == "all") {true.positives <- colSums(theTable); denominator <- total}
  
  # Generate color gradients. Palettes come from RColorBrewer.
  #   the greens get a little darker than I'd like, and the reds will disappear completely
  #   esp on unbalanced data.
  #   but it's definitely a 90% solution, so I am going to accept this for now
  greenPalette <- c("#F7FCF5","#E5F5E0","#C7E9C0","#A1D99B","#74C476","#41AB5D","#238B45","#006D2C","#00441B")
  redPalette <- c("#FFF5F0","#FEE0D2","#FCBBA1","#FC9272","#FB6A4A","#EF3B2C","#CB181D","#A50F15","#67000D")
  getColor <- function (greenOrRed = "green", amount = 0, denominator = total) {
    if (amount == 0)
      return("#FFFFFF")
    palette <- greenPalette
    if (greenOrRed == "red")
      palette <- redPalette
    colorRampPalette(palette)(100)[10 + ceiling(70 * amount / denominator)]
  }
  
  # set the basic GOLDEN RATIO layout
  # Golden rectangle
  layout(matrix(c(1,1,2,3), nrow = 2, ncol = 2), 
         heights = c(1,0.618),
         widths = c(1,0.618)
  )
  par(bg = fillColor)
  par(mar=c(2,2,2,2))
  plot(c(100, 345), c(300, 450), type = "n", xlab="", ylab="", xaxt='n', yaxt='n')
  box(which = "plot", lty = "solid", col = fontColor)
  title(title, cex.main=1.5, col.main = fontColor)
  
  # create the matrix 
  classes = colnames(theTable) # identify the classes
  
  classCount <- length(classes) # count of the number of classes
  spacing <-20/classCount       # determine the spacing side
  
  availableWidth <- 190 - ((classCount - 1) * spacing) # figure out the available width
  width <- floor(availableWidth / classCount)          # create the width of the squares
  
  availableHeight <- 125 - ((classCount - 1) * spacing) # figure out the available height
  height <- floor(availableHeight / classCount)         # create the height of the squares 
  
  x1.point <- 150 # top left anchor point
  y1.point <- 430 # top left anchor point
  
  rectangle.vector <- c(0, rep(1:classCount,each=2)) # these are the coefficients to multiply by the width or height to position the rectangle
  rectangle.vector <- rectangle.vector[-length(rectangle.vector)] # remove the last position
  spacing.vector <- rep(0:(classCount-1),each=2) # these are the coefficients to multiply by the spacing to position the rectangles
  
  x.points <- x1.point + rectangle.vector*width + spacing.vector*spacing # these are the x positions 
  y.points <- y1.point - rectangle.vector*height - spacing.vector*0.5*spacing # these are the y positions
  
  position.frame <- data.frame(xOdd = rep(seq(from = 1, to = 2*classCount-1, by = 2), times = classCount),
                               yOdd = rep(seq(from = 1, to = 2*classCount-1, by = 2) , each = classCount),
                               xEven = rep(seq(from = 2, to = 2*classCount, by = 2), times = classCount),
                               yEven = rep(seq(from = 2, to = 2*classCount, by = 2) , each = classCount)
  ) # create a frame with the combinations of the points needed to create the rectangles
  
  # actually draw the rectangles, moving through the position frame row by row
  
  classVector <- (1:classCount)-1 # used in calculating the "true positive" or diagonals
  diagonals <- 1 + classVector*(classCount + 1) # these are the indexes of the diagonal values or the true positives
  # true.positives <- colSums(theTable) # this will be the reference for the colors # determined earlier
  # color.denominators <- rep(true.positives, times = classCount) # each = classCount
  
  for (i in 1:nrow(position.frame)) {
    
    
    if (i %in% diagonals) {boxColor <- "green"} else {boxColor <- "red"}
    
    rect(x.points[position.frame[i,1]], y.points[position.frame[i,2]], x.points[position.frame[i,3]], y.points[position.frame[i,4]], col= getColor(boxColor, res[i], denominator = color.denominators[i] ) )
    
    # sample(c("green", "red", "purple", "yellow", "orange"))
    
  }
  
  # Add the labels
  
  # Axis names
  text(245, 450, 'Actual', cex=1.3, font=2, col = fontColor)
  
  # basis subtitle
  text(245, 443, basis.subtitle, cex=1.1, font=4, col = fontColor )
  
  
  text(115, 370, 'Predicted', cex=1.3, srt=90, font=2, col = fontColor)
  
  # Class labels
  odds <- seq(from = 1, to = 2*classCount-1, by = 2)
  counter <- 0
  for (i in odds){
    
    counter <- counter + 1
    text( ((x.points[i] + x.points[i+1])/2), y.points[1]+5, classes[counter], cex=1.2, col = fontColor) # columns across the top
    text( x.points[1]-10, ((y.points[i] + y.points[i+1])/2), classes[counter], cex=1.2, col = fontColor) # rows down the side
    
  }
  
  
  # add in the cm results
  if(percentage == FALSE){
    
    cex.size <- 6/classCount # this shrinks it waaaay too fast
    
    row.counter <- 0
    res.counter <- 0
    for (i in 1:classCount){ # building it row by row
      row.counter <- row.counter + 1
      
      y.coordinate <-  (y.points[odds[row.counter]] + y.points[odds[row.counter]+1]) / 2
      
      
      for (j in odds){ # moves horizontally across the row # odds is defined earlier
        res.counter <- res.counter + 1
        text( ((x.points[j] + x.points[j+1])/2), y.coordinate, res[res.counter], cex=cex.size, col = fillColor, font = 2) # labels
      } 
      
    }
    
    # wow...it looks really good!
  }
  
  if(percentage == TRUE){
    
    res.percent <- paste(round(100*res/percentage.denominator, 1), "%", sep="" ) # convert to percent of total
    
    cex.size <- 6/classCount # this shrinks it waaaay too fast
    
    row.counter <- 0
    res.counter <- 0
    for (i in 1:classCount){ # building it row by row
      row.counter <- row.counter + 1
      
      y.coordinate <-  (y.points[odds[row.counter]] + y.points[odds[row.counter]+1]) / 2
      
      
      for (j in odds){ # moves horizontally across the row # odds is defined earlier
        res.counter <- res.counter + 1
        text( ((x.points[j] + x.points[j+1])/2), y.coordinate, res.percent[res.counter], cex=cex.size, col = fillColor, font = 2) # labels
      } 
      
    }
  }
  
  # add in the metrics
  
  # one difference is that cm$byClass is a vector for a 2x2 and a matrix for anything larger
  # so if cm$byClass is a 2x2 then use  names(cm$byClass[1])
  # I am also going to need to define which class the metrics are for
  
  if (any(class(cm$byClass) == "matrix")) {metricNames <- colnames(cm$byClass)} else {metricNames <- names(cm$byClass)}
  
  if (is.na(metricsClass) & any(class(cm$byClass) == "matrix")) {metricsClass <- colnames(theTable)[1] }
  
  if (any(class(cm$byClass) == "matrix")) {metricTitle <- paste("Metrics: ", metricsClass) } else { metricTitle <- "Metrics" }
  
  plot(c(100, 0), c(100, 0), type = "n", xlab="", ylab="", main = metricTitle, xaxt='n', yaxt='n', col.main = fontColor)
  box(which = "plot", lty = "solid", col = fontColor)
  
  # metrics
  
  # transfer metricsClass back into original names
  
  if (any(!is.na(nameMatrix))) {metricsClass <- nameMatrix[nameMatrix[,"display"] == metricsClass, "original"] }
  
  # if it's a 2x2 and the metrics are a vector
  
  if (any(class(cm$byClass) == "numeric")) {
    
    text(65, 93, metrics[1], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 93, round(as.numeric(cm$byClass[metrics[1]]), 3), cex=1.2, col = fontColor)
    
    text(65, 81, metrics[2], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 81, round(as.numeric(cm$byClass[metrics[2]]), 3), cex=1.2, col = fontColor)
    
    text(65, 69, metrics[3], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 69, round(as.numeric(cm$byClass[metrics[3]]), 3), cex=1.2, col = fontColor)
    
    text(65, 57, metrics[4], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 57, round(as.numeric(cm$byClass[metrics[4]]), 3), cex=1.2, col = fontColor)
    
    text(65, 45, metrics[5], cex=1.2, font=2, adj = c(1, 0.5), col = fontColor )
    text(85, 45, round(as.numeric(cm$byClass[metrics[5]]), 3), cex=1.2, col = fontColor)
    
    text(65, 33, metrics[6], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 33, round(as.numeric(cm$byClass[metrics[6]]), 3), cex=1.2, col = fontColor)
    
    text(65, 21, metrics[7], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 21, round(as.numeric(cm$byClass[metrics[7]]), 3), cex=1.2, col = fontColor)
    
    #text(65, 25, names(cm$byClass[8]), cex=1.2, font=2, adj = c(1,0.5) )  # Prevalence
    #text(85, 25, round(as.numeric(cm$byClass[8]), 3), cex=1.2)
    
    #text(65, 15, names(cm$byClass[9]), cex=1.2, font=2, adj = c(1,0.5) ) # Detection Rate
    #text(85, 15, round(as.numeric(cm$byClass[9]), 3), cex=1.2)
    
    #text(65, 5, names(cm$byClass[11]), cex=1.2, font=2, adj = c(1,0.5) )
    text(65, 9, metrics[8], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 9, round(as.numeric(cm$byClass[metrics[8]]), 3), cex=1.2, col = fontColor)
    
  }
  
  # if there are more than two classes
  
  if (any(class(cm$byClass) == "matrix")) {
    
    
    text(65, 93, metrics[1], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 93, round(cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""), row.names(cm$byClass)), metrics[1] ], 3), cex=1.2, col = fontColor)
    
    text(65, 81, metrics[2], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 81, round(cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""), row.names(cm$byClass)), metrics[2] ], 3), cex=1.2, col = fontColor)
    
    text(65, 69, metrics[3], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 69, round(cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""), row.names(cm$byClass)), metrics[3]], 3), cex=1.2, col = fontColor)
    
    text(65, 57, metrics[4], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 57, round(cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""), row.names(cm$byClass)), metrics[4] ], 3), cex=1.2, col = fontColor)
    
    text(65, 45, metrics[5], cex=1.2, font=2, adj = c(1, 0.5), col = fontColor )
    text(85, 45, round(cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""), row.names(cm$byClass)), metrics[5] ], 3), cex=1.2, col = fontColor)
    
    text(65, 33, metrics[6], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 33, round(cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""), row.names(cm$byClass)), metrics[6]], 3), cex=1.2, col = fontColor)
    
    text(65, 21, metrics[7], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 21, round(cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""), row.names(cm$byClass)), metrics[7]], 3), cex=1.2, col = fontColor)
    
    #text(65, 25, names(cm$byClass[8]), cex=1.2, font=2, adj = c(1,0.5) )  # Prevalence
    #text(85, 25, round(as.numeric(cm$byClass[8]), 3), cex=1.2)
    
    #text(65, 15, names(cm$byClass[9]), cex=1.2, font=2, adj = c(1,0.5) ) # Detection Rate
    #text(85, 15, round(as.numeric(cm$byClass[9]), 3), cex=1.2)
    
    #text(65, 5, names(cm$byClass[11]), cex=1.2, font=2, adj = c(1,0.5) )
    text(65, 9, metrics[8], cex=1.2, font=2, adj = c(1,0.5), col = fontColor )
    text(85, 9, round(cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""), row.names(cm$byClass)), metrics[8]], 3), cex=1.2, col = fontColor)
    
  }
  
  # add in the accuracy information
  plot(c(100, 0), c(100, 0), type = "n", xlab="", ylab="", main = "Accuracy", xaxt='n', yaxt='n', col.main = fontColor)
  box(which = "plot", lty = "solid", col = fontColor)
  text(10, 85, names(cm$overall[1]), cex=1.5, font=2, adj = c(0,0.5), col = fontColor )
  text(80, 85, round(as.numeric(cm$overall[1]), 3), cex=1.4, col = fontColor)
  
  text(10, 65, "95% CI", cex=1.25, font=1, adj = c(0,0.5), col = fontColor)
  text(80, 65, paste("(", round(as.numeric(cm$overall[3]), 2), " - ", round(as.numeric(cm$overall[4]), 2), ")", sep="" ), cex=1.10, col = fontColor, adj = c(0.5, 0.5))
  
  text(10, 45, "P-Value", cex=1.25, font=1, adj = c(0,0.5), col = fontColor )
  text(80, 45, round(as.numeric(cm$overall[6]), 3), cex=1.10, col = fontColor)
  
  
  text(10, 15, names(cm$overall[2]), cex=1.5, font=2, adj = c(0,0.5), col = fontColor )
  text(80, 15, round(as.numeric(cm$overall[2]), 3), cex=1.4, col = fontColor)
  
  #  text(60, 20, "No Infor. Rate", cex=1.25, font=1, adj = c(1,0.5), col = fontColor )
  #  text(80, 20, round(as.numeric(cm$overall[5]), 3), cex=1.2, col = fontColor)
  
  #  text(70, 5, "P-Value [Acc > NIR]", cex=1.25, font=1, adj = c(1,0.5), col = fontColor )
  #  text(85, 5, round(as.numeric(cm$overall[6]), 3), cex=1.2, col = fontColor)
  
  # restore layout defaults
  # requires  .pardefault <- par() to be run at the start of the session 
  # par(.pardefault)
  
  # restore graphical parameters
  par(incomingPar)
  
}

drawGuide <- function(title = "How to interpret", fillColor = rgb(0/255,34/255,64/255), fontColor = "gray90") {
  # recommend fillColor = rgb(0/255,34/255,64/255) and fontColor = "gray90"
  #        or fillColor = "white"  or "ivory"      and fontColor = "gray20"
  
  # Cobalt background is #00240 or rgb(0,34,64) for the dark blue color
  #193853 or rgb(25,56,83) for the lighter blue color (behind this font)
  
  # Establish incoming graphical parameters
  incomingPar <- par()
  
  # Exclude read-only parameters
  incomingPar <- incomingPar[!names(incomingPar) %in% c("cin", "cra", "csi", "cxy", "din", "page")]
  
  
  # create a dummy confusionMatrix to build
  cm <- confusionMatrix(factor(sample(c("Yes","No"), 100, replace=TRUE ), levels = c("Yes","No")), 
                        factor(sample(c("Yes","No"), 100, replace=TRUE ), levels = c("Yes","No")), 
                        mode = "everything")
  
  total <- sum(cm$table)
  res <- as.numeric(cm$table)
  
  # Generate color gradients. Palettes come from RColorBrewer.
  greenPalette <- c("#F7FCF5","#E5F5E0","#C7E9C0","#A1D99B","#74C476","#41AB5D","#238B45","#006D2C","#00441B")
  redPalette <- c("#FFF5F0","#FEE0D2","#FCBBA1","#FC9272","#FB6A4A","#EF3B2C","#CB181D","#A50F15","#67000D")
  getColor <- function (greenOrRed = "green", amount = 0) {
    if (amount == 0)
      return("#FFFFFF")
    palette <- greenPalette
    if (greenOrRed == "red")
      palette <- redPalette
    colorRampPalette(palette)(100)[10 + ceiling(90 * amount / total)]
  }
  
  # set the basic GOLDEN RATIO layout
  # Golden rectangle
  layout(matrix(c(1,1,2,3), nrow = 2, ncol = 2), 
         heights = c(1,0.618),
         widths = c(1,0.618)
  )
  par(bg = fillColor)
  par(mar=c(2,2,2,2))
  
  #####
  #####
  # define the metrics
  
  plot(c(100, 0), c(100, 0), type = "n", xlab="", ylab="", xaxt='n', yaxt='n', col.main = fontColor)
  box(which = "plot", lty = "solid", col = fontColor)
  title(title, cex.main=1.5, col.main = fontColor)
  text(3, 99, "Sensitivity:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(37, 99, "How many of the actual positives", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 95.5, "were predicted or identified?", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)     
  text(37, 92, "TP/(TP+FN)", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  
  text(3, 86, "Specificity:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(37, 86, "How many of the actual negatives", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 82.5, "were predicted or identified?", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 79, "TN/(TN+FP)", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  
  text(3, 73, "Positive Predictive Value:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(37, 69.5, "The percent of predicted positives", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 66, "that are actually positive.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 62.5, "TP/(TP+FP)", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  
  text(3, 56, "Negative Predictive Value:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(37, 52.5, "The percent of predicted negatives", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 49, "that are actually negative.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 45.5, "TN/(TN+FN)", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  
  text(3, 39.5, "Precision:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(37, 39.5 , "How many of the positives", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 36, "are actually positive?", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor) 
  text(37, 32.5, "TP/(TP+FP)", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)   
  
  text(3, 26.5, "Recall:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(37, 26.5, "How many of the actual positives", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 23, "were predicted or identified?", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor) 
  text(37, 19.5, "TP/(TP+FN)", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  
  text(3, 13.5, "F1:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(37, 13.5, "Balances precision and recall.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(37, 10, "One is a perfect score.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor) 
  
  text(3, 4, "Balanced Accuracy:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(23.5, 0.5, "An average of Sensitivity and Specificity.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  
  
  #####
  #####
  # define the accuracy metrics
  plot(c(100, 0), c(100, 0), type = "n", xlab="", ylab="", main = "Accuracy", xaxt='n', yaxt='n', col.main = fontColor)
  box(which = "plot", lty = "solid", col = fontColor)
  
  text(3, 99, "Accuracy:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(6, 93, "The proportion of correct", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(6, 87, "predictions.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(6, 81, "(TP + TN)/(Total)", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)     
  
  text(3, 71, "95% CI:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(6, 65, "The range of likely Accuracy", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(6, 59, "values.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  
  text(3, 49, "P-Value:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(6, 43, "The chance Accuracy", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(6, 37, "is random.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor)
  text(6, 31, "Less than 0.05 is good.", cex= 1.0, font = 1, adj = c(0,0.5),  col = fontColor) 
  
  text(3, 21, "Kappa:", cex=1.2, font = 2, adj =c(0, 0.5),  col = fontColor)
  text(6, 15, "How much better than random", cex= 0.9, font = 1, adj = c(0,0.5),  col = fontColor)
  text(6, 9, "is the model performance?", cex= 0.9, font = 1, adj = c(0,0.5),  col = fontColor)
  text(6, 3, "One is a perfect score.", cex= 0.9, font = 1, adj = c(0,0.5),  col = fontColor)
  
  #####
  #####
  # create the confusion matrix 
  plot(c(100, 345), c(300, 450), type = "n", xlab="", ylab="", xaxt='n', yaxt='n')
  box(which = "plot", lty = "solid", col = fontColor)
  title("Confusion Matrix", cex.main=1.5, col.main = fontColor)
  
  classes = colnames(cm$table)
  rect(180, 405, 240, 360, col=getColor("green", res[1]))
  text(210, 415, classes[1], cex=1.2, col = fontColor)
  rect(250, 405, 310, 360, col=getColor("red", res[3]))
  text(280, 415, classes[2], cex=1.2, col = fontColor)
  text(130, 360, 'Predicted', cex=1.3, srt=90, font=2, col = fontColor)
  text(245, 442.5, 'Actual', cex=1.3, font=2, col = fontColor)
  rect(180, 310, 240, 355, col=getColor("red", res[2]))  ## 350 to 360 to 365
  rect(250, 310, 310, 355, col=getColor("green", res[4]))
  text(165, 382.5, classes[1], cex=1.2, srt=90, col = fontColor)
  text(165, 332.5, classes[2], cex=1.2, srt=90, col = fontColor)
  
  # add in the cm results
  text(210, 382.5, "TP", cex=1, font=2, col=fillColor)
  text(210, 332.5, "FN", cex=1, font=2, col=fillColor)
  text(280, 382.5, "FP", cex=1, font=2, col=fillColor)
  text(280, 332.5, "TN", cex=1, font=2, col=fillColor)
  
  #  rect(150, 430, 240, 370, col=getColor("green", res[1]))
  #  text(195, 435, classes[1], cex=1.2, col = fontColor)
  #  rect(250, 430, 340, 370, col=getColor("red", res[3]))
  #  text(295, 435, classes[2], cex=1.2, col = fontColor)
  #  text(125, 370, 'Predicted', cex=1.3, srt=90, font=2, col = fontColor)
  #  text(245, 450, 'Actual', cex=1.3, font=2, col = fontColor)
  #  rect(150, 305, 240, 365, col=getColor("red", res[2]))
  #  rect(250, 305, 340, 365, col=getColor("green", res[4]))
  #  text(140, 400, classes[1], cex=1.2, srt=90, col = fontColor)
  #  text(140, 335, classes[2], cex=1.2, srt=90, col = fontColor)
  
  # add in the cm results
  #  text(195, 400, "TP", cex=1, font=2, col=fillColor)
  #  text(195, 335, "FN", cex=1, font=2, col=fillColor)
  #  text(295, 400, "FP", cex=1, font=2, col=fillColor)
  #  text(295, 335, "TN", cex=1, font=2, col=fillColor)
  
  # restore layout defaults
  # requires  .pardefault <- par() to be run at the start of the session 
  # par(.pardefault)
  
  # restore graphical parameters
  par(incomingPar)
  
}
