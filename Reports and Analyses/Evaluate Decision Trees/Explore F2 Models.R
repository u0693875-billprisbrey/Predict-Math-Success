# Explore F2 Model and First Time Math Courses

# PURPOSE:  This takes a look at the first math courses and the 
# F2 model predictors.  

# It will probably be used to determine a filter that excludes rare 
# or advanced math classes ahead of running the next model. 

# Copying from Decision Tree Grades vF2:

library(caret)
library(xgboost)
library(lubridate)

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


print("Prep complete")

## GRADE TRANSFORMATIONS ## 

# convert grade value names to values compatible with R naming

clean_grade <- function(x) {
  x <- as.character(x)
  x <- gsub("-", "_minus", x)   # replace '-' with '_minus'
  x <- gsub("\\+", "_plus", x)  # replace '+' with '_plus'
  x <- gsub(" ", "missing", x)  # replace spaces with "missing"
  
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
# popCourses$wdraw_binary <- NA
# popCourses$wdraw_binary <- ifelse(popCourses$GRADE == "W","withdraw","not_withdraw")


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
## EXPLORATORY ##
#################

table(firstCourses$course) |>
  (\(x){ x[order(x, decreasing = TRUE)] })() |>
  barplot()

# I could use "hierarchical clustering" to select courses
# I also want to extract the 1000 level

firstCourses$course_level <- firstCourses$CATNBR %/% 1000

table(firstCourses$course_level) |>
  (\(x){ x[order(x, decreasing = TRUE)] })() |>
  log() |>
  barplot()

# let's exclude everything greater than 3000 level

course_levelFilter <- firstCourses$course_level < 3
table(firstCourses$course[course_levelFilter]) |>
  (\(x){ x[order(x, decreasing = TRUE)] })() |>
  barplot()

# there's one obvious cliff, and maybe a second
# Would it matter to lump these?

# But I def want to filter out some courses and re-run the model

boxplot(GRADEGPA ~ course,
        data = firstCourses[course_levelFilter,])

boxplot(GRADEGPA ~ course,
        data = firstCourses[course_levelFilter,], 
        horizontal = TRUE, col = "aliceblue", outline=FALSE)

# that's an ugly plot
# It would be nice to have some meaningful ways to bucket or order these

# Notice the medians at 4.0 for some of these courses
# No indication of count or size for these


# This is a very graceful graphic
boxplot(HSGPA ~ GRADEGPA,
        data = firstCourses[course_levelFilter,])

# wow --- some unexpected behavior at the bottom grades
# It really only pulls away for the 4.0
boxplot(ACTMATH ~ GRADEGPA,
        data = firstCourses[course_levelFilter,])

# least boxplot ever
boxplot(yr_diff ~ GRADEGPA,
        data = firstCourses[course_levelFilter,])

hist(firstCourses$yr_diff[course_levelFilter],
     breaks = -10:20) # it's all year 1, overwhelmingly

firstCourses$yr_diff_cut <- cut(firstCourses$yr_diff,
                                c(-1000,-0.5,0,1,2,1000)
                                )

boxplot(GRADEGPA ~ cut(yr_diff,
            c(-1000,-0.5,0,1,2,1000)
),
        data = firstCourses[course_levelFilter,])


# wow, unexpected.  More years is a HIGHER grade !
# How do I reconcile that with the other graphic?  Double-check!

cor(x=firstCourses$GRADEGPA, firstCourses$yr_diff, use = "complete.obs" )

# I need to do a reality check for these people completing the
# course five years before enrolling.

plot(y = firstCourses$AGE,
     x = firstCourses$yr_diff)

# I like this one better
plot(x = firstCourses$AGE,
     y = firstCourses$yr_diff) 

# looks like we've got a toddler
# I could clean that out I guess

# head(sort(firstCourses$AGE), 5)
# [1]  1 12 14 14 15

# how do I have 18 yrs old with a yr diff of 15?

View(firstCourses[firstCourses$AGE < 20 & firstCourses$yr_diff > 5,])

# I guess it's age at time of first enrollment or of cohort date
# I could take a closer look at the careers the emplids in this

# should I combine "age" with "yr_diff" to get age at time of course?

smoothScatter(x = firstCourses$AGE,
              y = firstCourses$yr_diff)

library(hexbin)
h <- hexbin(x = firstCourses$AGE,
            y = firstCourses$yr_diff)
plot(h, main = "2D density of Age and yr_diff")

plot(h, 
     trans = "log",
     main = "2D density of Age and yr_diff")

## 

table(firstCourses$course[course_levelFilter]) |>
  (\(x){x[order(x, decreasing = TRUE)]})() |>
  plot()

# which courses to filter out?
# I can get rid of the ones that aren't in the last year

# I kinda wanna see pdp of cohort_year and class_year

boxplot(HSGPA ~ GRADEGPA, data = firstCourses[course_levelFilter,])
boxplot(GRADEGPA ~ cohort_year, data = firstCourses[course_levelFilter,], outlier = FALSE)
boxplot(GRADEGPA ~ class_year, data = firstCourses[course_levelFilter,], outlier = FALSE)

# This isn't showing the grade inflation !

table(firstCourses[course_levelFilter, c("course","cohort_year")  ])

# I could filter out the courses that haven't appeared in the last few years.

# But if course doesn't matter, why would I?

# let's look up MATH_1010, the only course that popped up

courseFilter <- firstCourses$course == "MATH_1010"
boxplot(GRADEGPA ~ class_year, data = firstCourses[courseFilter,])

# I should develop a couple of feature engineering,
# and some class filters, run another model, and interpret that.

notRecentFilter <-firstCourses$course 

course_by_year <- table(firstCourses[course_levelFilter, c("course","class_year")  ]) |> as.data.frame()

recentCourses <- unique(course_by_year$course[course_by_year$class_year %in% c(2021:2025) & course_by_year$Freq > 0])

recent_filter <- firstCourses$course %in% recentCourses
courseClusters <- table(firstCourses$course[recent_filter]) |>
  (\(x){x[order(x, decreasing = TRUE)]})() |>
#  plot()
dist() |>
  hclust() |>
#  plot()
  cutree(k=2) # |> 
#  table()

# I think I'm fighting this too hard
# let's go with two clusters

# and I'll pretty much use this to organize my box plot.

# but I guess I can use these for grade inflation

boxplot(GRADEGPA ~ class_year, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1]),])
boxplot(GRADEGPA ~ class_year, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 2]),])  

# well, there it is.  Not interesting.

# let's look at ACTMATH vs GPA

plot(y = firstCourses$ACTMATH,
     x = firstCourses$GRADEGPA)

boxplot(ACTMATH ~ GRADEGPA + course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1]),])
boxplot(ACTMATH ~ GRADEGPA, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1]),])
boxplot(ACTMATH ~ course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1]),])

# DING DING DING!  There's the graph I want.
# We already do a good job of sorting people, making "course" invisible to grades

boxplot(ACTMATH ~ course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1]),])
boxplot(ACTMATH ~ course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 2]),])

# this puts "predicting course" back on the table as a useful exercise

# I should terrace these as five plots (?) with the same scale
# or do two in one graph and three in the next
# and color by course
boxplot(ACTMATH ~ GRADEGPA + course, data = firstCourses[firstCourses$course == names(courseClusters[courseClusters == 1])[1],])

boxplot(ACTMATH ~ GRADEGPA + course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1])[1:2],])

par(mfrow=c(1,2))
boxplot(ACTMATH ~ GRADEGPA + course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1])[1],], ylim = c(0,36))
boxplot(ACTMATH ~ GRADEGPA + course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1])[2],], ylim = c(0,36))

# It looks like ACT is determining the math class,
# and then something else is determinig the grade in that class

par(mfrow=c(1,2))
boxplot(HSGPA ~ GRADEGPA + course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1])[1],], ylim = c(0,4))
boxplot(HSGPA ~ GRADEGPA + course, data = firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1])[2],], ylim = c(0,4))


# I want a heat map of ACTMATH x HSGPA and actual grade

# Option 1: Faceted scatterplot

library(ggplot2)
 
ggplot(firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1])[1:2],], aes(x = HSGPA, y = ACTMATH, color = factor(GRADEGPA))) +
     geom_point(alpha = 0.7, size = 2) +
     facet_wrap(~ course, scales = "free") +
     scale_color_viridis_d(option = "plasma", name = "GRADE GPA") +
     theme_minimal() +
     theme(strip.text = element_text(size = 10),
           legend.position = "bottom") +
     labs(
         x = "High School GPA",
         y = "ACT Math",
         title = "ACT Math vs High School GPA by Course",
         subtitle = "Colored by GRADEGPA bins"
     )

# Option 2: One scatterplot

ggplot(firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1])[1:2],], aes(x = HSGPA, y = ACTMATH, size = GRADEGPA, color = course)) +
  geom_point(alpha = 0.6) +
  scale_size(range = c(1, 6), name = "GRADE GPA") +
  theme_minimal() +
  labs(
    x = "High School GPA",
    y = "ACT Math",
    title = "ACT Math vs High School GPA by Course",
    subtitle = "Point size shows GRADEGPA"
  )

# Option 3: Base R

unique_courses <- names(courseClusters[courseClusters == 1])

par(mfrow = c(2, 2))  # adjust layout
for (crs in unique_courses[1:4]) {
  dat <- subset(firstCourses, course == crs)
  plot(dat$HSGPA, dat$ACTMATH,
       col = as.factor(dat$GRADEGPA),
       pch = 19, main = crs,
       xlab = "High School GPA", ylab = "ACT Math")
}

# really needs help with the color on this last one.

## DENSITy PLOTS ## 

ggplot(firstCourses[firstCourses$course %in% names(courseClusters[courseClusters == 1])[1:2],], aes(x = HSGPA, y = ACTMATH, color = GRADEGPA)) +
  geom_hex(bins = 25) +
  facet_wrap(~ course, scales = "free") +
  scale_color_viridis_c(option = "plasma") +
  theme_minimal()

# Here's a 2D plot of actual grades

HSGPA <- firstCourses$HSGPA[firstCourses$course %in% names(courseClusters[courseClusters == 1])[2]]
ACTMATH <- firstCourses$ACTMATH[firstCourses$course %in% names(courseClusters[courseClusters == 1])[2]]
GRADEGPA <- firstCourses$GRADEGPA[firstCourses$course %in% names(courseClusters[courseClusters == 1])[2]]

n_bins <- 25
x_bins <- cut(HSGPA, breaks = n_bins)
y_bins <- cut(ACTMATH, breaks = n_bins)

# Calculate mean GRADEGPA per bin
bin_means <- tapply(GRADEGPA, list(x_bins, y_bins), mean, na.rm = TRUE)

# Get bin centers for plotting
x_breaks <- seq(min(HSGPA, na.rm=TRUE), max(HSGPA, na.rm=TRUE), length.out = n_bins +1)
y_breaks <- seq(min(ACTMATH, na.rm=TRUE), max(ACTMATH, na.rm=TRUE), length.out = n_bins +1)
x_centers <- (x_breaks[-1] + x_breaks[-(n_bins +1)])/2
y_centers <- (y_breaks[-1] + y_breaks[-(n_bins +1)])/2

# Plot
par(mar=c(5,4,4,6))
image(x_centers, y_centers, bin_means,
      col = hcl.colors(100, "YlOrRd", rev = TRUE),
      xlab = "HSGPA", ylab = "ACTMATH",
      main = "20 Binned Scatterplot"
      )

# legend is buggy
# Legend 

legend_vals <- seq(min(GRADEGPA, na.rm=TRUE),
                   max(GRADEGPA, na.rm = TRUE),
                   length.out = 5)
legend_at <- seq(par("usr")[3], par("usr")[4], length.out = 5)

legend_cols <- hcl.colors(100, "YlOrRd", rev=TRUE)

par(xpd=TRUE)
for(i in 1:5){
  rect(par("usr")[2] + 0.5, legend_at[i],
      par("usr")[2] + 1, legend_at[i+1],
      col = legend_cols[i+25],
      border = NA)
}

# That's not as interesting as I'd think it would be
# But there it is, I guess

# here it is as a hexbin

library(hexbin) 
hb <- hexbin(HSGPA, ACTMATH, xbins = 30, IDs = TRUE)
# cell_id <- hexbin::hcellID(hb)  # one ID per observation
# cell_ids <- hexbin:::.findBin(hb, HSGPA, ACTMATH)
# hex_means <- tapply(GRADEGPA, cell_ids, mean, na.rm=TRUE)

hex_means <- hexTapply(hb, GRADEGPA, mean, na.rm=TRUE)

plot(hb, colramp=function(n)hcl.colors(n, "YlOrRd", rev=TRUE),
     main = "Hexbin: Mean GRADEGPA",
     xlab = "HSGPA", ylab = "ACTMATH",
     cell.at = hex_means,
     use.count = FALSE
     )


grid.hexagons(hb, use.count = FALSE, cell.at = hex_means)
# not an error but nothing happens

# I guess I plot it first, and then plot over it?
# par(mar = c(0,0,0,0))
library(hexbin) 
hb <- hexbin(HSGPA, ACTMATH, xbins = 30, IDs = TRUE)
hvp <- plot(hb, colramp = function(n) hcl.colors(n, "YlOrRd", rev = TRUE), legend = FALSE)
hex_means <- hexTapply(hb, GRADEGPA, median, na.rm=TRUE)
pushHexport(hvp$plot.vp)




grid.hexagons(hb, 
              style = 'colorscale', 
            #  pen = "forestgreen",
              colramp = function(n) hcl.colors(n, "Cividis"),
            #  colramp = BTY,
            #  colorcut = 11,
              colorcut = seq(0,1, by = 0.1),
              border = 0, 
              minarea = 0.9,
              maxarea = 0.9,
              use.count = FALSE, 
              cell.at = hex_means)

# oh... it DID work!
# it's just dumb!

# man I *think* I'm getting close

grid.hexagons(hb, 
                           style = 'centroids', 
                            pen = "forestgreen",
                            border = 0, 
                            minarea = 0.05,
                            maxarea = 0.5,
                            use.count = FALSE, 
                            cell.at = hex_means)

# I guess I'm not getting the scaling I thought I should

# Scale values to be between minarea and maxarea
scaled_means <- scales::rescale(hex_means, to = c(0.05, 0.5))

grid.hexagons(hb, 
              style = 'centroids', 
              pen = "forestgreen",
              border = 0, 
              minarea = 0.05,
              maxarea = 0.5,
              use.count = FALSE, 
              cell.at = scaled_means)

# Exaggerate the differences
scaled_means_sq <- (scales::rescale(hex_means, to = c(0.2, 1.5)))^2

grid.hexagons(hb, 
              style = 'centroids', 
              pen = "forestgreen",
              border = 0, 
              minarea = 0.2,
              maxarea = 3.0,
              use.count = FALSE, 
              cell.at = scaled_means_sq)

###
###

cell_values <- rep(NA, hb@ncells)
cell_values[as.numeric(names(hex_means))] <- hex_means

grid.hexagons(hb, 
              style = 'colorscale', 
              border = "white",
              colramp = colorRampPalette(c("darkblue", "cyan", "yellow", "red")),
              use.count = FALSE, 
              cell.at = cell_values)

# Well, that was a completely wasted day, because this works great:

####################
### ALL I WANTED ###
####################

library(ggplot2)

# Create a simple dataframe
df <- data.frame(HSGPA = HSGPA, 
                 ACTMATH = ACTMATH, 
                 GRADEGPA = GRADEGPA)

# Plot with hexbins colored by median GRADEGPA
ggplot(df, aes(x = HSGPA, y = ACTMATH, z = GRADEGPA)) +
  stat_summary_hex(fun = median, bins = 30) +
  scale_fill_gradientn(colors = c("darkblue", "cyan", "yellow", "red"),
                       name = "Median\nGRADEGPA") +
  theme_minimal() +
  labs(title = "Median GRADEGPA by HSGPA and ACTMATH",
       x = "HSGPA", 
       y = "ACTMATH")



## SIDE BY SIDE ##
# TURN THIS INTO  A FUNCTION !
# Change the title to the course in question
library(ggplot2)

plotHex(data = firstCourses[firstCourses$course %in% c("MATH_1010", "MATH_1050", "MATH_1210", "MATH_1030", "MATH_1090"),])
plotHex(data = firstCourses[firstCourses$course %in% c("MATH_1010"),])


library(ggplot2)
library(patchwork)
# Create a simple dataframe
df <- data.frame(HSGPA = HSGPA, 
                 ACTMATH = ACTMATH, 
                 GRADEGPA = GRADEGPA)

# Plot 1: Median GRADEGPA
p1 <- ggplot(df, aes(x = HSGPA, y = ACTMATH, z = GRADEGPA)) +
  stat_summary_hex(fun = median, bins = 30) +
  scale_fill_gradientn(colors = c("darkblue", "cyan", "yellow", "red"),
                       name = "Median\nGRADEGPA") +
  theme_minimal() +
  labs(title = "Median GRADEGPA by HSGPA and ACTMATH",
       x = "HSGPA", 
       y = "ACTMATH")

# Plot 2: Counts per cell
p2 <- ggplot(df, aes(x = HSGPA, y = ACTMATH)) +
  geom_hex(bins = 30) +
  scale_fill_gradientn(colors = c("lightblue", "yellow", "orange", "red"),
                       name = "Count") +
  theme_minimal() +
  labs(title = "Count of Students by HSGPA and ACTMATH",
       x = "HSGPA", 
       y = "ACTMATH")

# Display both plots side by side
library(patchwork)
p1 + p2


## IS HIGH SCHOOL GPA LOSING ITS PREDICTIVE POWER DUE TO GRADE INFLATION? ##

# ok, let's run some new models!
# and I'll abandon binary and trinary

# let's look at load

boxplot(load ~ GRADEGPA, data = firstCourses, outline = FALSE)

# looks like a consequence, not a cause, 
# as people weak on their math or student skills take a smaller load  


############
## REVIEW ##
############

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

# Age buckets
firstCourses$age_cut <- cut(firstCourses$AGE, breaks = c(0,17,18,19,21,100))

# should I do yr_diff ? ....naaah




