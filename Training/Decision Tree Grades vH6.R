# Decision Tree Grades vH6

model_version <- "vH6"

# PURPOSE:  
# This runs one training model using regression and xgboost.
# It trains on only the first math class for first time freshman.
# It uses data derived by Bill Prisbrey.
# It follows vH4, but with this adjustment:
#   It is identical to vH4 but uses xgboost directly and does not use "caret"
#   It uses a Bayesian optimization search. 
#   It is run in the new environment. 
#   of updated RStudio and R on the new laptop received in Feb 2026.
#  

library(xgboost)
library(lubridate)
library(rsample)
library(recipes)
library(rBayesianOptimization)

# devtools::install_github("AnotherSamWilson/ParBayesianOptimization")
library(ParBayesianOptimization)

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
  "course_level"                ,
  #  "vol_cluster"                 ,
  "age_cut"                     ,
  "cleanGrade"                  ,
  "HSGPA.z"                     ,
  "ACTMATH.z"                   ,
  "dist"
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

saveRDS(hiGrades, here::here("Data", paste("hiGrades from ", model_version, ".rds", sep="")) )

cleanData <- merge(cleanData, hiGrades[,c("course", "class_year", "class_year_shift", "ACTMATH.median", "ACTMATH.stdev", "HSGPA.median", "HSGPA.stdev", "HSGPA.count")], by.x = c("course", "class_year"), by.y = c("course","class_year_shift"),  all.x=TRUE)

# Calculate distance as a z-score

# I need to take care to shift this in my training data
# 

cleanData$ACTMATH.z <- (cleanData$ACTMATH - cleanData$ACTMATH.median)/cleanData$ACTMATH.stdev
cleanData$HSGPA.z <- (cleanData$HSGPA - cleanData$HSGPA.median)/cleanData$HSGPA.stdev



cleanData$dist <- sqrt(
  ((cleanData$ACTMATH - cleanData$ACTMATH.median)/cleanData$ACTMATH.stdev)^2 +
    ((cleanData$HSGPA - cleanData$HSGPA.median)/cleanData$HSGPA.stdev)^2
)

# Check
# View(cleanData[cleanData$HSGPA.z < -20 & !is.na(cleanData$HSGPA.z) & !is.na(cleanData$ACTMATH), c(keepColumns,"HSGPA.z", "HSGPA.median", "HSGPA.stdev", "HSGPA.count", "class_year.y" )])

# recall that the aggregate used in hiGrades uses complete cases for both columns 

# Calcualte the distance  
# courseProximity$dist <- sqrt(
#  ((courseProximity$ACTMATH - courseProximity$ACTMATH.median)/courseProximity$ACTMATH.stdev)^2 +
#    ((courseProximity$HSGPA - courseProximity$HSGPA.median)/courseProximity$HSGPA.stdev)^2
# )


# stop("Next step is the training loop")

###########
## TRAIN ##
###########


## PREP AND PARTITION ##

xgb.set.config(verbosity = 0)   # 0 = silent, 1 = warning, 2 = info, 3 = debug

set.seed(123)

target <- target_classes # throw-back to when I predicted against two variables

# establish sample of complete cases
popSample <-
  initial_split( 
  data = cleanData[  , c(target,keepColumns)],
  prop = 0.25,
  strata = "GRADEGPA"
  ) |> # 25% sampling index 
  training() |>
(\(x){x[complete.cases(x),]})()

trainIndex <- which(popSample$class_year < 2024)

trainData <- popSample[trainIndex, c(target, keepColumns[-which(keepColumns %in% c("cleanGrade","EMPLID") )])]
testData  <- popSample[-trainIndex, c(target, keepColumns[-which(keepColumns %in% c("cleanGrade", "EMPLID") )])]


theData <- list(training = trainData, testing = testData, trainID = popSample$EMPLID[trainIndex], testID = popSample$EMPLID[-trainIndex] )

saveRDS(theData, here::here("Data", paste("Decision Tree", model_version, target, "Data.rds")))

## PREPARE DM ##

xgb_prep <- recipe(GRADEGPA ~ ., data = trainData) |>
  step_mutate(
    SEX = as.integer(SEX == "M"),
    FIRST_GEN_Y = as.integer(FIRST_GEN_STATUS_CD == "Y"),
    FIRST_GEN_U = as.integer(FIRST_GEN_STATUS_CD == "U"),
    HSPRIVATE = as.integer(HSPRIVATE == "Y"),
    RESSTAT = as.integer(RESSTAT == "R")
  ) |>
  step_integer(all_nominal()) |>
  step_zv(all_predictors()) |>
  prep(training = trainData, retain = TRUE) |>
  bake(new_data=NULL)

X <- xgb_prep[setdiff(names(xgb_prep), "GRADEGPA")]
Y <- xgb_prep$GRADEGPA

dTrain <- xgb.DMatrix(data = X, label = Y)



## TRAIN ##  

startTime <- Sys.time()
print(paste("STARTING", target, "AT", startTime,"\n"))
print(paste("STARTING", target, "AT", startTime,"\n"))
print(paste("STARTING", target, "AT", startTime,"\n"))

# Establish weighting

# targetCol <- trainData[[target]]

# Compute inverse-frequency weights automatically
# weights_map <- 1 / prop.table(table(targetCol))
# weights_map <- weights_map / mean(weights_map)  # normalize around 1
# weights <- weights_map[as.character(targetCol)]


# Create Bayesian search function

xgb_cv_bayes <- function(eta, max_depth, min_child_weight, 
                         subsample, colsample_bytree,
                         gamma, lambda, alpha) {
  set.seed(123)
  m <- xgb.cv(
    data = dTrain,
    nrounds = 6000,
    early_stopping_rounds = 50,
    nfold = 10,
    verbose = 0,
    params = list(
      objective = "reg:squarederror",
      eta = eta,
      max_depth = as.integer(max_depth),
      min_child_weight = as.integer(min_child_weight),
      subsample = subsample,
      colsample_bytree = colsample_bytree,
      gamma = gamma,
      lambda = lambda,
      alpha = alpha
    )
  )
  
  list(
    Score = -min(m$evaluation_log$test_rmse_mean),  # negative because BayesianOptimization maximizes
    nrounds = which.min(m$evaluation_log$test_rmse_mean)
  )
}

# Define search bounds
bounds <- list(
  eta               = c(0.01, 0.3),
  max_depth         = c(2L, 8L),
  min_child_weight  = c(1L, 10L),
  subsample         = c(0.5, 1.0),
  colsample_bytree  = c(0.5, 1.0),
  gamma             = c(1e-6, 100),
  lambda            = c(0, 100),
  alpha             = c(1e-6, 100)
)

# Run Bayesian optimization
set.seed(123)
system.time({
  bayes_result <- bayesOpt(
    #BayesianOptimization(
    FUN = xgb_cv_bayes,
    bounds = bounds,
    initPoints = 10,
    #init_points = 10,    # random exploration before Bayesian kicks in
    iters.n = 30,
    #n_iter = 30,         # Bayesian iterations after init
    acq = "ucb",         # acquisition function
    kappa = 2.576,       # exploration/exploitation tradeoff
    verbose = TRUE
  )
})
endTime <- Sys.time()

print(endTime-startTime)
print(endTime-startTime)
print(endTime-startTime)

library(beepr)
beep(8)
Sys.sleep(6)

# Extract best parameters
getBestPars(bayes_result)

# $eta
# [1] 0.01
# $max_depth
# [1] 3
# $min_child_weight
# [1] 10
# $subsample
# [1] 0.5
# $colsample_bytree
# [1] 1
# $gamma
# [1] 1e-06
# $lambda
# [1] 100
# $alpha
# [1] 1e-06

bayes_result$scoreSummary[which.max(Score), nrounds] # 1909

## DETERMINE OPTIMUM ROUNDS ##

# This uses the full data set

# establish sample of complete cases
popSample <-
  cleanData[  , c(target,keepColumns)] |>
#  initial_split( 
#    data = cleanData[  , c(target,keepColumns)],
#    prop = 0.25,
#    strata = "GRADEGPA"
#  ) |> # 25% sampling index 
#  training() |>
  (\(x){x[complete.cases(x),]})()

trainIndex <- which(popSample$class_year < 2024)

trainData <- popSample[trainIndex, c(target, keepColumns[-which(keepColumns %in% c("cleanGrade","EMPLID") )])]
testData  <- popSample[-trainIndex, c(target, keepColumns[-which(keepColumns %in% c("cleanGrade", "EMPLID") )])]


theData <- list(training = trainData, testing = testData, trainID = popSample$EMPLID[trainIndex], testID = popSample$EMPLID[-trainIndex] )

saveRDS(theData, here::here("Data", paste("Decision Tree", model_version, target, "Data.rds")))

## PREPARE DM ##

# xgb_prep <- recipe(GRADEGPA ~ ., data = trainData) |>
#  step_mutate(
#    SEX = as.integer(SEX == "M"),
#    FIRST_GEN_Y = as.integer(FIRST_GEN_STATUS_CD == "Y"),
#    FIRST_GEN_U = as.integer(FIRST_GEN_STATUS_CD == "U"),
#    HSPRIVATE = as.integer(HSPRIVATE == "Y"),
#    RESSTAT = as.integer(RESSTAT == "R")
#  ) |>
#  step_integer(all_nominal()) |>
#  step_zv(all_predictors()) |>
#  prep(training = trainData, retain = TRUE) |>
#  bake(new_data=NULL)

xgb_recipe <- recipe(GRADEGPA ~ ., data = trainData) |>
  step_mutate(
    SEX = as.integer(SEX == "M"),
    FIRST_GEN_Y = as.integer(FIRST_GEN_STATUS_CD == "Y"),
    FIRST_GEN_U = as.integer(FIRST_GEN_STATUS_CD == "U"),
    HSPRIVATE = as.integer(HSPRIVATE == "Y"),
    RESSTAT = as.integer(RESSTAT == "R")
  ) |>
  step_integer(all_nominal()) |>
  step_zv(all_predictors()) |>
  prep(training = trainData, retain = TRUE)

xgb_prep <- bake(xgb_recipe, new_data = NULL)

X <- xgb_prep[setdiff(names(xgb_prep), "GRADEGPA")]
Y <- xgb_prep$GRADEGPA

dTrain <- xgb.DMatrix(data = X, label = Y)

## TRAIN ##  

startTime <- Sys.time()
find_best_rounds <- xgb.cv(
  data = dTrain,
  nrounds = 6000,
  early_stopping_rounds = 50,
  nfold = 10,
  verbose = 0,
  params = c(
    list(objective = "reg:squarederror"),
    getBestPars(bayes_result)
  )
  )
endTime <- Sys.time()

endTime - startTime

find_best_rounds$early_stop$best_iteration # 3842

## FINAL MODEL ##

final_model <- xgb.train(
  data = dTrain,
  nrounds = find_best_rounds$early_stop$best_iteration,
  verbose = 1,
  params = c(
    list(objective = "reg:squarederror"),
    getBestPars(bayes_result)
  )
)

## SOME INVESTIGATION ##

xgb.importance(model = final_model) |> xgb.plot.importance()

> xgb.importance(model = final_model)
Feature        Gain       Cover   Frequency
<char>       <num>       <num>       <num>
  1:               HSGPA 0.560098028 0.122396062 0.120292025
2:           ACTMATH.z 0.073526565 0.082733294 0.090677649
3:            APCREDIT 0.037786933 0.032034074 0.036465743
4:             HSGPA.z 0.036735310 0.090126952 0.089329839
5:             yr_diff 0.036067798 0.081486467 0.078547361
6:             ACTMATH 0.035860067 0.067770336 0.062710595
7:              course 0.031345025 0.076273208 0.069636840
8:             RESSTAT 0.027672044 0.018321388 0.017558967
9:                dist 0.022858965 0.073429287 0.072557095
10:             age_cut 0.020796894 0.030984360 0.028566080
11:          class_year 0.017495197 0.048431624 0.048371396
12:             ACTCOMP 0.014491484 0.054094482 0.045750655
13:              ACTSCI 0.013950058 0.046034407 0.047135904
14:             ACTENGL 0.013817670 0.043734284 0.049606889
15:         cohort_year 0.013350930 0.037452666 0.043354549
16:              season 0.012305123 0.010230237 0.014189442
17: FIRST_GEN_STATUS_CD 0.010958551 0.017251713 0.017821041
18:           ETHNICITY 0.008324897 0.034599547 0.030550356
19:           HSPRIVATE 0.004322750 0.012615978 0.010220891
20:             FA_PELL 0.003255034 0.008941379 0.009771621
21:                 SEX 0.002868161 0.005417703 0.009621864
22:              HONORS 0.001337475 0.004322949 0.003931112
23:         FIRST_GEN_U 0.000775040 0.001317602 0.003332085
Feature        Gain       Cover   Frequency
<char>       <num>       <num>       <num>

## EVALUATION ## 
  
xgb_test <- bake(xgb_recipe, new_data = testData)

X <- xgb_test[setdiff(names(xgb_test), "GRADEGPA")]
Y <- xgb_test$GRADEGPA

dTest <- xgb.DMatrix(data = X, label = Y)

predictions <- predict(final_model, dTest)

> sqrt(mean((predictions - Y)^2))
[1] 0.9609721
> 
  > # MAE
  > mean(abs(predictions - Y))
[1] 0.7049025
> 
  > # Correlation
  > cor(predictions, Y)
[1] 0.5552423

> cor(predictions, Y)^2
[1] 0.308294

# Improvements:  
# Since the lower scores are more valuable,
# I'd like to mess with weighting it,
# and maybe use the log exploration of the parameters

# I think that's the next version. 

# Next I need to successfully save this

########## 
## SAVE ## 
##########  

xgb.save(final_model, here::here("Models", "Decision Tree vH6 GRADEGPA model.ubj"))
saveRDS(xgb_recipe, here::here("Models","Decision Tree vH6 GRADEGPA recipe.rds"))





  