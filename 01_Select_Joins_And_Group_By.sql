-- ============================================================
--Topic 1: SELECT, JOINS & GROUP BY
-- ============================================================

--Q1.1: Multi-Edition Gold Medalists in Summer Sports
--Find all female athletes (sex = 'F') who have won a Gold medal in at least 2 distinct Summer Olympic editions.
--Output columns: athlete_id, full_name, count_of_summer_editions
--Requirements: Exclude any Winter editions. Join from athletes through results to editions. Ensure you count distinct edition_ids, not just total gold medal rows.

SELECT a.athlete_id, a.full_name, COUNT(DISTINCT e.edition_id) AS count_of_summer_editions
FROM athletes a 
LEFT JOIN results r
ON a.athlete_id=r.athlete_id
LEFT JOIN editions e
ON r.edition_id=e.edition_id
WHERE a.sex='Female' AND e.season='Summer' AND r.medal='Gold'
GROUP BY 1,2
HAVING COUNT(DISTINCT e.edition_id)>=2

--Q1.2: Dual-Season Dominance by Country
--Identify all countries (country_name in nocs) that won at least 1 medal in both 'Summer' and 'Winter' seasons within the same calendar year (edition_year).
--Output columns: country_name, edition_year, summer_medals, winter_medals, total_medals
--Requirements: Use conditional aggregation (IFF or CASE WHEN) to count non-null medals per season per year.

SELECT n.country_name, e.edition_year, 
SUM(CASE WHEN season='Summer' AND medal IS NOT NULL THEN 1 ELSE 0 END) AS summer_medals, 
SUM(CASE WHEN season='Winter' AND medal IS NOT NULL THEN 1 ELSE 0 END) AS winter_medals, 
SUM(CASE WHEN medal IS NOT NULL THEN 1 ELSE 0 END) AS total_medals
FROM nocs n
LEFT JOIN results r 
ON n.noc=r.noc_id 
LEFT JOIN editions e
ON r.edition_id=e.edition_id
GROUP BY 1,2
HAVING summer_medals>=1 AND winter_medals>=1

--Q1.3: Athletic Profile Benchmarks by Sports Group
--Calculate the average height and weight of medal-winning athletes (Gold, Silver, or Bronze) grouped by sports_group_name.
--Output columns: sports_group_name, avg_height_cm, avg_weight_kg, total_medalist_records
--Requirements: Join athletes  results  events  disciplines  sport_groups. Filter out records where height_cm or weight_kg is NULL. Filter the final aggregated group results to show only sports groups where avg_height_cm is strictly greater than 180.0 cm.

SELECT s.sports_group_name, AVG(a.height_cm) AS avg_height_cm, AVG(a.weight_kg) AS avg_weight_kg, COUNT(r.medal) AS total_medalist_records
FROM athletes a
JOIN results r
ON a.athlete_id = r.athlete_id
JOIN events e
ON r.event_id = e.event_id
JOIN disciplines d
ON e.discipline_id = d.discipline_id
JOIN sport_groups s
ON d.sports_group_id = s.sports_group_id
WHERE r.medal IS NOT NULL AND a.height_cm IS NOT NULL AND a.weight_kg IS NOT NULL
GROUP BY 1
HAVING avg_height_cm > 180

--Q1.4: Solo vs. Team Country Performance
--Compare solo vs. team medal performance for each country era (country_era in nocs).
--Output columns: country_era, solo_medals, team_medals, total_medals
--Requirements: Filter out rows where medal IS NULL. Aggregate solo medals (team_or_solo = 'solo') and team medals (team_or_solo = 'team'). Include only country eras that have won at least 20 total combined medals.

SELECT country_era, SUM(CASE WHEN team_or_solo='Solo' THEN 1 ELSE 0 END) AS solo_medals, SUM(CASE WHEN team_or_solo='Team' THEN 1 ELSE 0 END) AS  team_medals, COUNT(medal) AS total_medals
FROM nocs n
JOIN results r
ON n.noc=r.noc_id
WHERE medal IS NOT NULL
GROUP BY 1
HAVING total_medals >=20

--Q1.5: Multi-Discipline Medalists in a Single Edition
--Find all athletes who won medals in more than one distinct discipline during the same Olympic edition.
--Output columns: athlete_id, full_name, edition_id, edition_year, distinct_disciplines_count
--Requirements: Join athletes, results, events, disciplines, and editions. Group by athlete and edition, and use HAVING COUNT(DISTINCT discipline_id) > 1.

SELECT a.athlete_id, a.full_name, ed.edition_id, ed.edition_year, COUNT(DISTINCT d.discipline_id) AS distinct_disciplines_count
FROM athletes a
JOIN results r
ON a.athlete_id=r.athlete_id
JOIN editions ed
ON r.edition_id=ed.edition_id
JOIN events e
ON r.event_id=e.event_id
JOIN disciplines d
on e.discipline_id=d.discipline_id
WHERE medal IS NOT NULL
GROUP BY 1,2,3,4
HAVING distinct_disciplines_count>1

--Q1.6: Country Success in Discontinued Events
--List all countries (country_name) that have won at least 5 medals in events that are now discontinued (is_event_discontinued = TRUE).
--Output columns: country_name, discontinued_gold_count, total_discontinued_medals
--Requirements: Join nocs, results, and events. Use conditional aggregation to break down discontinued gold medals versus total discontinued medals.

SELECT n.country_name, SUM(IFF(r.medal = 'Gold', 1, 0)) AS discontinued_gold_count, SUM(IFF(r.medal IS NOT NULL, 1, 0)) AS total_discontinued_medals
FROM nocs n
JOIN results r
ON n.noc = r.noc_id
JOIN events e
ON r.event_id = e.event_id
WHERE e.is_event_discontinued = TRUE 
GROUP BY 1
HAVING total_discontinued_medals >= 5