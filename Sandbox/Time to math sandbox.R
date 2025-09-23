# Time to math course EDA sandbox

# PURPOSE:  I'd like to figure out which year FTF complete their math courses.
# This is also my first look at combining FTF data and course data. 

##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))

## libraries
library(lubridate)

## 

intersect(colnames(ftfData), colnames(mathCourses))

# [1] "EMPLID"   "FULLNAME" # Wow ... that's it?  Really!

# Looks like I want "COHORT_DT" from freshman data, and I subtract that from EOTDATE

# And I wonder if how quickly can I predict the grade?

mData <- merge(mathCourses, ftfData[, c("EMPLID","COHORT_DT")], by = "EMPLID",  all.x = TRUE)

# I've gone up from 199533 rows in mathCourses to 199661 rows in mData

mData$yr_diff <-time_length(interval(mData$COHORT_DT, mData$EOTDATE), "years") %/% 1

class(mData$yr_diff) # difftime
hist(mData$yr_diff, breaks = c(min(mData$yr_diff):max(mData$yr_diff)))


View(mData[abs(mData$yr_diff) < 1,]) # that's like . . . HALF of the rows ?(!!!!)
# What's with all of the negative values?
# What are the Gen Ed's ?

# I need to see Whitney's queries

# let's find those top classes

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
# tempted to order this by term, then course, then emplid

# identify popular, high volume courses
mostPopCourses <- c("MATH_1050", "MATH_1210", "MATH_1010", "MATH_1220", "MATH_1030",
                    "MATH_1090", "MATH_1060", "MATH_2210", "MATH_1070", "MATH_2250") # identified via hierarchical clustering later in this report

# students_per_course |>
#  (\(x){x[order(x$EMPLID, decreasing = TRUE),]})() |>
#  (\(x){x[x$clust %in% 2:3,]})() |>
#  row.names()
# [1] "MATH_1050" "MATH_1210" "MATH_1010" "MATH_1220" "MATH_1030"
# [6] "MATH_1090" "MATH_1060" "MATH_2210" "MATH_1070" "MATH_2250"


mostPopFilter <- mathCourses$course %in% mostPopCourses
# extractFilter <- mathCourses$TERMEXTRACT == "E" # Managed via query

mathLabFilter <- 
  mathCourses$GRADE %in% c(" ", NA) &
  mathCourses$UNITS == 0

popCourses <- mathCourses[mostPopFilter &  !mathLabFilter,] # extractFilter &

###################################
## DETERMINE HIGH VOLUME COURSES ##
###################################

students_per_course <- aggregate(cbind(EMPLID, INSTEMPLID) ~ course , data = mathCourses[!mathLabFilter,], function(x) {length(unique(x))} )

# names(students_per_course) <- c("SUBJECT_COURSE","EMPLID","INSTEMPLID")

rownames(students_per_course) <- students_per_course[,1]
students_per_course <- students_per_course[,-1]

set.seed(43)
students_per_course_cluster <- students_per_course[,-2] |>
  #  log1p() |> 
  scale() |>
  dist(method = "euclidean") |> # binary dist with single method is very strange
  hclust(method = "complete") # liking average, complete

students_per_course$clust <- cutree(students_per_course_cluster, k = 3)

# Scatterplot

plot(x = log(students_per_course[,"EMPLID"]),
     y = log(students_per_course[,"INSTEMPLID"]),
     pch = c(rep(1,1), rep(19,10))[students_per_course[,"clust"]],
     col = c("darkgoldenrod1","purple", "dodgerblue", "aquamarine3", "chocolate" , "forestgreen", "blue")[students_per_course[,3]],
     xlab = "Count of students (log)",
     ylab = "Count of instructors (log)",
     main = "Course attendance\nbroken into three clusters"
)

# Table

library(kableExtra)

students_per_course |>
  (\(x){merge(x, unique(mathCourses[,c("course","TITLE")]), by.x = "row.names", by.y = "course" )})() |> # add the title
  (\(x){x[x$clust %in% 2:3,]} )() |> # filter to my small clusters
  (\(x){x[order(x$EMPLID, decreasing = TRUE),] })() |> # descending order of students
  (\(x){x$col <- cell_spec(
    x$clust,
    "html",
    color = "white",
    background = c("white","purple", "dodgerblue")[x$clust]
  ); 
  return(x)})() |> # add a column with the desired colors
  (\(x){x[,-which(colnames(x) %in% c("clust"))]})() |> # remove cluster column
  kbl(caption = "Count of students and instructors per course",
      col.names = c("Course", "Students", "Instructors", "Title", "Cluster"),
      row.names = FALSE,
      escape = FALSE
  ) |>
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE,
    font_size = 13
  )

##########################
## YEARS TO POP COURSES ##
##########################

pCourses <- merge(popCourses, ftfData[, c("EMPLID","COHORT_DT")], by = "EMPLID",  all.x = TRUE)

# I've gone up from 199533 rows in mathCourses to 199661 rows in mData

pCourses$yr_diff <-time_length(interval(pCourses$COHORT_DT, pCourses$EOTDATE), "years") %/% 1

hist(pCourses$yr_diff)

# let's break that out by course

par(mfrow = c(5,2), mar = c(4,2,0,0), oma = c(2,0,3,0))

invisible(
lapply(mostPopCourses, function(x) {
  
  hist(pCourses$yr_diff[pCourses$course ==x], breaks = -8:18,
       main = "", 
       #xaxt = "n",
       xlab = "",
       col = c(viridis::viridis(8, option = "inferno"), viridis::viridis(18, option = "viridis")))
  legend("topleft",x)
  
})
)

View(pCourses[pCourses$course == "MATH_2250",
              c("yr_diff", "COHORT_DT", "EOTDATE", 
                colnames(pCourses)[!colnames(pCourses) %in% c("yr_diff", "COHORT_DT", "EOTDATE") ]  )])

#  I think I want fractions of a year, maybe to two decimals,
# not the whole year.


