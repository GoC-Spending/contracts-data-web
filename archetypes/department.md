---
title: '{{ .Name }}'
author: ''
date: '{{ .Date }}'
---

Department content here.

## Vendors

```{r echo=FALSE, message=FALSE, warning=FALSE}

source("../../R/init.R")
current_filename <- get_current_filename()

dt_vendors_by_fiscal_year_by_department(current_filename)

```

## Categories

```{r echo=FALSE, message=FALSE, warning=FALSE}

dt_categories_by_fiscal_year_by_department(current_filename)

```