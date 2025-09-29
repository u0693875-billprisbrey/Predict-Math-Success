# Decision Tree Grades vD0

# PURPOSE:  
# This runs five training models with various bucketing of grades.
# Models are xgboost and I'll attempt 100% of the data
# (70% of the data only took 5 hrs)

library(caret)
library(xgboost)
library(lubridate)

##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))

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

# identify popular, high volume courses
mostPopCourses <- c("MATH_1050", "MATH_1210", "MATH_1010", "MATH_1220", "MATH_1030",
                    "MATH_1090", "MATH_1060", "MATH_2210", "MATH_1070", "MATH_2250") # identified via hierarchical clustering later in this report


mostPopFilter <- mathCourses$course %in% mostPopCourses

mathLabFilter <- 
  mathCourses$GRADE %in% c(" ", NA) &
  mathCourses$UNITS == 0

popCourses <- mathCourses[mostPopFilter &  !mathLabFilter,] 

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

popCourses <- merge(popCourses, ftfData[, c("EMPLID","COHORT_DT", student_demographics, academic_prep)], by = "EMPLID",  all.x = TRUE)

# Freshman year
popCourses$year <- year(popCourses$COHORT_DT)

# Year to class
popCourses$yr_diff <- time_length(interval(popCourses$COHORT_DT, popCourses$EOTDATE), "years")

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

popCourses$cleanGrade <- clean_grade(popCourses$GRADE) 

popCourses$cleanGrade <- factor(popCourses$cleanGrade,
                                levels = c(
                                  "A", "A_minus", "B_plus", "B", "B_minus", "C_plus",
                                  "C", "C_minus", "D",   
                                  "E", "W", "I", "CR", "EU", "NC", "V", 
                                  "missing", NA
                                )
)

# RARE AND UNUSUAL VALUES

rareGrades <- popCourses$cleanGrade %in% c("missing", "V", "I", "NC", "CR", "EU") 

# WITHDRAW
popCourses$wdraw_binary <- NA
popCourses$wdraw_binary <- ifelse(popCourses$GRADE == "W","withdraw","not_withdraw")


# Combine grades
# BINARY
popCourses$grade_binary <- NA
hiFilter <- popCourses$GRADE %in% c("A", "A-", "B+", "B", "B-", "C+", "C", "C-")
loFilter <- popCourses$GRADE %in% c( "D+", "D", "D-", "E" ) 
popCourses$grade_binary[hiFilter] <- "hi_grade"
popCourses$grade_binary[loFilter] <- "low_grade"

popCourses$grade_binary <- factor(popCourses$grade_binary,
                                  levels = c("hi_grade", "low_grade"))


# TRINARY
popCourses$grade_trinary <- NA
hiFilter <- popCourses$GRADE %in% c("A", "A-", "B+", "B", "B-")
medFilter <- popCourses$GRADE %in% c("C+", "C", "C-")
loFilter <- popCourses$GRADE %in% c( "D+", "D", "D-", "E" ) 
popCourses$grade_trinary[hiFilter] <- "hi_grade"
popCourses$grade_trinary[medFilter] <- "med_grade"
popCourses$grade_trinary[loFilter] <- "low_grade"


popCourses$grade_trinary <- factor(popCourses$grade_trinary,
                                  levels = c("hi_grade", "med_grade", "low_grade"))

# QUAD (EXPANDED FAILURE)
popCourses$grade_quad <- NA
hiFilter <- popCourses$GRADE %in% c("A")
medPlusFilter <- popCourses$GRADE %in% c("A-", "B+", "B", "B-")
medMinusFilter <- popCourses$GRADE %in% c("C+", "C", "C-")
loFilter <- popCourses$GRADE %in% c( "D+", "D", "D-", "E", "W" ) 
popCourses$grade_quad[hiFilter] <- "hi_grade"
popCourses$grade_quad[medPlusFilter] <- "medPlus_grade"
popCourses$grade_quad[medMinusFilter] <- "medMinus_grade"
popCourses$grade_quad[loFilter] <- "low_grade"

popCourses$grade_quad <- factor(popCourses$grade_quad,
                                  levels = c("hi_grade", 
                                             "medPlus_grade",
                                             "medMinus_grade",
                                             "low_grade"))

# popCourses$cleanGrade[popCourses$cleanGrade %in% c("D_plus", "D", "D_minus") ] <- "D"

print("Transformations complete")

#################
## PRE-PROCESS ##
#################

# Select columns

# colnames(popCourses)

keepColumns <- c(
#   "EMPLID"                      ,
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
   "AGE"                         ,
   "APCREDIT"                    ,
   "HSGPA"                       ,
   "HSPRIVATE"                   ,
   "HONORS"                      ,
   "ACTCOMP"                     ,
   "ACTENGL"                     ,
   "ACTMATH"                     ,
   "ACTSCI"                      ,
   "year"                        ,
   "yr_diff"                     ,
   "cleanGrade"                  
#   "wdraw_binary"                ,
#   "grade_binary"                ,
#   "grade_trinary"               ,
#   "grade_quad" 
)

target_classes <- c("GRADEGPA", "wdraw_binary", "grade_binary", "grade_trinary", "grade_quad")

# stop("Work on keep columns")

###########
## CLEAN ##
###########

cleanFilters <- !is.na(popCourses$cleanGrade) & 
  !rareGrades
  #!popCourses$cleanGrade %in% c("missing", "V", "I", "NC", "CR", "EU") 
cleanData <- popCourses[cleanFilters,]

cleanData$cleanGrade <- droplevels(cleanData$cleanGrade)

###########
## SPLIT ##
###########

# Initially take a subset
set.seed(123)
# subIndex <- createDataPartition(cleanData$cleanGrade, p = 0.7, list = FALSE)

# No subset

# popSample <- cleanData[subIndex, keepColumns]

# No missing values
# popSample <- popSample[complete.cases(popSample),]

# stop("Work on sampling")

# let's loop through this 

xgb.set.config(verbosity = 0)   # 0 = silent, 1 = warning, 2 = info, 3 = debug

lapply(target_classes,

              
       function(target){
       
         # establish sample of complete cases
         popSample <- cleanData[, c(target,keepColumns)] |> # no sampling index 
           (\(x){x[complete.cases(x),]})()
         
         ## SPLIT ##  
         
         # Use cleanGrade to partition on, but drop it for the test and train data
         trainIndex <- createDataPartition(popSample$cleanGrade, p = 0.8, list = FALSE)
         
         trainData <- popSample[trainIndex, c(target, keepColumns[-which(keepColumns %in% "cleanGrade")])]
         testData  <- popSample[-trainIndex, c(target, keepColumns[-which(keepColumns %in% "cleanGrade")])]
         
  #       return(list(training = trainData, testing = testData))
         
         theData <- list(training = trainData, testing = testData)
         
  #     })
         
         saveRDS(theData, here::here("Data", paste("Decision Tree vD0", target, "Data.rds")))
         
         
         ## TRAIN ##  
         
         startTime <- Sys.time()
         print(paste("STARTING", target, "AT", startTime,"\n"))
         print(paste("STARTING", target, "AT", startTime,"\n"))
         print(paste("STARTING", target, "AT", startTime,"\n"))
         
         # Establish control based on target
         
         targetCol <- trainData[[target]]
         
         if (is.numeric(targetCol)) {
           # regression
           ctrl <- trainControl(
             method = "cv",
             number = 5,
             summaryFunction = defaultSummary
           )
         } else if (is.factor(targetCol) && nlevels(targetCol) == 2) {
           # binary classification
           ctrl <- trainControl(
             method = "cv",
             number = 5,
             classProbs = TRUE,
             sampling = "smote",
             summaryFunction = twoClassSummary
           )
         } else {
           # multiclass classification
           ctrl <- trainControl(
             method = "cv",
             number = 5,
             classProbs = TRUE,
             summaryFunction = multiClassSummary
           )
         }
        

          
         fit <- 
           suppressWarnings(
             train(
               reformulate(".", response = target), 
               data = trainData,
               method = "xgbTree",
               trControl = ctrl,
               preProcess = c("zv", "nzv", "center", "scale", "knnImpute"), 
               tuneLength = 5            # let caret tune hyper-parameters
             )
           )
         
         endTime <- Sys.time()
         
         print(endTime-startTime)
         print(endTime-startTime)
         print(endTime-startTime)
      
         saveRDS(fit, here::here("Models", paste("Decision Tree vD0", target, "model.rds")))
         
         library(beepr)
         beep(8); Sys.sleep(6); #beep(0); Sys.sleep(3); beep(0)
         
       })





