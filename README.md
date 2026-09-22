# The Second Purchase

### Customer Retention & Repeat Purchase Analytics

**SQL · Python · Customer Analytics · Cohort Analysis · Predictive Modeling**

---

## Overview

Acquiring a customer is only the beginning of the customer lifecycle.

This project analyzes more than **1 million retail transaction records** to understand what happens after a customer's first purchase: how quickly customers return, which first-order behaviors are associated with repeat purchasing, and how much those early signals can tell us about future retention.

Using **MySQL and Python**, the analysis transforms raw transaction data into customer-level purchase journeys and evaluates 90-day repeat purchasing through behavioral analysis, cohort analysis, and logistic regression.


## Data

This project uses the **Online Retail II** dataset from the UCI Machine Learning Repository, containing more than **1 million transaction records** from a UK-based online retailer between December 2009 and December 2011.

**Source:** Chen, D. (2012). *Online Retail II* [Dataset]. UCI Machine Learning Repository.  
https://doi.org/10.24432/C5CG6D

The raw transaction data includes invoice identifiers, product codes, quantities, transaction dates, unit prices, customer identifiers, and customer countries.


### Business Question

> **What characteristics of a customer's first purchase are associated with making a second purchase within 90 days?**

---

## Key Findings

### 47.3% of eligible customers returned within 90 days

Repeat purchasing increased substantially across the first three months after acquisition:

| Window | Repeat Purchase Rate |
|---|---:|
| 30 Days | **23.4%** |
| 60 Days | **38.3%** |
| 90 Days | **47.3%** |

Eligibility was adjusted for each observation window so customers without sufficient follow-up time were not incorrectly classified as non-repeaters.

### Higher-value first orders were associated with stronger retention

| First-Order Value Quartile | 90-Day Repeat Rate |
|---|---:|
| Q1 | **36.6%** |
| Q2 | **45.2%** |
| Q3 | **50.2%** |
| Q4 | **57.1%** |

Customers in the highest first-order-value quartile had a **20.5 percentage-point higher observed repeat rate** than customers in the lowest quartile.

### Greater product variety was also associated with repeat purchasing

| First-Order Product Variety Quartile | 90-Day Repeat Rate |
|---|---:|
| Q1 | **41.9%** |
| Q2 | **44.1%** |
| Q3 | **48.5%** |
| Q4 | **54.6%** |

Customers who explored a broader range of products during their first order showed higher subsequent retention.

### Acquisition cohort improved predictive performance

Retention varied substantially across acquisition periods and did not follow a simple linear time trend.

| Model | ROC-AUC |
|---|---:|
| First-Order Behavior | **0.570** |
| Behavior + Linear Acquisition Time | **0.587** |
| Behavior + Acquisition Quarter | **0.617** |

Representing acquisition timing as quarterly cohorts produced the strongest model, while geography provided virtually no incremental predictive value.

---

## Analytical Workflow

### 1. Data Cleaning & Validation — SQL

The raw dataset contained **1,067,371 transaction rows** spanning December 2009 through December 2011.

Before analysis, the transaction data was audited for cancellations, negative quantities, non-positive prices, missing customer identifiers, duplicate rows, and invalid dates.

The cleaned analytical dataset retained identifiable, completed purchase transactions with:

- Valid customer IDs
- Positive quantities
- Positive prices
- Non-cancelled invoices
- Parsed transaction timestamps
- Line-level revenue calculations

### 2. Customer Journey Construction — SQL

Transaction-level records were aggregated into customer purchase histories to identify each customer's first and second orders.

SQL techniques included:

- Common Table Expressions (CTEs)
- Window functions
- `ROW_NUMBER()`
- `NTILE()`
- Conditional aggregation
- `DATEDIFF()`
- Cohort analysis

Customer-level features were then created for:

- First purchase date
- First-order value
- First-order item quantity
- First-order product variety
- First-order country
- Days to second purchase
- Acquisition cohort
- 90-day repeat purchase outcome

The final modeling dataset contained **5,281 eligible customers**.

### 3. Exploratory Analysis & Feature Engineering — Python

Python was used to examine first-order behavioral patterns and prepare features for modeling.

First-order value and item quantity were highly right-skewed due to a small number of unusually large orders. Log transformations were used to reduce the influence of extreme observations without automatically removing them.

The analysis also evaluated:

- Summary statistics and distributions
- Behavioral segmentation
- Correlations
- Multicollinearity using VIF
- Acquisition cohort patterns
- Geographic contribution

### 4. Predictive Modeling — Python

Logistic regression was used to evaluate whether information available at the first purchase could help distinguish customers who would return within 90 days.

The modeling process progressed from a **behavior-only baseline** to models incorporating acquisition context.

Feature ablation showed that acquisition timing added predictive information, while geography contributed virtually no incremental improvement.

Cohort analysis then revealed a nonlinear relationship between acquisition timing and retention, motivating the final quarterly cohort specification.

The final model achieved:

| Metric | Behavior Only | Final Model |
|---|---:|---:|
| Accuracy | 54.0% | **59.3%** |
| Precision | 52.1% | **58.5%** |
| Recall | 35.2% | **48.4%** |
| F1 Score | 42.0% | **53.0%** |
| ROC-AUC | 0.570 | **0.617** |

---

## Business Recommendations

### Prioritize the first 90 days after acquisition

Repeat purchasing increased from **23.4% within 30 days** to **47.3% within 90 days**, making the early post-purchase period an important retention window.

Businesses can use this period for structured post-purchase journeys such as product education, complementary-product recommendations, and appropriately timed re-engagement campaigns.

### Use first-order behavior for early customer segmentation

First-order value and product variety were consistently associated with higher repeat rates.

These signals can support early customer segmentation—for example, identifying customers demonstrating stronger initial engagement—rather than being treated as deterministic predictions of future behavior.

### Monitor retention by acquisition cohort

Retention varied substantially across acquisition periods, and quarterly cohort information improved predictive performance beyond first-order behavior alone.

Retention KPIs should therefore be monitored by acquisition cohort rather than only through aggregate averages. With richer marketing data, future analysis could investigate whether differences in channel mix, promotions, or seasonality help explain these patterns.

### Expand retention modeling with richer behavioral signals

The final model improved ROC-AUC from **0.570 to 0.617**, but predictive performance remained moderate.

Stronger customer-level prediction would likely require additional signals such as acquisition channel, email engagement, website activity, promotion exposure, product category, and post-purchase browsing behavior.

---

## Limitations

This analysis is **observational**. The relationships identified between first-order behavior, acquisition timing, and repeat purchasing should therefore be interpreted as associations rather than causal effects.

The available dataset primarily captures transaction behavior and does not include marketing exposure, acquisition channel, browsing activity, customer demographics, or other engagement signals that may influence retention.

Later acquisition cohorts also contain fewer customers than earlier cohorts, making extreme retention rates in smaller cohorts less stable.

Finally, the logistic regression model provides moderate predictive discrimination rather than production-level customer scoring. Its primary value is identifying and evaluating early retention signals within the available transaction data.
