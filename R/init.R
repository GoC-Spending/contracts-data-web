# Loaded by each page in the site

# Test with
# blogdown::serve_site()

# TODO: Confirm if more tidyverse libraries are needed
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(DT)
library(here)

print("Init file loaded")

# Uses here() to handle working directory uncertainties
csv_input_path <- here("../contracts-data/data/out/")

# Generally-used helper functions =========

# Thanks to
# https://stackoverflow.com/a/31752708/756641
get_current_filename <- function() {
  current_filename <- knitr::current_input()
  current_filename <- tools::file_path_sans_ext(current_filename)
  return(current_filename)
}

pivot_by_fiscal_year <- function(df, values_from = "total") {
  
  df %>%
    pivot_wider(names_from = d_fiscal_year, values_from = !!values_from) %>%
    return()
  
}


# Small renaming functions ======================

# Thanks to
# https://stackoverflow.com/a/68968141/756641
rename_column_names <- function(df) {
  
  lookup <- c(
    Vendor = "d_vendor_name",
    Category = "d_most_recent_category"
    )
  
  df %>%
    rename(any_of(lookup))
}

# Rounding and number formatting ================

option_round_totals_digits <- 2
option_round_percentages_digits <- 4

# Rounds any column ending in "total" to 2 decimal places
# Thanks to
# https://dplyr.tidyverse.org/reference/across.html
exports_round_totals <- function(input_df) {
  input_df <- input_df %>%
    mutate(
      across(ends_with("total"), ~ round(.x, digits = !!option_round_totals_digits))
    )
  
  return(input_df)
}

format_totals <- function(input_df) {
  input_df <- input_df %>%
    exports_round_totals() %>%
    mutate(
      across(ends_with("total"), ~ str_c("$", format(round(.x, digits = 2), big.mark=",")))
    )
  
  return(input_df)
}
  
# Rounds any column ending in "percentage" to 4 decimal places
# Note: not sure yet if this is useful
exports_round_percentages <- function(input_df) {
  input_df <- input_df %>%
    mutate(
      across(ends_with("percentage"), ~ round(.x, digits = !!option_round_percentages_digits))
    )
  
  return(input_df)
}

# Outputs a Datatable formatted for fiscal year displays
# with 4 fiscal years
# descending on the 4th year
# TODO: Update this to figure out how many columns there are,
# and sort by the last one (to make it more flexible)
dt_fiscal_year <- function(data, page_length = 10) {
  data %>%
    datatable(rownames = FALSE, 
              options = list(
                order = list(list(4, 'desc')),
                pageLength = page_length, 
                autoWidth = TRUE
              ))
}

# Department-specific functions ======

get_department_path <- function(department) {
  
  path <- str_c(csv_input_path, "departments/", department, "/")
  return(path)
  
}

get_fiscal_year_data_by_entity_and_department <- function(department, entity_type = "vendors") {
  if(entity_type == "vendors") {
    path <- str_c(get_department_path(department), "summary_total_by_vendor_and_fiscal_year.csv")
  }
  if(entity_type == "categories") {
    path <- str_c(get_department_path(department), "summary_total_by_category_and_fiscal_year.csv")
  }
  
  data <- read_csv(path) %>%
    format_totals() %>%
    rename_column_names() %>%
    pivot_by_fiscal_year()
  
  return(data)
}

dt_vendors_by_fiscal_year_by_department <- function(department) {
  
  data <- get_fiscal_year_data_by_entity_and_department(department, "vendors")
  
  data %>%
    dt_fiscal_year()
  
}

dt_categories_by_fiscal_year_by_department <- function(department) {
  
  data <- get_fiscal_year_data_by_entity_and_department(department, "categories")
  
  data %>%
    dt_fiscal_year(page_length = 20)
  
}
