# First math class sandbox
# 10.7.2025


# PURPOSE: The purpose of this sandbox is to identify the first math class per student. 

library(lubridate)

##########
## LOAD ##
##########

# ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))

##########
## PREP ##
##########

# convert to numeric
mathCourses$CATNBR <- as.numeric(as.character(mathCourses$CATNBR))
mathCourses$TERM <- as.numeric(as.character(mathCourses$TERM))


# identify unique classes
mathCourses$class <- paste(mathCourses$TERM, mathCourses$SUBJECT_CD, mathCourses$CATNBR, mathCourses$SECTION, sep= "_")

# identify unique courses
mathCourses$course <- paste(mathCourses$SUBJECT_CD, mathCourses$CATNBR, sep="_")

## PUT TERMS IN ORDER ##  

termDates <- unique(mathCourses[,c("TERM","EOTDATE")])

TD <- termDates[order(termDates$EOTDATE),]

# I just needed to see that.  Terms are already in chronological order

# ok, let's do this

# 
minTerm <- aggregate(TERM ~ EMPLID, data = mathCourses, min, na.rm = TRUE)

# for checking
minTerm$reference <- paste(minTerm$EMPLID, minTerm$TERM, sep = "_")

# now --- do I merge this back in, or do an "%in%" check?

mathCourses$minTerm <- paste(mathCourses$EMPLID, mathCourses$TERM, sep = "_") %in% minTerm$reference

table(mathCourses$minTerm)
FALSE   TRUE 
140838  76607 

# now I should compare that to Whitney's data

# But this is a pretty straight-forward data reduction
# I should be able to run vF0, and honestly get that done tonight




