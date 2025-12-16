# guide sandbox


actDetail <- aggregate(ACTMATH ~ course, data = cleanData[cleanData$class_year == 2023 & cleanData$GRADEGPA > 2.4, ], function(x){c(quantile(x,probs = c(0.1,0.25,0.5,0.75,0.9), na.rm=TRUE),count = length(x))}) |>
  (\(x){
    do.call(data.frame,x)
  })() 

hsDetail <- aggregate(HSGPA ~ course, data = cleanData[cleanData$class_year == 2023 & cleanData$GRADEGPA > 2.4, ], function(x){c(quantile(x,probs = c(0.1,0.25,0.5,0.75,0.9), na.rm=TRUE ), count = length(x))}) |>
  (\(x){
    do.call(data.frame,x)
  })()


hiGrades22 <- aggregate(cbind(HSGPA,ACTMATH) ~ course + class_year, 
                      data = cleanData[cleanData$GRADEGPA > 2.4,], function(x){
                        c(median = median(x),
                          IQR = IQR(x),
                          stdev = sd(x),
                          Q = quantile(x, probs = c(0.1,0.25,0.5,0.75,0.9), na.rm = TRUE),
                          count = length(x)
                        ) 
                      }) |>
  (\(x){
    do.call(data.frame,x)
  })()


lowGrades <- aggregate(cbind(HSGPA,ACTMATH) ~ course + class_year, 
                       data = cleanData[cleanData$GRADEGPA <= 2.4,], function(x){
                         c(median = median(x),
                           IQR = IQR(x),
                           stdev = sd(x),
                           Q = quantile(x, probs = c(0.1,0.25,0.5,0.75,0.9), na.rm = TRUE),
                           count = length(x)
                         ) 
                       }) |>
  (\(x){
    do.call(data.frame,x)
  })()



hiGrades22$clust1 <- hiGrades22 |>
  (\(x){ x[,colnames(x)[grepl("ACTMATH\\.Q\\.", colnames(x))]]  })() |>
  dist(method ="euclidean") |>
  hclust(method = "ward.D2")  |>
  #vplot()
  cutree(k=4)


