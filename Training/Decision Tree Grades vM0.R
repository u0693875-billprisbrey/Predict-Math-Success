# Decision Tree Grades vM0

# PURPOSE:  
# This runs one training model using regression and xgboost
# It trains on only the first math class for first time freshman.
# It uses data derived by Bill Prisbrey.
# It is similar to vH3, but it uses principal components per course

# This model is highly experimental and sandbox-like

# It ideally has these components:

# PCA for the previous year on just the two dimensions
#   Align the signage so dimensions are always consistent
# Centroids calculated for both successful and failing students
# Calculate isolation forest for both centroids (?)
# Predict the principal components for next year's students 
# Predict the isolation value for the next year's students
# Calculate the distance to center of both centroids (successful and failing) 
#    Experiment with a couple of methods
#  

library(caret)
library(xgboost)
library(lubridate)
library(factoextra)
library(FactoMineR)

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

# saveRDS(hiGrades, here::here("Data", "hiGrades from vH3.rds"))

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

##########################  
## PRINCIPAL COMPONENTS ##  
##########################  

yrFilter_2023 <- cleanData$class_year == 2023 & !is.na(cleanData$class_year)

actFilter <- !is.na(cleanData$ACTMATH)

courses_2023 <- unique(cleanData$course[yrFilter_2023 & actFilter]) 

perCourse_pca <- lapply(courses_2023, function(x){
  
  print(x)
  
  courseFilter <- cleanData$course == x & !is.na(cleanData$course)  
  
  course_data <- cleanData[
    yrFilter_2023 & courseFilter & actFilter
    , c("ACTMATH","HSGPA", "GRADEGPA")] |> droplevels()
  
  course_data$PassFail <- ifelse(course_data$GRADEGPA >= 2.4, "Pass", "Fail")
  
  if(nrow(course_data) < 3){ return(NA) } else {
  
  course_pca <- PCA(course_data, 
                      quanti.sup = 3,
                      quali.sup = 4,
                      graph = FALSE)

  }
  
  return(course_pca)
  
})

names(perCourse_pca) <- courses_2023

# plausible next steps --

# Plot all coord and compare
# Calculate "dist_pca" for the 2024 values of people who took these courses
# Compare to my current dist

fviz_pca_biplot(perCourse_pca[[23]], 
                label = "var",
                habillage = 4)

coords <- lapply(perCourse_pca, function(x){
  
  
  
  if(any(is.na(x))) {NA} else {
  cbind(x$ind$coord, x$ind$dist, x$call$X)
  }
    
})

combined_pca <- do.call(rbind, coords)

plot(x = combined_pca$Dim.1,
     y = combined_pca$Dim.2,
     pch = c(4,1)[factor(combined_pca$PassFail)],
     col = c("firebrick","forestgreen")[factor(combined_pca$PassFail)])

# Combining is just a bad idea.  These aren't the same thing.

mathCourse <- "MATH_1035"

plot(x = coords[[mathCourse]][["Dim.1"]],
     y = coords[[mathCourse]][["Dim.2"]],
     pch = c(4,1)[factor(coords[[mathCourse]][["PassFail"]])],
     col = c("firebrick","forestgreen")[factor(coords[[mathCourse]][["PassFail"]])]
     )

points(x = aggregate(coords[[mathCourse]][["Dim.1"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)[,2],
       y = aggregate(coords[[mathCourse]][["Dim.2"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)[,2],
       pch = c(4,1),
       col = c("firebrick","forestgreen"),
       cex=3,
       lwd = 3
         )

# o.k., I'm doing --- rolling three years, and...
# ... yeah medians

# I almost want an rmarkdown with all of these plotted






# Let's keep the per-course z-scores and focus on extracting the distance.


successful_perCourse_pca <- lapply(courses_2023, function(x){
  
  courseFilter <- cleanData$course == x & !is.na(cleanData$course)  
  gradeFilter <- cleanData$GRADEGPA >=2.4 & !is.na(cleanData$GRADEGPA)
  
  course_data <- cleanData[
    yrFilter_2023 & courseFilter & actFilter & gradeFilter
    , c("ACTMATH","HSGPA", "GRADEGPA")] |> droplevels()
  
#  course_data$PassFail <- ifelse(course_data$GRADEGPA >= 2.4, "Pass", "Fail")
  
  if(nrow(course_data) < 3){ return(NA) } else {
    
    course_pca <- PCA(course_data, 
                      quanti.sup = 3,
                      #quali.sup = 4,
                      graph = FALSE)
    
  }
  
  return(course_pca)
  
})

names(successful_perCourse_pca) <- courses_2023

# Extract distances
# Too soon


successful_coords <- lapply(successful_perCourse_pca, function(x){
  
  if(any(is.na(x))) {NA} else {
    cbind(x$ind$coord, x$ind$dist, x$call$X)
  }
  
})

# Calculate coordinates per course

yrFilter_2024 <- cleanData$class_year == 2024 & !is.na(cleanData$class_year)

common_courses <- intersect(as.character(courses_2023), cleanData$course[yrFilter_2024])

pred_pca <- lapply(common_courses,
       
       function(math_course){
         
         print(math_course)
         
         loop_course_filter <- cleanData$course == math_course
         
         if(any(is.na(perCourse_pca[[math_course]]))) {return(NA)}
         
         predict(perCourse_pca[[math_course]], cleanData[yrFilter_2024 & loop_course_filter, c("HSGPA","ACTMATH") ])
         
       }
       
       )
  
names(pred_pca) <- common_courses


# O.k, let's see what I've got here ---
# I want to plot the 2024 onto the 2023

coords_2024 <- lapply(pred_pca, function(x){
  
  
  
  if(any(is.na(x))) {NA} else {
    cbind(x$coord, x$dist)
  }
  
})


## 2023 and 2024 PLOTTED ##

mathCourse <- "MATH_1035"

plot(x = coords[[mathCourse]][["Dim.1"]],
     y = coords[[mathCourse]][["Dim.2"]],
     pch = c(4,1)[factor(coords[[mathCourse]][["PassFail"]])],
     col = c("firebrick","forestgreen")[factor(coords[[mathCourse]][["PassFail"]])]
)

points(x = aggregate(coords[[mathCourse]][["Dim.1"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)[,2],
       y = aggregate(coords[[mathCourse]][["Dim.2"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)[,2],
       pch = c(4,1),
       col = c("firebrick","forestgreen"),
       cex=3,
       lwd = 3
)

points(x = coords_2024[[mathCourse]][, "Dim.1"],
     y = coords_2024[[mathCourse]][,"Dim.2"],
     pch = 16,
     col = "gray30"
    # pch = c(3,6)[factor(coords_2024[[mathCourse]][["PassFail"]])],
    # lwd = 2,
    # col = c("firebrick","forestgreen")[factor(coords_2024[[mathCourse]][["PassFail"]])]
)

# honestly looks good
# with a decent prediction at drawing a vertical line at Dim.1 = 0

# now to calculate the distance

dim1_med = aggregate(coords[[mathCourse]][["Dim.1"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)
dim2_med = aggregate(coords[[mathCourse]][["Dim.2"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)

dist_fail <- sqrt(
  (coords_2024[[mathCourse]][, "Dim.1"] - dim1_med[1,2])^2 + 
  (coords_2024[[mathCourse]][, "Dim.2"] - dim2_med[1,2])^2
 )

dist_pass <- sqrt(
  (coords_2024[[mathCourse]][, "Dim.1"] - dim1_med[2,2])^2 + 
    (coords_2024[[mathCourse]][, "Dim.2"] - dim2_med[2,2])^2
)

# there's the absolute distance
# let's get a direction distance
# after a short break
  
signed_dist <- dist_fail - dist_pass 

# I better keep it this simple and see what I got

# o.k, time to train this, I think -- now that I have 
# distance and components 

# or, as it turns out, I'm only using the distance.
# Or I can use a model per course, but that's not a lot of numbers

cols <- colorRampPalette(c("red", "green"))(100)[
  cut(signed_dist, breaks = 100, labels = FALSE)
]

points(x = coords_2024[[mathCourse]][, "Dim.1"],
       y = coords_2024[[mathCourse]][,"Dim.2"],
       pch = 16,
       col = cols,
       # col = "gray30"
       # pch = c(3,6)[factor(coords_2024[[mathCourse]][["PassFail"]])],
       # lwd = 2,
       # col = c("firebrick","forestgreen")[factor(coords_2024[[mathCourse]][["PassFail"]])]
)

# eggs-cellent!

## FULL PLOT ##

# This is a good candidate for a function 

mathCourse <- "MATH_1090"

plot(x = coords[[mathCourse]][["Dim.1"]],
     y = coords[[mathCourse]][["Dim.2"]],
     pch = c(4,1)[factor(coords[[mathCourse]][["PassFail"]])],
     col = c("firebrick","forestgreen")[factor(coords[[mathCourse]][["PassFail"]])]
)

points(x = aggregate(coords[[mathCourse]][["Dim.1"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)[,2],
       y = aggregate(coords[[mathCourse]][["Dim.2"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)[,2],
       pch = c(4,1),
       col = c("firebrick","forestgreen"),
       cex=3,
       lwd = 3
)

dim1_med = aggregate(coords[[mathCourse]][["Dim.1"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)
dim2_med = aggregate(coords[[mathCourse]][["Dim.2"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)

dist_fail <- sqrt(
  (coords_2024[[mathCourse]][, "Dim.1"] - dim1_med[1,2])^2 + 
    (coords_2024[[mathCourse]][, "Dim.2"] - dim2_med[1,2])^2
)

dist_pass <- sqrt(
  (coords_2024[[mathCourse]][, "Dim.1"] - dim1_med[2,2])^2 + 
    (coords_2024[[mathCourse]][, "Dim.2"] - dim2_med[2,2])^2
)


signed_dist <- dist_fail - dist_pass 

cols <- colorRampPalette(c("red", "green"))(100)[
  cut(signed_dist, breaks = 100, labels = FALSE)
]

points(x = coords_2024[[mathCourse]][, "Dim.1"],
       y = coords_2024[[mathCourse]][,"Dim.2"],
       pch = 16,
       col = cols
)

# All courses

pred_dist <- lapply(common_courses, function(mathCourse){
  
  if(any(is.na(coords[[mathCourse]]))) {return(NA)} 
                  
  dim1_med = aggregate(coords[[mathCourse]][["Dim.1"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)
  dim2_med = aggregate(coords[[mathCourse]][["Dim.2"]], by = list(coords[[mathCourse]][["PassFail"]]), FUN = median)
  
  dist_fail <- sqrt(
    (coords_2024[[mathCourse]][, "Dim.1"] - dim1_med[1,2])^2 + 
      (coords_2024[[mathCourse]][, "Dim.2"] - dim2_med[1,2])^2
  )
  
  dist_pass <- sqrt(
    (coords_2024[[mathCourse]][, "Dim.1"] - dim1_med[2,2])^2 + 
      (coords_2024[[mathCourse]][, "Dim.2"] - dim2_med[2,2])^2
  )
  
  
  signed_dist <- dist_fail - dist_pass 
  
  return(cbind(fail_dist = dist_fail, pass_dist = dist_pass, rel_dist = signed_dist))
                    
                    })
names(pred_dist) <- common_courses

# ok, now we can merge and predict

pred_dist_frame <- do.call(rbind, pred_dist)

cleanData <- merge(cleanData, pred_dist_frame, by = "row.names", all.x = TRUE)

# how do I double-check this?

View(cleanData[,c(keepColumns, "fail_dist","pass_dist","rel_dist")])

cor(cleanData$dist, cleanData$pass_dist, use = "complete.obs") #0.98
# Wow, ok, so that's the same thing!

plot(x= cleanData$dist,
     y = cleanData$pass_dist,
     xlim = c(0,10))

# well, o.k.
# Not sure it was worth doing that...

cols <- colorRampPalette(c("red", "green"))(100)[
  cut(cleanData$GRADEGPA, breaks = 100, labels = FALSE)
]

plot(x= cleanData$pass_dist,
     y = cleanData$rel_dist,
     #xlim = c(0,10)
     col= cols
     )

boxplot(dist ~ GRADEGPA, data = cleanData[cleanData$class_year == 2024,], outline = FALSE)
boxplot(pass_dist ~ GRADEGPA, data = cleanData[cleanData$class_year == 2024,], outline = FALSE)
boxplot(fail_dist ~ GRADEGPA, data = cleanData[cleanData$class_year == 2024,], outline = FALSE)
boxplot(rel_dist ~ GRADEGPA, data = cleanData[cleanData$class_year == 2024,], outline = FALSE)

# ok, I like it!

# I mean, it's...one match and one additional feature

# onto training

stop("Next step is the training loop")

###########
## SPLIT ##
###########

# Initially take a subset
set.seed(123)

xgb.set.config(verbosity = 0)   # 0 = silent, 1 = warning, 2 = info, 3 = debug

lapply(target_classes,
       
       
       function(target){
         
         # establish sample of complete cases
         popSample <- cleanData[  , c(target,keepColumns, "fail_dist", "pass_dist","rel_dist")] |> # no sampling index 
           (\(x){x[complete.cases(x),]})()
         
         ## SPLIT ##  
         
         # Use cleanGrade to partition on, but drop it for the test and train data
         # trainIndex <- createDataPartition(popSample$cleanGrade, p = 0.8, list = FALSE)
         
         # Use class_year 2024 and 2025 as the test set
         trainIndex <- which(popSample$class_year < 2024)
         
         trainData <- popSample[trainIndex, c(target, keepColumns[-which(keepColumns %in% c("cleanGrade","EMPLID") )])]
         testData  <- popSample[-trainIndex, c(target, keepColumns[-which(keepColumns %in% c("cleanGrade", "EMPLID") )])]
         
         #       return(list(training = trainData, testing = testData))
         
         theData <- list(training = trainData, testing = testData, trainID = popSample$EMPLID[trainIndex], testID = popSample$EMPLID[-trainIndex] )
         
         #     })
         
         
         saveRDS(theData, here::here("Data", paste("Decision Tree vM0", target, "Data.rds")))
         
         
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
           nrounds = 600,          # scale boosting rounds for dataset size
           eta = c(0.05, 0.1),     # conservative learning rates
           max_depth = c(4, 6),    # tree depth
           gamma = 0,              # minimal regularization
           colsample_bytree = 0.8, # prevent overfitting
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
               preProcess = c("zv", "nzv", "center", "scale", "knnImpute"),
               tuneGrid = xgb_grid,
               weights = weights            
             )
           )
         
         endTime <- Sys.time()
         
         print(endTime-startTime)
         print(endTime-startTime)
         print(endTime-startTime)
         
         saveRDS(fit, here::here("Models", paste("Decision Tree vM0", target, "model.rds")))
         
         library(beepr)
         beep(8); Sys.sleep(6); #beep(0); Sys.sleep(3); beep(0)
         
       })



