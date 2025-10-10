# First math class sandbox
# 10.7.2025


# PURPOSE: The purpose of this sandbox is to identify the first math class per student. 

library(lubridate)

##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))


##########
## PREP ##
##########

# convert to numeric
mathCourses$CATNBR <- as.numeric(as.character(mathCourses$CATNBR))
mathCourses$TERM <- as.numeric(as.character(mathCourses$TERM))


# identify unique classes
mathCourses$class <- paste(mathCourses$TERM, mathCourses$SUBJECT_CD, mathCourses$CATNBR, mathCourses$SECTION, sep= "_")

# identify unique courses
mathCourses$course <- paste(mathCourses$SUBJECT_CD, mathCourses$CATNBR, sep="_")

## PUT TERMS IN ORDER ##  

termDates <- unique(mathCourses[,c("TERM","EOTDATE")])

TD <- termDates[order(termDates$EOTDATE),]

# I just needed to see that.  Terms are already in chronological order

# ok, let's do this

# 
minTerm <- aggregate(TERM ~ EMPLID, data = mathCourses, min, na.rm = TRUE)

# for checking
minTerm$reference <- paste(minTerm$EMPLID, minTerm$TERM, sep = "_")

# now --- do I merge this back in, or do an "%in%" check?

mathCourses$minTerm <- paste(mathCourses$EMPLID, mathCourses$TERM, sep = "_") %in% minTerm$reference

table(mathCourses$minTerm)
FALSE   TRUE 
140838  76607 

# now I should compare that to Whitney's data

# But this is a pretty straight-forward data reduction
# I should be able to run vF0, and honestly get that done tonight

########################
## COMPARE TO WH DATA ##
########################

library(readxl)
whData <- read_excel(here::here("Data", "WH Dataset - Math Placement Project - First Time Students from Fall 2021 - 2024 Cohorts and Their First Math Course 2025.09.30.xlsx"))

firstMath <- mathCourses[mathCourses$minTerm == TRUE,]

earlyTerms <- setdiff(unique(firstMath$TERM), unique(whData$FIRST_MATH_TERM)) |> (\(x){x[order(x)]})()
earlyCohorts <- "need to merge with ftfData and perform a setDiff"

recentMath <- firstMath[firstMath$TERM %in% earlyTerms, ]

# so recentMath should contain everything in whData, plus some math classes
# taken by earlier cohorts  

# Let's check some things

all(whData$EMPLID %in% recentMath$EMPLID) # FALSE
 # wow, ok.

all(whData$FIRST_MATH_COURSE_CATNBR %in% recentMath$CATNBR) # FALSE
 # let's see who that is

missingCATNBR <- setdiff(whData$FIRST_MATH_COURSE_CATNBR, recentMath$CATNBR)
[1] NA     "1215" "4100" "1035" "2271" "1105"
[7] "3220" "5000"

missingCATNBR <- setdiff(whData$FIRST_MATH_COURSE_CATNBR, recentMath$CATNBR) |>
  (\(x){x[!is.na(x)]})()

# Why wouldn't I have those?
library(skimr)
skim(whData[whData$FIRST_MATH_COURSE_CATNBR %in% missingCATNBR,])

# 358 rows
table(whData$FIRST_MATH_COURSE_CATNBR[whData$FIRST_MATH_COURSE_CATNBR %in% missingCATNBR])

> table(whData$FIRST_MATH_COURSE_CATNBR[whData$FIRST_MATH_COURSE_CATNBR %in% missingCATNBR])

# 1035 1105 1215 2271 3220 4100 5000 
# 95   43  193   23    1    1    2 

# These have "MATH" as their subject
unique(whData$FIRST_MATH_COURSE_SUBJECT_CD[whData$FIRST_MATH_COURSE_CATNBR %in% missingCATNBR])
# [1] "MATH"

# I guess I need to bring in ftfData to filter on that next ste

table(whData$COHORTTERM)
table(whData$COHORT)

# Ok, let's see if I can do this without merging

selectTerm <- unique(whData$COHORTTERM)
selectEmplid <- unique(ftfData$EMPLID[ftfData$COHORTTERM %in% selectTerm])

recentCohortMath <- firstMath[firstMath$EMPLID %in% selectEmplid, ]

# Ok, there we go
# almost identical

# I could run a model on that
# or just use Whitney's data

# How much time should I spend on figuring out the differences?

missingCATNBR <- setdiff(whData$FIRST_MATH_COURSE_CATNBR, recentCohortMath$CATNBR) |>
  (\(x){x[!is.na(x)]})()
# [1] "3150" "5110" "4200"

missingEMPLID <- setdiff(whData$EMPLID, recentCohortMath$EMPLID) |>
  (\(x){x[!is.na(x)]})()
# 3737

# WHOA ... shut the front door!

# let's see the aggregate

myAvg <- aggregate(GRADEGPA ~ CATNBR, recentCohortMath, mean)
whyAvg <- aggregate(GRADEGPA ~ CATNBR, whData, mean) # oh fer....

myStudentCount <- aggregate(EMPLID ~ CATNBR, recentCohortMath, length)
whStudentCount <- aggregate(EMPLID ~ FIRST_MATH_COURSE_CATNBR, whData, length)


missingCATNBR_from_WH <- setdiff(recentCohortMath$CATNBR, whData$FIRST_MATH_COURSE_CATNBR) |>
  (\(x){x[!is.na(x)]})()
# long list
# [1]  525  121  540   70  539  621  204  213
# [9]  532  230  514  207  206  980  490  219
# [17]  203  526  616  527  202  536   50  101
# [25]  100  209 3620  510  495  505   71  201
# [33]   15  529   13   60  218  160  500  205
# [41]   51   12   14  623  524  212  620  150
# [49]  221   91  276  159  535  310  614  214

# let's see if we have differences in student counts

countCompare <- merge(myStudentCount, whStudentCount, 
                      by.x = "CATNBR", 
                      by.y = "FIRST_MATH_COURSE_CATNBR",
                      all.x = TRUE)
countCompare$countDiff <- countCompare$EMPLID.y - countCompare$EMPLID.x

summary(countDiff)

# Wow, that's pretty different, don't you think?
Min.  1st Qu.   Median     Mean  3rd Qu. 
-2387.00    -8.00     1.00  -112.11     5.75 
Max.     NA's 
   69.00       56 
   
# This is worth digging into
# She\'s got an extra rule or filter or something...
# but why would she ever have more than I do, if that\'s the case ?

# I think I'll run models on both before trying to figure out the difference


   



