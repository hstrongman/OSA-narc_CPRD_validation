capture log close
log using "$logdir\9.cr_studypopulation_an_flowchart.txt", replace text

/*******************************************************************************
# Stata do file:    9.cr_studypopulation_an_flowchart.do
#
# Author:      Helen Strongman
#
# Date:        24/11/2022 (updated 29/06/2023 to remove merged practices from Aurum)
#
# Description: 	This do file restricts the all_registered_patients file for each
#				database to people included in the linked study
#				population 
#				AND currently registered in a practice that has up to date data.
# 
#				The do file additionally populates a spreadsheet with numbers
#				needed to describe how the primary care and linked study 
#				populations were defined.
#
# Protocol change: Follow-up ends 2 months before last collection date following
#					(1) advice from CPRD via email that data from currently
#					contributing practices may not be complete in the last 6 weeks
#					in the May 2022 Aurum build AND (2) Observation of missing
#					events in THIN data in the months prior to the last
#					collection date (https://onlinelibrary.wiley.com/doi/full/10.1002/pds.3981)
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/


/**************************
*** STUDY POPULATION ******
**************************/

local datasetchange = 0 /*The datasignature command is used at the end of the 
do file to check that the patient level dataset has not changed since this do
file was last run. Setting this local to 1 overides this*/

noi foreach database in aurum /*gold*/ { 
	/****  READ IN DATA SET FOR BOTH CONDITIONS  ****/
	use "$datadir_dm\4.cr_dm_all_registered_patients_`database'.dta", clear
	destring pracid, replace
	
	/**** GENERATE KEY VARIABLES **********/
	gen start_primary = max(regstartdate + 90, $studystart_primary)
	label variable start_primary "Start of follow-up in primary care cohort"
	note start_primary: "Latest of 90 days following practice registration or start of study period"

	gen end_primary = min(regenddate, lcd - 60, cprd_ddate, $studyend_primary)
	label variable end_primary "End of follow-up in primary care cohort"
	note end_primary: "Earliest of end of practice registration, end of practice data collection - 2 months, CPRD death date and end of study period"

	gen start_linked = max(regstartdate + 90, $studystart_linked)
	label variable start_linked "Start of follow-up in linked cohort"
	note start_primary: "Latest of 90 days following practice registration or start of study period"
	
	gen end_linked = min(regenddate, lcd - 60, dod, $studyend_linked)
	label variable end_primary "End of follow-up in linked cohort"
	note end_primary: "Earliest of end of practice registration, end of practice data collection - 2 months, ONS mortality death date and end of study period"
	
	gen dob = mdy(7,02,yob)
	label variable dob "date of birth"
	note dob: "Imputed as 2nd July of the birth year"
	
	gen date18 = dob + (365.25 * 18)
	label variable date18 "18th birthday"
	note date18: "Matched cohort for OSA will be restricted to 18 and over"
	
	format start_primary end_primary start_linked end_linked dob date18 %td
	 
	/*LINKAGE ELIGIBILITY: (1) For this study, more patients are eligible for linkage
	to HES APC than other HES datasets. This is because during the Covid pandemic 
	linkage of HES APC data was prioritised and therefore more up to date than other
	HES datasets (2) linkage eligibility flags are missing from practices in 
	Scotland, Wales and Northern Ireland*/
	gen _linkelig = hes_apc_e
	replace _linkelig = 0 if _linkelig == .
	replace _linkelig = 0 if ons_death_e == 0 | ons_death_e == .
	*replace _linkelig = 0 if lsoa_e == 0
	drop hes_apc_e ons_death_e lsoa_e hes_did_e
	
	/*MERGED AURUM PRACTICES: The CPRD Aurum data dictionary for this build 
	(September 2023) lists practices that have merged and continued to contribute to CPRD.
	Patients in these practices will be included twice with different patids.
	CPRD therefore advice removing these practices from the build*/
	
	local mergedprac = "20024 20469 20822 21173 21558 20036 20487 20868 21277 21585 20091 20552 20912 21281"
	local mergedprac = "`mergedprac' 20171 20554 20996 21331 20178 20640 21001 21334 20202 20734 21015 21390 20254 20737"
	local mergedprac = "`mergedprac' 21078 21444 20389 20740 21112 21451 20430 20790 21118 21529 20452 20803 21172 21553"

	gen _mergedprac = 0
	foreach prac of local mergedprac {
		replace _mergedprac = 1 if pracid == `prac'
		}
		
	
	/*IDENTIFY STUDY POPULATION*/
	
	*forvalues linked = 1 {		/*linked only*/
	local linked = 1
		
		if `linked' == 0 local linkedtext = "primary"
		if `linked' == 1 local linkedtext = "linked"
		
		noi di as yellow "set up flow chart numbers file"

		local dataset = "`database'`linkedtext'"
		capture erase "$resultdir\_`dataset'.dta"
		tempname memhold
		*tempfile results
		postfile `memhold' int criteria double `dataset' using "$resultdir\_`dataset'"
		local i = 1
		
		/*STUDY POPULATION DEFINITION*/
		
		di as yellow "number of people in CPRD build"
		gen _stillin = 0
		replace _stillin = 1
		count if _stillin == 1
		di "`r(N)'"
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "People in CPRD build", replace
		local i = `i' + 1
		
		/*CHANGE BELOW - ONLY RUNNING FOR AURUM
		di as yellow "exclude duplicate gold practices that have contributed to Aurum"
		di as yellow "these include practices that have contributed to Aurum before and after a practice merger"
		di as yellow "and gold practices that have contributed to Aurum"*/
		di as yellow "exclude practices that have contributed to Aurum before and after a practice merger"

		count if (dupgoldpractice == 1 | _mergedprac == 1) & _stillin == 1
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Duplicate practice", add
		replace _stillin = 0 if (dupgoldpractice == 1 | _mergedprac == 1) & _stillin == 1
		local i = `i' + 1
		
		
		di as yellow "exclude not acceptable"
		count if acceptable == 0 & _stillin == 1
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Not research quality", add
		replace _stillin = 0 if acceptable == 0 & _stillin == 1
		local i = `i' + 1
		
		di as yellow "exclude if gender isn't male or female"
		count if gender >2 & _stillin == 1
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Gender not recorded", add
		replace _stillin = 0 if gender >2 & _stillin == 1
		local i = `i' + 1
	
		di as yellow "exclude if not eligible for linkage"
		if `linked'== 0 post `memhold' (`i') (.)
		label define criterialab `i' "Not eligible for key linkages", add
		if `linked'== 1 {
			count if _linkelig == 0 & _stillin == 1
			post `memhold' (`i') (`r(N)')
			replace _stillin = 0 if _linkelig == 0 & _stillin == 1
			}
		local i = `i' + 1
		
		di as yellow "exclude if not followed-up during study period"
		gen _exccode = 0 if _stillin == 1
		*replace _exccode = 1 if regstartdate >= ${studyend_`linkedtext'}
		replace _exccode = 1 if regstartdate >= end_`linkedtext' & _stillin == 1
		replace _exccode = 2 if end_`linkedtext' <=  ${studystart_`linkedtext'} & _stillin == 1
		tab _exccode, m
		
		count if _exccode >= 1 & _stillin == 1
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "No follow-up in study period", add
		replace _stillin = 0 if _exccode >=1 &  _stillin == 1
		local i = `i' + 1
		
		di as yellow "exclude if less than 90 days follow-up after registration"
		count if (regstartdate + 90 >= end_`linkedtext') & _stillin == 1
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "DOLSIGN<90DOLSIGN days follow-up after registration", add
		*DOLSIGN WILL BE REPLACED WITH $ IN LATEX FLOWCHART. $ CANNOT BE USED HERE AS IT IS READ AS A MACRO
		replace _stillin = 0 if (regstartdate + 90 >= end_`linkedtext') & _stillin == 1
		local i = `i' + 1

		assert end_`linkedtext' > start_`linkedtext' if _stillin == 1
		drop _exccode
		
		/*added for validation study*/
		di as yellow "exclude if not currently registered in practice"
		count if (regenddate < lcd | dod < lcd) & _stillin == 1 /*left practice or died after lcd*/
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Left practice prior to last data collection", add
		replace _stillin = 0 if (regenddate < lcd | dod < lcd) & _stillin == 1
		local i = `i' + 1
		
		/*added for validation study*/
		di as yellow "exclude if practice has not contributed to CPRD in the 2 months prior to build creation"
		assert (month(lcd) == 5 | month(lcd) == 6) if year(lcd) == 2023
		count if year(lcd) < 2023 & _stillin == 1 /*lcd < 2 months prior to creation of current build*/
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Practice last contributed to CPRD before May 2023", add
		replace _stillin = 0 if year(lcd) < 2023 &  _stillin == 1
		local i = `i' + 1
		
		
		di as yellow "Study population count"
		count if _stillin == 1
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Study population", add
		local i = `i' + 1
		
		rename _stillin studypop_`linkedtext'
				
		postclose `memhold'
	
*} /*linked*/
	keep if studypop_linked == 1 /*| studypop_primary == 1*/
	drop _linkelig
	/*check that rerunning the file has not changed the patient level dataset.
	if this check fails, subsequent do files need to be rerun*/
    if `datasetchange' == 1 datasignature set, saving("$datadir_dm\9.cr_studypopulation_an_flowchart_`database'_signature.dtasig", replace)
	datasignature confirm using "$datadir_dm\9.cr_studypopulation_an_flowchart_`database'_signature.dtasig"
	save "$datadir_dm\9.cr_studypopulation_an_flowchart_`database'.dta", replace
} /*database*/


/*save criterialab label*/
tempfile templabel
label list criterialab
label save criterialab using `templabel'

/**************************
*** STUDY POPULATION FLOW CHART ******
**************************/


local i = 1
foreach database in /*gold*/ aurum {
	foreach linkedtext in /*primary*/ linked {
		local dataset = "`database'`linkedtext'"
		if `i' == 1 use "$resultdir\_`dataset'", clear
		pause
		if `i' > 1 {
			merge 1:1 criteria using "$resultdir\_`dataset'"
			assert _merge == 3
			drop _merge
			}
		save "$resultdir\9.cr_studypopulation_an_flowchart.dta", replace
		local i = `i' + 1
		erase "$resultdir\_`dataset'.dta"
	}
}

/*/**** ADD COLUMNS FOR AURUM AND GOLD COMBINED ***/
foreach linkedtext in primary linked {
	local name "combined`linkedtext'"
	egen `name' = rowtotal(gold`linkedtext' aurum`linkedtext')
}
*/

/****  LABEL RESULTS DATASET AND VARIABLES  ****/
label data "Study population flow chart"
do `templabel'
label values criteria criterialab
note: "exclusions in each grouping are sequential"
note: "Research quality criteria are based on CPRD's quality flag (acceptable)"
note: "Gender not recorded includes interdeterminate, unknown or missing gender"
note: "Practices that have contributed to GOLD and Aurum (duplicate practices) have been excluded from the CPRD GOLD cohort"
note: "Practices that have been identified by CPRD as contributing to Aurum before and after a practice merger have been excluded"
note: "Key linkages are HES APC, ONS mortality and area based linkages"
note: "Follow-up in CPRD starts at registration and ends at the latest of transfer out of practice, death or 2 months prior to the last collection date"
note: "The last collection dates for the September 2023 CPRD Aurum build are in June 2023."

compress
save "$resultdir\9.cr_studypopulation_an_flowchart.dta", replace
export excel using "$resultdir\9.cr_studypopulation_an_flowchart.xlsx", replace firstrow(variables)

capture log close





