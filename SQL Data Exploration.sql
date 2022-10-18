/*

Covid 19 Data Exploration

Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4;

Select *
From PortfolioProject..CovidVaccinations
order by 3,4;

Select Location, date, Total_cases, New_cases, Total_deaths, Population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2;


-- Looking at Total Cases vs Total Deaths
-- Likelihood of dying if you contract Covid19 in Australia

Select Location, date, Total_cases, Total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where Location like '%Australia%'
and continent is not null
Order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population got Covid19 in Australia and the Philippines

Select Location, date, Population, Total_cases, (total_cases/population) * 100 as CovidContractionPercentage
From PortfolioProject..CovidDeaths
Where Location in ('Australia', 'Philippines')
and continent is not null
Order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, Max(Total_cases) as HighestInfectionCount, max((total_cases/population)) * 100 as HighestInfectionPercentage
From PortfolioProject..CovidDeaths
--Where Location in ('Australia', 'Philippines')
Group by location, population 
Order by HighestInfectionPercentage desc


-- Countries with Highest Death count per Population

Select Location, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Location 
Order by TotalDeathCount desc


-- BREAK THINGS DOWN BY CONTINENT

-- Continents with the highest death count per population

Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent 
Order by TotalDeathCount desc

Select location, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
Group by location 
Order by TotalDeathCount desc


-- Global numbers

Select date, Sum(new_cases) as TotalNewCases, Sum(cast(new_deaths as int)) as New_Deaths, Sum(cast(Total_deaths as int)) as Total_Deaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2;


Select date, Sum(new_cases) as TotalNewCases, Sum(cast(new_deaths as int)) as New_Deaths, Sum(cast(new_deaths as int))/Sum(new_cases) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2;


-- Death Percentage around the world

Select Sum(new_cases) as TotalNewCases, Sum(cast(new_deaths as int)) as New_Deaths, 
Sum(cast(new_deaths as int))/Sum(new_cases) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2




-- Total Population vs Vaccinations
-- Adding new_vaccinations count per location and date as RollingVaccinationCount

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(cast(vac.new_vaccinations as int)) over (partition by dea.location Order by dea.location, dea.date) as RollingVaccinationCount			
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by  2,3;

-- or
/*
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(CONVERT(int, vac.new_vaccinations,)) over (partition by dea.location order by dea.location, 
dea.date) as RollingVaccinationCount			
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by  2,3
*/



-- Using CTE (Population vs Vaccination) 
-- Performing Calculation on Partition By from previous query
-- Using RollingVaccinationCount in determining Vaccination Percentage against total population
-- Remove comment on dea.location for location specific querying

with PopVsVac (continent, location, date, population, new_vaccinations, RollingVaccinationCount)
as(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	Sum(cast(vac.new_vaccinations as int)) over (partition by dea.location Order by dea.location, dea.date) as RollingVaccinationCount			
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
-- and dea.location like '%Australia%' or dea.location = 'Australia'
)

Select *, (RollingVaccinationCount/population) * 100 as VaccinatedPercentage
From PopVsVac


-- Using Temp Table to perform Calculation on Partition By from Previous query

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_Vaccination numeric,
RollingVaccinationCount numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	Sum(cast(vac.new_vaccinations as int)) over (partition by dea.location Order by dea.location, dea.date) as RollingVaccinationCount			
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingVaccinationCount/Population) * 100 as VaccinatedPercentage
From #PercentPopulationVaccinated
Order by Location


-- Creating View to store data for later visualizations


Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	Sum(cast(vac.new_vaccinations as int)) over (partition by dea.location Order by dea.location, dea.date) as RollingVaccinationCount			
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null;


Create View DailyWorldDeathPercentage as
Select date, Sum(new_cases) as TotalNewCases, Sum(cast(new_deaths as int)) as New_Deaths, Sum(cast(new_deaths as int))/Sum(new_cases) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date;



Create View DailyTotalDeaths as
Select date, Sum(new_cases) as TotalNewCases, Sum(cast(new_deaths as int)) as New_Deaths, Sum(cast(Total_deaths as int)) as Total_Deaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date;


Create View HighestContinentDeathCount as
Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent;


-- Checking all created views

Select *
From PercentPopulationVaccinated


Select *
From DailyWorldDeathPercentage


Select *
From DailyTotalDeaths


Select *
From HighestContinentDeathCount