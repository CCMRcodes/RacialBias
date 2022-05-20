clear all
cap more off
cap log close
version 16.0

cd ""

local day : display %tdCYND daily("$S_DATE", "DMY")
di "`day'"

log using "Logs\fig2_sensitivity_`day'.log", replace


********************************************************************************
	
	* Project: 		Sensitivity Analysis for Figure 2 -- 
	*					Including all SaO2s and SpO2s for White and Black patients
	
	* Author: 		S Seelye
	
	* Date Created: 	11 AUG  21
	* Date Updated: 	10 MARCH 22
	
********************************************************************************	

use Data\vapd_allpairs_withspo2_20220311, clear			

***************
** VARIABLES **
***************

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

**************
* CLEAN LABS *
**************

** SpO2 **
gen spo2_92to96 = inrange(spo2_value, 92, 96)
tab spo2_92to96

** SaO2 **

* drop observations with missing SaO2
drop if sao2_datetime==.  //n=22,042 missing

gen sao2_less88 = sao2_value<88

*--------------------
* FLOW CHART
*--------------------

count 
	
* drop all patients in the icu 
drop if icu==1 
count
	
	
* drop all observations that have an spo2 value less than 70 
*drop if spo2_value<70 //do not drop for this sensitivity analysis
count 
	
* drop all sao2s less than 70 (this excludes venus blood gas, which can have sao2s <70)
*drop if sao2_value<70 //do not drop for this sensitivity analysis
count
	
* keep only patients with 1-2 pairs per day 

*identify the number of spo2-sao2 matched pairs by patient-day*
bysort patienticn datevalue (spo2_datetime): gen pairs_num = _n
bysort patienticn datevalue (spo2_datetime): egen pairs_tot = max(pairs_num)
			
keep if inlist(pairs_tot, 1, 2) 
count
	* 36204

*--------------------------------
* Pull in Supplemental Oxygen	
*--------------------------------

merge 1:m patienticn datevalue spo2_value spo2_datetime using Data\sao2_spo2_pairs_20132019_20220308
drop if _merge==2 

duplicates report patienticn admityear spo2_value spo2_datetime

duplicates tag patienticn admityear spo2_value spo2_datetime, gen(dup)
tab dup

drop if dup==1 & o2_lpm==.
drop dup

duplicates report patienticn admityear spo2_value spo2_datetime

* replace all missing supplemental oxygen with 0 - assumed room air 
recode o2_lpm .=0

count 
* 36204

	
**************************************************************
* Appendix 7: Black & White Including all SaO2 & SpO2s 
**************************************************************

* 10 min interval
local diagnoses				///
				chf_ccs septicemia_ccs pneumonia_ccs							///
				aud_ccs cornary_athero_ccs cardiac_dys_ccs copd_ccs 			///
				resp_failure_ccs skin_ccs device_ccs surgical_ccs osteo_ccs		///
				diabetes_comp_ccs urinary_ccs renal_ccs chest_pain_ccs 			///
				cognitive_ccs ami_ccs acd_ccs back_ccs

local comorbid 																	///
				chf_hosp cardic_arrhym_hosp 									///
				valvular_d2_hosp pulm_circ_hosp pvd_hosp paralysis_hosp 		///
				neuro_hosp pulm_hosp dm_uncomp_hosp drug_hosp psychoses_hosp 	///
				depression_hosp htn_hosp dm_comp_hosp hypothyroid_hosp 			///
				renal_hosp liver_hosp pud_hosp ah_hosp lymphoma_hosp 			///
				cancer_met_hosp cancer_nonmet_hosp ra_hosp coag_hosp 			///
				obesity_hosp wtloss_hosp fen_hosp anemia_cbl_hosp 				///
				anemia_def_hosp etoh_hosp

logit sao2_less88 i.nhblack##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses'	o2_lpm , vce(cluster patienticn)	or
					
margins nhblack if spo2_value>=92, at(spo2=(92(1)100)) 
margins nhblack if spo2_value>=92
marginsplot , name(occult10allsaspo2, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("10 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("")		///
				ylabel(0(.1)0.5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) ///
				legend(off)
		
*----------------------------------
* Create 5 & 2 minute intervals 
*----------------------------------

* Create absolute value of SpO2-SaO2 time gap 
gen sao2_spo2_min_diff_abs = abs(sao2_spo2_min_diff)

* Median of 10 min interval for NH White or Black patients w/ spo2_value>=92 
sum sao2_spo2_min_diff_abs
sum sao2_spo2_min_diff_abs if spo2_value>=92 & !missing(nhblack), de

tab nhblack if spo2_value>=92


* Create 5 min interval indicator between SpO2 and SaO2 
gen sao2_spo2_5min_ind = 0
replace sao2_spo2_5min_ind = 1 if sao2_spo2_min_diff_abs<=5

sum sao2_spo2_min_diff_abs if spo2_value>=92 & sao2_spo2_5min_ind == 1 & !missing(nhblack) , de

tab nhblack sao2_spo2_5min_ind if spo2_value>=92, co


* Create 2 min interval indicator between SpO2 and SaO2 
gen sao2_spo2_2min_ind = 0
replace sao2_spo2_2min_ind = 1 if sao2_spo2_min_diff_abs<=2

sum sao2_spo2_min_diff_abs if spo2_value>=92 & sao2_spo2_2min_ind == 1 & !missing(nhblack) , de

tab nhblack sao2_spo2_2min_ind if spo2_value>=92, co


*------------------------------
* 5 min interval
*------------------------------

local diagnoses				///
				chf_ccs septicemia_ccs pneumonia_ccs							///
				aud_ccs cornary_athero_ccs cardiac_dys_ccs copd_ccs 			///
				resp_failure_ccs skin_ccs device_ccs surgical_ccs osteo_ccs		///
				diabetes_comp_ccs urinary_ccs renal_ccs chest_pain_ccs 			///
				cognitive_ccs ami_ccs acd_ccs back_ccs

local comorbid 																	///
				chf_hosp cardic_arrhym_hosp 									///
				valvular_d2_hosp pulm_circ_hosp pvd_hosp paralysis_hosp 		///
				neuro_hosp pulm_hosp dm_uncomp_hosp drug_hosp psychoses_hosp 	///
				depression_hosp htn_hosp dm_comp_hosp hypothyroid_hosp 			///
				renal_hosp liver_hosp pud_hosp ah_hosp lymphoma_hosp 			///
				cancer_met_hosp cancer_nonmet_hosp ra_hosp coag_hosp 			///
				obesity_hosp wtloss_hosp fen_hosp anemia_cbl_hosp 				///
				anemia_def_hosp etoh_hosp

logit sao2_less88 i.nhblack##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses' o2_lpm	if sao2_spo2_5min_ind==1 , vce(cluster patienticn)	

margins nhblack					
margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult5allsaspo2, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("5 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("") ///
				ylabel(0(.1)0.5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) ///
				legend(off)


*------------------------------
* 2 min interval
*------------------------------

local diagnoses				///
				chf_ccs septicemia_ccs pneumonia_ccs							///
				aud_ccs cornary_athero_ccs cardiac_dys_ccs copd_ccs 			///
				resp_failure_ccs skin_ccs device_ccs surgical_ccs osteo_ccs		///
				diabetes_comp_ccs urinary_ccs renal_ccs chest_pain_ccs 			///
				cognitive_ccs ami_ccs acd_ccs back_ccs

local comorbid 																	///
				chf_hosp cardic_arrhym_hosp 									///
				valvular_d2_hosp pulm_circ_hosp pvd_hosp paralysis_hosp 		///
				neuro_hosp pulm_hosp dm_uncomp_hosp drug_hosp psychoses_hosp 	///
				depression_hosp htn_hosp dm_comp_hosp hypothyroid_hosp 			///
				renal_hosp liver_hosp pud_hosp ah_hosp lymphoma_hosp 			///
				cancer_met_hosp cancer_nonmet_hosp ra_hosp coag_hosp 			///
				obesity_hosp wtloss_hosp fen_hosp anemia_cbl_hosp 				///
				anemia_def_hosp etoh_hosp

logit sao2_less88 i.nhblack##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses' o2_lpm	if sao2_spo2_2min_ind==1 , vce(cluster patienticn)	

margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult2allsaspo2, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("2 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("Probability of Occult Hypoxemia", size(small)) ///
				ylabel(0(.1)0.5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off) 	///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) 		

graph combine occult2allsaspo2 occult5allsaspo2 occult10allsaspo2, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) 


log close				
								



