# Reproduction of WH Logistic Regression

# PURPOSE: This is a copy of Whitney's code which is re-produced 
# in order to calculate Kappa and investigate the prediction results. 

# It was copied from WH Historic Academic Performance in the First Math Course taken by First Time Students 2025.10.16
# Then I have adjusted the function "evaluate_model" at around line 500 to include Kappa, and return the confusion matrix,
# and switched the positive case to 0 instead of 1.

# Setting work directory
# setwd('C:/Users/u1057827/Box/UAIR - Undergraduate Studies/Analysis/Math Placement')
setwd('C:/Users/u0693875/Box/UAIR - Student Success Analyses/Math Placement')

# Loading required packages
library("readxl")
library("tidyverse")
library("car")
library("caret")
library("knitr")
library("tibble")
library("kableExtra")
library("gridExtra")
library("pROC")
library("margins")

# Loading Data
First_Math <- read_excel("Dataset - Math Placement Project - First Time Students from Fall 2021 - 2024 Cohorts & Their First Math Course 2025.10.03.xlsx")

# Classifying FIRST_MATH_COURSE_GRADE as Pass, Fail, N/A, or Null
First_Math$FIRST_MATH_COURSE_GRADE_PASS_FAIL <- ifelse(
  is.na(First_Math$FIRST_MATH_COURSE_GRADE), "Null",
  ifelse(First_Math$FIRST_MATH_COURSE_GRADE %in% c("A", "A-", "B+", "B", "B-", "C+", "C", "C-"), "Pass",
         ifelse(First_Math$FIRST_MATH_COURSE_GRADE %in% c("D+", "D", "D-", "E", "EU"), "Fail",
                "N/A")))

# Curating the data set further
Math_Students <- First_Math %>%
  # Filter to students who took a math class AND earned a Pass or Fail grad
  filter(
    !is.na(FIRST_MATH_TERM),
    FIRST_MATH_COURSE_GRADE_PASS_FAIL %in% c("Pass", "Fail")
  ) %>%
  # Drop SATWRTG variable because there are so few observations with entries
  select(-SATWRTG) %>%  # Drop SATWRTG
  mutate(
    # Converting NULL APCREDIT entries to 0's
    APCREDIT = ifelse(is.na(APCREDIT), 0, APCREDIT),
    # Creating a new variable, concatenating the subject code and catalog number
    FIRST_MATH_COURSE = paste(FIRST_MATH_COURSE_SUBJECT_CD, FIRST_MATH_COURSE_CATNBR),
    STANDARDIZED_TEST_SCORES = if_else(
      !is.na(ACTCOMP) | !is.na(ACTENGL) | !is.na(ACTMATH) | !is.na(ACTSCI) | !is.na(SATMATH) | !is.na(SATVERBAL), 1, 0)) %>%
  # Dropping now duplicate columns
  select(-FIRST_MATH_COURSE_SUBJECT_CD, -FIRST_MATH_COURSE_CATNBR)

# Create a data frame with predictor variables and their short descriptions
predictors <- data.frame(
  Predictor = c("APCREDIT",
                "HSGPA",
                "HSPRIVATE",
                "ACTENGL",
                "ACTMATH",
                "ACTSCI",
                "SATMATH",
                "SATVERBAL"),
  Description = c("AP Credits earned by the student.",
                  "High school GPA earned by the student.",
                  "High school Private Indicator (Yes/ No)",
                  "ACT English Score earned by the student.",
                  "ACT Math Score earned by the student.",
                  "ACT Science Score earned by the student.",
                  "SAT Math Score earned by the student.",
                  "SAT Verbal Score earned by the student.")
)

# Display the table with styling and a horizontal scroll bar for wide tables
predictors %>%
  kable(caption = "List of Control Variables with Descriptions", 
        format = "html", 
        align = "l") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

controls <- data.frame(
  Control =   c("COHORT",
                "SEX",
                "FIRST_GEN_STATUS_CD",
                "ETHNICITY",
                "RESSTAT",
                "FA_PELL",
                "MATH_IN_FIRST_YEAR",
                "STANDARDIZED_TEST_SCORES"),
  Description = c("Cohort of the first-time student.",
                  "Gender of the student.",
                  "First Generation Indicator (Yes/ No/ Unknown).",
                  "Ethnicity of the student.",
                  "Residency of the student (Non-Resident/ Resident).",
                  "Pell eligibility.",
                  "Indicator of whether the student took math in their first year (1/ 0).",
                  "Indicator of whether the student submitted standardized test scores (ACT or SAT).")
)

# Display the table with styling and a horizontal scroll bar for wide tables
controls %>%
  kable(caption = "List of Control Variables with Descriptions", 
        format = "html", 
        align = "l") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))
# Create a data frame with predictor variables and their short descriptions
grades <- data.frame(
  Classification = c("Pass",
                     "Pass",
                     "Pass",
                     "Pass",
                     "Pass",
                     "Pass",
                     "Pass",
                     "Pass",
                     "Fail",
                     "Fail",
                     "Fail",
                     "Fail",
                     "Fail",
                     "N/A",
                     "N/A",
                     "N/A",
                     "N/A",
                     "N/A"),
  Grade =     c("A",
                "A-",
                "B+",
                "B",
                "B-",
                "C+",
                "C",
                "C-",
                "D+",
                "D",
                "D-",
                "E",
                "EU",
                "I",
                "W",
                "CR",
                "NC",
                "V"),
  Description = c("Excellent performance, superior achievement" ,
                  "Excellent performance, superior achievement",
                  "Good performance, substantial achievement",
                  "Good performance, substantial achievement",
                  "Good performance, substantial achievement",
                  "Standard performance and achievement",
                  "Standard performance and achievement",
                  "Standard performance and achievement",
                  "Substandard performance, marginal achievement",
                  "Substandard performance, marginal achievement",
                  "Substandard performance, marginal achievement",
                  "Unsatisfactory performance and achievement",
                  "Unofficial Withdrawal",
                  "Incomplete",
                  "Official Withdrawal",
                  "Credit",
                  "No Credit",
                  "Audit"))

# Display the table with styling and a horizontal scroll bar for wide tables
grades %>%
  kable(caption = "List of Grades with Pass/ Fail Indicator", 
        format = "html", 
        align = "l") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

# Filter to only Pass and Fail
First_Math_PF <- First_Math %>%
  filter(FIRST_MATH_COURSE_GRADE_PASS_FAIL %in% c("Pass", "Fail"))

# Define order
category_order <- c("Pass", "Fail")

# Summarize and prepare data
grade_summary_pf <- First_Math_PF %>%
  count(FIRST_MATH_COURSE_GRADE_PASS_FAIL, name = "Count") %>%
  mutate(
    Percentage = Count / sum(Count),
    Label = paste0(format(Count, big.mark = ","), " (", round(Percentage * 100, 1), "%)"),
    FIRST_MATH_COURSE_GRADE_PASS_FAIL = factor(FIRST_MATH_COURSE_GRADE_PASS_FAIL, levels = category_order)
  )

# Red shades for Pass and Fail
red_shades_pf <- c("#990000", "#E57373")  # Darker for Pass, lighter for Fail

# Plot
ggplot(grade_summary_pf, aes(x = FIRST_MATH_COURSE_GRADE_PASS_FAIL, y = Count, fill = FIRST_MATH_COURSE_GRADE_PASS_FAIL)) +
  geom_col() +
  geom_text(aes(label = Label), vjust = -0.5, size = 4.5) +
  scale_fill_manual(values = red_shades_pf) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Distribution of Pass and Fail Grades",
    x = "Grade Classification",
    y = "Number of Observations"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    panel.grid = element_blank()
  )

# Summary of rows with and without missing values
First_Math_complete_rows   <- sum(complete.cases(Math_Students))
First_Math_incomplete_rows <- sum(!complete.cases(Math_Students))

# Creating data frame of values
First_Math_rows_summary <- data.frame(
  Category = c("Rows with NO missing values (used for model)", 
               "Rows WITH missing values (to be dropped)"),
  Count = c(First_Math_complete_rows, First_Math_incomplete_rows)
)

# Displaying tables
kable(First_Math_rows_summary, caption = "Summary of Rows by Missing Data for Students who have taken math")

# Count missing values for each column
missing_summary <- colSums(is.na(Math_Students))

# Convert to data frame properly
missing_table <- data.frame(
  Column = names(missing_summary),
  Missing_Count = as.vector(missing_summary)
)

# Filter to only columns with missing values
missing_table_filtered <- missing_table %>%
  filter(Missing_Count > 0) %>%
  arrange(desc(Missing_Count))

# Display the table
missing_table_filtered %>%
  kable(caption = "Missing Values by Column") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))


# Create overlap summary with percentage
act_sat_overlap <- Math_Students %>%
  mutate(
    ACT = !is.na(ACTCOMP) | !is.na(ACTENGL) | !is.na(ACTMATH) | !is.na(ACTSCI),
    SAT = !is.na(SATMATH) | !is.na(SATVERBAL)
  ) %>%
  count(ACT, SAT) %>%
  rename(Count = n) %>%
  mutate(
    Percent = round((Count / sum(Count)) * 100, 1),  # Calculate percentage
    ACT = ifelse(ACT, "Yes", "No"),
    SAT = ifelse(SAT, "Yes", "No")
  )

# Display as a styled table
act_sat_overlap %>%
  kable(caption = "Overlap of ACT and SAT Scores Among Math Students") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

# Define irrelevant columns
irrelevant_cols <- c("COHORT", "EMPLID", "FIRST_MATH_COURSE_GRADE", "FIRST_MATH_COURSE_TITLE", "FIRST_MATH_TERM", "ACTCOMP")

# Define ACT and SAT columns
act_cols <- c("ACTCOMP", "ACTENGL", "ACTMATH", "ACTSCI")
sat_cols <- c("SATMATH", "SATVERBAL")
standardized_test_cols <- c("STANDARDIZED_TEST_SCORES")

# Group 1: Students with HSGPA only
Model_Group1 <- Math_Students %>%
  filter(!is.na(HSGPA)) %>%
  select(where(~ !all(is.na(.)))) %>%              # Drop all-NA columns
  select(-all_of(c(irrelevant_cols, act_cols, sat_cols)))  # Drop irrelevant + ACT + SAT

# Group 2: Students with HSGPA + ACT scores
Model_Group2 <- Math_Students %>%
  filter(complete.cases(select(., HSGPA, ACTCOMP, ACTENGL, ACTMATH, ACTSCI))) %>%
  select(where(~ !all(is.na(.)))) %>%
  select(-all_of(c(irrelevant_cols, sat_cols, standardized_test_cols)))    # Drop irrelevant + SAT

# Group 3: Students with HSGPA + SAT scores
Model_Group3 <- Math_Students %>%
  filter(complete.cases(select(., HSGPA, SATMATH, SATVERBAL))) %>%
  select(where(~ !all(is.na(.)))) %>%
  select(-all_of(c(irrelevant_cols, act_cols, standardized_test_cols)))    # Drop irrelevant + ACT

# Total number of students
total_students <- nrow(Math_Students)

# Create a summary table of group sizes with percentage of total
group_counts <- data.frame(
  Group = c("HSGPA Only", "HSGPA + ACT", "HSGPA + SAT"),
  Observations = c(nrow(Model_Group1), nrow(Model_Group2), nrow(Model_Group3))
) %>%
  mutate(
    Percent = round((Observations / total_students) * 100, 1)  # Percent of total students
  )

# Display the table with kable styling
group_counts %>%
  kable(caption = "Number of Observations in Each Modeling Group") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

# Create summary table
course_summary <- Math_Students %>%
  count(FIRST_MATH_COURSE, name = "Count") %>%
  mutate(
    Percentage = Count / sum(Count),
    Percentage_Label = paste0(round(Percentage * 100, 1), "%")
  ) %>%
  arrange(desc(Count))

# Display as a styled HTML table
course_summary %>%
  kable(
    caption = "Summary of Student Counts and Percentages by First Math Course",
    format = "html",
    col.names = c("Course", "Count", "Proportion", "Percent"),
    align = "l"
  ) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

# Convert target variable to binary (0 = Fail, 1 = Pass)
Model_Group1 <- Model_Group1 %>%
  mutate(FIRST_MATH_COURSE_GRADE_PASS_FAIL = ifelse(FIRST_MATH_COURSE_GRADE_PASS_FAIL == "Pass", 1, 0))

Model_Group2 <- Model_Group2 %>%
  mutate(FIRST_MATH_COURSE_GRADE_PASS_FAIL = ifelse(FIRST_MATH_COURSE_GRADE_PASS_FAIL == "Pass", 1, 0))

Model_Group3 <- Model_Group3 %>%
  mutate(FIRST_MATH_COURSE_GRADE_PASS_FAIL = ifelse(FIRST_MATH_COURSE_GRADE_PASS_FAIL == "Pass", 1, 0))

# Set reference levels before modeling
Model_Group1 <- Model_Group1 %>%
  mutate(
    SEX = relevel(factor(SEX), ref = "F"),
    FIRST_GEN_STATUS_CD = relevel(factor(FIRST_GEN_STATUS_CD), ref = "Y"),
    ETHNICITY = relevel(factor(ETHNICITY), ref = "C"),
    FIRST_MATH_COURSE = relevel(factor(FIRST_MATH_COURSE), ref = "MATH 1010")
  )

Model_Group2 <- Model_Group2 %>%
  mutate(
    SEX = relevel(factor(SEX), ref = "F"),
    FIRST_GEN_STATUS_CD = relevel(factor(FIRST_GEN_STATUS_CD), ref = "Y"),
    ETHNICITY = relevel(factor(ETHNICITY), ref = "C"),
    FIRST_MATH_COURSE = relevel(factor(FIRST_MATH_COURSE), ref = "MATH 1010")
  )

Model_Group3 <- Model_Group3 %>%
  mutate(
    SEX = relevel(factor(SEX), ref = "F"),
    FIRST_GEN_STATUS_CD = relevel(factor(FIRST_GEN_STATUS_CD), ref = "Y"),
    ETHNICITY = relevel(factor(ETHNICITY), ref = "C"),
    FIRST_MATH_COURSE = relevel(factor(FIRST_MATH_COURSE), ref = "MATH 1010")
  )

# Logistic Regression for Group 1: HSGPA only
Model_Main_Group1 <- glm(
  FIRST_MATH_COURSE_GRADE_PASS_FAIL ~ .,
  data = Model_Group1 %>% mutate(FIRST_MATH_COURSE = as.factor(FIRST_MATH_COURSE)),
  family = binomial(link = "logit")
) 

# Logistic Regression for Group 2: HSGPA + ACT
Model_Main_Group2 <- glm(
  FIRST_MATH_COURSE_GRADE_PASS_FAIL ~ .,
  data = Model_Group2 %>% mutate(FIRST_MATH_COURSE = as.factor(FIRST_MATH_COURSE)),
  family = binomial(link = "logit")
)

# Logistic Regression for Group 3: HSGPA + SAT
Model_Main_Group3 <- glm(
  FIRST_MATH_COURSE_GRADE_PASS_FAIL ~ .,
  data = Model_Group3 %>% mutate(FIRST_MATH_COURSE = as.factor(FIRST_MATH_COURSE)),
  family = binomial(link = "logit")
)

# Summarize model
summary(Model_Main_Group1)

# Check multicollinearity (VIF)
vif(Model_Main_Group1)

# Compute average marginal effects
AME_Model_Main_Group1 <- margins(Model_Main_Group1)

# Convert to data frame for plotting
ame_df1 <- summary(AME_Model_Main_Group1) %>%
  as.data.frame() %>%
  filter(!grepl("factor", factor))

# Compute confidence intervals
ame_df1 <- ame_df1 %>%
  mutate(LowerCI = AME - 1.96 * SE,
         UpperCI = AME + 1.96 * SE,
         Sign = ifelse(AME > 0, "Positive", "Negative"))

# Create formatted table
ame_df1 %>%
  select(factor, AME, SE, LowerCI, UpperCI, Sign) %>%
  arrange(desc(AME)) %>%
  kable(digits = 3, caption = "Group 1 General Model: Average Marginal Effects with 95% Confidence Intervals")%>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

ggplot(ame_df1, aes(x = reorder(factor, AME), y = AME, color = Sign)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = LowerCI, ymax = UpperCI), width = 0.2) +
  coord_flip() +
  scale_color_manual(values = c("Positive" = "steelblue", "Negative" = "firebrick")) +
  labs(title = "Group 1 General Model: Average Marginal Effects (AME) with 95% CI",
       x = "Predictor",
       y = "Marginal Effect on Probability of Passing") +
  theme_minimal(base_size = 12)

# Summarize model
summary(Model_Main_Group2)

# Check multicollinearity (VIF)
vif(Model_Main_Group2)

# Compute average marginal effects
AME_Model_Main_Group2 <- margins(Model_Main_Group2)

# Convert to data frame for plotting
ame_df2 <- summary(AME_Model_Main_Group2) %>%
  as.data.frame() %>%
  filter(!grepl("factor", factor))  # Optional: remove factor levels if too many

# Compute confidence intervals
ame_df2 <- ame_df2 %>%
  mutate(LowerCI = AME - 1.96 * SE,
         UpperCI = AME + 1.96 * SE,
         Sign = ifelse(AME > 0, "Positive", "Negative"))

# Create formatted table
ame_df2 %>%
  select(factor, AME, SE, LowerCI, UpperCI, Sign) %>%
  arrange(desc(AME)) %>%
  kable(digits = 3, caption = "Group 2 General Model: Average Marginal Effects with 95% Confidence Intervals")%>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

# chart
ggplot(ame_df2, aes(x = reorder(factor, AME), y = AME, color = Sign)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = LowerCI, ymax = UpperCI), width = 0.2) +
  coord_flip() +
  scale_color_manual(values = c("Positive" = "steelblue", "Negative" = "firebrick")) +
  labs(title = "Group 2 General Model: Average Marginal Effects (AME) with 95% CI",
       x = "Predictor",
       y = "Marginal Effect on Probability of Passing") +
  theme_minimal(base_size = 12)

# Summarize model
summary(Model_Main_Group3)

# Check multicollinearity (VIF)
vif(Model_Main_Group3)

# Compute average marginal effects
AME_Model_Main_Group3 <- margins(Model_Main_Group3)

# Convert to data frame for plotting
ame_df3 <- summary(AME_Model_Main_Group3) %>%
  as.data.frame() %>%
  filter(!grepl("factor", factor))  # Optional: remove factor levels if too many

# Compute confidence intervals
ame_df3 <- ame_df3 %>%
  mutate(LowerCI = AME - 1.96 * SE,
         UpperCI = AME + 1.96 * SE,
         Sign = ifelse(AME > 0, "Positive", "Negative"))

# Create formatted table
ame_df3 %>%
  select(factor, AME, SE, LowerCI, UpperCI, Sign) %>%
  arrange(desc(AME)) %>%
  kable(digits = 3, caption = "Group 3 General Model: Average Marginal Effects with 95% Confidence Intervals")%>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

# chart
ggplot(ame_df3, aes(x = reorder(factor, AME), y = AME, color = Sign)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = LowerCI, ymax = UpperCI), width = 0.2) +
  coord_flip() +
  scale_color_manual(values = c("Positive" = "steelblue", "Negative" = "firebrick")) +
  labs(title = "Group 3 General Model: Average Marginal Effects (AME) with 95% CI",
       x = "Predictor",
       y = "Marginal Effect on Probability of Passing") +
  theme_minimal(base_size = 12)

# Function to evaluate a model
evaluate_model <- function(model, data, label) {
  probs <- predict(model, type = "response")
  preds <- ifelse(probs > 0.5, 1, 0)
  actual <- data$FIRST_MATH_COURSE_GRADE_PASS_FAIL
  
  cm <- confusionMatrix(factor(preds), factor(actual), positive = "1", mode = "everything") # Change this to 0
  auc <- roc(actual, probs)$auc
  
  accTibble <- tibble(
    Group = label,
    Kappa = as.numeric(cm$overall["Kappa"]),
    Accuracy = as.numeric(cm$overall["Accuracy"]),
    Precision = as.numeric(cm$byClass["Precision"]),
    Recall = as.numeric(cm$byClass["Recall"]),
    AUC = as.numeric(auc)
  )
  
  return(list(cm = cm, accuracy = accTibble))
  
}

# Evaluate each model
eval_main_group1 <- evaluate_model(Model_Main_Group1, Model_Group1, "Group 1: HSGPA Only")
eval_main_group2 <- evaluate_model(Model_Main_Group2, Model_Group2, "Group 2: HSGPA + ACT")
eval_main_group3 <- evaluate_model(Model_Main_Group3, Model_Group3, "Group 3: HSGPA + SAT")

# Combine and display
bind_rows(eval_main_group1, eval_main_group2, eval_main_group3) %>%
  kable(
    caption = "Comparison of General Model Evaluation Metrics",
    format = "html",
    digits = 3
  ) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))
