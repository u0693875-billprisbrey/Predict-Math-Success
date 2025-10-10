---
title: "Evaluate Grade Decision Trees using vF0 models"
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
## FALSE  TRUE 
##     2  6394 
## [1] "grade_trinary"
## missingFilter
## FALSE  TRUE 
##     5  6391 
## [1] "grade_quad"
## missingFilter
## FALSE  TRUE 
##     3  6393 
## [1] "GRADEGPA"
## missingFilter
## FALSE  TRUE 
##     2  6147
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
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.39 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.30 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.11 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.39 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.30 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.11 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.85 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_trinary </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.73 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.59 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.18 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.37 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.30 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.00 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.81 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> grade_quad </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.89 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.72 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.28 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.30 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.24 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.88 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.71 </td>
  </tr>
  <tr>
   <td style="text-align:left;background-color: rgba(255, 255, 255, 255) !important;"> GRADEGPA </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.10 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.90 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.27 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.28 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.23 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.91 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.75 </td>
  </tr>
</tbody>
</table>


![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF0_results_files/figure-html/unnamed-chunk-6-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF0_results_files/figure-html/unnamed-chunk-6-2.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF0_results_files/figure-html/unnamed-chunk-6-3.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF0_results_files/figure-html/unnamed-chunk-6-4.png)<!-- -->

# Variable importance

![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF0_results_files/figure-html/unnamed-chunk-7-1.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF0_results_files/figure-html/unnamed-chunk-7-2.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF0_results_files/figure-html/unnamed-chunk-7-3.png)<!-- -->![](C:\Users\u0693875\Documents\Projects\FIRST TIME FRESHMEN\Predict-Math-Success\Reports and Analyses\Evaluate Decision Trees\Evaluate_Grade_Decision_Trees_vF0_results_files/figure-html/unnamed-chunk-7-4.png)<!-- -->



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
## Number of rows             25616                       
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
##  1 grade_binary          0             1    0.856
##  2 FA_PELL               0             1    0.211
##  3 AGE                   0             1   18.2  
##  4 APCREDIT              0             1    9.69 
##  5 HSGPA                 0             1    3.62 
##  6 HONORS                0             1    0.187
##  7 ACTCOMP               0             1   25.3  
##  8 ACTENGL               0             1   25.1  
##  9 ACTMATH               0             1   24.6  
## 10 ACTSCI                0             1   25.1  
## 11 load                  0             1   13.6  
## 12 cohort_year           0             1 2013.   
## 13 class_year            0             1 2013.   
## 14 yr_diff               0             1    0.539
##        sd       p0      p25      p50      p75
##  1  0.352    0        1        1        1    
##  2  0.408    0        0        0        0    
##  3  0.762    1       18       18       18    
##  4 13.6      0        0        3       16    
##  5  0.360    1.2      3.4      3.72     3.92 
##  6  0.390    0        0        0        0    
##  7  4.51    10       22       25       29    
##  8  5.39     5       21       25       29    
##  9  4.92     1       21       25       28    
## 10  4.76     2       22       25       28    
## 11  2.44     0       12       14       15    
## 12  5.22  2005     2009     2012     2017    
## 13  5.18  2005     2009     2013     2017    
## 14  0.899   -0.397    0.240    0.241    0.260
##      p100 hist 
##  1    1   ▂▁▁▁▇
##  2    1   ▇▁▁▁▂
##  3   37   ▁▁▇▁▁
##  4   88   ▇▂▁▁▁
##  5    4   ▁▁▁▂▇
##  6    1   ▇▁▁▁▂
##  7   36   ▁▃▇▇▃
##  8   36   ▁▂▇▇▅
##  9   36   ▁▁▅▇▂
## 10   36   ▁▁▅▇▃
## 11   19   ▁▁▁▇▂
## 12 2024   ▇▇▇▅▃
## 13 2025   ▇▇▆▅▂
## 14   16.6 ▇▁▁▁▁
## 
## [[2]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             25616                       
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
## 1   9     0       57          0
## 2   1     0        2          0
## 3   1     0        3          0
## 4   1     0        9          0
## 5   1     0        2          0
## 6   1     0        2          0
## 7   6     0        3          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable n_missing complete_rate     mean
##  1 grade_trinary         0             1    1.56 
##  2 FA_PELL               0             1    0.210
##  3 AGE                   0             1   18.2  
##  4 APCREDIT              0             1    9.71 
##  5 HSGPA                 0             1    3.62 
##  6 HONORS                0             1    0.188
##  7 ACTCOMP               0             1   25.3  
##  8 ACTENGL               0             1   25.1  
##  9 ACTMATH               0             1   24.6  
## 10 ACTSCI                0             1   25.1  
## 11 load                  0             1   13.6  
## 12 cohort_year           0             1 2013.   
## 13 class_year            0             1 2013.   
## 14 yr_diff               0             1    0.543
##        sd       p0      p25      p50      p75
##  1  0.732    0        1        2        2    
##  2  0.407    0        0        0        0    
##  3  0.756    1       18       18       18    
##  4 13.6      0        0        3       16    
##  5  0.360    1.2      3.4      3.72     3.93 
##  6  0.391    0        0        0        0    
##  7  4.53    10       22       25       29    
##  8  5.41     5       21       25       29    
##  9  4.94     1       21       25       28    
## 10  4.77     2       22       25       28    
## 11  2.44     0       12       14       15    
## 12  5.23  2005     2009     2012     2017    
## 13  5.19  2005     2009     2013     2017    
## 14  0.894   -0.397    0.240    0.241    0.260
##      p100 hist 
##  1    2   ▂▁▂▁▇
##  2    1   ▇▁▁▁▂
##  3   29   ▁▁▁▇▁
##  4   89   ▇▂▁▁▁
##  5    4   ▁▁▁▂▇
##  6    1   ▇▁▁▁▂
##  7   36   ▁▃▇▇▃
##  8   36   ▁▂▇▇▅
##  9   36   ▁▁▅▇▂
## 10   36   ▁▁▅▇▃
## 11   19   ▁▁▁▇▂
## 12 2024   ▇▇▇▅▃
## 13 2025   ▇▇▆▅▂
## 14   14.2 ▇▁▁▁▁
## 
## [[3]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             25616                       
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
## 1   9     0       58          0
## 2   1     0        2          0
## 3   1     0        3          0
## 4   1     0        9          0
## 5   1     0        2          0
## 6   1     0        2          0
## 7   6     0        3          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable n_missing complete_rate     mean
##  1 grade_quad            0             1    1.88 
##  2 FA_PELL               0             1    0.210
##  3 AGE                   0             1   18.2  
##  4 APCREDIT              0             1    9.65 
##  5 HSGPA                 0             1    3.62 
##  6 HONORS                0             1    0.187
##  7 ACTCOMP               0             1   25.3  
##  8 ACTENGL               0             1   25.1  
##  9 ACTMATH               0             1   24.6  
## 10 ACTSCI                0             1   25.1  
## 11 load                  0             1   13.6  
## 12 cohort_year           0             1 2013.   
## 13 class_year            0             1 2013.   
## 14 yr_diff               0             1    0.539
##        sd       p0      p25      p50      p75
##  1  1.02     0        1        2        3    
##  2  0.408    0        0        0        0    
##  3  0.755    1       18       18       18    
##  4 13.6      0        0        3       16    
##  5  0.361    1.18     3.4      3.72     3.93 
##  6  0.390    0        0        0        0    
##  7  4.53    10       22       25       29    
##  8  5.42     5       21       25       29    
##  9  4.93     1       21       25       28    
## 10  4.77     2       22       25       28    
## 11  2.45     0       12       14       15    
## 12  5.22  2005     2009     2012     2017    
## 13  5.18  2005     2009     2013     2017    
## 14  0.899   -0.397    0.240    0.241    0.260
##      p100 hist 
##  1    3   ▃▃▁▇▆
##  2    1   ▇▁▁▁▂
##  3   26   ▁▁▁▇▁
##  4   89   ▇▂▁▁▁
##  5    4   ▁▁▁▂▇
##  6    1   ▇▁▁▁▂
##  7   36   ▁▃▇▇▃
##  8   36   ▁▂▇▇▅
##  9   36   ▁▁▅▇▂
## 10   36   ▁▁▅▇▃
## 11   19   ▁▁▁▇▂
## 12 2024   ▇▇▇▅▃
## 13 2025   ▇▇▆▃▂
## 14   16.6 ▇▁▁▁▁
## 
## [[4]]
## ── Data Summary ────────────────────────
##                            Values                      
## Name                       data_list[[x]][["training...
## Number of rows             24632                       
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
## 1   9     0       58          0
## 2   1     0        2          0
## 3   1     0        3          0
## 4   1     0        9          0
## 5   1     0        2          0
## 6   1     0        2          0
## 7   6     0        3          0
## 
## ── Variable type: numeric ────────────────────────
##    skim_variable n_missing complete_rate     mean
##  1 GRADEGPA              0             1    2.91 
##  2 FA_PELL               0             1    0.203
##  3 AGE                   0             1   18.2  
##  4 APCREDIT              0             1   10.1  
##  5 HSGPA                 0             1    3.64 
##  6 HONORS                0             1    0.194
##  7 ACTCOMP               0             1   25.6  
##  8 ACTENGL               0             1   25.4  
##  9 ACTMATH               0             1   24.9  
## 10 ACTSCI                0             1   25.3  
## 11 load                  0             1   13.7  
## 12 cohort_year           0             1 2013.   
## 13 class_year            0             1 2013.   
## 14 yr_diff               0             1    0.536
##        sd       p0      p25      p50      p75
##  1  1.21     0        2.3      3.3      4    
##  2  0.402    0        0        0        0    
##  3  0.751   14       18       18       18    
##  4 13.8      0        0        3       16    
##  5  0.352    1.18     3.43     3.74     3.93 
##  6  0.396    0        0        0        0    
##  7  4.38    11       22       25       29    
##  8  5.28     7       22       25       29    
##  9  4.72     1       22       25       28    
## 10  4.68     2       22       25       28    
## 11  2.27     2       13       14       15    
## 12  5.29  2005     2009     2012     2017    
## 13  5.25  2005     2009     2013     2017    
## 14  0.894   -0.397    0.240    0.241    0.260
##      p100 hist 
##  1    4   ▂▁▂▃▇
##  2    1   ▇▁▁▁▂
##  3   37   ▇▁▁▁▁
##  4   89   ▇▂▁▁▁
##  5    4   ▁▁▁▂▇
##  6    1   ▇▁▁▁▂
##  7   36   ▁▃▇▆▂
##  8   36   ▁▂▇▇▅
##  9   36   ▁▁▅▇▂
## 10   36   ▁▁▅▇▃
## 11   19   ▁▁▃▇▂
## 12 2024   ▇▇▇▅▃
## 13 2025   ▇▇▇▅▃
## 14   16.6 ▇▁▁▁▁
```

