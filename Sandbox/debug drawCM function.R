# Debug "drawCM"

source(here::here("Functions", "Draw Confusion Matrix vC6.R"))

twoClassDummy <- dummyCM(classCount = 2)
threeClassDummy <- dummyCM()

drawCM(twoClassDummy)
drawCM(threeClassDummy)

newTriple <- changeDisplay(threeClassDummy, cbind(original = c("C","B","A"), display = c("Charlie", "Bob", "Ann")))

drawCM(threeClassDummy, nameMatrix = cbind(original = c("A","B","C"), display = c("[0,5]", "(5,10]", "(10,20]")))

# that worked

drawCM(quad_cm,
       nameMatrix = cbind(original = c("[0.5,1.5]","(1.5,2.5]","(2.5,10]"), display = c("Low", "Med", "High")))

# o.k., I'm liking this!  Looking good!
# Now I need to update the project
# I guess it's time to make this into a package 

dummyCM(classCount  = 4,
        balance = c(0.4,0.2,0.2,0.1),
        accuracy =0.4) |>
  drawCM()

## Gotta figure out these:

> dummyCM(classCount = 3) |> drawCM(metrics = c("Recall", "Precision", "Neg Pred Value"), metricsClass = "A")
Error in cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""),  : 
   subscript out of bounds
                         
> # man, why?
> dummyCM(classCount = 3) |> drawCM(metrics = c("Recall", "Precision", "Neg Pred Value"), metricsClass = "A")
Error in cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""),  : 
    subscript out of bounds
                                                  
> dummyCM(classCount = 3) |> drawCM(metrics = c("Recall", "Precision", "Neg Pred Value"), metricsClass = "B")
        Error in cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""),  : 
       subscript out of bounds
                                                                         
> dummyCM(classCount = 3) |> drawCM(metrics = c("Recall", "Precision", "Neg Pred Value"), metricsClass = "C")
 Error in cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""),  : 
    subscript out of bounds
                                                                                                    
> dummyCM(classCount = 3) |> drawCM(metrics = c("Recall", "Precision", "Neg Pred Value"), metricsClass = NA)
    Error in cm$byClass[grep(paste("[[:punct:]] ", metricsClass, "$", sep = ""),  : 
   subscript out of bounds

# This fails:
dummyCM(classCount = 3) |> drawCM(metrics = c("Recall", "Precision", "Neg Pred Value"), metricsClass = "C")

# This is o.k. (it provides the default metrics list, which looks for 'any' NA values)
dummyCM(classCount = 3) |> drawCM(metrics = c("Recall", "Precision", NA, "Neg Pred Value"), metricsClass = "C")

