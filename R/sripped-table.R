stripped_table <- function(src, n = 20, order_col = 2, long_table = F) {
  num_cols <- ncol(src)
  src %>% 
  arrange(desc(.[[order_col]])) %>% 
    st_drop_geometry() %>% 
    slice(1:n) %>% 
    tibble() %>% 
    kbl(format = 'latex', booktabs = TRUE, row.names = T, longtable = long_table) %>% 
    kable_material('striped') %>% 
    {
      if(num_cols>11) {
        kable_styling(kable_input = ., latex_options = c("HOLD_position", "striped", "scale_down", "repeat_header"), stripe_color = 'lightgray')
      } else {
        kable_styling(kable_input = ., latex_options = c("HOLD_position", "striped", "repeat_header"), stripe_color = 'lightgray')
      }
    }
}
