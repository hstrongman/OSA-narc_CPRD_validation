capture log close
log using "$logdir\11.cr_validationcohort_an_flowchart.txt", replace text

/*******************************************************************************
# Stata do file:    11.cr_validationcohort_an_flowchart.do
#
# Author:      Helen Strongman
#
# Date:       05/01/2024.
#
# Description: 	This do file flags people in the validation study cohort.
#				Restrictions are baesd on post-protocol decisions recorded in
#				the manuscript.
# 
#				The do file additionally populates a spreadsheet with numbers
#				needed to describe how the primary care and linked study 
#				populations were defined. Symbols are written in Latex code
#				with "DOLSIGN" replacing "$" to avoid confusion with macros in
#				Stata
#				THIS SPREADSHEET IS RECREATED IN 11a...do
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off
local datasetchange = 0 /*The datasignature command is used at the end of the 
do file to check that the patient level dataset has not changed since this do
file was last run. Setting this local to 1 overides this*/


local j = 1 /*dataset indicator*/
foreach database in aurum /*gold*/ {
	/****  READ IN INCIDENT COHORT DATA  ****/
		foreach linkedtext in /*primary*/ linked {
			foreach medcondition in OSA narcolepsy {
				use "$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", clear
				
				/*** SET UP RESULTS FILE FOR EACH COHORT ***/
				local dataset = "`database'`linkedtext'`medcondition'"
				capture erase "$resultdir\_`dataset'.dta"
				tempname memhold
				postfile `memhold' int criteria double `dataset' using "$resultdir\_`dataset'"
				local i = 1
				
				/*** DEFINE VALIDATION COHORT ***/
				post `memhold' (`i') (.)
				label define criterialab `i' "VALIDATION COHORT", add
				local i = `i' + 1
				
				gen _stillin = 1
				di as yellow "Practice has at least 1 eligible narcolepsy case"
				count if narcolepsypraccount >= 1 & _stillin == 1
				local with = `r(N)'
				count if narcolepsypraccount == 0 & _stillin == 1
				local without = `r(N)'
				replace _stillin = 0 if narcolepsypraccount == 0
				
				post `memhold' (`i') (`without')
				label define criterialab `i' "No eligible narcolepsy cases in practice", add
				local i = `i' + 1
			
				post `memhold' (`i') (`with')
				label define criterialab `i' "DOLSIGN\geq1DOLSIGN eligible narcolepsy cases in practice", add
				local i = `i' + 1
				
				di as yellow "Practice has at least 2 eligible OSA cases"
				count if OSApraccount >= 2 & _stillin == 1
				local with = `r(N)'
				count if OSApraccount <2 & _stillin == 1
				local without = `r(N)'
				replace _stillin = 0 if OSApraccount <2
				
				post `memhold' (`i') (`without')
				label define criterialab `i' "DOLSIGN\<2DOLSIGN eligible OSA cases in practice", add
				local i = `i' + 1
			
				post `memhold' (`i') (`with')
				label define criterialab `i' "DOLSIGN\geq2DOLSIGN eligible OSA cases in practice", add
				local i = `i' + 1				
				
				di as yellow "Use random sampling within practices to:"
				di as yellow "identify two people with OSA in each practice, or"
				di as yellow "restrict the sample to 2 for practices with >=3 eligible narcolepsy cases"
				
				set seed 1346
				gen _randno = runiform(0,1)
				bysort pracid (patid): gen _patno = _n
				count if _patno <= 2
				local with = `r(N)'
				count if _patno > 2
				local without = `r(N)'
				replace _stillin = 0 if _patno > 2
				
				post `memhold' (`i') (`without')
				label define criterialab `i' "excluded through random sampling", add
				local i = `i' + 1
			
				post `memhold' (`i') (`with')
				label define criterialab `i' "included through random sampling", add
				local i = `i' + 1				
				
				di as yellow "Validation study sample for recruitment"
				rename _stillin forrecruitment
				label variable forrecruitment "Validation sample for recruitment"
				count if forrecruitment == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Incident sleep disorder", add
				local i = `i' + 1
				
				postclose `memhold'
				
				
				/**** VALIDATION COHORT PATIENT LEVEL DATA SET ***/
				di as yellow "Validation cohort patient level data set"
				
				/*** keep incidence cases*/
				keep if forrecruitment == 1
				drop _*
			
				/*save criterialab label*/
				tempfile templabel
				label list criterialab
				label save criterialab using `templabel'
	
				/**** SAVE FILE FOR EACH COHORT ****/
				di as yellow "save file for each cohort"
				/*check that there are no changes to the patient level dataset when the file is rerun
				- if there are, subsequent do files need to be rerun*/
				compress
				if `datasetchange' == 1 datasignature set, saving("$datadir_an\11.cr_validationcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dtasig", replace) reset
				datasignature confirm using "$datadir_an\11.cr_validationcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dtasig"
				save "$datadir_an\11.cr_validationcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", replace
				describe
				pause
				
				/**** FLOW CHART DATASET ****/
				use "$resultdir\_`dataset'", clear
				if `j' > 1 {
					merge 1:1 criteria using "$resultdir\11.cr_validationcohort_an_flowchart.dta"
					assert _merge == 3
					drop _merge
					}
				save "$resultdir\11.cr_validationcohort_an_flowchart.dta", replace
				*erase "_`dataset'.dta"
				local j = `j' + 1
				pause
			} /*medcondition*/
		} /*linked*/
	} /*database*/
	
/*/**** ADD COLUMNS FOR AURUM AND GOLD COMBINED ***/
foreach linkedtext in primary linked {
	foreach medcondition in narcolepsy OSA {
		local name "combined`linkedtext'`medcondition'"
		egen `name' = rowtotal(gold`linkedtext'`medcondition' aurum`linkedtext'`medcondition'), missing
}
}
*/

/****  LABEL RESULTS DATASET AND VARIABLES  ****/
label data "Validation cohort flow chart"
do `templabel'
label values criteria criterialab
note: "See database, variable labels and notes in patient level database"
pause
export excel using "$resultdir\11.cr_validationcohort_an_flowchart.xlsx", replace firstrow(variables)
save "$resultdir\11.cr_validationcohort_an_flowchart.dta", replace

** erase temporary files
local myfiles: dir "$resultdir\" files "_*", respectcase
tokenize `"`myfiles'"'
while "`1'" !="" {
	erase "$resultdir\\`1'"
	mac shift
	}



capture log close





