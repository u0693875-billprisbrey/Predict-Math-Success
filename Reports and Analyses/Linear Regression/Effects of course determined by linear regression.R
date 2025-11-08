# Linear Regression
# Determining effects of course 


library(tidyverse)
library(broom)

##########
## LOAD ##
##########

# Build file paths
data_files <- here::here("Data", paste0("Decision Tree ", "vH2", " ", c("GRADEGPA", "grade_quad"), " Data.rds"))

# Read each model into a named list
data_list <- setNames(
  lapply(data_files, readRDS),
  c("GRADEGPA", "grade_quad")
)

##########
## PREP ##
##########

df <- data_list[["GRADEGPA"]][["testing"]] %>%
  mutate(course = as.factor(course))

###########
## MODEL ##
###########

startTime <- Sys.time()
model <- lm(GRADEGPA ~ ., 
            data = df)
endTime <- Sys.time()
endTime-startTime # 0.05s or something

#############
## RESULTS ##
#############

course_effects <- tidy(model) |>
  filter(str_starts(term, "course"))

print(course_effects, n = 30)

anova(model)

##################
## COOL GRAPHIC ##
##################

library(tidyverse)

# Add the reference course manually (coefficient = 0 by definition)
reference_course <- tibble(
  term = "courseMATH_1010",  # Replace with actual reference course name
  estimate = 0,
  std.error = 0,
  statistic = NA,
  p.value = NA
)

# Combine with course effects
all_courses <- bind_rows(reference_course, course_effects) %>%
  filter(term != "course_level") %>%  # Remove the NA row
  mutate(
    course = str_remove(term, "courseMATH_"),
    course_num = as.numeric(course),
    significant = p.value < 0.05 | is.na(p.value)
  )

# Plot 1: Course effects with confidence intervals
ggplot(all_courses, aes(x = reorder(course, estimate), y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(aes(color = significant), size = 3) +
  geom_errorbar(aes(ymin = estimate - 1.96*std.error,
                    ymax = estimate + 1.96*std.error,
                    color = significant),
                width = 0.3) +
  coord_flip() +
  scale_color_manual(values = c("TRUE" = "red", "FALSE" = "gray60"),
                     labels = c("Not significant", "Significant (p<0.05)")) +
  labs(
    title = "Course Effects on Grades (Controlling for Student Characteristics)",
    x = "Course",
    y = "Effect on Grade (relative to reference course)",
    color = "",
    caption = "Error bars show 95% confidence intervals"
  ) +
  theme_minimal()

# Plot 2: By course level
# I don't like this plot.  I don't think the course level is that informative.  
ggplot(all_courses, aes(x = course_num, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(aes(color = significant), size = 3) +
  geom_smooth(method = "loess", se = TRUE, color = "blue", alpha = 0.2) +
  scale_color_manual(values = c("TRUE" = "red", "FALSE" = "gray60")) +
  labs(
    title = "Course Difficulty by Course Number",
    x = "Course Number",
    y = "Effect on Grade",
    color = "Significant"
  ) +
  theme_minimal()


