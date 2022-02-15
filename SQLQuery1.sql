


-- Total cases and death count across the world

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths as int)) AS TotalDeaths, SUM(CAST(total_deaths AS int))/SUM(total_cases) * 100 AS DeathPercent
FROM CovidProject..CovidDeaths
WHERE continent is not null


--Total Deaths v/s Total cases (with date)

SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)* 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
--AND location like '%india%' (Remove comment and enter country of interest)
ORDER BY 1,2


-- Total cases v/s Total Population

SELECT location, date, population, total_cases, total_deaths, (total_cases/population)* 100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
WHERE continent is not null
--AND location like '%india%'
ORDER BY 1,2


--Countries with highest infection rate against population

SELECT location, population, MAX(total_cases) AS HighestCaseCount, (MAX(total_cases)/population)*100 AS InfectionRatePercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
Order by InfectionRatePercentage DESC


--Countries with highest death count

SELECT location, MAX(total_cases) as TotalCaseCount, MAX(CAST(total_deaths as int)) AS TotalDeathsCount
From CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathsCount DESC


--Continents with highest death count

SELECT continent, SUM(CAST(new_deaths as int)) as DeathCount
FROM CovidProject..CovidDeaths
WHERE continent is not null
Group by continent
Order by DeathCount DESC


-- Now we join CovidDeaths and CovidVaccination tables and find some interesting insights

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS dea
JOIN CovidProject..CovidVaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY dea.location, dea.date


-- Let's check out % of people vaccinated in the given population
-- NOTE: We couldn't perform the calculation above because we need to create a temporary table or CTE because we can't use the column we just created

WITH PercentPopulationVaccinated (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS dea
JOIN CovidProject..CovidVaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (RollingPeopleVaccinated/population) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated
ORDER BY 2,3



-- Let's checkout countries with highest fully vaccination percentage v/s population

SELECT location, population, MAX(CAST(people_fully_vaccinated AS int)) as FullyVaccinated, (MAX(CAST(people_fully_vaccinated AS int)/population)) * 100 AS VacPercent
FROM CovidProject..CovidVaccination
WHERE continent is not null
GROUP BY location, population
ORDER BY VacPercent DESC



-- Now let's join the CovidDeaths and CovidExtraData tables

SELECT *
FROM CovidProject..CovidExtraData as ed
JOIN CovidProject..CovidDeaths as dea
	ON ed.location = dea.location
	AND ed.date = dea. date
WHERE dea.continent is not null
ORDER BY ed.location


-- Now we find if there's any correltion between the total cases with a county's GDP, human development index and population density

WITH totals as (
SELECT dea.location, MAX(dea.population) as TotalPopulation, MAX(CAST(dea.total_cases as int)) as cases
, MAX(CAST(dea.total_deaths as int)) as total_deaths , MAX(human_development_index) AS DEVindex
FROM CovidProject..CovidExtraData as ed
JOIN CovidProject..CovidDeaths as dea
	ON ed.location = dea.location
	AND ed.date = dea. date
WHERE dea.continent is not null
	AND ed.gdp_per_capita is not null
group by dea.location)
--ORDER BY cases DESC)

SELECT location, TotalPopulation, cases, total_deaths, DEVindex, (cases/TotalPopulation) as infection_rate
FROM totals
GROUP BY location, TotalPopulation, cases, total_deaths, DEVindex
ORDER BY infection_rate desc

-- It does look like there's a trend. My observations are that inection rate is directly proportional to human development index.
-- We could look at GDP and population density too just by replacing DEVindex with the other two or we could just add those columns.
-- However, I am going to stop here, create some views and conclude the project.

CREATE VIEW PercentVaccinated as
WITH PercentPopulationVaccinated (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS dea
JOIN CovidProject..CovidVaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (RollingPeopleVaccinated/population) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated


SELECT *
FROM PercentVaccinated


                                                              --CONCLUSION--


