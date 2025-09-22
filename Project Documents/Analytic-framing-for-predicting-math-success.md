---
title: "Analytical Framing for Predicting Math Success"
author: "Bill Prisbrey"
date: "2025-09-22"
output:
  html_document:
    keep_md: true
---



**PURPOSE:**  This document creates the initial analytical framing for investigating math success; its relation to student success metrics as prioritized by academic leadership; and recommending math course placement for incoming first time freshman. This is a living document and may be continuously updated with feedback and new information. 

**PROBLEM STATEMENTS:**  Several possible problem statements have been suggested:   

  * *Can the University of Utah improve various student success metrics with improved math class placement for first time freshman?*    
  * *Can the University of Utah maintain student success metrics with math class placement recommendations in lieu of math placement tests?*    
  * *Can the University of Utah reduce the number of students required to take a math placement test with high confidence placement recommendations?*   
  * *Can the University of Utah improve on the existing [placement and prerequisites guidelines](https://catalog.utah.edu/departments/MATH/overview)?*   
  
  However, until further feedback and revision is received, the following problem statement will be used going forward:    
  
  * *Can the University of Utah optimize math class placement for student success metrics for first time freshmen given limited math class capacity?*    
  
# ANALYTICS PROBLEM RE-FRAMING:

### 1. Decomposition     

The business problem can be broken into two major components, each with distinct modeling considerations and limitations.      

1.1 ***Predict math success.*** Initially, predictors of math success should be well understood.    
1.1.1  *Exploratory data analysis.*  Describe the status quo:  distributions of student features, course enrollments, and outcomes.    
1.1.2  *Logistic regression.* Logistic regression struggles with non-linear relationships and has reduced predictive accuracy but is easier to interpret and explain.   
1.1.3  *Decision trees.* Decision trees can manage non-linear relationships with high accuracy but are more difficult to interpret and explain.   
  
1.2 ***Recommend math course placement.*** Next, causal effects (not just association) should be understood for recommendations or policy changes.      
1.2.1. *Causal inference methods.*  Causal methods estimate the impact of a recommendation or intervention or of an adjustment to policy.        
1.2.2. *Integer programming.*  Once student success metrics are defined, course placement can be optimized for constraints such as the number of seats available, and the cost of teaching assistants, smaller sections, or repeating a course.   

### 2. Data   

2.1 ***Internally available data that will be used:***    
  2.1.1  Descriptions of first time freshman in OBIA.COMBINED_COURSE_V.     
  2.1.2  Course history per student in OBIA.FTF_DEMO_V.   
  2.1.3  Other OBIA tables.    
  2.1.4  Other information about the student available at the time of registering in the Student Data Warehouse.       

2.2 ***Internally available data that might be used:***    
  2.2.1  Student application essays.      
  2.2.2  Student course feedback.    
  2.2.3  Math placement test scores.   
  2.2.4  High school transcripts as available.       

2.3 ***Data that will not be used:***   
  2.3.1  No external data will be used.   
  2.3.2  Complete high school transcripts.  
  2.3.3  Data that is not available at the time of a first time freshman registering for class.      

### 3. Actions and Actors       

Clarification of the business case could help identify actions and actors.    

# DRIVERS AND RELATIONSHIPS:

Possible factors that might influence a first time freshman student's performance in a math course are listed below.  

### STUDENT:        

A formulation is taken from organizational behavior that performance is a function of motivation and ability.  (Additional reading is [here](https://open.lib.umn.edu/organizationalbehavior/part/chapter-5-theories-of-motivation/).)

  - **ABILITY:**    
   - *Math ability.*  Level of math knowledge and skill.      
     -  *Standardized test scores* might indicate math skill.   
     -  *Time since last math course* might indicate math retention.       
     -  *Declared major* might indicate self-assessment at math potential.    
   - *Academic skills.*  Study skills, perseverance, and capacity to manage academic demands.     
     -  *Course load* might indicate time available to focus on math.   
     -  *Concurrent course difficulty* might indicate ability to focus on math. 
     -  *High school GPA* and *AP credits* could indicate the individual level of academic skill.   
     -  *Type of high school.*  Some schools prepare students better.   
  -  *Commute.*  Farther students may have less time to study.     
  -  *Employment.*  More hours at a job means less hours to study.   
  
  - **MOTIVATION:**      
    - *Academic career timing.*  Students with low ability might be more motivated to pass a difficult course closer to graduation.   
    - *Friends in class.* Students with friends in class might have both more opportunities to form study groups and more motivation to do well.   
    - *Relevance to major.*  Motivation may weaken as the connection between the math course and the major weakens.       

### INSTRUCTIONAL:    

  - *Instructor grading policy.*  Different instructors have different grading tendencies.       
  - *Instructor capacity.* An instructor with a heavy teaching load or research load may have less time for individual attention. 
  - *Instructor experience.* More experienced instructors may be better teachers.   
  - *Tutoring.* Both tutor availability, and the student making use of tutoring resources, could affect grades.  
  - *Availability of TA's.*  More teaching assistants could improve grades.   
  - *Availabiltiy of co-requisites.*  Timely assistance in weak areas could improve grades.   
  - *Grading responsiveness.*  Fast response times on assignment and test grades could help the student appropriately prioritize their efforts.   
  
### CLASSROOM:    

  - *Timing.*  Early Monday morning or late Friday afternoon classes may be more difficult.   
  - *Size.* Larger classes might indicate individual attention.      
  - *Modality.* Different course modes may influence grades.   
  - *Class capacity.* A section at near- or over- capacity might reduce the instructors's and TA's capacity for individual attention.     

# ASSUMPTIONS:    

A key assumption is that performance in general education math courses is causal for downstream student success metrics; that is, that improving math outcomes will directly improve student success metrics.  Rather, math performance may be correlated: it may serve as the "canary in the coal mine" that predicts later student success but is not the root cause itself.   

# KEY METRICS OF SUCCESS:   

Needs attention.    

