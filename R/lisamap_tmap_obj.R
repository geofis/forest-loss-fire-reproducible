lisamap_tmap_obj <- function(objesp = NULL, link = 'ENLACE', var = 'mivariable_pct_log', pesos = NULL) {
  require(tidyverse)
  require(spdep)
  require(sf)
  require(tmap)
  
  # Variable en forma vectorial
  varvectorial <- objesp[var] %>% st_drop_geometry %>% dplyr::select(var) %>% pull
  
  # Moral local
  lomo <- localmoran(varvectorial, listw = pesos)
  
  # Puntuaciones z
  objesp$puntuacionz <- varvectorial %>% scale %>% as.vector
  
  # Crear variable con rezago
  objesp$lagpuntuacionz <- lag.listw(pesos, objesp$puntuacionz)
  
  # Variable nueva sobre significancia de la correlación local, rellena con NAs
  objesp$quad_sig <- NA
  
  # Cuadrante high-high quadrant
  objesp[(objesp$puntuacionz >= 0 & 
            objesp$lagpuntuacionz >= 0) & 
           (lomo[, 5] <= 0.05), "quad_sig"] <- "high-high"
  # Cuadrante low-low
  objesp[(objesp$puntuacionz <= 0 & 
            objesp$lagpuntuacionz <= 0) & 
           (lomo[, 5] <= 0.05), "quad_sig"] <- "low-low"
  # Cuadrante high-low
  objesp[(objesp$puntuacionz >= 0 & 
            objesp$lagpuntuacionz <= 0) & 
           (lomo[, 5] <= 0.05), "quad_sig"] <- "high-low"
  # Cuadrante low-high
  objesp[(objesp$puntuacionz <= 0 
          & objesp$lagpuntuacionz >= 0) & 
           (lomo[, 5] <= 0.05), "quad_sig"] <- "low-high"
  # No significativas
  objesp[(lomo[, 5] > 0.05), "quad_sig"] <- "not signif."  
  
  #Convertir a factorial
  objesp$quad_sig <- as.factor(objesp$quad_sig)
  
  #Objeto espacial
  objesp <- objesp %>% select(all_of(link), !!var := quad_sig)
  return(objesp)
}

