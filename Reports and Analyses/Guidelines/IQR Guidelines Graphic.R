# IQR guidelines graphic

# PURPOSE:  Create a scatterplot of the courses (filtered to >B-) on ACTMATH
# by HSGPA with IQR radii 

library(lubridate)

##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))
creditLoad <- readRDS(here::here("Data", "Freshman_career_credit_load.rds"  ))

source(here::here("Functions", "Predict Math Success Functions.R"))

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

# zeroBinary
firstCourses$zero_binary <- NA
firstCourses$zero_binary <- ifelse(firstCourses$GRADE %in% c("E","EU"),"zero","not_zero")

# Combine grades
# ADJUSTED BINARY
firstCourses$D_binary <- NA
hiFilter <- firstCourses$GRADE %in% c("A", "A-", "B+", "B", "B-",  "C+", "C", "C-")
loFilter <- firstCourses$GRADE %in% c( "D+", "D", "D-") 
firstCourses$D_binary[hiFilter] <- "hi"
firstCourses$D_binary[loFilter] <- "low"

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

# zeroFilter
zeroFilter <- firstCourses$zero_binary != "zero"

# Combined filters
cleanData <- firstCourses[cleanFilters & outlierFilters & course_levelFilter & recent_filter & ageFilter & withdrawFilter,]
cleanData <- cleanData[!is.na(cleanData$cleanGrade),]
cleanData$cleanGrade <- droplevels(cleanData$cleanGrade)
cleanData$course <- factor(cleanData$course)

#################################
## DETAILS PER COURSE AND YEAR ##
#################################

gofer <- aggregate(cbind(HSGPA,ACTMATH) ~ course + class_year, 
          data = cleanData[cleanData$GRADEGPA > 2.4,], function(x){
           c(median = median(x),
             IQR = IQR(x)
             ) 
          }) |>
  (\(x){
  do.call(data.frame,x)
  })()
    
plot(x= gofer$HSGPA.median[gofer$class_year == 2024],
     y = gofer$ACTMATH.median[gofer$class_year == 2024],
     pch = 19,
     col = "dodgerblue")

# IQR Ellipse

library(DescTools)


DrawEllipse(
  x=3.8,
  y = 27,
  radius.x = 0.4975,
  radius.y = 3
  
  
)


DrawEllipse(
  x= gofer$HSGPA.median[gofer$class_year == 2024],
  y = gofer$ACTMATH.median[gofer$class_year == 2024],
  radius.x = gofer$HSGPA.IQR[gofer$class_year == 2024],
  radius.y = gofer$ACTMATH.IQR[gofer$class_year == 2024]
) # sheesh!



# Cluster
gofer$clust <- NA
clusterCount <- 6
for(yr in unique(gofer$class_year)){
clusterFilter <- gofer$class_year == yr

gofer$clust[clusterFilter] <- gofer |>
  (\(x){y <- x[clusterFilter , c("HSGPA.median","HSGPA.IQR","ACTMATH.median","ACTMATH.IQR") ]; return(y)})() |>
  dist() |>
  hclust() |>
  cutree(k=clusterCount) 
}

# Filter
plotFilter <- gofer$class_year == 2024 # & gofer$clust == 1

plot(x= gofer$HSGPA.median[plotFilter],
     y = gofer$ACTMATH.median[plotFilter],
     pch = 19,
     col = c("dodgerblue","gold4","forestgreen","purple", "red", "aquamarine3" )[gofer$clust[plotFilter]],
     xlim = c(3,4),
     ylim = c(10,36)
     )

ellipseFilter <- gofer$course == "MATH_1010" & gofer$class_year == 2024

DrawEllipse(
  x= gofer$HSGPA.median[plotFilter],
  y = gofer$ACTMATH.median[plotFilter],
  radius.x = gofer$HSGPA.IQR[plotFilter],
  radius.y = gofer$ACTMATH.IQR[plotFilter],
  col = NA,
  border = c("dodgerblue","gold4","forestgreen","purple","red" )[gofer$clust[plotFilter]]
)

# I should iterate through the years for the clustering
# crying out for plotly
# Shiny would be nice, too

# I can plot an individual point on there
# Can I filter to all the classes captured by an individual?  
#  The overlap with the IQR?  
#  That's a little more thinking  

# Eh, distance should be easy to calculate.

# I could also calculate the population within this IQR for each course.  

# I need to see how different 2023 and 2024 are, because 2024 would have been based on 2023.
# I also want to see how far off the low grades are.


# Change by year

hiGrades <- aggregate(cbind(HSGPA,ACTMATH) ~ course + class_year, 
                   data = cleanData[cleanData$GRADEGPA > 2.4,], function(x){
                     c(median = median(x),
                       IQR = IQR(x)
                     ) 
                   }) |>
  (\(x){
    do.call(data.frame,x)
  })()


lowGrades <- aggregate(cbind(HSGPA,ACTMATH) ~ course + class_year, 
                      data = cleanData[cleanData$GRADEGPA <= 2.4,], function(x){
                        c(median = median(x),
                          IQR = IQR(x)
                        ) 
                      }) |>
  (\(x){
    do.call(data.frame,x)
  })()


change.over.time <- hiGrades |>
  (\(x){x[order(x$course,x$class_year, decreasing = TRUE),]})() |>
  (\(x){aggregate(ACTMATH.median ~course, data =x, FUN = diff)})()

lapply(change.over.time[,2], mean) |> unlist()|> mean(na.rm=TRUE) # 0.257 # as I've noted, it's slightly shifted higher 

# but it's not much change over time, with a couple of exceptions 


change.over.time.GPA <- hiGrades |>
  (\(x){x[order(x$course,x$class_year, decreasing = TRUE),]})() |>
  (\(x){aggregate(HSGPA.median ~course, data =x, FUN = diff)})()

lapply(change.over.time.GPA[,2], mean) |> unlist() |> plot()
lapply(change.over.time.GPA[,2], mean) |> unlist() |> median(na.rm=TRUE) |> (\(val){abline(h=val)})()

# with some exceptions, pretty close to zero

# o.k., so 2024 should look a lot like 2023

# I could get fancier and cough up the most recent year 

compareGrades <- merge(hiGrades, lowGrades, by = c("course","class_year"), all = TRUE)

compareGrades$ACT.diff <- compareGrades$ACTMATH.median.y - compareGrades$ACTMATH.median.x 
compareGrades$HSGPA.diff <- compareGrades$HSGPA.median.y - compareGrades$HSGPA.median.x 

# well let's look closer at the positive values 

View(compareGrades[compareGrades$ACT.diff > 0 | compareGrades$HSGPA.diff,])

# Eh

# let's look at the biggest difference

# Eh
# let's plot these 

# Eh

# Let's build the cluster inside the plot function
# I want extensibility and control
# Col and shape by whichever I specify
# Use the feature map colors that I've already created


courseScatter <- function(
    data,
    dist_params = list(),
    hclust_params = list(),
    cutree_params = list(),
   featureMap = NA                        
) {
  
  # where data is an aggregation from cleanData as follows:
  
  # hiGrades <- aggregate(cbind(HSGPA,ACTMATH) ~ course + class_year, 
  #                      data = cleanData[cleanData$GRADEGPA > 2.4,], function(x){
  #                        c(median = median(x),
  #                          IQR = IQR(x)
  #                        ) 
  #                      }) |>
  #  (\(x){
  #    do.call(data.frame,x)
  #  })()
  
#############  
## CLUSTER ##
#############  
  
  data$clust <- NA
  
  if(!is.na(cluster)) {
    
    default_dist_params <- list(x=incoming, method = "euclidean")
    dist_params <- modifyList(default_dist_params, dist_params)
    
    default_hclust_params <- list(d = incoming, method = "complete")
    hclust_params <- modifyList(default_hclust_params, hclust_params)
    
    default_cutree_params <- list(tree=incoming, k=3)
    cutree_params <- modifyList(default_cutree_params, cutree_params)
    
    data$clust <- NA
    
    for(yr in unique(data$class_Year)){
      
      yearFilter <- data$class_year == yr
      
      data$clust <- data |>
        (\(x){x[yearFilter , c("HSGPA.median","HSGPA.IQR","ACTMATH.median","ACTMATH.IQR") ]; })() |>
        (\(incoming){do.call(dist, dist_params)})() |>
        (\(incoming){do.call(hclust, hclust_params)})() |>
        (\(incoming){do.call(cutree, cutree_params)})()
    }
    
    
  }
  

  
}


clusterCount <- 6
for(yr in unique(gofer$class_year)){
  clusterFilter <- gofer$class_year == yr
  
  gofer$clust[clusterFilter] <- gofer |>
    (\(x){y <- x[clusterFilter , c("HSGPA.median","HSGPA.IQR","ACTMATH.median","ACTMATH.IQR") ]; return(y)})() |>
    dist() |>
    hclust() |>
    cutree(k=clusterCount) 
}


#### After I made the "courseScatter" function
