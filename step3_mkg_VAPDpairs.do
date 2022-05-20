/*******************************************************************************
	
	Step 3. Creating a single dataset that combines SpO2-SaO2  
		pairs with the VAPD
	
	Author: 	S Seelye
	
	Date Created: 	5 AUG 2021
	Date Updated: 	5 AUG 2021
	
*******************************************************************************/	
 
clear all
cap more off
version 16.0

cd ""

*********************
* SaO2-SpO2 Dataset *
*********************
use Data\sao2_spo2_pairs_20132019,	clear 

* create a new variable to distinguish spo2_values in the matched pair 
* dataset with sao2 in case the spo2 values differ for particular datetimes 
* across the various datasets 
rename spo2_value spo2_value_sao2pair 

* keep only those pairs that occur within a 10-min time period 
keep if inrange(sao2_spo2_min_diff, -10, 10)

* save tempfile 
count
	* 90,336

tempfile sao2spo2
save `sao2spo2'

*******************
* Merge with VAPD *
*******************
* Merging with the VAPD will need to be done in individual years because 
* of space issues in Stata. 

forval i=2013/2019 {

import sas 	sta3n sta6a specialty icu admityear new_dischargedate3 			///
			inhosp_mort mort30_admit datevalue new_admitdate3 patienticn 	///
			chf cardic_arrhym valvular_d2 pulm_circ pvd paralysis neuro 	///
			pulm dm_uncomp dm_comp hypothyroid renal liver pud ah lymphoma 	///
			cancer_met cancer_nonmet ra coag obesity wtloss fen anemia_cbl 	///
			anemia_def etoh drug psychoses depression gender hosp_los 		///
			singlelevel_ccs multilevel1_ccs cardio_sofa any_pressor_daily 	///
			coagulation_sofa renal_sofa liver_sofa elixhauser_vanwalraven 	///
			cdc_hosp_sepsis angus_def_sepsis new_teaching region ethnicity 	///
			hispanic htn female Rurality race  dod age unique_hosp_count_id ///
			using "Data\vapd`i'", case(lower) clear
  				
tab admityear 

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

* merge with pairs 
merge 1:m patienticn datevalue using `sao2spo2'

* keep only those that are matched 
keep if _merge==3
drop _merge 

count
tab admityear

* organize dataset 
drop merge* 

order patienticn datevalue admityear sta6a sta3n race gender ethnicity hispanic female

drop year

* save dataset 
save Data\vapd_spo2sao2pairs, replace

log close
