
capture log close
log using "$logdir\32n.cr_referralfile_aurum.txt", text replace

/*******************************************************************************
# Stata do file:    32n.cr_referralfile_aurum
#
# Author:      Helen Strongman
#
# Date:        29/08/2024
#
# Description: 	This do file identifies referral records within 6 months of the
#				index date. LEAVE THIS FOR NOW - IDEALLY WOULD HAVE CODE LIST
#				FOR LETTERS AND REFERRALS
#
# Before running this do file: 
#				Extract data
#					
# Inspired and adapted from: 
# 				N/A
#
*******************************************************************************/




qui foreach medcondition in OSA narcolepsy { 


**referral records
import delimited using "$datadir_raw/`medcondition'_aurum_linked/`medcondition'_aurum_linked_Extract_Referral_001.txt", varnames(1) case(lower) stringcols(_all) clear
keep patid obsid
destring patid, replace
destring obsid, replace
isid patid obsid
gen refrecord = 1
tempfile tempref
save `tempref'

**merge with each observation file

/*create a local listing all Extract files for the filetype*/
local myfiles: dir "$datadir_raw/`medcondition'_aurum_linked/" files "*Observation*.dta", respectcase
	/*assign 1st macro (file name) in local as `1'*/
	tokenize `"`myfiles'"'
	/*start loop at i=1*/
	local i=1
	while "`1'" !="" {
		noi di "`1'"
		merge 1:1 patid obsid using "$datadir_raw/`medcondition'_aurum_linked//`1'", keep(3) nogen noreport keepusing(patid obsid evdate projectmedcode)
		if `i' > 1 append using `tempmerge'
		tempfile tempmerge
		save `tempmerge'
		local i=`i'+1
		mac shift
	}
	
	**merge with linked cohort
	merge m:1 patid using "$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_aurum_linked.dta"
	
	**merge with medcode lookup
	merge m:1 projectmedcode using "$codedir/medcodeid_projectmedcode_lookup.dta", keep(1 3) nogen noreport
	
	**merge with medical dictionary
	merge m:1 medcodeid using "$dict_aurummed", keep(1 3) nogen noreport
	gen _withinyear = 1 if abs(evdate - indexdate) <= 365.25
	tab _withinyear, m
	distinct patid if _withinyear == 1
	distinct medcodeid if _withinyear == 1
	x
	gsort patid _withinyear
	bysort term: gen _distinctterm = 1 if _n ==1
	list term if _distinctterm == 1
	gen notrelevant = 0
	local exterms = week administration admission emergency diabetes asthma migration back bleeding glucose blood breast cervi cardiolog casualty chest choice choose dermat
	replace notrelevant = 1 if strmatch(term, "2 week rule")
	
}

general - laboratory test / blood test / letter / report / admission / test / discharged / outpatient / "advice and guidance request" / "choose and book referral" / "day hospital care" / day-case / hospital / further care / "refer to physician"
specific - narcolepsy, neurology, neurologist, night terrors, sleep (including sleep clinic), fatigue, respiratory (with refer or one of above), thoracic
sleep fatigue tired neurologist neurology 


BASED ON THIS - HELPFUL TO HAVE FIVE CODE LISTS
(1) Contact with hospital specialist (non-specific) 
(2) contact with neurologist
(3) contact with respiratory clinician
(4) contact with sleep clinic
(5) blood test

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



