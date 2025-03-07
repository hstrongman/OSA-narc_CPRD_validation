
capture log close
log using "$logdir\31n.cr_problemfile.txt", text replace

/*******************************************************************************
# Stata do file:    31n.cr_problemfile
#
# Author:      Helen Strongman
#
# Date:        28/08/2024
#
# Description: 	This do file identifies and counts "problem" records associated with 
#				sleep disorder diagnoses. Most index dates are not associated
#				with a problem record so decided not to use this for the validation
#				study.
#
# Before running this do file: 
#				Extract data
#					
# Inspired and adapted from: 
# 				N/A
#
*******************************************************************************/



local i=1
qui foreach medcondition in narcolepsy OSA { 


**probobside from define records
if "`medcondition'" == "OSA" import delimited using "$datadir_raw/define/sleep_apnoea_aurum_Define_Inc1_Observation_001.txt", varnames(1) case(lower) stringcols(_all) clear
if "`medcondition'" == "narcolepsy" import delimited using "$datadir_raw/define/`medcondition'_aurum_Define_Inc1_Observation_001.txt", varnames(1) case(lower) stringcols(_all) clear
keep patid probobsid obsdate
destring patid, replace
gen evdate = date(obsdate, "DMY")
format evdate %td
drop obsdate
replace evdate = date("01/01/1800", "DMY") if evdate == . /*this means that
people with coded events not associated with a date will have a diagnosis
date of 01/01/1800 and be excluded from the study population because this
is before their date of birth - NOT IN PROTOCOL*/ 
label variable evdate "Date associated with the event"
distinct patid probobsid evdate, joint
duplicates drop

*keep first record = indexdate
bysort patid (evdate): keep if _n ==1


**merge with linked cohort
merge m:1 patid using "$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_aurum_linked.dta"

drop if _merge == 2

gen problem = 0
replace problem = 1 if _merge == 3

noi di "`medcondition'"
noi tab problem, m



}


capture log close



