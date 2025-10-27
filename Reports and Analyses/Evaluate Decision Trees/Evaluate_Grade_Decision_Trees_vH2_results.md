---
title: "Evaluate Grade Decision Trees using vH2 models"
date: "October 27, 2025"
params: 
  version: "vH0"
  target_classes: 
    - GRADEGPA
    - grade_quad
output:
  html_document:
    keep_md: true
---











```
## [1] "GRADEGPA"
## missingFilter
## FALSE  TRUE 
##    11  2003 
## [1] "grade_quad"
## missingFilter
## FALSE  TRUE 
##    11  2003
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

course, SEX, FIRST_GEN_STATUS_CD, ETHNICITY, RESSTAT, FA_PELL, APCREDIT, HSGPA, HSPRIVATE, HONORS, ACTCOMP, ACTENGL, ACTMATH, ACTSCI, cohort_year, class_year, yr_diff, season, course_level, vol_cluster, age_cut. 

"load" is the credit load per student per term. 
"yr_diff" is the time (expressed as fractions of a year) between the cohort date and the end of term date for the course.  

The other variables are either self-explanatory or taken directly from OBIA tables.  

# Results


```
## [1] "GRADEGPA"
## [1] "GRADEGPA"
## missingFilter
## FALSE  TRUE 
##    11  2003 
## [1] "grade_quad"
## [1] "grade_quad"
## missingFilter
## FALSE  TRUE 
##    11  2003
```

```
## [1] "GRADEGPA"
## missingFilter
## FALSE  TRUE 
##    11  2003 
## [1] "grade_quad"
## missingFilter
## FALSE  TRUE 
##    11  2003
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
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> R-sq </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> NRMSE (Range) </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> NMAE (Range) </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> NRMSE (SD) </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> NMAE (SD) </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> GRADEGPA </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.06 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.84 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.26 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.26 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.21 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.92 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.73 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_quad </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.85 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.67 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.30 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.28 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.22 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.86 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.68 </td>
  </tr>
</tbody>
</table>


![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vH2_results_files/figure-html/unnamed-chunk-6-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vH2_results_files/figure-html/unnamed-chunk-6-2.png)<!-- -->

# Variable importance

![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vH2_results_files/figure-html/unnamed-chunk-7-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vH2_results_files/figure-html/unnamed-chunk-7-2.png)<!-- -->



# Training data


Presentation order: 


```
## [1] "GRADEGPA"
## [1] "grade_quad"
```

```
## [[1]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             38536                       
## Number of columns          22                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   factor                   2                           
##   numeric                  13                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────────────────────────────────────
##   skim_variable       n_missing complete_rate min max empty n_unique whitespace
## 1 SEX                         0             1   1   1     0        2          0
## 2 FIRST_GEN_STATUS_CD         0             1   1   1     0        3          0
## 3 ETHNICITY                   0             1   1   1     0        9          0
## 4 RESSTAT                     0             1   1   1     0        2          0
## 5 HSPRIVATE                   0             1   1   1     0        2          0
## 6 season                      0             1   4   6     0        3          0
## 7 vol_cluster                 0             1   6   7     0        2          0
## 
## ── Variable type: factor ─────────────────────────────────────────────────────────
##   skim_variable n_missing complete_rate ordered n_unique
## 1 course                0             1 FALSE         28
## 2 age_cut               0             1 FALSE          5
##   top_counts                                 
## 1 MAT: 9263, MAT: 6206, MAT: 5069, MAT: 3385 
## 2 (17: 31449, (18: 3283, (19: 1928, (0,: 1552
## 
## ── Variable type: numeric ────────────────────────────────────────────────────────
##    skim_variable n_missing complete_rate     mean     sd       p0      p25
##  1 GRADEGPA              0             1    2.85   1.22     0        2    
##  2 FA_PELL               0             1    0.218  0.413    0        0    
##  3 APCREDIT              0             1    7.30  12.6      0        0    
##  4 HSGPA                 0             1    3.62   0.344    1.07     3.41 
##  5 HONORS                0             1    0.161  0.367    0        0    
##  6 ACTCOMP               0             1   25.0    4.33    11       22    
##  7 ACTENGL               0             1   24.8    5.27     7       21    
##  8 ACTMATH               0             1   24.4    4.61     1       21    
##  9 ACTSCI                0             1   24.9    4.54     2       22    
## 10 cohort_year           0             1 2014.     5.28  2005     2010    
## 11 class_year            0             1 2015.     5.22  2005     2010    
## 12 yr_diff               0             1    0.493  0.783   -0.397    0.241
## 13 course_level          0             1    1.03   0.173    1        1    
##         p50      p75    p100 hist 
##  1    3.3      4        4    ▂▁▂▃▇
##  2    0        0        1    ▇▁▁▁▂
##  3    0       12       89    ▇▁▁▁▁
##  4    3.71     3.91     4.42 ▁▁▁▇▇
##  5    0        0        1    ▇▁▁▁▂
##  6   25       28       36    ▁▅▇▅▂
##  7   24       28       36    ▁▂▇▆▃
##  8   24       27       36    ▁▁▅▇▂
##  9   24       28       36    ▁▁▅▇▂
## 10 2015     2019     2023    ▆▆▅▇▆
## 11 2015     2019     2023    ▅▆▅▇▇
## 12    0.258    0.260   16.6  ▇▁▁▁▁
## 13    1        1        2    ▇▁▁▁▁
## 
## [[2]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             38536                       
## Number of columns          22                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   factor                   2                           
##   numeric                  13                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────────────────────────────────────
##   skim_variable       n_missing complete_rate min max empty n_unique whitespace
## 1 SEX                         0             1   1   1     0        2          0
## 2 FIRST_GEN_STATUS_CD         0             1   1   1     0        3          0
## 3 ETHNICITY                   0             1   1   1     0        9          0
## 4 RESSTAT                     0             1   1   1     0        2          0
## 5 HSPRIVATE                   0             1   1   1     0        2          0
## 6 season                      0             1   4   6     0        3          0
## 7 vol_cluster                 0             1   6   7     0        2          0
## 
## ── Variable type: factor ─────────────────────────────────────────────────────────
##   skim_variable n_missing complete_rate ordered n_unique
## 1 course                0             1 FALSE         28
## 2 age_cut               0             1 FALSE          5
##   top_counts                                 
## 1 MAT: 9263, MAT: 6206, MAT: 5069, MAT: 3385 
## 2 (17: 31449, (18: 3283, (19: 1928, (0,: 1552
## 
## ── Variable type: numeric ────────────────────────────────────────────────────────
##    skim_variable n_missing complete_rate     mean     sd       p0      p25
##  1 grade_quad            0             1    1.83   1.01     0        1    
##  2 FA_PELL               0             1    0.218  0.413    0        0    
##  3 APCREDIT              0             1    7.30  12.6      0        0    
##  4 HSGPA                 0             1    3.62   0.344    1.07     3.41 
##  5 HONORS                0             1    0.161  0.367    0        0    
##  6 ACTCOMP               0             1   25.0    4.33    11       22    
##  7 ACTENGL               0             1   24.8    5.27     7       21    
##  8 ACTMATH               0             1   24.4    4.61     1       21    
##  9 ACTSCI                0             1   24.9    4.54     2       22    
## 10 cohort_year           0             1 2014.     5.28  2005     2010    
## 11 class_year            0             1 2015.     5.22  2005     2010    
## 12 yr_diff               0             1    0.493  0.783   -0.397    0.241
## 13 course_level          0             1    1.03   0.173    1        1    
##         p50      p75    p100 hist 
##  1    2        3        3    ▃▃▁▇▆
##  2    0        0        1    ▇▁▁▁▂
##  3    0       12       89    ▇▁▁▁▁
##  4    3.71     3.91     4.42 ▁▁▁▇▇
##  5    0        0        1    ▇▁▁▁▂
##  6   25       28       36    ▁▅▇▅▂
##  7   24       28       36    ▁▂▇▆▃
##  8   24       27       36    ▁▁▅▇▂
##  9   24       28       36    ▁▁▅▇▂
## 10 2015     2019     2023    ▆▆▅▇▆
## 11 2015     2019     2023    ▅▆▅▇▇
## 12    0.258    0.260   16.6  ▇▁▁▁▁
## 13    1        1        2    ▇▁▁▁▁
```

