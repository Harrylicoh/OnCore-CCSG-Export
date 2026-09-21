# Clinical Trials Reporting Program (CTRP) Data Export

## Overview
The National Cancer Institute (NCI) requires upload of Subject Accrual Information from Pariticipating Institutions to the Clinical Trials Reporting Program (CTRP) for NCI funded trials on a quarterly basis as part of the Cancer Center Support Grant (CCSG). This is typically done through CTRP's Manual Upload Service, where users manually upload batch files of subject accruals to the CTRP website.

## Problem Decomposition
The export pipeline processes study records through three stages:

### 1. Study Classification & Change Detection

- Classification of studies using internal business rules and filters out ones not relevant to federal reporting requirements. 

- Identifying studies that require federal reporting vs. exempt protocols.

- Filtering out static studies, targeting only records with new or updated participant activity during the reporting window.

### 2. Data Extraction

- Connecting to the underlying CTMS database to retrieve relevant study IDs, demographic profiles, participating sites, and enrollment counts.

### 3. Format Transformation & Export

- Normalizes extracted data into the specific Format required by the NIH (Subject-level vs. Summary-level).

#### Reporting Standards

There are two formats that NIH allows for reporting of study accrual data to the CTRP, **Subject** and **Summary** level accrual.

##### Subject Accrual
Study accruals are identified by a Sequence Number and demographic information is associated with this number to be uploaded onto CTRP. 

Granularity exists at: **Study - Subject - Race(s)** level.
* A subject can be a member of multiple races

##### Summary Accrual
Study accrual are identified by Enrollment Institution, Month, and total number of accruals for the institution up to that date.

Granularity exists at: **Study - Enrollment Institution - Month** level
* A study can have multiple sites where they can enroll subjects


