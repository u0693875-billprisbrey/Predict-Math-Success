# Compare data sandbox
# 10.3.2025

# PRUPOSE:  The purpose of this file is to compare Whitney's data
# with the query and transformation I use in my modeling.

##############
## SETTINGS ##
##############

library(lubridate)

##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))

library(readxl)
wh_math <- read_excel(here::here("Data",  "WH Dataset - Math Placement Project - First Time Students from Fall 2021 - 2024 Cohorts & Their First Math Course 2025.09.30.xlsx"))

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

##############
## STRATEGY ##
##############

# wh_math described:

# This dataset is a list of first-time students from Fall 2021, Fall 2022, Fall 2023, and Fall 2024 cohorts along with those student's demographics, pre-UU academic performance, and the math course(s) they took the first term they took math. There is one row per student per math course taken in their first term they took math. I plan to further filter this list as part of my modeling preparations, but this is the base dataset I plan to use. 

# Since these datasets have different preparations, 
# they shouldn't be directly comparable.
# However, classes for matching courses in wh_math should be found identically in popCourses

## Compare courses

# First, let's see if wh_math has the same yearly instability

# huh, she doesn't have year in there

wh_math$year <- 2000 + (wh_math$FIRST_MATH_TERM %/% 10) %% 100

# and math isn't numeric

numeric_grade <- data.frame("letter_grade" = c(
  "B-",   "B+", "A",  "A-", "D+", "C",  "B",    "D",  "E", 
   "C-", "C+", "D-" 
),
"GRADEGPA" = c(2.7, 3.3, 4, 3.7, 1.3, 2, 3, 1, 0, 1.7, 2.3, 0.7
  
) )

rareGrades <- c("W", "EU", "V",  "I",  "NC", "CR")

wh_math <- merge(wh_math, numeric_grade, by.x = "FIRST_MATH_COURSE_GRADE", by.y= "letter_grade", all.x=TRUE)

boxplot(GRADEGPA ~ year,
  data = wh_math,
  col = "aliceblue"
)

# it's not crazy off what I have


aggregate(GRADEGPA~year+FIRST_MATH_COURSE_CATNBR, data = wh_math, mean, na.rm=TRUE)

wh_math$course <- paste(wh_math$FIRST_MATH_COURSE_SUBJECT_CD, wh_math$FIRST_MATH_COURSE_CATNBR, sep="_")

wh_byYear <- aggregate(GRADEGPA~year+course, data = wh_math, mean, na.rm=TRUE)

# that's a lot more courses than I did.

pop_byYear <- aggregate(GRADEGPA~year+course, data = popCourses, mean, na.rm = TRUE)

# courses in common

commonCourses <- intersect(unique(popCourses$course), unique(wh_math$course))

# let's compare

compareGPAmean <- merge(pop_byYear, wh_byYear, by = c("course","year"))
names(compareGPAmean)[grepl(".x", names(compareGPAmean))] <- "GRADEGPA_pop"
names(compareGPAmean)[grepl(".y", names(compareGPAmean))] <- "GRADEGPA_wh"

compareGPAmean$diff <- compareGPAmean$GRADEGPA_wh - compareGPAmean$GRADEGPA_pop

summary(compareGPAmean$diff)    

# Min.  1st Qu.   Median     Mean  3rd Qu.      Max. 
# -0.10435  0.08053  0.17118  0.22224  0.29767 0.88176 

# so Whitney's is always higher.  Huh.

# Does she include people who are taking it for the second time?
# Or only people taking it the first time?

# > head(compareGPAmean[order(compareGPAmean$diff, decreasing = TRUE),])
# course year GRADEGPA_pop GRADEGPA_wh      diff
# 38 MATH_2250 2022     2.998239    3.880000 0.8817613
# 33 MATH_2210 2021     2.970798    3.660741 0.6899430
# 29 MATH_1220 2021     2.774254    3.414379 0.6401254
# 30 MATH_1220 2022     2.988377    3.492857 0.5044806
# 34 MATH_2210 2022     3.133546    3.621053 0.4875063
# 31 MATH_1220 2023     3.107992    3.528169 0.4201770

whFilter <- wh_math$course == "MATH_2250" & wh_math$year == 2022
View(wh_math[viewFilter,])

# only five people (? huh?)

popFilter <- popCourses$course == "MATH_2250" & popCourses$year == 2022
View(popCourses[viewFilter,])

# a bajillion people

# looks like these data sets are pretty different.

# rather than just accept Whitney's data, I want to see if 
# I can end up there, to see if I understand the data correctly.

all(wh_math$EMPLID %in% popCourses$EMPLID) # FALSE
# now that is shocking!

emplid_in_wh <- setdiff(wh_math$EMPLID, popCourses$EMPLID)
length(emplid_in_wh) # 5137  # WOW!  Really?

skim(wh_math[wh_math$EMPLID %in% emplid_in_wh,])

# oh, I get it. No, no..... wait.  Huh?

missing <- wh_math[wh_math$EMPLID %in% emplid_in_wh,]

aggregate(EMPLID~year, data = missing, function(x){length(unique(x))} )


missing$year <- addNA(missing$year) # thanks Chat!

aggregate(EMPLID~year, data = missing, function(x){length(unique(x))} )

year EMPLID
1 2021    199
2 2022    203
3 2023    254
4 2024    555
5 2025     68
6 <NA>   3858

# So I'm missing a couple hundred per year ---
# and a bunch without a term.
# Do these also have a grade?

table(missing$GRADEGPA[missing$year == NA], useNA = "always")
sum(is.na(missing$GRADEGPA[missing$year == NA]))

View(missing) # Huh ?????

# This is spinning me in circles.  I better wrap up version D0 report
# and come back to this with fresh information  




