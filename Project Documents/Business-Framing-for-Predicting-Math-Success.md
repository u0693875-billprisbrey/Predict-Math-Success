---
title: "Business Framing for Predicting Math Success"
author: "Bill Prisbrey"
date: "2025-09-16"
output:
  html_document:
    keep_md: true
---



**PURPOSE:**  This document creates the initial business framing for investigating math success; its relation to student success metrics as prioritized by academic leadership; and recommending math course placement for incoming first time freshman. This is a living document and may be continuously updated with feedback and new information. 

**PROBLEM STATEMENTS:**  Several possible problem statements are suggested:   

  * *Can the University of Utah improve various student success metrics with improved math class placement for first time freshman?*    
  * *Can the University of Utah maintain student success metrics with math class placement recommendations in lieu of math placement tests?*    
  * *Can the University of Utah reduce the number of students required to take a math placement test with high confidence placement recommendations?*   
  * *Can the University of Utah improve on the existing [placement and prerequsites guidelines](https://catalog.utah.edu/departments/MATH/overview)?*   

**BACKGROUND:**

The Math Department has requested every student take a math placement test.  Many students feel that this is an onerous burden and the University wishes to reduce it without sacrificing student success metrics.

**HISTORY:**

The University of Utah previously utilized a math placement test called Accu-placer.  It was discontinued upon OBIA's report that available information (such as test scores and high school GPA) could supplant the placement test with acceptable accuracy.   

However, the placement test was merely discontinued without an alternative process for providing a placement recommendation.  This resulted in incoming freshmen "negotiating" their initial math courses without guidelines or much guidance from their academic advisors.  

This is believed to result in poor math class placement, harming various student success metrics.

The Math Department revived the math placement test, requiring all incoming first time freshman to take the test. However, the reach may have been too broad and some students could be reasonably excused from taking the test; reducing University costs and the time burden on students.   

**STAKEHOLDERS:**     

  * *Liz Conder*    
    As the Executive Director of Reporting and Analytics at UAIR, Liz is the sponsor of this project and will take primary responsibility for project direction and communicating results with internal stakeholders. 
    
  * *Dr. Luis Oquendo*  
    As the Academic Reporting Manager, Dr. Oquendo will manage day-to-day activities.       
    
  * *Math Department leadership*     
    Dr. Tommaso de Fernex is the chair of the math department and Dr. Jingyi Zhu is the associate chair responsible for student affairs and scheduling.   
    
  * *Academic leadership*   
  Dr. Mitzi Montoya (Provost and Executive Vice President for Academic Affairs), Dr. Paul Kohn (Senior Vice Provost for Strategic Enrollment and Student Success), and Dr. Chase Hagood (Vice Provost for Student Success) ultimately prioritize student success metrics and approve adjustments to processes.     
  
**COMMUNICATION PLANNING:**

Studies will be provided to Dr. Oquendo, who will coordinate with Liz Conder to direct the development of reports and presentations that will be shared with academic leadership.    

**MANAGEMENT OF NEGATIVE OUTCOMES AND PERSPECTIVES:**   

Management of negative outcomes and perspectives will be conducted by Liz Conder.    

**AMENABILITY TO ANALYTICS:**      
Describing academic outcomes and recommending math placement is amenable to analytics.

Although data and methodologies are available, actionability could be improved with a more detailed business case.     

**Amenability components:**

  * *Data availability*   
    * Coursework and grades dating back to 2005 are available in OBIA.combined_course_v.   
    * Data identifying and describing first time freshman is available in OBIA.ftf_demo_v.     
    * A faculty activity database describing instructors is available in "Elements."   
  
  
  * *Possible data sources*  
    * Math placement test scores    
    * Faculty demographics    
    * Student course feedback     
    * Student application essays    
    * High school transcripts   

    
  * *Methodology selection*   
    Academic outcomes and predictors can be described with decision trees, logistic regression, SHAP values, and possibly with unsupervised clustering.       

  * *Actionability*
  
    * A predictive model could recommend a math placement for all first time freshman.  It would need to be administered according to an ethical framework, which would include requirements for transparency, opting out, and manual over-ride.   
    * Academic advisors could have guidelines when "negotiating" math class placement with first time freshman, including likely grades and probability.  
    * Portions of first-time freshmen could be excused from taking a math placement test according to some kind of accuracy or confidence criteria (for example, if the math placement recommendation aligned with their academic goals and risk tolerance.)   
    
  
**COSTS AND BENEFITS:**   

To be determined.  

Is the goal to reduce the cost of administering math placement tests by excusing some individuals?    

Is the goal related to student success metrics, such as:    

  * Reducing DFWI's in math within the first year   
  * Improving subsequent grade performance    
  * Reducing time-to-graduate by placing students in more challenging courses       

Is the goal related to class and teacher capacity by reducing the number of students in certain classes with a more optimized distribution?        

**RISKS:**    

An analysis of historical data carries the inherent assumption that the future will continue as the past.  The recent past has had a large discontinuity in the form of disruptions caused by COVID that [some observers](https://www.tandfonline.com/doi/full/10.1080/2331186X.2024.2383046?utm_source=chatgpt.com) claim to still be altering academic performance. 

It is also possible that this analysis could suggest methods to improve student success outcomes that the University does not wish to act on or adopt, such as implementing a machine learning recommendation that uses many variables.    

**NEXT STEPS:**   

- **Improved clarity on the history of math placement.**  Because historical data will be analyzed, it will be useful to know when math placement practices changed and if they correspond to changes in student success outcomes.   

- **Improved clarity on the business case.**  Any adjustment to a system may come with trade-offs; one metric may sink in order for another to rise.  Better understanding of the math department's pain points and academic leadership's objectives could help steer the analyses to address these concerns directly and better accommodate trade-offs.   



