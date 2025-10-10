# Decision Tree Grades vG1

# PURPOSE:  
# This runs training models using xgboost on data provided by Whitney Holt. 
# vG1 converts APCREDIT values of NA to zero. 

library(caret)
library(xgboost)
library(lubridate)
library(readxl)

##########
## LOAD ##
##########


whData <- read_excel(here::here("Data", "WH Dataset - Math Placement Project - First Time Students from Fall 2021 - 2024 Cohorts and Their First Math Course 2025.09.30.xlsx"))

##########
## PREP ##
##########

clean_grade <- function(x) {
  x <- as.character(x)
  x <- gsub("-", "_minus", x)   # replace '-' with '_minus'
  x <- gsub("\\+", "_plus", x)  # replace '+' with '_plus'
  x <- gsub(" ", "missing", x)        # replace spaces with '_'
  
  return(x)
}

whData$cleanGrade <- clean_grade(whData$FIRST_MATH_COURSE_GRADE) 

whData$cleanGrade <- factor(whData$cleanGrade,
                                  levels = c(
                                    "A", "A_minus", "B_plus", "B", "B_minus", "C_plus",
                                    "C", "C_minus", "D_plus", "D", "D_minus",   
                                    "E", "EU", "W", "I", "CR",  "NC", "V", 
                                    "missing", NA
                                  )
)

gpa_map <- c("A" = 4,
             "A-" = 3.7,
             "B+" = 3.3,
             "B" = 3.0,
             "B-" = 2.7,
             "C+" = 2.3,
             "C" = 2.0,
             "C-" = 1.7,
             "D+" = 1.3,
             "D" = 1.0,
             "D-" = 0.7,
             "E" = 0,
             "EU" = 0
             )                            
                            
whData$GRADEGPA <- gpa_map[whData$FIRST_MATH_COURSE_GRADE]
whData$GRADE <- whData$FIRST_MATH_COURSE_GRADE                            

rareGrades <- whData$cleanGrade %in% c("missing", "V", "I", "NC", "CR") # , "EU" convert EU to 0


# Bucket grades
# BINARY
whData$grade_binary <- NA
hiFilter <- whData$GRADE %in% c("A", "A-", "B+", "B", "B-", "C+", "C", "C-")
loFilter <- whData$GRADE %in% c( "D+", "D", "D-", "E", "EU" ) 
whData$grade_binary[hiFilter] <- 1
whData$grade_binary[loFilter] <- 0



# TRINARY
whData$grade_trinary <- NA
hiFilter <- whData$GRADE %in% c("A", "A-", "B+", "B", "B-")
medFilter <- whData$GRADE %in% c("C+", "C", "C-")
loFilter <- whData$GRADE %in% c( "D+", "D", "D-", "E", "EU" ) 
whData$grade_trinary[hiFilter] <-  2 #"hi_grade"
whData$grade_trinary[medFilter] <- 1 # "med_grade"
whData$grade_trinary[loFilter] <-  0 #"low_grade"



# QUAD
whData$grade_quad <- NA
hiFilter <- whData$GRADE %in% c("A")
medPlusFilter <- whData$GRADE %in% c("A-", "B+", "B", "B-")
medMinusFilter <- whData$GRADE %in% c("C+", "C", "C-")
loFilter <- whData$GRADE %in% c( "D+", "D", "D-", "E", "EU" ) 
whData$grade_quad[hiFilter] <- 3 # "hi_grade"
whData$grade_quad[medPlusFilter] <- 2 # "medPlus_grade"
whData$grade_quad[medMinusFilter] <- 1 #"medMinus_grade"
whData$grade_quad[loFilter] <-0 # "low_grade"


## CONVERT APCREDIT NA VALUES to ZERO ##  

whData$APCREDIT[is.na(whData$APCREDIT)] <- 0

print("Transformations complete")

# skim(whData)
# drop SATWRTG
# drop all SAT
# I'm guessing NA means they didn't offer AP at their high school (?)

# What is up with these people (how'd they get into the query?)

sum(is.na(whData$FIRST_MATH_TERM)) # 3910
sum(is.na(whData$FIRST_MATH_COURSE_CATNBR)) # 3910
sum(is.na(whData$FIRST_MATH_COURSE_GRADE)) # 3978

#################
## PRE-PROCESS ##
#################

keepColumns <- c(

 "COHORTTERM"         ,         
 "COHORT"             ,         
# "EMPLID"             ,         
 "SEX"                ,         
 "FIRST_GEN_STATUS_CD",         
 "ETHNICITY"          ,         
 "RESSTAT"            ,         
 "FA_PELL"            ,         
 "APCREDIT"           ,         
 "HSGPA"              ,         
 "HSPRIVATE"          ,         
 "ACTCOMP"            ,         
 "ACTENGL"            ,         
 "ACTMATH"            ,         
 "ACTSCI"             ,         
# "SATMATH"            ,         
# "SATVERBAL"          ,         
# "SATWRTG"            ,         
 "MATH_IN_FIRST_YEAR" ,         
# "FIRST_MATH_TERM"    ,         
# "FIRST_MATH_COURSE_SUBJECT_CD",
 "FIRST_MATH_COURSE_CATNBR"   , 
# "FIRST_MATH_COURSE_TITLE"    , 
# "FIRST_MATH_COURSE_GRADE"    , 
 "cleanGrade"               #  , 
# "GRADEGPA"                   , 
# "grade_binary"               , 
# "GRADE"                      , 
# "grade_trinary"              , 
# "grade_quad"  
)


target_classes <- c("GRADEGPA",  "grade_binary", "grade_trinary", "grade_quad")

###########
## CLEAN ##
###########

cleanFilters <- !is.na(whData$cleanGrade) & 
  !rareGrades
#!popCourses$cleanGrade %in% c("missing", "V", "I", "NC", "CR") 

# Outlier filters
zeroHSGPA_filter <- whData$HSGPA == 0
# highLoad_filter <- whData$load > quantile(whData$load, 0.99)
# preMath_filter <- whData$yr_diff < -0.5 # since all cohort dates start in September, I wanted to includ the summer before the cohort date

outlierFilters <- !zeroHSGPA_filter # & !highLoad_filter & !preMath_filter

cleanData <- whData[cleanFilters & outlierFilters,]

cleanData$cleanGrade <- droplevels(cleanData$cleanGrade)

###########
## SPLIT ##
###########

set.seed(123)

xgb.set.config(verbosity = 0)   # 0 = silent, 1 = warning, 2 = info, 3 = debug

lapply(target_classes,
       
       
       function(target){
         
         # establish sample of complete cases
         popSample <- cleanData[  , c(target,keepColumns)] |> # no sampling index 
           (\(x){x[complete.cases(x),]})()
         
         ## SPLIT ##  
         
         # Use cleanGrade to partition on, but drop it for the test and train data
         trainIndex <- createDataPartition(popSample$cleanGrade, p = 0.8, list = FALSE)
         
         trainData <- popSample[trainIndex, c(target, keepColumns[-which(keepColumns %in% "cleanGrade")])]
         testData  <- popSample[-trainIndex, c(target, keepColumns[-which(keepColumns %in% "cleanGrade")])]
         
         #       return(list(training = trainData, testing = testData))
         
         theData <- list(training = trainData, testing = testData)
         
         #     })
         
         saveRDS(theData, here::here("Data", paste("Decision Tree vG1", target, "Data.rds")))
         
         
         ## TRAIN ##  
         
         startTime <- Sys.time()
         print(paste("STARTING", target, "AT", startTime,"\n"))
         print(paste("STARTING", target, "AT", startTime,"\n"))
         print(paste("STARTING", target, "AT", startTime,"\n"))
         
         # Establish weighting
         
         targetCol <- trainData[[target]]
         
         # Compute inverse-frequency weights automatically
         weights_map <- 1 / prop.table(table(targetCol))
         weights_map <- weights_map / mean(weights_map)  # normalize around 1
         weights <- weights_map[as.character(targetCol)]
         
         # regression
         ctrl <- trainControl(
           method = "cv",
           number = 5,
           summaryFunction = defaultSummary
         )
         
         xgb_grid <- expand.grid(
           nrounds = 600,          
           eta = c(0.05, 0.1),     
           max_depth = c(4, 6),    
           gamma = 0,              
           colsample_bytree = 0.8, 
           min_child_weight = 1,
           subsample = 0.8
         )
         
         fit <- 
           suppressWarnings(
             train(
               reformulate(".", response = target), 
               data = trainData,
               method = "xgbTree",
               trControl = ctrl,
               preProcess = c("zv", "nzv", "center", "scale"),
               tuneGrid = xgb_grid,
               weights = weights            
             )
           )
         
         endTime <- Sys.time()
         
         print(endTime-startTime)
         print(endTime-startTime)
         print(endTime-startTime)
         
         saveRDS(fit, here::here("Models", paste("Decision Tree vG1", target, "model.rds")))
         
         library(beepr)
         beep(8); Sys.sleep(6); #beep(0); Sys.sleep(3); beep(0)
         
       })






