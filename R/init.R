# Loaded by each page in the site

# Test with
# blogdown::serve_site()

# Update with
# blogdown::build_site(build_rmd = 'newfile')
# or
# blogdown::build_site(build_rmd = TRUE)

# TODO: Confirm if more tidyverse libraries are needed
# TODO: Clean up this library section
# see https://towardsdatascience.com/attach-packages-mindfully-in-r-b9c8151b3fb4
library(dplyr, mask.ok = list(base = TRUE, stats = TRUE))
library(tidyr)
library(readr)
library(purrr)
#library(htmltools)
library(stringr)
library(DT)
suppressMessages(library(here))
library(urltools)
suppressMessages(requireNamespace("scales"))
#library(htmlwidgets)
library(lubridate, mask.ok = list(base = TRUE))

# print("Init file loaded")

# Uses here() to handle working directory uncertainties
csv_input_path <- here("../contracts-data/data/out/")


# Pull in frequently-used "meta" data tables
meta_tables <- tibble(entity_type = c("categories", "departments", "vendors"))
meta_tables <- meta_tables %>%
  mutate(
    file_path = str_c(csv_input_path, "meta/", entity_type, ".csv"),
    matching = map(file_path, read_csv)
  )

# Loop through or retrieve vendors, departments, and categories =====

get_meta_list <- function(entity_type) {
  meta_tables %>% 
    filter(entity_type == !!entity_type) %>% 
    pull(matching) %>% 
    first() %>%
    return()
}

# e.g. get_meta_name_by_filepath("departments", "aafc-aac")
# returns "Agriculture and Agri-Food Canada | Agriculture et Agroalimentaire Canada"
get_meta_name_by_filepath <- function(entity_type, filepath) {
  
  meta_table <- get_meta_list(entity_type)
  entry <- meta_table %>%
    filter(filepath == !!filepath) %>%
    pull(name)
  return(entry)
  
}

# e.g. get_meta_filepath_by_name("departments", "Agriculture and Agri-Food Canada | Agriculture et Agroalimentaire Canada")
# returns "aafc-aac"
get_meta_filepath_by_name <- function(entity_type, name) {
  
  meta_table <- get_meta_list(entity_type)
  entry <- meta_table %>%
    filter(name == !!name) %>%
    pull(filepath)
  return(entry)
  
}

# Generally-used helper functions =========

# Thanks to
# https://stackoverflow.com/a/31752708/756641
get_current_filename <- function() {
  current_filename <- knitr::current_input()
  current_filename <- tools::file_path_sans_ext(current_filename)
  return(current_filename)
}

pivot_by_fiscal_year <- function(df, values_from = "total") {
  
  df <- df %>%
    pivot_wider(names_from = d_fiscal_year, values_from = !!values_from)
  
  # Ensure that columns are actually in ascending order
  # (which doesn't always happen, if the first few rows don't
  # have each of the fiscal years)
  cols <- names(df)
  # Skip the very first entry
  first_col <- cols[1]
  cols <- cols[2:length(cols)]
  
  cols <- tibble(cols = cols)
  cols <- cols %>%
    arrange(cols) %>%
    pull(cols)
  
  col_order <- c(first_col, cols)
  
  df <- df %>%
    relocate(any_of(col_order))
  
  df %>%
    return()
  
}

add_first_column_links <- function(df) {
  first_col <- names(df)[1]
  
  if(first_col == "Vendor") {
    add_first_column_links_vendor(df) %>%
      return()
  }
  else if(first_col == "Department") {
    add_first_column_links_department(df) %>%
      return()
  }
  else if(first_col == "Category") {
    add_first_column_links_category(df) %>%
      return()
  }
  else {
    df %>%
      return()
  }

}

# df <- get_fiscal_year_data_by_entity_and_department("tc", "vendors")
add_first_column_links_vendor <- function(df, replace = TRUE) {
  
  meta_vendors <- get_meta_list("vendors")
  df <- df %>%
    left_join(meta_vendors, by = c("Vendor" = "name"))
  df <- df %>%
    mutate(
      href = str_c('<a href="/vendors/', filepath, '/">', Vendor, "</a>")
    )
  
  if(replace == TRUE) {
    df %>%
      mutate(
        Vendor = href
      ) %>%
      select(! c(filepath, href)) %>%
      return()
  }
  else {
    df %>%
      return()
  }
}

# df <- get_fiscal_year_data_by_entity_and_vendor("ibm_canada", "departments")
# Note that for departments, acronyms show up as the primary key
# in the CSV files, which is different from vendors.
add_first_column_links_department <- function(df, replace = TRUE) {
  
  meta_departments <- get_meta_list("departments")
  df <- df %>%
    left_join(meta_departments, by = c("Department" = "filepath"))
  df <- df %>%
    mutate(
      href = str_c('<a href="/departments/', Department, '/">', name, "</a>")
    )
  
  if(replace == TRUE) {
    df %>%
      mutate(
        Department = href
      ) %>%
      select(! c(name, href)) %>%
      return()
  }
  else {
    df %>%
      return()
  }
}

# df <- get_fiscal_year_data_by_entity_and_vendor("ibm_canada", "categories")
# add_first_column_links(df)
add_first_column_links_category <- function(df, replace = TRUE) {
  
  meta_categories <- get_meta_list("categories")
  df <- df %>%
    left_join(meta_categories, by = c("Category" = "filepath"))
  df <- df %>%
    mutate(
      href = str_c('<a href="/categories/', Category, '/">', name, "</a>")
    )
  
  if(replace == TRUE) {
    df %>%
      mutate(
        Category = href
      ) %>%
      select(! c(name, href)) %>%
      return()
  }
  else {
    df %>%
      return()
  }
}


# Small renaming functions ======================

# Thanks to
# https://stackoverflow.com/a/68968141/756641
rename_column_names <- function(df) {
  
  lookup <- c(
    Vendor = "d_vendor_name",
    Category = "d_most_recent_category",
    Department = "owner_org"
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
    exports_round_totals()
  
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
dt_fiscal_year <- function(data, page_length = 10, dom = NULL) {
  
  num_cols <- length(names(data))
  last_col_dt_index <- num_cols - 1L
  fiscal_year_cols_dt <- seq(1, last_col_dt_index)
  fiscal_year_cols <- seq(2, num_cols)
  
  data %>%
    add_first_column_links() %>%
    datatable(rownames = FALSE,
              style = 'bootstrap',
              escape = c(-1),
              options = list(
                order = list(list(last_col_dt_index, 'desc')),
                dom = dom,
                pageLength = page_length, 
                autoWidth = TRUE,
                columnDefs = list(list(width = '16%', targets = as.list(fiscal_year_cols_dt)))
              )) %>%
    formatCurrency(columns = fiscal_year_cols)
}

dt_fiscal_year_categories <- function(data) {
  dt_fiscal_year(data, page_length = 30, dom = 't')
}

# Department-specific functions ======

get_department_path <- function(department) {
  
  path <- str_c(csv_input_path, "departments/", department, "/")
  return(path)
  
}

get_fiscal_year_data_by_entity_and_department <- function(department, entity_type = "vendors") {
  if(entity_type == "vendors") {
    path <- str_c(get_department_path(department), "summary_by_fiscal_year_by_vendor.csv")
  }
  if(entity_type == "categories") {
    path <- str_c(get_department_path(department), "summary_by_fiscal_year_by_category.csv")
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
    dt_fiscal_year_categories()
  
}

# Vendor-specific functions =====================

get_vendor_path <- function(vendor) {
  
  path <- str_c(csv_input_path, "vendors/", vendor, "/")
  return(path)
  
}

get_fiscal_year_data_by_entity_and_vendor <- function(vendor, entity_type = "departments") {
  if(entity_type == "departments") {
    path <- str_c(get_vendor_path(vendor), "summary_by_fiscal_year_by_department.csv")
  }
  if(entity_type == "categories") {
    path <- str_c(get_vendor_path(vendor), "summary_by_fiscal_year_by_category.csv")
  }
  
  data <- read_csv(path) %>%
    format_totals() %>%
    rename_column_names() %>%
    pivot_by_fiscal_year()
  
  return(data)
}

dt_departments_by_fiscal_year_by_vendor <- function(vendor) {
  
  data <- get_fiscal_year_data_by_entity_and_vendor(vendor, "departments")
  data %>%
    dt_fiscal_year()
  
}

dt_categories_by_fiscal_year_by_vendor <- function(vendor) {
  
  data <- get_fiscal_year_data_by_entity_and_vendor(vendor, "categories")
  data %>%
    dt_fiscal_year_categories()
  
}


# Get the original names for a given vendor
get_original_vendor_names <- function(vendor) {
  path <- str_c(get_vendor_path(vendor), "original_vendor_names.csv")
  names <- read_csv(path)
}

display_original_vendor_names <- function(vendor) {
  
  search_prefix <- "https://search.open.canada.ca/en/ct/?sort=contract_value_f%20desc&page=1&search_text="
  names <- get_original_vendor_names(vendor)
  names <- names %>%
    mutate(
      url_encoded_name = url_encode(str_c("\"", original_vendor_name, "\"")),
      markdown_link = str_c("[", original_vendor_name, "](", search_prefix, url_encoded_name, ")")
    )
  
  names %>% pull(markdown_link) %>% str_c(collapse = " \n- ") %>% str_c('- ', .)
}

# Category-specific functions ===================

get_category_path <- function(category) {
  
  path <- str_c(csv_input_path, "categories/", category, "/")
  return(path)
  
}

get_fiscal_year_data_by_entity_and_category <- function(category, entity_type = "departments") {
  if(entity_type == "departments") {
    path <- str_c(get_category_path(category), "summary_by_fiscal_year_by_department.csv")
  }
  if(entity_type == "vendors") {
    path <- str_c(get_category_path(category), "summary_by_fiscal_year_by_vendor.csv")
  }
  
  data <- read_csv(path) %>%
    format_totals() %>%
    rename_column_names() %>%
    pivot_by_fiscal_year()
  
  return(data)
}

dt_departments_by_fiscal_year_by_category <- function(category) {
  
  data <- get_fiscal_year_data_by_entity_and_category(category, "departments")
  data %>%
    dt_fiscal_year()
  
}

dt_vendors_by_fiscal_year_by_category <- function(category) {
  
  data <- get_fiscal_year_data_by_entity_and_category(category, "vendors")
  data %>%
    dt_fiscal_year()
  
}


# Homepage (by criteria) functions ==============

get_summary_overall_path <- function(summary_type) {
  
  path <- str_c(csv_input_path, "overall/", summary_type, "/")
  return(path)
  
}

get_fiscal_year_data_by_entity_and_summary_type <- function(summary_type = "core", entity_type = "departments") {
  if(entity_type == "departments") {
    path <- str_c(get_summary_overall_path(summary_type), "summary_by_fiscal_year_by_department.csv")
  }
  if(entity_type == "vendors") {
    path <- str_c(get_summary_overall_path(summary_type), "summary_by_fiscal_year_by_vendor.csv")
  }
  if(entity_type == "categories") {
    path <- str_c(get_summary_overall_path(summary_type), "summary_by_fiscal_year_by_category.csv")
  }
  
  data <- read_csv(path) %>%
    format_totals() %>%
    rename_column_names() %>%
    pivot_by_fiscal_year()
  
  return(data)
}

dt_fiscal_year_data_by_entity_and_summary_type <- function(summary_type = "core", entity_type = "departments") {
  data <- get_fiscal_year_data_by_entity_and_summary_type(summary_type, entity_type)
  
  if(entity_type == "categories") {
    data %>%
      dt_fiscal_year_categories()
  }
  else {
    data %>%
      dt_fiscal_year()
  }
  
}


# Subtitle stats functions ======================

# Fancy round to millions or billions
fancy_round <- function(number) {
  scales::label_number(accuracy = 0.1, scale_cut = scales::cut_short_scale())(number)
}

# entity_type should be "categories", "vendors", or "departments"
get_name_from_filename <- function(entity_filepath, entity_type) {
  
  meta_entities <- get_meta_list(entity_type)
  
  entity <- meta_entities %>%
    filter(filepath == !!entity_filepath) %>%
    pull(name)
  
  entity
  
}

# entity_type should be "categories", "vendors", "departments", or "overall"
get_most_recent_fiscal_year_item <- function(entity_filepath, entity_type, column = "total") {
  file_path = str_c(csv_input_path, entity_type, "/", entity_filepath,"/summary_by_fiscal_year.csv")
  data <- read_csv(file_path)
  
  data %>%
    arrange(desc(d_fiscal_year)) %>%
    slice_head(n = 1) %>% 
    pull(!!column)
}

get_most_recent_fiscal_year_total <- function(entity_filepath, entity_type, format = TRUE) {
  data <- get_most_recent_fiscal_year_item(entity_filepath, entity_type, "total")
  
  if(format == TRUE) {
    data %>% 
      fancy_round()
  }
  else {
    data
  }
}

get_most_recent_fiscal_year_year <- function(entity_filepath, entity_type) {
  data <- get_most_recent_fiscal_year_item(entity_filepath, entity_type, "d_fiscal_year")
  data
}

# entity_filepath <- "1x1_architecture"
# entity_type <- "vendors"
# get_most_recent_fiscal_year_total(entity_filepath, entity_type)
# get_most_recent_fiscal_year_year(entity_filepath, entity_type)
