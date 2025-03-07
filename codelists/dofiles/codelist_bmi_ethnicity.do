
/*******************************************************************************
* Stata script:   codelist_bmi_ethnicity.do
*
* Author:      Helen Strongman
*
* Date:       14/08/2024
*
* Description: 	Use BMI and ethnicity code lists from main study.
*				Update projectmedcode
*
* Before running this do file: copy code lists from main project to olddir 
	
* Inspired and adapted from: 
				
*******************************************************************************/

clear all
set more off
cap log close
log using "$logdir/codelist_bmi_ethnicity.txt", replace text

use "$olddir/codelist_bmi_aurum.dta", clear
drop projectmedcode
merge 1:1 medcodeid using "$datadir_stata/medcodeid_projectmedcode_lookup.dta"
keep if _merge == 3
drop _merge
save "$datadir_stata/codelist_bmi_aurum.dta", replace

use "$olddir/codelist_ethnicity_aurum.dta", clear
drop projectmedcode
merge 1:1 medcodeid using "$datadir_stata/medcodeid_projectmedcode_lookup.dta"
keep if _merge == 3
drop _merge
save "$datadir_stata/codelist_ethnicity_aurum.dta", replace


capture log close
