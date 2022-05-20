clear all
cap more off
version 16.0
cap log close

cd ""


local day : display %tdCYND daily("$S_DATE", "DMY")
di "`day'"

log using "Logs\allvapd_hypox_rate_`day'.log", replace


********************************************************************************
	
	* Project: 		Racial Bias in Pulse Oximetry
	*					Do file for figures reported in Results, Probability of 
	*					Occult Hypoxemia, para. 4
	
	* Author: 		S Seelye
	
	* Date Created: 	2021 Aug 11 
	* Date Updated: 	2022 Apr 18
	
********************************************************************************	


* keep only pulse ox values of 92-100 
use Data\pulseox_20132020_sw_20210224, clear			

sum spo2
keep if spo2>=92
sum spo2

* keep only variables we need
keep patienticn vital_date spo2
			
* merge with vapd 
merge m:1 patienticn vital_date using Data\vapd_for_pulseox_20211020

* keep only those that are matched 
keep if _merge==3
drop _merge 

count
tab admityear

* keep only floor status patients 
drop if icu==1 

count
tab admityear

* race/ethnicity
tab race

gen race_rvd = .
replace race_rvd = 1 if race=="BLACK OR AFRICAN AMERICAN"
replace race_rvd = 2 if inlist(race, "WHITE" , "WHITE NOT OF HISP ORIG")
replace race_rvd = 3 if inlist(race, "ASIAN", "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER")
replace race_rvd = 4 if inlist(race, "AMERICAN INDIAN OR ALASKA NATIVE")
replace race_rvd = 5 if inlist(race, "", "DECLINED TO ANSWER", "UNKNOWN", "UNKNOWN BY PATIENT")
label define race_rvd 1 "Black" 2 "White" 3 "Asian/Pacific Islander" 4 "American Indian" 5 "Unknown", replace
label val race_rvd race_rvd

tab race race_rvd

tab hispanic race_rvd

gen race_new = .
replace race_new = 1 if race_rvd==1 & hispanic==0
replace race_new = 2 if race_rvd==2 & hispanic==0
replace race_new = 3 if hispanic==1
replace race_new = 4 if race_rvd==3 & hispanic==0
replace race_new = 5 if race_rvd==4 & hispanic==0
replace race_new = 6 if race_rvd==5 & hispanic==0
label define race_new 1 "NH Black" 2 "NH White" 3 "Hispanic/Latino" 4 "Asian/Pacific Islander" 5 "American Indian" 6 "Unknown"
lab val race_new race_new

tab race race_new 
tab race_new hispanic

gen black = race_new==1
gen white = race_new==2
gen asian = race_new==4
gen amerind = race_new==5
gen other_race = race_new==6

label def black 1 "NH Black" 0 "All Other"
label val black black

tab race black 
tab race white

drop race race_rvd 
rename race_new race

gen nhblack = .
replace nhblack = 1 if race==1
replace nhblack = 0 if race==2
label def nhblack 1 "NH Black" 0 "NH White"
label val nhblack nhblack

tab nhblack

* all patients - 54,048,788
* white patients - 39,691,417
* black patients - 14,357,371 

* probability of occult hypoxemia for patients with 2 or fewer SpO2 readings 
* (see do file = analysis_allpairs_withspo2)
	// black probability of occult hypoxemia = 0.1953465 
	// white probability of occult hypoxemia = 0.1554555 

di 14357371*0.1953465  //nhblack full sample occult hypoxemia = 2,804,662
di 39691417*0.1554555   //nhwhite full sample occult hypoxemia = 6,170,249 
di 14357371*0.1554555   //#occult hypoxemia in nhblack if had same rate as nhwhite = 2,231,932
di 2804662-2231932 // 572,730 episodes of occult hypoxemia that would not have happened if nhblack had been white
di 572730/2804662 //20.4% of occult hypoxemia cases would not have occurred


* save dataset 
save Data\vapd_allspo2_92to100_20211129, replace
 
log close