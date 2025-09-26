# Query math courses taken by first time freshmen
# 9.18.2025

# PURPOSE:  Experiment with queries for various goals--
#  Only math courses taken by first time freshmen (ACCOMPLISHED HERE)
#  Top math classes taken by first time freshman (DONE elsewhere)
#  Combined demographics and courses (CURRENTLY merging in R elsewhere)

library(here)

################
## CONNECTION ##
################

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                         Driver = "Oracle in OraClient19Home1", 
                         DBQ = "//ocm-campus01.it.utah.edu:2080/biprodusr.sys.utah.edu",
                         UID = Sys.getenv("userid"),
                         PWD = Sys.getenv("pwd"),
                         Port = 2080)

###########
## QUERY ##
###########

queryStart <- Sys.time()
mathData <- dbGetQuery(con.ds, "
                      SELECT *
FROM OBIA.COMBINED_COURSE_V
WHERE (
        UPPER(DEPARTMENT)   LIKE '%MATH%'
     OR UPPER(TITLE)        LIKE '%MATH%'
     OR UPPER(SUBJECT_LONG) LIKE '%MATH%'
     OR UPPER(SUBJECT)      LIKE '%MATH%'
      )
  AND TERMEXTRACT IN ('E','S')
  AND EMPLID IN (
        SELECT EMPLID
        FROM OBIA.FTF_DEMO_V
      );
                       ")

queryEnd <- Sys.time()
DBI::dbDisconnect(con.ds)


print("Query time:")
print(queryEnd - queryStart)
print("\nData dimension")
print(dim(mathData))

##########
## SAVE ##
##########

saveRDS(mathData, here::here("Data","FTF_math_data.rds"))





