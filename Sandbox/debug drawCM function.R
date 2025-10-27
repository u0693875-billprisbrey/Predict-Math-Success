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

