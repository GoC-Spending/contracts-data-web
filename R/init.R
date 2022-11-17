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
library(tibble)
suppressMessages(requireNamespace("fs"))
library(htmltools)
library(stringr)
library(DT)
suppressMessages(library(here))
library(urltools)
suppressMessages(requireNamespace("scales"))
#library(htmlwidgets)
library(lubridate, mask.ok = list(base = TRUE))
library(yaml)

# print("Init file loaded")

# Uses here() to handle working directory uncertainties
csv_input_path <- here("../contracts-data/data/out/")
parse_run_log_yaml_output_path <- here("data/parse_run_log.yaml")
build_run_log_yaml_output_path <- here("data/build_run_log.yaml")

it_subcategory_display_amount_threshold <- 10000000
it_subcategory_display_percentage_threshold <- 0.4

# Pull in frequently-used "meta" data tables
meta_tables <- tibble(entity_type = c("categories", "departments", "vendors"))
meta_tables <- meta_tables %>%
  mutate(
    file_path = str_c(csv_input_path, "meta/", entity_type, ".csv"),
    matching = map(file_path, read_csv)
  )

category_labels <- read_csv(str_c(csv_input_path, "../categories/category_labels.csv"))

it_subcategory_labels <- read_csv(str_c(csv_input_path, "../categories/it_subcategory_labels.csv"))

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
get_meta_name_by_filepath <- function(entity_type, filepath, output_column = "name") {
  
  meta_table <- get_meta_list(entity_type)
  entry <- meta_table %>%
    filter(filepath == !!filepath) %>%
    pull(output_column)
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

# More advanced labels for categories and vendors ======

get_category_label_by_category <- function(original_category, output_column = "category_path") {
  
  category_labels %>%
    filter(original_category == !!original_category) %>%
    pull(output_column)
  
}

get_category_label_by_path <- function(category_path, output_column = "original_category") {
  
  category_labels %>%
    filter(category_path == !!category_path) %>%
    pull(output_column)
  
}

get_it_subcategory_label_by_path <- function(original_it_subcategory) {
  
  it_subcategory_labels %>%
    filter(original_it_subcategory == !!original_it_subcategory) %>%
    pull(it_subcategory_name)
  
}

# Generally-used helper functions =========

# Thanks to
# https://stackoverflow.com/a/31752708/756641
get_current_filename <- function() {
  current_filename <- knitr::current_input()
  current_filename <- tools::file_path_sans_ext(current_filename)
  return(current_filename)
}

pivot_by_fiscal_year <- function(df, values_from = "total", num_of_years = 4) {
  
  # Before pivoting, limit to the requested number of (most recent) years.
  years_to_include <- df %>%
    select(d_fiscal_year) %>%
    distinct() %>%
    arrange(d_fiscal_year) %>%
    slice_tail(n = num_of_years) %>%
    pull(d_fiscal_year)
  
  # Remove earlier entries from the input data
  df <- df %>%
    filter(d_fiscal_year %in% years_to_include)
  
  # Remove inflation-adjusted columns, e.g. total_constant_2019_dollars
  df <- df %>%
    select(! ends_with("_dollars"))
  
  # Pivot!
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
  else if(first_col == "IT subcategory") {
    add_first_column_links_it_subcategory(df) %>%
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
      href = str_c('<a href="/vendors/', filepath, '/">', display_label, "</a>")
    )
  
  if(replace == TRUE) {
    df %>%
      mutate(
        Vendor = href
      ) %>%
      select(! c(filepath, display_label, href)) %>%
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
  
  # meta_categories <- get_meta_list("categories")
  df <- df %>%
    left_join(category_labels, by = c("Category" = "original_category"))
  df <- df %>%
    mutate(
      href = str_c('<a href="/categories/', category_path, '/">', category_name, "</a>")
    )
  
  if(replace == TRUE) {
    df %>%
      mutate(
        Category = href
      ) %>%
      select(! c(href, leading_zero_category, category_path, category_name)) %>%
      return()
  }
  else {
    df %>%
      return()
  }
}

add_first_column_links_it_subcategory <- function(df, replace = TRUE) {
  
  # meta_categories <- get_meta_list("categories")
  df <- df %>%
    left_join(it_subcategory_labels, by = c("IT subcategory" = "original_it_subcategory"))
  df <- df %>%
    mutate(
      href = str_c('<a href="/it_subcategories/', `IT subcategory`, '/">', it_subcategory_name, "</a>")
    )
  
  if(replace == TRUE) {
    df %>%
      mutate(
        "IT subcategory" = href
      ) %>%
      select(! c(href, it_subcategory_name)) %>%
      return()
  }
  else {
    df %>%
      return()
  }
}


# Reusable function for vendors and departments
has_sufficient_it_spending_to_display_it_subcategories <- function(data, most_recent_fiscal_year_spending) {
  
  overall_it_total <- data %>%
    filter(Category == "3_information_technology") %>%
    select(! Category) %>%
    pivot_longer(
      cols = everything(),
      names_to = "year",
      values_to = "total"
    ) %>%
    summarize(
      overall_total = sum(total, na.rm = TRUE)
    ) %>%
    pull(overall_total)
  
  if(overall_it_total > it_subcategory_display_amount_threshold) {
    return(TRUE)
  }
  
  if(most_recent_fiscal_year_spending > 0) {
    most_recent_it_total <- data %>%
      filter(Category == "3_information_technology") %>%
      select(! Category) %>%
      pivot_longer(
        cols = everything(),
        names_to = "year",
        values_to = "total"
      ) %>%
      arrange(year) %>%
      slice_tail(n = 1) %>%
      pull(total) %>%
      as.numeric()
    
    if(length(most_recent_it_total) > 0) {
      if(!is.na(most_recent_it_total) & most_recent_it_total / most_recent_fiscal_year_spending >= it_subcategory_display_percentage_threshold) {
        return(TRUE)
      }
      
    }
  }
  
  return(FALSE)
  
}


# Small renaming functions ======================

# Thanks to
# https://stackoverflow.com/a/68968141/756641
rename_column_names <- function(df) {
  
  lookup <- c(
    Vendor = "d_vendor_name",
    Category = "d_most_recent_category",
    Department = "owner_org",
    "IT subcategory" = "d_most_recent_it_subcategory"
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
  if(entity_type == "it_subcategories") {
    path <- str_c(get_department_path(department), "summary_by_fiscal_year_by_it_subcategory.csv")
  }
  
  data <- read_csv(path)
  
  # For departments and vendors, there can end up being situations where none of the department's vendors are in the top list of included vendors, making the vendor data empty for that department.
  # This attempts to handle those cases.
  if(count(data) > 0) {
    data <- data %>%
      format_totals() %>%
      rename_column_names() %>%
      pivot_by_fiscal_year()
    
    return(data)
  } else {
    return(FALSE)
  }

}

dt_vendors_by_fiscal_year_by_department <- function(department) {
  
  data <- get_fiscal_year_data_by_entity_and_department(department, "vendors")
  
  # Note: data is a tibble if there is data, and FALSE if not.
  # Review if this should be handled more rigorously.
  # See get_fiscal_year_data_by_entity_and_department for more details - small departments may have 0 vendors that were large enough to be in the set of included vendors.
  if(! is.logical(data)) {
    data %>%
      dt_fiscal_year()
  } else {
    htmltools::p(class="no-table-data", "No data available – none of this department’s vendors were large enough to be included in the results.")
  }
  
}

dt_categories_by_fiscal_year_by_department <- function(department) {
  
  data <- get_fiscal_year_data_by_entity_and_department(department, "categories")
  
  data %>%
    dt_fiscal_year_categories()
  
}

dt_it_subcategories_by_fiscal_year_by_department <- function(department) {
  
  data <- get_fiscal_year_data_by_entity_and_department(department, "it_subcategories")
  data %>%
    dt_fiscal_year_categories()
  
}

has_sufficient_it_spending_to_display_it_subcategories_by_department <- function(department) {
  data <- get_fiscal_year_data_by_entity_and_department(department, "categories")
  
  most_recent_fiscal_year_spending <- get_most_recent_fiscal_year_total(department, "departments", format = FALSE)
  
  # Return the output of:
  has_sufficient_it_spending_to_display_it_subcategories(data, most_recent_fiscal_year_spending)
  
}

blogdown_display_it_subcategories_by_department <- function(department) {
  if(has_sufficient_it_spending_to_display_it_subcategories_by_department(department)) {
    return("markup")
  }
  else {
    return("hide")
  }
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
  if(entity_type == "it_subcategories") {
    path <- str_c(get_vendor_path(vendor), "summary_by_fiscal_year_by_it_subcategory.csv")
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

dt_it_subcategories_by_fiscal_year_by_vendor <- function(vendor) {
  
  data <- get_fiscal_year_data_by_entity_and_vendor(vendor, "it_subcategories")
  data %>%
    dt_fiscal_year_categories()
  
}


# Determine whether or not to display the "IT subcategories" section
has_sufficient_it_spending_to_display_it_subcategories_by_vendor <- function(vendor) {
  data <- get_fiscal_year_data_by_entity_and_vendor(vendor, "categories")
  
  most_recent_fiscal_year_spending <- get_most_recent_fiscal_year_total(vendor, "vendors", format = FALSE)
  
  # Return the output of:
  has_sufficient_it_spending_to_display_it_subcategories(data, most_recent_fiscal_year_spending)
  
}

# Format for the knitr chunk "results" parameter
blogdown_display_it_subcategories_by_vendor <- function(vendor) {
  if(has_sufficient_it_spending_to_display_it_subcategories_by_vendor(vendor)) {
    return("markup")
  }
  else {
    return("hide")
  }
}


# Get the original names for a given vendor
get_original_vendor_names <- function(vendor) {
  path <- str_c(get_vendor_path(vendor), "original_vendor_names.csv")
  names <- read_csv(path)
}

display_original_vendor_names <- function(vendor) {
  
  # Note: in the original_vendor_name included as the link text below, we'll replace a small set of characters to avoid breaking Markdown links.
  # This includes `, *, and @
  # Thanks to
  # https://community.rstudio.com/t/removing-asterisk-and-brackets-from-a-column/69095/2
  replacement_pattern <- "\\*|\\`|\\@"
  
  search_prefix <- "https://search.open.canada.ca/en/ct/?sort=contract_value_f%20desc&page=1&search_text="
  names <- get_original_vendor_names(vendor)
  names <- names %>%
    mutate(
      url_encoded_name = url_encode(str_c("\"", original_vendor_name, "\"")),
      markdown_link = str_c("[", str_replace_all(original_vendor_name, pattern = replacement_pattern, replacement = ""), "](", search_prefix, url_encoded_name, ")")
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
  # Handling for
  # Error: no applicable method for 'round_any' applied to an object of class "logical"
  if(is.na(number)) {
    number
  }
  else {
    scales::label_number(accuracy = 0.1, scale_cut = scales::cut_short_scale())(number)
  }

}

# Add thousands separators, for counts of contracts and amendments etc.
format_entity_count <- function(number) {
  format(number,big.mark=",", trim=TRUE)
}

format_currency <- function(number) {
  format(number,big.mark=",", digits = 2, nsmall = 2, trim=TRUE)
}

# Convert decimals to friendly percentages
format_percentage <- function(percentage) {
  str_c(percentage * 100, "%")
}

format_percentage_rounded <- function(percentage) {
  str_c(round(percentage, digits = 2) * 100, "%")
}

# entity_type should be "categories", "vendors", or "departments"
get_name_from_filename <- function(entity_filepath, entity_type, output_column = "name") {
  
  meta_entities <- get_meta_list(entity_type)
  
  entity <- meta_entities %>%
    filter(filepath == !!entity_filepath) %>%
    pull(output_column)
  
  # Handling for extraneous apostrophes, e.g.
  # "Office of the Taxpayers' Ombudsperson"
  # which might break quoted YAML strings, for example.
  entity <- entity %>%
    str_replace_all("'", "")
  
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


# YAML helper functions for site-wide data ======

# Write log files (a tibble with name, value columns in that order) to a YAML file
write_log_to_yaml <- function(run_log, file) {
  
  # Convert to named list, to create an indexed array
  # in the output YAML file.
  # Thanks to
  # https://www.r-bloggers.com/2017/10/how-best-to-convert-a-names-values-tibble-to-a-named-list/
  run_log <- as.list( setNames( run_log[[2]], run_log[[1]] ) )
  
  run_log %>%
    write_yaml(file = file, column.major = FALSE)
  
  run_log
  
}


# Update the Hugo data file with the latest run log from the main repository
update_run_yaml <- function() {
  file_path = str_c(csv_input_path, "run_log.csv")
  run_log <- read_csv(file_path) %>%
    filter(!is.na(value)) %>%
    select(name, value)
  
  run_log %>%
    write_log_to_yaml(parse_run_log_yaml_output_path)
  
}

# Note: this is currently being updated on every page load; that's probably unnecessary...!
update_run_yaml()

# Retrieve data from the research findings CSV files

get_research_finding <- function(function_name, summary_type, value_column, filter_column = FALSE, filter_search = FALSE) {
  
  file_path = str_c(csv_input_path, "overall/", summary_type, "/", function_name,".csv")
  
  data <- read_csv(file_path)
  
  if(filter_column != FALSE & filter_search != FALSE) {
    data <- data %>%
      filter(across(all_of(filter_column)) == !!filter_search)
  }
  
  data %>%
    pull(value_column) %>%
    first()
  
}

# Example usage
# get_research_finding("s421_mean_contract_value", "all", "mean_overall_value")
# get_research_finding("s421_mean_contract_value", "all", "n")
# 
# get_research_finding("s421_mean_contract_value_by_vendor", "all", "mean_overall_value", "d_vendor_name", "ALTIS HUMAN RESOURCES")
# get_research_finding("s421_mean_contract_value_by_vendor", "all", "n", "d_vendor_name", "ALTIS HUMAN RESOURCES")

# Link generation helpers ===================

a_table_source_data_github <- function(entity_filepath, entity_type, filename, text = "View source data", a_class = "source-data-link btn btn-link", p_class = "text-right") {
  htmltools::p(class=p_class,
               htmltools::a(text, href=str_c("https://github.com/GoC-Spending/contracts-data/tree/main/data/out/", entity_type, "/", entity_filepath, "/", filename), class=a_class)
  )
}

# filename <- "summary_by_fiscal_year.csv"
# a_table_source_data_github(entity_filepath, entity_type, filename)
