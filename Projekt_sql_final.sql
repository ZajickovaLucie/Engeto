#vytvoøení základní tabulky a economies promìnné - bez dožití

CREATE VIEW v_countries_economies AS 
select 
	c.country,
	c.capital_city,
	e.population,
	c.population_density,
	c.median_age_2018, 
	e.gini,
	e.GDP /1000000 as GDP_mil,
	ROUND (r.population / c.population *100, 2) AS share_religion,
	e.mortaliy_under5
from countries c 
left join economies e
on c.country = e.country
left join religions r 
ON e.country = r.country
group by e.country,c.capital_city,e.population, c.population_density,c.median_age_2018,
	e.gini,e.GDP /1000000,	e.mortaliy_under5

#tabulka covid19_basic_differences  a covid19_tests
CREATE VIEW v_cdif_ctests AS 
select 
	cbd.date,
	cbd.country,
	cbd.confirmed,
	ct.tests_performed
from covid19_basic_differences cbd 
left join covid19_tests ct 
on cbd.country = ct.country

#spojení tabulek výše
CREATE VIEW v_vce_vcc AS 
select 
 vcc.date,
 vce.*,
 vcc.confirmed,
 vcc.tests_performed
 from v_countries_economies vce 
 left join v_cdif_ctests vcc 
 on vce.country = vcc.country
 where date is not null

 #vytvoøení tabulky s oèekávanou délkou dožití
 CREATE VIEW v_life_expectancy_1965_2015 AS 
 SELECT a.country, a.life_exp_1965 , b.life_exp_2015,
    round( b.life_exp_2015 - a.life_exp_1965, 2 ) as life_exp_growth
FROM (
    SELECT le.country , le.life_expectancy as life_exp_1965
    FROM life_expectancy le 
    WHERE year = '1965'
    ) a JOIN (
    SELECT le.country , le.life_expectancy as life_exp_2015
    FROM life_expectancy le 
    WHERE year = '2015'
    ) b
    ON a.country = b.country

 
#vytvoøení tabulky s úkolem è. 2 a pøidání k pøedešlé v_vce_vcc   
    
CREATE VIEW v_variables_23 AS
 select 
 	vvv.*,
 	CASE WHEN vvv.date <= '2020-03-19' THEN 3
		 WHEN vvv.date >= '2020-03-20' AND vvv.date <= '2020-06-19' THEN 0
		 WHEN vvv.date >= '2020-06-20' AND vvv.date <= '2020-09-21' THEN 1
		 WHEN vvv.date >= '2020-09-22' AND vvv.date <= '2020-12-20' THEN 2
		 WHEN vvv.date >= '2020-12-21' AND vvv.date <= '2021-03-19' THEN 3
		 ELSE 'error'
		 END AS season,
	case when WEEKDAY(vvv.date) in (5, 6) then 1 else 0 end as weekend,
 	vle.life_exp_growth
from v_vce_vcc vvv 
left join v_life_expectancy_1965_2015 vle
on vvv.country = vle.country
 
	
#ukol è. 3 - vytvoøení tabulky
CREATE VIEW v_weather_variable  AS
SELECT
	city,
	replace (date, '00:00:00', '') as date,
	COUNT(time) *3 AS rain_hours,
	(SELECT AVG(temp) AS avegera_temp 
	FROM weather w 
	where time IN ('06:00', '09:00', '12:00', '15:00', '18:00', '21:00') ) as avg_tep,
	MAX (gust) AS max_wind
FROM weather w
WHERE city IS NOT NULL AND rain != '0.0 mm'
GROUP BY city, date

select * from v_weather_variable

create table projekt_sql as
select 
vv23.*,
vwv.rain_hours,
vwv.avg_tep,
vwv.max_wind
from v_variables_23 vv23
left join v_weather_variable vwv 
on vv23.capital_city = vwv.city
where vwv.max_wind is not null



