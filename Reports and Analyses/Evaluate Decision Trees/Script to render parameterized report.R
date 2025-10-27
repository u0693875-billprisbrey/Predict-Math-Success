# Render model results

# PURPOSE:  This script enables me to render the report
# that simply gives the results.

# I am going to run these one at a time, rather than looping

reportVersion <- "vG1"

rmarkdown::render(
  here::here("Reports and Analyses", "Evaluate Decision Trees",   "Evaluate Grade Decision Trees Parameter Template.Rmd"),
  params = list(version = reportVersion),
  output_file = here::here("Reports and Analyses", "Evaluate Decision Trees", paste0("Evaluate_Grade_Decision_Trees_", reportVersion, "_results.html")
)
)

# reportVersions <- c("vF0", "vF1", "vF2", "vF3", "vG0",  "vG1")

# lapply(reportVersions, function(x) {

# rmarkdown::render(
#   "Evaluate_Grade_Decision_Trees.Rmd",
#  params = list(version = "vF1"),
#  output_file = paste0("Evaluate_Grade_Decision_Trees_", "vF1", ".html")
# )
  
# }

reportVersion <- "vH0"
target_classes <- c('GRADEGPA','grade_quad')

rmarkdown::render(
  here::here("Reports and Analyses", "Evaluate Decision Trees",   "Evaluate Grade Decision Trees Parameter Template.Rmd"),
  params = list(version = reportVersion,
                target_classes = target_classes),
  output_file = here::here("Reports and Analyses", "Evaluate Decision Trees", paste0("Evaluate_Grade_Decision_Trees_", reportVersion, "_results.html")
  )
)

reportVersion <- "vH1"
target_classes <- c('GRADEGPA','grade_quad')

rmarkdown::render(
  here::here("Reports and Analyses", "Evaluate Decision Trees",   "Evaluate Grade Decision Trees Parameter Template.Rmd"),
  params = list(version = reportVersion,
                target_classes = target_classes),
  output_file = here::here("Reports and Analyses", "Evaluate Decision Trees", paste0("Evaluate_Grade_Decision_Trees_", reportVersion, "_results.html")
  )
)


reportVersion <- "vH2"
target_classes <- c('GRADEGPA','grade_quad')

rmarkdown::render(
  here::here("Reports and Analyses", "Evaluate Decision Trees",   "Evaluate Grade Decision Trees Parameter Template.Rmd"),
  params = list(version = reportVersion,
                target_classes = target_classes),
  output_file = here::here("Reports and Analyses", "Evaluate Decision Trees", paste0("Evaluate_Grade_Decision_Trees_", reportVersion, "_results.html")
  )
)