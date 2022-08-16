# Work in progress to generate pages for each 
# vendor, department, and category automatically.
# Hugo's built-in archetypes functionality includes
# the necessary content.

source("helpers.R")

blogdown::new_post(
  "IBM CANADA", 
  kind = "vendor",
  file = "vendor/ibm_canada.Rmarkdown")

blogdown::new_post(
  "Shared Services Canada | SPC", 
  kind = "department",
  file = "department/sst-spc.Rmarkdown")

blogdown::new_post(
  "Treasury Board", 
  kind = "department",
  file = "department/tbs-sct.Rmarkdown")

blogdown::new_post(
  "3_information_technology", 
  kind = "category",
  file = "category/3_information_technology.Rmarkdown")
