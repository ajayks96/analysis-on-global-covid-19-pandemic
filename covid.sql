/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT 
	location,
    str_to_date(date,"%d/%m/%Y") as date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM coviddeaths_new
ORDER BY 1,2


-- DEATH RATE 
-- LIKLYHOOD OF YOU DYING IN YOUR COUNTRY

SELECT 
	location,
    str_to_date(date,"%d/%m/%Y") as date,
    total_cases,
    CAST(total_deaths AS FLOAT),
    (total_deaths/total_cases)*100 as Deathpresentage
FROM coviddeaths_new
WHERE location LIKE '%INDIA%'
ORDER BY 1,2

-- LOOKING AT TOTAL CASES VS POPULATION
-- SHOWS THE COVID INFECTION RATE

SELECT 
	location,
    str_to_date(date,"%d/%m/%Y") as date,
    total_cases,
    population,
    (total_cases/population)*100 as InfectionRate
FROM coviddeaths_new
WHERE location LIKE '%INDIA%'
ORDER BY 1,2 DESC

-- LOOKING AT COUNTRY WITH HIGHEST INFECTION RATE

SELECT 
	location,
    -- str_to_date(date,"%d/%m/%Y") as date,
    MAX(total_cases),
    population,
    MAX((total_cases / population) * 100) as InfectionRate
FROM coviddeaths_new
GROUP BY location ,population
ORDER BY InfectionRate DESC

-- SHOWING COUNRTYS WITH HIGHEST DEATH COUNT PER POPULATON

SELECT 
	location,
    MAX(CAST(total_deaths AS FLOAT)) AS TotalDeathCount
FROM coviddeaths_new
WHERE TRIM(continent) <> ""
GROUP BY location 
ORDER BY TotalDeathCount DESC

-- lets break it down into continent
-- continent with highest DeathCount

SELECT 
	location,
    MAX(CAST(total_deaths AS FLOAT)) AS TotalDeathCount
FROM coviddeaths_new
WHERE TRIM(continent) = ""
GROUP BY location 
ORDER BY TotalDeathCount DESC

-- global numbers
-- per day

SELECT 
    str_to_date(date,"%d/%m/%Y") as Date,
    SUM(new_cases) AS TotalNewCases,
    SUM(CAST(new_deaths AS FLOAT)) AS TotalNewDeaths,
    SUM(CAST(new_deaths AS FLOAT)) / SUM(new_cases) * 100 AS Deathpresentage
FROM coviddeaths_new
WHERE TRIM(continent) <> "" OR continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- total

SELECT 
    SUM(new_cases) AS TotalNewCases,
    SUM(CAST(new_deaths AS FLOAT)) AS TotalNewDeaths,
    SUM(CAST(new_deaths AS FLOAT)) / SUM(new_cases) * 100 AS Deathpresentage
FROM coviddeaths_new
WHERE TRIM(continent) <> "" OR continent IS NOT NULL
ORDER BY 1,2

-- LOOKING AT TOTAL POPULATION VS VACCINATION


SELECT 
	DEA.continent, 
	DEA.location, 
    DEA.date, 
    DEA.population, 
    VAC.new_vaccinations,
    SUM(CAST(VAC.new_vaccinations AS FLOAT)) OVER (PARTITION BY VAC.location order by DEA.location, DEA.date) as RollingPeopleVaccinated
FROM coviddeaths_new DEA
JOIN covidvaccin VAC
	ON DEA.location = VAC.location
    AND DEA.date = DEA.date
WHERE TRIM(DEA.continent) <> "" OR DEA.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(select
DEA.continent, 
	DEA.location, 
    DEA.date, 
    DEA.population, 
    VAC.new_vaccinations,
    SUM(CAST(VAC.new_vaccinations AS FLOAT)) OVER (PARTITION BY VAC.location order by DEA.location, DEA.date) as RollingPeopleVaccinated
FROM coviddeaths_new DEA
JOIN covidvaccin VAC
	ON DEA.location = VAC.location
    AND DEA.date = DEA.date
WHERE TRIM(DEA.continent) <> "" OR DEA.continent IS NOT NULL
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select DEA.continent, 
	DEA.location, 
    DEA.date, 
    DEA.population, 
    VAC.new_vaccinations,
    SUM(CAST(VAC.new_vaccinations AS FLOAT)) OVER (PARTITION BY VAC.location order by DEA.location, DEA.date) as RollingPeopleVaccinated
FROM coviddeaths_new DEA
JOIN covidvaccin VAC
	ON DEA.location = VAC.location
    AND DEA.date = DEA.date
WHERE TRIM(DEA.continent) <> "" OR DEA.continent IS NOT NULL
Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select DEA.continent, 
	DEA.location, 
    DEA.date, 
    DEA.population, 
    VAC.new_vaccinations,
    SUM(CAST(VAC.new_vaccinations AS FLOAT)) OVER (PARTITION BY VAC.location order by DEA.location, DEA.date) as RollingPeopleVaccinated
FROM coviddeaths_new DEA
JOIN covidvaccin VAC
	ON DEA.location = VAC.location
    AND DEA.date = DEA.date
WHERE TRIM(DEA.continent) <> "" OR DEA.continent IS NOT NULL