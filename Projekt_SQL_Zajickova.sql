#Vytvoøení základní tabulky_countries, covid19_basic_differences, life_expectancy
create view v_zakl_tabulka as 
 with countries_diff as (
 select distinct 
 cbd.date,
 CASE WHEN cbd.date <= '2020-03-19' THEN 3
		 WHEN cbd.date >= '2020-03-20' AND cbd.date <= '2020-06-19' THEN 0
		 WHEN cbd.date >= '2020-06-20' AND cbd.date <= '2020-09-21' THEN 1
		 WHEN cbd.date >= '2020-09-22' AND cbd.date <= '2020-12-20' THEN 2
		 WHEN cbd.date >= '2020-12-21' AND cbd.date <= '2021-03-19' THEN 3
		 ELSE 'error'
		 END AS season,
	case when WEEKDAY(cbd.date) in (5, 6) then 1 else 0 end as weekend,
 c.country,
 c.capital_city,
 cbd.confirmed,
 c.population,
 c.population_density,
 c.median_age_2018
 from countries c  
 inner join covid19_basic_differences cbd 
 on c.country = cbd.country  
),
doba_doziti as (
SELECT a.country, a.life_exp_1965 , b.life_exp_2015,
    round( b.life_exp_2015 - a.life_exp_1965, 2 ) as life_exp_ratio
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
)
select 
cd.*,
dd.life_exp_ratio
from countries_diff cd
left join doba_doziti dd 
on cd.country=dd.country;
 
 
# GDP pro rok 2019 a gini pro rok 2017
create view v_ekonom_tabulka as
with gdp_2019 as (
select 
 year,
 country,
 population,
 round(gdp / population, 2) as GDP_per_person,
 mortaliy_under5 as child_mortality
from economies e
where `year` = '2019'
group by year,
 country,
 population,
 mortaliy_under5 
 ),
gini_2017 as (
select 
	country,
	year,
	gini
from economies e
where year = '2017'
)
select
g19.country,
g19.GDP_per_person,
g17.gini
from gdp_2019 g19
left join gini_2017 g17
on g19.country = g17.country;

#Spojení tabulek výše
create view v_zakl_tabulka_eko_covidtest as
select 
	vzb.*,
	ct.tests_performed, 
	vet.GDP_per_person,
	vet.gini
from v_zakl_tabulka vzb
left join v_ekonom_tabulka vet
on vzb.country = vet.country
left join covid19_tests ct 
on vet.country = ct.country and vzb.date = ct.date;

create view v_variables_weather as
SELECT
	city,
	replace (date, '00:00:00', '') as date,
	COUNT(time) *3 AS rain_hours,
	(select round ( AVG(temp),2) AS avegera_temp 
	FROM weather w 
	where time IN ('06:00', '09:00', '12:00', '15:00', '18:00', '21:00')) as avg_day_temp,
	MAX (gust) AS max_wind
FROM weather w
WHERE city IS NOT NULL AND rain != '0.0 mm'
GROUP BY city, date;

#Finální tabulka bez podílu náboženství
create view v_fin_tabulka_without_religions as
select 
	vztec.*,
	vvw.rain_hours,
	vvw.avg_day_temp,
	vvw.max_wind
from v_zakl_tabulka_eko_covidtest vztec 
left join v_variables_weather vvw
on vztec.capital_city = vvw.city and vztec.date = vvw.date;

create view v_s_religions as
select a.country, a.Christianity,b.Hinduism, c.Buddhism, d.Judaism, e.Islam, 
f.Folk_Religions, g.Unaffiliated_Religions, h.Other_Religions
	from (
	select r.country, r.population  as Christianity
	from religions r 
	where religion = 'Christianity' and year = '2020'
	) a join (
	select r.country, r.population as Hinduism
	from religions r
	where religion = 'Hinduism' and year = '2020'
	) b 
	on a.country = b.country
	join (
	select r.country, r.population as Buddhism
	from religions r
	where religion = 'Buddhism' and year = '2020'
	) c 
	on b.country=c.country
	join (
	select r.country, r.population as Judaism
	from religions r
	where religion = 'Judaism' and year = '2020'
	) d
	on c.country = d.country
	join (
	select r.country, r.population as Islam
	from religions r
	where religion = 'Islam' and year = '2020'
	) e 
	on d.country = e.country
	join (
	select r.country,r.population as Folk_Religions
	from religions r
	where religion = 'Folk Religions' and year = '2020'
	) f 
	on e.country = f.country
	join (
	select r.country, r.population as Unaffiliated_Religions
	from religions r
	where religion = 'Unaffiliated Religions' and year = '2020'
	) g
	on f.country = g.country
	join (
	select r.country, r.population as Other_Religions
	from religions r
	where religion = 'Other Religions' and year = '2020'
	) h
	on g.country = h.country;

create view v_religions_share as
select 
	c.country, c.population,
	round (vrs.Christianity / c.population,2 ) *100 as Share_Christianity, 
	round (vrs.Hinduism / c.population,2 ) *100 as Share_Hinduism , 
	round (vrs.Judaism / c.population,2 ) *100 as Share_Judaism, 
	round (vrs.Islam / c.population,2 ) *100 as Share_Islam, 
	round (vrs.Folk_Religions / c.population,2 ) *100 as Share_Folk_Religions, 
	round (vrs.Unaffiliated_Religions / c.population,2 ) *100 as Share_Unaffiliated_Religions,
	round (vrs.Other_Religions / c.population,2 ) *100 as Share_Other_Religions
	from countries c
	left join v_s_religions vrs
	on c.country = vrs.country;

create view_Projekt_SQL_final_Zajickova
select 
vftwr.*,
vrs.Share_Christianity,
vrs.Share_Hinduism,
vrs.Share_Judaism,
vrs.Share_Islam,
vrs.Share_Folk_Religions,
vrs.Share_Unaffiliated_Religions,
vrs.Share_Other_Religions
from v_fin_tab_without_religions vftwr
left join v_religions_share vrs
on vftwr.country = vrs.country

