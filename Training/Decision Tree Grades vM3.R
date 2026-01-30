# DECISION TREE GRADES vM3

model_version <- "vM3"

# PURPOSE:
# Perform a model that only uses the principal component derivatives and 
# removes the z-score derivatives

# This model includes three features -- "dist_fail", "dist_pass", and "signed_dist", which
# are the differences between the pass/fail medoid (separated at 2.4 GPA) and the predicted
# principal component coordinates of the following year.  "Signed_dist" is the difference 
# between these distances. These distances were meant to improve on the z-score distances.

# This model removes z-scores and their derivative: "ACTMATH.z", "HSGPA.z", and "dist"

# This model used a PCA calculated on a rolling three years prior.

# This model didn't improve, in fact worsened, from the z-scores (R^2 of 0.23, where
# z-scores had 0.26).

# This script will not complete when sourced.  I suspect the package "FactoMiner" is not updated.



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

# prepare FTF data

# Remove students with multiple values for COHORT_DT in FTF data
# problemIDs <- c("00517160", "00572252", "00280932", "00643029", "00548206")

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

# stop("Prior to merge with difficult filter")

firstCourses <- merge(firstCourses, ftfData[!duplicateFilter, c("EMPLID","COHORT_DT", student_demographics, academic_prep)], by = "EMPLID",  all.x = TRUE)

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

# Add row_id
cleanData$rowid <- paste("ID",cleanData$TERM, cleanData$EMPLID, cleanData$CATNBR, sep = "_" )

# stop("Stop after cleaning")
print("Clean complete")

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

cleanData_orig <- cleanData
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

print("Z-scores added")
stop("Starting principal components")

##########################  
## PRINCIPAL COMPONENTS ##  
##########################  

# Filters

actFilter <- !is.na(cleanData$ACTMATH)
hsgpaFilter <- !is.na(cleanData$HSGPA) & cleanData$HSGPA > 0

# Convert rowid to row names
rownames(cleanData) <- cleanData$rowid

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

print("PCA complete")

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

print("CENTROID DIFF COMPLETE")

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

print(rep("PREDICTION 1 COMPLETE\n",3))


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

print("PCA predictions complete") 

## EXTRACTING AND MERGING DATA ## 

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

print(rep("DISTANCE EXTRACTED\n",3))

distance_frame <- lapply(year_distance, function(x) {
  
  annual_frame <- do.call(rbind, x)
  
}) |>
  (\(x){ do.call(rbind,x)})() |>
  as.data.frame()

# stop("Distance extracted")

# Merge back into cleanData
cleanData_orig <- cleanData

cleanData <- merge(cleanData, as.data.frame(distance_frame), by = "row.names",all.x = TRUE)
row.names(cleanData) <- cleanData$Row.names
cleanData$Row.names <- NULL

####################
## SELECT COLUMNS ##
####################

# > colnames(cleanData)


keepColumns <- c(
  "course"              ,                      
  "class_year"           ,       
  # "TERM"                  ,      
  "EMPLID"                 ,     
  # "class"                ,       
  # "CATNBR"               ,       
  # "TITLE"                ,       
  # "SECTION"              ,       
  # "UNITS"                ,       
  # "GRADE"                ,       
  # "GRADEGPA"             ,       
  # "INSTEMPLID"           ,       
  # "INSTNAME"             ,       
  # "EOTDATE"              ,       
  # "ACADYR"               ,       
  # "TERMEXTRACT"          ,       
  # "MAX_SNAP"             ,       
  # "CENSUSDATE"           ,       
  # "ALT_ID"               ,       
  # "FULLNAME"             ,       
  # "STUDENTCAREER"        ,       
  # "SUBJECT_CD"           ,       
  # "SUBJECT_NAME"         ,       
  # "SUBJECT_LONG"         ,       
  # "SUBJECT_ACAD_ORG_CD"  ,       
  # "CATNBR2"              ,       
  # "CLASSNBR"             ,       
  # "OFFERINGNBR"          ,       
  # "SESSIONCODE"          ,       
  # "COURSECAREER"         ,       
  # "SCHEDFLAG"            ,       
  # "WAUTOENRL"            ,       
  # "AUTOENROLL"           ,       
  # "COMPONENT"            ,       
  # "GENED"                ,       
  # "VARCREDIT"            ,       
  # "CONTRACT"             ,       
  # "DIRECTPAY"            ,       
  # "CORRESPONDENCE"       ,       
  # "ONLINECOURSE"         ,       
  # "IVC"                  ,       
  # "IVC_HYBRID"           ,       
  # "COURSE_MODALITY"      ,       
  # "INSTRUCTION_MODE"     ,       
  # "TELECOURSE"           ,       
  # "STUDYABROAD"          ,       
  # "EDNET"                ,       
  # "HYBRIDCOURSE"         ,       
  # "COURSE_LEVEL"         ,       
  # "USHE_COURSE_LEVEL"    ,       
  # "FISCAL_YEAR_OF_STARTDT" ,       
  # "VP"                     ,     
  # "VP_SHORT"               ,     
  # "VP_FORMAL"              ,     
  # "ACAD_COLLEGE_CD"        ,     
  # "COLLEGE"                ,     
  # "COLLEGE_SHORT"          ,     
  # "COLLEGE_FORMAL"         ,     
  # "ACAD_COLLEGE_REG_SUPP"  ,     
  # "ACAD_COLLEGE_TYPE"           ,    
  # "ACAD_COLLEGE_CIP_CD"         ,
  # "ACAD_DEPARTMENT_CD"          ,
  # "DEPARTMENT"                  ,
  # "DEPARTMENT_SHORT"            ,
  # "DEPARTMENT_FORMAL"           ,
  # "ACAD_DEPARTMENT_REG_SUPP"    ,
  # "ACAD_DEPARTMENT_TYPE"        ,
  # "ACAD_DEPARTMENT_CIP_CD"      ,
  # "ACAD_DIVISION_CD"            ,
  # "DIVISION"                    ,
  # "DIVISION_SHORT"              ,
  # "DIVISION_FORMAL"             ,
  # "ACAD_DIVISION_REG_SUPP"      ,
  # "ACAD_DIVISION_TYPE"          ,
  # "ACAD_DIVISION_CIP_CD"        ,
  # "VP_CD"                       ,
  # "COLLEGE_CD"                  ,
  # "DEPARTMENT_CD"               ,
  # "DIVISION_CD"                 ,
  # "ROLLUP_SORT_ORDER"           ,
  # "PS_ACAD_ORG"                 ,
  # "PS_ACAD_GROUP"               ,
  # "CAMPUS"                      ,
  # "COURSE_CAMPUS"               ,
  # "USHE_SITE_TYPE_CD"           ,
  # "USHE_SITE_TYPE"              ,
  # "ONOFFCAMPUS"                 ,
  # "COURSELOCATION"              ,
  # "CONTACTMINUTES"              ,
  # "TEAMTAUGHT"                  ,
  # "XLIST"                       ,
  # "BEGTIME1"                    ,
  # "BEGTIME2"                    ,
  # "BEGTIME3"                    ,
  # "DAYS1"                       ,
  # "DAYS2"                       ,
  # "DAYS3"                       ,
  # "ENDTIME1"                    ,
  # "ENDTIME2"                    ,
  # "ENDTIME3"                    ,
  # "CLASSLOC1"                   ,
  # "CLASSLOC2"                   ,
  # "CLASSLOC3"                   ,
  # "CLASSLOCBUILDNAME1"          ,
  # "CLASSLOCBUILDROOM1"          ,
  # "CLASSLOCBUILDNAME2"          ,
  # "CLASSLOCBUILDROOM2"          ,
  # "CLASSLOCBUILDNAME3"          ,
  # "CLASSLOCBUILDROOM3"          ,
  # "STARTDT"                     ,
  # "ENDDT"                       ,
  # "BUDGETCODE"                  ,
  # "LINEITEM"                    ,
  # "SERVICELEARNING"             ,
  # "XLIST_ID"                    ,
  # "COMBINEDID"                  ,
  # "USHE_ACADYR"                 ,
  # "USHE_TERM"                   ,
  # "TERM2"                       ,
  # "ORG_EFFDT"                   ,
  # "CLASSENROLLMENTCAPACITY"     ,
  # "ROOM_MAX_1"                  ,
  # "ROOM_MAX_2"                  ,
  # "ROOM_MAX_3"                  ,
  # "TERM_NBR"                    ,
  # "CLASS_ATTR_LIST"             ,
  # "EXCLUDE_BUDGET_SCH"             ,
  # "SPR_CORRECTION_NOT_USHE_FLAG"   ,
  # "Section Divider: OLD"           ,
  # "SUBJECTCOLL"                    ,
  # "SUBJECT"                     ,
  # "class.1"                     ,
  # "minTerm"                     ,
  # "COHORT_DT"                   ,
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
  # "load"                        ,
  "cohort_year"                 ,
  "yr_diff"                     ,
  "season"                      ,
  "course_level"                ,
  # "vol_cluster"                 ,
  "age_cut"                     ,
  "cleanGrade"                  ,
  # "wdraw_binary"                ,
  # "grade_binary"                ,
  # "grade_trinary"               ,
  # "grade_quad"                  ,
  # "rowid"                       ,
  # "class_year.y"                ,
  # "ACTMATH.median"              ,
  # "ACTMATH.stdev"               ,
  # "HSGPA.median"                ,
  # "HSGPA.stdev"                 ,
  # "HSGPA.count"                 ,
#  "ACTMATH.z"                   ,
#  "HSGPA.z"                     ,
#  "dist"                        ,
  "dist_fail"                   ,
  "dist_pass"                   ,
  "signed_dist"
)

###########
## TRAIN ##
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

target_classes <- "GRADEGPA"

lapply(target_classes,
       
       
       function(target){
         
         # establish sample of complete cases
         popSample <- cleanData[  , c(target,keepColumns)] |> # no sampling index 
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
         
         
         saveRDS(theData, here::here("Data", paste("Decision Tree", model_version, target, "Data.rds")))
         
         
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
               preProcess = c("zv", "nzv", "center", "scale", "knnImpute"),
               tuneGrid = xgb_grid,
               weights = weights            
             )
           )
         
         endTime <- Sys.time()
         
         print(endTime-startTime)
         print(endTime-startTime)
         print(endTime-startTime)
         
         saveRDS(fit, here::here("Models", paste("Decision Tree", model_version, target, "model.rds")))
         
         library(beepr)
         beep(8); Sys.sleep(6); #beep(0); Sys.sleep(3); beep(0)
         
       })

