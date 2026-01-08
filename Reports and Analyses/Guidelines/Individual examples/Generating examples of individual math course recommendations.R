# Generating individual math course recommendations
# 1.06.2025


# PURPOSE:  This document generates several examples of the 
# individual math course recommendations.

##########
## LOAD ## 
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
hiGrades <- readRDS(here::here("Data","hiGrades from vH3.rds"))

source(here::here("Functions", "Predict Math Success Functions.R"))

library(here)

#########################
## IDENTIFY CANDIDATES ##
#########################

# This section identifies EMPLID's of students who took math classes in 2024
# according to various criteria. 

# criteria <- list("elite" = !is.na(ftfData$ACTMATH) & ftfData$ACTMATH > 30 & ftfData$HSGPA > 3.93 & !is.na(ftfData$HSGPA),
#                 "advanced" = !is.na(ftfData$ACTMATH) &  ftfData$ACTMATH > 25 & ftfData$ACTMATH <= 30 & ftfData$HSGPA > 3.9 & ftfData$HSGPA <= 3.93 & !is.na(ftfData$HSGPA),
#                 "intermediate" = !is.na(ftfData$ACTMATH) & ftfData$ACTMATH > 23 & ftfData$ACTMATH <= 25 & ftfData$HSGPA > 3.8 & ftfData$HSGPA <= 3.9 & !is.na(ftfData$HSGPA),
#                 "basic" = !is.na(ftfData$ACTMATH) & ftfData$ACTMATH > 10 & ftfData$ACTMATH <= 23 & ftfData$HSGPA > 3.7 & ftfData$HSGPA <= 3.8 & !is.na(ftfData$HSGPA),
#                 "high" = !is.na(ftfData$ACTMATH) & ftfData$ACTMATH > 30 & ftfData$ACTMATH <= 36 & ftfData$HSGPA > 3.00 & ftfData$HSGPA <= 3.8 & !is.na(ftfData$HSGPA),
#                 "low"= !is.na(ftfData$ACTMATH) & ftfData$ACTMATH > 10 & ftfData$ACTMATH <= 20 & ftfData$HSGPA > 3.00 & ftfData$HSGPA <= 3.8 & !is.na(ftfData$HSGPA)
#                 )

# set.seed(42)
# candidates <- lapply(criteria, function(x) {
#  sample(ftfData$EMPLID[ftfData$TERM_YEAR == 2024 & x],1)
  
# })

# The following was developed in the template that is being called
candidates <- list("elite"
                   = "01494417",
                   
                   "advanced"
                   = "01439526",
                   
                   "intermediate"
                   = "01114185",
                   
                   "basic"
                   = "01494165",
                   
                   "high"
                   = "01495399",
                   
                   "low"
                   = "01446590")

#############
## INSPECT ##
#############

# sapply(candidates, function(x){x %in% tg2$EMPLID}) |> all()

# emplidFilter <- ftfData$EMPLID == candidates[[1]]

# xLim <- range(c(ftfData$HSGPA[emplidFilter], 3.6, 4.0))
# yLim <- range(c(ftfData$ACTMATH[emplidFilter]-1, 17, 36))

# courseScatter(hiGrades[hiGrades$class_year == 2023,], 
#              clusterColumn = "clust1",
#              ellipse_params = list(plot = FALSE),
#              qrect_params = list(border = NA),
#              legend_params = list(plot = FALSE),
#              plot_params = list(xlim = xLim, ylim = yLim),
#              mtext_params = list(side = c(1,2,3,3),
#                                  text = c("High School GPA","ACT Math", "Plotting individual students against incoming qualifications", "Median student achieving at least B- per course"),
#                                  font = c(1,1,2,3),
#                                  cex = c(1.3, 1.3, 1.75, 1.25),
#                                  line = c(2.3, 2.3, 1.25, 0.30)
#              )
#)

#points(x = ftfData$HSGPA[emplidFilter] ,
#       y = ftfData$ACTMATH[emplidFilter],
#       cex = 3,
#       pch = 13,
#       col = "gray10")

##########  
## KNIT ##  
########## 

lapply(seq_along(candidates), function(x){
  
  rmarkdown::render(
    input = here::here("Reports and Analyses","Guidelines", "Individual Math Course Recommendations.Rmd"),
    output_file = here::here("Reports and Analyses","Guidelines", "Individual examples", paste(names(candidates)[x], " example", " run A",".html", sep = "")),
    params = list(emplid = candidates[[x]])
                    )
})
