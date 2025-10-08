# Course load per term sandbox

# The purpose of this sandbox is to calculate the number of credits
# per term per student.

# I developed a pretty straight-forward query that I'll run as a background job

##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))
mathCourses <- readRDS(here::here("Data", "FTF_math_data.rds"))

# should be an aggregate of "credit" by term + EMPLID 
# I'm going to need all courses 

# I'm going to need all of their courses, not just math course
# I think I'll figure it out with math, and then convert it to SQL

creditLoad <- aggregate(UNITS ~ TERM + EMPLID, data = mathCourses, sum, na.rm=TRUE)

SELECT
TERM,
EMPLID,
SUM(UNITS) AS UNITS
FROM
mathCourses
GROUP BY
TERM,
EMPLID;


################
## CONNECTION ##
################

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                         Driver = "Oracle in OraClient19Home1", 
                         # Host = "ocm-campus01.it.utah.edu", 
                         # SVC = "biprodusr.sys.utah.edu",
                         DBQ = "//ocm-campus01.it.utah.edu:2080/biprodusr.sys.utah.edu",
                         UID = Sys.getenv("userid"),
                         PWD = Sys.getenv("pwd"),
                         Port = 2080)

###########
## QUERY ##
###########

queryStart <- Sys.time()
creditLoad <- dbGetQuery(con.ds, "
SELECT
  TERM,
  EMPLID,
  SUM(UNITS) AS UNITS
FROM
  OBIA.COMBINED_COURSE_V
WHERE 
  TERMEXTRACT IN ('E','S')
  AND EMPLID IN (
        SELECT EMPLID
        FROM OBIA.FTF_DEMO_V
      )
GROUP BY
  TERM,
  EMPLID
ORDER BY DBMS_RANDOM.VALUE 
  FETCH FIRST 10000 ROWS ONLY
                       ; 
                       ")

queryEnd <- Sys.time()
DBI::dbDisconnect(con.ds)

print("Query time:")
print(queryEnd - queryStart)

# this is going pretty quickly
# I'm tempted to run the whole thing---how many rows again? 1.7 M?

dbGetQuery(con.ds, "
SELECT COUNT(EMPLID) FROM OBIA.COMBINED_COURSE_V;
           ")

# 12544021

# 12 M
# Wow

# well, let's get to it, I guess!