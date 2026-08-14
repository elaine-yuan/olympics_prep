# olympics_prep
This repository is a collection of AI-generated SQL challenges and their solutions. The challenges were generated based on an ERD of the Olympics dataset.

## Overview
Database: Olympics
SQL dialect: Snowflake SQL
Number of challenges: 24

## Topics Covered
1. [SELECT, JOINS & GROUP BY](https://github.com/elaine-yuan/olympics_prep/blob/main/01_Select_Joins_And_Group_By.sql): Joins, filtering, aggregation, conditional aggregation
2. [DATE MATH & TIMELINE LOGIC](https://github.com/elaine-yuan/olympics_prep/blob/main/02_Date_Math_And_Timeline_Logic.sql): DATEDIFF(), date extraction, Olympic timelines, age calculations
3. [PERCENT OF TOTAL & AGG-OF-AGGS](https://github.com/elaine-yuan/olympics_prep/blob/main/03_Pct_of_Total_And_Agg_of_Aggs.sql): Percentages, ratios, window sums, aggregate-of-aggregates
4. WINDOW FUNCTIONS & RANKING: LAG(), LEAD(), ranking, running totals, percentiles

## Database Schema

The analysis uses a relational Olympics database containing information about:
* Athletes
* Countries / NOCs
* Olympic editions
* Sports groups
* Disciplines
* Events
* Results

<img width="1141" height="691" alt="olympics erd" src="[https://github.com/user-attachments/assets/c69d9ba8-66a8-48ca-8060-14f0a9d25dd6](https://github.com/elaine-yuan/olympics_prep/blob/main/olympics_erd.png?raw=true)" />
