---
title: Methodology
author: ''
date: '2022-08-17'
slug: methodology
categories: []
tags: []
---

To examine contract trends at a government-wide level, publicly-available contracting data was cleaned, categorized, and aggregated. This process included specific handling for multi-year and amended contracts, to better illustrate estimated spending over time. The R code used for this analysis is [publicly available on GitHub](https://github.com/goc-Spending/contracts-data). The steps used are described in more detail below. 

This analysis builds on a [2017-2019 Ottawa Civic Tech project](https://goc-spending.github.io/) led by one of the authors.

## Table of contents

{{< table_of_contents >}}

## Data sources

The primary data source for the analysis is the [Proactive Disclosure of Contracts dataset](https://open.canada.ca/data/en/dataset/d8f85d91-7dec-4fd1-8055-483b77225d8b), published by the Government of Canada on [open.canada.ca](https://open.canada.ca/en). This dataset consists of rows for each contract and/or contract amendment reported by departments and agencies. 

Publishing this data is required under [section 86 (1)](https://laws-lois.justice.gc.ca/eng/acts/a-1/page-10.html#1171954) of the _Access to Information Act_. Departments are required to publicly disclose new contracts “within 30 days after the end of each of the first three quarters and within 60 days after the end of each fourth quarter”. 

Prior to the 2017-18 fiscal year, most departments published this information on departmental websites that were not machine-readable. Since 2017-18, departments have consistently published data in the [combined CSV dataset](https://open.canada.ca/data/en/dataset/d8f85d91-7dec-4fd1-8055-483b77225d8b) maintained by the Treasury Board Secretariat’s open government team. This combined dataset resolves [a number of data quality issues](https://goc-spending.github.io/methodology/#date-validation) with the information previously published by departments.

The analysis uses the complete CSV dataset [available for download on open.canada.ca](https://open.canada.ca/data/en/dataset/d8f85d91-7dec-4fd1-8055-483b77225d8b). Dataset entries can also be [individually viewed using a search function on the website](https://search.open.canada.ca/en/ct/?sort=contract_value_f%20desc&page=1&search_text=); each entry represents a row of the CSV file.This function provides a good overview of the fields that are available in the CSV dataset. [For example](https://search.open.canada.ca/en/ct/id/esdc-edsc,C-2022-2023-Q1-00335):



* The name of the vendor (company) the contract is awarded to
* A description of the contract (often but not always matching an economic object code, [described below](#group-by-industry-category))
* An economic object code (representing a particular category of goods or services, for example “0491” for management consulting)
* The federal organization (department or agency) issuing the contract
* The reporting period (fiscal year and quarter)
* Start date and end dates (in some cases, a delivery date) for the contract
* The total value of the contract
* The original value of the contract (applicable to contracts with amendments)
* The amendment value of that specific amendment (for a contract amendment entry)
* A procurement identification number issued by the department’s procurement office (or by PSPC, for larger contracts)

There are a variety of other contract metadata fields, some of which have been added in the past few years. Consistent usage of these other fields varies between departments and from older to more recent contracts.

It’s important to note that the contract value indicates contract **award** amounts: the amount of money that the department commits to spending through the contract, rather than a transactional record of funds being spent at a particular point in time. As well, for many information technology and professional services contracts that are issued with [“task authorizations”](https://buyandsell.gc.ca/policy-and-guidelines/supply-manual/section/3/35/1), the contract value represents the maximum amount of money that could be spent under the contract. Depending on the value of task authorizations issued under the contract, the actual amount spent could be lower. Departments [may or may not amend their published contract entries](https://www.tbs-sct.canada.ca/pol/doc-eng.aspx?id=14676#cla4.1.9) to match this spending at the conclusion of the contract.

In rare cases, some departments have also [declined to include](https://www.tbs-sct.canada.ca/pol/doc-eng.aspx?id=14676#cla4.1.10) the contract value, instead indicating that the contract value “is not disclosed to support Canada’s economic interests and the negotiating position of the Government of Canada” ([indicated for example here](https://search.open.canada.ca/en/ct/id/hc-sc,C-2021-2022-Q3-00541)). In these cases the contract value is listed as $0.00 and the actual contract value is not public information nor included in any of this paper’s analysis. Most of these instances are from 2021-2022; this is a disappointing trend that we hope will not frequently occur in the future.

The amount of money ultimately spent by the Government of Canada on each contract is not publicly disclosed, if it differs from the contract award amount included in the proactive disclosure CSV dataset. **This represents a “data cliff” in Canadian government spending: it isn’t possible to follow the money from contract award to money as spent.** Countries around the world have adopted the [Open Contracting Data Standard](https://www.open-contracting.org/data-standard/) (OCDS) and more robust contracting data systems in order to make this possible.


## Analysis steps


### Retrieve data and perform initial cleanup

When the analysis code is run, it first downloads [a new copy of the CSV dataset from open.canada.ca](https://open.canada.ca/data/en/dataset/d8f85d91-7dec-4fd1-8055-483b77225d8b) and saves a date-specific copy. The most recent download date is visible in the [analysis run log](https://github.com/GoC-Spending/contracts-data/blob/main/data/out/run_log.csv).

Once the data is downloaded and loaded, the analysis code does several cleanup actions. This includes cleaning up or correcting for data entry errors in procurement IDs, reporting periods, and reference numbers that are used in later amendment matching steps.


### Normalize vendor names

The source data provided by departments does not include any normalization or consolidation of vendor (company) names. As a result, the same vendors are often listed under a wide range of manually-entered names.

First, all punctuation and frequently-used suffixes are [removed from the vendor names](https://github.com/GoC-Spending/contracts-data/blob/main/lib/vendors.R#L26-L73) (for example, “Ltd”, “Limited”, “Limitée”, etc.). Accented characters are converted to unaccented equivalents. Vendor names are converted to uppercase.

Next, vendor names are [matched to a canonical name using a lengthy normalization table](https://github.com/GoC-Spending/contracts-data/blob/main/data/vendors/vendor_normalization_data.csv) that was created manually. This matching table has more than 6,000 entries, and was [adapted from an earlier version created as part of the Ottawa Civic Tech project](https://goc-spending.github.io/methodology/#vendor-name-normalization).

R’s [fuzzyjoin package](http://varianceexplained.org/fuzzyjoin/) was used to suggest possible matches, which were then confirmed manually. Known mergers and acquisitions as well as subsidiary companies are included in the matching table where known; [suggested changes or additions to the vendor normalization table are welcome](https://docs.google.com/forms/d/e/1FAIpQLSfHGzAQMaOkj4OD2Kc8Gw4ROChOfx6MKm5t2CSr6R4U2qupBQ/viewform?usp=pp_url&entry.739845506=%2Fmethodology%2F).

The current record-holder for the most variations on a company name is [Canadian Corps of Commissionaires](/vendors/canadian_corps_of_commissionaires/), with 296 distinct vendor name entries. The original names of each vendor are included in a summary table, to facilitate [searches of the source data on open.canada.ca](https://search.open.canada.ca/en/ct/?sort=contract_value_f%20desc&page=1&search_text=).


### Group by industry category

Contracts were categorized into one of the following twelve categories:



1. Facilities and construction
2. Professional services
3. Information technology
4. Medical
5. Transportation and logistics
6. Industrial products and services
7. Travel
8. Security and protection
9. Human capital
10. Office management
11. Defence
12. (Other and uncategorized)

This category structure is based on the [“Government-wide Categories”](https://www.acquisition.gov/sites/default/files/page_file_uploads/Government%20Wide%20Categories.pdf) approach [developed by the Government Services Administration](https://www.acquisition.gov/content/category-management) (GSA) in the United States. The GSA version includes 9 additional defence-related categories that are grouped into a single “Defence” category in this analysis.

The Canadian government uses several categorization approaches, including [economic object codes used in the Public Accounts](https://www.tpsgc-pwgsc.gc.ca/recgen/pceaf-gwcoa/2021/7-eng.html), [Goods and Services Identification Number](https://buyandsell.gc.ca/procurement-data/goods-and-services-identification-number) (GSIN) codes, and [United Nations Standard Products and Services Code](https://www.unspsc.org/) (UNSPSC) codes. (PSPC is [currently migrating from GSIN to UNSPSPC codes](https://buyandsell.gc.ca/procurement-data/unspsc) in contract reporting.) 

In this analysis, we chose to use the GSA’s [Government-wide Categories](https://www.acquisition.gov/sites/default/files/page_file_uploads/Government%20Wide%20Categories.pdf) structure for two reasons: it included information technology (our primary area of focus) as a distinct top-level category, rather than being nested below professional services. And, it was concise enough at twelve options to facilitate manual categorization and data correction. (In comparison, there are around a hundred GSIN codes and several dozen top-level UNSPSC segments. UNSPSC codes in machine-readable format are also [only available to paid subscribers](https://www.unspsc.org/subscribe) or for purchase.)

About 77% of contracts in the CSV dataset included economic object codes; these were matched to one of the twelve categories above. For contracts without economic object codes, these were matched using the description field. A text classifier model was trained using the initial set of descriptions and categories and run in a Jupyter Notebook. This model was used to generate an expanded matching table of descriptions to categories, with about 9,300 rows. This table was then manually reviewed before using it to categorize the remaining contracts.

Some contracts are deliberately categorized as “Other and uncategorized”. This includes international development transfers from [Global Affairs Canada](/departments/dfatd-maecd/) intended for other countries (transferred via Canadian non-profit organizations or specialized providers) as well as contracts from various departments that don’t include distinct description fields (for example, issued with descriptions like “Other”, “Payments”, or “Miscellaneous expenditures”).

With economic object codes being used as the primary categorization method, there was a significant level of category overlap between defence-specific information technology or transportation and logistics contracts issued by the [Department of National Defence](/departments/dnd-mdn/) and civilian equivalents issued by other departments. To differentiate these, all DND-issued information technology or transportation and logistics contracts [are bulk-listed as “Defence” at the end of the categorization process](https://github.com/GoC-Spending/contracts-data/blob/main/load.R#L316-L332). 


### Associate amendments with original contracts

Each row in the CSV dataset represents either a new contract, or an amendment to a previous contract. These amendments can include a change to the total value of the contract (a larger or smaller total amount of money) or to the end date (typically, but not always, extending the contract for a longer period of time than the original contract). 

Matching amendments back to their original contract is a critical step, to prevent double-counting the value of the same (amended) contract more than once when examining spending over time.

Departments do not issue procurement IDs consistently enough to solely use these for matching. To compensate, two amendment matching approaches are taken in series:



1. Entries are grouped by matching **department**, **vendor**, and **procurement ID** (after procurement IDs have had extraneous suffixes removed, and after vendor names have been normalized as described above)
2. Any entries not grouped using the first method are grouped by matching **department**, **vendor**, **original value**, and **start date** (which allows matching contract and amendment groups without consistent procurement IDs). This is at slightly higher risk of matching unrelated contracts issued by the same department to the same vendor, on the same day, for the same original amount. (This may sound unlikely, but could happen in some cases at specific procurement thresholds, such as the $25k and $40k limits for sole-sourcing services and goods respectively).

Across the entire contract set, approximately 91% of contracts with amendments are matched using the first method and 9% are matched using the second method.


### Calculate spending over time

After contracts are matched with their amendments, the most-recently-issued amendment in the group is used to determine the “canonical” total value of the contract, and the canonical end date (which in some cases may be earlier than the end date of previous amendments, for contracts whose duration was shortened by their latest amendment). These total values and end dates are used throughout the rest of the analysis.

Using the original start date of the contract, and the “canonical” end date indicated by the most-recently-issued amendment (or, for contracts without amendments, the contract’s original end date), a “per day” cost of the contract is determined by dividing the total value of the contract by the number of days (inclusive) between the start and end of the contract.

This “per day” cost is then expanded in a data table that includes individual rows for each day of each contract and amendment group. This table is then used to calculate costs for specific time ranges, particularly fiscal years, since it can be easily filtered or grouped according to a specific time range and then summed up using the per-day cost.

During this stage of the analysis, inflation-adjusted totals are also calculated using constant 2019 dollars. This uses [quarterly data from gross domestic product price indexes published by Statistics Canada](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=3610010601), accessed via the excellent [cansim R package](https://mountainmath.github.io/cansim/). Quarterly values (based on the “General governments final consumption expenditure” price index) are used to determine constant dollar amounts for “per day” costs that can then be summed up in later steps in the same way as current dollars.

In calculating spending over time, it’s important to note: **this approach assumes a completely consistent, linear spending of money on a given contract throughout its entire duration.** In practice, spending on a long-term contract likely varies wildly from month to month and year to year, as project deliverables are completed or component goods are shipped by the vendor. Actual spending over time is not publicly disclosed by departments, and as a consequence this linear spending approach is used to determine a best-effort estimate. 

If actual spending was disclosed, even for a subset of contracts and vendors, it could be used to generate spending models (for example, a chart with a spike in the first or second year of a multi-year contract that approaches $0 by the final year) that could be incorporated here.

As is, the totals calculated for any given time period **should always be considered estimates**; they accurately reflect the total contract values published by departments but they do not necessarily reflect the actual spending that took place for a given contract in the given time period. 


### Generate and export summary CSV files

The summary CSV files generated by the analysis ([available on GitHub](https://github.com/GoC-Spending/contracts-data/tree/main/data/out)) are filtered to a specified time range (e.g. the 2017-2018 to 2021-2022 fiscal years) given that 2017-2018 was the first year that comprehensive departmental data was included [in the open.canada.ca dataset](https://open.canada.ca/data/en/dataset/d8f85d91-7dec-4fd1-8055-483b77225d8b). The start and end fiscal years can be viewed [in the analysis run log](https://github.com/GoC-Spending/contracts-data/blob/main/data/out/run_log.csv).

Although departments are [required under the Access to Information Act](https://laws-lois.justice.gc.ca/eng/acts/a-1/page-10.html#1171954) to publish contract award data within 60 days after the end of the fourth quarter (60 days after March 31), in practice it appears to take several more months before this data is fully available. Prior to August 2022, data for the 2021-2022 fiscal year was visibly incomplete (with substantially fewer contracts per year than previous fiscal years). By early August 2022, this had been rectified and the analysis uses 2021-2022 as the most recent analysis year as a result. (Future research efforts could benefit from more comprehensive daily or weekly monitoring of changes to the dataset to better understand the timelines on which this data is updated, and of variation across departments.)

Overall summaries of government-wide spending are broken down into three “summary types”: 



1. [Core public service departments](/core/) (excluding, for example, the Department of National Defence, commissions, review committees, and Offices of Parliament).
2. [The Department of National Defence](/dnd/) (given that defence procurement is substantially different in scale and types of contracts than other public sector procurement).
3. [All departments, agencies, and public sector organizations](/all/) included in the source dataset.

Overall spending, amendment trends, and contract durations are calculated for each of these summary types. The same calculations are also made individually for each department, each vendor, and each category. These are [published on GitHub in CSV format](https://github.com/GoC-Spending/contracts-data/tree/main/data/out/overall/all), and used to generate the website display (described below).

The source data includes a “long tail” of vendors (with 115,730 unique vendors in the dataset, after vendor names have been normalized). In summaries and CSV exports that list individual vendors, these are limited to vendors with an average of at least $1M in annual contract value across the five fiscal years of the specified time range. This excludes vendors whose government-wide contract spending is less than $5M over that time range (for example, vendors who were issued contracts for the first time in the most recent fiscal year are excluded if their contract spending that year was less than $5M). 

Just under [1,500 vendors](/all/#vendors) meet that threshold and are individually included in the website display and CSV exports. Note that government-wide, department-wide, and category-wide summaries and contract totals still include vendors that are smaller than the spending threshold.


### Website display

The [website display](/) is generated using the CSV files from the summary exports above. Along with the overall summaries, it [generates](https://github.com/GoC-Spending/contracts-data-web/blob/main/R/generate.R) individual pages for each department, each category, and each vendor that are linked together. The website is powered by the [Blogdown R package](https://pkgs.rstudio.com/blogdown/), the [DT (DataTables) package](https://rstudio.github.io/DT/), and the [Hugo static website generator](https://gohugo.io/). The [source code is visible on GitHub](https://github.com/GoC-Spending/contracts-data-web) and the website is hosted by [Netlify](https://www.netlify.com/).

The primary goal of the website is descriptive, to help illustrate overall spending trends at a government-wide level as well as across entire departments, and for vendors across all of the departments they work with. Each vendor page on the website includes links to the original proactive disclosure entries on open.canada.ca (using their original, pre-normalized names) via the [open.canada.ca search function](https://search.open.canada.ca/en/ct/?sort=contract_value_f%20desc&page=1&search_text=).

Each website page includes links to the [exported CSV files](https://github.com/GoC-Spending/contracts-data/tree/main/data/out) used to generate each table, for accessibility and to facilitate future analysis by other researchers and civic tech organizations.

Suggestions, comments, and error corrections can be submitted using the [feedback link](https://docs.google.com/forms/d/e/1FAIpQLSfHGzAQMaOkj4OD2Kc8Gw4ROChOfx6MKm5t2CSr6R4U2qupBQ/viewform?usp=pp_url&entry.739845506=%2Fmethodology%2F) at the bottom of each page. Thanks for your support! [Read more about the project](/about/).
