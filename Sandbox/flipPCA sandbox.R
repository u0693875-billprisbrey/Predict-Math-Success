# flipPCA sandbox

# I decided not to use this, as the distance is my predictor and not the dimension coordinates

flipPCA <- function(pca_obj, vars_to_check = c("HSGPA", "ACTMATH")) {
  loadings <- pca_obj$var$coord
  
  for (i in seq_len(ncol(loadings))) {
    loading_sum <- sum(loadings[vars_to_check, i])
    
    if (loading_sum < 0) {
      pca_obj$var$coord[, i] <- -pca_obj$var$coord[, i]
      pca_obj$var$cor[, i] <- -pca_obj$var$cor[, i]
      pca_obj$ind$coord[, i] <- -pca_obj$ind$coord[, i]
      
      # flip centroids 
      if (!is.null(pca_obj$quali.sup)) {
        pca_obj$quali.sup$coord[, i] <- -pca_obj$quali.sup$coord[, i]
      }
    }
  }
  
  return(pca_obj)
}