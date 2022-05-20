/*******************************************************************************
	
	Step 2. Merging cleaned SaO2 & SpO2 datasets to create a dataset of  
	SaO2-SpO2 pairs measured within 10 min
	
	Author: 		S Seelye
	
	Date Created: 	5 AUG 2021
	Date Updated: 	5 AUG 2021
	
*******************************************************************************/	
 
clear all
cap more off
version 16.0

cd ""


* note: pulse ox dataset is too large for stata's memory to handle; 
*		create spo2-sao2 pairs separately by year and then append dataset  
 

forval i=2013/2019 { 

* pull in cleaned sao2 dataset that does not contain duplicates
use Data\sao2_cleaned, clear 

* only keep one year of data at a time
gen datevalue = dofc(labchemspecimendatetime)
format datevalue %tdD_m_Y 
gen year = year(date)
keep if year==`i'

* organize dataset 
destring patienticn, replace
format patienticn %12.0g

keep patienticn labchemspecimendatetime year datevalue labchemresultnumericvalue lab 
order patienticn labchemspecimendatetime year datevalue labchemresultnumericvalue lab 

* append spo2 dataset for the same year
append using Data\spo2_`i'_20210727
sort patienticn datevalue 

* organize the dataset such that all of the sao2s and spo2s are in chronological 
* order based on the time of measurement 

* first, create a new datetime variable that brings together sao2 & spo2 datetimes 
gen double datetime_sao2spo2 = labchemspecimendatetime
replace datetime_sao2spo2 = vitalsigntakendatetime if datetime_sao2spo2==.
format datetime_sao2spo2 %tc

sort patienticn datetime_sao2spo2

* identify patient-days that have both a sao2 & spo2
gen sao2spo2_ind = "."
replace sao2spo2_ind = "sao2" if lab=="sao2"
replace sao2spo2_ind = "spo2" if spo2!=.

* identify observations within patient-days that have a different lab/vital 
* type from the one before it (ie, alternating between sao2 & spo2)
bysort patienticn datevalue (datetime_sao2spo2): gen sao2spo2_patday = 1 if sao2spo2_ind!=sao2spo2_ind[_n-1] & _n!=1 //this identifies values that alternate between spo2 & sao2 - ie, NOT two of the same labs/vitals chronologically next to each other

bysort patienticn datevalue: egen sao2spo2_patday_ind = max(sao2spo2_patday)

* drop patient-days that do not have both a sao2 and spo2 
drop if sao2spo2_patday_ind == .

* bring the prior datetime forward; we will do this so that we can have a 
* wide dataset with the paired datetime values and lab/vital value on the same row
bysort patienticn datevalue (datetime_sao2spo2): gen double prior_datetime_sao2spo2 = datetime_sao2spo2[_n-1] if sao2spo2_patday==1
format prior_datetime_sao2spo2 %tc

* bring the prior label forward to identify sao2/spo2
bysort patienticn datevalue (datetime_sao2spo2): gen prior_sao2spo2_ind = sao2spo2_ind[_n-1] if sao2spo2_patday==1

* create a new variable that includes both spo2 and sao2 values; we will use 
* this to bring the prior value forward for the wide dataset.
gen sao2spo2_values = .
replace sao2spo2_values = labchemresultnumericvalue if lab=="sao2"
replace sao2spo2_values = spo2 if sao2spo2_ind=="spo2"

*bring prior sao2 & spo2 values forward
bysort patienticn datevalue (datetime_sao2spo2): gen prior_sao2spo2_values = sao2spo2_values[_n-1] if sao2spo2_patday==1

* create new sao2 and spo2 variables using the prior values as well as the 
* index value 
gen sao2_value = .
replace sao2_value = prior_sao2spo2_values if prior_sao2spo2_ind=="sao2"
replace sao2_value = labchemresultnumericvalue if sao2_value==.

gen spo2_value = .
replace spo2_value = prior_sao2spo2_values if prior_sao2spo2_ind=="spo2"
replace spo2_value = spo2 if spo2_value==.

* create new sao2 and spo2 datetime variables using the prior datetimes as well as the 
* index datetimes 
gen double sao2_datetime = .
replace sao2_datetime = prior_datetime_sao2spo2 if prior_sao2spo2_ind=="sao2"
replace sao2_datetime = labchemspecimendatetime if sao2_datetime==.
format sao2_datetime %tc

gen double spo2_datetime = .
replace spo2_datetime = prior_datetime_sao2spo2 if prior_sao2spo2_ind=="spo2"
replace spo2_datetime = vitalsigntakendatetime if spo2_datetime==.
format spo2_datetime %tc

* keep only those with a sao2-spo2 pair 
keep if sao2spo2_patday==1

* calculate the time difference between the pairs
gen double sao2_spo2_min_diff = minutes(sao2_datetime-spo2_datetime)

* keep only variables we need 
keep patienticn datevalue sao2_value sao2_datetime spo2_value  ///
	 spo2_datetime year sao2_spo2_min_diff

count 
	* 201,455

count if inrange(sao2_spo2_min_diff, -10, 10)	
sum sao2_spo2_min_diff if inrange(sao2_spo2_min_diff, -10, 10)	
	* 12,159
	
* save current dataset 
*save Data\sao2_spo2_pairs_`i', replace 

}

* Append all datasets
use Data\sao2_spo2_pairs_2013, clear
append using Data\sao2_spo2_pairs_2014
append using Data\sao2_spo2_pairs_2015
append using Data\sao2_spo2_pairs_2016
append using Data\sao2_spo2_pairs_2017
append using Data\sao2_spo2_pairs_2018
append using Data\sao2_spo2_pairs_2019

tab year 
tab year if inrange(sao2_spo2_min_diff, -10, 10)	

* save dataset 
*save Data\sao2_spo2_pairs, replace 

log close

