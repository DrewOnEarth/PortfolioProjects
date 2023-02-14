/*
Exploring Data from Covid 19, vaccinations and deaths

Skills used: Aggregate Functions, Joins, Temp Tables, Creating Views, Converting Data Type
/*

--Viewing Data in the Covid_Deaths dataset

SElECT *
FROM Covid_Portfolio_Project..Covid_Deaths
WHERE continent is not null
ORDER BY 3,4

--Selecting data that we will be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Portfolio_Project..Covid_Deaths
WHERE continent is not null 
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract Covid 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM Covid_Portfolio_Project..Covid_Deaths
WHERE location = 'United States'
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS Confirmed_Cases_Percentage
FROM Covid_Portfolio_Project..Covid_Deaths
--WHERE location = 'United States'
ORDER BY 1,2

--Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS Confirmed_Cases_Percentage
FROM Covid_Portfolio_Project..Covid_Deaths
GROUP BY location, population
ORDER BY Confirmed_Cases_Percentage DESC

--Showing the countries with the highest Death Count per Population

SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM Covid_Portfolio_Project..Covid_Deaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Let's break things down by continent
--Shows continents with highest death count

SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM Covid_Portfolio_Project..Covid_Deaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Global Numbers, Total Cases, Total Deaths and Death Percentage

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM Covid_Portfolio_Project..Covid_Deaths
WHERE continent is not null


--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM Covid_Portfolio_Project..Covid_Deaths AS dea
JOIN Covid_Portfolio_Project..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3	
 
-- Use CTE to perform calculation using Partition By

WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM Covid_Portfolio_Project..Covid_Deaths AS dea
JOIN Covid_Portfolio_Project..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3	
)
SELECT *, (Rolling_People_Vaccinated/population)*100 AS Rolling_People_Vaccinated_Percent
FROM PopvsVac


-- Using Temp Table to perform calculation on Partition By

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM Covid_Portfolio_Project..Covid_Deaths AS dea
JOIN Covid_Portfolio_Project..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3	

SELECT *, (Rolling_People_Vaccinated/population) * 100
FROM #PercentPopulationVaccinated


--Creating View to store data for later visualizations

USE Covid_Portfolio_Project
GO
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM Covid_Portfolio_Project..Covid_Deaths AS dea
JOIN Covid_Portfolio_Project..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
