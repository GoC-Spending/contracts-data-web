---
title: '{{ .Name }}'
author: ''
date: '{{ .Date }}'
---

Category content here.

## Vendors

```{r echo=FALSE, message=FALSE, warning=FALSE}

source("../../R/init.R")
current_filename <- get_current_filename()

dt_vendors_by_fiscal_year_by_category(current_filename)

```

## Departments and agencies

```{r echo=FALSE, message=FALSE, warning=FALSE}

dt_departments_by_fiscal_year_by_category(current_filename)

```
