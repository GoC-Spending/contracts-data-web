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
# build_all_pages()
# which also updates the build log YAML file.

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

# Logging helpers (adapted from the main analysis repository) ====

build_run_log <- tibble_row(
  time = as.character(now()), 
  name = "load_helper_scripts", 
  value = as.character("")
)

add_log_entry <- function(name, value = "") {
  input <- tibble_row(
    time = as.character(now()), 
    name = as.character(name), 
    value = as.character(value)
  )
  
  # Thanks to
  # https://stackoverflow.com/a/32759849/756641
  build_run_log <<- build_run_log %>%
    bind_rows(input)
  
  input
}

update_build_log_yaml <- function() {
  # Uses a global variable for build_run_log_yaml_output_path
  # set in init.R
  build_run_log <- build_run_log %>%
    filter(!is.na(value)) %>%
    filter(value != "") %>%
    select(name, value)
  
  write_log_to_yaml(build_run_log, build_run_log_yaml_output_path)
}



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


# If needed, delete the existing dynamically-generated
# content pages.
remove_existing_content_folders <- function() {

  content_folder <- here("content/")
  
  
  output_department_path <- str_c(content_folder, "department")
  output_category_path <- str_c(content_folder, "category")
  
  remove_existing_vendor_folders()
  
  if(fs::dir_exists(output_department_path)) {
    fs::dir_delete(output_department_path)
  }
  if(fs::dir_exists(output_category_path)) {
    fs::dir_delete(output_category_path)
  }

}

# At this point, usually just need to regenerate the vendor folders
remove_existing_vendor_folders <- function() {
  
  content_folder <- here("content/")
  output_vendor_path <- str_c(content_folder, "vendor")
  if(fs::dir_exists(output_vendor_path)) {
    fs::dir_delete(output_vendor_path)
  }
  
}

# Regenerate all the things!! ==================

# Currently takes about 3 minutes
# Note: if existing content folders are removed, then the
# "serve site" function will regenerate all missing .markdown files
# which is equivalent to the build_all_pages() function below.
generate_all_pages <- function(remove_all_existing_folders = FALSE, remove_vendor_folders = FALSE) {
  # Start time
  run_start_time <- now()
  print(str_c("Start time: ", run_start_time))
  
  if(remove_all_existing_folders) {
    print("Heads-up: Removing all existing folders!")
    remove_existing_content_folders()
  } else if(remove_vendor_folders) {
    print("Heads-up: Removing existing vendor folders!")
    remove_existing_vendor_folders()
  }
  
  generate_all_category_pages()
  generate_all_department_pages()
  generate_all_vendor_pages()
  
  run_end_time <- now()
  print(str_c("Start time was: ", run_start_time))
  print(str_c("End time was: ", run_end_time))
  
}

# Currently takes about 55 minutes
build_all_pages <- function() {
  run_start_time <- now()
  print(str_c("Start time: ", run_start_time))
  add_log_entry("start_time", run_start_time)
  add_log_entry("build_date", today())
  
  # Update the parse run log YAML file just in case it's been a while.
  update_run_yaml()
  
  blogdown::build_site(build_rmd = TRUE)
  
  run_end_time <- now()
  print(str_c("Start time was: ", run_start_time))
  print(str_c("End time was: ", run_end_time))
  add_log_entry("end_time", run_end_time)
  add_log_entry("build_duration_hours", round(time_length(interval(run_start_time, run_end_time), "hours"), digits = 2))
  
  # Write the log to a YAML file
  update_build_log_yaml()
}


# Do everything!
generate_and_build <- function() {
  generate_all_pages(TRUE)
  build_all_pages()
}
