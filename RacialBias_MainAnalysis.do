
clear all
cap more off
cap log close
version 16.0

cd ""

local day : display %tdCYND daily("$S_DATE", "DMY")
di "`day'"

log using "Logs\mainanalysis_`day'.log", replace


********************************************************************************
	
	* Project: 		Racial Bias in Pulse Oximetry – Main Analysis
	
	* Author: 		S Seelye
	
	* Date Created: 2021 Aug 11 
	* Date Updated: 2022 Apr 18
	
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


*--------
* LABS 
*--------

** SpO2 **
histogram spo2_value 
sum spo2_value, detail

gen spo2_92to96 = inrange(spo2_value, 92, 96)
tab spo2_92to96

** SaO2 **
* drop observations with missing SaO2 datetime 
drop if sao2_datetime==.  //n=22,042 missing
count //70153

gen sao2_less88 = sao2_value<88
 

*----------------------------------------------------
* Figure 1 Flow Chart; Results (para 1)
*----------------------------------------------------

count //70,153

* drop all patients in the icu 
drop if icu==1 //33,556
count //36,597
	
* drop all observations that have an spo2 value less than 70 
drop if spo2_value<70 //168
count //36,429

* drop all sao2s less than 70
drop if sao2_value<70 //6135
count //30,294

* keep only patients with 1-2 pairs per day 
* identify the number of spo2-sao2 matched pairs by patient-day*
bysort patienticn datevalue (spo2_datetime): gen pairs_num = _n
bysort patienticn datevalue (spo2_datetime): egen pairs_tot = max(pairs_num)

tab pairs_tot if  pairs_num==1
tab pairs_tot if  pairs_num==1 & inrange(pairs_tot, 2, 8)
	
tab race if pairs_num==1 & pairs_tot==2
 			
keep if inlist(pairs_tot, 1, 2) //255 dropped
count //30,039

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

* replace missing supplemental oxygen with 0 - assumed room air 
recode o2_lpm .=0

count //30,039

*-------------------------------
* TABLE 1; Results (para. 2)
*-------------------------------

* Total Ns by Race
tab race_3cat
tab race_3cat if pairs_num==1

* SpO2 
table race_3cat, c(p50 spo2_value p25 spo2_value p75 spo2_value)
ttest spo2_value, by(white_vblack)
ttest spo2_value, by(white_vhispanic)

* SaO2 
table race_3cat, c(p50 sao2_value p25 sao2_value p75 sao2_value)
ttest sao2_value, by(white_vblack)
ttest sao2_value, by(white_vhispanic)

* Supplemental Oxygen 
table race_3cat, c(p50 o2_lpm p25 o2_lpm p75 o2_lpm mean o2_lpm sd o2_lpm)
ttest o2_lpm, by(white_vblack)
ttest o2_lpm, by(white_vhispanic)

* Occult Hypoxemia
gen spo2_92ormore = spo2_value>=92
tab spo2_92ormore race_3cat, co

tab spo2_92ormore white_vblack , co chi2
tab spo2_92ormore white_vhispanic , co chi2

tab sao2_less88 race_3cat if spo2_92ormore==1, co
tab sao2_less88 white_vblack if spo2_92ormore==1, co chi2
tab sao2_less88 white_vhispanic if spo2_92ormore==1, co chi2
proportion sao2_less88 if spo2_92ormore==1, over(race_3cat)
 //Results, Post-hoc, hypothesis-generating, and sensitivity analyses para. 1
 
* Total Patient-Days 
tab race_3cat if pairs_num==1

* Age 
sum age if pairs_num==1, de
sum age if pairs_num==1 & nhwhite==1, de 
sum age if pairs_num==1 & nhblack==1, de 
sum age if pairs_num==1 & hispanic==1, de 

ttest age if pairs_num==1, by(white_vblack)
ttest age if pairs_num==1, by(white_vhispanic)

* Male 
tab male if pairs_num==1
tab male race_3cat if pairs_num==1, co 
tab male white_vblack if pairs_num==1, co chi2
tab male white_vhispanic if pairs_num==1, co chi2

* Diagnoses
tab copd_ccs race_3cat if pairs_num==1, chi2 co
tab copd_ccs white_vblack if pairs_num==1, co chi2
tab copd_ccs white_vhispanic if pairs_num==1, co chi2

tab resp_failure_ccs race_3cat if pairs_num==1, chi2 co
tab resp_failure_ccs white_vblack if pairs_num==1, co chi2
tab resp_failure_ccs white_vhispanic if pairs_num==1, co chi2

tab septicemia_ccs race_3cat if pairs_num==1, chi2 co
tab septicemia_ccs white_vblack if pairs_num==1, co chi2
tab septicemia_ccs white_vhispanic if pairs_num==1, co chi2

tab pneumonia_ccs race_3cat if pairs_num==1, chi2 co
tab pneumonia_ccs white_vblack if pairs_num==1, co chi2
tab pneumonia_ccs white_vhispanic if pairs_num==1, co chi2

tab chf_ccs race_3cat if pairs_num==1, chi2 co
tab chf_ccs white_vblack if pairs_num==1, co chi2
tab chf_ccs white_vhispanic if pairs_num==1, co chi2

tab cornary_athero_ccs race_3cat if pairs_num==1, chi2 co
tab cornary_athero_ccs white_vblack if pairs_num==1, co chi2
tab cornary_athero_ccs white_vhispanic if pairs_num==1, co chi2

tab diabetes_comp_ccs race_3cat if pairs_num==1, chi2 co
tab diabetes_comp_ccs white_vblack if pairs_num==1, co chi2
tab diabetes_comp_ccs white_vhispanic if pairs_num==1, co chi2

tab cardiac_dys_ccs race_3cat if pairs_num==1, chi2 co
tab cardiac_dys_ccs white_vblack if pairs_num==1, co chi2
tab cardiac_dys_ccs white_vhispanic if pairs_num==1, co chi2

tab renal_ccs race_3cat if pairs_num==1, chi2 co
tab renal_ccs white_vblack if pairs_num==1, co chi2
tab renal_ccs white_vhispanic if pairs_num==1, co chi2

tab ami_ccs race_3cat if pairs_num==1, chi2 co
tab ami_ccs white_vblack if pairs_num==1, co chi2
tab ami_ccs white_vhispanic if pairs_num==1, co chi2

* Other Diagnoses 
gen dx_top10 = 0
replace dx_top10 = 1 if inlist(1, 	copd_ccs, septicemia_ccs, resp_failure_ccs,	///
									pneumonia_ccs, chf_ccs, cornary_athero_ccs,	///
									diabetes_comp_ccs, cardiac_dys_ccs, 		///
									renal_ccs, ami_ccs) 
tab dx_top10 pairs_tot if pairs_num==1, chi2 co
																
gen dx_other = 0
replace dx_other=1 if inlist(1, aud_ccs, skin_ccs, device_ccs, surgical_ccs,  ///
								osteo_ccs, urinary_ccs, acd_ccs, back_ccs,	 ///
								chest_pain_ccs, cognitive_ccs)
replace dx_other = 1 if dx_top10!=1 

tab dx_other dx_top10 if pairs_num==1 
tab dx_other dx_top10
								
tab dx_other race_3cat if pairs_num==1, chi2 co
tab dx_other white_vblack if pairs_num==1, co chi2
tab dx_other white_vhispanic if pairs_num==1, co chi2

* Comorbidities
foreach var in 	chf_hosp neuro_hosp pulm_hosp liver_hosp dm_uncomp_hosp			///
				dm_comp_hosp cancer_nonmet_hosp cancer_met_hosp 				///
				renal_hosp {
	tab `var' race_3cat if pairs_num==1, chi2 co
	tab `var' white_vblack if pairs_num==1, co chi2
	tab `var' white_vhispanic if pairs_num==1, co chi2
}

* hospital length of stay
table race_3cat, c(p50 hosp_los p25 hosp_los p75 hosp_los)
ttest hosp_los if pairs_num==1, by(white_vblack)
ttest hosp_los if pairs_num==1, by(white_vhispanic)

* mortality 
tab inhosp_mort race_3cat if pairs_num==1, chi2 co
tab inhosp_mort white_vblack if pairs_num==1, co chi2
tab inhosp_mort white_vhispanic if pairs_num==1, co chi2

tab mort30_admit race_3cat if pairs_num==1, chi2 co
tab mort30_admit white_vblack if pairs_num==1, co chi2
tab mort30_admit white_vhispanic if pairs_num==1, co chi2

*---------------------------------------------------------------
* Appendix 1. Descriptives of 1 vs 2 Pairs per Day 
*---------------------------------------------------------------

* also reported in Results, paragraph 2

tab pairs_tot
tab pairs_tot if pairs_num==1

* SpO2 
table pairs_tot, c(p50 spo2_value p25 spo2_value p75 spo2_value)
ttest spo2_value, by(pairs_tot)

* SaO2 
table pairs_tot, c(p50 sao2_value p25 sao2_value p75 sao2_value)
ttest sao2_value, by(pairs_tot)

* Demographics
tab male pairs_tot if pairs_num==1, chi2

tab nhblack pairs_tot if pairs_num==1, chi2
tab white_vhispanic pairs_tot if pairs_num==1, chi2 co

* Diagnoses
tab copd_ccs pairs_tot if pairs_num==1, chi2 co
tab septicemia_ccs pairs_tot if pairs_num==1, chi2 co
tab resp_failure_ccs pairs_tot if pairs_num==1, chi2 co
tab pneumonia_ccs pairs_tot if pairs_num==1, chi2 co
tab chf_ccs pairs_tot if pairs_num==1, chi2 co
tab cornary_athero_ccs pairs_tot if pairs_num==1, chi2 co
tab diabetes_comp_ccs pairs_tot if pairs_num==1, chi2 co
tab cardiac_dys_ccs pairs_tot if pairs_num==1, chi2 co
tab renal_ccs pairs_tot if pairs_num==1, chi2 co
tab ami_ccs pairs_tot if pairs_num==1, chi2 co

* Comorbidities
foreach var in 	chf_hosp neuro_hosp pulm_hosp liver_hosp dm_uncomp_hosp			///
				dm_comp_hosp cancer_nonmet_hosp cancer_met_hosp 				///
				renal_hosp cardic_arrhym_hosp valvular_d2_hosp pulm_circ_hosp 	///
				pvd_hosp paralysis_hosp htn_hosp hypothyroid_hosp pud_hosp 		///
				lymphoma_hosp coag_hosp ra_hosp fen_hosp anemia_cbl_hosp 		///
				anemia_def_hosp obesity_hosp wtloss_hosp etoh_hosp drug_hosp 	///
				depression_hosp psychoses_hosp{
	tab `var' pairs_tot if pairs_num==1, chi2 co
}

* hospital length of stay
bysort pairs_tot: sum hosp_los if pairs_num==1, det
ttest hosp_los if pairs_num==1 , by(pairs_tot)

* mortality 
tab inhosp_mort pairs_tot if pairs_num==1, chi2 co
tab mort30_admit pairs_tot if pairs_num==1, chi2 co


*---------------------
* Appendix 3  
*---------------------

* Appendix 3, reported in Results, Probability of Occult Hypoxemia, para. 1
table race_3cat spo2_value if spo2_value>=89, c(n sao2_value)

* Figure for Table 
gen sao2_nhblack = sao2_value if nhblack==1 
gen sao2_nhwhite = sao2_value if nhblack==0

graph box sao2_nhwhite sao2_nhblack if spo2_value>=89 & spo2_value<=100, ///
		over(spo2_value) yline(88, lpattern(dash) lcolor(gs4))			///
		graphregion(color(white)) plotregion(color(white)) 				///
		ylabel(, labsize(small) angle(0)) 								///
		ytitle("Arterial Oxygen Saturation", size(small))				
		
	*graph save "Graph" "Figures\boxplot_20210927.gph", replace

	
* histograms of spo2 and sao2	
histogram spo2_value, percent bin(30) name(spo2, replace) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xtitle("SpO2", size(medsmall) margin(medium)) 		///
		ytitle(, size(medsmall)) ///
		ylabel(, labsize(small) angle(0))	///
		xlabel(, labsize(small))	///
		lcolor(navy) fcolor(navy*0.8)

	*graph save "spo2" "Figures\histogram_spo2_20220309.gph", replace


histogram sao2_value, percent bin(30) name(sao2, replace) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xtitle("SaO2", size(medsmall) margin(medium)) 		///
		ytitle(, size(medsmall)) ///
		ylabel(0(5)20, labsize(small) angle(0) gmin gmax)	///
		xlabel(, labsize(small))	///
		lcolor(navy) fcolor(navy*0.8)
	
	*graph save "sao2" "Figures\histogram_sao2_20220309.gph", replace

graph combine spo2 sao2, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) 

	*graph save "Figures\histogram_combine_20220309.gph", replace
	


*----------------------
* Appendix 4
*----------------------

* identify unique hospitalizations 
sort patienticn new_admitdate3 datevalue
egen uniqhospid = group(patienticn new_admitdate3 new_dischargedate3)

* identify first record of unique hospitalization 
bysort uniqhospid (datevalue): gen uniqhospidnum = _n

* Total hospitalizations 
tab uniqhospidnum

* Age 
sum age if uniqhospidnum==1, de

* Male 
tab male if uniqhospidnum==1

* Race 
tab race_3cat if uniqhospidnum==1

* Diagnoses
foreach var in copd_ccs resp_failure_ccs septicemia_ccs pneumonia_ccs ///
				chf_ccs cornary_athero_ccs diabetes_comp_ccs cardiac_dys_ccs ///
				renal_ccs ami_ccs {
		
		tab `var' if uniqhospidnum==1				
}


* Other Diagnoses 
tab dx_other if uniqhospidnum==1


* Comorbidities
foreach var in 	chf_hosp neuro_hosp pulm_hosp liver_hosp dm_uncomp_hosp			///
				dm_comp_hosp cancer_nonmet_hosp cancer_met_hosp 				///
				renal_hosp {
	tab `var' if uniqhospidnum==1
}

* hospital length of stay
sum hosp_los if uniqhospidnum==1, de

* mortality 
tab inhosp_mort if uniqhospidnum==1
tab mort30_admit if uniqhospidnum==1
	
*----------------------------------------------------------------
* Figure 2: Non-Hispanic White VS Non-Hispanic Black Patients
*----------------------------------------------------------------

*---------------------
* 10 Min Interval
*---------------------

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
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92 , vce(cluster patienticn)	or
					
margins if inrange(spo2_value, 92, 96)	
margins if inrange(spo2_value, 97, 100)				
						
margins nhblack if inrange(spo2_value, 92, 96)	
margins nhblack if inrange(spo2_value, 97, 100)				
			
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
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) 

	*graph save "occult10min" "Figures\fig2_sao2_less88_adjusted_10min_occulthypox_20220309.gph", replace
			
margins nhblack, at(spo2=(92(1)100)) contrast
marginsplot, name(occult10min_contrast, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("10 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("")		///
			 ylabel(0(0.05)0.125, labsize(small) angle(0))	///
			 xlabel(, labsize(small))		
	
	*graph save "occult10min_contrast" "Figures\fig2_sao2_less88_adjusted_contrast10min_occulthypox_20220309.gph", replace

margins , dydx(nhblack) //4.0% (95%CI, 2.7% to 5.3%; p<0.001) 
						//reported in Results, Probability of Occult Hypoxemia, para. 1
margins , at(nhblack==1) at(nhblack==0) post // 19.53465, 15.54555
matlist e(b)
lincom _b[2._at] - _b[1._at]	// 0.039891 (p<0.001)

tab nhblack if spo2_value>=92 //full sample of nhblack & nhwhite patients with spo2>=92
di 5852*_b[1._at] //nhblack full sample occult hypoxemia = 1143
di 18157*_b[2._at] //nhwhite full sample occult hypoxemia = 2823
di 5852*_b[2._at] //#occult hypoxemia in nhblack if had same rate as nhwhite = 910
di 1143-910 //233
di 233/1143 //0.204

*-------------------------------
* Intervals: 10, 5 & 2 Min.
*-------------------------------

* Create absolute value of SpO2-SaO2 time gap 
gen sao2_spo2_min_diff_abs = abs(sao2_spo2_min_diff)

* Median of 10 min interval for NH White or Black patients w/ spo2_value>=92 
sum sao2_spo2_min_diff_abs
sum sao2_spo2_min_diff_abs if spo2_value>=92 & inlist(race_3cat, 1, 2), de
	//median time difference 5.0 minutes (IQR 2.4,7.7) for 24,009 pairs
	//Results, Probability of Occult Hypoxemia, para. 3

* Create 5 min interval indicator between SpO2 and SaO2 
gen sao2_spo2_5min_ind = 0
replace sao2_spo2_5min_ind = 1 if sao2_spo2_min_diff_abs<=5

sum sao2_spo2_min_diff_abs if spo2_value>=92 & sao2_spo2_5min_ind == 1 & inlist(race_3cat, 1, 2), de
	//median time difference 2.6 minutes (IQR 1.0, 4.0) for 12,603 pairs
	//Results, Probability of Occult Hypoxemia, para. 3
	
tab nhblack sao2_spo2_5min_ind if spo2_value>=92, co

* Create 2 min interval indicator between SpO2 and SaO2 
gen sao2_spo2_2min_ind = 0
replace sao2_spo2_2min_ind = 1 if sao2_spo2_min_diff_abs<=2

sum sao2_spo2_min_diff_abs if spo2_value>=92 & sao2_spo2_2min_ind == 1 & inlist(race_3cat, 1, 2), de
	//median time difference 1.0 minute (IQR 0.2, 1.5) for 5,305 pairs
	//Results, Probability of Occult Hypoxemia, para. 3
	
tab nhblack sao2_spo2_2min_ind if spo2_value>=92, co

*--------------------
* 5 Min Interval 
*--------------------

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
					age male `comorbid' `diagnoses' o2_lpm	if spo2_value>=92 & sao2_spo2_5min_ind==1 , vce(cluster patienticn)	
		
margins if inrange(spo2_value, 92, 96)	
margins if inrange(spo2_value, 97, 100)				
						
margins nhblack if inrange(spo2_value, 92, 96)	
margins nhblack if inrange(spo2_value, 97, 100)				
							
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
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) 

	*graph save "occult5min" "Figures\fig2_sao2_less88_adjusted_5min_occulthypox_20220309.gph", replace

margins nhblack, at(spo2=(92(1)100)) contrast
marginsplot, name(occult5min_contrast, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("5 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("") ///
			 ylabel(0(0.05)0.125, labsize(small) angle(0))	///
			 xlabel(, labsize(small))		
	
	*graph save "occult5min_contrast" "Figures\fig2_sao2_less88_adjusted_contrast5min_occulthypox_20220309.gph", replace

margins , dydx(nhblack)	//3.7% (95%CI 2.0% to 5.5%; p<0.001))
						//reported in Results, Probability of Occult Hypoxemia, para. 3
margins , at(nhblack==1) at(nhblack==0) post //19.1, 15.4
matlist e(b)
lincom _b[2._at] - _b[1._at]	// -0.0372663 (p<0.001)

*---------------------
* 2 Min Interval
*---------------------

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
					age male `comorbid' `diagnoses' o2_lpm	if spo2_value>=92 & sao2_spo2_2min_ind==1 , vce(cluster patienticn)	
		
margins if inrange(spo2_value, 92, 96)	
margins if inrange(spo2_value, 97, 100)				
						
margins nhblack if inrange(spo2_value, 92, 96)	
margins nhblack if inrange(spo2_value, 97, 100)				
				
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

	*graph save "occult2min" "Figures\fig2_sao2_less88_adjusted_2min_occulthypox_20220309.gph", replace
			
margins nhblack, at(spo2=(92(1)100)) contrast
marginsplot, name(occult2min_contrast, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("2 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("Racial Difference in Probability of Occult Hypoxemia", size(small)) ///
			 ylabel(0(0.05)0.125, labsize(small) angle(0))	///
			 xlabel(, labsize(small))		
	
	*graph save "occult2min_contrast" "Figures\fig2_sao2_less88_adjusted_contrast2min_occulthypox_20220309.gph", replace

margins , dydx(nhblack)	//4.6% (95%CI 1.9% to 7.2%; p=0.001)
						//reported in Results, Probability of Occult Hypoxemia, para. 3
	
margins , at(nhblack==1) at(nhblack==0) post //20.0; 15.4
matlist e(b)
lincom _b[2._at] - _b[1._at]	// -0.0455407 (p=0.001)

graph combine occult2min occult5min occult10min, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) 

graph combine occult2min_contrast occult5min_contrast occult10min_contrast, ///
				rows(1) fysize(50) iscale(0.55) imargin(1 1 1 1) graphregion(color(white)) ///
				name(combine, replace)


********************************************************************************						
* Appendix 6. Probability of occult hypoxemia for White and Hispanic patients
********************************************************************************

gen hispanic_vwhite = .
recode hispanic_vwhite .=1 if race_3cat==3
recode hispanic_vwhite .=0 if race_3cat==1
tab hispanic_vwhite race_3cat, m

*---------------------
* 10 Min Interval		
*---------------------

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

logit sao2_less88 i.hispanic_vwhite##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92 , vce(cluster patienticn)	or
margins hispanic_vwhite, at(spo2=(92(1)100)) 
marginsplot , name(occult10racecat, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("10 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("")		///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off) ///
				note("Hispanic" "White", position(3) ring(0) size(small) margin(medsmall)) 
		
	*graph save "occult10racecat" "Figures\Fig2_10min_hispanic_20220309.gph", replace

margins hispanic_vwhite, at(spo2=(92(1)100)) contrast
marginsplot, name(occult10hispcontrast, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("10 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("")		///
			 ylabel(-0.1(0.05)0.15, labsize(small) angle(0))	///
			 xlabel(, labsize(small))		
	
	*graph save "occult10hispcontrast" "Figures\Fig2_10min_contrast_hisp_20220309.gph", replace

margins, dydx(hispanic_vwhite)	
margins , at(hispanic_vwhite==1) at(hispanic_vwhite==0) post // 18.0, 15.5
matlist e(b)
lincom _b[2._at] - _b[1._at]	// -0.025 (p=0.047)

	
*---------------------
* 5 Min Interval		
*---------------------

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

logit sao2_less88 i.hispanic_vwhite##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92 & sao2_spo2_5min_ind==1 , vce(cluster patienticn)	

margins hispanic_vwhite					
margins hispanic_vwhite, at(spo2=(92(1)100)) 
marginsplot , name(occult5racecat, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("5 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("") ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off) 
	
	*graph save "occult5racecat" "Figures\Fig2_5min_hispanic_20220309.gph", replace

margins hispanic_vwhite, at(spo2=(92(1)100)) contrast
marginsplot, name(occult5hispcontrast, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("5 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("") ///
			 ylabel(-0.1(0.05)0.15, labsize(small) angle(0))	///
			 xlabel(, labsize(small))		
	
	*graph save "occult5hispcontrast" "Figures\Fig2_5min_contrast_hisp_20220309.gph", replace

margins , at(hispanic_vwhite==1) at(hispanic_vwhite==0) post //18.9, 15.3
matlist e(b)
lincom _b[2._at] - _b[1._at]	//  -0.036 (0.042)
	

*-------------------
* 2 Min Interval
*-------------------

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

logit sao2_less88 i.hispanic_vwhite##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses' o2_lpm if spo2_value>=92 & sao2_spo2_2min_ind==1 , vce(cluster patienticn)	

margins hispanic_vwhite, at(spo2=(92(1)100)) 
marginsplot , name(occult2racecat, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("2 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("Probability of Occult Hypoxemia", size(small)) ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off) 	

	*graph save "occult2racecat" "Figures\Fig2_2min_hispanic_20220309.gph", replace
			

margins hispanic_vwhite, at(spo2=(92(1)100)) contrast
marginsplot, name(occult2hispcontrast, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("2 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("Racial Difference in Probability of Occult Hypoxemia", size(small)) ///
			 ylabel(-0.1(0.05)0.15, labsize(small) angle(0))	///
			 xlabel(, labsize(small))		
	
	*graph save "occult2hispcontrast" "igures\Fig2_2min_contrast_hisp_20220309.gph", replace

margins , at(hispanic_vwhite==1) at(hispanic_vwhite==0) post //17.68, 15.4
matlist e(b)
lincom _b[2._at] - _b[1._at]	// -0.023 (p=0.353)


graph combine occult2racecat occult5racecat occult10racecat, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) 
				
graph combine occult2hispcontrast occult5hispcontrast occult10hispcontrast, ///
				rows(1) fysize(50) iscale(0.55) imargin(1 1 1 1) graphregion(color(white)) ///
				name(combine, replace)

				

********************************************************************************
* NOTE: Below are same models as above, but switching order of hispanic and  
* white for better clarity in figure
********************************************************************************

*---------------------
* 10 Minute Interval		
*---------------------

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

logit sao2_less88 i.white_vhispanic##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92 , vce(cluster patienticn)	or

margins white_vhispanic, at(spo2=(92(1)100)) 
marginsplot , name(occult10racecat, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("10 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("")		///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--") lcolor(maroon) fcolor(maroon))  ///
				plot2opts(lpattern("--") lcolor(navy) fcolor(navy))  ///
				ci1opts(recast(rarea) color(maroon))  ///
				ci2opts(recast(rarea) color(navy)) ///
				legend(off) ///
				note("Hispanic" "White", position(3) ring(0) size(small) margin(medsmall)) 
	
*---------------------
* 5 Minute Interval		
*---------------------

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

logit sao2_less88 i.white_vhispanic##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92 & sao2_spo2_5min_ind==1 , vce(cluster patienticn)	

margins white_vhispanic					
margins white_vhispanic, at(spo2=(92(1)100)) 
marginsplot , name(occult5racecat, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("5 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("") ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--") lcolor(maroon) fcolor(maroon))  ///
				plot2opts(lpattern("--") lcolor(navy) fcolor(navy))  ///
				ci1opts(recast(rarea) color(maroon))  ///
				ci2opts(recast(rarea) color(navy)) ///
				legend(off) ///
				note("Hispanic" "White", position(3) ring(0) size(small) margin(medsmall)) 
	

*------------------------------
* 2 min sensitivity analysis 
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

logit sao2_less88 i.white_vhispanic##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses' o2_lpm if spo2_value>=92 & sao2_spo2_2min_ind==1 , vce(cluster patienticn)	

margins white_vhispanic, at(spo2=(92(1)100)) 
marginsplot , name(occult2racecat, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("2 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("Probability of Occult Hypoxemia", size(small)) ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--") lcolor(maroon) fcolor(maroon))  ///
				plot2opts(lpattern("--") lcolor(navy) fcolor(navy))  ///
				ci1opts(recast(rarea) color(maroon))  ///
				ci2opts(recast(rarea) color(navy)) ///
				legend(off) ///
				note("Hispanic" "White", position(3) ring(0) size(small) margin(medsmall)) 	

graph combine occult2racecat occult5racecat occult10racecat, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) ///
				name(combineocculthisp)

*graph save "combineocculthisp" "Figures\Fig2_hispanic_20220311.gph"


********************************************************************************
* Appendix 7: Probability of occult hypoxemia for Black and White patients. 
* 			  SpO2 values <=92 included in model 
********************************************************************************

*---------------------
* 10 Min Interval
*---------------------

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
margins nhblack //W=18.1; B=22.8
margins , dydx(nhblack) 
		
margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult10app7, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("10 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("") ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) 

*--------------------
* 5 Min Interval 
*--------------------

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

margins nhblack if spo2_value>=92					
margins if spo2_value>=92, dydx(nhblack) 					
					
margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult5app7, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("5 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("") ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) 

	
*---------------------
* 2 Min Interval
*---------------------

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

margins nhblack if spo2_value>=92					
margins if spo2_value>=92, dydx(nhblack) 							
				
margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult2app7, replace) ///
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

	
graph combine occult2app7 occult5app7 occult10app7, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) 


**************************************************************
* Appendix 8: Black & White w/ Hospital Random Effects
**************************************************************

* 10 min
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

meqrlogit sao2_less88 i.nhblack##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses'	o2_lpm || sta6a: , or
					
margins nhblack , at(spo2=(92(1)100)) predict(mu fixed)
marginsplot , name(occult10rand, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("10 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("")		///
				xlabel(, labsize(small))		///
				ylabel(0(.1)0.5, labsize(small) angle(0))	///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				note("Black" "White", position(3) ring(0) size(small) margin(medsmall)) ///
				legend(off)
	
*----------------------
* 5 min interval 
*----------------------

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

meqrlogit sao2_less88 i.nhblack##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses' o2_lpm	if sao2_spo2_5min_ind==1 || sta6a:	

margins nhblack, at(spo2=(92(1)100)) predict(mu fixed)
marginsplot , name(occult5rand, replace) ///
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


*---------------------
* 2 min interval 
*---------------------

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

meqrlogit sao2_less88 i.nhblack##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses' o2_lpm	if sao2_spo2_2min_ind==1 || sta6a:

margins nhblack, at(spo2=(92(1)100)) predict(mu fixed)
marginsplot , name(occult2rand, replace) ///
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

	
graph combine occult2rand occult5rand occult10rand, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) 


	
********************************************************************************				
* Appendix 9: Post hoc analysis of surgical vs non-surgical patients		
********************************************************************************		

tab nhblack if spo2_value>=92 & surgery_hosp==1 
tab nhblack if surgery_hosp==1 & pairs_num==1

*------------
* 10 Min
*------------
		
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
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92 & surgery_hosp==1 , vce(cluster patienticn)	or
				
margins nhblack, at(spo2=(92(1)100)) 

marginsplot , name(occult10surg, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("10 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("")		///
				ylabel(0(.1).6, labsize(small) angle(0) gmin gmax)	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off)

	*graph save "occult10surg" "Figures\fig2_10min_surg_20220309.gph", replace
			
margins nhblack, at(spo2=(92(1)100)) contrast
marginsplot, name(occult10contrastsurg, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("10 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("")		///
			 ylabel(-0.3(0.1)0.3, labsize(small) angle(0) gmin gmax)	///
			 xlabel(, labsize(small))		
	
	*graph save "occult10contrastsurg" "Figures\fig2_contrast10min_surg_20220309.gph", replace

margins, dydx(nhblack)	
margins , at(nhblack==1) at(nhblack==0) post // 11.4, 11.1
matlist e(b)
lincom _b[2._at] - _b[1._at]	//p=0.817 (CI=-0.036, 0.028)


* including surgical and non-surgical in the same model 
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

logit sao2_less88 i.nhblack#c.spo2_value c.spo2_value#c.spo2_value i.surgery_hosp 	///
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92, vce(cluster patienticn)	or
margins nhblack, at(spo2_value=(92(1)100) surgery_hosp=(0) surgery_hosp=(1)) 		
marginsplot, name(surgbyrace, replace) ///
				graphregion(color(white)) plotregion(color(white)) ///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("Probability of Occult Hypoxemia", size(small)) ///
				ylabel(0(.1).5, labsize(small) angle(0))	///
				xlabel(, labsize(small))		///
				title("")
*graph save "surgbyrace" “Figures\fig2_surgbyrace_20220411.gph"	

margins , dydx(nhblack) at(surgery_hosp==1) at(surgery_hosp==0) 

margins surgery_hosp, at(nhblack==(1) nhblack==(0))
margins nhblack, at(surgery_hosp==(1) surgery_hosp==(0))

margins if surgery_hosp==1, at(nhblack==1) at(nhblack==0)
margins if surgery_hosp==1, dydx(nhblack)

margins if surgery_hosp==0, at(nhblack==1) at(nhblack==0)
margins if surgery_hosp==0, dydx(nhblack)

margins if surgery_hosp==1 & nhblack==1 //n=580
margins if surgery_hosp==1 & nhblack==0 //n=1758
margins if surgery_hosp==0 & nhblack==1 //n=5272
margins if surgery_hosp==0 & nhblack==0 //n=16,399

margins nhblack, at(surgery_hosp==(1) surgery_hosp==(0)) post
matlist e(b)
lincom _b[1._at#1.nhblack] - _b[1._at#0.nhblack]	// 0.0267, p<0.001 
lincom _b[2._at#1.nhblack] - _b[2._at#0.nhblack] // 0.0404, p<0.001


*-------------------
* 5 min interval 
*-------------------

tab nhblack if spo2_value>=92 & sao2_spo2_5min_ind==1 & surgery_hosp==1 

* model
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
					age male `comorbid' `diagnoses' o2_lpm	if spo2_value>=92 & sao2_spo2_5min_ind==1 & surgery_hosp==1 , vce(cluster patienticn)	

margins nhblack					
margins if nhblack==1, at(spo2=(92(1)100)) 
margins if nhblack==0, at(spo2=(92(1)100)) 

margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult5surg, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("5 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("") ///
				ylabel(0(.1).6, labsize(small) angle(0) gmin gmax)	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off)

	*graph save "occult5surg" "Figures\fig2_5min_surg_20220309.gph", replace

margins nhblack, at(spo2=(92(1)100)) contrast
marginsplot, name(occult5contrastsurg, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("5 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("") ///
			 ylabel(-0.3(0.1)0.3, labsize(small) angle(0) gmin gmax)	///
			 xlabel(, labsize(small))		
	
	*graph save "occult5contrastsurg" "Figures\fig2_contrast5min_surg_20220309.gph", replace

	
margins , at(nhblack==1) at(nhblack==0) post //11.9, 10.7
matlist e(b)
lincom _b[2._at] - _b[1._at]	
lincom _b[1._at] - _b[2._at] 	


*------------------
* 2 min interval
*------------------

tab nhblack if spo2_value>=92 & sao2_spo2_2min_ind==1 & surgery_hosp==1 

* model
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
					age male `comorbid' `diagnoses' o2_lpm	if spo2_value>=92 & sao2_spo2_2min_ind==1 & surgery_hosp==1  , vce(cluster patienticn)	

margins nhblack, at(spo2=(92(1)100)) 
marginsplot , name(occult2surg, replace) ///
				recast(line) recastci(rarea) ///
				graphregion(color(white)) plotregion(color(white)) ///
				title("2 Minute Interval", color(black) size(medsmall))		///
				xtitle("Pulse Oximetry", size(small) margin(medium)) 		///
				ytitle("Probability of Occult Hypoxemia", size(small)) ///
				ylabel(0(.1).6, labsize(small) angle(0) gmin gmax)	///
				xlabel(, labsize(small))		///
				plot1opts(lpattern("--"))  ///
				plot2opts(lpattern("--"))  ///
				legend(off) 	

	*graph save "occult2surg" "Figures\fig2_2min_surg_20220309.gph", replace
			

margins nhblack, at(spo2=(92(1)100)) contrast
marginsplot, name(occult2contrastsurg, replace) 							///
			 recast(line) plot1opts(lcolor(gs8)) 		///
			 ciopt(color(black%20)) recastci(rarea)  	///
			 graphregion(color(white)) plotregion(color(white)) ///
			 title("2 Minute Interval" , size(medsmall) color(black))		///
			 xtitle("Pulse Oximetry" , size(small) margin(medium)) 		///
			 ytitle("Racial Difference in Probability of Occult Hypoxemia", size(small)) ///
			 ylabel(-0.3(0.1)0.3, labsize(small) angle(0) gmin gmax)	///
			 xlabel(, labsize(small))		
	
	*graph save "occult2contrastsurg" "Figures\fig2_contrast2min_surg_20220309.gph", replace
	
margins , at(nhblack==1) at(nhblack==0) post 
matlist e(b)
lincom _b[2._at] - _b[1._at]	
lincom _b[1._at] - _b[2._at] 	


graph combine occult2surg occult5surg occult10surg, ///
				rows(1) fysize(50) iscale(0.5) imargin(2 2 2 2) graphregion(color(white)) ///
				title("White and Black Surgical Patients", size(small) just(left) position(11) color(black)) ///
				name(surgcombine, replace)

graph combine occult2contrastsurg occult5contrastsurg occult10contrastsurg, ///
				rows(1) fysize(50) iscale(0.5) imargin(0.5 0.5 0.5 0.5) graphregion(color(white)) ///
				title("White and Black Surgical Patients", size(small) just(left) position(11) color(black)) ///
				name(surgcontrastcombine, replace) 


************************
* Appendix 5 
************************

** Preparing data for Appendix 5: Calibration Plots **

* all races
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

logit sao2_less88 i.race_3cat##c.spo2_value c.spo2_value#c.spo2_value 	///
					age male `comorbid' `diagnoses'	o2_lpm if spo2_value>=92 , vce(cluster patienticn)	or
predict pr_all if e(sample)

* black 
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

logit sao2_less88 c.spo2_value##c.spo2_value age male `comorbid' `diagnoses' o2_lpm /// 
				if spo2_value>=92 & nhblack==1, vce(cluster patienticn)	or
predict pr_bl if e(sample)

* white 
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

logit sao2_less88 c.spo2_value##c.spo2_value age male `comorbid' `diagnoses' o2_lpm /// 
				if spo2_value>=92 & nhblack==0, vce(cluster patienticn)	or
predict pr_wh if e(sample)
		
* hispanic
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

logit sao2_less88 c.spo2_value##c.spo2_value age male `comorbid' `diagnoses' o2_lpm /// 
				if spo2_value>=92 & hispanic==1, vce(cluster patienticn)	or
predict pr_hisp if e(sample)


* save datasets to import in R to make Karandeep calibration plots 

* create id for each observation 
gen n = _n 

* create hypoxemia indicator 
gen hypoxemia = .
replace hypoxemia = 1 if sao2_less88==1 & spo2_value>=92
replace hypoxemia = 0 if sao2_less88==0 & spo2_value>=92

tab hypoxemia, m
tab hypoxemia race_3cat, co

* all races
preserve 
	keep n hypoxemia pr_all 
	*save Data\karandeep_all, replace 
restore 

* black 
preserve 
	keep if race_3cat==2
	keep n hypoxemia pr_bl 
	*save Data\karandeep_black, replace 
restore 

* white 
preserve 
	keep if race_3cat==1
	keep n hypoxemia pr_wh
	*save Data\karandeep_white, replace 
restore 

* hispanic 
preserve 
	keep if race_3cat==3
	keep n hypoxemia pr_hisp 
	*save Data\karandeep_hispanic, replace 
restore 

drop n

						
********************************************************************************
* Analyzing patient-days with 2 pairs per day for section:
* Patient-level divergence between first and second spo2-sao2 pairs
********************************************************************************
	
* keep only patients who have 2 pairs in a day for remaining analyses
keep if pairs_tot==2
count //3016
					
* show relationship between difference in pairs between 1st & 2nd readings
gen spo2sao2_diff = spo2_value-sao2_value

bysort nhblack: sum spo2sao2_diff, det
histogram spo2sao2_diff, by(nhblack,	graphregion(fcolor(white))) bgcolor(white) ///
			text(0.18 50 	///
			"Mean = "		///	
			"Median (IQR) = "	///
			, just(right) size(small) )

bysort patienticn datevalue: gen firstpair_diff = spo2sao2_diff[pairs_num[1]]
bysort patienticn datevalue: gen secondpair_diff = spo2sao2_diff[pairs_num[2]]

* difference between the first pair difference and second pair difference
gen diff_pairdiff = (secondpair-firstpair) if pairs_num==1
sum diff_pairdiff, det

bysort black: sum diff_pairdiff, det
	
histogram diff_pairdiff, by(black, graphregion(fcolor(white)) bgcolor(white)) ///
						 name(diff, replace)

* difference between the first pair difference and second pair difference
* if both first and second pairs have spo2>=92
bysort patienticn datevalue: gen spo2_both92_ind = 1 if spo2_value[pairs_num[1]]>=92 & spo2_value[pairs_num[2]]>=92						 
replace spo2_both92_ind=0 if missing(spo2_both92_ind)
tab nhblack spo2_both92_ind

histogram diff_pairdiff if spo2_both92_ind==1, by(nhblack, graphregion(fcolor(white)) bgcolor(white)) ///
										   percent name(diff92, replace) ///
										   graphregion(color(white)) plotregion(color(white)) ///
										   xtitle("2nd Pair - 1st Pair Difference", size(medsmall) margin(medium)) 		///
										   ytitle(, size(medsmall)) ///
										   ylabel(0(10)50, labsize(small) angle(0))	///
										   xlabel(, labsize(small))	///
										   lcolor(navy) fcolor(navy*0.7) 

	*graph save "diff92" "Figures\histogram_diff92_20220331.gph", replace
						 
* difference between the first pair difference and second pair difference,
* top-coded at 15 
gen diff_pairdiff_topcode = (secondpair-firstpair) if pairs_num==1			
replace diff_pairdiff_topcode = 15 if diff_pairdiff_topcode>15 & !missing(diff_pairdiff_topcode)
replace diff_pairdiff_topcode = -15 if diff_pairdiff_topcode<-15 & !missing(diff_pairdiff_topcode)

histogram diff_pairdiff_topcode, by(black,	graphregion(fcolor(white))) bgcolor(white) ///
								name(diff_topcode, replace)

* difference between the first pair difference and second pair difference
* if both first and second pairs have spo2>=92, top-coded at 15
table nhblack if spo2_both92_ind==1, c(n diff_pairdiff_topcode median diff_pairdiff_topcode p25 diff_pairdiff_topcode p75 diff_pairdiff_topcode)
table nhblack if spo2_both92_ind==1, c(n diff_pairdiff_topcode mean diff_pairdiff_topcode sd diff_pairdiff_topcode)
	// reported in Results, Patient-level divergence between first and second Pairs, para.2

histogram diff_pairdiff_topcode if spo2_both92_ind==1, by(nhblack, graphregion(fcolor(white)) bgcolor(white)) ///
										   percent name(diff92topcode, replace) ///
										   graphregion(color(white)) plotregion(color(white)) ///
										   xtitle("2nd Pair - 1st Pair Difference", size(medsmall) margin(medium)) 		///
										   ytitle(, size(medsmall)) ///
										   ylabel(0(10)30, labsize(small) angle(0))	///
										   xlabel(-15(5)15, labsize(small))	///
										   lcolor(navy) fcolor(navy*0.7) 
										   
	*graph save "diff92topcode" "Figures\histogram_diff92topcode_20220331.gph", replace

*-------------------------------------------------------------------------------
* Predictive Margins for Patients who Have 2 Pairs & both Pairs SpO2>=92
*-------------------------------------------------------------------------------

* identify patients with 2 pairs that are both spo2>=92
bysort patienticn datevalue: egen spo2_92ormore_pair = sum(spo2_92ormore)

*tertiles of difference 
sort patienticn datevalue pairs_num
gen spo2sao2_diff_firstpair = spo2sao2_diff if pairs_num==1
bysort patienticn datevalue (pairs_num): replace spo2sao2_diff_firstpair=spo2sao2_diff_firstpair[_n-1] if pairs_num==2
xtile spo2sao2_diff_firstpair_tert = spo2sao2_diff_firstpair if pairs_num==2, nq(3)
label def spo2sao2_diff_firstpair_tert 1 "Tertile 1" 2 "Tertile 2" 3 "Tertile 3"
label val spo2sao2_diff_firstpair_tert spo2sao2_diff_firstpair_tert
bysort spo2sao2_diff_firstpair_tert: sum spo2sao2_diff_firstpair, de 
	// reported in Results, Patient-level divergence between first and second Pairs, para.1

*---------------------		
* Figure 3 Legend 
*---------------------
		
* tertile difference among Black patients 
logit sao2_less88 i.spo2sao2_diff_firstpair_tert#c.spo2_value c.spo2_value#c.spo2_value if pairs_num==2 & spo2_92ormore_pair==2 & nhblack==1
margins 

margins i.spo2sao2_diff_firstpair_tert , at(spo2_value=92) //Black@92%: T1=12.9%, T2=10.2%, T3=39.6%
margins i.spo2sao2_diff_firstpair_tert , at(spo2_value=98) //Black@98%: T1=7.5%, T2=5.8%, T3=28.4%

margins i.spo2sao2_diff_firstpair_tert if inrange(spo2_value, 92, 93)
margins i.spo2sao2_diff_firstpair_tert if inrange(spo2_value, 98, 99)

* tertile difference among White Patients 
logit sao2_less88 i.spo2sao2_diff_firstpair_tert#c.spo2_value c.spo2_value#c.spo2_value if pairs_num==2 & spo2_92ormore_pair==2 & nhblack==0
margins 

margins i.spo2sao2_diff_firstpair_tert , at(spo2_value=92) //White@92%: T1=2.7%, T2=2.4%, T3=32.0%
margins i.spo2sao2_diff_firstpair_tert , at(spo2_value=98) //white@98%: T1=2.4; T2=2.1; T3=3.4

margins i.spo2sao2_diff_firstpair_tert if inrange(spo2_value, 92, 93)
margins i.spo2sao2_diff_firstpair_tert if inrange(spo2_value, 98, 99)


*-------------------------------------------------------------------------------
* Predictive Margins on Second Pair for Patients who Have 2 Pairs 
* & first pair has/doesn't have occult hypoxemia
*-------------------------------------------------------------------------------
* hypoxemia on first pair
gen hypoxemia_firstpair = 1 if spo2_value>=92 & sao2_less88 & pairs_num==1
replace hypoxemia_firstpair = 0 if hypoxemia_firstpair==.

bysort patienticn datevalue: egen hypoxemia_firstpair_ind = max(hypoxemia_firstpair)

tab hypoxemia_firstpair_ind if pairs_num==1
tab nhblack hypoxemia_firstpair_ind if pairs_num==1

* not hypoxemic on first pair 
gen nohypoxemia_firstpair = 1 if spo2_value>=92 & sao2_less88==0 & pairs_num==1
replace nohypoxemia_firstpair = 0 if nohypoxemia_firstpair==.

bysort patienticn datevalue: egen nohypoxemia_firstpair_ind = max(nohypoxemia_firstpair)

tab nohypoxemia_firstpair_ind if pairs_num==1
tab nhblack nohypoxemia_firstpair_ind if pairs_num==1

* hypoxemia on second pair
gen hypoxemia_secpair = 1 if spo2_value>=92 & sao2_less88 & pairs_num==2
replace hypoxemia_secpair = 0 if hypoxemia_secpair==.

bysort patienticn datevalue: egen hypoxemia_secpair_ind = max(hypoxemia_secpair)

tab hypoxemia_firstpair_ind hypoxemia_secpair_ind if nhblack==0, ro
tab hypoxemia_firstpair_ind hypoxemia_secpair_ind if nhblack==1, ro

drop hypoxemia_firstpair


* for white patients
//hypoxemia present on first pair
logit sao2_less88 c.spo2_value if pairs_num==2 & spo2_value>=92 & nhblack==0 & hypoxemia_firstpair_ind==1
margins //79.8

//hypoxemia NOT present on first pair (nohypoxemia_firstpair_ind)
logit sao2_less88 c.spo2_value if pairs_num==2 & spo2_value>=92 & nhblack==0 & nohypoxemia_firstpair_ind==1
margins //2.5; reported in Results, Patient-level divergence between first and second Pairs, para.2


* for black patients
//hypoxemia present on first pair
logit sao2_less88 c.spo2_value if pairs_num==2 & spo2_value>=92 & nhblack==1 & hypoxemia_firstpair_ind==1
margins //71.4


//hypoxemia NOT present on first pair (nohypoxemia_firstpair_ind)
logit sao2_less88 c.spo2_value if pairs_num==2 & spo2_value>=92 & nhblack==1 & nohypoxemia_firstpair_ind==1
margins //6.5; reported in Results, Patient-level divergence between first and second Pairs, para.2


log close
 
