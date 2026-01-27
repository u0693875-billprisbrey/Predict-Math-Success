# DECISION TREE GRADES vM1

model_version <- "vM1"

# PURPOSE:
# This is an attempt to get a working version of vM0.
# It is similar to vH3, except it calculates the distance
# using principal components, adds the distance to the medoid
# for failing, and adds a feature that compares these two distances.

# It improves on vM0 in that I loop through all the years.

# I am thining of adding a feature that allows me to toggle
# taking the PCA for 1 to x previous years.

# This should follow the previous steps:

# Derive the principal components for 1 to x previous years.
#   Align the signage so the dimensions are consistent
#   Extract one PCA per course per "x" years
#   Calculate the centers for passing and failing
# Skip identifying outliers (too few data points in most classes)
# Predict the principal components for the next year
# Calculate the distances 
# Train the model (xgboost)


library(caret)
library(xgboost)
library(lubridate)
library(factoextra)
library(FactoMineR)

############### 
## FUNCTIONS ## 
############### 

# For FactoMineR
flipPCA <- function(pca_obj, vars_to_check = c("HSGPA", "ACTMATH")) {
  loadings <- pca_obj$var$coord
  
  for (i in seq_len(ncol(loadings))) {
    loading_sum <- sum(loadings[vars_to_check, i])
    
    if (loading_sum < 0) {
      pca_obj$var$coord[, i] <- -pca_obj$var$coord[, i]
      pca_obj$var$cor[, i] <- -pca_obj$var$cor[, i]
      pca_obj$ind$coord[, i] <- -pca_obj$ind$coord[, i]
    }
  }
  
  return(pca_obj)
}


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

stop("stop before PCA")

###############################
## SKIPPING Z-SCORE DISTANCE ##
###############################

##########################  
## PRINCIPAL COMPONENTS ##  
##########################  

# Filters

actFilter <- !is.na(cleanData$ACTMATH)
hsgpaFilter <- !is.na(cleanData$HSGPA) & cleanData$HSGPA > 0

# Rolling components

# rolling_pca <- lapply(2006:2025, function(loop_target) { 

# target_year <- loop_target # 2024:2025

set.seed(123) # to ensure consistent sign application

no_of_years <- 1
initial_year <- min(cleanData$class_year)+no_of_years - 1
final_year <- max(cleanData$class_year)

rolling_pca <- lapply(initial_year:final_year, function(loop_year){
 
  # Set filters
  target_yr_filter <- (cleanData$class_year %in% (loop_year + 1)) & !is.na(cleanData$class_year)
  loop_yr_filter <- cleanData$class_year %in% (loop_year - no_of_years +1 ):(loop_year) & !is.na(cleanData$class_year)
  courses_in_loop_yr <- unique(cleanData$course[loop_yr_filter & actFilter & hsgpaFilter])
  courses_in_target_yr <- unique(cleanData$course[target_yr_filter & actFilter & hsgpaFilter]) 
  common_courses <- intersect(courses_in_loop_yr, courses_in_target_yr) |> as.character()
  
  per_course_pca <- lapply(common_courses, function(loop_course){ 
    
    # print(loop_course)
    
    courseFilter <- cleanData$course == loop_course & !is.na(cleanData$course)  
    
    course_data <- cleanData[
      loop_yr_filter & courseFilter & actFilter
      , c("ACTMATH","HSGPA", "GRADEGPA")] |> droplevels()
    
  #  course_data_check <- cleanData[
  #    loop_yr_filter & courseFilter & actFilter
  #    , c("ACTMATH","HSGPA", "GRADEGPA", "class_year","course")] |> droplevels()
    
    course_data$PassFail <- ifelse(course_data$GRADEGPA >= 2.4, "Pass", "Fail")
    
    if(nrow(course_data) < 3){ return(NA) } else {
      
      course_pca <- PCA(course_data, 
                        quanti.sup = 3,
                        quali.sup = 4,
                        graph = FALSE) # |> 
        # flipPCA(vars_to_check = c("HSGPA", "ACTMATH")) # to ensure consistent sign application
       
    }
    
    })
  names(per_course_pca) <- common_courses
  return(per_course_pca)
})
names(rolling_pca) <- initial_year:final_year

no_of_years <- 3
initial_year <- min(cleanData$class_year)+no_of_years - 1
final_year <- max(cleanData$class_year)

rolling_pca_3 <- lapply(initial_year:final_year, function(loop_year){
  
  # Set filters
  target_yr_filter <- (cleanData$class_year %in% (loop_year + 1)) & !is.na(cleanData$class_year)
  loop_yr_filter <- cleanData$class_year %in% (loop_year - no_of_years +1 ):(loop_year) & !is.na(cleanData$class_year)
  courses_in_loop_yr <- unique(cleanData$course[loop_yr_filter & actFilter & hsgpaFilter])
  courses_in_target_yr <- unique(cleanData$course[target_yr_filter & actFilter & hsgpaFilter]) 
  common_courses <- intersect(courses_in_loop_yr, courses_in_target_yr) |> as.character()
  
  per_course_pca <- lapply(common_courses, function(loop_course){ 
    
    # print(loop_course)
    
    courseFilter <- cleanData$course == loop_course & !is.na(cleanData$course)  
    
    course_data <- cleanData[
      loop_yr_filter & courseFilter & actFilter
      , c("ACTMATH","HSGPA", "GRADEGPA")] |> droplevels()
    
    #  course_data_check <- cleanData[
    #    loop_yr_filter & courseFilter & actFilter
    #    , c("ACTMATH","HSGPA", "GRADEGPA", "class_year","course")] |> droplevels()
    
    course_data$PassFail <- ifelse(course_data$GRADEGPA >= 2.4, "Pass", "Fail")
    
    if(nrow(course_data) < 3){ return(NA) } else {
      
      course_pca <- PCA(course_data, 
                        quanti.sup = 3,
                        quali.sup = 4,
                        graph = FALSE) # |> 
      # flipPCA(vars_to_check = c("HSGPA", "ACTMATH")) # to ensure consistent sign application
      
    }
    
  })
  names(per_course_pca) <- common_courses
  return(per_course_pca)
})
names(rolling_pca_3) <- initial_year:final_year

# Check sign flip
# "Pass" centroid should always be higher than "Fail" along Dim.1

# checkSign <- lapply(rolling_pca, function(loop_year){ 
  
#  if(!is.list(loop_year)) {return(NA)}
  
#  lapply(loop_year, function(loop_course){ 
    
#    if(is.logical(loop_course)){return(NA)}
#    if (nrow(loop_course$quali.sup$coord) < 2) return(NA)
    
    #print(paste(loop_year, " ::: ", loop_course))    
#    checkVal <- loop_course$quali.sup$coord[1,1] < loop_course$quali.sup$coord[2,1]
#    return(checkVal)
#    })
  
#  })

# > checkSign |> unlist() |> table()

# FALSE  TRUE 
# 31   294

# which(!unlist(checkSign))

# invertedCentroids <- unlist(checkSign)[!unlist(checkSign) & !is.na(unlist(checkSign))] |> names()

# [1] "2005.MATH_1030" "2005.MATH_1060" "2007.MATH_2210" "2007.MATH_1040" "2008.MATH_1100"
# [6] "2008.MATH_1170" "2009.MATH_2210" "2009.MATH_1010" "2009.MATH_1090" "2010.MATH_1220"
# [11] "2010.MATH_2250" "2010.MATH_1170" "2012.MATH_1210" "2013.MATH_1030" "2013.MATH_1321"
# [16] "2014.MATH_1010" "2014.MATH_1080" "2014.MATH_1321" "2015.MATH_1311" "2015.MATH_1170"
# [21] "2016.MATH_1090" "2016.MATH_1311" "2017.MATH_1170" "2019.MATH_2270" "2019.MATH_1320"
# [26] "2020.MATH_1100" "2021.MATH_1100" "2021.MATH_1320" "2023.MATH_1040" "2024.MATH_2270"
# [31] "2024.MATH_1035"

# removing the function flipPCA didn't change this list.
# So I'll continue without it

# fviz_pca_biplot(rolling_pca[["2005"]][["MATH_1030"]], 
#                label = "var",
#                habillage = 4)

# at least one of these ("2024.MATH_2270") is due to a single person failing out of a class of 18.
# the first few puts the variables pointing upwards

# rolling_pca[["2005"]][["MATH_1030"]]$quanti.sup

# let's check the correlation

# cor(x = rolling_pca[["2005"]][["MATH_1030"]]$ind$coord[,1],
#    y = cleanData$HSGPA[cleanData$class_year == 2005 & cleanData$course == "MATH_1030" & actFilter & hsgpaFilter])
   # ruh roh

# do I care?

# loop_course <- "MATH_1030"
# loop_yr_filter <- cleanData$class_year == 2005
# courseFilter <- cleanData$course == loop_course & !is.na(cleanData$course)  

# course_data <- cleanData[
#  loop_yr_filter & courseFilter & actFilter
#  , c("ACTMATH","HSGPA", "GRADEGPA")] |> droplevels()

#  course_data_check <- cleanData[
#    loop_yr_filter & courseFilter & actFilter
#    , c("ACTMATH","HSGPA", "GRADEGPA", "class_year","course")] |> droplevels()

# course_data$PassFail <- ifelse(course_data$GRADEGPA >= 2.4, "Pass", "Fail")

# course_pca <- PCA(course_data, 
#                  quanti.sup = 3,
#                  quali.sup = 4,
#                  graph = FALSE)


#  course_pca_flip <- PCA(course_data, 
#                    quanti.sup = 3,
#                    quali.sup = 4,
#                    graph = FALSE) |> 
#    flipPCA(vars_to_check = c("HSGPA", "ACTMATH")) # to ensure consistent sign application
  

# fviz_pca_biplot(course_pca, 
#                                     label = "var",
#                                     habillage = 4,
#                                     title = "2005 MATH_1030 (no flip)")  

# fviz_pca_biplot(course_pca_flip, 
#                label = "var",
#                habillage = 4,
#                title = "2005 MATH_1030 (flip)")  

# I don't think I care, since I'm using the distance.  That doesn't have orientation.

# I think I'll remove the sign flip function, and I'll keep track of the check failures

  
# names(rolling_pca) <- 2006:2024

# I should save the PCA
# I need to include the "align_sign" function for consistency # TESTED AND ABANDONED
# I need to adjust the rolling PCA targets to accomodate the number of years # DONE
# (like, only start with a number that includes that minimum)

# I could incorporate the prediction in this loop
# Or I could do it separately, and leave this "rolling_pca" as nicely self-contained ?
# I'll do the prediction separately, even though it duplicates the loop structure


# Save the difference between the centroids
# C/should be an indicator of prediction accuracy for that course
# Another one is the percentage of failures per course

## CENTROID DIFF ##

centroidDiff <- lapply(rolling_pca, function(loop_yr_list){
  
  lapply(loop_yr_list, function(loop_course){ 
    
    if(any(is.na(loop_course))) {return(NA)}
    if(nrow(loop_course$quali.sup$coord) < 2 ) {return(NA)}
    
    # centroid_diff <- sqrt(sum((loop_course$quali.sup$coord["Pass",] - loop_course$quali.sup$coord["Fail",])^2))
    
    # for binary, the centroids are always collinear with 0, so I can use
    centroid_diff <- sum(loop_course$quali.sup$dist)
    
    return(centroid_diff)
    
    })
  
})

centroidDiff_3 <- lapply(rolling_pca_3, function(loop_yr_list){
  
  lapply(loop_yr_list, function(loop_course){ 
    
    if(any(is.na(loop_course))) {return(NA)}
    if(nrow(loop_course$quali.sup$coord) < 2 ) {return(NA)}
    
    # centroid_diff <- sqrt(sum((loop_course$quali.sup$coord["Pass",] - loop_course$quali.sup$coord["Fail",])^2))
    
    # for binary, the centroids are always collinear with 0, so I can use
    centroid_diff <- sum(loop_course$quali.sup$dist)
    
    return(centroid_diff)
    
  })
  
})


# unlist(centroidDiff) |> hist()

print("PCA complete")

stop("stop after PCA") # crashes after here for some reason

## PREDICTIONS ##

# Pick the PCA list to use
pca_list <- rolling_pca

no_of_years <- 1
initial_year <- min(cleanData$class_year)+no_of_years - 1
final_year <- max(cleanData$class_year)

rolling_pred <- lapply(initial_year:(final_year-1), function(loop_year){
  
  # Set filters
  target_yr_filter <- (cleanData$class_year %in% (loop_year + 1)) & !is.na(cleanData$class_year)
  loop_yr_filter <- cleanData$class_year %in% (loop_year - no_of_years +1 ):(loop_year) & !is.na(cleanData$class_year)
  courses_in_loop_yr <- unique(cleanData$course[loop_yr_filter & actFilter & hsgpaFilter])
  courses_in_target_yr <- unique(cleanData$course[target_yr_filter & actFilter & hsgpaFilter]) 
  common_courses <- intersect(courses_in_loop_yr, courses_in_target_yr) |> as.character()
  
  per_course_pred <- lapply(common_courses, function(loop_course){ 
    
    # print(loop_course)
    
    courseFilter <- cleanData$course == loop_course & !is.na(cleanData$course)  
    
    course_data <- cleanData[
      target_yr_filter & courseFilter & actFilter
      , c("ACTMATH","HSGPA")] |> droplevels()
    
    #  course_data_check <- cleanData[
    #    loop_yr_filter & courseFilter & actFilter
    #    , c("ACTMATH","HSGPA", "GRADEGPA", "class_year","course")] |> droplevels()
    
    #  course_data$PassFail <- ifelse(course_data$GRADEGPA >= 2.4, "Pass", "Fail")
    
    if(nrow(course_data) < 1){ return(NA) }
    if(any(is.na(pca_list[[as.character(loop_year)]][[loop_course]])) | any(is.null(pca_list[[as.character(loop_year)]][[loop_course]]))  ) {return(NA)}
      
      # predict(perCourse_pca[[math_course]], cleanData[yrFilter_2024 & loop_course_filter, c("HSGPA","ACTMATH") ])
      
      course_pred <- predict(pca_list[[as.character(loop_year)]][[loop_course]],
                        course_data) # |> 
      # flipPCA(vars_to_check = c("HSGPA", "ACTMATH")) # to ensure consistent sign application
   
      # CALCULATE THE DISTANCE      
      
      prior_coord <- cbind(pca_list[[as.character(loop_year)]][[loop_course]]$ind$coord, pca_list[[as.character(loop_year)]][[loop_course]]$ind$dist, pca_list[[as.character(loop_year)]][[loop_course]]$call$X)
      
      dim1_med <- aggregate(Dim.1 ~ PassFail, data = prior_coord, FUN = median)
      dim2_med <- aggregate(Dim.2 ~ PassFail, data = prior_coord, FUN = median)
      
      dist_fail <- sqrt( (course_pred$coord[,"Dim.1"] - dim1_med[1,2])^2 +
                           (course_pred$coord[,"Dim.2"] - dim2_med[1,2])^2
      )
      
      dist_pass <- sqrt(
        (course_pred$coord[,"Dim.1"] - dim1_med[2,2])^2 + 
          (course_pred$coord[,"Dim.2"] - dim2_med[2,2])^2
      )
      
      
      signed_dist <- dist_fail - dist_pass 
      
    

      
      return(
        list(course_pred = course_pred,
              distance = cbind(dist_fail, dist_pass, signed_dist),
              prior_median = c(dim1_med, dim2_med),
              target_yr = unique(cleanData$class_year[target_yr_filter]),
              course = loop_course,
              prior_coord = prior_coord
              )
      )
    
  })
  names(per_course_pred) <- common_courses
  return(per_course_pred)
})
names(rolling_pred) <- (initial_year+1):final_year

pca_list <- rolling_pca_3

no_of_years <- 3
initial_year <- min(cleanData$class_year)+no_of_years - 1
final_year <- max(cleanData$class_year)

rolling_pred_3 <- lapply(initial_year:(final_year-1), function(loop_year){
  
  # Set filters
  target_yr_filter <- (cleanData$class_year %in% (loop_year + 1)) & !is.na(cleanData$class_year)
  loop_yr_filter <- cleanData$class_year %in% (loop_year - no_of_years +1 ):(loop_year) & !is.na(cleanData$class_year)
  courses_in_loop_yr <- unique(cleanData$course[loop_yr_filter & actFilter & hsgpaFilter])
  courses_in_target_yr <- unique(cleanData$course[target_yr_filter & actFilter & hsgpaFilter]) 
  common_courses <- intersect(courses_in_loop_yr, courses_in_target_yr) |> as.character()
  
  per_course_pred <- lapply(common_courses, function(loop_course){ 
    
    # print(loop_course)
    
    courseFilter <- cleanData$course == loop_course & !is.na(cleanData$course)  
    
    course_data <- cleanData[
      target_yr_filter & courseFilter & actFilter
      , c("ACTMATH","HSGPA")] |> droplevels()
    
    #  course_data_check <- cleanData[
    #    loop_yr_filter & courseFilter & actFilter
    #    , c("ACTMATH","HSGPA", "GRADEGPA", "class_year","course")] |> droplevels()
    
    #  course_data$PassFail <- ifelse(course_data$GRADEGPA >= 2.4, "Pass", "Fail")
    
    if(nrow(course_data) < 1){ return(NA) }
    if(any(is.na(pca_list[[as.character(loop_year)]][[loop_course]])) | any(is.null(pca_list[[as.character(loop_year)]][[loop_course]]))  ) {return(NA)}
    
    # predict(perCourse_pca[[math_course]], cleanData[yrFilter_2024 & loop_course_filter, c("HSGPA","ACTMATH") ])
    
    course_pred <- predict(pca_list[[as.character(loop_year)]][[loop_course]],
                           course_data) # |> 
    # flipPCA(vars_to_check = c("HSGPA", "ACTMATH")) # to ensure consistent sign application
    
    # CALCULATE THE DISTANCE      
    
    prior_coord <- cbind(pca_list[[as.character(loop_year)]][[loop_course]]$ind$coord, pca_list[[as.character(loop_year)]][[loop_course]]$ind$dist, pca_list[[as.character(loop_year)]][[loop_course]]$call$X)
    
    dim1_med <- aggregate(Dim.1 ~ PassFail, data = prior_coord, FUN = median)
    dim2_med <- aggregate(Dim.2 ~ PassFail, data = prior_coord, FUN = median)
    
    dist_fail <- sqrt( (course_pred$coord[,"Dim.1"] - dim1_med[1,2])^2 +
                         (course_pred$coord[,"Dim.2"] - dim2_med[1,2])^2
    )
    
    dist_pass <- sqrt(
      (course_pred$coord[,"Dim.1"] - dim1_med[2,2])^2 + 
        (course_pred$coord[,"Dim.2"] - dim2_med[2,2])^2
    )
    
    
    signed_dist <- dist_fail - dist_pass 
    
    
    
    
    return(
      list(course_pred = course_pred,
           distance = cbind(dist_fail, dist_pass, signed_dist),
           prior_median = c(dim1_med, dim2_med),
           target_yr = unique(cleanData$class_year[target_yr_filter]),
           course = loop_course,
           prior_coord = prior_coord
      )
    )
    
  })
  names(per_course_pred) <- common_courses
  return(per_course_pred)
})
names(rolling_pred_3) <- (initial_year+1):final_year

## EXTRACT COORDINATES ## 

# I don't think I need this anymore

pred_coords <- lapply(rolling_pred, function(yr_pred){
  
  lapply(yr_pred, function(course_pred) {
  
  if(any(is.na(course_pred))) {NA} else {
    cbind(course_pred$coord, dist = course_pred$dist)
  }
  
    
  })  
    
})

pred_coords_3 <- lapply(rolling_pred_3, function(yr_pred){
  
  lapply(yr_pred, function(course_pred) {
    
    if(any(is.na(course_pred))) {NA} else {
      cbind(course_pred$coord, dist = course_pred$dist)
    }
    
    
  })  
  
})

## ASSEMBLE THE DATA ## 

# essentially a lot of unlisting here 


year_distance <- list()
yr_inc <- 0
for(year_name in names(rolling_pred_3)){ 
yr_inc <- yr_inc + 1

course_distances <- list()
course_inc <- 0
for(course_name in names(rolling_pred_3[[year_name]]) ) {
  
course_inc <- course_inc + 1

 #print(paste(i, inc))
 
 if( all(is.na(rolling_pred_3[[year_name]][[course_inc]]) ) ) { 
   
 course_distances[[course_inc]] <- NA } else {
 
 course_distances[[course_inc]] <- rolling_pred_3[[year_name]][[course_inc]][["distance"]] 
  
 }

names(course_distances)[[course_inc]] <- course_name

}

year_distance[[yr_inc]] <- course_distances
names(year_distance)[[yr_inc]] <- year_name
}

# ok, looks fine.  FINALLY!


distance_frame <- lapply(year_distance, function(x) {
  
  annual_frame <- do.call(rbind, x)
  
}) |>
  (\(x){ do.call(rbind,x)})()


# Merge back into cleanData

cleanData2 <- merge(cleanData, distance_frame, by = "row.names",all.x = TRUE)

# check

checkRows <- sample(row.names(distance_frame),10)

identical(cleanData[as.numeric(checkRows),c("course","EMPLID","class_year")],
          cleanData2[as.numeric(checkRows),c("course","EMPLID","class_year")]
) # FALSE
# well that's hopelessly scrambled

# I could figure out the cleanData unique ID, I guess, and pass that through the PCA

cleanData$rowid <- paste(cleanData$TERM, cleanData$EMPLID, cleanData$CATNBR, sep = "_" )

# identify dupes

theDupes <- table(cleanData$rowid) |>
  (\(x){x[order(x)]})() |>
  (\(x){x[x>1]})() |>
  names()

View(cleanData[cleanData$rowid %in% theDupes,])

# these five are all "Department of Science" but have multiple cohort dates
# I have a couple of choices:
  # Remove them (as there's only five)
  # Filter according to a rule (remove the first or second date)

# Since there are so few, and because I don't want to make a judgment call on the correct cohort date,
# I am going to filter them out.

# And I think I'll start vM2.


