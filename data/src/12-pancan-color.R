
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------

pcc <- readr::read_tsv(file = '/home/liucj/shiny-data/GSCALite/02_pcc.tsv')


pcc %>% 
  dplyr::rename(shortname = cancer_types, fullname = study_name) %>% 
  dplyr::arrange(shortname) ->
  pcc_new

gsca_conf <- readr::read_lines(file = 'data/src/gsca.conf')

collname <- mongolite::mongo(collection = 'pcc', url = gsca_conf)

collname$drop()
collname$insert(data = pcc_new)
collname$index(add = '{"shortname": 1}')
# Save image --------------------------------------------------------------

save.image(file = 'data/rda/12-pancan-color.rda')
