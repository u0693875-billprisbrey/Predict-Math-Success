---
title: "Evaluate Grade Decision Trees using vF2 models"
date: "October 09, 2025"
params: 
  version: "vF0"
output:
  html_document:
    keep_md: true
---











```
## [1] "grade_binary"
## missingFilter
## TRUE 
## 8520 
## [1] "grade_trinary"
## missingFilter
## FALSE  TRUE 
##     1  8519 
## [1] "grade_quad"
## missingFilter
## FALSE  TRUE 
##     3  8517 
## [1] "GRADEGPA"
## missingFilter
## FALSE  TRUE 
##     9  8263
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

course, SEX, FIRST_GEN_STATUS_CD, ETHNICITY, RESSTAT, FA_PELL, AGE, APCREDIT, HSGPA, HSPRIVATE, HONORS, ACTCOMP, ACTENGL, ACTMATH, ACTSCI, load, cohort_year, class_year, yr_diff, season. 

"load" is the credit load per student per term. 
"yr_diff" is the time (expressed as fractions of a year) between the cohort date and the end of term date for the course.  

The other variables are either self-explanatory or taken directly from OBIA tables.  

# Results

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
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.40 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.32 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.10 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.40 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.32 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.13 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.90 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_trinary </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.74 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.61 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.19 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.37 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.31 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.00 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.82 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_quad </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.89 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.73 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.28 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.30 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.88 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.72 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> GRADEGPA </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.12 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.90 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.28 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.23 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.91 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.74 </td>
  </tr>
</tbody>
</table>


![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF2_results_files/figure-html/unnamed-chunk-6-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF2_results_files/figure-html/unnamed-chunk-6-2.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF2_results_files/figure-html/unnamed-chunk-6-3.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF2_results_files/figure-html/unnamed-chunk-6-4.png)<!-- -->

# Variable importance

![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF2_results_files/figure-html/unnamed-chunk-7-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF2_results_files/figure-html/unnamed-chunk-7-2.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF2_results_files/figure-html/unnamed-chunk-7-3.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF2_results_files/figure-html/unnamed-chunk-7-4.png)<!-- -->



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
## Number of rows             34104                       
## Number of columns          21                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   numeric                  14                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────
##   skim_variable       n_missing complete_rate min
## 1 course                      0             1   7
## 2 SEX                         0             1   1
## 3 FIRST_GEN_STATUS_CD         0             1   1
## 4 ETHNICITY                   0             1   1
## 5 RESSTAT                     0             1   1
## 6 HSPRIVATE                   0             1   1
## 7 season                      0             1   4
##   max empty n_unique whitespace
## 1  10     0       62          0
## 2   1     0        2          0
## 3   1     0        3          0
## 4   1     0        9          0
## 5   1     0        2          0
## 6   1     0        2          0
## 7   6     0        3          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable n_missing complete_rate     mean
##  1 grade_binary          0             1    0.848
##  2 FA_PELL               0             1    0.226
##  3 AGE                   0             1   18.2  
##  4 APCREDIT              0             1    7.25 
##  5 HSGPA                 0             1    3.62 
##  6 HONORS                0             1    0.157
##  7 ACTCOMP               0             1   24.9  
##  8 ACTENGL               0             1   24.7  
##  9 ACTMATH               0             1   24.2  
## 10 ACTSCI                0             1   24.8  
## 11 load                  0             1   13.6  
## 12 cohort_year           0             1 2015.   
## 13 class_year            0             1 2015.   
## 14 yr_diff               0             1    0.511
##        sd       p0      p25      p50      p75
##  1  0.359    0        1        1        1    
##  2  0.418    0        0        0        0    
##  3  0.788    1       18       18       18    
##  4 12.5      0        0        0       12    
##  5  0.349    1.07     3.4      3.71     3.91 
##  6  0.364    0        0        0        0    
##  7  4.47    10       22       25       28    
##  8  5.38     5       21       24       28    
##  9  4.82     1       21       24       27    
## 10  4.66     2       22       24       28    
## 11  2.38     0       12.5     14       15    
## 12  5.50  2005     2010     2015     2019    
## 13  5.45  2005     2010     2015     2019    
## 14  0.822   -0.397    0.241    0.260    0.260
##       p100 hist 
##  1    1    ▂▁▁▁▇
##  2    1    ▇▁▁▁▂
##  3   39    ▁▁▇▁▁
##  4   88    ▇▁▁▁▁
##  5    4.42 ▁▁▂▇▇
##  6    1    ▇▁▁▁▂
##  7   36    ▁▃▇▆▂
##  8   36    ▁▂▇▇▅
##  9   36    ▁▁▅▇▂
## 10   36    ▁▁▅▇▂
## 11   19    ▁▁▁▇▂
## 12 2024    ▆▇▇▇▆
## 13 2025    ▇▇▇▇▅
## 14   16.6  ▇▁▁▁▁
## 
## [[2]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             34104                       
## Number of columns          21                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   numeric                  14                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────
##   skim_variable       n_missing complete_rate min
## 1 course                      0             1   7
## 2 SEX                         0             1   1
## 3 FIRST_GEN_STATUS_CD         0             1   1
## 4 ETHNICITY                   0             1   1
## 5 RESSTAT                     0             1   1
## 6 HSPRIVATE                   0             1   1
## 7 season                      0             1   4
##   max empty n_unique whitespace
## 1  10     0       61          0
## 2   1     0        2          0
## 3   1     0        3          0
## 4   1     0        9          0
## 5   1     0        2          0
## 6   1     0        2          0
## 7   6     0        3          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable n_missing complete_rate     mean
##  1 grade_trinary         0             1    1.54 
##  2 FA_PELL               0             1    0.225
##  3 AGE                   0             1   18.2  
##  4 APCREDIT              0             1    7.32 
##  5 HSGPA                 0             1    3.62 
##  6 HONORS                0             1    0.157
##  7 ACTCOMP               0             1   24.9  
##  8 ACTENGL               0             1   24.7  
##  9 ACTMATH               0             1   24.3  
## 10 ACTSCI                0             1   24.8  
## 11 load                  0             1   13.6  
## 12 cohort_year           0             1 2015.   
## 13 class_year            0             1 2015.   
## 14 yr_diff               0             1    0.512
##        sd       p0      p25      p50      p75
##  1  0.743    0        1        2        2    
##  2  0.418    0        0        0        0    
##  3  0.812    1       18       18       18    
##  4 12.6      0        0        0       12    
##  5  0.349    1.07     3.4      3.71     3.92 
##  6  0.364    0        0        0        0    
##  7  4.48    10       22       25       28    
##  8  5.40     5       21       24       28    
##  9  4.83     1       21       24       27    
## 10  4.65     2       22       24       27    
## 11  2.39     0       12.5     14       15    
## 12  5.50  2005     2010     2015     2019    
## 13  5.45  2005     2010     2015     2019    
## 14  0.823   -0.397    0.241    0.260    0.260
##       p100 hist 
##  1    2    ▂▁▂▁▇
##  2    1    ▇▁▁▁▂
##  3   49    ▁▇▁▁▁
##  4   89    ▇▁▁▁▁
##  5    4.42 ▁▁▂▇▇
##  6    1    ▇▁▁▁▂
##  7   36    ▁▃▇▆▂
##  8   36    ▁▂▇▇▅
##  9   36    ▁▁▅▇▂
## 10   36    ▁▁▅▇▂
## 11   19    ▁▁▁▇▂
## 12 2024    ▆▇▇▇▆
## 13 2025    ▇▇▇▇▅
## 14   16.6  ▇▁▁▁▁
## 
## [[3]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             34104                       
## Number of columns          21                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   numeric                  14                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────
##   skim_variable       n_missing complete_rate min
## 1 course                      0             1   7
## 2 SEX                         0             1   1
## 3 FIRST_GEN_STATUS_CD         0             1   1
## 4 ETHNICITY                   0             1   1
## 5 RESSTAT                     0             1   1
## 6 HSPRIVATE                   0             1   1
## 7 season                      0             1   4
##   max empty n_unique whitespace
## 1   9     0       59          0
## 2   1     0        2          0
## 3   1     0        3          0
## 4   1     0        9          0
## 5   1     0        2          0
## 6   1     0        2          0
## 7   6     0        3          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable n_missing complete_rate     mean
##  1 grade_quad            0             1    1.84 
##  2 FA_PELL               0             1    0.223
##  3 AGE                   0             1   18.2  
##  4 APCREDIT              0             1    7.30 
##  5 HSGPA                 0             1    3.62 
##  6 HONORS                0             1    0.158
##  7 ACTCOMP               0             1   24.9  
##  8 ACTENGL               0             1   24.7  
##  9 ACTMATH               0             1   24.3  
## 10 ACTSCI                0             1   24.8  
## 11 load                  0             1   13.6  
## 12 cohort_year           0             1 2015.   
## 13 class_year            0             1 2015.   
## 14 yr_diff               0             1    0.511
##        sd       p0      p25      p50      p75
##  1  1.02     0        1        2        3    
##  2  0.416    0        0        0        0    
##  3  0.792   14       18       18       18    
##  4 12.6      0        0        0       12    
##  5  0.348    1.07     3.4      3.71     3.91 
##  6  0.365    0        0        0        0    
##  7  4.47    10       22       25       28    
##  8  5.38     5       21       24       28    
##  9  4.83     1       21       24       27    
## 10  4.66     2       22       24       28    
## 11  2.38     0       12.5     14       15    
## 12  5.51  2005     2010     2015     2019    
## 13  5.46  2005     2010     2015     2019    
## 14  0.826   -0.397    0.241    0.260    0.260
##       p100 hist 
##  1    3    ▃▃▁▇▆
##  2    1    ▇▁▁▁▂
##  3   39    ▇▁▁▁▁
##  4   89    ▇▁▁▁▁
##  5    4.42 ▁▁▂▇▇
##  6    1    ▇▁▁▁▂
##  7   36    ▁▃▇▆▂
##  8   36    ▁▂▇▇▅
##  9   36    ▁▁▅▇▂
## 10   36    ▁▁▅▇▂
## 11   19    ▁▁▁▇▂
## 12 2024    ▆▇▇▇▆
## 13 2025    ▇▇▇▇▅
## 14   16.6  ▇▁▁▁▁
## 
## [[4]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             33121                       
## Number of columns          21                          
## _______________________                                
## Column type frequency:                                 
##   character                7                           
##   numeric                  14                          
## ________________________                               
## Group variables            None                        
## 
## ── Variable type: character ──────────────────────
##   skim_variable       n_missing complete_rate min
## 1 course                      0             1   8
## 2 SEX                         0             1   1
## 3 FIRST_GEN_STATUS_CD         0             1   1
## 4 ETHNICITY                   0             1   1
## 5 RESSTAT                     0             1   1
## 6 HSPRIVATE                   0             1   1
## 7 season                      0             1   4
##   max empty n_unique whitespace
## 1   9     0       53          0
## 2   1     0        2          0
## 3   1     0        3          0
## 4   1     0        9          0
## 5   1     0        2          0
## 6   1     0        2          0
## 7   6     0        3          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable n_missing complete_rate     mean
##  1 GRADEGPA              0             1    2.86 
##  2 FA_PELL               0             1    0.218
##  3 AGE                   0             1   18.2  
##  4 APCREDIT              0             1    7.45 
##  5 HSGPA                 0             1    3.63 
##  6 HONORS                0             1    0.163
##  7 ACTCOMP               0             1   25.1  
##  8 ACTENGL               0             1   24.9  
##  9 ACTMATH               0             1   24.5  
## 10 ACTSCI                0             1   25.0  
## 11 load                  0             1   13.7  
## 12 cohort_year           0             1 2015.   
## 13 class_year            0             1 2015.   
## 14 yr_diff               0             1    0.508
##        sd       p0      p25      p50      p75
##  1  1.22     0        2.3      3.3      4    
##  2  0.413    0        0        0        0    
##  3  0.810   14       18       18       18    
##  4 12.7      0        0        0       12    
##  5  0.342    1.18     3.42     3.72     3.92 
##  6  0.369    0        0        0        0    
##  7  4.38    10       22       25       28    
##  8  5.33     7       21       24       29    
##  9  4.69     1       21       25       27    
## 10  4.59     2       22       24       28    
## 11  2.25     2       13       14       15    
## 12  5.54  2005     2010     2015     2019    
## 13  5.49  2005     2011     2015     2020    
## 14  0.817   -0.397    0.241    0.260    0.260
##       p100 hist 
##  1    4    ▂▁▂▃▇
##  2    1    ▇▁▁▁▂
##  3   49    ▇▁▁▁▁
##  4   89    ▇▁▁▁▁
##  5    4.42 ▁▁▂▇▇
##  6    1    ▇▁▁▁▂
##  7   36    ▁▃▇▆▂
##  8   36    ▁▂▇▆▃
##  9   36    ▁▁▅▇▂
## 10   36    ▁▁▅▇▂
## 11   19    ▁▁▃▇▂
## 12 2024    ▆▆▇▇▆
## 13 2025    ▇▇▇▇▅
## 14   16.6  ▇▁▁▁▁
```

