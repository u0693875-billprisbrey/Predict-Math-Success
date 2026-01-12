# Freshman Skim
# Query and skim OBIA.FTF_DEMO_V

# NOTE FOR PROJECT PREDICTING MATH SUCCESS:
# THIS SCRIPT WAS ORIGINALLY CALLED IN THE PROJECT "UAIR DATA SOURCES DESCRIBED"
# ON OR AROUND 27 AUG 2025.  THIS PROJECT IS CURRENTLY AT 
# BOX >> DOCUMENTS 9.23.2025 >> PROJECTS >> OQUENDO >> UAIR-DATA-SOURCES-DESCRIBED >> QUERY AND SKIM
# THE DATA FILE 'FRESHMAN_DATA.RDS' WAS PORTED TO THIS PROJECT, "PREDICTING MATH SUCCESS". 
# THIS NOTE WAS WRITTEN ON 9 JAN 2026.

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
theData <- dbGetQuery(con.ds, "SELECT * 
                       FROM OBIA.FTF_DEMO_V 
                       ")

# ORDER BY DBMS_RANDOM.VALUE 
# FETCH FIRST 1000 ROWS ONLY

queryEnd <- Sys.time()

print("Query time:")
print(queryEnd - queryStart)
print("\nData dimension")
print(dim(theData))

##########
## SKIM ##
##########

library(skimr)

skimStart <- Sys.time()
freshmanSkim <- skim(theData)
skimEnd <- Sys.time()

print("Skim time:")
print(skimEnd - skimStart)

##########
## SAVE ##
##########

saveRDS(theData, here::here("Data","Freshman_data.rds"))
saveRDS(freshmanSkim, here::here("Query and skim","Freshman_Skim.rds"))
