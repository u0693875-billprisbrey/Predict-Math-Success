---
title: "Deeper dive into vH3 model"
date: "December 17, 2025"
params: 
  version: "vH3"
  target_classes: 
    - GRADEGPA
output:
  html_document:
    keep_md: true
---

# MODIFY THIS TEXT TO FIT vH3

**PURPOSE:** This report describes a model trained to predict initial math grades for first time freshmen in 2024 based on prior twenty years' of data on variables like ACT math test scores, high school GPA, and high school AP credits.  It includes the distance of the current  It performs with an r-squared value of 0.26.  Various aspects of the model prediction and actual performance are visualized and compared.  

EXECUTIVE SUMMARY

METHODOLOGY

To be copied from elsewhere.  
Importantly, 'W' or "withdraw" is removed from this analysis. 

DISCUSSION  

*ACCURACY*  

Predicting GPA directly performs with an R-squared value of 0.26.  Lumping the grades together into four bins, and predicting these bins, results in an R-squared value of 0.28.  Due to the similarity in performance, and a preference for the increased detail, this report focuses on the model that predicted grades directly.  

As far as distinguishing a binary grouping between "high" and "low", the model had an optimum Kappa of 0.39 at a cut-off value of predicting a GPA of 2.4 or less.  This draws a dividing line between a C+ and a B-, and identified "low" performers with 0.47 precision and 0.67 recall.  These "low" performers [[find out how they actually did, and shouldn't your histogram show that?]]

*PREDICTABLY FAILED*  

The model can identify a few students who were not expected to pass their first math class, and indeed did fail it, with good precision.  Due to their predictable failure, these students might be considered admissions mistakes, or are candidates for having their admissions determination reviewed.  

However, very few students are in this category.  The model predicted only 17 students would score 1.1 or less, and 11 of the students (65% precision) did indeed score 1.1 or less.  (Of the remaining six, one student scored 1.7, one student achieved a 4.0, and the remaining scored between a 2.0 and a 3.0.)  This very low number of students represented a recall metric of only 0.054.

A few conclusions can be drawn from this good-precision/low-recall result:  

  * That math grading practices are not mis-aligned with admissions standards.  (If they were mis-aligned, there would be more students expected to fail and the recall metric would be higher.)  
  * That practically every student admitted in 2024 was reasonably expected to pass a math class.   
  * That variables outside of information available upon admission is predicting or determining or causing math class failures.  This could include things like the number of credits taken, or a "poisonous" combination of difficult classes, or a mid-semester move.  It would be interesting to open up the class information to determine how quickly eventual failures can be identified. For example, to see if the first week's homework results or the first test's grade is highly predictive. 



  

NEXT STEPS

RESULTS 

What this report shows:

- There are a handful of students who predictably failed (with good precision.)  This could suggest: 
  - That these students shouldn't have been admitted and constitute an admissions mistake.  (If we knew they had a high chance of failure, should we have admitted them?)    
  - That the very small number of students in this category suggests that we don't have a large admissions failure.   
  
- An R-squared model of 0.28 is a decently predictive model on very few variables.  It can predict the student's grade with a mean absolute error of 0.84.  So incoming math ability and study ability can explain about 28% of grade variation.    

- However, it still leaves a lot un-explained.  It is not mechanically deterministic and doesn't suggest strong cut-offs.  The histograms compare the ranges of actual vs predicted values.  

- Failure (<1.3) seems to be about a lot more than math ability and study ability (test scores and high school GPA) as students fail despite predicted grades as high as an A.  (What's my metric that says this?)

- The optimum split is 2.7 (B-).  This is where the model performs at its best (least-random) ability to sort students into high and low grades. 

- Unexpectedly, "course" disappears as an explanatory variable. 

  - Maybe this means that the courses are roughly equivalent and course selection doesn't matter. 
  - Maybe this means that some unknown sorting mechanism adequately places students into math courses appropriate to their ability, so that only their studiousness or "study ability" (as indicated by their high school GPA) separates academic performance.  

- The top two predictors of grade are (overwhelmingly) the high school GPA and the ACT math test scores.  

  - A heat map of expected values based on twenty years' of data is very reasonable, with lower grades expected upon moving diagonally to the lower left. 
  
  - Grade inflation?  A lot redder than expected; Way more 'A's than expected.  Looks a lot easier to top off on this scale.  Looking a lot more like a pass-fail.  (Like---what's the number here?  How many did I expect and how many did I get?  It's a simple question of precision I guess.)  
  
    Looking at this: createCM(aligned[["GRADEGPA"]], cuts = c(0,3.3,3.7,4)) |> drawCM()
    
 Look how it "leans" right towards the higher end.  Way more people get >3.7 who are predicted to get <3.7 .
 
 Math looks very, very, very forgiving.  It is graded very generously.
 
Look at how low the precision is for  
createCM(aligned[["GRADEGPA"]], cuts = c(0,3.3,4)) |> drawCM().

They are really pushing grades up here. 

...or is that a correct interpretation?  Does it just mean my model is bad?  Can I manually adjust the prediction and improve the prediction?  If I can, why doesn't the model do it automatically?




  
  
  





And what makes these reports hard to complete 

This report needs some TLC, changes to plot sizes, some words and write-up, and then it needs a comparison with the grade-only prediction (maybe a separate report?).

Possibly develop a <= accuracy metric, a modification of recall, as I don't care how many people got better than a C+ but I care how many people got a C+ or less.

I'll polish up this report a little more before adding that.  















### Models  

<table class="table table-striped table-hover table-condensed" style="color: black; width: auto !important; ">
<caption>Grade Mapping</caption>
 <thead>
  <tr>
   <th style="text-align:left;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> Letter Grade </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> GPA </th>
   <th style="text-align:center;font-weight: bold;background-color: rgba(240, 240, 240, 255) !important;"> Quad </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;font-weight: bold;"> E, EU </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> D- </td>
   <td style="text-align:center;"> 0.7 </td>
   <td style="text-align:center;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> D </td>
   <td style="text-align:center;"> 1.0 </td>
   <td style="text-align:center;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> D+ </td>
   <td style="text-align:center;"> 1.3 </td>
   <td style="text-align:center;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> C- </td>
   <td style="text-align:center;"> 1.7 </td>
   <td style="text-align:center;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> C </td>
   <td style="text-align:center;"> 2.0 </td>
   <td style="text-align:center;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> C+ </td>
   <td style="text-align:center;"> 2.3 </td>
   <td style="text-align:center;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> B- </td>
   <td style="text-align:center;"> 2.7 </td>
   <td style="text-align:center;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> B </td>
   <td style="text-align:center;"> 3.0 </td>
   <td style="text-align:center;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> B+ </td>
   <td style="text-align:center;"> 3.3 </td>
   <td style="text-align:center;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> A- </td>
   <td style="text-align:center;"> 3.7 </td>
   <td style="text-align:center;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> A </td>
   <td style="text-align:center;"> 4.0 </td>
   <td style="text-align:center;"> 3 </td>
  </tr>
</tbody>
</table>



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
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 1.03 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.81 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.26 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.26 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.2 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.9 </td>
   <td style="text-align:center;background-color: rgba(255, 255, 255, 255) !important;"> 0.71 </td>
  </tr>
</tbody>
</table>


![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-8-1.png)<!-- -->



![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-9-1.png)<!-- -->





![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-11-1.png)<!-- -->![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-11-2.png)<!-- -->

I'd like to say what percentage of votes in this <2.7
Basically recall and precision for <1.7 (the dividing line between D+ and C-)


Examining the precision for predictions of grades <1.1 looks like these few people could be an admissions error, or a very low probability of success for this handful of people. 






![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-13-1.png)<!-- -->


![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-14-1.png)<!-- -->![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-14-2.png)<!-- -->


# Variable importance

### Predictors

SPEND SOME MORE TIME TALKING ABOUT THIS.
REMOVE "load" EXPLANATION

course, SEX, FIRST_GEN_STATUS_CD, ETHNICITY, RESSTAT, FA_PELL, APCREDIT, HSGPA, HSPRIVATE, HONORS, ACTCOMP, ACTENGL, ACTMATH, ACTSCI, cohort_year, class_year, yr_diff, season, course_level, age_cut, HSGPA.z, ACTMATH.z, dist. 

"load" is the credit load per student per term. 
"yr_diff" is the time (expressed as fractions of a year) between the cohort date and the end of term date for the course.  

The other variables are either self-explanatory or taken directly from OBIA tables.  


![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-15-1.png)<!-- -->![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-15-2.png)<!-- -->![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-15-3.png)<!-- -->

not a bad series of boxplots.  Def something happening here




![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-16-1.png)<!-- -->



# Confusion matrix




![](Deeper-dive-into-vH3-model_files/figure-html/unnamed-chunk-19-1.png)<!-- -->


# 

# Training data

Presentation order: 



