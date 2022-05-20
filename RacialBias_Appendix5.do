clear all
cap more off
version 16.0
cap log close

local day : display %tdCYND daily("$S_DATE", "DMY")
di "`day'"

log using "Logs\racialbias_appendix5_`day'.log", replace

********************************************************************************
	
	* Project: 		Racial bias in pulse oximetry - 
	*				Appendix 5: bland altman figures
	
	* Author: 		M Sjoding 
	* Author: 		S Seelye
	
	* Date Created: 	14 MARCH 22
	* Date Updated: 	14 MARCH 22
	
********************************************************************************	


* Appendix - Bland Altman Plots
* Reported in Results, Probability of Occult Hypoxemia, para. 2


/*
Corrected program such that the x-axis is generated using the "reference standard"
only, ie the SaO2. To use this program, you need to specify the correct order
of the variables ie, "comparator" "reference standard" 
*/

capture program drop blandaltman_reference

program blandaltman_reference
syntax varlist(max=2)
// prepare for Bland Altman Interreader
tempvar diff_xy
tempvar reference
tempvar lower
tempvar higher
tempvar MW
tempvar SE
tempvar CIhigher
tempvar CIlower

generate `diff_xy'=0
generate `reference'=0
generate `lower'=0
generate `higher'=0
generate `MW'=0
generate `SE'=0
generate `CIhigher'=0
generate `CIlower'=0
              
// count the variable: how many variable are in the list?
local noofvars : word count `varlist'
display as text "The variable list of this program counts " `noofvars' " variables"
display as result " "
display as result " "

// Interreader
local x = 1
local y = 1
	foreach varx of varlist `varlist' { 
		foreach vary of varlist `varlist' {
			if `y' >`x'{
				quietly replace `reference'=`vary'
				quietly replace `diff_xy'=`varx'-`vary'
				display as result " Bland Altman Plot of `varx' and `vary' using 'vary' as reference"
				quietly sum `diff_xy'
				quietly return list
				quietly replace `MW'=r(mean)
				quietly replace `lower'=r(mean)-1.96*r(sd)
				quietly replace `higher'=r(mean)+1.96*r(sd)
				quietly replace `SE'=(r(sd))/(sqrt(r(N)))
				quietly replace `CIlower'=r(mean)-1.96*`SE'
				quietly replace `CIhigher'=r(mean)+1.96*`SE'
				display as result "- mean of difference between `varx' and `vary' is "r(mean)
				display as result "- sd of difference between `varx' and `vary' is "r(sd)
				display as result "- lower limit of difference between `varx' and `vary' is " `lower'
				display as result "- higher limit of difference between `varx' and `vary' is " `higher'
				display as result "- Limits of agreement (Reference Range for difference): " `lower' " to " `higher'
				display as result "- Mean difference:" `MW' " (CI " `CIlower' " to " `CIhigher' ")"
				display as result " "
				display as result " "
				
				label var `diff_xy' "Values"
				label var `MW' "mean of difference"
				label var `lower' "lower limit of agreement"
				label var `higher' "higher limit of agreement"
				twoway (scatter `diff_xy' `reference', msymbol(smcircle_hollow) mcolor(ebblue)) ///
				(line `MW' `reference', lcolor(red))(line `lower' `reference', lcolor(black) ) (line `higher' `reference', lcolor(black) ),  ///
				title(Bland Altman Plot, size(8)) subtitle(,size(5)) xtitle(Reference: `vary') ///
				ytitle(Difference of `varx' and `vary') caption() note(NOTE)  legend(off) 
				}
			local y = `y'+1
			}
		local y = 1
		local x =`x'+1  
}
end

capture program drop blandaltman

program blandaltman
syntax varlist(max=2)
// prepare for Bland Altman Interreader
tempvar diff_xy
tempvar avg_xy
tempvar lower
tempvar higher
tempvar MW
tempvar SE
tempvar CIhigher
tempvar CIlower

generate `diff_xy'=0
generate `avg_xy'=0
generate `lower'=0
generate `higher'=0
generate `MW'=0
generate `SE'=0
generate `CIhigher'=0
generate `CIlower'=0
              
// count the variable: how many variable are in the list?
local noofvars : word count `varlist'
display as text "The variable list of this program counts " `noofvars' " variables"
display as result " "
display as result " "

// Interreader
local x = 1
local y = 1
	foreach varx of varlist `varlist' { 
		foreach vary of varlist `varlist'{
			if `y' >`x'{
				quietly replace `avg_xy'=(`varx'+`vary')/2
				quietly replace `diff_xy'=`varx'-`vary'
				display as result " Bland Altman Plot of `varx' and `vary'"
				quietly sum `diff_xy'
				quietly return list
				quietly replace `MW'=r(mean)
				quietly replace `lower'=r(mean)-1.96*r(sd)
				quietly replace `higher'=r(mean)+1.96*r(sd)
				quietly replace `SE'=(r(sd))/(sqrt(r(N)))
				quietly replace `CIlower'=r(mean)-1.96*`SE'
				quietly replace `CIhigher'=r(mean)+1.96*`SE'
				display as result "- mean of difference between `varx' and `vary' is "r(mean)
				display as result "- sd of difference between `varx' and `vary' is "r(sd)
				display as result "- lower limit of difference between `varx' and `vary' is " `lower'
				display as result "- higher limit of difference between `varx' and `vary' is " `higher'
				display as result "- Limits of agreement (Reference Range for difference): " `lower' " to " `higher'
				display as result "- Mean difference:" `MW' " (CI " `CIlower' " to " `CIhigher' ")"
				display as result " "
				display as result " "
				
				label var `diff_xy' "Values"
				label var `MW' "mean of difference"
				label var `lower' "lower limit of agreement"
				label var `higher' "higher limit of agreement"
				twoway (scatter `diff_xy' `avg_xy', msymbol(smcircle_hollow) mcolor(ebblue)) ///
				(line `MW' `avg_xy', lcolor(red))(line `lower' `avg_xy', lcolor(black) ) (line `higher' `avg_xy', lcolor(black) ),  ///
				title(Bland Altman Plot, size(8)) subtitle(,size(5)) xtitle(Average of `varx' and `vary') ///
				ytitle(Difference of `varx' and `vary') caption() note(NOTE)  legend(off) 
				}
			local y = `y'+1
			}
		local y = 1
		local x =`x'+1  
}
end



/*Reference blandaltman, where the x axis is the reference standard and the
y-axis is the difference */ 

/*Everyone*/
clear
version 16.1
set more off

* pull in dataset
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

			histogram spo2_value 

			sum spo2_value, detail

			** SaO2 **

			* drop observations with missing SaO2
			drop if sao2_datetime==.  //n=20,651 missing

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
				* 70,153

			* drop all patients in the icu 
			drop if icu==1 //33,556
			count
				* 36,597
				
			* drop all observations that have an spo2 value less than 70 
			drop if spo2_value<70 //168
			count 
				* 36,429

			*histogram spo2_value
			*histogram sao2_value

			* drop all sao2s less than 70 (this excludes venus blood gas, which can have sao2s <70)
			drop if sao2_value<70 //6135
			count
				* 30,294

			* keep only patients with 1-2 pairs per day 

				*identify the number of spo2-sao2 matched pairs by patient-day*
				bysort patienticn datevalue (spo2_datetime): gen pairs_num = _n
				bysort patienticn datevalue (spo2_datetime): egen pairs_tot = max(pairs_num)

			keep if inlist(pairs_tot, 1, 2) 
			count
				* 30,039



*-------------------------------
* bland-altman w/o reference
*-------------------------------
blandaltman spo2_value sao2_value 

preserve 
keep if nhblack==1
blandaltman spo2_value sao2_value 
restore

preserve 
keep if nhwhite==1
blandaltman spo2_value sao2_value 
restore

preserve 
keep if race_3cat==3
blandaltman spo2_value sao2_value 
restore

*-------------------------------
* bland-altman w/ reference
*-------------------------------

** ALL RACES AND ETHNICITIES **

*** Here is the Bland Altman calculation using SaO2 as the sole reference standard for the x-axis
*** The ordering here is important, the first variable is the comparator, second is reference
blandaltman_reference spo2_value sao2_value

*** confirm that this figure looks the same when I generate it as a simple scatter
*** and the estimates looks the same
gen diff = spo2_value - sao2_value
twoway (scatter diff sao2_value, msymbol(smcircle_hollow) mcolor(ebblue)) 
sum diff

di r(mean)-1.96*r(sd)
di r(mean)+1.96*r(sd)

di sqrt(r(mean)^2 + r(sd)^2)

** WHITE PATIENTS **

preserve 
keep if nhwhite==1
blandaltman_reference spo2_value sao2_value

gen diff_white = spo2_value - sao2_value
*twoway (scatter diff_white sao2_value, msymbol(smcircle_hollow) mcolor(ebblue)) 
sum diff_white

di r(mean)-1.96*r(sd)
di r(mean)+1.96*r(sd)

di sqrt(r(mean)^2 + r(sd)^2)

restore


** BLACK PATIENTS **

preserve 
keep if nhblack==1
blandaltman_reference spo2_value sao2_value

gen diff_black = spo2_value - sao2_value
*twoway (scatter diff_black sao2_value, msymbol(smcircle_hollow) mcolor(ebblue)) 
sum diff_black

di r(mean)-1.96*r(sd)
di r(mean)+1.96*r(sd)

di sqrt(r(mean)^2 + r(sd)^2)

restore

** HISPANIC PATIENTS **

preserve 
keep if race_3cat==3
blandaltman_reference spo2_value sao2_value

gen diff_hisp = spo2_value - sao2_value
*twoway (scatter diff_hisp sao2_value, msymbol(smcircle_hollow) mcolor(ebblue)) 
sum diff_hisp

di r(mean)-1.96*r(sd)
di r(mean)+1.96*r(sd)

di sqrt(r(mean)^2 + r(sd)^2)

restore

log close
