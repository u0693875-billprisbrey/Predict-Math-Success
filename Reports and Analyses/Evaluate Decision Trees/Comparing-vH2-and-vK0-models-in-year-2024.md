---
title: "Comparing predictions with and without test scores"
author: "Bill Prisbrey"
date: "2025-11-22"
output:
  html_document:
    keep_md: true
    toc: true
---

***PURPOSE:*** This document compares vH2 and vK0 for the year 2024. 

# EXECUTIVE SUMMARY

In order to minimize errors, the models tend to select the middle ground. 

Because actual performance data is heavily skewed towards the top, the models' tendency to populate the center results in under-prediction. 

Adding test scores improves the prediction.  Test score submitters also perform better, pushing their curve to the right.

Neither model really predicts failures, or admissions standards are aligned with grading standards.  (There aren't easily predicted failuress.) Something else is driving the failures. 

I'd like to see the density curves for score-submitters and non-score submitters.  




























```
## [1] "GRADEGPA"
## [1] "grade_quad"
```












# Histograms

![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-14-1.png)<!-- -->


# Density plots

![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-15-1.png)<!-- -->


# Comparison heatmap

![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-16-1.png)<!-- -->

# Differences

![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-17-1.png)<!-- -->


# Box plots

![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-18-1.png)<!-- -->



# Confusion matrix

![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-19-1.png)<!-- -->![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-19-2.png)<!-- -->![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-19-3.png)<!-- -->![](Comparing-vH2-and-vK0-models-in-year-2024_files/figure-html/unnamed-chunk-19-4.png)<!-- -->



