# The Second Purchase

### Customer Retention & Repeat Purchase Analytics

**SQL · Python · Customer Analytics · Cohort Analysis · Predictive Modeling**

---

## Overview

Acquiring a customer is only the beginning of the customer lifecycle.

This project analyzes more than **1 million retail transaction records** to understand what happens after a customer's first purchase: how quickly customers return, which first-order behaviors are associated with repeat purchasing, and how much those early signals can tell us about future retention.

Using **MySQL and Python**, the analysis transforms raw transaction data into customer-level purchase journeys and evaluates 90-day repeat purchasing through behavioral analysis, cohort analysis, and logistic regression.

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
