---
title: "Evaluate Grade Decision Trees using vH1 models"
date: "October 17, 2025"
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
##     1  8102
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
##     1  8102 
## [1] "grade_quad"
```

```
## [1] "GRADEGPA"
## missingFilter
## FALSE  TRUE 
##     1  8102
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
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.12 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.91 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.28 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.23 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.92 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.75 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_quad </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.89 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.72 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.29 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.30 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.88 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.72 </td>
  </tr>
</tbody>
</table>


![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vH1_results_files/figure-html/unnamed-chunk-6-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vH1_results_files/figure-html/unnamed-chunk-6-2.png)<!-- -->

# Variable importance

![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vH1_results_files/figure-html/unnamed-chunk-7-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vH1_results_files/figure-html/unnamed-chunk-7-2.png)<!-- -->



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
## Number of rows             32447                       
## Number of columns          22                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   factor                   2                           
##   numeric                  13                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ────────────────────────────────────────────────────────────────────
##   skim_variable       n_missing complete_rate min max empty n_unique whitespace
## 1 SEX                         0             1   1   1     0        2          0
## 2 FIRST_GEN_STATUS_CD         0             1   1   1     0        3          0
## 3 ETHNICITY                   0             1   1   1     0        9          0
## 4 RESSTAT                     0             1   1   1     0        2          0
## 5 HSPRIVATE                   0             1   1   1     0        2          0
## 6 season                      0             1   4   6     0        3          0
## 7 vol_cluster                 0             1   6   7     0        2          0
## 
## ── Variable type: factor ───────────────────────────────────────────────────────────────────────
##   skim_variable n_missing complete_rate ordered n_unique
## 1 course                0             1 FALSE         28
## 2 age_cut               0             1 FALSE          5
##   top_counts                                 
## 1 MAT: 7485, MAT: 5208, MAT: 4345, MAT: 2866 
## 2 (17: 26439, (18: 2773, (19: 1615, (0,: 1352
## 
## ── Variable type: numeric ──────────────────────────────────────────────────────────────────────
##    skim_variable n_missing complete_rate     mean     sd       p0      p25      p50      p75
##  1 GRADEGPA              0             1    2.86   1.22     0        2        3.3      4    
##  2 FA_PELL               0             1    0.219  0.414    0        0        0        0    
##  3 APCREDIT              0             1    7.37  12.6      0        0        0       12    
##  4 HSGPA                 0             1    3.63   0.341    1.07     3.42     3.72     3.92 
##  5 HONORS                0             1    0.159  0.366    0        0        0        0    
##  6 ACTCOMP               0             1   25.1    4.36    10       22       25       28    
##  7 ACTENGL               0             1   24.8    5.31     7       21       24       28    
##  8 ACTMATH               0             1   24.4    4.65     1       21       24       27    
##  9 ACTSCI                0             1   24.9    4.56     2       22       24       28    
## 10 cohort_year           0             1 2015.     5.55  2005     2010     2015     2019    
## 11 class_year            0             1 2015.     5.50  2005     2011     2016     2020    
## 12 yr_diff               0             1    0.496  0.779   -0.397    0.241    0.260    0.260
## 13 course_level          0             1    1.03   0.178    1        1        1        1    
##       p100 hist 
##  1    4    ▂▁▂▃▇
##  2    1    ▇▁▁▁▂
##  3   89    ▇▁▁▁▁
##  4    4.42 ▁▁▁▇▇
##  5    1    ▇▁▁▁▂
##  6   36    ▁▃▇▆▂
##  7   36    ▁▂▇▆▃
##  8   36    ▁▁▅▇▂
##  9   36    ▁▁▅▇▂
## 10 2024    ▆▆▇▇▆
## 11 2025    ▇▇▇▇▅
## 12   16.6  ▇▁▁▁▁
## 13    2    ▇▁▁▁▁
## 
## [[2]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             32447                       
## Number of columns          22                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   factor                   2                           
##   numeric                  13                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ────────────────────────────────────────────────────────────────────
##   skim_variable       n_missing complete_rate min max empty n_unique whitespace
## 1 SEX                         0             1   1   1     0        2          0
## 2 FIRST_GEN_STATUS_CD         0             1   1   1     0        3          0
## 3 ETHNICITY                   0             1   1   1     0        9          0
## 4 RESSTAT                     0             1   1   1     0        2          0
## 5 HSPRIVATE                   0             1   1   1     0        2          0
## 6 season                      0             1   4   6     0        3          0
## 7 vol_cluster                 0             1   6   7     0        2          0
## 
## ── Variable type: factor ───────────────────────────────────────────────────────────────────────
##   skim_variable n_missing complete_rate ordered n_unique
## 1 course                0             1 FALSE         29
## 2 age_cut               0             1 FALSE          5
##   top_counts                                 
## 1 MAT: 7502, MAT: 5181, MAT: 4326, MAT: 2854 
## 2 (17: 26470, (18: 2762, (19: 1627, (0,: 1315
## 
## ── Variable type: numeric ──────────────────────────────────────────────────────────────────────
##    skim_variable n_missing complete_rate     mean     sd       p0      p25      p50      p75
##  1 grade_quad            0             1    1.84   1.01     0        1        2        3    
##  2 FA_PELL               0             1    0.219  0.413    0        0        0        0    
##  3 APCREDIT              0             1    7.40  12.6      0        0        0       12    
##  4 HSGPA                 0             1    3.63   0.343    1.07     3.42     3.71     3.92 
##  5 HONORS                0             1    0.158  0.365    0        0        0        0    
##  6 ACTCOMP               0             1   25.1    4.37    10       22       25       28    
##  7 ACTENGL               0             1   24.8    5.30     7       21       24       29    
##  8 ACTMATH               0             1   24.5    4.65     1       21       24       27    
##  9 ACTSCI                0             1   25.0    4.58     2       22       24       28    
## 10 cohort_year           0             1 2015.     5.53  2005     2010     2015     2019    
## 11 class_year            0             1 2015.     5.48  2005     2011     2016     2020    
## 12 yr_diff               0             1    0.500  0.795   -0.397    0.241    0.260    0.260
## 13 course_level          0             1    1.03   0.180    1        1        1        1    
##       p100 hist 
##  1    3    ▃▃▁▇▆
##  2    1    ▇▁▁▁▂
##  3   89    ▇▁▁▁▁
##  4    4.42 ▁▁▁▇▇
##  5    1    ▇▁▁▁▂
##  6   36    ▁▃▇▆▂
##  7   36    ▁▂▇▆▃
##  8   36    ▁▁▅▇▂
##  9   36    ▁▁▅▇▂
## 10 2024    ▆▆▆▇▆
## 11 2025    ▇▆▇▇▅
## 12   16.6  ▇▁▁▁▁
## 13    2    ▇▁▁▁▁
```

