# Decision Tree xA0 Evaluated

# PURPOSE:  Run xgboost on 30% of the data; combine grades and filter out others

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

# Combine grades
popCourses$cleanGrade[popCourses$cleanGrade %in% c("D_plus", "D", "D_minus") ] <- "D"



# Set factor levels

popCourses$cleanGrade <- factor(popCourses$cleanGrade,
                                levels = c(
                                  "A", "A_minus", "B_plus", "B", "B_minus", "C_plus",
                                  "C", "C_minus", "D",   
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

cleanFilters <- !is.na(popCourses$cleanGrade) & 
  !popCourses$cleanGrade %in% c("missing", "V", "I", "NC", "CR", "EU") 
cleanData <- popCourses[cleanFilters,]

cleanData$cleanGrade <- droplevels(cleanData$cleanGrade)

###########
## SPLIT ##
###########

# Initially take a subset
set.seed(123)
subIndex <- createDataPartition(cleanData$cleanGrade, p = 0.35, list = FALSE)
popSample <- cleanData[subIndex, keepColumns]

# No missing values
popSample <- popSample[complete.cases(popSample),]

set.seed(123)
trainIndex <- createDataPartition(popSample$cleanGrade, p = 0.8, list = FALSE)

trainData <- popSample[trainIndex, keepColumns ]
testData  <- popSample[-trainIndex, keepColumns ]

gradeFit <- readRDS(here::here("Models", "Decision Tree xA0 model.R"))

grade_pred <- predict(gradeFit, newdata = testData)

grade_cm <- confusionMatrix(data = grade_pred, reference = testData[,"cleanGrade"])

# Actual vs predicted counts
actual_counts <- rowSums(grade_cm$table)
correct_counts <- diag(grade_cm$table)

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


