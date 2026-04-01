# Decision Tree Grades vH7

model_version <- "vH7"

# PURPOSE:  
# This runs one training model using regression and xgboost.
# It trains on only the first math class for first time freshman.
# It uses data derived by Bill Prisbrey.
# It follows vH6, but with this adjustment:
#     Weighting is adjusted to improve the accuracy of predictions at the low end
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

# saveRDS(hiGrades, here::here("Data", paste("hiGrades from ", model_version, ".rds", sep="")) )

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


#####    FIRST PASS      ######
##### ONE QUARTER SAMPLE ###### 

## PREP AND PARTITION ##

xgb.set.config(verbosity = 0)   # 0 = silent, 1 = warning, 2 = info, 3 = debug

set.seed(123)

target <- target_classes # throw-back to when I predicted against two variables

cleanData$weighting <- ifelse(cleanData$GRADEGPA < 2.4, 4, 1)

# stop("Starting bayesian optimization")

if(FALSE){ # Skip first and second passes of code completely

# establish sample of complete cases
popSample <-
  initial_split( 
    data = cleanData[  , c(target,keepColumns, "weighting")],
    prop = 0.25,
    strata = "GRADEGPA"
  ) |> # 25% sampling index 
  training() |>
  (\(x){x[complete.cases(x),]})()

trainIndex <- which(popSample$class_year < 2024)

trainData <- popSample[trainIndex, c(target, "weighting", keepColumns[-which(keepColumns %in% c("cleanGrade","EMPLID") )])]
testData  <- popSample[-trainIndex, c(target, "weighting", keepColumns[-which(keepColumns %in% c("cleanGrade", "EMPLID") )])]


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
  step_rm("weighting") |>
  prep(training = trainData, retain = TRUE) |>
  bake(new_data=NULL)

X <- xgb_prep[setdiff(names(xgb_prep), "GRADEGPA")]
Y <- xgb_prep$GRADEGPA

dTrain <- xgb.DMatrix(data = X, label = Y, weight = trainData$weighting)



## TRAIN ##  

startTime <- Sys.time()
print(paste("STARTING", target, "AT", startTime,"\n"))
print(paste("STARTING", target, "AT", startTime,"\n"))
print(paste("STARTING", target, "AT", startTime,"\n"))


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

print(endTime-startTime) # 1.8 hrs
print(endTime-startTime) # 1.8 hrs
print(endTime-startTime) # 1.8 hrs

library(beepr)
beep(8)
Sys.sleep(6)

# Extract best parameters
getBestPars(bayes_result)

# stop("bayes_result extracted")

# $eta
# [1] 0.01
# $max_depth
# [1] 3
# $min_child_weight
# [1] 10
# $subsample
# [1] 0.5
# $colsample_bytree
# [1] 0.6960955
# $gamma
# [1] 7.352264
# $lambda
# [1] 100
# $alpha
# [1] 1e-06

bayes_result$scoreSummary[which.max(Score), nrounds] # 1261


#####    SECOND PASS      ######
##### FULL DATA SET       ###### 


# establish sample of complete cases
popSample <-
  cleanData[  , c(target, "weighting", keepColumns)] |>
  #  initial_split( 
  #    data = cleanData[  , c(target,keepColumns)],
  #    prop = 0.25,
  #    strata = "GRADEGPA"
  #  ) |> # 25% sampling index 
  #  training() |>
  (\(x){x[complete.cases(x),]})()

trainIndex <- which(popSample$class_year < 2024)

trainData <- popSample[trainIndex, c(target, "weighting", keepColumns[-which(keepColumns %in% c("cleanGrade","EMPLID") )])]
testData  <- popSample[-trainIndex, c(target, "weighting", keepColumns[-which(keepColumns %in% c("cleanGrade", "EMPLID") )])]


theData <- list(training = trainData, testing = testData, trainID = popSample$EMPLID[trainIndex], testID = popSample$EMPLID[-trainIndex] )

saveRDS(theData, here::here("Data", paste("Decision Tree", model_version, target, "Data.rds")))

## PREPARE DM ##

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
  step_rm("weighting") |>
  prep(training = trainData, retain = TRUE)

xgb_prep <- bake(xgb_recipe, new_data = NULL)

X <- xgb_prep[setdiff(names(xgb_prep), "GRADEGPA")]
Y <- xgb_prep$GRADEGPA

dTrain <- xgb.DMatrix(data = X, label = Y, weight = trainData$weighting)

# Define search bounds
bounds <- list(
  eta               = c(0.005, 0.1),
  max_depth         = c(2L, 6L),
  min_child_weight  = c(5L, 30L),
  subsample         = c(0.2, 0.6),
  colsample_bytree  = c(0.5, 1.0),
  gamma             = c(1e-6, 20),
  lambda            = c(50, 500),
  alpha             = c(1e-6, 1)
)


# Run Bayesian optimization
set.seed(123)

startTime <- Sys.time()

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
    verbose = TRUE,
    saveFile = here::here("Models", paste("bayes_checkpoint_", model_version, ".rds", sep=""))
  )
})
endTime <- Sys.time()

print(endTime-startTime)

# Load the interrupted file and continue

bayes_result <- readRDS(here::here("Models", paste0("bayes_checkpoint_", model_version, ".rds")))

# Interuppted file is actually complete
nrow(bayes_result$scoreSummary)
# [1] 40

getBestPars(bayes_result)
# $eta
# [1] 0.005
# $max_depth
# [1] 5
# $min_child_weight
# [1] 27
# $subsample
# [1] 0.6
# $colsample_bytree
# [1] 0.5
# $gamma
# [1] 9.000869
# $lambda
# [1] 50
# $alpha
# [1] 1e-06

bayes_result$scoreSummary[which.max(Score), nrounds]
# [1] 3368

# Frustratingly, I am still at boundary values, some of them on the other side.

# I will run a third optimization, which will take me 4 hrs

# Or maybe I will run this over-night again

}





#####    THIRD PASS      ######
#####   FULL DATA SET    ###### 


# establish sample of complete cases
popSample <-
  cleanData[  , c(target, "weighting", keepColumns)] |>
  #  initial_split( 
  #    data = cleanData[  , c(target,keepColumns)],
  #    prop = 0.25,
  #    strata = "GRADEGPA"
  #  ) |> # 25% sampling index 
  #  training() |>
  (\(x){x[complete.cases(x),]})()

trainIndex <- which(popSample$class_year < 2024)

trainData <- popSample[trainIndex, c(target, "weighting", keepColumns[-which(keepColumns %in% c("cleanGrade","EMPLID") )])]
testData  <- popSample[-trainIndex, c(target, "weighting", keepColumns[-which(keepColumns %in% c("cleanGrade", "EMPLID") )])]


theData <- list(training = trainData, testing = testData, trainID = popSample$EMPLID[trainIndex], testID = popSample$EMPLID[-trainIndex] )

saveRDS(theData, here::here("Data", paste("Decision Tree", model_version, target, "Data.rds")))

## PREPARE DM ##

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
  step_rm("weighting") |>
  prep(training = trainData, retain = TRUE)

xgb_prep <- bake(xgb_recipe, new_data = NULL)

X <- xgb_prep[setdiff(names(xgb_prep), "GRADEGPA")]
Y <- xgb_prep$GRADEGPA

dTrain <- xgb.DMatrix(data = X, label = Y, weight = trainData$weighting)

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
  eta               = c(0.001, 0.01),
  max_depth         = c(3L, 7L),
  min_child_weight  = c(20L, 50L),
  subsample         = c(0.3, 0.9),
  colsample_bytree  = c(0.3, 0.7),
  gamma             = c(1, 20),
  lambda            = c(10, 100),
  alpha             = c(1e-6, 1)
)


# Run Bayesian optimization
set.seed(123)

startTime <- Sys.time()

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
    verbose = TRUE,
    saveFile = here::here("Models", paste("bayes_checkpoint_3_", model_version, ".rds", sep=""))
  )
})
endTime <- Sys.time()

print(endTime-startTime)

> getBestPars(bayes_result)
$eta
[1] 0.004397132

$max_depth
[1] 4

$min_child_weight
[1] 45

$subsample
[1] 0.7023901

$colsample_bytree
[1] 0.6580249

$gamma
[1] 9.175519

$lambda
[1] 28.97361

$alpha
[1] 0.97604


> bayes_result$scoreSummary[which.max(Score), nrounds]
[1] 4315




















## FINAL MODEL ##

final_model <- xgb.train(
  data = dTrain,
  nrounds = bayes_result$scoreSummary[which.max(Score), nrounds], # find_best_rounds$early_stop$best_iteration,
  verbose = 1,
  params = c(
    list(objective = "reg:squarederror"),
    getBestPars(bayes_result)
  )
)


########## 
## SAVE ## 
##########  

xgb.save(final_model, here::here("Models", paste("Decision Tree ", model_version, " GRADEGPA model.ubj")) )
saveRDS(xgb_recipe, here::here("Models",paste("Decision Tree ", model_version, " GRADEGPA recipe.rds")) )


## SOME INVESTIGATION for vH7

# xgb.importance(model = final_model) |> xgb.plot.importance()

# > xgb.importance(model = final_model)

# Feature         Gain        Cover    Frequency
# <char>        <num>        <num>        <num>
#   1:               HSGPA 0.4229650409 0.1023486999 0.0955371347
# 2:             HSGPA.z 0.1416666643 0.0739268874 0.0815331156
# 3:            APCREDIT 0.0618534543 0.0513962403 0.0468265930
# 4:           ACTMATH.z 0.0559497877 0.0758164411 0.0886293226
# 5:             ACTMATH 0.0538409704 0.0659509197 0.0644938458
# 6:                dist 0.0347260872 0.0567021839 0.0753370175
# 7:             yr_diff 0.0307334233 0.0884356279 0.0742275810
# 8:              course 0.0284983784 0.0789027338 0.0684710709
# 9:             RESSTAT 0.0280459804 0.0317488815 0.0220422005
# 10:          class_year 0.0175158637 0.0454562213 0.0516829942
# 11:             ACTCOMP 0.0156539018 0.0593017676 0.0478941639
# 12:             age_cut 0.0147093053 0.0343067406 0.0280080382
# 13:              ACTSCI 0.0146925580 0.0512879802 0.0491710625
# 14:         cohort_year 0.0138382041 0.0377711965 0.0458846186
# 15:             ACTENGL 0.0133843657 0.0367347660 0.0460311480
# 16: FIRST_GEN_STATUS_CD 0.0127801899 0.0185587733 0.0226492506
# 17:              HONORS 0.0082101788 0.0053965856 0.0052541238
# 18:              season 0.0075621117 0.0099270540 0.0150506573
# 19:           ETHNICITY 0.0062597401 0.0321223660 0.0242610734
# 20:             FA_PELL 0.0046432948 0.0124405890 0.0136062966
# 1:           HSPRIVATE 0.0045265721 0.0177638103 0.0110315666
# 22:                 SEX 0.0036148955 0.0059479993 0.0117014151
# 23:         FIRST_GEN_Y 0.0031440592 0.0052807242 0.0060914343
# 24:         FIRST_GEN_U 0.0009285027 0.0009673006 0.0037469647
# 25:        course_level 0.0002564699 0.0015075098 0.0008373106
# Feature         Gain        Cover    Frequency
# <char>        <num>        <num>        <num>  
  ## EVALUATION ## 
  
#   xgb_test <- bake(xgb_recipe, new_data = testData)

# X <- xgb_test[setdiff(names(xgb_test), "GRADEGPA")]
# Y <- xgb_test$GRADEGPA

# dTest <- xgb.DMatrix(data = X, label = Y, weight = testData$weighting)

# predictions <- predict(final_model, dTest)

# > sqrt(mean((predictions - Y)^2))
# [1] 1.093141
# > mean(abs(predictions - Y))
# [1] 0.887903
# > cor(predictions, Y)
# [1] 0.5419226
# > cor(predictions, Y)^2
# [1] 0.2936801






