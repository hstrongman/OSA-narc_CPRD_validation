
capture log close
log using "$logdir\33n.cr_edsdrugs_aurum.txt", text replace

/*******************************************************************************
# Stata do file:    33n.cr_edsdrugs_aurum
#
# Author:      Helen Strongman
#
# Date:        26/11/2024
#
# Description: 	This do file identifies drugs to treat excessive daytime
#				sleepiness (narcolepsy only)
#
# Before running this do file: 
#				Extract data
#					
# Inspired and adapted from: 
# 				N/A
#
*******************************************************************************/

**Drug issue records for narcolepsy incident cohort
use "$datadir_raw/narcolepsy_aurum_linked/narcolepsy_aurum_linked_Extract_DrugIssue_001.dta", clear
distinct patid
keep patid issuedate projectprodcode

**Merge with codelists
foreach edsdrug in dexamfetamine modafinil methylphenidate {
	merge m:1 projectprodcode using "$codedir/codelist_`edsdrug'_aurum.dta", keepusing(projectprodcode)
	gen _`edsdrug' = 0
	replace _`edsdrug' = 1 if _merge == 3
	drop if _merge == 2
	drop _merge
	tab _`edsdrug', m
}

gen edsdrug = 1 if _dexamfetamine == 1 | _modafinil == 1 | _methylphenidate == 1
keep if edsdrug == 1
distinct patid

/**Very few patients have a code for an EDS drug
*sense check with raw data
import delimited using "$datadir_raw/narcolepsy_aurum_linked/narcolepsy_aurum_linked_Extract_DrugIssue_001.txt", varnames(1) case(lower) stringcols(_all) clear
merge m:1 prodcodeid using "$codedir/codelist_dexamfetamine_aurum.dta", keepusing(prodcodeid)
distinct patid if _merge == 3 /*106 distinct patients - same as above*/
*/

bysort patid (issuedate): keep if _n == 1
keep patid edsdrug issuedate
**merge with linked cohort
merge m:1 patid using "$datadir_dm\10.cr_incidentcohort_an_flowchart_narcolepsy_aurum_linked.dta", keepusing(patid)
drop _merge
replace edsdrug = 0 if edsdrug == .
tab edsdrug, m
label variable edsdrug "At least one prescription for EDS drug"

rename issuedate edsdrugdate
label variable edsdrugdate "Date of first EDS drug prescription"

save "$datadir_dm/33n.cr_edsdrugs_aurum", replace

capture log close



