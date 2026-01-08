# courseScatter plotly development sandbox

# original

courseScatter(hiGrades[hiGrades$class_year == 2023,], 
              clusterColumn = "clust1",
              ellipse_params = list(plot = FALSE),
              qrect_params = list(border = NA),
              legend_params = list(plot = FALSE),
              plot_params = list(xlim = c(3.6,4.0), ylim = c(17,36)),
              mtext_params = list(side = c(1,2,3,3),
                                  text = c("High School GPA","ACTMATH","Incoming qualifications of successful students by course", "Median student achieving at least B-"),
                                  font = c(1,1,2,3),
                                  cex = c(1.3, 1.3, 1.75, 1.25),
                                  line = c(2.3, 2.3, 1.25, 0.30)
              )
)

# trouble-shooting plotly

courseScatterPlotly(data = hiGrades[hiGrades$class_year == 2023,],
                    clusterColumn = "clust1",
                    ellipseFilter = 50 # since there are only 21 rows, this suppresses all ellipses
                    )

courseScatterPlotly(data = hiGrades[hiGrades$class_year == 2023,],
                    clusterColumn = "clust1",
                    ellipseFilter = which(hiGrades$course[hiGrades$class_year == 2023] %in% "MATH_1100") 
) # nice!

courseScatterPlotly(data = hiGrades[hiGrades$class_year == 2023,],
                    clusterColumn = "clust1",
                    clusterFilter = 1
                    # ellipseFilter = which(hiGrades$course[hiGrades$class_year == 2023] %in% "MATH_1100") 
)

# clusterFilter colors are off for 3 and 4

courseScatterPlotly(data = hiGrades[hiGrades$class_year == 2023,],
                    clusterColumn = "clust1",
                    clusterFilter = 2,
                    ellipseFilter = which(hiGrades$course[hiGrades$class_year == 2023 & hiGrades$clust1 ==2] %in% "MATH_1100") 
)



courseScatterPlotly(data = hiGrades[hiGrades$class_year == 2023,],
                    showCourse = TRUE ,
                    clusterColumn = "clust1",
                    clusterFilter = 2 #,
                  #  ellipseFilter = which(hiGrades$course[hiGrades$class_year == 2023 & hiGrades$clust1 ==2] %in% "MATH_1100") 
)

# looks like showCourse only adds a legend and replaces the cluster color scheme  

courseScatterPlotly(data = hiGrades[hiGrades$class_year == 2023,],
                    showCourse = TRUE,
                    clusterColumn = "clust1",
                    clusterFilter = 2 ,
                    ellipseFilter = which(hiGrades$course[hiGrades$class_year == 2023 & hiGrades$clust1 ==2] %in% "MATH_1100"),
                    ellipse_npoints = 20
)

