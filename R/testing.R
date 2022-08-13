# Testing functions for work in progress

source("R/init.R")

department <- "ssc-spc"

path <- str_c(get_department_path(department), "summary_total_by_vendor_and_fiscal_year.csv")

data <- read_csv(path) %>%
  format_totals()

data %>%
  pivot_wider(names_from = d_fiscal_year, values_from = total)

data %>%
  rename_vendor_name() %>%
  pivot_by_fiscal_year()
