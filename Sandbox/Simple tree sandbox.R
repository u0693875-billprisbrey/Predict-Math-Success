# Simple tree sandbox

# PURPOSE:  Run xgboost on a sample with a few variables.
# Scale up (more variables, larger sample) incrementally.

library(caret)
library(xgboost)
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
popCourses <- merge(popCourses, ftfData[, c("EMPLID","COHORT_DT", "HSPRIVATE" , "AGE", "SEX", "ETHNICITY", "HSGPA", "ACTCOMP","ACTENGL","ACTMATH","ACTSCI", "HONORS")], by = "EMPLID",  all.x = TRUE)

# Year to class
popCourses$yr_diff <- time_length(interval(popCourses$COHORT_DT, popCourses$EOTDATE), "years")

# convert grade value names   

clean_grade <- function(x) {
  x <- as.character(x)
  x <- gsub("-", "_minus", x)   # replace '-' with '_minus'
  x <- gsub("\\+", "_plus", x)  # replace '+' with '_plus'
  x <- gsub(" ", "missing", x)        # replace spaces with '_'
  
  return(x)
}

popCourses$cleanGrade <- clean_grade(popCourses$GRADE) 

# Set factor levels

popCourses$cleanGrade <- factor(popCourses$cleanGrade,
                                levels = c(
                                  "A", "A_minus", "B_plus", "B", "B_minus", "C_plus",
                                  "C", "C_minus", "D_plus", "D", "D_minus",   
                                  "E", "W", "I", "CR", "EU", "NC", "V", 
                                  "missing", NA
                                )
                                )


#################
## PRE-PROCESS ##
#################

# Select columns

keepColumns <- c(
#  "EMPLID",                      
#  "TERM"  ,                      
  "course" ,                     
#  "class"   ,                    
#  "CATNBR"  ,                    
#  "TITLE"   ,                    
#  "SECTION" ,                    
#  "UNITS"   ,                    
#  "GRADE"   ,
  "cleanGrade",
#  "GRADEGPA",                    
#  "INSTEMPLID",                  
#  "INSTNAME"  ,                  
#  "EOTDATE"   ,                  
#  "ACADYR"    ,                  
#  "TERMEXTRACT",                 
#  "MAX_SNAP"  ,                  
#  "CENSUSDATE" ,                 
#  "ALT_ID"    ,                  
#  "FULLNAME"   ,                 
#  "STUDENTCAREER",               
#  "SUBJECT_CD"    ,              
#  "SUBJECT_NAME"  ,              
#  "SUBJECT_LONG"  ,              
#  "SUBJECT_ACAD_ORG_CD" ,        
#  "CATNBR2"             ,        
#  "CLASSNBR"            ,        
#  "OFFERINGNBR"         ,        
#  "SESSIONCODE"         ,        
#  "COURSECAREER"        ,        
#  "SCHEDFLAG"           ,        
#  "WAUTOENRL"           ,        
#  "AUTOENROLL"          ,        
#  "COMPONENT"           ,        
#  "GENED"               ,        
#  "VARCREDIT"           ,        
#  "CONTRACT"            ,        
#  "DIRECTPAY"           ,        
#  "CORRESPONDENCE"      ,        
#  "ONLINECOURSE"        ,        
#  "IVC"                 ,        
#  "IVC_HYBRID"          ,        
#  "COURSE_MODALITY"     ,        
#  "INSTRUCTION_MODE"    ,        
#  "TELECOURSE"          ,        
#  "STUDYABROAD"         ,        
#  "EDNET"               ,        
#  "HYBRIDCOURSE"        ,        
#  "COURSE_LEVEL"        ,        
#  "USHE_COURSE_LEVEL"   ,        
#  "FISCAL_YEAR_OF_STARTDT",      
#  "VP"                    ,      
#  "VP_SHORT"              ,      
#  "VP_FORMAL"             ,      
#  "ACAD_COLLEGE_CD"       ,      
#  "COLLEGE"               ,      
#  "COLLEGE_SHORT"         ,      
#  "COLLEGE_FORMAL"        ,      
#  "ACAD_COLLEGE_REG_SUPP" ,      
#  "ACAD_COLLEGE_TYPE"     ,      
#  "ACAD_COLLEGE_CIP_CD"   ,      
#  "ACAD_DEPARTMENT_CD"    ,      
#  "DEPARTMENT"            ,      
#  "DEPARTMENT_SHORT"      ,      
#  "DEPARTMENT_FORMAL"     ,      
#  "ACAD_DEPARTMENT_REG_SUPP",    
#  "ACAD_DEPARTMENT_TYPE"    ,    
#  "ACAD_DEPARTMENT_CIP_CD"  ,    
#  "ACAD_DIVISION_CD"        ,    
#  "DIVISION"                ,    
#  "DIVISION_SHORT"          ,    
#  "DIVISION_FORMAL"         ,    
#  "ACAD_DIVISION_REG_SUPP"  ,    
#  "ACAD_DIVISION_TYPE"      ,    
#  "ACAD_DIVISION_CIP_CD"    ,    
#  "VP_CD"                   ,    
#  "COLLEGE_CD"              ,    
#  "DEPARTMENT_CD"           ,    
#  "DIVISION_CD"             ,    
#  "ROLLUP_SORT_ORDER"       ,    
#  "PS_ACAD_ORG"             ,    
#  "PS_ACAD_GROUP"           ,    
#  "CAMPUS"                  ,    
#  "COURSE_CAMPUS"           ,    
#  "USHE_SITE_TYPE_CD"       ,    
#  "USHE_SITE_TYPE"          ,    
#  "ONOFFCAMPUS"             ,    
#  "COURSELOCATION"          ,    
#  "CONTACTMINUTES"          ,    
#  "TEAMTAUGHT"              ,    
#  "XLIST"                   ,    
#  "BEGTIME1"                ,    
#  "BEGTIME2"                ,    
#  "BEGTIME3"                ,    
#  "DAYS1"                   ,    
#  "DAYS2"                   ,    
#  "DAYS3"                   ,    
#  "ENDTIME1"                ,    
#  "ENDTIME2"                ,    
#  "ENDTIME3"                ,    
#  "CLASSLOC1"               ,    
#  "CLASSLOC2"               ,    
#  "CLASSLOC3"               ,    
#  "CLASSLOCBUILDNAME1"      ,    
#  "CLASSLOCBUILDROOM1"      ,    
#  "CLASSLOCBUILDNAME2"      ,    
#  "CLASSLOCBUILDROOM2"      ,    
#  "CLASSLOCBUILDNAME3"      ,    
#  "CLASSLOCBUILDROOM3"      ,    
#  "STARTDT"                 ,    
#  "ENDDT"                   ,    
#  "BUDGETCODE"              ,    
#  "LINEITEM"                ,    
#  "SERVICELEARNING"         ,    
#  "XLIST_ID"                ,    
#  "COMBINEDID"              ,    
#  "USHE_ACADYR"             ,    
#  "USHE_TERM"               ,    
#  "TERM2"                   ,    
#  "ORG_EFFDT"               ,    
#  "CLASSENROLLMENTCAPACITY" ,    
#  "ROOM_MAX_1"              ,    
#  "ROOM_MAX_2"              ,    
#  "ROOM_MAX_3"              ,    
#  "TERM_NBR"                ,    
#  "CLASS_ATTR_LIST"         ,    
#  "EXCLUDE_BUDGET_SCH"      ,    
#  "SPR_CORRECTION_NOT_USHE_FLAG",
#  "Section Divider: OLD"        ,
#  "SUBJECTCOLL"               ,  
#  "SUBJECT"                   ,  
#  "class.1"                   ,  
#  "COHORT_DT"                 ,  
  "HSPRIVATE"                 ,  
  "AGE"                       ,  
  "SEX"                       ,  
  "ETHNICITY"                 ,  
  "HSGPA"                     ,  
  "ACTCOMP"                   ,  
  "ACTENGL"                   ,  
  "ACTMATH"                   ,  
  "ACTSCI"                    ,  
  "HONORS"                    ,  
  "yr_diff" 
)

###########
## CLEAN ##
###########

# developed recursively

colSums(is.na(popCourses[,keepColumns]))/nrow(popCourses) 

# course            GRADE  COURSE_MODALITY 
# 0              243            80302 
# INSTRUCTION_MODE     COURSE_LEVEL        HSPRIVATE 
# 80226                0                0 
# AGE              SEX        ETHNICITY 
# 0                0                0 
# HSGPA          ACTCOMP          ACTENGL 
# 5855            28741            27868 
# ACTMATH           ACTSCI           HONORS 
# 27870            27884                0 
# yr_diff 
# 0 


cleanData <- popCourses[!is.na(popCourses$cleanGrade) & popCourses$cleanGrade != "missing",]

cleanData$cleanGrade <- droplevels(cleanData$cleanGrade)

###########
## SPLIT ##
###########

# Initially take a subset
set.seed(123)
subIndex <- createDataPartition(cleanData$cleanGrade, p = 0.1, list = FALSE)
popSample <- cleanData[subIndex, keepColumns]


# No missing values
popSample <- popSample[complete.cases(popSample),]


set.seed(123)
trainIndex <- createDataPartition(popSample$cleanGrade, p = 0.7, list = FALSE)

trainData <- popSample[trainIndex, keepColumns ]
testData  <- popSample[-trainIndex, keepColumns ]

###########
## TRAIN ##
###########

startTime <- Sys.time()
fit <- train(
  cleanGrade ~ ., 
  data = trainData,
  method = "xgbTree",
  trControl = trainControl(
    method = "cv",          # cross-validation
    number = 5,             # 5-fold CV
    classProbs = TRUE,      # needed for probabilities
    summaryFunction = multiClassSummary
  ),
  preProcess = c("zv", "nzv", "center", "scale", "knnImpute"), 
  tuneLength = 5            # let caret tune hyperparameters
)
endTime <- Sys.time()

# > endTime - startTime
# Time difference of 2.275265 hours

# I thought it would be a lot quicker.

##############
## EVALUATE ##
##############

varImp(fit)

#Overall
#HSGPA           100.00000
#ACTMATH          25.43221
#yr_diff          20.60828
#ACTCOMP           9.30727
#ACTSCI            6.87860
#ACTENGL           6.54131
#AGE               5.91679
#courseMATH_1070   2.11513
#courseMATH_2210   1.67264
#courseMATH_1050   1.67089
#courseMATH_1090   1.47211
#courseMATH_2250   1.41001
#courseMATH_1030   1.03025
#courseMATH_1220   0.97694
#courseMATH_1210   0.74371
#courseMATH_1060   0.69852
#ETHNICITYH        0.46664
#ETHNICITYC        0.44340
#HSPRIVATEY        0.40787
#HONORS            0.08796

#############
## PREDICT ##
#############

char_cols <- c("course","HSPRIVATE","SEX","ETHNICITY")

# Training data
for(col in char_cols) {
  trainData[[col]] <- factor(trainData[[col]])
}

# Test data
for(col in char_cols) {
  testData[[col]] <- factor(testData[[col]], levels = levels(trainData[[col]]))
}


pred <- predict(fit, newdata = testData) #[, setdiff(names(testData), "cleanGrade")])

cm <- confusionMatrix(data = pred, reference = testData[,"cleanGrade"])


# Kappa of 0.1134, wow that's low

# I have a bigger problem here --- some unknown mechanism is sorting 
# them into classes.  They haven't randomly been assigned a class.

# So I have to assume that "something", external to the data, put them in the class
# ... and then High School GPA said how good they'd be in that class. 

# It's almost ACT -->> where and HSGRADE -->> how good  
# (because in this data set people were never slotted into the wrong course, so "ACT" disappears?)

# And predicting 17 categories is JUST. TOO. MANY.  
# I need to trim some of these out or lump some together.

# Let's see what Chat coughs up for me --
library(caret)
library(dplyr)

# Confusion matrix
cm <- confusionMatrix(pred, testData$cleanGrade)

# Actual vs predicted counts
actual_counts <- rowSums(cm$table)
correct_counts <- diag(cm$table)

# Proportion of each grade in test set
prop_actual <- prop.table(table(testData$cleanGRADE))

# Per-grade accuracy
accuracy_per_grade <- correct_counts / actual_counts

# Expected accuracy by chance (proportion of that grade)
baseline_per_grade <- prop_actual[names(accuracy_per_grade)]

# Combine into a table
grade_perf <- data.frame(
  Grade = names(accuracy_per_grade),
  Accuracy = as.numeric(accuracy_per_grade),
  Baseline = as.numeric(baseline_per_grade)
)

# Compute improvement over chance
grade_perf <- grade_perf %>%
  mutate(Over_Chance = Accuracy - Baseline) %>%
  arrange(desc(Over_Chance))

# Display
print(grade_perf)


print(grade_perf)
Grade  Accuracy     Baseline Over_Chance
1   B_plus 0.2500000 0.0849128127  0.16508719
2        W 0.2000000 0.0424564064  0.15754359
3        A 0.3408925 0.2183472328  0.12254523
4        E 0.1890756 0.0978013647  0.09127427
5        B 0.1516710 0.1190295679  0.03264138
6        C 0.1092437 0.0818802123  0.02736349
7  A_minus 0.1153846 0.0943896892  0.02099493
8  B_minus 0.0000000 0.0727824109 -0.07278241
9   C_plus       NaN 0.0568612585         NaN
10 C_minus       NaN 0.0375284306         NaN
11  D_plus       NaN 0.0265352540         NaN
12       D       NaN 0.0341167551         NaN
13 D_minus       NaN 0.0193328279         NaN
14       I       NaN 0.0007581501         NaN
15      CR       NaN 0.0056861259         NaN
16      EU       NaN 0.0056861259         NaN
17      NC       NaN 0.0018953753         NaN
18       V       NaN 0.0000000000         NaN


library(ggplot2)

# Replace NaN with 0 for accuracy
grade_perf$Accuracy[is.na(grade_perf$Accuracy)] <- 0
grade_perf$Over_Chance[is.na(grade_perf$Over_Chance)] <- -grade_perf$Baseline[is.na(grade_perf$Over_Chance)]

# Plot
ggplot(grade_perf, aes(x = Grade, y = Accuracy)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_point(aes(y = Baseline), color = "red", size = 2) +
  geom_text(aes(y = Accuracy + 0.02, label = round(Accuracy, 2)), size = 3) +
  labs(title = "Model Accuracy per Grade vs Baseline Proportion",
       y = "Accuracy", x = "Grade") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# How to read it:
  
#  Blue bars → model accuracy per grade

# Red points → baseline chance accuracy (proportion of that grade in test data)

# Text labels → exact model accuracy per grade

# Insights you can get at a glance:
  
#  Grades where blue bar >> red point → model is doing better than random

# Grades where blue bar ≈ red point → model is mostly guessing

# Grades where blue bar = 0 → model completely fails to predict that grade

# This makes it immediately obvious which grades are difficult for your model.

# Huh, baseline proportions are pretty interesting:

# proportions(table(popCourses$cleanGrade)) |> (\(x){x[order(x, decreasing = TRUE)]})()

# A            B            E      A_minus 
# 0.2222764529 0.1178871367 0.0950233098 0.0917414208 
# B_plus            C      B_minus       C_plus 
# 0.0852113032 0.0812057155 0.0726223135 0.0590740024 
# W      C_minus            D       D_plus 
# 0.0425383308 0.0365720248 0.0344177592 0.0260531498 
# D_minus           EU           CR           NC 
# 0.0195819378 0.0054024942 0.0053435885 0.0019523032 
# I      missing            V 
# 0.0014053217 0.0013884915 0.0003029436 

# I should include "year" as a category
# Filter out some values
# Combine other values

# let's combine all D grades
# filter out EU, CR, NC, I, missing, and V
# Do I combine "E" and "W" ?
# Do I combine "C" grades?

# create a new script and run that in the background


saveRDS("fit", here::here("Models", "Simple tree sandbox model.R"))


# I need to predict WHICH COURSE (!duh!)
# I wonder if I can predict both GRADE and COURSE ?