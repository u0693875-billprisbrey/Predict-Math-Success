# Reconcile data sandbox
# 10.28.2025

# PURPOSE:  The purpose of this sandbox is to concretely identify and understand differences in 
# the data set prepared by me and prepared by Whitney Holt.

# This differs from "Compare data sandbox.R" in that this sandbox compares first time freshmen in their first math courses.

###################
## PRISBREY DATA ##
###################

library(lubridate)
library(tidyverse)
library(readxl)
library(skimr)

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

# add unique identifier key here 
mathCourses$key <- paste(mathCourses$EMPLID, mathCourses$CATNBR, mathCourses$TERM, sep = "_")
                   
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

firstCourses <- merge(firstCourses, ftfData[, c("EMPLID","COHORT_DT", "COHORTTERM", student_demographics, academic_prep)], by = "EMPLID",  all.x = TRUE)

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

# Unique Identifier
# firstCourses$key <- paste(firstCourses$EMPLID, firstCourses$CATNBR, firstCourses$TERM, sep = "_")

# Combined filters
cleanData <- firstCourses[cleanFilters & outlierFilters & course_levelFilter & recent_filter & ageFilter & withdrawFilter,]
cleanData <- cleanData[!is.na(cleanData$cleanGrade),]
cleanData$cleanGrade <- droplevels(cleanData$cleanGrade)

cleanData$course <- factor(cleanData$course)


###############
## HOLT DATA ##
###############

# Per Holt: 
# This dataset is a list of first-time students from Fall 2021, Fall 2022, Fall 2023, and Fall 2024 cohorts 
# along with those student's demographics, pre-UU academic performance, and the math course(s) 
# they took the first term they took math. There is one row per student per math course taken 
# in their first term they took math. I plan to further filter this list as part of my modeling  
# preparations, but this is the base dataset I plan to use. 


whData <- read_excel(here::here("Data", "WH Dataset - Math Placement Project - First Time Students from Fall 2021 - 2024 Cohorts and Their First Math Course 2025.09.30.xlsx"))

##########
## PREP ##
##########

whData <- whData[!is.na(whData$FIRST_MATH_COURSE_CATNBR),]

#######################
## UNIQUE IDENTIFIER ##
#######################

whData$key <- paste(whData$EMPLID, whData$FIRST_MATH_COURSE_CATNBR, whData$FIRST_MATH_TERM, sep = "_")

#################
## COMPARISONS ##
#################

all(whData$key %in% firstCourses$key) # FALSE
missingKeys <- setdiff(whData$key, firstCourses$key) # length(missingKeys) # 616

length(missingKeys)/length(whData$key) # I dropped 3%.  Not a lot, but enough I'd like to track down


all(whData$FIRST_MATH_COURSE_CATNBR %in% firstCourses$CATNBR) # TRUE 
all(whData$FIRST_MATH_TERM %in% firstCourses$TERM) # TRUE


all(whData$EMPLID %in% firstCourses$EMPLID) # FALSE
missingEmplids <- setdiff(whData$EMPLID, firstCourses$EMPLID) # that's interesting

# let's make sure the grades are the same

gradeCheck <- merge(whData[,c("key", "FIRST_MATH_COURSE_GRADE")], 
      firstCourses[,c("key", "GRADE")],
      by = "key",
      all.x = TRUE
      )

identical(gradeCheck$FIRST_MATH_COURSE_GRADE, gradeCheck$GRADE) # FALSE
gradeCheck$miss <- gradeCheck$FIRST_MATH_COURSE_GRADE == gradeCheck$GRADE

# > table(gradeCheck$miss)
# FALSE  TRUE 
# 2 17960 

# gradeCheck[!gradeCheck$miss & !is.na(gradeCheck$miss),]
# key FIRST_MATH_COURSE_GRADE GRADE  miss
# 9423 01415918_1090_1228                       W    D+ FALSE
# 9424 01415918_1090_1228                      D+     W FALSE

# so I guess the key has some dupes.
# that's interesting

firstCourses[firstCourses$key == "01415918_1090_1228", c("GRADE", "TERM", "class_year", "CATNBR")  ]


# > nrow(whData)
# [1] 18644
# > length(unique(whData$key))
# [1] 18643
# > nrow(firstCourses)
# [1] 62989
# > length(unique(firstCourses$key))
# [1] 62958

# whData looks a little tighter-- only one dupe made it through (two grades)  

theDupes <- table(firstCourses$key) |>
  (\(x){x[order(x, decreasing = TRUE)]})() |>
  (\(x){x[x>1]})()

length(theDupes) #31
max(theDupes) # 2

# View(firstCourses[firstCourses$key %in% names(theDupes),])

# I should see these for "cleanGrades" because these probably got cleaned out 
# Lots of rare grades and NA values in there

cleanDupes <- table(cleanData$key) |>
  (\(x){x[order(x, decreasing = TRUE)]})() |>
  (\(x){x[x>1]})()

length(cleanDupes) # 0 # THOUGHT SO!

# Determine per cohort term matches of EMPLID's and keys
# Where did she find "COHORTTERM" ?  I have COHORT_DT. # ADDED from ftfData in the merge
# table(cleanData[,c("COHORTTERM","COHORT_DT")]) # as expected, 1:1 with no blurring

whPerTerm <- lapply(unique(whData$COHORTTERM), function(x) {
  emplidPerTerm <- unique(whData$EMPLID[whData$COHORTTERM == x]) 
  keyPerTerm <- unique(whData$key[whData$COHORTTERM == x])
  return(list(emplid = emplidPerTerm, key = keyPerTerm))
  })
names(whPerTerm) <- unique(whData$COHORTTERM)

cleanPerTerm <- lapply(unique(cleanData$COHORTTERM), function(x) {
  emplidPerTerm <- unique(cleanData$EMPLID[cleanData$COHORTTERM == x]) 
  keyPerTerm <- unique(cleanData$key[cleanData$COHORTTERM == x])
  return(list(emplid = emplidPerTerm, key = keyPerTerm))
})
names(cleanPerTerm) <- unique(cleanData$COHORTTERM)

# now -- setdiff?  merge? mapply?

snakes <- merge(data.frame(emplid = whPerTerm[["1218"]][["emplid"]], wh = TRUE), data.frame(emplid = cleanPerTerm[["1218"]][["emplid"]], clean = TRUE), by = "emplid", all = TRUE  )

sapply(snakes, function(x) sum(is.na(x)))
# emplid     wh  clean 
# 0      5    595 

snakes[is.na(snakes)] <- FALSE

# so I have 5 emplids in WH that aren't in clean
# and I have 595 add'l emplids in clean that aren't in wh.  Huh.

View(snakes[!snakes$wh|!snakes$clean,])

600/nrow(snakes) # 13% diff.  Wow!

# let's convert this into a lapply

gorilla <- lapply(unique(whData$COHORTTERM), function(x){ 
  x <- as.character(x)
  EMPLIDs <- merge(data.frame(emplid = whPerTerm[[x]][["emplid"]], wh = TRUE), data.frame(emplid = cleanPerTerm[[x]][["emplid"]], clean = TRUE), by = "emplid", all = TRUE  )
  EMPLIDs[is.na(EMPLIDs)] <- FALSE
  keys <- merge(data.frame(key = whPerTerm[[x]][["key"]], wh = TRUE), data.frame(key = cleanPerTerm[[x]][["key"]], clean = TRUE), by = "key", all = TRUE  )
  keys[is.na(keys)] <- FALSE
  return(list(emplid = EMPLIDs, key = keys))
  })
names(gorilla) <- unique(whData$COHORTTERM)

# almost there ...

# looks like my data has a few hundred more EMPLIDs for some reason.

# I wonder if I just found the "rareGrades" that I've already filtered out.

missing1238 <- gorilla[["1238"]][["emplid"]][["emplid"]][gorilla[["1238"]][["emplid"]]["clean"] == FALSE]
missingKey1238 <- gorilla[["1238"]][["key"]][["key"]][gorilla[["1238"]][["key"]]["clean"] == FALSE]

View(whData[whData$key %in% missingKey1238,]) # not sure why they'd get peeled out

View(mathCourses[mathCourses$key %in% missingKey1238 & !mathLabFilter,]) 

# ok, looks like these are all getting filtered out of my data set eventually.
# I should be able to walk through my filters and figure out which ones are snagged by which filter.

length(missingKey1238) # 596
length(unique(missingKey1238)) # 596

# Full data
length((mathCourses$key[mathCourses$key %in% missingKey1238])) # 721
length(unique(mathCourses$key[mathCourses$key %in% missingKey1238])) # 596

# Math lab filter removed duplicates
length((mathCourses$key[mathCourses$key %in% missingKey1238 & !mathLabFilter])) # 596
length(unique(mathCourses$key[mathCourses$key %in% missingKey1238 & !mathLabFilter])) # 596

# cleanFilters 
mathCourses$key |>
  (\(x){x[!mathLabFilter]})() |> 
  (\(x){x[x$key %in% missingKey1238 ]})() |> length() 
  (\(x){x[cleanFilters]})() |> length()
  unique() |>
  length()

length((mathCourses$key[mathCourses$key %in% missingKey1238 & !mathLabFilter & cleanFilters])) # 596
length(unique(mathCourses$key[mathCourses$key %in% missingKey1238 & !mathLabFilter & cleanFilters])) # 596

# cleanFilters <- !is.na(firstCourses$cleanGrade) & !rareGrades

# Outlier filters
# zeroHSGPA_filter <- firstCourses$HSGPA == 0
# highLoad_filter <- firstCourses$load > quantile(firstCourses$load, 0.99)
# preMath_filter <- firstCourses$yr_diff < -0.5 # since all cohort dates start in September, I wanted to includ the summer before the cohort date
# outlierFilters <- !zeroHSGPA_filter & !highLoad_filter & !preMath_filter

# withdrawFilter
# withdrawFilter <- firstCourses$cleanGrade != "W"

# cleanData <- firstCourses[cleanFilters & outlierFilters & course_levelFilter & recent_filter & ageFilter & withdrawFilter,]


# so WH data has length(missingKey1238) = 596 keys that aren't in my cleanData.
# But all of these are in my mathCourses data (all(missingKey1238 %in% mathCourses$key) = TRUE).
# So which filter peeled them out?

# my filter game is confusing in this document.  But let's see what we got:

which(missingKey1238 %in% mathCourses$key) |> length() # 596
which(missingKey1238 %in% firstCourses$key) |> length() # 473 # firstCourses filters out math labs and only takes first term math classes
                                                        # So for 596-473= 123 students, WH thinks it's their first term and I don't

which(missingKey1238 %in% firstCourses$key[!zeroHSGPA_filter]) |> length() # 280
                                                                           # so I peeled out 473 - 280 = 193 more as not having a high school GPA

which(missingKey1238 %in% firstCourses$key[!zeroHSGPA_filter & !highLoad_filter]) |> length() # 266
                                                                                              # Another 280-266 = 14 explained


which(missingKey1238 %in% firstCourses$key[!zeroHSGPA_filter & !highLoad_filter & !preMath_filter]) |> length() # 212 # Another 266-212 = 54 explained

which(missingKey1238 %in% firstCourses$key[!zeroHSGPA_filter & !highLoad_filter & !preMath_filter & withdrawFilter]) |> length() # 49 # Another 212 - 54 = 163 explained  

which(missingKey1238 %in% firstCourses$key[!zeroHSGPA_filter & !highLoad_filter & !preMath_filter & withdrawFilter & cleanFilters]) |> length() # 15 Another 49 - 15 = 34

which(missingKey1238 %in% firstCourses$key[!zeroHSGPA_filter & !highLoad_filter & !preMath_filter & withdrawFilter & cleanFilters & ageFilter]) |> length() # 15 nothing additional

which(missingKey1238 %in% firstCourses$key[!zeroHSGPA_filter & !highLoad_filter & !preMath_filter & withdrawFilter & cleanFilters & ageFilter & course_levelFilter]) |> length() # 0 # The final 15 explained
which(missingKey1238 %in% firstCourses$key[!zeroHSGPA_filter & !highLoad_filter & !preMath_filter & withdrawFilter & cleanFilters & ageFilter & recent_filter]) |> length() # 0 # # also gets rid of them all

# I need to turn this into a nice little report

# But essentially --- like, do I need to do all the terms?  Or can I conclude that we're working from the same basic data sets? 

# I can probably add the terms in

filterList <- list(
  baseline = mathCourses$key,
  mathLab =  mathCourses$key[!mathLabFilter],
  firstTerm = mathCourses$key[firstTermFilter],
  course_level = firstCourses$key[course_levelFilter],
  recent = firstCourses$key[recent_filter],
  volume = firstCourses$key[courseFilter],
  age = firstCourses$key[ageFilter],
  clean = firstCourses$key[!is.na(firstCourses$cleanGrade)],
  rare = firstCourses$key[!rareGrades],
  withdraw = firstCourses$key[withdrawFilter],
  zeroHSGPA = firstCourses$key[!zeroHSGPA_filter],
  high_load = firstCourses$key[!highLoad_filter],
  pre_math = firstCourses$key[!preMath_filter],
  combined = cleanData$key[cleanFilters & outlierFilters & course_levelFilter & recent_filter & ageFilter & withdrawFilter]
)

sapply(filterList, function(x) sum(missingKey1238 %in% x))

# o.k., I like it
# let's do all the terms now, not just missingKey1238

missingKey1238 <- gorilla[["1238"]][["key"]][["key"]][gorilla[["1238"]][["key"]]["clean"] == FALSE]

missingCleanKeys <- unlist(lapply(names(gorilla), function(x){
  
  gorilla[[x]][["key"]][["key"]][gorilla[[x]][["key"]]["clean"] == FALSE]
  
}))

sapply(filterList, function(x) sum(missingCleanKeys %in% x))

# o.k., good.
# but now I need to go the other way-- not what is in WH and missing in clean, but what is in clean
# that is missing from wh?


missingWHKeys <- unlist(lapply(names(gorilla), function(x){
  
  # gorilla[[x]][["key"]][["key"]][gorilla[[x]][["key"]]["clean"] == FALSE]
  gorilla[[x]][["key"]][["key"]][gorilla[[x]][["key"]]["wh"] == FALSE]
  
  
}))

# only 27
# they are all spring and summer from 2021 (not many!)

# Let's at least drop this into a report so I can claim allll-l-l-l this work








# let's get the mean grade per year/course and make sure that matches.
# An idea:  In addition to your +1 year modeling, do +1 +plus some from that year to detect the year
# where the predictors stopped working (it's not just year.)






