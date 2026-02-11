---
title: "Predictors over time"
author: "Bill Prisbrey"
date: "2026-02-11"
output:
  html_document:
    keep_md: true
    toc: true
---










# Executive Summary

### **PURPOSE:**  *This report examines predictors of math course selection and academic performance over time.*  

### **EXECUTIVE SUMMARY:**  *This report finds that math grades awarded have increased; that ACT math test scores has drastically decreased; and that the mix of courses selected has changed.  The students who submit test scores are increasingly elite, with better high school GPA's, test scores, and grade performance in initial math courses.  It also finds that courses and grades are consistently mildly distinguished by high school GPA and ACT math test scores over time; and that transforming these qualifications into z-scores per course improves stability.*

# Discussion  

This report finds many changes over time.  Most notably, grades have increased; test score submission rates have decreased;  and the mix of courses selected has changed. 

***Grades have increased.***  This report finds that the proportion of students earning an 4.0 ("A") has steadily increased from ~20% to ~30% since 2005.  Conversely, the proportion of students achieving a 2.3 ("C+") or worse has declined from ~40% to ~30% in the same time span.  

***Test score submission rates have decreased.***  This report finds that a decreasing number of students submit ACT test scores.  Only one-third of students in high volume courses submitted math test scores in 2024, compared to about 90% submission until 2016.  These students are increasingly elite, with better high school GPA's, test scores, and grade performance in initial math courses.

***Mix of courses selected has changed.***  This report finds that overall enrollment has steadily increased, and that enrollment has increased more in high volume courses (1010, 1050, 1210, 1030, and 1090.)  Among these, Math 1010 and Math 1090 have shifted positions as highest and lowest enrolled classes.  Where Math 1010 used to be the highest enrolled course by a large margin, it is now the lowest enrolled course by a large margin. 

Awarded grades are also higher in the low-volume courses than the high volume courses, with a median grade of 3.7 in the low-volume courses compared to 3.0 for the high-volume courses in 2024.  It is also observed that Math 1090 had a rising median course GPA since 2015, peaking with a median grade of 4.0 in 2020.  The median grade for 1090 has since fallen to be more in alignment with the other high volume courses in 2024.

**Courses and grades are at least mildly distinguished by ACT math test scores and high school GPA.**  Low-volume classes have higher test scores and high school GPA.  Among the high volume classes, Math 1010 has students with the lowest median test scores and high school GPA, and Math 1210 has the highest.

Transforming these incoming qualifications of ACT math test scores and high school GPA into z-scores introduces stability.  The median z-scores and combined distance for on track students is mostly stable.  The median z-scores and combined distance for at risk students shows a strong trend in the last few years, however, particularly in the combined distance for the median at risk student.  This aligns with the the grade compression already noted.  (Here, "on track" is defined as achieving a grade of 2.7 ("B-") or better, and "at risk" is defined as achieving a grade of 2.3 ("C+") or worse.  This cut-off was identified as the optimum in the predictive model described in the accompanying report.)
  
# Enrollment  

### *Courses are separated into high volume or low volume courses.  Courses with less than five percent of the cumulative enrollment are combined together as 'other'.* 


Five math courses have distinctly high enrollment.  These courses are categorized together as "high volume" and designated as "hi_vol" in legends in this course.  These courses are Math 1010, 1050, 1210, 1030, and 1090.  

An additional nine courses are categorized as "low volume."  They are Math 1070, 1220, 1080, 1060, 1310, 2210, 990, 1100, and 1250.

Many small courses that consist of less than 5% of the total enrollment combined are lumped together as "other."



![](Predictors-over-time_files/figure-html/unnamed-chunk-4-1.png)<!-- -->









### *Although enrollment has steadily increased over time, the course mixture has changed as Math 1010 has declined to be replaced by Math 1090.* 

![](Predictors-over-time_files/figure-html/unnamed-chunk-7-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-7-2.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-7-3.png)<!-- -->

# Grade distribution over time

### *The proportion of students receiving an 'A' has increased.*  

![](Predictors-over-time_files/figure-html/unnamed-chunk-8-1.png)<!-- -->

![](Predictors-over-time_files/figure-html/unnamed-chunk-9-1.png)<!-- -->



# ACT test scores
### *Submission of ACT test scores has steeply declined, especially for high volume courses.  Only a third of students in some courses (like Math 1090) have submitted ACT test scores.*


![](Predictors-over-time_files/figure-html/unnamed-chunk-10-1.png)<!-- -->



![](Predictors-over-time_files/figure-html/unnamed-chunk-11-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-11-2.png)<!-- -->












### *Students who submit test scores are a self-selected elite, with better high school GPAs and more AP credits, a rising median ACT score, and consequent better math performance.*   

![](Predictors-over-time_files/figure-html/unnamed-chunk-16-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-16-2.png)<!-- -->

On average, test submitters' high school GPA is 0.26 higher than non-test submitters. 

![](Predictors-over-time_files/figure-html/unnamed-chunk-17-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-17-2.png)<!-- -->

Test score submitters' median AP credit was three credits higher than non-test submitters' median.


![](Predictors-over-time_files/figure-html/unnamed-chunk-18-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-18-2.png)<!-- -->

![](Predictors-over-time_files/figure-html/unnamed-chunk-19-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-19-2.png)<!-- -->

Math grades have diverged until test score submitters have a median math grade 0.7 points higher than non-submitters in 2024 (3.7 compared to 3.0.) 




###  *Courses are distinguished by ACT math scores with heavy overlap.*

![](Predictors-over-time_files/figure-html/unnamed-chunk-21-1.png)<!-- -->

![](Predictors-over-time_files/figure-html/unnamed-chunk-22-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-22-2.png)<!-- -->




# High school GPA
### *Median high school GPA has increased over the years, with the courses mildly distinguished by high school GPA with heavy overlap.* 

![](Predictors-over-time_files/figure-html/unnamed-chunk-24-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-24-2.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-24-3.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-24-4.png)<!-- -->


![](Predictors-over-time_files/figure-html/unnamed-chunk-25-1.png)<!-- -->



# Math grades 
### *The median math grade fluctuates over time without a clear trend, while above-median grades shift higher:  the 70th percentile shifts from a B+ to an A in 2016.*  

![](Predictors-over-time_files/figure-html/unnamed-chunk-26-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-26-2.png)<!-- -->

### *Low-volume classes have maintained a higher median GPA than high-volume classes, and seem to have recently stabilized at their twenty-year high.* 

![](Predictors-over-time_files/figure-html/unnamed-chunk-27-1.png)<!-- -->


![](Predictors-over-time_files/figure-html/unnamed-chunk-28-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-28-2.png)<!-- -->

Math 1090 peaked with a median grade of 4.0 in 2020.
 
### *Courses are not distinguished by grade distribution.*   


![](Predictors-over-time_files/figure-html/unnamed-chunk-29-1.png)<!-- -->




# Z-scores

### *Successfully on track students are closer to the prior year's median successful student.*  




![](Predictors-over-time_files/figure-html/unnamed-chunk-31-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-31-2.png)<!-- -->




![](Predictors-over-time_files/figure-html/unnamed-chunk-32-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-32-2.png)<!-- -->



![](Predictors-over-time_files/figure-html/unnamed-chunk-33-1.png)<!-- -->![](Predictors-over-time_files/figure-html/unnamed-chunk-33-2.png)<!-- -->





# Additional comparison graphics  

![](Predictors-over-time_files/figure-html/unnamed-chunk-34-1.png)<!-- -->




![](Predictors-over-time_files/figure-html/unnamed-chunk-35-1.png)<!-- -->

![](Predictors-over-time_files/figure-html/unnamed-chunk-36-1.png)<!-- -->

![](Predictors-over-time_files/figure-html/unnamed-chunk-37-1.png)<!-- -->

