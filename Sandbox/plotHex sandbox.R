library(ggplot2)
library(patchwork)

plotHex <- function(data, title = NA){

  # Ideally data represents a single course
  
  # Check for required packages
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required but not installed.")
  }
  if(!requireNamespace("patchwork", quietly = TRUE)) {
    stop("Package 'patchwork' is required but not installed.")
  }
 
  df <- data[,c("HSGPA","ACTMATH","GRADEGPA")] 
  
# Create a simple dataframe
# df <- data.frame(HSGPA = HSGPA, 
#                 ACTMATH = ACTMATH, 
#                 GRADEGPA = GRADEGPA)

# Establish title
  
  if(is.na(title)){ 
    if(length(unique(data$course)) <= 5) {
      
      title <- paste(unique(data$course), collapse = ", ")
      
    } else {title <- "Multiple courses"}
    
    }


# Plot 1: Median GRADEGPA
p1 <- ggplot(df, aes(x = HSGPA, y = ACTMATH, z = GRADEGPA)) +
  stat_summary_hex(fun = median, bins = 30) +
  scale_fill_gradientn(colors = c("darkblue", "cyan", "yellow", "red"),
                       name = "Median\nGRADEGPA") +
  theme_minimal() +
  labs(
       x = "HSGPA", 
       y = "ACTMATH")

# Plot 2: Counts per cell
p2 <- ggplot(df, aes(x = HSGPA, y = ACTMATH)) +
  geom_hex(bins = 30) +
  scale_fill_gradientn(colors = c("lightblue", "yellow", "orange", "red"),
                       name = "Count") +
  theme_minimal() +
  labs(
       x = "HSGPA", 
       y = "ACTMATH")

# Display both plots side by side
(p1 + p2) + 
  plot_annotation(title = title,
                  theme = theme(plot.title = element_text(hjust = 0.5, size = 14)))
}

