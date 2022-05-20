/*************************************************	
	Step 1. Clean SaO2 values for analysis
	
	Author: S Seelye
	
	Date created: 22 FEB 2021
	Last Updated: 22 FEB 2021		
**************************************************/

clear all
cap log close
cap more off
version 16.0

cd "”

local day : display %tdCYND daily("$S_DATE", "DMY")
di "`day'"

log using "Logs\step1_cleaning_sao2_`day'.log", replace

* drop all observations with indeterminant sao2 values 
drop if sao2==. 

* drop those with missing lab values 
drop if labchemresultnumericvalue==.

* drop those that are >100 or <0
drop if labchemresultnumericvalue<0 | labchemresultnumericvalue>100)

** Step 1 **

* identify cases with different lab values
bysort patienticn labchemspecimendatetime: gen difflabval = 1 if labchemresultnumericvalue!=labchemresultnumericvalue[_n-1] & _n!=1
order difflabval, after(labchemresultnumericvalue)
replace difflabval=0 if difflabval==.

bysort patienticn labchemspecimendatetime: gen numdifflabval = sum(difflabval)
order numdifflabval, after(difflabval)
tab numdifflabval

bysort patienticn labchemspecimendatetime: egen maxnumdifflabval = max(numdifflabval) 

* calculate # dups that have two or more different sao2 values
replace sao2=0 if sao2==. 

	
* investigate sao2 values 
bysort patienticn labchemspecimendatetime: gen sao2difflabval = 1 if labchemresultnumericvalue!=labchemresultnumericvalue[_n-1] & _n!=1
order sao2difflabval, after(labchemresultnumericvalue)
replace sao2difflabval=0 if sao2difflabval==.
	
tab sao2difflabval
	
bysort patienticn labchemspecimendatetime: gen sao2numdifflabval = sum(sao2difflabval)
order sao2numdifflabval, after(sao2difflabval)
tab sao2numdifflabval

bysort patienticn labchemspecimendatetime: egen sao2maxnumdifflabval = max(sao2numdifflabval) 
tab sao2maxnumdifflabval

bysort patienticn labchemspecimendatetime: gen uniqsao2 = _n 
tab uniqsao2 
	
tab sao2maxnumdifflabval if uniqsao2==1
tab sao2maxnumdifflabval , m

* save a temporary file of the sao2 values that are not dups 
tempfile sao2prep
save `sao2prep' 
		
* only keep those with dups to investigate labchemtestnames
keep if sao2maxnumdifflabval>=1
order uniqid uniqsao2 patienticn labchemspecimendatetime labchemresultnumericvalue shortaccessionnumber labchemtestname
keep uniqid uniqsao2 patienticn labchemspecimendatetime labchemresultnumericvalue shortaccessionnumber labchemtestname

drop uniqid 
sort patienticn labchemresultnumericvalue
egen group = group(patienticn labchemspecimendatetime)
	
reshape wide shortaccessionnumber labchemtestname labchemresultnumericvalue, i(group) j(uniqsao2)
order group labchemresultnumericvalue1 labchemresultnumericvalue2 labchemtestname1 labchemtestname2 shortaccessionnumber1 shortaccessionnumber2
	
gen sao2labnames = labchemtestname1
forval j = 2/6 {
replace sao2labnames = labchemtestname1 + " ; " + labchemtestname`j' if labchemtestname`j' != ""
}
tab sao2labnames, sort
ssc install groups
groups sao2labnames
groups sao2labnames, show(f p)
	
browse 	sao2labnames labchemresultnumericvalue1 						///
			labchemresultnumericvalue2 labchemtestname1 labchemtestname2 	///
			shortaccessionnumber1 shortaccessionnumber2 			///
			if sao2labnames=="O2HB% (SAT) ; O2 (SAT)"
	
browse 	sao2labnames labchemresultnumericvalue1 						///
			labchemresultnumericvalue2 labchemtestname1 labchemtestname2 	///
			shortaccessionnumber1 shortaccessionnumber2 			///
			if sao2labnames=="POC-HHB ; POC-SO2"
	
browse 	sao2labnames labchemresultnumericvalue1 						///
			labchemresultnumericvalue2 labchemtestname1 labchemtestname2 	///
			shortaccessionnumber1 shortaccessionnumber2 			///
			if sao2labnames=="i-sO2 ; SpO2"
	
browse 	sao2labnames labchemresultnumericvalue1 						///	labchemresultnumericvalue2 labchemtestname1 labchemtestname2 	///
	shortaccessionnumber1 shortaccessionnumber2 					///
	if sao2labnames=="OXYGEN (O2) SATURATION % ; OXYGEN (O2) SATURATION %"
	
browse 	sao2labnames labchemresultnumericvalue1 						///
	labchemresultnumericvalue2 labchemtestname1 labchemtestname2 	///
	shortaccessionnumber1 shortaccessionnumber2 					///
	if sao2labnames=="_O2 SAT LOW ; _O2 SAT"
	
browse 	sao2labnames labchemresultnumericvalue1 						///
	labchemresultnumericvalue2 labchemtestname1 labchemtestname2 	///
	shortaccessionnumber1 shortaccessionnumber2 					///
	if sao2labnames=="SpO2 ; i-sO2"
	
browse
	
* "POC-HHB" should be dropped; recode these to missing and drop after reshaping 
forval i = 1/6 {
replace labchemtestname`i' = "." if labchemtestname`i' == "POC-HHB"
}
		
* "SpO2" should be dropped; recode these to missing and drop after reshaping
forval i = 1/6 {
replace labchemtestname`i' = "." if labchemtestname`i' == "SpO2"
}
	
* for the "OXYGEN (O2) SATURATION %; OXYGEN (O2) SATURATION %", 
* recode to missing the lab with the lowest value (this will typically
* be the first value)
replace labchemresultnumericvalue1 = . if labchemresultnumericvalue1<labchemresultnumericvalue2 & sao2labnames=="OXYGEN (O2) SATURATION % ; OXYGEN (O2) SATURATION %"
replace labchemresultnumericvalue2 = . if labchemresultnumericvalue2<labchemresultnumericvalue1 & sao2labnames=="OXYGEN (O2) SATURATION % ; OXYGEN (O2) SATURATION %" & !missing(labchemresultnumericvalue1) & !missing(labchemresultnumericvalue2)

* "O2 SAT LOW" should be dropped; recode these to missing and drop after reshaping
forval i = 1/6 {
replace labchemtestname`i' = "." if labchemtestname`i' == "_O2 SAT LOW"
}
		
* "O2 SAT (%O2HB)" should be dropped; recode these to missing and drop after reshaping
forval i = 1/6 {
replace labchemtestname`i' = "." if labchemtestname`i' == "O2 SAT (%O2HB)"
}
		
* "O2 HGB SAT-sEA" should be dropped; recode these to missing and drop after reshaping
forval i = 1/6 {
	replace labchemtestname`i' = "." if labchemtestname`i' == "O2 HGB SAT-sEA"
}
		
* "O2 SATURATION (BU/CN/SY)" should be dropped; recode these to missing and drop after reshaping
forval i = 1/6 {
	replace labchemtestname`i' = "." if labchemtestname`i' == "O2 SATURATION (BU/CN/SY)"
}
		
	
* rename all blank labchemtestname to "."
forval i = 1/6 {
	replace labchemtestname`i' = "." if labchemtestname`i' == ""
}
		
		
* drop variables we no longer need
drop sao2labnames shortaccessionnumber* 
		
* reshape back to long
reshape long labchemtestname labchemresultnumericvalue, i(group) j(uniqsao2)

* after reshaping to long, drop the observations with missing 
* labchemtestnames or missing labchemresultnumericvalues. these were
* recoded to missing above to signify tests that need to be dropped.
drop if labchemtestname=="."

* drop missing labchemresultnumericvalue
drop if labchemresultnumericvalue==.
		
* check remaining duplicates 
duplicates report patienticn labchemspecimendatetime
duplicates tag patienticn labchemspecimendatetime, gen(dup)
		
br if dup==1
	
tab dup 
		
br
		
* reshape duplicates back to wide to examine these remaining pairs 
* first, create new uniqsao2 number
drop uniqsao2 
bysort patienticn labchemspecimendatetime: gen uniqsao2 = _n 
		
reshape wide labchemtestname labchemresultnumericvalue, i(group) j(uniqsao2)

tab dup // (77/5379 or 1.4%)
sort labchemtestname1
br if dup==1
		
br 
		
* for the "OXYGEN (O2) SATURATION %; OXYGEN (O2) SATURATION %", 
* recode to missing the lab with the lowest value 
replace labchemresultnumericvalue1 = . if labchemresultnumericvalue1<labchemresultnumericvalue2 & labchemtestname1=="OXYGEN (O2) SATURATION %" & labchemtestname2=="OXYGEN (O2) SATURATION %"
		
* for the remaining duplicates, replace the lowest of the two numeric values with missing 
replace labchemresultnumericvalue1 = . if labchemresultnumericvalue1<labchemresultnumericvalue2 & !missing(labchemresultnumericvalue1) & !missing(labchemresultnumericvalue2)

replace labchemresultnumericvalue2 = . if labchemresultnumericvalue2<labchemresultnumericvalue3 & !missing(labchemresultnumericvalue2) & !missing(labchemresultnumericvalue3)

replace labchemresultnumericvalue3 = . if labchemresultnumericvalue3<labchemresultnumericvalue4 & !missing(labchemresultnumericvalue3) & !missing(labchemresultnumericvalue4)

replace labchemresultnumericvalue4 = . if labchemresultnumericvalue4<labchemresultnumericvalue5 & !missing(labchemresultnumericvalue4) & !missing(labchemresultnumericvalue5)

* replace to missing the labtestnames with missing labchemresultnumericvalue
replace labchemtestname1="." if labchemresultnumericvalue1==.
replace labchemtestname2="." if labchemresultnumericvalue2==.
replace labchemtestname3="." if labchemresultnumericvalue3==.
replace labchemtestname4="." if labchemresultnumericvalue4==.

* reshape back to long 
reshape long labchemtestname labchemresultnumericvalue, i(group) j(uniqsao2)

* drop missing labchemtestnames & labchemresultnumericvalues 
drop if labchemtestname=="." | labchemtestname==""
		
duplicates report patienticn labchemspecimendatetime
		
count 
		
drop group uniqsao2 dup
		
* tempfile of cleaned dup 
tempfile sao2dup
save `sao2dup'
		
restore 

* append cleaned duplicates dataset  with the full sao2 datatset
use `sao2prep', clear 
append using `sao2dup'		

* drop the original duplicates from the sao2 file
tab sao2maxnumdifflabval , m //missing values are from the cleaned dups file
drop if inlist(sao2maxnumdifflabval, 1, 2, 3, 4, 5) //these are dups that have been cleaned 

* doublecheck that there aren't any duplicates
duplicates report patienticn labchemspecimendatetime

* keep only variables we still need	
keep patienticn labchemresultnumericvalue labchemspecimendatetime ///
		labchemtestname labspecimendate clean_unit

gen lab = "sao2"		
		
* save final sao2 dataset 
save "sao2_cleaned.dta", replace 

log close
