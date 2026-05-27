# Case Study #1: Danny's Diner

## Context

Danny's Diner is a small Japanese restaurant that opened in early 2021, 
serving sushi, curry, and ramen. Danny collected basic data on his 
customers but doesn't have the SQL skills to turn it into actionable 
insights. He wants to understand customer behavior, specifically their 
spending patterns, visit frequency, and favorite items, to inform 
decisions about expanding his loyalty program.

This case study is part of [Danny Ma's 8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-1/).

## Business Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?

## Data Schema

The dataset consists of three tables:

- **sales**: customer transactions with order date and product ID
- **menu**: product catalog with prices
- **members**: customers enrolled in the loyalty program with join date

## Tools Used

- **MySQL 8.0** for database and query execution
- **MySQL Workbench** as the SQL IDE

## Key Findings

| # | Question | Key Finding |
|---|---|---|
| 1 | Total spend per customer | A and B spent ~$75 each; C spent $36 (half) |
| 2 | Visit frequency | B is most frequent (6 days); A visits less but with larger baskets |
| 3 | First item per customer | Sushi/curry for A, curry for B, ramen for C |
| 4 | Most popular item | Ramen dominates (8 purchases, ~2x the next product) |
| 5 | Favorite per customer | A and C love ramen; B has a 3-way tie (diverse palate) |
| 6 | First post-membership purchase | Both A and B purchased shortly after joining |
| 7 | Last pre-membership purchase | Sushi appears in both customers' final pre-member orders |
| 8 | Pre-membership behavior | Both members showed consistent interest before signing up |
| 9 | Loyalty points (sushi 2x) | B leads (940 pts), then A (860), then C (360) |
| 10 | Points end-of-January | A: 1,370 / B: 820 — first-week bonus boosts onboarding |

## Business Insights

**1. Customer segmentation is uneven.**  
Customers A and B behave similarly in spend but differently in frequency. Customer C is a low-engagement outlier — a clear target for upsell campaigns. Danny shouldn't treat all customers the same.

**2. Ramen is the franchise driver.**  
It's the most purchased item overall AND the favorite of two out of three customers. Promotions, bundles, and supply forecasting should center on ramen.

**3. The current loyalty design favors sushi buyers.**  
The 2x multiplier on sushi gives customer B (a sushi buyer) a structural advantage. This may or may not align with Danny's strategic intent — worth reviewing.

**4. The first-week 2x bonus drives behavior.**  
Customer A's high points total at the end of January reflects multiple purchases in their first member week. The onboarding incentive is doing what it should — convert new members into active ones.

## Technical Reflections

- **Window functions were essential** for questions involving "first/last/most popular per customer". `RANK()`, `PARTITION BY`, and subqueries to filter on rank were used throughout.

- **`RANK()` vs `ROW_NUMBER()` matters.** I consistently used `RANK()` to preserve legitimate ties (e.g., a customer purchasing two items on the same day). Using `ROW_NUMBER()` would arbitrarily hide one of them, falsifying the answer.

- **Data cleanliness was not a challenge here** (this is a tutorial dataset), but I'm carrying forward the discipline of clear assumptions and explicit comments into Case Study #2 (Pizza Runner), which involves significant data cleaning.

