clear all
cap more off
cap log close
version 16.0

cd ""

local day : display %tdCYND daily("$S_DATE", "DMY")
di "`day'"

log using "Logs\appendix4_`day'.log", replace


********************************************************************************
	
	* Project: 		Racial Differences in Occult Hypoxemia
	*					Analyses for Appendix 4 - VAPD dataset, 2013-2019
	
	* Author: 		S Seelye
	
	* Date Created: 	2022 Mar 11
	* Date Updated: 	2022 Apr 19
	
********************************************************************************	

* use full VAPD
use "Data\pa_vapd20132020jan_20210208.dta", clear

* only keep 2013-2019 
tab admityear 
drop if admityear==2020
	
* identify unique hospitalizations 
sort patienticn new_admitdate3 datevalue
egen uniqhospid = group(patienticn new_admitdate3 new_dischargedate3)

* identify first record of unique hospitalization 
bysort uniqhospid (datevalue): gen uniqhospidnum = _n

* Total hospitalizations 
tab uniqhospidnum

keep if uniqhospidnum==1

*-----------------
* VARIABLES 
*-----------------

* organize variables 
format patienticn %12.0g

* race
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

tab hispanic
tab hispanic race_rvd

* race/ethnicity
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

tab race
gen race_3cat = . 
recode race_3cat .=1 if race==2
recode race_3cat .=2 if race==1
recode race_3cat .=3 if race==3
label def race_3cat 1 "White" 2 "Black" 3 "Hispanic", replace
label val race_3cat race_3cat
tab race_3cat race, m

gen nhwhite = race_3cat==1
tab race_3cat nhwhite

gen white_vhispanic = .
replace white_vhispanic = 1 if race_3cat==1
replace white_vhispanic = 0 if race_3cat==3
tab white_vhispanic race_3cat, m

gen white_vblack = .
replace white_vblack = 1 if race_3cat==1
replace white_vblack = 0 if race_3cat==2
tab white_vblack race_3cat, m

* only keep white, black, and hispanic
keep if inlist(race_3cat, 1, 2, 3)
count 

* gender 
gen male=gender=="M"

* create top-20 singlelevel ccs diagnsoses for VAPD 
tab singlelevel_ccs, sort

gen copd_ccs = singlelevel_ccs==127
gen resp_failure_ccs = singlelevel_ccs==131
gen septicemia_ccs = singlelevel_ccs==2
gen pneumonia_ccs = singlelevel_ccs==122
gen chf_ccs = singlelevel_ccs==108
gen cornary_athero_ccs = singlelevel_ccs==101
gen diabetes_comp_ccs = singlelevel_ccs==50
gen aud_ccs = singlelevel_ccs==660
gen cardiac_dys_ccs = singlelevel_ccs==106
gen skin_ccs = singlelevel_ccs==197
gen device_ccs = singlelevel_ccs==237
gen surgical_ccs = singlelevel_ccs==238
gen osteo_ccs = singlelevel_ccs==203
gen urinary_ccs = singlelevel_ccs==159
gen renal_ccs = singlelevel_ccs==157
gen chest_pain_ccs = singlelevel_ccs==102
gen cognitive_ccs = singlelevel_ccs==653
gen ami_ccs = singlelevel_ccs==100
gen acd_ccs = singlelevel_ccs==109
gen back_ccs = singlelevel_ccs==205

* drop patients with missing age
drop if age==. //0 missing

* change missing to 0s for all comorbidities
foreach var in 	chf_hosp cardic_arrhym_hosp 	///
				valvular_d2_hosp pulm_circ_hosp pvd_hosp paralysis_hosp 		///
				neuro_hosp pulm_hosp dm_uncomp_hosp drug_hosp psychoses_hosp 	///
				depression_hosp htn_hosp dm_comp_hosp hypothyroid_hosp 			///
				renal_hosp liver_hosp pud_hosp ah_hosp lymphoma_hosp 			///
				cancer_met_hosp cancer_nonmet_hosp ra_hosp coag_hosp 			///
				obesity_hosp wtloss_hosp fen_hosp anemia_cbl_hosp 				///
				anemia_def_hosp etoh_hosp 	{
				
	replace `var' = 0 if `var'==.
				
}

*---------
* TABLE 
*---------

* Total hospitalizations 
tab uniqhospidnum

* Age 
sum age , de

* Male 
tab male 

* Race 
tab race_3cat 

* Diagnoses
foreach var in copd_ccs resp_failure_ccs septicemia_ccs pneumonia_ccs ///
				chf_ccs cornary_athero_ccs diabetes_comp_ccs cardiac_dys_ccs ///
				renal_ccs ami_ccs {
		
		tab `var' 				
}


* Other Diagnoses 
gen dx_top10 = 0
replace dx_top10 = 1 if inlist(1, 	copd_ccs, septicemia_ccs, resp_failure_ccs,	///
									pneumonia_ccs, chf_ccs, cornary_athero_ccs,	///
									diabetes_comp_ccs, cardiac_dys_ccs, 		///
									renal_ccs, ami_ccs) 

tab dx_top10									



* Comorbidities
foreach var in 	chf_hosp neuro_hosp pulm_hosp liver_hosp dm_uncomp_hosp			///
				dm_comp_hosp cancer_nonmet_hosp cancer_met_hosp 				///
				renal_hosp {
	tab `var' 
}

* hospital length of stay
sum hosp_los , de

* mortality 
tab inhosp_mort 
tab mort30_admit 

log close
