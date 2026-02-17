# Fit.ly Tech — Customer Churn Analysis

> Identifying churn drivers and establishing KPIs to reduce a 28.5% churn rate and recover $52,900 in annual lost revenue.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Business Problem](#business-problem)
- [Dataset Description](#dataset-description)
- [Methodology](#methodology)
- [Key Findings](#key-findings)
- [Recommended Metric](#recommended-metric)
- [Results](#results)

---

## Project Overview

This project conducts a comprehensive churn analysis for **Fit.ly Tech**, a fitness SaaS company experiencing rising customer churn over two consecutive quarters. Using three internal datasets covering 400 customers, 918 support tickets, and 445 activity events, the analysis identifies the primary drivers of churn and establishes actionable KPIs for leadership monitoring.

---

## Business Problem

Fit.ly Tech's leadership is concerned about a rising churn rate and needs answers to:

- What is driving customers to cancel their subscriptions?
- Which customer segments are most at risk?
- What metrics should the business monitor to track and reduce churn?

---

## Dataset Description

| Dataset | Rows | Description |
|--------|------|-------------|
| `da_fitly_account_info.csv` | 400 | Customer plan, pricing, and churn status |
| `da_fitly_customer_support.csv` | 918 | Support tickets with channel, topic, and resolution times |
| `da_fitly_user_activity.csv` | 445 | Customer activity events with timestamps |

### Key Variables

**Account Info:**
- `customer_id` — Unique customer identifier (format: "C10000")
- `plan` — Subscription tier (Free, Basic, Pro, Enterprise)
- `plan_list_price` — Monthly price
- `churn_status` — "Y" if churned, blank if active

**Customer Support:**
- `user_id` — Customer identifier (numeric)
- `topic` — Support ticket category (billing, technical, account)
- `channel` — Contact method (email, chat, phone)
- `resolution_time_hours` — Time taken to resolve ticket
- `comments` — Free-text ticket notes

**User Activity:**
- `user_id` — Customer identifier
- `event_type` — Activity type (track_workout, watch_video, read_article, share_workout)
- `event_time` — Timestamp of activity

---

## Methodology

### 1. Data Validation and Cleaning

**Account Info:**
- Created binary churn indicator (1 = churned, 0 = active) from `churn_status`
- Converted `plan` from character to categorical variable reflecting subscription tiers
- Created numeric `user_id` by removing "C" prefix from `customer_id` to enable dataset joins
- Verified data completeness: no missing values in `plan_list_price`; no duplicate records

**Customer Support:**
- Converted `ticket_time` to datetime format
- Recoded missing channel values ("-") to "unknown"
- Identified and flagged 28 GDPR deletion requests; retained in analysis as data is anonymized
- Validated data quality: no missing `topic` values; all resolution times positive

**User Activity:**
- Converted `event_time` to datetime format
- Verified completeness: no missing values in `user_id` or `event_type`

### 2. Data Aggregation

- **Support metrics:** Ticket counts, average resolution times, and topic breakdowns aggregated per customer
- **Activity metrics:** Total events, engagement frequency, and event type distribution aggregated per customer

### 3. Data Integration

All three datasets merged using **LEFT JOIN** operations on `user_id`, preserving all 400 customers to avoid selection bias. Customers with zero activity (154, 39%) and no support contact (33, 8%) were retained as critical churn-risk segments.

### 4. Analysis Dimensions

Churn patterns analyzed across three key dimensions:
- **Plan type** — Churn rate by subscription tier
- **Engagement level** — Churn rate by activity volume
- **Support activity** — Churn rate by ticket volume and resolution time

---

## Key Findings

### Finding 1: Zero Engagement is the Primary Churn Driver

| Segment | Customers | Churn Rate |
|---------|-----------|------------|
| No activity | 154 (39%) | **54%** |
| With activity | 246 (61%) | **13%** |

Customers with no product engagement churn at **4× the rate** of engaged customers. Among paid plan users with zero activity, churn rates reach 58% (Basic), 43% (Pro), and 53% (Enterprise).

### Finding 2: Support Contact Correlates With Higher Churn

| Segment | Churn Rate | Avg Resolution Time |
|---------|-----------|-------------------|
| With support tickets | 30% | 18.7 hours (churned) |
| No support tickets | 15% | 6.7 hours (active) |

Billing tickets show the highest churn correlation at **36%**. Churned customers experienced resolution times **12 hours longer** than retained customers. Additionally, 28 GDPR deletion requests were identified in support comments.

### Finding 3: Free Plan Users Are Churning Without Converting

| Plan | Customers | Churn Rate |
|------|-----------|------------|
| Free | 105 (26%) | **41%** |
| Basic | 118 (30%) | 24% |
| Pro | 85 (21%) | 22% |
| Enterprise | 92 (23%) | 26% |

Among disengaged Free users specifically, churn reaches **59%**, indicating the platform fails to demonstrate value during the critical trial period.

---

## Recommended Metric

### Zero-Activity Customer Rate

```
Zero-Activity Rate (%) = (Customers with 0 Events / Total Customers) × 100
```

| | Value |
|--|-------|
| **Current Baseline** | 38.5% (154 customers) |
| **Q2 2026 Target** | 25.0% |
| **Stretch Goal** | 20.0% |
| **Monitor** | Weekly |
| **Owner** | Product Team |

**Why this metric:**  
It is a **leading indicator of churn**—predicting cancellations 30-60 days before they occur. When this rate drops, churn will follow. Calculate it monthly, segment by plan type, and trigger immediate intervention if it exceeds 35%.

---

## Results

### Priority Recommendations

| Priority | Action | Target | Expected Impact |
|----------|--------|--------|----------------|
| 1 | Activation campaign for 154 zero-activity customers | Zero-Activity Rate: 39% → 25% | ~20 churns prevented/quarter |
| 2 | Reduce billing support resolution time | Resolution: 12hrs → 6hrs SLA | Support churn: 30% → 22% |
| 3 | Improve Free-to-paid conversion | Free churn: 41% → 30% | 11-16 conversions/quarter |

### Business Impact

- **Current churn rate:** 28.5% (114 customers)
- **Annual revenue lost:** $52,908
- **Target churn rate:** 20.0% by Q2 2026
- **Estimated annual savings:** $17,400 (if target achieved)

### KPI Summary

| Metric | Baseline | Target | Monitor |
|--------|----------|--------|---------|
| Overall Churn Rate | 28.5% | 20.0% | Monthly |
| Zero-Activity Rate | 38.5% | 25.0% | Weekly |
| First Activity Rate (D14) | 62.0% | 75.0% | Weekly |
| Billing Resolution Time | 12.0 hrs | 6.0 hrs | Daily |
| Billing SLA Compliance | 39.7% | 80.0% | Daily |
| Free Plan Churn Rate | 41.0% | 30.0% | Monthly |
| Free-to-Paid Conversion | Track now | 8.0% | Monthly |

---

*Analysis conducted using R | Data covers June–December 2025 | 400 customers across Free, Basic, Pro, and Enterprise plans*
