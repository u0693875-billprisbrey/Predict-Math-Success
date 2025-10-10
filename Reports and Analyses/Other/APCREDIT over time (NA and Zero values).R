# APCREDIT OVER TIME
# 10.09.2025

# PURPOSE:  How should I treat AP Credit values of NA? Should I convert them to zero?  
# This looks at APCREDIT values over time.

# CONCLUSION: 
# This brief investigation shows that before 2015 there were no NA values-- only zero values
# or values greater than zero.  After 2016, though, there are no zero values and only NA values
# or values greater than zero.

# This suggests converting NA values to zero.

# However, this does not distinguish between high schools that do or don't
# offer AP credits.  Seems like an 'NA' value should exist as "not an option."

##########
## LOAD ##
##########

ftfData <- readRDS(here::here("Data", "Freshman_data.rds"))

ap_by_term <- aggregate(APCREDIT ~ COHORTTERM, data = ftfData, 
                   na.action = na.pass,
                   function(x) {c(
  na.val = sum(is.na(x)),
  zero.val = length(x[!is.na(x) & x == 0]),
  gr.zero = length(x[!is.na(x) & x > 0])
  ) 
  })

ap_by_term <- cbind(ap_by_term[1], as.data.frame(ap_by_term[[2]]))

ap_by_term$total <- rowSums(ap_by_term[,2:4])

# As Whitney described, it switches from values of zero to
# values of NA from 2015 to 2016.  

# Is there no distinguishing high schools that don't offer AP credit?

# It might have been nice to drop this into an e-mail,
# but I'm not adding any information.

par(mar=c(5.5,4.5, 3.5, 6 ))

plot(y=rep(1, nrow(ap_by_term)) ,
     ylim = range(ap_by_term[,2:4]),
     x = ap_by_term$COHORTTERM,
     ylab = "Count of students",
     xlab = "Cohort term",
     las = 2,
     main = "AP credits over time",
     type = "n"
)

lines(y = ap_by_term$na.val,
     x = ap_by_term$COHORTTERM,
     type = "l",
     col = "darkorange2")

lines(
  y = ap_by_term$zero.val,
  x = ap_by_term$COHORTTERM,
  type = "l",
  col = "deepskyblue2"
)

lines(
  y = ap_by_term$gr.zero,
  x = ap_by_term$COHORTTERM,
  type = "l",
  col = "seagreen3"
)

legend("topright",
       legend = c("NA", "Zero", ">0"),
       inset = c(-0.35, 0),
       lty =1,
       lwd = 3,
       col = c("darkorange2", "deepskyblue2", "seagreen3"),
       xpd = TRUE
       )


library(kableExtra)
ap_by_term |>
  kbl(caption = "Count of students with APCREDIT values by Cohort Term", booktabs = TRUE) |>
  kable_styling(full_width = FALSE, position = "center", font_size = 12) |>
  row_spec(0, bold = TRUE) |>      # make header bold
  kable_paper("hover", full_width = FALSE)



# > ap_by_term
# COHORTTERM na.val zero.val gr.zero total
# 1        1058      0     2102     719  2821
# 2        1068      0     2089     749  2838
# 3        1078      0     1982     761  2743
# 4        1088      0     2027     615  2642
# 5        1098      0     2182     685  2867
# 6        1108      0     2406     704  3110
# 7        1118      0     2385     883  3268
# 8        1128      0     2602     892  3494
# 9        1138      0     1967    1157  3124
# 10       1148      0     1847    1304  3151
# 11       1158      0     1939    1471  3410
# 12       1168   2034        0    1567  3601
# 13       1178   2329        0    1790  4119
# 14       1188   2430        0    1826  4256
# 15       1198   2333        0    1916  4249
# 16       1208   2638        0    1845  4483
# 17       1218   3539        0    1822  5361
# 18       1228   3499        0    2021  5520
# 19       1238   3362        0    2198  5560
# 20       1248   3534        0    2467  6001