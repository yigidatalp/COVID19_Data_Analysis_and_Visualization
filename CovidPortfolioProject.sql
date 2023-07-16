--SELECT *
--FROM CovidDeaths
--WHERE continent IS NOT NULL
--ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

--SELECT Location, date, total_cases, new_cases, total_deaths, population
--FROM CovidDeaths
--WHERE continent IS NOT NULL
--ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying
SELECT SUM(CAST(new_cases as int)) total_cases, SUM(CAST(new_deaths as int)) total_deaths, 
100*(SUM(CAST(new_deaths as float))/SUM(CAST(new_cases as float))) death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Total Deaths per continents
SELECT location, SUM(CAST(new_deaths as int)) total_deaths
FROM CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' AND location NOT IN ('World', 'European Union')
GROUP BY location
ORDER BY 2 DESC

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, 
(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 DeathPercentage
FROM CovidDeaths
--WHERE location = 'Turkey'
WHERE continent IS NOT NULL AND (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 IS NOT NULL
ORDER BY 1, 2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT location, date, total_cases, population, 
(CAST(total_cases AS float)/population)*100 PercentPopulationInfectedPerDate
FROM CovidDeaths
WHERE continent IS NOT NULL AND (CAST(total_cases AS float)/population)*100 IS NOT NULL
ORDER BY 1, 2

-- Looking at countries with the Highest Infection Rate compared to Population
SELECT location, population, MAX(CAST(total_cases AS float)) highest_infection_count,  
100*(MAX(CAST(total_cases AS float))/population) percent_population_infected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
-- HAVING (MAX(CAST(total_cases AS float))/population)*100 IS NOT NULL
ORDER BY 4 DESC

-- Looking at countries with the Highest Infection Rate compared to Population by date
SELECT location, population, date, MAX(CAST(total_cases as float)) highest_infection_count, 
100*(MAX(CAST(total_cases AS float))/population) percent_population_infected
FROM CovidDeaths
GROUP BY location, population, date
ORDER BY 5 DESC

-- Showing Countries with the Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS float)) HighestDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
HAVING MAX(CAST(total_deaths AS float)) IS NOT NULL
ORDER BY HighestDeathCount DESC

-- Showing Continents with the Highest Death Count
SELECT location, MAX(CAST(total_deaths AS float)) HighestDeathCount
FROM CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' AND location NOT IN ('World', 'European Union')
GROUP BY location
ORDER BY HighestDeathCount DESC

-- GLOBAL NUMBERS
SELECT SUM((CAST(new_cases AS float))) TotalNewCases, 
SUM((CAST(new_deaths AS float))) TotalNewDeaths,
(SUM((CAST(new_deaths AS float)))/SUM((CAST(new_cases AS float))))*100 DeathPercentage 
FROM CovidDeaths
WHERE continent IS NOT NULL

-- Looking at Total Population vs Vaccinations 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL

-- USE CTE
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopVsVac

-- USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated 
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_Vaccinations nvarchar(255),
RollingPeopleVaccinated float
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating a view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated