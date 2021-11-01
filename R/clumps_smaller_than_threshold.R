clumpssmaller <- function(src, threshold = 10000) {
  cl <- clump(src)
  clthre <- data.frame(freq(cl))
  clthre <- clthre[clthre$count > ceiling(threshold/prod(res(src))), ]
  clthre <- as.vector(clthre$value)
  cl[cl %in% clthre] <- NA
  cl[cl>=1] <- 1
  return(cl)
}
