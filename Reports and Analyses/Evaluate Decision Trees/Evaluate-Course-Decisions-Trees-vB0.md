---
title: "Evaluate Course Decision Trees vB0"
author: "Bill Prisbrey"
date: "2025-10-31"
params: 
  version: "vB0"
  target_classes: 
    - course_target
output:
  html_document:
    keep_md: true
---











### Models  

Only one model. I could delete this section 

### Predictors  

SEX, FIRST_GEN_STATUS_CD, ETHNICITY, RESSTAT, FA_PELL, APCREDIT, HSGPA, HSPRIVATE, HONORS, ACTCOMP, ACTENGL, ACTMATH, ACTSCI, cohort_year, class_year, yr_diff, season, course_level, age_cut. 

"load" is the credit load per student per term. 
"yr_diff" is the time (expressed as fractions of a year) between the cohort date and the end of term date for the course.  

The other variables are either self-explanatory or taken directly from OBIA tables.  

# Results

Develop and report the confusion matrices 

![](Evaluate-Course-Decisions-Trees-vB0_files/figure-html/unnamed-chunk-4-1.png)<!-- -->![](Evaluate-Course-Decisions-Trees-vB0_files/figure-html/unnamed-chunk-4-2.png)<!-- -->


# Variable importance

![](Evaluate-Course-Decisions-Trees-vB0_files/figure-html/unnamed-chunk-5-1.png)<!-- -->


