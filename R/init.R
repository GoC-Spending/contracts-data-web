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

rename_vendor_name <- function(df) {
  df %>%
    rename(
      Vendor = d_vendor_name
    )
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
      across(ends_with("total"), ~ str_c("$", format(.x, big.mark=",")))
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


# Department-specific functions ======

get_department_path <- function(department) {
  
  path <- str_c(csv_input_path, "departments/", department, "/")
  return(path)
  
}

dt_vendors_by_fiscal_year_by_department <- function(department) {
  
  path <- str_c(get_department_path(department), "summary_total_by_vendor_and_fiscal_year.csv")
  
  data <- read_csv(path) %>%
    format_totals() %>%
    rename_vendor_name() %>%
    pivot_by_fiscal_year()
  
  data %>%
    datatable(rownames = FALSE, 
              options = list(
                pageLength = 10, 
                autoWidth = TRUE
                ))
  
}