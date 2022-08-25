---
title: Methodology
author: ''
date: '2022-08-17'
slug: methodology
categories: []
tags: []
---

To illustrate contract trends at a government-wide level, publicly-available contracting data was cleaned, analyzed, and aggregated. This process included specific handling for multi-year and amended contracts, as well as normalizing vendor names and assigning high-level categories (information technology, professional services, facilities and construction, etc.). The R code used for this analysis is [publicly available on GitHub](https://github.com/goc-Spending/contracts-data). The steps used are described in more detail below. 

This analysis builds off a [2017-2019 Ottawa Civic Tech project](https://goc-spending.github.io/). [See the original methodology here](https://goc-spending.github.io/methodology/).


## Data sources

The primary data source for the analysis is the Proactive Disclosure of Contracts dataset, published by the Government of Canada on open.canada.ca. This dataset consists of rows for each contract and/or contract amendment reported by departments and agencies. 

Publishing this data is required under section the Access to Information Act. Prior to the 2017-18 fiscal year, most departments published this information on departmental websites that were not machine-readable. Since 2017-18, departments have consistently published data in the [combined CSV dataset](https://open.canada.ca/data/en/dataset/d8f85d91-7dec-4fd1-8055-483b77225d8b) maintained by the Treasury Board Secretariat’s [Open Government team](https://open.canada.ca/en). This combined dataset resolves a number of issues with the information previously published by departments (notably inconsistent date formatting).

The analysis uses the complete CSV dataset [available for download on open.canada.ca](https://open.canada.ca/data/en/dataset/d8f85d91-7dec-4fd1-8055-483b77225d8b). Dataset entries can also be individually viewed [using a search function on the website](https://search.open.canada.ca/en/ct/?sort=contract_value_f%20desc&page=1&search_text=); each entry represents a row of the CSV file.This function provides a good overview of the fields that are available in the CSV dataset. [For example](https://search.open.canada.ca/en/ct/id/esdc-edsc,C-2022-2023-Q1-00335):



* The name of the vendor (company) the contract is issued to
* A description of the contract (often but not always matching an economic object code, described below)
* An economic object code (representing a particular category of goods or services, for example “0491” for management consulting)
* The federal organization (department or agency) issuing the contract
* The reporting period (fiscal year and quarter)
* Start date and end dates (in some cases, a delivery date) for the contract
* The total value of the contract
* The original value of the contract (applicable to contracts with amendments)
* The amendment value of that specific amendment (for a contract amendment entry)
* A procurement identification number issued by the department’s procurement office (or by PSPC, for larger contracts)

There are a variety of other contract metadata fields, some of which have been added in the past few years. Coverage or use of these other fields varies between departments and from older to more recent contracts.

Each row in the CSV dataset represents either a new contract, or an amendment to a previous contract. These amendments can include a change to the total value of the contract (a larger or smaller total amount of money) or to the end date (typically, extending the contract for a longer period of time than the original contract). Matching amendments back to their original contract is challenging, described in more detail below.

It’s important to note that the contract value indicates the amount of money that the department **commits** to spending through the contract, rather than a transactional record of funds being spent at a particular point in time. As well, for many information technology and professional services contracts that are issued with “task authorizations”, the contract value represents the maximum amount of money that could be spent under the contract. Depending on the value of task authorizations issued under the contract, the actual amount spent could be lower. Departments may or may not amend their published contract entries to match this spending at the conclusion of the contract.

Beginning in 2020-2021, some departments have also declined to include the contract value, instead indicating that the contract value “is not disclosed to support Canada’s economic interests and the negotiating position of the Government of Canada” ([indicated for example here](https://search.open.canada.ca/en/ct/id/hc-sc,C-2021-2022-Q3-00541)). In these cases the contract value is listed as $0.00 and the actual contract value is not public information nor included in any of this paper’s analysis. 


## Steps


### Retrieve data


### Initial data cleanup


### Normalize vendor names


### Group by industry category


### Associate amendments with original contracts


### Calculate spending over time


### Generate and export summary CSV files


### Website display
