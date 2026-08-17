-- ============================================================
--Topic 4: WINDOW FUNCTIONS & RANKING
-- ============================================================

--Q4.1: Top 3 Athletes per Sports Group (Using QUALIFY)
--Find the top 3 athletes with the most Gold medals in each sports_group_name. Break ties using total overall medals.
--Output columns: sports_group_name, athlete_rank, full_name, gold_medals, total_medals
--Requirements: Use DENSE_RANK() or ROW_NUMBER() over PARTITION BY sports_group_id ORDER BY gold_count DESC, total_count DESC. You must use Snowflake's QUALIFY clause to filter the rank directly without wrapping the query in an inner subquery.

SELECT sg.sports_group_name, DENSE_RANK() OVER(PARTITION BY sports_group_name ORDER BY SUM(IFF(medal='Gold', 1, 0)) DESC) AS athlete_rank, a.full_name, SUM(IFF(medal='Gold', 1, 0)) AS gold_medals, SUM(IFF(medal IS NOT NULL, 1, 0)) AS total_medals
FROM sport_groups sg JOIN disciplines d ON sg.sports_group_id=d.sports_group_id 
JOIN events e ON d.discipline_id=e.discipline_id
JOIN results r ON e.event_id=r.event_id
JOIN athletes a ON r.athlete_id=a.athlete_id
GROUP BY 1,3
QUALIFY athlete_rank<=3;

--Q4.2: Trajectory & Consecutive Edition Performance (LAG)
--Track an athlete's medal performance across consecutive editions within the same sport discipline.
--Output columns: full_name, discipline_name, edition_year, current_medal, prev_edition_year, prev_medal
--Requirements: Use LAG(edition_year) and LAG(medal) window functions partitioned by athlete_id and discipline_id, ordered by edition_year. Filter out athletes who have only competed in a single edition for that discipline.

WITH cte AS
(SELECT a.full_name, d.discipline_name, ed.edition_year, medal AS current_medal,  LAG(edition_year) OVER(PARTITION BY a.athlete_id, d.discipline_id ORDER BY edition_year) AS prev_edition_year, LAG(medal) OVER(PARTITION BY a.athlete_id, d.discipline_id ORDER BY edition_year) AS prev_medal, COUNT(*) OVER(PARTITION BY a.athlete_id, d.discipline_id) AS edition_count
FROM athletes a JOIN results r ON a.athlete_id=r.athlete_id
JOIN editions ed ON r.edition_id=ed.edition_id
JOIN events e ON r.event_id=e.event_id
JOIN disciplines d ON e.discipline_id=d.discipline_id)
SELECT full_name, discipline_name, edition_year, current_medal, prev_edition_year, prev_medal
FROM cte
WHERE edition_count>1
ORDER BY 1,2,3;

--Q4.3: First Ever Medal per Country
--Identify the exact edition, event, and medal type when each country (country_name) won its first-ever Olympic medal.
--Output columns: country_name, first_medal_year, event_name, medal
--Requirements: Use ROW_NUMBER() OVER (PARTITION BY noc_id ORDER BY edition_year ASC, opening_ceremony_date ASC) combined with QUALIFY row_num = 1. Filter for non-null medals.

SELECT n.country_name, ed.edition_year AS first_medal_year, event_name, medal
FROM nocs n LEFT JOIN results r ON n.noc=r.noc_id 
LEFT JOIN editions ed ON r.edition_id=ed.edition_id
LEFT JOIN events e ON r.event_id=e.event_id
WHERE medal IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY noc_id ORDER BY edition_year ASC, opening_ceremony_date ASC)=1;

--Q4.4: Cumulative Medal Tally Over Time (Running Total)
--Create a historical running cumulative sum of Gold medals won by each country across Summer Olympic editions over time.
--Output columns: country_name, edition_year, gold_medals_in_edition, cumulative_gold_medals
--Requirements: Aggregate gold medals by country and edition year first. Then apply SUM(gold_medals_in_edition) OVER (PARTITION BY country_name ORDER BY edition_year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW).

WITH gold_medals AS
(
SELECT n.country_name, ed.edition_year, SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS gold_medals_in_edition
FROM nocs n LEFT JOIN results r ON n.noc=r.noc_id 
LEFT JOIN editions ed ON r.edition_id=ed.edition_id
WHERE season='Summer'
GROUP BY 1,2
)
SELECT *, SUM(gold_medals_in_edition) OVER (PARTITION BY country_name ORDER BY edition_year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_gold_medals
FROM gold_medals;

--Q4.4: NOC Medal Rankings by Olympic Edition
--Rank each country's NOC by its total number of medals within each Olympic edition.Return the top 3 NOCs for each edition, breaking ties by gold medals,then silver medals, then bronze medals.
--Output columns: edition_id, country_name, noc_rank, total_medals, gold_medals, silver_medals, bronze_medals
--Requirements: Aggregate medals by edition_id and noc_id. Use RANK() or DENSE_RANK() with PARTITION BY edition_id. ORDER BY total_medals DESC, gold_medals DESC, silver_medals DESC, bronze_medals DESC.Use Snowflake's QUALIFY clause to filter for the top 3 NOCs per edition.

WITH medals AS
(
SELECT e.edition_id, n.country_name, SUM(CASE WHEN medal IS NOT NULL THEN 1 ELSE 0 END) AS total_medals, SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS gold_medals,SUM(CASE WHEN medal='Silver' THEN 1 ELSE 0 END) AS silver_medals, SUM(CASE WHEN medal='Bronze' THEN 1 ELSE 0 END) AS bronze_medals
FROM nocs n JOIN results r ON n.noc=r.noc_id
JOIN editions e ON r.edition_id=e.edition_id
GROUP BY 1,2
)
SELECT edition_id, country_name,RANK() OVER(PARTITION BY edition_id ORDER BY total_medals DESC, gold_medals DESC, silver_medals DESC, bronze_medals DESC) AS noc_rank, total_medals, gold_medals, silver_medals, bronze_medals
FROM medals
QUALIFY noc_rank<=3;

--Q4.6: Percentile Rank of Athlete Height within Discipline
--For each discipline, calculate the height percentile of each medalist relative to all other medalists in that same discipline.
--Output columns: discipline_name, full_name, height_cm, height_percentile
--Requirements: Use PERCENT_RANK() OVER (PARTITION BY discipline_id ORDER BY height_cm ASC). Exclude athletes where height_cm is NULL.

SELECT d.discipline_name, a.full_name, a.height_cm, ROUND(PERCENT_RANK() OVER (PARTITION BY d.discipline_name ORDER BY height_cm ASC)*100,2) AS height_percentile
FROM athletes a JOIN results r ON a.athlete_id=r.athlete_id
JOIN editions ed ON r.edition_id=ed.edition_id
JOIN events e ON r.event_id=e.event_id
JOIN disciplines d ON e.discipline_id=d.discipline_id
WHERE height_cm IS NOT NULL
GROUP BY 1,2,3;