capture log close
log using "$logdir\11.cr_validationcohort_an_flowchart.txt", replace text

/*******************************************************************************
# Stata do file:    11.cr_validationcohort_an_flowchart.do
#
# Author:      Helen Strongman
#
# Date:       08/07/2024.
#
# Description: 	This do file populates a spreadsheet with numbers
#				needed to describe how the validation cohort was defined. It
#				has a different structure to the version created in do file 11.
#
#				Symbols are written in Latex code
#				with "DOLSIGN" replacing "$" to avoid confusion with macros in
#				Stata
#				THIS SPREADSHEET IS RECREATED IN 11a...do
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off


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
				
				/*** COUNTS FROM INCIDENT COHORT ***/
				post `memhold' (`i') (.)
				label define criterialab `i' "Incident sleep disorder cohort"
				local i = `i' + 1				
				
				distinct pracid
				local patcount = `r(N)'
				local praccount = `r(ndistinct)'
				
				post `memhold' (`i') (`patcount')
				label define criterialab `i' "patients", add
				local i = `i' + 1		
				
				post `memhold' (`i') (`praccount')
				label define criterialab `i' "practices", add
				local i = `i' + 1		
				
				/*** DEFINE VALIDATION COHORT ***/
				post `memhold' (`i') (.)
				label define criterialab `i' "VALIDATION COHORT", add
				local i = `i' + 1
				
				gen _stillin = 1
				di as yellow "Practice has no eligible narcolepsy cases"
				count if narcolepsypraccount == 0 & _stillin == 1
				local without = `r(N)'
				replace _stillin = 0 if narcolepsypraccount == 0
				
				post `memhold' (`i') (`without')
				label define criterialab `i' "No eligible narcolepsy cases in practice", add
				local i = `i' + 1
			
				di as yellow "Practice has <2 eligible OSA cases"
				count if OSApraccount <2 & _stillin == 1
				local without = `r(N)'
				replace _stillin = 0 if OSApraccount <2
				
				post `memhold' (`i') (`without')
				label define criterialab `i' "DOLSIGN\leq2DOLSIGN eligible OSA cases in practice", add
				local i = `i' + 1
			
				keep if _stillin == 1
				keep patid pracid
				merge  1:1 patid using "$datadir_an\11.cr_validationcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta"
				
				di as yellow "excluded through random sampling"
				count if _merge == 1
				local without = `r(N)'
				post `memhold' (`i') (`without')
				label define criterialab `i' "Excluded through convenience sampling", add
				local i = `i' + 1
				
				post `memhold' (`i') (.)
				label define criterialab `i' "Recruitment sample", add
				local i = `i' + 1	
				
				distinct pracid if _merge == 3
				local patcount = `r(N)'
				local praccount = `r(ndistinct)'
				
				post `memhold' (`i') (`patcount')
				label define criterialab `i' "patients", add
				local i = `i' + 1		
				
				post `memhold' (`i') (`praccount')
				label define criterialab `i' "practices", add
				local i = `i' + 1	
				
				drop _merge
				
				* completed questionnaire
				tempfile templabel
				label list criterialab
				label save criterialab using `templabel'
				
				use "$datadir_dm/v2.cr_formatted_validation_data.dta", clear
				do `templabel'
				
				distinct pracid if medcondition == "`medcondition'"
				local patcount = `r(N)'
				local praccount = `r(ndistinct)'
				
				post `memhold' (`i') (.)
				label define criterialab `i' "Questionnaires completed (Validation sample)", add
				local i = `i' + 1	
				
				post `memhold' (`i') (`patcount')
				label define criterialab `i' "patients", add
				local i = `i' + 1		
				
				post `memhold' (`i') (`praccount')
				label define criterialab `i' "practices", add
				local i = `i' + 1				
						
				postclose `memhold'
				
						
				/*save criterialab label*/
				tempfile templabel
				label list criterialab
				label save criterialab using `templabel'
				
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
export excel using "$resultdir\11a.cr_validationcohort_an_flowchart.xlsx", replace firstrow(variables)
save "$resultdir\11a.cr_validationcohort_an_flowchart.dta", replace

** erase temporary files
local myfiles: dir "$resultdir\" files "_*", respectcase
tokenize `"`myfiles'"'
while "`1'" !="" {
	erase "$resultdir\\`1'"
	mac shift
	}



capture log close





