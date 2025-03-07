capture log close
log using "$logdir\10.cr_incidentcohort_an_flowchart.txt", replace text

/*******************************************************************************
# Stata do file:    10.cr_incidentcohort_an_flowchart.do
#
# Author:      Helen Strongman
#
# Date:        05/01/2023. Last updated 14/11/2023.
#
# Description: 	This do file flags incident OSA or narcolepsy cases.
#				This replaces a do file identifying the full unmatched cohort for
#				the main study and would not have been needed if both cohorts
#				were run in the same CPRD build. (an additional do file would
#				have been used to restrict to active patients)
# 
#				The do file additionally populates a spreadsheet with numbers
#				needed to describe how the validation study sample 
#				populations was defined. Symbols are written in Latex code
#				with "DOLSIGN" replacing "$" to avoid confusion with macros in
#				Stata
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off
local datasetchange = 1 /*The datasignature command is used at the end of the 
do file to check that the patient level dataset has not changed since this do
file was last run. Setting this local to 1 overides this*/

local j = 1 /*dataset indicator*/
foreach database in aurum /*gold*/ {
	/****  READ IN STUDY POPULATION DATA  ****/
		foreach linkedtext in /*primary*/ linked {
			foreach medcondition in OSA narcolepsy {
				use "$datadir_dm/9.cr_studypopulation_an_flowchart_`database'.dta", clear
				keep if studypop_`linkedtext' == 1
				
				/*** SET UP RESULTS FILE FOR EACH COHORT ***/
				local dataset = "`database'`linkedtext'`medcondition'"
				capture erase "$resultdir\_`dataset'.dta"
				tempname memhold
				postfile `memhold' int criteria double `dataset' using "$resultdir\_`dataset'"
				local i = 1
				
				post `memhold' (`i') (.)
				label define criterialab `i' "INCIDENT COHORT", add
				local i = `i' + 1
				
				*** PREVALENT COHORT ***
				gen _stillin = 1
				di as yellow "number of people with and without a clinical code for `medcondition'"
				if "`medcondition'" == "narcolepsy" {
					if "`linkedtext'" == "primary" {
						gen indexdate = narcolepsydate_pc
						}
					if "`linkedtext'" == "linked" {
						gen indexprimary = narcolepsydate_pc
						gen indexhesapc = narcolepsydate_hesapc
						/*NB need to keep variables with original name for later
						in do file*/
						gen indexdate = min(indexprimary, indexhesapc)
						}
				}
				if "`medcondition'" == "OSA" {
					if "`linkedtext'" == "primary" {
						gen indexdate = min(OSAdate_pc, SAdate_pc, SASdate_pc, OSASdate_pc)
					}
					if "`linkedtext'" == "linked" {
						gen indexprimary = min(OSAdate_pc, SAdate_pc, SASdate_pc, OSASdate_pc)
						gen indexhesapc = min(SAdate_hesapc, SASdate_hesapc)
						format indexprimary indexhesapc %td
						label variable indexhesapc "First record of OSA in HES APC"
						label variable indexprimary "First record of OSA in primary care data"
						gen indexdate = min(indexprimary, indexhesapc)
						}
				}
				format indexdate %td
				label variable indexdate "First coded clinical record of `medcondition'"
				note indexdate: "Referral and test/value records not included (based on GOLD file type and Aurum observation type)"
				note indexdate: "Cataplexy only records not included in narcolepsy definition"
				
				count if indexdate != .
				pause
				local with = `r(N)'
				count if indexdate == .
				local without = `r(N)'
				replace _stillin = 0 if indexdate == .
				
				post `memhold' (`i') (`without')
				label define criterialab `i' "No coded records for sleep disorder", add
				local i = `i' + 1
			
				post `memhold' (`i') (`with')
				label define criterialab `i' "DOLSIGN\geq1DOLSIGN coded record for sleep disorder", add
				local i = `i' + 1		
				
			
				di as yellow "At least one record with missing date"
				count if indexdate == d(01/01/1800) & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Missing date for DOLSIGN\geq1DOLSIGN record", add
				replace _stillin = 0 if indexdate == d(01/01/1800)
				local i = `i' + 1				
				
				di as yellow "Index date (first ever coded record) on or after end of study period"
				count if indexdate >= ${studyend_`linkedtext'} & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index date DOLSIGN\geqDOLSIGN end of study period", add
				replace _stillin = 0 if indexdate >= ${studyend_`linkedtext'}
				local i = `i' + 1	
				
				di as yellow "Index date on or after end of follow-up"
				count if indexdate >= end_`linkedtext' & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index date DOLSIGN\geqDOLSIGN end of follow-up", add
				replace _stillin = 0 if indexdate >= end_`linkedtext'
				local i = `i' + 1
						
				di as yellow "Record of central or primary sleep apnoea before index or start of follow-up"
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
					}
				if "`medcondition'" == "OSA" {
					gen _othersadate = min(centraldate_pc, primarydate_pc)
					if "`linkedtext'" == "linked" replace _othersadate = min(_othersadate, centraldate_hesapc, primarydate_hesapc)
					format _othersadate %td
					count if (_othersadate <= indexdate |  _othersadate <= start_`linkedtext') & _stillin == 1
					pause
					replace _stillin = 0 if _othersadate <= indexdate | _othersadate <= start_`linkedtext'
					post `memhold' (`i') (`r(N)')
					}
				label define criterialab `i' "Record of central or primary sleep apnoea DOLSIGN\leqDOLSIGN index", add
				local i = `i' + 1
				
				/*combined with above 24/01/2023*
				di as yellow "Record of central or primary sleep apnoea before start of follow-up"
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
					label define criterialab `i' "N/A", add
					}
				if "`medcondition'" == "OSA" {
					count if _othersadate <= start_`linkedtext' & _stillin == 1
					replace _stillin = 0 if  _othersadate <= start_`linkedtext'
					post `memhold' (`i') (`r(N)')
					label define criterialab `i' "Record of central or primary sleep apnoea before start of follow-up", add
					}
				local i = `i' + 1
				*/
				
				di as yellow "Aged <= 18 at index (OSA only)"
				if "`medcondition'" == "OSA" {
					count if _stillin == 1 & date18 > indexdate
					replace _stillin = 0 if date18 > indexdate
					post `memhold' (`i') (`r(N)')
				}
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
				}
				label define criterialab `i' "Aged DOLSIGN<18DOLSIGN at index date", add
				local i = `i' + 1
				
				di as yellow "Prevalent sleep disorder"
				gen prevalent = _stillin
				label variable prevalent "Prevalent `medcondition'"
				count if prevalent == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Prevalent sleep disorder", add
				local i = `i' + 1				
				
				*** INCIDENT UNMATCHED COHORT ***
				di as yellow "index date in the 90 days after practice registration"
				count if indexdate < (regstartdate + 90) & indexdate >= regstartdate & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index date DOLSIGN<90DOLSIGN days after practice registration", add
				replace _stillin = 0 if indexdate < (regstartdate + 90) & indexdate >= regstartdate & _stillin == 1 /*& indexdate >= regstartdate added 17/06/2024*/
				local i = `i' + 1
				/*note 90 day criteria goes before "before follow-up" because 
				start_`linkedtext' incorporates regstart + 90*/
			
				di as yellow "Index date before start of follow-up"
				count if indexdate < start_`linkedtext' & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index dateDOLSIGN<DOLSIGN start of follow-up", add
				replace _stillin = 0 if indexdate < start_`linkedtext' & _stillin == 1
				local i = `i' + 1				
				
				di as yellow "Incident sleep disorder"
				rename _stillin incident
				label variable incident "Incident `medcondition'"
				count if incident == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Incident sleep disorder", add
				local i = `i' + 1				
				
				postclose `memhold'
				
				
				/**** INCIDENT COHORT PATIENT LEVEL DATA SET ***/
				di as yellow "Incident cohort patient level data set"
				
				/*** keep incidence cases*/
				keep if incident == 1
			
				
				/*** create variable describing code type recorded at index*/
				
				if "`medcondition'" == "OSA" local prefixlist "OSA OSAS SA SAS"
				if "`medcondition'" == "narcolepsy" local prefixlist "narcolepsy"
				
				if "`linkedtext'" == "primary" local dataablist = "pc"
				if "`linkedtext'" == "linked" local dataablist = "pc hesapc"
					
				gen _pc = 0 if indexdate !=.
				gen _hesapc = 0 if indexdate !=.
					
				foreach prefix of local prefixlist {
						gen _`prefix' = 0
						foreach dataab of local dataablist {
							if strpos("`prefix'", "O") == 1 & "`dataab'" == "hesapc" continue
							replace _`prefix' = 1 if `prefix'date_`dataab' == indexdate & indexdate !=.
							replace _`dataab' = 1 if `prefix'date_`dataab' == indexdate & indexdate !=.
						}
					}
				
				gen indexcode = ""
				label variable indexcode "`medcondition' code type(s) recorded at index"
					gen _codecount = 0
					foreach prefix of local prefixlist {
						replace _codecount = _codecount + 1 if _`prefix' == 1
						replace indexcode = "`prefix'" if _`prefix' == 1 & _codecount == 1
						replace indexcode = indexcode + " + " + "`prefix'" if _`prefix' == 1 & _codecount > 1
						drop _`prefix'
						}
				drop _codecount
				tab indexcode, m
				
				/*** create variable describing whether codes are recorded in 
				primary care and/or linked data ***/
				
				if "`linkedtext'" == "linked" {
					if "`medcondition'" == "narcolepsy" {
						rename narcolepsydate_hesapc indexlinked
						label variable indexlinked "First record of narcolepsy in HES APC"
						/*variable generated previously for OSA*/
					}
					gen cprdvshesapc = 0 if indexhesapc !=. | indexprimary !=.
					label variable cprdvshesapc "Concordance between CPRD and HES APC"
					recode cprdvshesapc 0 = 1 if indexhesapc == indexprimary
					recode cprdvshesapc 0 = 2 if indexhesapc < indexprimary & indexhesapc !=. & indexprimary !=.
					recode cprdvshesapc 0 = 3 if indexhesapc > indexprimary & indexhesapc !=. & indexprimary !=.
					recode cprdvshesapc 0 = 4 if indexhesapc ==. | indexprimary !=.
					recode cprdvshesapc 0 = 5 if indexhesapc !=. | indexprimary ==.

					label define cprdvshesapclab 1 "CPRD and HES APC on index" 2 "HES APC first" 3 "CPRD first" 4 "CPRD only" 5 "HES APC only"
					label values cprdvshesapc cprdvshesapclab
				}
				
				/***generate variable describing the number of eligible people in each practice 
				- needed to restrict validation study (see next do file)***/
				duplicates tag pracid, gen(_dup)
				gen `medcondition'praccount = _dup + 1
				label variable `medcondition'praccount "Number of active `medcondition' patients in practice"
				
				/*save criterialab label*/
				tempfile templabel
				label list criterialab
				label save criterialab using `templabel'
				
	
				/**** KEEP RELEVANT VARIABLES AND SAVE TEMPORARY FILE
				changed for validation study cohort to add variable describing
				the number of incident people per practice who are eligible
				for the narcolepsy cohort to the OSA dataset and vice versa****/
				di as yellow "save file for each cohort"
				local keep "patid pracid indexdate" /*identifiers*/
				local keep "`keep' dob yob gender region pracsize indexcode" /*stratification and matching variables*/ 
				local extra ""
				if "`medcondition'" == "narcolepsy" local extra "cataplexy*" 
				if "`linkedtext'" == "linked" local extra "`extra' cprdvshesapc"
				local keep "`keep' `extra' regstartdate" /*varibles to check post-hoc decisions and for sensitivity analyses*/
				local keep "`keep' `medcondition'praccount" /*variable to restrict validation cohort (see next do file)*/
				local keep = regexr("`keep'", "  ", " ")
				di "`keep'"
				keep `keep'
				order `keep'
				
				tempfile temp`medcondition'
				save `temp`medcondition''
				
				
				/**** FLOW CHART DATASET ****/
				use "$resultdir\_`dataset'", clear
				if `j' > 1 {
					merge 1:1 criteria using "$resultdir\10.cr_incidentcohort_an_flowchart.dta"
					assert _merge == 3
					drop _merge
					}
				save "$resultdir\10.cr_incidentcohort_an_flowchart.dta", replace
				*erase "_`dataset'.dta"
				local j = `j' + 1
				pause
			} /*medcondition*/
				
				foreach medcondition in narcolepsy OSA { /*don't switch order*/
					if "`medcondition'" == "narcolepsy" local other = "OSA"
					if "`medcondition'" == "OSA" local other = "narcolepsy"
					use `temp`other'', clear
					keep pracid *praccount
					duplicates drop
			
					describe
					describe using `temp`medcondition''
					merge 1:m pracid using `temp`medcondition'', keepusing(_all) 
					
					recode `other'praccount . = 0 if _merge == 2
					*recode `medcondition'praccount . = 0 if _merge ==1
					drop if _merge == 1
					tab narcolepsypraccount, m
					summ OSApraccount, d
					drop _merge
					
					/*check that there are no changes to the patient level dataset when the file is rerun
					- if there are, subsequent do files need to be rerun*/
					compress
					if `datasetchange' == 1 datasignature set, saving("$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dtasig", replace) reset
					datasignature confirm using "$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dtasig"
					/*save dataset*/
					save "$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", replace
					describe
					pause
					
				}
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
use "$resultdir\10.cr_incidentcohort_an_flowchart.dta", clear
label data "Incident cohort flow chart"
do `templabel'
label values criteria criterialab
note: "See database, variable labels and notes in patient level database"
pause
export excel using "$resultdir\10.cr_incidentcohort_an_flowchart.xlsx", replace firstrow(variables)
save "$resultdir\10.cr_incidentcohort_an_flowchart.dta", replace

** erase temporary files
local myfiles: dir "$resultdir\" files "_*", respectcase
tokenize `"`myfiles'"'
while "`1'" !="" {
	erase "$resultdir\\`1'"
	mac shift
	}



capture log close





