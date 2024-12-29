-- First import the excel file into the database
USE [Covid-19 Project];

-- We'll be looking at the COVID-19 data from 2020-2024 (for * countries)
-- Checking if were able to import all of the data


SELECT*
FROM [Covid-19 Project]..covid_deaths;

SELECT*
FROM [Covid-19 Project]..covid_vaccinations;

-- Data we will be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Covid-19 Project]..covid_deaths
ORDER BY 1,2


--Looking at total_cases v/s total_deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM [Covid-19 Project]..covid_deaths
ORDER BY 1,2;


-- Looking at total_cases v/s total_deaths in India

SELECT location, date, total_cases, total_deaths, new_cases
FROM [Covid-19 Project]..covid_deaths
WHERE location LIKE 'India'
ORDER BY 2;


--Looking at total_cases v/s population
--Shows how much % of the population of India got COVID-19

SELECT location, date, total_cases, population, (total_cases/population)*100 AS population_infected
FROM [Covid-19 Project]..covid_deaths
WHERE location LIKE 'India' AND total_cases IS NOT NULL
ORDER BY 4 DESC;


-- Looking at countries with the highest infection rate compared to their population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM [Covid-19 Project]..covid_deaths
GROUP BY location, population
ORDER BY 4 DESC;


-- Looking at countries with the highest death rate compared to their population

SELECT location, population, MAX((total_deaths/population))*100 AS percent_population_died
FROM [Covid-19 Project]..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC;


-- Looking at countries with the highest death count

SELECT location, MAX(total_deaths) AS highest_death_count
FROM [Covid-19 Project]..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;


-- CONTINENTS DATA **(This dataset had data for groups/unions of countries too so counting that also)**
-- Looking at continents with the highest death count

SELECT continent, MAX(total_deaths) AS max_death_count
FROM [Covid-19 Project]..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;


-- Looking at continents with the highest infection rate
SELECT continent, MAX(total_cases) AS max_infection_count, MAX((total_cases/population))*100 AS infection_rate
FROM [Covid-19 Project]..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 3 DESC;



-- GLOBAL NUMBERS
-- Looking at the total number of cases/death/death_percentage in the world
SELECT SUM(total_cases) AS total_cases, SUM(total_deaths) AS total_deaths, (SUM(total_deaths)/SUM(total_cases))*100 AS death_percentage
FROM [Covid-19 Project]..covid_deaths
WHERE continent IS NOT NULL;


-- Looking at the number of cases/death in the world

SELECT date, SUM(new_cases) AS daily_cases, SUM(new_deaths) AS daily_deaths
FROM [Covid-19 Project]..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


-- Joining death table to vaccination table 
-- Looking at total population v/s vaccinations

-- Changing the coloumn size in the table
ALTER TABLE covid_deaths
ALTER COLUMN date nvarchar(150)


-- Looking at Total population vs Vaccinations
-- Using CTE
-- in CTE, no. of columns should be equal to the original table

WITH POPvsVAC (Continent, Location, Date, Population, NewVaccinations,RollingPeopleVaccinated)
AS
(
SELECT DISTINCT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
From covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVacciated
FROM POPvsVAC
ORDER BY 2,3


-- Using TEMP Table
-- Drop command can be added so that you can make multiple iterations and no error
-- occurs because a table exists. 

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric, 
New_Vaccination numeric,
Rolling_People_Vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT DISTINCT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
From covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
SELECT *, (Rolling_People_Vaccinated/Population)*100 AS Percent_Population_Vaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2,3



-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION
CREATE VIEW ContinentWithHighestInfectionRate
AS
SELECT continent, MAX(total_cases) AS max_infection_count, MAX((total_cases/population))*100 AS infection_rate
FROM [Covid-19 Project]..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent;
SELECT * 
FROM ContinentWithHighestInfectionRate
ORDER BY 3 DESC

CREATE VIEW Death_Percentage
AS
SELECT SUM(total_cases) AS total_cases, SUM(total_deaths) AS total_deaths, (SUM(total_deaths)/SUM(total_cases))*100 AS death_percentage
FROM [Covid-19 Project]..covid_deaths
WHERE continent IS NOT NULL;
SELECT *
FROM Death_Percentage

CREATE VIEW Percent_Population_Vaccinated
AS
SELECT DISTINCT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
From covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
SELECT * 
FROM Percent_Population_Vaccinated
ORDER BY 2,3
