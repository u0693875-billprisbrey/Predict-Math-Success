---
title: "Evaluate Grade Decision Trees using vG0 models"
date: "October 09, 2025"
params: 
  version: "vG0"
output:
  html_document:
    keep_md: true
---











```
## [1] "grade_binary"
## missingFilter
## FALSE  TRUE 
##     1   723 
## [1] "grade_trinary"
## missingFilter
## FALSE  TRUE 
##     1   723 
## [1] "grade_quad"
## missingFilter
## FALSE  TRUE 
##     1   723
```


### Models  

*MODEL 1: binary* 

  - Target buckets:   
    1: "A", "A-", "B+", "B", "B-", "C+", "C", "C-"  
    0: "D+", "D", "D-", "E", "EU" 
  
*MODEL 2: trinary*  

  - Target buckets:     
    2: "A", "A-", "B+", "B", "B-"  
    1: "C+", "C", "C-"  
    0: "D+", "D", "D-", "E", "EU" 

*MODEL 3: quad* 

  - Target buckets:   
    3: "A"  
    2: "A-", "B+", "B", "B-"  
    1: "C+", "C", "C-"  
    0: "D+", "D", "D-", "E", "EU" 

*MODEL 4: grade GPA* 

  - Targets: 
    4, 3.7, 3.3, 3, 2.7, 2.3, 2, 1.7, 1.3, 1, 0.7, 0

### Predictors  

COHORTTERM, COHORT, SEX, FIRST_GEN_STATUS_CD, ETHNICITY, RESSTAT, FA_PELL, APCREDIT, HSGPA, HSPRIVATE, ACTCOMP, ACTENGL, ACTMATH, ACTSCI, MATH_IN_FIRST_YEAR, FIRST_MATH_COURSE_CATNBR. 

"load" is the credit load per student per term. 
"yr_diff" is the time (expressed as fractions of a year) between the cohort date and the end of term date for the course.  

The other variables are either self-explanatory or taken directly from OBIA tables.  

# Results


```
## [1] "grade_binary"
## missingFilter
## FALSE  TRUE 
##     1   723 
## [1] "grade_trinary"
## missingFilter
## FALSE  TRUE 
##     1   723 
## [1] "grade_quad"
## missingFilter
## FALSE  TRUE 
##     1   723
```

```
## [1] "grade_binary"
## missingFilter
## FALSE  TRUE 
##     1   723 
## [1] "grade_trinary"
## missingFilter
## FALSE  TRUE 
##     1   723 
## [1] "grade_quad"
## missingFilter
## FALSE  TRUE 
##     1   723
```

<table class=" lightable-classic" style="color: black; font-family: Calibri; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>Normalized Regression Results Across Grading Buckets</caption>
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="3"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Raw Metrics</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="4"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Normalized Metrics</div></th>
</tr>
  <tr>
   <th style="text-align:left;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;">  </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> RMSE </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> MAE </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> R² </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> NRMSE (Range) </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> NMAE (Range) </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> NRMSE (SD) </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> NMAE (SD) </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_binary </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.27 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.16 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.02 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.27 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.16 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.15 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.67 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_trinary </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.57 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.41 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.07 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.29 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.21 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.10 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.79 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_quad </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.84 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.64 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.12 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.28 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.21 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.00 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.76 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> GRADEGPA </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.95 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.70 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.12 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.17 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.01 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.74 </td>
  </tr>
</tbody>
</table>


![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG0_results_files/figure-html/unnamed-chunk-6-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG0_results_files/figure-html/unnamed-chunk-6-2.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG0_results_files/figure-html/unnamed-chunk-6-3.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG0_results_files/figure-html/unnamed-chunk-6-4.png)<!-- -->

# Variable importance

![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG0_results_files/figure-html/unnamed-chunk-7-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG0_results_files/figure-html/unnamed-chunk-7-2.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG0_results_files/figure-html/unnamed-chunk-7-3.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG0_results_files/figure-html/unnamed-chunk-7-4.png)<!-- -->



# Training data


Presentation order: 


```
## [1] "grade_binary"
## [1] "grade_trinary"
## [1] "grade_quad"
## [1] "GRADEGPA"
```

```
## [[1]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             2923                        
## Number of columns          17                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   numeric                  10                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────
##   skim_variable            n_missing complete_rate
## 1 COHORT                           0             1
## 2 SEX                              0             1
## 3 FIRST_GEN_STATUS_CD              0             1
## 4 ETHNICITY                        0             1
## 5 RESSTAT                          0             1
## 6 HSPRIVATE                        0             1
## 7 FIRST_MATH_COURSE_CATNBR         0             1
##   min max empty n_unique whitespace
## 1   9   9     0        4          0
## 2   1   1     0        2          0
## 3   1   1     0        3          0
## 4   1   1     0        9          0
## 5   1   1     0        2          0
## 6   1   1     0        2          0
## 7   4   4     0       34          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable      n_missing complete_rate
##  1 grade_binary               0             1
##  2 COHORTTERM                 0             1
##  3 FA_PELL                    0             1
##  4 APCREDIT                   0             1
##  5 HSGPA                      0             1
##  6 ACTCOMP                    0             1
##  7 ACTENGL                    0             1
##  8 ACTMATH                    0             1
##  9 ACTSCI                     0             1
## 10 MATH_IN_FIRST_YEAR         0             1
##        mean     sd      p0     p25     p50     p75
##  1    0.939  0.239    0       1       1       1   
##  2 1233.    11.0   1218    1218    1228    1238   
##  3    0.169  0.375    0       0       0       0   
##  4   16.8   12.4      3       6      14      24   
##  5    3.82   0.232    2.66    3.73    3.92    3.99
##  6   27.8    4.26    10      25      28      31   
##  7   27.7    5.24     8      24      28      33   
##  8   27.0    4.83    10      24      27      30   
##  9   27.7    4.73     7      24      27      32   
## 10    0.945  0.228    0       1       1       1   
##    p100 hist 
##  1    1 ▁▁▁▁▇
##  2 1248 ▇▇▁▇▇
##  3    1 ▇▁▁▁▂
##  4   76 ▇▃▁▁▁
##  5    4 ▁▁▁▂▇
##  6   36 ▁▁▅▇▆
##  7   36 ▁▁▆▇▇
##  8   36 ▁▂▆▇▅
##  9   36 ▁▁▅▇▆
## 10    1 ▁▁▁▁▇
## 
## [[2]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             2923                        
## Number of columns          17                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   numeric                  10                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────
##   skim_variable            n_missing complete_rate
## 1 COHORT                           0             1
## 2 SEX                              0             1
## 3 FIRST_GEN_STATUS_CD              0             1
## 4 ETHNICITY                        0             1
## 5 RESSTAT                          0             1
## 6 HSPRIVATE                        0             1
## 7 FIRST_MATH_COURSE_CATNBR         0             1
##   min max empty n_unique whitespace
## 1   9   9     0        4          0
## 2   1   1     0        2          0
## 3   1   1     0        3          0
## 4   1   1     0        9          0
## 5   1   1     0        2          0
## 6   1   1     0        2          0
## 7   4   4     0       34          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable      n_missing complete_rate
##  1 grade_trinary              0             1
##  2 COHORTTERM                 0             1
##  3 FA_PELL                    0             1
##  4 APCREDIT                   0             1
##  5 HSGPA                      0             1
##  6 ACTCOMP                    0             1
##  7 ACTENGL                    0             1
##  8 ACTMATH                    0             1
##  9 ACTSCI                     0             1
## 10 MATH_IN_FIRST_YEAR         0             1
##        mean     sd      p0     p25     p50     p75
##  1    1.80   0.530    0       2       2       2   
##  2 1232.    11.0   1218    1218    1228    1238   
##  3    0.166  0.372    0       0       0       0   
##  4   17.2   12.7      3       6      14      24   
##  5    3.82   0.229    2.66    3.74    3.92    3.99
##  6   27.9    4.25    10      25      28      31   
##  7   27.8    5.23     8      24      28      33   
##  8   27.1    4.80    10      24      27      30   
##  9   27.7    4.77     7      24      27      32   
## 10    0.946  0.227    0       1       1       1   
##    p100 hist 
##  1    2 ▁▁▁▁▇
##  2 1248 ▇▇▁▇▇
##  3    1 ▇▁▁▁▂
##  4   78 ▇▃▁▁▁
##  5    4 ▁▁▁▂▇
##  6   36 ▁▁▅▇▆
##  7   36 ▁▁▆▇▇
##  8   36 ▁▂▆▇▅
##  9   36 ▁▁▅▇▆
## 10    1 ▁▁▁▁▇
## 
## [[3]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             2923                        
## Number of columns          17                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   numeric                  10                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────
##   skim_variable            n_missing complete_rate
## 1 COHORT                           0             1
## 2 SEX                              0             1
## 3 FIRST_GEN_STATUS_CD              0             1
## 4 ETHNICITY                        0             1
## 5 RESSTAT                          0             1
## 6 HSPRIVATE                        0             1
## 7 FIRST_MATH_COURSE_CATNBR         0             1
##   min max empty n_unique whitespace
## 1   9   9     0        4          0
## 2   1   1     0        2          0
## 3   1   1     0        3          0
## 4   1   1     0        9          0
## 5   1   1     0        2          0
## 6   1   1     0        2          0
## 7   4   4     0       34          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable      n_missing complete_rate
##  1 grade_quad                 0             1
##  2 COHORTTERM                 0             1
##  3 FA_PELL                    0             1
##  4 APCREDIT                   0             1
##  5 HSGPA                      0             1
##  6 ACTCOMP                    0             1
##  7 ACTENGL                    0             1
##  8 ACTMATH                    0             1
##  9 ACTSCI                     0             1
## 10 MATH_IN_FIRST_YEAR         0             1
##        mean     sd      p0     p25     p50     p75
##  1    2.30   0.854    0       2       3       3   
##  2 1233.    11.0   1218    1218    1228    1238   
##  3    0.171  0.377    0       0       0       0   
##  4   17.1   12.6      3       6      14      24   
##  5    3.82   0.231    2.66    3.73    3.92    3.99
##  6   27.9    4.23    10      25      28      31   
##  7   27.8    5.19     8      24      28      33   
##  8   27.0    4.81    10      24      27      30   
##  9   27.7    4.77     7      24      27      32   
## 10    0.947  0.225    0       1       1       1   
##    p100 hist 
##  1    3 ▁▁▁▆▇
##  2 1248 ▇▇▁▇▇
##  3    1 ▇▁▁▁▂
##  4   78 ▇▃▁▁▁
##  5    4 ▁▁▁▂▇
##  6   36 ▁▁▅▇▆
##  7   36 ▁▁▆▇▇
##  8   36 ▁▂▆▇▅
##  9   36 ▁▁▅▇▆
## 10    1 ▁▁▁▁▇
## 
## [[4]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             2923                        
## Number of columns          17                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   numeric                  10                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────
##   skim_variable            n_missing complete_rate
## 1 COHORT                           0             1
## 2 SEX                              0             1
## 3 FIRST_GEN_STATUS_CD              0             1
## 4 ETHNICITY                        0             1
## 5 RESSTAT                          0             1
## 6 HSPRIVATE                        0             1
## 7 FIRST_MATH_COURSE_CATNBR         0             1
##   min max empty n_unique whitespace
## 1   9   9     0        4          0
## 2   1   1     0        2          0
## 3   1   1     0        3          0
## 4   1   1     0        9          0
## 5   1   1     0        2          0
## 6   1   1     0        2          0
## 7   4   4     0       35          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable      n_missing complete_rate
##  1 GRADEGPA                   0             1
##  2 COHORTTERM                 0             1
##  3 FA_PELL                    0             1
##  4 APCREDIT                   0             1
##  5 HSGPA                      0             1
##  6 ACTCOMP                    0             1
##  7 ACTENGL                    0             1
##  8 ACTMATH                    0             1
##  9 ACTSCI                     0             1
## 10 MATH_IN_FIRST_YEAR         0             1
##        mean     sd      p0     p25     p50     p75
##  1    3.38   0.952    0       3       4       4   
##  2 1232.    11.0   1218    1218    1228    1238   
##  3    0.167  0.373    0       0       0       0   
##  4   16.9   12.4      3       6      14      24   
##  5    3.82   0.228    2.66    3.74    3.91    3.99
##  6   27.9    4.24    10      25      28      31   
##  7   27.8    5.20     8      24      28      33   
##  8   27.0    4.79    10      24      27      30   
##  9   27.7    4.76     7      24      27      32   
## 10    0.942  0.234    0       1       1       1   
##    p100 hist 
##  1    4 ▁▁▁▂▇
##  2 1248 ▇▇▁▇▇
##  3    1 ▇▁▁▁▂
##  4   75 ▇▃▂▁▁
##  5    4 ▁▁▁▂▇
##  6   36 ▁▁▅▇▆
##  7   36 ▁▁▆▇▇
##  8   36 ▁▂▆▇▅
##  9   36 ▁▁▆▇▆
## 10    1 ▁▁▁▁▇
```

