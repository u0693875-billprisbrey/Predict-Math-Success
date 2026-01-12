---
title: "Source data, cleaning, and preparation"
date: "January 12, 2026"
output:
  html_document:
    keep_md: true
---

**PURPOSE:** This report describes the data sources, cleaning, and preparation used to recommend courses and predict grades. 






# Original SQL

Math courses taken by first time freshmen were queried as follows.  This data set is named "mathCourses" in the code below.  

```sql

  SELECT *
  FROM OBIA.COMBINED_COURSE_V
  WHERE (
        UPPER(DEPARTMENT)   LIKE '%MATH%'
     OR UPPER(TITLE)        LIKE '%MATH%'
     OR UPPER(SUBJECT_LONG) LIKE '%MATH%'
     OR UPPER(SUBJECT)      LIKE '%MATH%'
      )
  AND TERMEXTRACT IN ('E','S')
  AND EMPLID IN (
        SELECT EMPLID
        FROM OBIA.FTF_DEMO_V
      );


```
Data describing first time freshmen were queried as follows.  This data set is named "ftfData" in the code below.

```sql

SELECT * FROM OBIA.FTF_DEMO_V

```
The number of credits taken per student per term were queried as follows.  This data set is named "creditLoad" in the code below. 

```sql

SELECT
  TERM,
  EMPLID,
  SUM(UNITS) AS UNITS
FROM
  OBIA.COMBINED_COURSE_V
WHERE 
  TERMEXTRACT IN ('E','S')
  AND EMPLID IN (
        SELECT EMPLID
        FROM OBIA.FTF_DEMO_V
      )
GROUP BY
  TERM,
  EMPLID

```    

# Preparation Description

The first term each student took a math course was identified, and all math classes taken in that term are extracted.  

These initial math courses, student demographics (e.g. age and gender) and indicators of academic ability (e.g. ACT test scores and high school GPA), and the number of credit units per student per term are combined.   

Some new fields were defined.  A year difference (or *"yr_diff"*) was calculated as the difference between the cohort date and the end-of-term date in fractions of a year.  Medians and standard deviations for high school GPA and ACT math test scores per course per year for successful students who achieved a GPA greater than 2.4 (or at least a grade of B-minus) were calculated. 

A new feature was engineered. The distance (or *"dist"*) between a student's high school GPA and ACT math test scores and the prior year's median qualifications for successful students was calculated as a Euclidean distance susing the median-centered z-score.  (A possible improvement could calculate a Mahalanobis distance instead, as the two values are correlated.)

A variety of filters and transformations were applied as described below.  Most notably, only complete cases were used in modeling, or all records missing a value were removed.  This excluded the majority of students in recent years, as the rate of submitting ACT math test scores has precipitously declined.  

# Preparation Detail 

New fields were defined: 

  * *"class"* was defined as a combination of the fields TERM, CATNBR (catalog number), and SECTION.  
  * *"course"* was defined as a combination of the fields SUBJECT_CD (subject code) and CATNBR (catalog number).  
  * *"class_yr"* (class year) was defined as the year extracted from the field "EOTDATE" (end-of-term date).  
  * *"yr_diff"* (year difference) was defined as the difference between the fields "COHORT_DT" (cohort date) and "EOTDATE" (end-of-term date) in fractions of years.  
  * *season* was defined as "spring", "summer", or "fall" according to the identifier numbers 4, 6, or 8 in the "TERM" field.  
  * *course_level* was extracted as the "CATNBR" (catalog number) divided by 1000.  
  
One field was re-named: 

  * *"load"* replaced the term "UNITS" referring to the number of credits taken per student per term. 
  
Filters were applied:  

  * All math labs are filtered out (where "GRADE" is blank or has values of NA and "UNITS" is equal to zero.) 
  * All math classes taken after the first term per student that math classes are taken are filtered out. 
  * All courses with CATNBR values of 3000 and above are filtered out.  
  * "Withdraw" grades ("W") are removed. 
  * Courses that were not taught after the year 2021 were removed.  
  * All records with missing or 'NA' values were removed (only complete cases were used.)  

Outliers were removed: 

  * HSGPA values of zero (no high school GPA) 
  * Students aged less than eleven are filtered out.  
  * Unusually high credit load values are removed (greater than the 99th percentile) 
  * Early math classes are removed (yr_diff < -0.5, suggesting the class was taken during high school) 
  * Missing, rare or unusual grade values for this data set are removed (" ", "V", "I", "NC", "CR" and NA)  
    

Some field values were transformed:   

  * "APCREDIT" (advanced placement credit) values of NA are converted to zero. 
  * "GRADE" values of "EU" are converted to zero. 
  
Data sets were joined:  

  * Selected fields describing first time freshmen were  merged with the initial math courses data 
  * The number of credits ("UNITS" re-named as "load") were merged into this data set.  

New features were engineered: 

  * The median and standard deviation values for high school GPA and ACT math test scores were calculated per course per year for students who achieved a grade higher than 2.4 (or at least a B-minus.)   
  * The distance per student per qualification per course was calculated as the student's score minus the prior year's course median (for successful students) divided by the prior year's course standard deviation (for successful students), resulting in a median-centered z-score for the high school GPA and the ACT math test scores .  
  * A new field *"dist"* was calculated as the Euclidean distance in median-centered z-scores, or the square root of the ACT math test and high school GPA test scores first squared then added.  
  
# Code Detail 



``` r
##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))
creditLoad <- readRDS(here::here("Data", "Freshman_career_credit_load.rds"  ))

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

mathLabFilter <- 
  mathCourses$GRADE %in% c(" ", NA) &
  mathCourses$UNITS == 0

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

# Age buckets
firstCourses$age_cut <- cut(firstCourses$AGE, breaks = c(0,17,18,19,21,100))

# Age filter
ageFilter <- firstCourses$AGE > 11

print("Prep complete")
```

```
## [1] "Prep complete"
```

``` r
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

## CONVERT APCREDIT NA VALUES to ZERO ##  

firstCourses$APCREDIT[is.na(firstCourses$APCREDIT)] <- 0

print("Transformations complete")
```

```
## [1] "Transformations complete"
```

``` r
#################
## PRE-PROCESS ##
#################


# Select columns

# colnames(popCourses)

keepColumns <- c(
  "EMPLID"                      ,
  "course"                      ,
  "SEX"                         ,
  "FIRST_GEN_STATUS_CD"         ,
  "ETHNICITY"                   ,
  "RESSTAT"                     ,
  "FA_PELL"                     ,
  "APCREDIT"                    ,
  "HSGPA"                       ,
  "HSPRIVATE"                   ,
  "HONORS"                      ,
  "ACTCOMP"                     ,
  "ACTENGL"                     ,
  "ACTMATH"                     ,
  "ACTSCI"                      ,
  "cohort_year"                 ,
  "class_year"                  ,
  "yr_diff"                     ,
  "season"                      ,
  "course_level"                ,
  "age_cut"                     ,
  "cleanGrade"                  ,
  "HSGPA.z"                     ,
  "ACTMATH.z"                   ,
  "dist"
)

target_classes <- c("GRADEGPA") 

###########
## CLEAN ##
###########

cleanFilters <- !is.na(firstCourses$cleanGrade) & 
  !rareGrades
#!popCourses$cleanGrade %in% c("missing", "V", "I", "NC", "CR") 

# Outlier filters
zeroHSGPA_filter <- firstCourses$HSGPA == 0
highLoad_filter <- firstCourses$load > quantile(firstCourses$load, 0.99)
preMath_filter <- firstCourses$yr_diff < -0.5 # since all cohort dates start in September, I wanted to include the summer before the cohort date
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


# Merge to cleanData 

hiGrades$class_year_shift <- hiGrades$class_year + 1

cleanData <- merge(cleanData, hiGrades[,c("course", "class_year", "class_year_shift", "ACTMATH.median", "ACTMATH.stdev", "HSGPA.median", "HSGPA.stdev", "HSGPA.count")], by.x = c("course", "class_year"), by.y = c("course","class_year_shift"),  all.x=TRUE)

# Calculate distance as a z-score

cleanData$ACTMATH.z <- (cleanData$ACTMATH - cleanData$ACTMATH.median)/cleanData$ACTMATH.stdev
cleanData$HSGPA.z <- (cleanData$HSGPA - cleanData$HSGPA.median)/cleanData$HSGPA.stdev

  

cleanData$dist <- sqrt(
  ((cleanData$ACTMATH - cleanData$ACTMATH.median)/cleanData$ACTMATH.stdev)^2 +
    ((cleanData$HSGPA - cleanData$HSGPA.median)/cleanData$HSGPA.stdev)^2
)
```



# Data Detail


``` r
cleanData[  , c(target_classes, keepColumns)] |> 
    (\(x){x[complete.cases(x),]})() |>
  skim()
```


Table: Data summary

|                         |                            |
|:------------------------|:---------------------------|
|Name                     |(function(x) {
    x[comp... |
|Number of rows           |38920                       |
|Number of columns        |26                          |
|_______________________  |                            |
|Column type frequency:   |                            |
|character                |6                           |
|factor                   |4                           |
|numeric                  |16                          |
|________________________ |                            |
|Group variables          |None                        |


**Variable type: character**

|skim_variable       | n_missing| complete_rate| min| max| empty| n_unique| whitespace|
|:-------------------|---------:|-------------:|---:|---:|-----:|--------:|----------:|
|EMPLID              |         0|             1|   8|   8|     0|    38601|          0|
|SEX                 |         0|             1|   1|   1|     0|        2|          0|
|FIRST_GEN_STATUS_CD |         0|             1|   1|   1|     0|        3|          0|
|RESSTAT             |         0|             1|   1|   1|     0|        2|          0|
|HSPRIVATE           |         0|             1|   1|   1|     0|        2|          0|
|season              |         0|             1|   4|   6|     0|        3|          0|


**Variable type: factor**

|skim_variable | n_missing| complete_rate|ordered | n_unique|top_counts                                  |
|:-------------|---------:|-------------:|:-------|--------:|:-------------------------------------------|
|course        |         0|             1|FALSE   |       27|MAT: 8911, MAT: 6327, MAT: 5140, MAT: 3480  |
|ETHNICITY     |         0|             1|FALSE   |        9|C: 27934, H: 4843, A: 2802, M: 1864         |
|age_cut       |         0|             1|FALSE   |        5|(17: 31732, (18: 3341, (19: 1949, (0,: 1594 |
|cleanGrade    |         0|             1|FALSE   |       13|A: 11672, B: 4576, A_m: 4333, B_p: 3746     |


**Variable type: numeric**

|skim_variable | n_missing| complete_rate|    mean|    sd|      p0|     p25|     p50|     p75|    p100|hist  |
|:-------------|---------:|-------------:|-------:|-----:|-------:|-------:|-------:|-------:|-------:|:-----|
|GRADEGPA      |         0|             1|    2.86|  1.22|    0.00|    2.30|    3.30|    4.00|    4.00|▂▁▂▃▇ |
|FA_PELL       |         0|             1|    0.22|  0.41|    0.00|    0.00|    0.00|    0.00|    1.00|▇▁▁▁▂ |
|APCREDIT      |         0|             1|    7.32| 12.43|    0.00|    0.00|    0.00|   12.00|   85.00|▇▁▁▁▁ |
|HSGPA         |         0|             1|    3.63|  0.34|    1.07|    3.42|    3.72|    3.92|    4.42|▁▁▁▇▇ |
|HONORS        |         0|             1|    0.16|  0.37|    0.00|    0.00|    0.00|    0.00|    1.00|▇▁▁▁▂ |
|ACTCOMP       |         0|             1|   25.08|  4.36|   10.00|   22.00|   25.00|   28.00|   36.00|▁▃▇▆▂ |
|ACTENGL       |         0|             1|   24.86|  5.31|    7.00|   21.00|   24.00|   29.00|   36.00|▁▂▇▆▃ |
|ACTMATH       |         0|             1|   24.45|  4.64|    1.00|   21.00|   24.00|   27.00|   36.00|▁▁▅▇▂ |
|ACTSCI        |         0|             1|   24.98|  4.57|    2.00|   22.00|   24.00|   28.00|   36.00|▁▁▅▇▂ |
|cohort_year   |         0|             1| 2015.06|  5.34| 2005.00| 2011.00| 2016.00| 2019.00| 2024.00|▅▆▆▇▆ |
|class_year    |         0|             1| 2015.42|  5.26| 2006.00| 2011.00| 2016.00| 2020.00| 2025.00|▆▆▇▇▅ |
|yr_diff       |         0|             1|    0.51|  0.80|   -0.40|    0.24|    0.26|    0.26|   16.64|▇▁▁▁▁ |
|course_level  |         0|             1|    1.03|  0.18|    1.00|    1.00|    1.00|    1.00|    2.00|▇▁▁▁▁ |
|HSGPA.z       |         0|             1|   -0.54|  1.24|  -42.07|   -1.16|   -0.23|    0.32|    2.01|▁▁▁▁▇ |
|ACTMATH.z     |         0|             1|   -0.14|  1.12|  -10.00|   -0.81|    0.00|    0.51|    6.93|▁▁▇▅▁ |
|dist          |         0|             1|    1.42|  1.04|    0.00|    0.72|    1.18|    1.87|   42.07|▇▁▁▁▁ |
