-- ============================================================
--Topic 2: DATE MATH & TIMELINE LOGIC
-- ============================================================

--Q2.1: Youngest Solo Gold Medalist
--Calculate the age (in years) of each athlete on the day their Olympic edition's opening ceremony started (opening_ceremony_date). Determine who the youngest athletes were to win a Gold medal in a solo event.
--Output columns: athlete_id, full_name, event_name, edition_year, age_at_opening
--Requirements: Use Snowflake’s DATEDIFF('year', date_of_birth, opening_ceremony_date). Filter for medal = 'Gold' and team_or_solo = 'solo'.

SELECT a.athlete_id, a.full_name, e.event_name, ed.edition_year, DATEDIFF('year', date_of_birth, opening_ceremony_date) AS age_at_opening
FROM athletes a JOIN results r ON a.athlete_id=r.athlete_id
JOIN editions ed ON r.edition_id=ed.edition_id
JOIN events e ON r.event_id=e.event_id
WHERE medal='Gold' AND team_or_solo='Solo'
ORDER BY age_at_opening

--Q2.2: Post-Olympic Lifespan Analysis
--Identify athletes who passed away (date_of_death IS NOT NULL) within 10 years (3,652 days) of the competition_end_date of their last recorded Olympic appearance.
--Output columns: athlete_id, full_name, last_competition_end_date, date_of_death, days_lived_after_last_olympics
--Requirements: Group by athlete to find their maximum competition_end_date. Compute the date difference in days between that max date and date_of_death.

SELECT a.athlete_id, a.full_name, MAX(ed.competition_end_date) AS last_competition_end_date, a.date_of_death, DATEDIFF('day',MAX(ed.competition_end_date), a.date_of_death) AS days_lived_after_last_olympics
FROM athletes a JOIN results r ON a.athlete_id=r.athlete_id
JOIN editions ed ON r.edition_id=ed.edition_id
WHERE date_of_death IS NOT NULL
GROUP BY 1,2,4
HAVING days_lived_after_last_olympics<3652

--Q2.3: Games Duration vs. Season Average
--Find all Olympic editions where the total length of the competition (from competition_start_date to competition_end_date) was strictly longer than the average competition duration for that specific season.
--Output columns: edition_id, season, edition_year, host_city, edition_duration_days, season_avg_duration_days
--Requirements: Use DATEDIFF('day', competition_start_date, competition_end_date) combined with a window average or subquery.

WITH cte AS(
SELECT ed.edition_id, ed.season, ed.edition_year, ed.host_city, DATEDIFF('day',competition_start_date, competition_end_date) AS edition_duration_days, ROUND(AVG(DATEDIFF('day',competition_start_date, competition_end_date)) OVER(PARTITION BY ed.season),1) AS season_avg_duration_days
FROM editions ed
)
SELECT * FROM cte
WHERE edition_duration_days>season_avg_duration_days

--Q2.4: Longevity Span Across Olympics
--Identify athletes who competed across a career time span of 16 years or more between their first Olympic competition start date and their last Olympic competition start date.
--Output columns: athlete_id, full_name, first_competition_start, last_competition_start, career_span_years, total_editions_attended
--Requirements: Calculate DATEDIFF('year', MIN(competition_start_date), MAX(competition_start_date)) grouped by athlete.

SELECT a.athlete_id, a.full_name, MIN(ed.competition_start_date) AS first_competition_start, MAX(ed.competition_start_date) AS last_competition_start, DATEDIFF('year', MIN(competition_start_date), MAX(competition_start_date)) AS career_span_years, COUNT(DISTINCT ed.edition_id) AS total_editions_attended
FROM athletes a JOIN results r ON a.athlete_id=r.athlete_id
JOIN editions ed ON r.edition_id=ed.edition_id
GROUP BY 1,2
HAVING career_span_years>=16

--Q2.5: Birth Month Seasonality of Medalists
--Determine if there is a birth-month preference among medalists. Calculate total medal counts grouped by the athlete's birth month (1–12).
--Output columns: birth_month, month_name, total_gold_medals, total_medals
--Requirements: Use Snowflake’s MONTH(date_of_birth) or EXTRACT(month FROM date_of_birth). Exclude athletes whose date_of_birth is NULL.

SELECT MONTH(a.date_of_birth) AS birth_month, MONTHNAME(a.date_of_birth) AS month_name, SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS total_gold_medals, SUM(CASE WHEN medal IS NOT NULL THEN 1 ELSE 0 END) AS total_medals
FROM athletes a JOIN results r ON a.athlete_id=r.athlete_id
WHERE date_of_birth IS NOT NULL
GROUP BY 1,2

--Q2.6: Host City Preparation Lag
--Calculate the gap in days between the opening_ceremony_date and the competition_start_date for each edition.
--Output columns: edition_id, edition_year, host_city, opening_ceremony_date, competition_start_date, days_gap
--Requirements: Use DATEDIFF('day', opening_ceremony_date, competition_start_date). Order the results to find editions where competitions started before or significantly after the opening ceremony.

SELECT edition_id, edition_year, host_city, opening_ceremony_date, competition_start_date, DATEDIFF('day', opening_ceremony_date, competition_start_date) AS days_gap
FROM editions ed
ORDER BY days_gap
