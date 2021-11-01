source('R/clumps_greater_than_threshold.R')
source('R/clumps_smaller_than_threshold.R')
source('R/select_buffer.R')
source('R/lisamap_tmap_obj.R')
source('R/sripped-table.R')
basegeofispath <- 'https://raw.githubusercontent.com/geofis/'
basegeotelpath <- 'https://raw.githubusercontent.com/maestria-geotel-master/'
devtools::source_url(paste0(
  basegeofispath,
  'zonal-stats-sf/master/zonal-stats-sf.R'))
devtools::source_url(paste0(
  basegeofispath,
  'geomorpho90m-tools/master/estadistica_zonal.R'))
devtools::source_url(paste0(
  basegeofispath,
  'geomorpho90m-tools/master/estadistica_zonal_objetos.R'))
devtools::source_url(paste0(
  basegeofispath,
  'geomorpho90m-tools/master/estadistica_zonal_objetos_contar_cumulos.R'))
devtools::source_url(paste0(
  basegeotelpath,
  'unidad-3-asignacion-1-vecindad-autocorrelacion-espacial/master/lisaclusters.R'))
devtools::source_url('https://raw.githubusercontent.com/r-spatial/stars/master/R/raster.R') #st_as_raster fun
renamecolums <- function(x) {
  str_replace_all(
    x,
    c('min' = 'MIN', 'cuartil_25%' = 'Q1', 'media$' = 'MEAN',
      'mediana' = 'MEDIAN', 'cuartil_75%' = 'Q3', 'max' = 'MAX', 'desv' = 'SD'))
}
# ** If "error in st_upfront(x)..." is not found, run this:
st_upfront = function(x, first = attr(st_dimensions(x), "raster")$dimensions) {
  if (!is.character(first))
    first = names(st_dimensions(x))[first]
  aperm(x, c(first, setdiff(names(st_dimensions(x)), first)))
}
moran_plot_gg <- function(mp, mp_sum, xname = NULL, textsize = 16, facet = T,
                          x_pos_title = -Inf, y_pos_title = Inf, hjust_title = 0, vjust_title = 1) {
  ggplot(mp, aes(x = x, y = wx)) + geom_point(shape=1) +
    geom_smooth(formula=y ~ x, method="lm") +
    geom_hline(data = mp_sum, aes(yintercept = wx), lty=2) +
    geom_vline(data = mp_sum, aes(xintercept = x), lty=2) + theme_minimal() +
    theme(text = element_text(size = textsize), strip.background = element_blank(), strip.text = element_text(colour = 'white')) +
    geom_point(data=mp[mp$is_inf,], aes(x=x, y=wx), shape=9) +
    geom_text(data=mp[mp$is_inf,], aes(x=x, y=wx, label=labels, vjust=1.5)) +
    geom_label(data = mp_sum, aes(x = x_pos_title, y = y_pos_title, label = name, hjust = hjust_title, vjust = vjust_title), size = 7, label.size = 0, fill = 'white', label.padding = unit(0, "lines")) +
    {if(!is.null(xname)) xlab(xname)} +
    {if(facet) facet_wrap(~ name, scales = 'free')} +
    xlab("Observed variable") +
    ylab("Spatially lagged variable")
}
create_year_from_string <- function(x = NULL) {
  library(tidyverse)
  year <- gsub('(.*)(YEAR)([0-9]{,2})(.*)', '\\3', x)
  return(year)
}
create_variable_name_from_string <- function(x = NULL) {
  varname <- gsub('__|^_', '', gsub('YEAR[0-9]{1,}', '', x))
  return(varname)
}
# summarySE, from: https://www.bookstack.cn/read/cookbook-r-en/30cb4cde0f517b2f.md
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
  library(plyr)
  # New version of length which can handle NA's: if na.rm==T, don't count them
  length2 <- function (x, na.rm=FALSE) {
    if (na.rm) sum(!is.na(x))
    else       length(x)
  }
  # This does the summary. For each group's data frame, return a vector with
  # N, mean, and sd
  datac <- ddply(data, groupvars, .drop=.drop,
                 .fun = function(xx, col) {
                   c(N    = length2(xx[[col]], na.rm=na.rm),
                     sum = sum   (xx[[col]], na.rm=na.rm),
                     mean = mean   (xx[[col]], na.rm=na.rm),
                     sd   = sd     (xx[[col]], na.rm=na.rm)
                   )
                 },
                 measurevar
  )
  # Rename the "mean" column    
  datac <- plyr::rename(datac, c("mean" = measurevar))
  datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean
  # Confidence interval multiplier for standard error
  # Calculate t-statistic for confidence interval: 
  # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
  ciMult <- qt(conf.interval/2 + .5, datac$N-1)
  datac$ci <- datac$se * ciMult
  return(datac)
}
crear_tabla_de_mfilter_para_gg <- function(x) {
  df <- data.frame(
    Cycle = as.numeric(x[['cycle']]),
    Series = as.numeric(x[['x']]),
    Trend = as.numeric(x[['trend']]),
    Year = with(x, tsp(cycle)[1]:tsp(cycle)[2]),
    Filter = x[['title']]
  )
  return(df)
}
periodic_summaries <- function(source_table = four_variables_for_plots,
                               measurevar = 'value',
                               bins = 'year',
                               sum_variable = 'variable2',
                               aspect_ratio = 1/3,
                               smooth_method = 'loess',
                               smooth_formula = 'y ~ x',
                               smooth_span = 0.5,
                               smooth_alpha = 0.3,
                               method_args = list(degree = 1),
                               labels_angle = 90,
                               xlab = bins,
                               smooth = T,
                               save = F,
                               plot_filename = NULL,
                               calc_se = T) {
  x_axis_breaks <- unique(source_table[, bins])
  summaries <- summarySE(
    data = source_table,
    measurevar = measurevar, groupvars = c(bins, sum_variable))
  p <- source_table %>%
    ggplot + aes_string(x = bins, y = 'value', group = 1) +
    scale_x_discrete(breaks = x_axis_breaks) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = labels_angle, vjust = 0.5), panel.grid.minor = element_blank(),
          text = element_text(size = 14), aspect.ratio = aspect_ratio) +
    geom_errorbar(data = summaries, aes(ymin = value - se, ymax = value + se), colour = "grey30", width = .3) +
    geom_line(data = summaries) +
    geom_point(data = summaries, aes_string(x = bins, y = 'value'), size=2, shape=21, fill="white") +
    xlab(xlab) +
    facet_wrap(sum_variable, scales = 'free_y', ncol = 1)
  if(smooth)
    p <- p +
    geom_smooth(method = smooth_method, span = smooth_span, formula = smooth_formula, method.args = method_args, alpha = smooth_alpha, size = 0) + 
    stat_smooth(geom = "line", method = smooth_method, span = smooth_span, formula = smooth_formula, method.args = method_args, alpha = smooth_alpha, size = 2, col = 'blue')
  dev.new()
  print(p)
  if(save){
    jpeg(paste0('out/', plot_filename), width = 1800, height = 2700, res = 350)
    print(p)
    dev.off()
  }
  summaries_print <- summaries %>%
    mutate(!!(sum_variable) := case_when(
      !!as.name(sum_variable) == '(C)' ~ 'Avg. number of MODIS M6 fire points per 100 sq. km',
      !!as.name(sum_variable) == '(D)' ~ 'Avg. number of VIRS V1 fire points per 100 sq. km',
      !!as.name(sum_variable) == '(B)' ~ 'Avg. number of forest loss patches $<$1 Ha per 100 sq. km',
      !!as.name(sum_variable) == '(A)' ~ 'Avg. area of forest loss in sq. km per 100 sq. km'
    )) %>%
    {if(calc_se) mutate(., value = paste0(round(value, 2), ' (', round(se, 2), ')')) else .} %>% 
    dplyr::select(all_of(bins), all_of(sum_variable), value) %>%
    {if(calc_se)
      pivot_wider(., names_from = sum_variable, values_from = value, values_fill = '-')
      else pivot_wider(., names_from = sum_variable, values_from = value)}
  summaries_print_latex <- summaries_print %>% kableExtra::kable(format = 'latex')
  return(
    list(
      plot = p,
      summaries_print_latex,
      summaries_print_df = summaries_print
    )
  )
}

# Annual models summary
annual_models_sign_coefs <- function(model) {
  lapply(
    model,
    function(x) 
      summary(x, Nagelkerke = T)$Coef[,4] %>%
      as.data.frame %>%
      rownames_to_column(var = 'variable')) %>% 
    plyr::ldply() %>%
    mutate(
      # .id = 2000+as.numeric(create_year_from_string(.id)),
      .id = as.numeric(create_year_from_string(.id)),
      variable = gsub('(.*)(_YEAR.*)', '\\1', variable)) %>% 
    mutate(sign = .>0.01) %>% 
    select(year = .id, variable, sign) %>% 
    filter(sign) %>% 
    select(-sign) %>% 
    group_by(variable) %>% 
    summarise(years = toString(year))
}

# Small maps for regional models, showing bbox
small_map <- function(source_sf) {
  mr <- c(
    range(st_coordinates(hexzonalfmt)[,1]),
    range(st_coordinates(hexzonalfmt)[,2]))
  ggplot(st_as_sfc(st_bbox(source_sf))) +
    geom_sf(data = hexzonalfmt, fill = 'transparent', color = 'grey80', lwd = 0.2) +
    geom_sf(data = seaocean, fill = 'white') +
    geom_sf(color = 'red', fill = 'transparent') +
    theme(legend.position = "none") +
    labs(caption = NULL) + 
    coord_sf(xlim = mr[c(1:2)], ylim = mr[c(3:4)]) +
    theme(
      plot.title = element_text(hjust = 0.5, vjust = -0.5, size = 12),
      plot.background = element_rect(fill = 'white', color = 'black', size = 0),
      panel.border = element_rect(fill = 'transparent', size = 0.5),
      panel.background = element_rect(fill = 'white', colour = 'black'),
      panel.grid = element_blank(),
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      plot.margin = unit(c(1, 1, 1, 1), "mm"))
}

# Small maps for regional models (showing hexagons)
small_map_hex <- function(source_sf) {
  mr <- c(
    range(st_coordinates(source_sf)[,1]),
    range(st_coordinates(source_sf)[,2]))
  ggplot(source_sf) +
    geom_sf(fill = 'grey75') +
    geom_sf(data = seaocean, fill = 'white') +
    theme(legend.position = "none") +
    labs(caption = NULL) + 
    coord_sf(xlim = mr[c(1:2)], ylim = mr[c(3:4)]) +
    theme(
      plot.title = element_text(hjust = 0.5, vjust = -0.5, size = 12),
      plot.background = element_rect(fill = 'white', color = 'black', size = 0),
      panel.background = element_rect(fill = 'grey90'),
      panel.grid = element_blank(),
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      plot.margin = unit(c(2, 2, 2, 2), "mm"))
}
