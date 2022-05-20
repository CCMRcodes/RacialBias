clear all
cap more off
cap log close
version 16.0

cd ""

local day : display %tdCYND daily("$S_DATE", "DMY")
di "`day'"

log using "Logs\analysis_surgery_sensitivity_`day'.log", replace


********************************************************************************
	
	* Project: 		Sensitivity analysis to address: 
	* 					Non-surgical patients in hospitals that have surgeries
	
	* Author: 		S Seelye
	
	* Date Created: 	15 MARCH 22
	* Date Updated: 	15 MARCH 22
	
********************************************************************************	

 

			
/*
			* Import additional variables from VAPD 

			forval i=2013(1)2019 {
				
				import sas 	sta6a datevalue patienticn new_admitdate3 new_dischargedate3 	///
							sta3n dod age unique_hosp_count_id chf_hosp cardic_arrhym_hosp 	///
							valvular_d2_hosp pulm_circ_hosp pvd_hosp paralysis_hosp 		///
							neuro_hosp pulm_hosp dm_uncomp_hosp drug_hosp psychoses_hosp 	///
							depression_hosp htn_hosp dm_comp_hosp hypothyroid_hosp 			///
							renal_hosp liver_hosp pud_hosp ah_hosp lymphoma_hosp 			///
							cancer_met_hosp cancer_nonmet_hosp ra_hosp coag_hosp 			///
							obesity_hosp wtloss_hosp fen_hosp anemia_cbl_hosp 				///
							anemia_def_hosp etoh_hosp 	admityear							///
						using "vapd`i'.sas7bdat", clear

				tab admityear 
						
				duplicates report patienticn datevalue 

				*duplicates from transfers; randomly drop duplicates 
				bysort patienticn datevalue: gen rnd = uniform()
				bysort patienticn datevalue (rnd): keep if _n==1

				drop rnd

				* save tempfile 
				tempfile vapd`i'
				save `vapd`i''

			}

			* append vapd 
			use `vapd2013', clear 
			append using `vapd2014'
			append using `vapd2015'
			append using `vapd2016'
			append using `vapd2017'
			append using `vapd2018'
			append using `vapd2019'

			* check duplicates
			duplicates report patienticn datevalue 
			bysort patienticn datevalue: gen rnd = uniform()
			bysort patienticn datevalue (rnd): keep if _n==1
			drop rnd

			save Data\vapd_selectvariables_20132019, replace

			* merge with pairs 
			clear all
			use Data\vapd_allpairs_withspo2_20210811, clear 

			merge m:1 patienticn datevalue using Data\vapd_selectvariables_20132019, keep(match master)		
			drop _merge 

			save Data\vapd_allpairs_withspo2_20210923, replace
			

			** 3/15/2022 UPDATE -- add surgery variables & hematocrit
			
				* create and merge in hospital-level surgery variable and hemoglobin variables
				use sta6a datevalue patienticn new_admitdate3 new_dischargedate3 uniq specialty hi_hematocrit_daily  ///
					using "pa_vapd20132020jan_20210208.dta", clear

				* surgery indicator 
				gen surgery_daily = 0
				replace surgery_daily = 1 if inlist(specialty, "CARDIAC SURGERY", ///
					"EAR, NOSE, THROAT (ENT)", "GENERAL SURGERY", "NEUROSURGERY", "OB/GYN")
				replace surgery_daily = 1 if inlist(specialty, "ORAL SURGERY", "ORTHOPEDIC", ///
					"PLASTIC SURGERY", "PODIATRY", "SURGICAL OBSERVATION")
				replace surgery_daily = 1 if inlist(specialty, "SURGICAL STEPDOWN", ///
					"THORACIC SURGERY", "TRANSPLANTATION", "UROLOGY", "VASCULAR")
				tab specialty surgery_daily

				bysort patienticn new_admitdate3 new_dischargedate3: egen surgery_hosp = max(surgery_daily)

				* identify surgery hospitals 
				bysort sta6a: egen surgery_hospital = max(surgery_daily)
				tab sta6a if surgery_hospital==1
				tab sta6a if surgery_hospital==0 //12 hospitals with 0 surgeries
				
				* hematocrit - cutoff at 30
				sum hi_hematocrit_daily 
				gen hct_over30 = .
				replace hct_over30 = 1 if hi_hematocrit_daily>30 & !missing(hi_hematocrit_daily)
				replace hct_over30 = 0 if hi_hematocrit_daily<=30 & !missing(hi_hematocrit_daily)
				tab hct_over30
				
				* only keep variables we need for pulling in specialty 
				keep patienticn datevalue surgery_hosp surgery_daily surgery_hospital hi_hematocrit_daily hct_over30

				* check duplicates 
				duplicates report patienticn datevalue
				
				*duplicates from transfers; randomly drop duplicates 
				bysort patienticn datevalue: gen rnd = uniform()
				bysort patienticn datevalue (rnd): keep if _n==1

					drop rnd
				
				duplicates report patienticn datevalue

				* save tempfile
				tempfile surgery
				save `surgery'
				
				* merge into earlier vapd pairs dataset 
				use Data\Archive\vapd_allpairs_withspo2_20210923, clear
					drop _merge
				merge m:1 patienticn datevalue using `surgery'
					drop _merge
				
			* save new vapd pairs dataset 
			save Data\vapd_surgery_sensitivity_20220315, replace
*/
	
	
	
use Data\vapd_surgery_sensitivity_20220315, clear				


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

histogram spo2_value 

sum spo2_value, detail

** SaO2 **

* drop observations with missing SaO2
drop if sao2_datetime==.  //n=22,042 missing

* check duplicate SpO2, SaO2 datetimes & values for a given patient 
*duplicates list patienticn spo2_value sao2_value spo2_datetime sao2_datetime 
	* 0 dropped

* check duplicates in terms of patienticn, spo2 (sao2) value, and spo2 (sao2) datetime
*duplicates list patienticn spo2_value spo2_datetime 

duplicates report patienticn sao2_value sao2_datetime 
*duplicates list patienticn sao2_value sao2_datetime 
duplicates report patienticn sao2_datetime 	//all of the duplicates have the same 
											//sao2 values, since the number of copies
											//here is the same as the number of 
											//copies for the above command:
											//duplicates report patienticn sao2_value sao2_datetime

duplicates tag patienticn sao2_value sao2_datetime , gen(dup_sao2)

*br patienticn spo2_value spo2_datetime sao2_value sao2_datetime dup_sao2 if dup_sao2==1
		// the remaining duplicate sao2 values & datetimes are due to having
		// a different matched pair with spo2 timestamps.

drop dup_sao2 
 
* create indicators 
gen spo2_80orless = spo2_value<=80 
gen sao2_88orless = sao2_value<=88 

sum sao2_value if sao2_value<70
*histogram sao2_value 

tab sao2_88orless

gen spo2_92to96 = inrange(spo2_value, 92, 96)
tab spo2_92to96

gen sao2_less88 = sao2_value<88

* look at distribution of sao2_value with an spo2 cutoff of 80
sum sao2_value if spo2_80orless 
sum sao2_value if spo2_value>80 
*histogram sao2_value if spo2_80orless, title("SaO2s with SpO2<80") graphregion(color(white)) ylab(0(.02).1, angle(0)) text(0.095 15 "N=1,510", place(nw) size(medsmall))
*histogram sao2_value if spo2_value>80, title("SaO2s with SpO2>80") graphregion(color(white)) ylab(0(.02).1, angle(0)) text(0.095 15 "N=67,967", place(nw) size(medsmall))

sum sao2_value if spo2_value<70 	
sum sao2_value if spo2_value>=70		

*histogram sao2_value if spo2_value<=70, title("SaO2s with SpO2<70") graphregion(color(white)) ylab(0(.02).1, angle(0)) text(0.095 15 "N=510", place(nw) size(medsmall))
*histogram sao2_value if spo2_value>70, title("SaO2s with SpO2>70") graphregion(color(white)) ylab(0(.02).1, angle(0)) text(0.095 15 "N=68,967", place(nw) size(medsmall))


*--------------------
* FLOW CHART
*--------------------

count 
	* 74,651

* drop all patients in the icu 
drop if icu==1 //35,583
count
	* 39,068
	
* drop all observations that have an spo2 value less than 70 
drop if spo2_value<70 //177
count 
	* 38,891

*histogram spo2_value
*histogram sao2_value

* drop all sao2s less than 70 (this excludes venus blood gas, which can have sao2s <70)
drop if sao2_value<70 //6603
count
	* 32,288

* keep only patients with 1-2 pairs per day 

	*identify the number of spo2-sao2 matched pairs by patient-day*
	bysort patienticn datevalue (spo2_datetime): gen pairs_num = _n
	bysort patienticn datevalue (spo2_datetime): egen pairs_tot = max(pairs_num)

			
keep if inlist(pairs_tot, 1, 2) 
count
	* 30,039

*--------------------------------
* Pull in Supplemental Oxygen	
*--------------------------------

* use the sao2_spo2_pairs dataset that includes supplemental oxygen values for 
* the sao2-spo2 cleaned pairs 

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
	* 30,039

	
*-----------------------------------
* Creating 5 & 2 Minute Intervals
*-----------------------------------

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
	
	
*------------------------------------------------	
* Appendix 9: Hospitals with Surgeries
*------------------------------------------------
	
** 10 minutes **
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
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92 & surgery_hospital==1 & surgery_hosp==0, vce(cluster patienticn)	or
				
margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult10min, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("10 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("")		///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off) 	///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) 


** 5 minutes **
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
					age male `comorbid' `diagnoses' o2_lpm	if spo2_value>=92 & surgery_hospital==1 & surgery_hosp==0 & sao2_spo2_5min_ind==1 , vce(cluster patienticn)	

margins nhblack					
margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult5min, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("5 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("") ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off) 	///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) 
				
** 2 minutes **
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
					age male `comorbid' `diagnoses' o2_lpm	if spo2_value>=92 & surgery_hospital==1 & surgery_hosp==0 & sao2_spo2_2min_ind==1 , vce(cluster patienticn)	

margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult2min, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("2 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("Probability of Occult Hypoxemia", size(small)) ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off) 	///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) 

graph combine occult2min occult5min occult10min, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) 


log close				
