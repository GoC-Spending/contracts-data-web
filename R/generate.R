# Work in progress to generate pages for each 
# vendor, department, and category automatically.
# Hugo's built-in archetypes functionality includes
# the necessary content.

source("R/init.R")


# After running each of 
# generate_all_category_pages() etc.
# or
# generate_all_pages()
# then run
# blogdown::build_site(build_rmd = TRUE)
# or
# blogdown::build_site(build_rmd = 'newfile')

# Example manual generator runs

# blogdown::new_post(
#   "IBM CANADA", 
#   kind = "vendor",
#   file = "vendor/ibm_canada.Rmarkdown")
# 
# blogdown::new_post(
#   "Shared Services Canada | SPC", 
#   kind = "department",
#   file = "department/sst-spc.Rmarkdown")
# 
# blogdown::new_post(
#   "Treasury Board", 
#   kind = "department",
#   file = "department/tbs-sct.Rmarkdown")
# 
# blogdown::new_post(
#   "3_information_technology", 
#   kind = "category",
#   file = "category/3_information_technology.Rmarkdown")

# Generate vendor pages =========================

generate_vendor_page <- function(name, filepath) {
  blogdown::new_post(
    name,
    kind = "vendor",
    file = str_c("vendor/", filepath, ".Rmarkdown"),
    open = FALSE)
}

generate_all_vendor_pages <- function() {
  vendors <- get_meta_list("vendors")
  names <- vendors %>% 
    pull("name")
  filepaths <- vendors %>% 
    pull("filepath")
  map2(names, filepaths, generate_vendor_page)
}

# Generate department pages =====================

generate_department_page <- function(name, filepath) {
  blogdown::new_post(
    name,
    kind = "department",
    file = str_c("department/", filepath, ".Rmarkdown"),
    open = FALSE)
}

generate_all_department_pages <- function() {
  departments <- get_meta_list("departments")
  names <- departments %>% 
    pull("name")
  filepaths <- departments %>% 
    pull("filepath")
  map2(names, filepaths, generate_department_page)
}


# Generate category pages =======================

generate_category_page <- function(name, filepath) {
  blogdown::new_post(
    name,
    kind = "category",
    file = str_c("category/", filepath, ".Rmarkdown"),
    open = FALSE)
}

generate_all_category_pages <- function() {
  categories <- get_meta_list("categories")
  names <- categories %>% 
    pull("name")
  filepaths <- categories %>% 
    pull("filepath")
  map2(names, filepaths, generate_category_page)
}


# Regenerate all the things!! ==================

generate_all_pages <- function() {
  # Start time
  run_start_time <- now()
  paste("Start time:", run_start_time)
  
  generate_all_category_pages()
  generate_all_department_pages()
  generate_all_vendor_pages()
  
  run_end_time <- now()
  paste("Start time was:", run_start_time)
  paste("End time was:", run_end_time)
  
}
