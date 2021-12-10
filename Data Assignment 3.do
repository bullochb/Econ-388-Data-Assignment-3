*log file open
log using data_assignment_3_log, replace

********************************************************************
*Start off, cd into folder
********************************************************************
clear
* get into my directly
cd "C:\Users\Brayden Bulloch\OneDrive - BYU\Econ 388\Data Assignment 3"
*make sure to save each file as csv


********************************************************************
*Population Data
********************************************************************
*import csv from census data.
*this data was very hard for me to find.
*I add a year column just using excel. Excuse my laziness
import delimited using "census-pop-by-county - copy.csv", clear

*give v1 v2 and v3 new names 
rename v1 geoID
rename v2 county
rename v4 population
rename v6 year
keep geoID county population year

drop if _n<3

* keep only most recent population data. 2019
destring year, replace force
keep if year==2019


*create fips variable
gen fips = substr(geoID, 10, 5)
destring fips, replace
destring population, replace

*delete unwanted columns
keep geoID county population fips

*save that joint
save "census-pop-by-county.dta", replace


********************************************************************
*NY Times Case/Death Data
********************************************************************
* import the data from the NY Times site
import delimited using "CovidDeaths.csv", clear
keep geoid county state cases deaths

*create fips variable
gen fips = substr(geoid,5,5)
drop geoid
destring fips, replace
*collapse that cheese
collapse (sum) cases deaths (min) fips, by (county state)

*save that cheese
save "CovidDeaths.dta", replace



********************************************************************
*HPI Data
********************************************************************
import delimited using "HPI_with_3_digit_zip_code.csv", clear

*this step is a mess. Come back here and fix 
rename indexnsa HPI
rename ïthreedigitzip threedigitzip
destring threedigitzip, replace force
destring year, replace force
keep if year==2021
destring HPI, replace
collapse HPI, by(year threedigitzip)
save "HPI_with_3_digit_zip_code.csv.dta", replace


********************************************************************
*Zip County Cross Walk
********************************************************************
import delimited using "crosswalk.csv", clear
keep ïzip county
rename ïzip zipcode
tostring(zipcode), gen(zipcode1)
drop zipcode
gen threedigitzip = substr(zipcode1,1,3)
drop zipcode1
destring threedigitzip, replace

save "crosswalk.dta", replace




********************************************************************
*Start merging
********************************************************************
*merge census population data to the NYTimes Covid data
use "census-pop-by-county.dta", clear
merge 1:1 fips using "CovidDeaths.dta"
keep if _m==3
drop _m
save "Population Covid Deaths.dta",replace


*merge that HPI stuff with crosswalk
*we will be merging threedigitzip
use "HPI_with_3_digit_zip_code.csv.dta", clear
merge 1:m threedigitzip using "crosswalk.dta"
keep if _m==3
drop _m
collapse HPI, by(county)
rename county fips
save "Zip HPI.dta", replace

*merge this onto the Population/Deaths data
merge 1:1 fips using "Population Covid Deaths.dta"
keep if _m==3
drop _m


gen mortalityrate = (deaths/population)*100

*save combined data set
save "Big Data.dta", replace


********************************************************************
*Actual Analysis
********************************************************************
*read in data now, to avoid running everything above
use "Big Data.dta", clear


*basic regression
reg HPI mortalityrate


*regression by state
encode(state), gen(statenum)

reg HPI mortalityrate i.statenum population cases
*output to excel
outreg2 using datatables, replace excel

*run regression for loghpi mortalityrate i.statenum
*make this bad boy a log for different interpretation
gen loghpi = log(HPI)

reg loghpi mortalityrate i.statenum

*close log file
log close
