-- ============================================================
--Topic 3: PERCENT OF TOTAL & AGG-OF-AGGS
-- ============================================================

--Q3.1: Medal Distribution Breakdown per Country
--For each country (country_name), calculate the total number of medals won, along with the percentage breakdown of Gold, Silver, and Bronze medals relative to that country's grand total.
--Output columns: country_name, total_medals, pct_gold, pct_silver, pct_bronze
--Requirements: Use Snowflake’s DIV0() function to protect against division-by-zero. Include only countries with at least 50 total medals. Format percentages rounded to 2 decimal places.

SELECT n.country_name,
SUM(IFF(r.medal IS NOT NULL, 1, 0)) AS total_medals,
ROUND(DIV0NULL(SUM(IFF(r.medal='Gold', 1, 0)), SUM(IFF(r.medal IS NOT NULL, 1, 0))) * 100, 2) AS pct_gold,
ROUND(DIV0NULL(SUM(IFF(r.medal='Silver', 1, 0)), SUM(IFF(r.medal IS NOT NULL, 1, 0))) * 100, 2) AS pct_silver,
ROUND(DIV0NULL(SUM(IFF(r.medal='Bronze', 1, 0)), SUM(IFF(r.medal IS NOT NULL, 1, 0))) * 100, 2) AS pct_bronze
FROM nocs n JOIN results r ON n.noc=r.noc_id
GROUP BY 1
HAVING total_medals >= 50

--Q3.2: Discipline Efficiency (Avg Medals per Participant)
--Calculate the average number of medals won per athlete for each discipline, but only for disciplines where total athlete participation exceeds 200 distinct athletes.
--Output columns: discipline_name, distinct_athletes, total_medals, medals_per_athlete
--Requirements: An aggregate-of-aggregates problem. First aggregate total distinct athlete_ids and non-null medal counts by discipline_id inside a CTE/subquery, then compute the ratio and filter by participant threshold.

WITH cte AS 
(
SELECT d.discipline_name, COUNT(DISTINCT r.athlete_id) AS distinct_athletes, SUM(IFF(r.medal IS NOT NULL, 1, 0)) AS total_medals
FROM disciplines d JOIN events e ON d.discipline_id=e.discipline_id
JOIN results r ON e.event_id=r.event_id
GROUP BY 1
)
SELECT *, total_medals/distinct_athletes AS medals_per_athlete
FROM cte
WHERE distinct_athletes>200

--Q3.3: Country Share of Total Medals Per Edition
--For each Summer Olympic edition, calculate each participating country’s share of total medals awarded in that specific edition using RATIO_TO_REPORT() or window sums.
--Output columns: edition_year, country_name, country_medals, edition_total_medals, pct_share_of_edition
--Requirements: Group results by edition_year and country_name, then apply RATIO_TO_REPORT(country_medals) OVER (PARTITION BY edition_year) * 100.

SELECT ed.edition_year, n.country_name, SUM(IFF(r.medal IS NOT NULL, 1, 0)) AS country_medals,
SUM(SUM(IFF(r.medal IS NOT NULL, 1, 0))) OVER (PARTITION BY ed.edition_year) AS edition_total_medals,
ROUND(RATIO_TO_REPORT(SUM(IFF(r.medal IS NOT NULL, 1, 0))) OVER (PARTITION BY ed.edition_year) * 100, 2) AS pct_share_of_edition
FROM nocs n JOIN results r ON n.noc = r.noc_id
JOIN editions ed ON r.edition_id = ed.edition_id
WHERE ed.season = 'Summer'
GROUP BY 1,2

--Q3.4: Sports Group Contribution to NOC Total
--Find each NOC's top sports group (by medal count) and calculate what percentage of the NOC's total all-time medals came from that single sports group.
--Output columns: country_name, sports_group_name, group_medals, noc_total_medals, pct_of_noc_total
--Requirements: Aggregate medals by noc_id and sports_group_id. Calculate SUM(group_medals) OVER (PARTITION BY noc_id) to get NOC totals, then calculate the proportion.

WITH cte AS
(
SELECT n.country_name, sg.sports_group_name, SUM(IFF(r.medal IS NOT NULL, 1, 0)) AS group_medals, SUM(SUM(IFF(r.medal IS NOT NULL, 1, 0))) OVER (PARTITION BY n.country_name) AS noc_total_medals
FROM nocs n JOIN results r ON n.noc = r.noc_id
JOIN events e ON r.event_id=e.event_id
JOIN disciplines d ON e.discipline_id=d.discipline_id
JOIN sport_groups sg ON d.sports_group_id=sg.sports_group_id
GROUP BY 1,2
),
ranked AS 
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY country_name ORDER BY group_medals DESC) AS rn
FROM cte
)
SELECT country_name, sports_group_name, group_medals, noc_total_medals, ROUND(DIV0NULL(group_medals,noc_total_medals)*100,2) AS pct_of_noc_total
FROM ranked
WHERE rn=1

--Q3.5: Gender Medal Ratio Trends Over Time
--For each edition year, calculate the percentage of total medals awarded to female athletes versus male athletes.
--Output columns: edition_year, season, female_medals, male_medals, pct_female_medals
--Requirements: Use DIV0() alongside conditional aggregation COUNT(IFF(sex = 'F', 1, NULL)) divided by total non-null medals in that edition.

SELECT e.edition_year, e.season, SUM(IFF(a.sex='Female' AND r.medal IS NOT NULL, 1, 0)) AS female_medals, SUM(IFF(a.sex='Male' AND r.medal IS NOT NULL, 1, 0)) AS male_medals,
ROUND(DIV0NULL(SUM(IFF(a.sex = 'Female' AND r.medal IS NOT NULL, 1, 0)), SUM(IFF(r.medal IS NOT NULL, 1, 0)))*100, 2) AS pct_female_medals
FROM athletes a JOIN results r ON a.athlete_id = r.athlete_id
JOIN editions e ON r.edition_id = e.edition_id
GROUP BY 1, 2

--Q3.6: Discontinued Event Medal Concentration
--Determine the percentage of a country's total historical medal count that was derived from discontinued events.
--Output columns: country_name, discontinued_medals, total_all_time_medals, pct_from_discontinued
--Requirements: Join nocs, results, and events. Use DIV0() to calculate (discontinued_medals / total_all_time_medals) * 100. Filter for countries with at least 10 discontinued event medals.

SELECT country_name, SUM(IFF(is_event_discontinued AND medal IS NOT NULL, 1, 0)) AS discontinued_medals, SUM(IFF(r.medal IS NOT NULL, 1, 0)) AS total_all_time_medals,ROUND(DIV0NULL(SUM(IFF(is_event_discontinued AND medal IS NOT NULL, 1, 0)), SUM(IFF(r.medal IS NOT NULL, 1, 0)))*100, 2)  pct_from_discontinued
FROM nocs n JOIN results r ON n.noc=r.noc_id 
JOIN events e ON r.event_id=e.event_id
GROUP BY 1
HAVING discontinued_medals>=10
