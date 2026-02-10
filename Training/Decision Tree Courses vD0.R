# Decision Tree Courses vD0

model_version <- "vD0"

# PURPOSE:  
# This performs a training model using classification and xgboost.
# It trains on only the first math classes for first time freshman.
# It uses data derived by Bill Prisbrey.
# It follows vC1, and vJ0 for the iterative annual aspect 
# The goal is to predict the first term math course instead of the grade. 
#   In order to include z-scores and "dist" metrics, 
#    I create a grid with all possible student x course combinations
#    I predict on "enroll/not enroll" binary column
#   The prep from vH4 is copied
#   Target courses are at the top 90th (not 85th) cumulative instead of 85th (??? Might change this)

# As previously,
#    It iteratively adds a year to the training set and predicts the next year
#    The filter on recent courses is removed

library(caret)
library(xgboost)
library(lubridate)
library(MLmetrics)

##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))
creditLoad <- readRDS(here::here("Data", "Freshman_career_credit_load.rds"  ))

print("You made it past loading")

##########
## PREP ##
##########

# convert to numeric
mathCourses$CATNBR <- as.numeric(as.character(mathCourses$CATNBR))

# identify unique classes
mathCourses$class <- paste(mathCourses$TERM, mathCourses$SUBJECT_CD, mathCourses$CATNBR, mathCourses$SECTION, sep= "_")

# identify unique courses
mathCourses$course <- paste(mathCourses$SUBJECT_CD, mathCourses$CATNBR, sep="_")

# re-arrange order
mathCourses <- mathCourses[,c("TERM", "course", "class", "CATNBR", "EMPLID", "TITLE", "SECTION",  "UNITS", "GRADE", "GRADEGPA", "INSTEMPLID", "INSTNAME", "EOTDATE", colnames(mathCourses)[!colnames(mathCourses) %in% c("TERM", "course", "EOTDATE", "CATNBR", "EMPLID", "TITLE", "SECTION",  "UNITS", "GRADE", "GRADEGPA", "INSTEMPLID", "INSTNAME") ] )   ]

## IDENTIFY FIRST TERM OF MATH CLASSES ##

# Identify minimum term per student
minTerm <- aggregate(TERM ~ EMPLID, data = mathCourses, min, na.rm = TRUE)
minTerm$reference <- paste(minTerm$EMPLID, minTerm$TERM, sep = "_") # combine for reference
mathCourses$minTerm <- paste(mathCourses$EMPLID, mathCourses$TERM, sep = "_") %in% minTerm$reference # identify courses in minimum terms 

firstTermFilter <- mathCourses$minTerm == TRUE

## identify popular, high volume courses
# mostPopCourses <- c("MATH_1050", "MATH_1210", "MATH_1010", "MATH_1220", "MATH_1030",
#                    "MATH_1090", "MATH_1060", "MATH_2210", "MATH_1070", "MATH_2250") # identified via hierarchical clustering later in this report


# mostPopFilter <- mathCourses$course %in% mostPopCourses

mathLabFilter <- 
  mathCourses$GRADE %in% c(" ", NA) &
  mathCourses$UNITS == 0

# popCourses <- mathCourses[mostPopFilter &  !mathLabFilter,] 

firstCourses <- mathCourses[firstTermFilter & !mathLabFilter,]

# prepare FTF data
# Remove students with multiple values in FTF data (multiple COHORT_DT values)

theDupes <- table(ftfData$EMPLID) |>
  (\(x){x[x>1]})() |>
  names()

duplicateFilter <- ftfData$EMPLID %in% theDupes

# Merge in FTF data
student_demographics <- c("SEX",
                          "FIRST_GEN_STATUS_CD",
                          "ETHNICITY",
                          "RESSTAT",
                          "FA_PELL",
                          "AGE"
)
academic_prep <- c(
  "APCREDIT",
  "HSGPA",
  "HSPRIVATE",
  "HONORS",
  "ACTCOMP",
  "ACTENGL",
  "ACTMATH",
  "ACTSCI" #,
  #  SATMATH, # leaving out SAT because it's a smaller proportion
  #  SATVERBAL,
  #  SATWRTG        
)

firstCourses <- merge(firstCourses, ftfData[, c("EMPLID","COHORT_DT", student_demographics, academic_prep)], by = "EMPLID",  all.x = TRUE)

# Merge in credit load
names(creditLoad)[names(creditLoad) == "UNITS"] <- "load"

firstCourses <- merge(firstCourses, creditLoad, by = c("TERM", "EMPLID"), all.x = TRUE)

# Freshman year
firstCourses$cohort_year <- year(firstCourses$COHORT_DT)

# Class year
firstCourses$class_year <- year(firstCourses$EOTDATE)

# Year to class
firstCourses$yr_diff <- time_length(interval(firstCourses$COHORT_DT, firstCourses$EOTDATE), "years")

# Season

# Align season
season_map <- c("4" = "spring", "6" = "summer", "8" = "fall")

# Extract 4th digit and map
firstCourses$season <- season_map[substr(firstCourses$TERM, 4, 4)]

# Course levels column
firstCourses$course_level <- firstCourses$CATNBR %/% 1000

# filter out courses at 3000+ level
course_levelFilter <- firstCourses$course_level < 3

# filter out courses that aren't recent
course_by_year <- table(firstCourses[course_levelFilter, c("course","class_year")  ]) |> as.data.frame()
recentCourses <- unique(course_by_year$course[course_by_year$class_year %in% c(2021:2025) & course_by_year$Freq > 0])
recent_filter <- firstCourses$course %in% recentCourses

# Course clusters by volume
courseClusters <- table(firstCourses$course[recent_filter]) |>
  (\(x){x[order(x, decreasing = TRUE)]})() |>
  dist() |>
  hclust() |>
  cutree(k=2)

firstCourses$vol_cluster <- ifelse(firstCourses$course %in% names(courseClusters)[courseClusters == 1], "hi_vol","low_vol")

# Course filter
higherVolCourses <- table(firstCourses$course[recent_filter]) |> 
  (\(x){x[order(x, decreasing = TRUE)]})() |> 
  proportions() |> 
  cumsum() |>
  (\(x){names(x[x<0.9]) })()

courseFilter <- firstCourses$course %in% higherVolCourses

# > higherVolCourses
# [1] "MATH_1010" "MATH_1050" "MATH_1210" "MATH_1030" "MATH_1090" "MATH_1060"
# [7] "MATH_1070" "MATH_1220" "MATH_1080"

# Age buckets
firstCourses$age_cut <- cut(firstCourses$AGE, breaks = c(0,17,18,19,21,100))

# Age filter
ageFilter <- firstCourses$AGE > 11

print("Prep complete")

## GRADE TRANSFORMATIONS ## 

# convert grade value names to values compatible with R naming

clean_grade <- function(x) {
  x <- as.character(x)
  x <- gsub("-", "_minus", x)   # replace '-' with '_minus'
  x <- gsub("\\+", "_plus", x)  # replace '+' with '_plus'
  x <- gsub(" ", "missing", x)        # replace spaces with '_'
  
  return(x)
}

firstCourses$cleanGrade <- clean_grade(firstCourses$GRADE) 

firstCourses$cleanGrade <- factor(firstCourses$cleanGrade,
                                  levels = c(
                                    "A", "A_minus", "B_plus", "B", "B_minus", "C_plus",
                                    "C", "C_minus", "D_plus", "D", "D_minus",   
                                    "E", "EU", "W", "I", "CR",  "NC", "V", 
                                    "missing", NA
                                  )
)

# RARE AND UNUSUAL VALUES

rareGrades <- firstCourses$cleanGrade %in% c("missing", "V", "I", "NC", "CR") # , "EU" convert EU to 0

# WITHDRAW
firstCourses$wdraw_binary <- NA
firstCourses$wdraw_binary <- ifelse(firstCourses$GRADE == "W","withdraw","not_withdraw")


# Combine grades
# BINARY
firstCourses$grade_binary <- NA
hiFilter <- firstCourses$GRADE %in% c("A", "A-", "B+", "B", "B-", "C+", "C", "C-")
loFilter <- firstCourses$GRADE %in% c( "D+", "D", "D-", "E", "EU" ) 
firstCourses$grade_binary[hiFilter] <- 1
firstCourses$grade_binary[loFilter] <- 0

#popCourses$grade_binary <- factor(popCourses$grade_binary,
#                                  levels = c("hi_grade", "low_grade"))


# TRINARY
firstCourses$grade_trinary <- NA
hiFilter <- firstCourses$GRADE %in% c("A", "A-", "B+", "B", "B-")
medFilter <- firstCourses$GRADE %in% c("C+", "C", "C-")
loFilter <- firstCourses$GRADE %in% c( "D+", "D", "D-", "E", "EU" ) 
firstCourses$grade_trinary[hiFilter] <-  2 #"hi_grade"
firstCourses$grade_trinary[medFilter] <- 1 # "med_grade"
firstCourses$grade_trinary[loFilter] <-  0 #"low_grade"


# popCourses$grade_trinary <- factor(popCourses$grade_trinary,
#                                  levels = c("hi_grade", "med_grade", "low_grade"))

# QUAD
firstCourses$grade_quad <- NA
hiFilter <- firstCourses$GRADE %in% c("A")
medPlusFilter <- firstCourses$GRADE %in% c("A-", "B+", "B", "B-")
medMinusFilter <- firstCourses$GRADE %in% c("C+", "C", "C-")
loFilter <- firstCourses$GRADE %in% c( "D+", "D", "D-", "E", "EU" ) 
firstCourses$grade_quad[hiFilter] <- 3 # "hi_grade"
firstCourses$grade_quad[medPlusFilter] <- 2 # "medPlus_grade"
firstCourses$grade_quad[medMinusFilter] <- 1 #"medMinus_grade"
firstCourses$grade_quad[loFilter] <-0 # "low_grade"

# popCourses$grade_quad <- factor(popCourses$grade_quad,
#                                  levels = c("hi_grade", 
#                                             "medPlus_grade",
#                                             "medMinus_grade",
#                                             "low_grade"))

# popCourses$cleanGrade[popCourses$cleanGrade %in% c("D_plus", "D", "D_minus") ] <- "D"

## CONVERT APCREDIT NA VALUES to ZERO ##  

firstCourses$APCREDIT[is.na(firstCourses$APCREDIT)] <- 0

print("Transformations complete")

#################
## PRE-PROCESS ##
#################


# Select columns

# colnames(popCourses)

keepColumns <- c(
  "EMPLID"                      ,
  #   "TERM"                        ,
  "course"                      ,
  #   "class"                       ,
  #   "CATNBR"                      ,
  #   "TITLE"                       ,
  #   "SECTION"                     ,
  #   "UNITS"                       ,
  #   "GRADE"                       ,
  #   "GRADEGPA"                    ,
  #   "INSTEMPLID"                  ,
  #   "INSTNAME"                    ,
  #   "EOTDATE"                     ,
  #   "ACADYR"                      ,
  #   "TERMEXTRACT"                 ,
  #   "MAX_SNAP"                    ,
  #   "CENSUSDATE"                  ,
  #   "ALT_ID"                      ,
  #   "FULLNAME"                    ,
  #   "STUDENTCAREER"               ,
  #   "SUBJECT_CD"                  ,
  #   "SUBJECT_NAME"                ,
  #   "SUBJECT_LONG"                ,
  #   "SUBJECT_ACAD_ORG_CD"         ,
  #   "CATNBR2"                     ,
  #   "CLASSNBR"                    ,
  #   "OFFERINGNBR"                 ,
  #   "SESSIONCODE"                 ,
  #   "COURSECAREER"                ,
  #   "SCHEDFLAG"                   ,
  #   "WAUTOENRL"                   ,
  #   "AUTOENROLL"                  ,
  #   "COMPONENT"                   ,
  #   "GENED"                       ,
  #   "VARCREDIT"                   ,
  #   "CONTRACT"                    ,
  #   "DIRECTPAY"                   ,
  #   "CORRESPONDENCE"              ,
  #   "ONLINECOURSE"                ,
  #   "IVC"                         ,
  #   "IVC_HYBRID"                  ,
  #   "COURSE_MODALITY"             ,
  #   "INSTRUCTION_MODE"            ,
  #   "TELECOURSE"                  ,
  #   "STUDYABROAD"                 ,
  #   "EDNET"                       ,
  #   "HYBRIDCOURSE"                ,
  #   "COURSE_LEVEL"                ,
  #   "USHE_COURSE_LEVEL"           ,
  #   "FISCAL_YEAR_OF_STARTDT"      ,
  #   "VP"                          ,
  #   "VP_SHORT"                    ,
  #   "VP_FORMAL"                   ,
  #   "ACAD_COLLEGE_CD"             ,
  #   "COLLEGE"                     ,
  #   "COLLEGE_SHORT"               ,
  #   "COLLEGE_FORMAL"              ,
  #   "ACAD_COLLEGE_REG_SUPP"       ,
  #   "ACAD_COLLEGE_TYPE"           ,
  #   "ACAD_COLLEGE_CIP_CD"         ,
  #   "ACAD_DEPARTMENT_CD"          ,
  #   "DEPARTMENT"                  ,
  #   "DEPARTMENT_SHORT"            ,
  #   "DEPARTMENT_FORMAL"           ,
  #   "ACAD_DEPARTMENT_REG_SUPP"    ,
  #   "ACAD_DEPARTMENT_TYPE"        ,
  #   "ACAD_DEPARTMENT_CIP_CD"      ,
  #   "ACAD_DIVISION_CD"            ,
  #   "DIVISION"                    ,
  #   "DIVISION_SHORT"              ,
  #   "DIVISION_FORMAL"             ,
  #   "ACAD_DIVISION_REG_SUPP"      ,
  #   "ACAD_DIVISION_TYPE"          ,
  #   "ACAD_DIVISION_CIP_CD"        ,
  #   "VP_CD"                       ,
  #   "COLLEGE_CD"                  ,
  #   "DEPARTMENT_CD"               ,
  #   "DIVISION_CD"                 ,
  #   "ROLLUP_SORT_ORDER"           ,
  #   "PS_ACAD_ORG"                 ,
  #   "PS_ACAD_GROUP"               ,
  #   "CAMPUS"                      ,
  #   "COURSE_CAMPUS"               ,
  #   "USHE_SITE_TYPE_CD"           ,
  #   "USHE_SITE_TYPE"              ,
  #   "ONOFFCAMPUS"                 ,
  #   "COURSELOCATION"              ,
  #   "CONTACTMINUTES"              ,
  #   "TEAMTAUGHT"                  ,
  #   "XLIST"                       ,
  #   "BEGTIME1"                    ,
  #   "BEGTIME2"                    ,
  #   "BEGTIME3"                    ,
  #   "DAYS1"                       ,
  #   "DAYS2"                       ,
  #   "DAYS3"                       ,
  #   "ENDTIME1"                    ,
  #   "ENDTIME2"                    ,
  #   "ENDTIME3"                    ,
  #   "CLASSLOC1"                   ,
  #   "CLASSLOC2"                   ,
  #   "CLASSLOC3"                   ,
  #   "CLASSLOCBUILDNAME1"          ,
  #   "CLASSLOCBUILDROOM1"          ,
  #   "CLASSLOCBUILDNAME2"          ,
  #   "CLASSLOCBUILDROOM2"          ,
  #   "CLASSLOCBUILDNAME3"          ,
  #   "CLASSLOCBUILDROOM3"          ,
  #   "STARTDT"                     ,
  #   "ENDDT"                       ,
  #   "BUDGETCODE"                  ,
  #   "LINEITEM"                    ,
  #   "SERVICELEARNING"             ,
  #   "XLIST_ID"                    ,
  #   "COMBINEDID"                  ,
  #   "USHE_ACADYR"                 ,
  #   "USHE_TERM"                   ,
  #   "TERM2"                       ,
  #   "ORG_EFFDT"                   ,
  #   "CLASSENROLLMENTCAPACITY"     ,
  #   "ROOM_MAX_1"                  ,
  #   "ROOM_MAX_2"                  ,
  #   "ROOM_MAX_3"                  ,
  #   "TERM_NBR"                    ,
  #   "CLASS_ATTR_LIST"             ,
  #   "EXCLUDE_BUDGET_SCH"          ,
  #   "SPR_CORRECTION_NOT_USHE_FLAG",
  #   "Section Divider: OLD"        ,
  #   "SUBJECTCOLL"                 ,
  #   "SUBJECT"                     ,
  #   "class.1"                     ,
  #   "COHORT_DT"                   ,
  "SEX"                         ,
  "FIRST_GEN_STATUS_CD"         ,
  "ETHNICITY"                   ,
  "RESSTAT"                     ,
  "FA_PELL"                     ,
  # "AGE"                         ,
  "APCREDIT"                    ,
  "HSGPA"                       ,
  "HSPRIVATE"                   ,
  "HONORS"                      ,
  "ACTCOMP"                     ,
  "ACTENGL"                     ,
  "ACTMATH"                     ,
  "ACTSCI"                      ,
  #  "load"                        ,
  "cohort_year"                 ,
  "class_year"                  ,
  "yr_diff"                     ,
  "season"                      ,
  # "course_level"                ,
  #  "vol_cluster"                 ,
  "age_cut"                     ,
  "cleanGrade"                  
#  "HSGPA.z"                     , # not yet available
#  "ACTMATH.z"                   , # not yet available
#  "dist"                          # not yet available  
  #   "wdraw_binary"                ,
  #   "grade_binary"                ,
  #   "grade_trinary"               ,
  #   "grade_quad" 
)

# target_classes <- c("GRADEGPA",  "grade_binary", "grade_trinary", "grade_quad") # "wdraw_binary",
target_classes <- c("GRADEGPA") #, "grade_quad")

# stop("Work on keep columns")

###########
## CLEAN ##
###########

cleanFilters <- !is.na(firstCourses$cleanGrade) & 
  !rareGrades
#!popCourses$cleanGrade %in% c("missing", "V", "I", "NC", "CR") 

# Outlier filters
zeroHSGPA_filter <- firstCourses$HSGPA == 0
highLoad_filter <- firstCourses$load > quantile(firstCourses$load, 0.99)
preMath_filter <- firstCourses$yr_diff < -0.5 # since all cohort dates start in September, I wanted to includ the summer before the cohort date
outlierFilters <- !zeroHSGPA_filter & !highLoad_filter & !preMath_filter

# withdrawFilter
withdrawFilter <- firstCourses$cleanGrade != "W"

# Combined filters
cleanData <- firstCourses[cleanFilters & outlierFilters & course_levelFilter & recent_filter & ageFilter & withdrawFilter,]
cleanData <- cleanData[!is.na(cleanData$cleanGrade),]
cleanData$cleanGrade <- droplevels(cleanData$cleanGrade)

cleanData$course <- factor(cleanData$course)
cleanData$ETHNICITY <- factor(cleanData$ETHNICITY)

# stop("Cleaning finished!")

#################
## EXPAND GRID ##
#################

# First I'll do all years, all employees, all courses
# and then I'll trust the merge to reduce it.

# length(unique(cleanData$class_year)) * length(unique(cleanData$EMPLID)) * length(unique(cleanData$course))
# [1] 32851896

# I guess I'll do that by year  

theYears <- unique(cleanData$class_year)

optionsList <- lapply(theYears, function(yr){
  
  theCourses <- unique(cleanData$course[cleanData$class_year == yr & !is.na(cleanData$class_year)])
  theIDs <- unique(cleanData$EMPLID[cleanData$class_year == yr & !is.na(cleanData$class_year)])  
  
  courseGrid <- expand.grid(theCourses, theIDs)
  
  courseGrid$class_yr <- rep(yr, nrow(courseGrid))
  
  return(courseGrid)
  
})

sapply(optionsList, nrow) |> sum() # 1151372 # Big, but doable

optionsGrid <- do.call(rbind, optionsList)
colnames(optionsGrid) <- c("course_option","EMPLID","class_year")

optionsData <- merge(cleanData[,keepColumns], optionsGrid, by = c("EMPLID", "class_year"), all = TRUE)

optionsData$enroll <- ifelse(optionsData$course == optionsData$course_option, "enroll","not_enroll")
optionsData$enroll <- factor(optionsData$enroll)

# Filter to high volume courses

optionsData_top90 <- optionsData[ (optionsData$course  %in% higherVolCourses & optionsData$course_option %in% higherVolCourses),]


#############################################  
## DISTANCE FROM MEDIAN SUCCESSFUL STUDENT ##  
#############################################  

hiGrades <- aggregate(cbind(HSGPA,ACTMATH) ~ course + class_year, 
                      data = cleanData[cleanData$GRADEGPA > 2.4,], function(x){
                        c(median = median(x),
                          IQR = IQR(x),
                          stdev = sd(x),
                          Q = quantile(x, probs = c(0.1,0.25,0.5,0.75,0.9), na.rm = TRUE),
                          count = length(x)
                        ) 
                      }) |>
  (\(x){
    do.call(data.frame,x)
  })()  

# stop("Good to here")

# Merge to cleanData 
# ADJUSTMENT -- I need to shift this by one year! 

hiGrades$class_year_shift <- hiGrades$class_year + 1

# saveRDS(hiGrades, here::here("Data", "hiGrades from vH4.rds"))

optionsData_top90 <- merge(optionsData_top90, hiGrades[,c("course",  "class_year_shift", "ACTMATH.median", "ACTMATH.stdev", "HSGPA.median", "HSGPA.stdev", "HSGPA.count")], by.x = c("course_option", "class_year"), by.y = c("course","class_year_shift"),  all.x=TRUE)

# These are the years with NA values--

# > table(optionsData_top90_2$class_year[is.na(optionsData_top90_2$ACTMATH.median)], useNA = "always")

#  2005  2006  2007  2012  <NA> 
#  10104  1626  1633  2185     0 

# In the first place, there's no 2004 values to put onto 2005
# And I am assuming that there wasn't a prior course for the other years
# (Or those were the first years those courses were offered)  



# Calculate distance as a z-score

# I need to take care to shift this in my training data
# 

optionsData_top90$ACTMATH.z <- (optionsData_top90$ACTMATH - optionsData_top90$ACTMATH.median)/optionsData_top90$ACTMATH.stdev
optionsData_top90$HSGPA.z <- (optionsData_top90$HSGPA - optionsData_top90$HSGPA.median)/optionsData_top90$HSGPA.stdev



optionsData_top90$dist <- sqrt(
  ((optionsData_top90$ACTMATH - optionsData_top90$ACTMATH.median)/optionsData_top90$ACTMATH.stdev)^2 +
    ((optionsData_top90$HSGPA - optionsData_top90$HSGPA.median)/optionsData_top90$HSGPA.stdev)^2
)

# Check
# View(cleanData[cleanData$HSGPA.z < -20 & !is.na(cleanData$HSGPA.z) & !is.na(cleanData$ACTMATH), c(keepColumns,"HSGPA.z", "HSGPA.median", "HSGPA.stdev", "HSGPA.count", "class_year.y" )])

# recall that the aggregate used in hiGrades uses complete cases for both columns 

# Calcualte the distance  
# courseProximity$dist <- sqrt(
#  ((courseProximity$ACTMATH - courseProximity$ACTMATH.median)/courseProximity$ACTMATH.stdev)^2 +
#    ((courseProximity$HSGPA - courseProximity$HSGPA.median)/courseProximity$HSGPA.stdev)^2
# )

# stop("Starting to train")

###########
## SPLIT ##
###########

# Initially take a subset
set.seed(123)

# let's loop through this 

xgb.set.config(verbosity = 0)   # 0 = silent, 1 = warning, 2 = info, 3 = debug

# 2007:2025
lapply(2007:2024,  function(testYear){ 
  
  target <- "enroll"
  
  # lapply(target_classes,
  
  
  #       function(target){
  
  # establish sample of complete cases
  popSample <- optionsData_top90[,-which(colnames(optionsData_top90) %in% c("EMPLID", "course", "cleanGrade", "HSGPA.stdev", "HSGPA.median", "HSGPA.count", "ACTMATH.stdev", "ACTMATH.median", "ACTMATH.count"  ) )] |> # no sampling index 
    (\(x){x[complete.cases(x),]})()
  
  
  ## SPLIT ##  
  
  # Use cleanGrade to partition on, but drop it for the test and train data
  # trainIndex <- createDataPartition(popSample$cleanGrade, p = 0.8, list = FALSE)
  # trainData <- popSample[trainIndex, c(target, keepColumns[-which(keepColumns %in% "cleanGrade")])]
  # testData  <- popSample[-trainIndex, c(target, keepColumns[-which(keepColumns %in% "cleanGrade")])]
  
  
  # trainIndex <- createDataPartition(popSample$course_target, p = 0.8, list = FALSE)
  
  trainIndex <- which(popSample$class_year < testYear)
  testIndex <- which(popSample$class_year == testYear)
  
  
  trainData <- popSample[trainIndex, ]
  testData  <- popSample[testIndex, ]
  # testData  <- popSample[-trainIndex, c(target, keepColumns)]
  
  # trainData$course_target <- droplevels(trainData$course_target)
  
  #       return(list(training = trainData, testing = testData))
  
  theData <- list(training = trainData, testing = testData)
  
  #     })
  
  saveRDS(theData, here::here("Data","Over Time", paste("Decision Tree Courses", model_version,  testYear, "Data.rds")))
  
  
  ## TRAIN ##  
  
  startTime <- Sys.time()
  print(paste("STARTING", testYear, "AT", startTime,"\n"))
  print(paste("STARTING", testYear, "AT", startTime,"\n"))
  print(paste("STARTING", testYear, "AT", startTime,"\n"))
  
  #   # Establish weighting
  #   
  #   targetCol <- trainData[[target]]
  #   
  #   # Compute inverse-frequency weights automatically
  #   weights_map <- 1 / prop.table(table(targetCol))
  #   weights_map <- weights_map / mean(weights_map)  # normalize around 1
  #   weights <- weights_map[as.character(targetCol)]
  #   
  #   # regression
  #   ctrl <- trainControl(
  #     method = "cv",
  #     number = 5,
  #     summaryFunction = defaultSummary
  #   )
  
  #     xgb_grid <- expand.grid(
  #       nrounds = 600,          # scale boosting rounds for dataset size
  #      eta = c(0.05, 0.1),     # conservative learning rates
  #       max_depth = c(4, 6),    # tree depth
  #      gamma = 0,              # minimal regularization
  #       colsample_bytree = 0.8, # prevent overfitting
  #       min_child_weight = 1,
  #       subsample = 0.8
  #     )
  
  ctrl <- trainControl(
    method = "cv",
    number = 5,
    classProbs = TRUE,
    summaryFunction = twoClassSummary,  # multiClassSummary,
    savePredictions = "final",  
    verboseIter = FALSE  
  )     
  
  # Define the tuning grid with multi-class objective
  xgb_grid <- expand.grid(
    nrounds = c(100, 200),
    max_depth = c(3, 6),
    eta = c(0.05, 0.2),
    gamma = 0,
    colsample_bytree = c(0.8),
    min_child_weight = 1,
    subsample = c(0.8)
  )
  
  # Calculate class weights
  # class_weights <- 1 / table(trainData[[target]])
  # class_weights <- class_weights / sum(class_weights) * length(class_weights)
  
  # Then add to train():
  # weights = class_weights[trainData[[target]]]
  
  #   if (is.numeric(targetCol)) {
  #     # regression
  #     ctrl <- trainControl(
  #       method = "cv",
  #       number = 5,
  #       summaryFunction = defaultSummary
  #     );
  #   } else if (is.factor(targetCol) && nlevels(targetCol) == 2) {
  #     # binary classification
  #     ctrl <- trainControl(
  #       method = "cv",
  #       number = 5,
  #       classProbs = TRUE,
  #       sampling = "smote",
  #       summaryFunction = twoClassSummary
  #     )
  #   } else {
  #     # multiclass classification
  #     ctrl <- trainControl(
  #       method = "cv",
  #       number = 5,
  #       classProbs = TRUE,
  #       summaryFunction = multiClassSummary
  #     )
  #   }
  
  
  
  fit <- 
    suppressWarnings(
      train(
        reformulate(".", response = target), 
        data = trainData,
        method = "xgbTree",
        trControl = ctrl,
        #preProcess = c("zv", "nzv"),
        preProcess = c("zv", "nzv", "center", "scale", "knnImpute"),
        tuneGrid = xgb_grid,
      #  objective = "multi:softprob",  
      #  num_class = length(unique(trainData[[target]])), 
      #  eval_metric = "mlogloss",
      #  metric = "Accuracy"
         metric = "ROC"
        
      )
    )
  
  endTime <- Sys.time()
  
  print(endTime-startTime)
  print(endTime-startTime)
  print(endTime-startTime)
  
  saveRDS(fit, here::here("Models", "Over Time", paste("Decision Tree Courses", model_version, testYear, "model.rds")))
  
  library(beepr)
  # beep(1); Sys.sleep(2); #beep(8); Sys.sleep(6); beep(0)
  
})
