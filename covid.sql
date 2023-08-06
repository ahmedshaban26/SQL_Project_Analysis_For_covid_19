use PortfolioProject

-- Select data that we are going to be using

select location , date , total_cases , new_cases , total_deaths , population
from CovidDeaths
where continent is not null
order by 1,2

-- looking at Total Cases Vs Toata Deaths

select location , date , total_cases , total_deaths , (cast( total_deaths as float)  / total_cases) * 100 as TotalPercentage
from CovidDeaths
where continent is not null
order by 1,2

-- looking at Total Cases Vs Toata Deaths With Filtering by Country

alter function totalCasesForLocation (@country varchar(20))
returns table
as
	return (
			select location , date , total_cases , total_deaths , (cast( total_deaths as float)  / total_cases) * 100 as TotalPercentage
			from CovidDeaths
			where location = @country and continent is not null
			)

-- example 1 ---> filtering by Egypt
select * from dbo.totalCasesForLocation('Egypt')

-- Example 2 ---> filtering by united states
select * from dbo.totalCasesForLocation('united states')

-- looking at cantries with highest infection rate compare to population

select location , population , max(cast(total_cases as int)) as HighestInfetionCount , 
max((total_cases / population)) * 100 as PercentagePopulationInfected
from CovidDeaths
where continent is not null
-- where location = 'united states'
group by location , population
order by PercentagePopulationInfected desc


-- looking at cantries with highest death count per population

select location , max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

-- Global percentage of death to new cases by every day

select date , sum(new_cases) as Total_Cases , 
sum(new_deaths) as Total_Deaths , sum(new_deaths) / nullif(sum(new_cases),0) * 100  as DeathPercentage
from CovidDeaths
where continent is not null 
group by date
order by 1,2


-- Egypt percentage of death to new cases by every day

create view VEgypt
as
select date , sum(new_cases) as Total_Cases , 
sum(new_deaths) as Total_Deaths , sum(new_deaths) / nullif(sum(new_cases),0) * 100  as DeathPercentage
from CovidDeaths
where continent is not null and location= 'egypt'
group by date

select * from VEgypt
order by date

-- The top 10 countries with the highest number of Infection cases

select top(10) location , sum(cast(total_cases as float)) from CovidDeaths
where continent is not null
group by location
order by 2 desc

-- Top 10 countries with the highest number of deaths
select top(10) location , sum(cast(total_deaths as float)) from CovidDeaths
where continent is not null
group by location
order by 2 desc


-- CTE

with PopVsVac (continent , location , date , population, new_vaccinations ,RollingPeopleVaccinated)
as (
select c.continent , c.location , c.date , c.population , v.new_vaccinations ,
sum(cast(v.new_vaccinations as int)) over(partition by c.location , c.date) as RollingPeopleVaccinated
from CovidDeaths c
join CovidVaccinations v
	on c.location = v.location
	and c.date = v.date
where c.continent is not null
--order by 2,3
)
select * ,(RollingPeopleVaccinated/population) * 100 
from PopVsVac


-- looking at cantries with  smoker percentage and death percentage

select c.location , sum(cast(c.total_cases as float)) as TotalCases, sum(cast(c.total_deaths as float)) TotalDeaths,
(Sum(cast(v.male_smokers as float)) + Sum(cast(v.female_smokers as float))) / sum (c.population) as SmokerPercentage ,
sum(cast(c.total_deaths as float)) / sum(cast(c.total_cases as float)) *100 PercentageOfDeath
from CovidVaccinations v
join CovidDeaths c
	on c.location = v.location
	and c.date = v.date
where c.continent is not null
group by c.location
order by SmokerPercentage desc