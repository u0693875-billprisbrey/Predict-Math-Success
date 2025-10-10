---
title: "Evaluate Grade Decision Trees using vG1 models"
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
##     3  1549
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
##     3  1549
```

```
## [1] "grade_binary"
## missingFilter
## FALSE  TRUE 
##     3  1549
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
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.35 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.07 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.35 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.07 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.73 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_trinary </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.69 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.54 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.19 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.34 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.27 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.99 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.78 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_quad </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.88 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.71 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.30 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.29 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.88 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.72 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> GRADEGPA </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.08 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.87 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.25 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.27 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.22 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.92 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.74 </td>
  </tr>
</tbody>
</table>


![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG1_results_files/figure-html/unnamed-chunk-6-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG1_results_files/figure-html/unnamed-chunk-6-2.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG1_results_files/figure-html/unnamed-chunk-6-3.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG1_results_files/figure-html/unnamed-chunk-6-4.png)<!-- -->

# Variable importance

![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG1_results_files/figure-html/unnamed-chunk-7-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG1_results_files/figure-html/unnamed-chunk-7-2.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG1_results_files/figure-html/unnamed-chunk-7-3.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vG1_results_files/figure-html/unnamed-chunk-7-4.png)<!-- -->



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
## Number of rows             6234                        
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
##  1    0.877  0.328    0       1       1       1   
##  2 1232.    11.0   1218    1218    1228    1238   
##  3    0.226  0.418    0       0       0       0   
##  4    7.99  12.1      0       0       0      12   
##  5    3.74   0.271    2.42    3.59    3.83    3.97
##  6   25.6    4.95    10      22      26      29   
##  7   25.2    5.93     9      21      25      30   
##  8   24.8    5.33    10      21      25      28   
##  9   25.6    5.11     7      22      25      29   
## 10    0.940  0.238    0       1       1       1   
##    p100 hist 
##  1    1 ▁▁▁▁▇
##  2 1248 ▇▇▁▆▆
##  3    1 ▇▁▁▁▂
##  4   78 ▇▂▁▁▁
##  5    4 ▁▁▁▂▇
##  6   36 ▁▃▇▇▅
##  7   36 ▁▃▇▅▅
##  8   36 ▁▆▇▇▃
##  9   36 ▁▂▇▇▅
## 10    1 ▁▁▁▁▇
## 
## [[2]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             6234                        
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
## 7   4   4     0       36          0
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
##  1    1.62   0.693    0       1       2       2   
##  2 1232.    11.0   1218    1218    1228    1238   
##  3    0.225  0.417    0       0       0       0   
##  4    8.11  12.2      0       0       0      12.8 
##  5    3.74   0.272    2.42    3.59    3.83    3.97
##  6   25.6    4.96    10      22      26      29   
##  7   25.2    5.97     8      21      25      30   
##  8   24.8    5.32     8      21      25      28   
##  9   25.6    5.07     7      22      25      29   
## 10    0.940  0.238    0       1       1       1   
##    p100 hist 
##  1    2 ▁▁▂▁▇
##  2 1248 ▇▇▁▆▆
##  3    1 ▇▁▁▁▂
##  4   78 ▇▂▁▁▁
##  5    4 ▁▁▁▂▇
##  6   36 ▁▃▇▇▅
##  7   36 ▁▃▇▇▆
##  8   36 ▁▅▅▇▃
##  9   36 ▁▂▇▇▅
## 10    1 ▁▁▁▁▇
## 
## [[3]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             6234                        
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
## 7   4   4     0       36          0
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
##  1    1.99   0.996    0       1       2       3   
##  2 1231.    11.0   1218    1218    1228    1238   
##  3    0.225  0.418    0       0       0       0   
##  4    8.03  12.2      0       0       0      12   
##  5    3.74   0.271    2.42    3.59    3.83    3.97
##  6   25.6    4.96    10      22      26      29   
##  7   25.2    5.94     8      21      25      30   
##  8   24.8    5.34     8      21      25      28   
##  9   25.6    5.11     7      22      25      29   
## 10    0.942  0.233    0       1       1       1   
##    p100 hist 
##  1    3 ▂▃▁▇▇
##  2 1248 ▇▇▁▆▆
##  3    1 ▇▁▁▁▂
##  4   78 ▇▂▁▁▁
##  5    4 ▁▁▁▂▇
##  6   36 ▁▃▇▇▅
##  7   36 ▁▃▇▇▆
##  8   36 ▁▅▅▇▃
##  9   36 ▁▂▇▇▅
## 10    1 ▁▁▁▁▇
## 
## [[4]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             6234                        
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
## 7   4   4     0       36          0
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
##  1    3.03   1.17     0       2.3     3.3     4   
##  2 1232.    11.0   1218    1218    1228    1238   
##  3    0.224  0.417    0       0       0       0   
##  4    8.11  12.2      0       0       0      13   
##  5    3.74   0.269    2.48    3.59    3.83    3.97
##  6   25.6    4.98    11      22      26      30   
##  7   25.3    5.97     8      21      25      30   
##  8   24.8    5.32     8      21      25      28   
##  9   25.7    5.11     7      22      25      30   
## 10    0.942  0.234    0       1       1       1   
##    p100 hist 
##  1    4 ▁▁▂▂▇
##  2 1248 ▇▇▁▇▆
##  3    1 ▇▁▁▁▂
##  4   78 ▇▂▁▁▁
##  5    4 ▁▁▁▂▇
##  6   36 ▁▅▇▇▃
##  7   36 ▁▃▇▇▆
##  8   36 ▁▃▅▇▃
##  9   36 ▁▂▇▇▅
## 10    1 ▁▁▁▁▇
```

