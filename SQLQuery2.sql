--showing percentage chance of death if contracted with covid in Australia
select location,format(date,'yyyy-MM-dd') as date,[total_cases]
     ,[total_deaths],([total_deaths]/[total_cases])*100 as chances_death from  AnalystPortfolio..CovidDeaths
	  where  location = 'australia'
	  order by 2 desc;

--showing total cases vs population
--percentage of population got covid
select location,max([total_cases]) as Total_Cases
      ,max([total_deaths]) as Total_Deaths,(max([total_cases])/max(population))*100 as percent_population_infected from  AnalystPortfolio..CovidDeaths
	  where continent is not null
	  group by location
	  order by percent_population_infected desc;

--showing countries with highest death toll in percentage 
select location,max([total_cases]) as Total_Cases
      ,max([total_deaths]) as Total_Deaths,(max([total_deaths])/max(population))*100 as percent_death_count from  AnalystPortfolio..CovidDeaths
	  where continent is not null
	  group by location
	  order by [total_deaths] desc;

--countries with total deaths
select location,max([total_deaths]) as Total_Deaths from  AnalystPortfolio..CovidDeaths
	  where continent is not null
	  group by location
	  order by [total_deaths] desc;

--continents with total deaths

select continent,max([total_deaths]) as Total_Deaths from  AnalystPortfolio..CovidDeaths
	  where continent is not null	group by continent;
	
--total deaths in Australia and new zealand
select location= 'Australia(continent)' , sum(t.tot) as Total_Deaths from 
(select Location , max([total_deaths]) as tot from 
CovidDeaths group by location having location in ('Australia','new zealand')) as t;

--total deaths in Australia Continent
select cont='Australian Continent', sum(t.tot) as totalDeaths from
(select max([total_deaths]) as tot from  AnalystPortfolio..CovidDeaths where continent= 'oceania' group by location) as t;

--global deaths recorded on each day

select date as Date, sum(new_cases) as Total_Cases_on_date,sum(new_deaths) as Total_deaths
  ,sum(new_deaths)/sum(new_cases)*100 as percentagedeath from AnalystPortfolio..CovidDeaths 
  where continent is not null
group by date  
having sum(total_deaths) is not null and sum(new_cases) <>0   order by percentagedeath desc;

--global total death 
select  sum(new_cases) as Total_Cases_on_date,sum(new_deaths) as Total_deaths
  ,sum(new_deaths)/sum(new_cases)*100 as percentagedeath from AnalystPortfolio..CovidDeaths 
where continent is not null 
--select *  from  AnalystPortfolio..CovidDeaths

--countries with highest death per population
select location,max(population) as Population,max(total_deaths) as Deaths
,(max(total_deaths)/max(population))*100 as DeathPerPopulation from AnalystPortfolio..CovidDeaths
 where continent is not null
group by location order by Deaths desc ;
 
select * from AnalystPortfolio..CovidVaccinations;
--vaccinated people in australia
select d.continent,d.location,d.date,v.people_vaccinated
from AnalystPortfolio..CovidDeaths d
inner join AnalystPortfolio..CovidVaccinations v
on d.date=v.date and d.location= v.location
 where d.continent is not null and d.location ='australia'
order by 2,3;

--%people fully vaccinated  in countries
select d.location,max(d.date) as Date,max(d.population) as Population ,max(v.people_fully_vaccinated) as People_Vaccinated
,(max(v.people_fully_vaccinated)/max(d.population))*100 as percentage_vaccinated
from AnalystPortfolio..CovidDeaths d
inner join AnalystPortfolio..CovidVaccinations v
on d.date=v.date and d.location= v.location
 where d.continent is not null 
 group by d.location
order by percentage_vaccinated desc;

--create view for above query(%people fully vaccinated  in countries)
drop view if exists V_fully_vaccinated_ppl_countries
create view
V_fully_vaccinated_ppl_countries
as
select d.location,max(d.population) as Population ,max(v.people_fully_vaccinated) as People_Vaccinated
,(max(v.people_fully_vaccinated)/max(d.population))*100 as percentage_vaccinated
from AnalystPortfolio..CovidDeaths d
inner join AnalystPortfolio..CovidVaccinations v
on d.date=v.date and d.location= v.location
 where d.continent is not null 
 group by d.location;

 select * from V_fully_vaccinated_ppl_countries order by percentage_vaccinated desc


--rolling count for new vaccination
select d.continent, d.location,d.date,d.population,v.new_vaccinations
,sum(convert(int,v.new_vaccinations)) over (partition by d.location order by d.location,d.date ) as RollingCount_vaccination
from AnalystPortfolio..CovidDeaths d
inner join AnalystPortfolio..CovidVaccinations v
on d.date=v.date and d.location= v.location
 where d.continent is not null 
 --group by d.location
order by 2,3 ;
--use cte % people vaccinated per day per country
with cte as(
select d.continent, d.location,d.date,d.population,v.new_vaccinations
,sum(convert(int,v.new_vaccinations)) over (partition by d.location order by d.location,d.date ) as RollingCount_vaccination
from AnalystPortfolio..CovidDeaths d
inner join AnalystPortfolio..CovidVaccinations v
on d.date=v.date and d.location= v.location
 where d.continent is not null 
 --group by d.location

)
select continent, location,date,population
,new_vaccinations,RollingCount_vaccination,(RollingCount_vaccination/population)*100 as percentage_vaccinated from cte
order by 2,3 ;

-- % people vaccinated till date
--create temp table
drop table if exists #temp_percent_people_vaccinated; 
create table #temp_percent_people_vaccinated
(continent nvarchar(250)
, location nvarchar(250)
,date datetime
,population int
,new_vaccinations int
,RollingCount_vaccination float
)

insert into #temp_percent_people_vaccinated
select d.continent, d.location,d.date,d.population,v.new_vaccinations
,sum(convert(int,v.new_vaccinations)) over (partition by d.location order by d.location,d.date ) as RollingCount_vaccination
from AnalystPortfolio..CovidDeaths d
inner join AnalystPortfolio..CovidVaccinations v
on d.date=v.date and d.location= v.location
 where d.continent is not null; 

 select * from #temp_percent_people_vaccinated where location='china'

 select max(location),max(population) as Population,max(RollingCount_vaccination) as Vaccinations
 , (max(RollingCount_vaccination)/ max(population))*100 as percent_vaccinated
 from #temp_percent_people_vaccinated 
 group by location order by percent_vaccinated desc;