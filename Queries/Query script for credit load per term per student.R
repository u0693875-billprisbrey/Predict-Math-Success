# Query script for credit load per student per term

################
## CONNECTION ##
################

# library(DBI)
#con.ds <- DBI::dbConnect(odbc::odbc(), 
 #                        Driver = "Oracle in OraClient19Home1", 
                         # Host = "ocm-campus01.it.utah.edu", 
                         # SVC = "biprodusr.sys.utah.edu",
  #                       DBQ = "//ocm-campus01.it.utah.edu:2080/biprodusr.sys.utah.edu",
  #                       UID = Sys.getenv("userid"),
  #                       PWD = Sys.getenv("pwd"),
   #                      Port = 2080)

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                        Driver = "Oracle in instantclient_23_0", 
                         Host = "ocm-campus01.it.utah.edu", 
                      SVC = "biprodusr.sys.utah.edu",
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
  ; 
                       ")


# ORDER BY DBMS_RANDOM.VALUE 
# FETCH FIRST 1000000 ROWS ONLY  

queryEnd <- Sys.time()
DBI::dbDisconnect(con.ds)

print("Query time:")
print(queryEnd - queryStart)

saveRDS(creditLoad, here::here("Data","Freshman_career_credit_load.rds"))

library(beepr)
beep(8)

