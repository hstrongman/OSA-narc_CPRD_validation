	
capture log close
log using "$logdir\v9.an_validation_data_table_bydef.txt", replace text

/*******************************************************************************
# Stata do file:    v9.an_validation_data_table_bydef.do
#
# Author:      Helen Strongman
#
# Date:       21/10/2024
#
# Description: Descriptive data table comparing key validation survey questions
#				for OSA and narcolepsy defined using different combinations of
#				CPRD and HES APC definitions. Plus definitions that require
#				HES OP visits in the 6 months before or after diagnosis.
#				 
# Requirements: inc_0.an_table1_putexcel.do
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause on

/***************************************************************************
read in data
****************************************************************************/
	
	*read in validation file
	use "$datadir_an/v7.cr_validationcohort_allvars.dta", clear
	
	
	/*expand dataset to create one row for each definition*/
	keep patid medcondition q* def_* index_* timediffcat_* timediffbin_* timelagtodiagcode_* timelagtorefcode_* summary
	
	expand 7, gen(_expand) /*x = number of exposure groups*/
	tab _expand, m
	*generate exposed variable
	bysort patid medcondition (_expand): gen exposed = _n - 1
	tab exposed, m
	
	label define exposedlab 0 "Original (CPRD or HES APC)" ///
	1 "CPRD" ///
	2 "CPRD & HES APC" ///
	3 "Original with OP visit to sleep-related specialty" ///
	4 "CPRD with OP visit to sleep-related specialty" ///
	5 "Original with EDS drug prescription" ///
	6 "CPRD with EDS drug prescription"
	label values exposed exposedlab
	
	*for each definition, drop patients who do not meet the criteria
	local i = 0
	foreach def in either cprd both_and either_possop cprd_possop either_edsdrug cprd_edsdrug {
		drop if exposed == `i' & (def_`def' == 0 | def_`def' == .)
		local i = `i' + 1
	}
	
	tab exposed, m
	
	*set definition-specific variables to missing unless the row if for that definition
	local i = 0
	foreach def in either cprd both_and either_possop cprd_possop either_edsdrug cprd_edsdrug {
		foreach var in def timelagtodiagcode timediffcat timediffbin timelagtorefcode {
		replace `var'_`def' = . if exposed !=`i'
		}
		local i = `i' + 1
	}
	
tempfile temp
save `temp'

/*******************************************************************************
tabulate all variables in dataset against medical condition
*******************************************************************************/


foreach medcondition in OSA narcolepsy {
	
	use `temp', clear
	keep if medcondition == "`medcondition'"

	putexcel set "$resultdir\v9.an_validation_data_table_bydef.xlsx", sheet("`medcondition'", replace) modify

	putexcel B1 = "Original (CPRD or HES APC)", bold hcenter
	putexcel C1 = "CPRD", bold hcenter
	putexcel D1 = "CPRD & HES APC", bold hcenter
	putexcel E1 = "Original with OP visit", bold hcenter
	putexcel F1 = "Original with OP visit to sleep-related specialty", bold hcenter
	putexcel G1 = "CPRD with EDS drug prescription", bold hcenter
	putexcel H1 = "CPRD with EDS drug prescription", bold hcenter

	putexcel A2 = "N+", bold

	local expgroups = 7
	local expcols = `expgroups' * 2
	local letterstring = substr("`c(ALPHA)'", 3, `expcols') /*2nd number should be 2 x number of exposure groups*/
	di "`letterstring'"

	local i = 0
	foreach col of local letterstring {
		count if exposed == `i'
		local string = string(r(N), "%9.0fc")
		putexcel `col'2 = "`string'", hcenter bold
		sleep 2000
		local i = `i' + 1
		}

	include "$dodir/inc_0.an_table1_putexcel.do" /*run program to enter exposed / control values*/
	

	global startrow = 3


******** ALL CASES **********************************************
	
	putexcel A$startrow = "ALL CASES", bold
	sleep 2000
	global startrow = $startrow + 1
	
	HSputexcel summary "Recorded role of hospital specialist" categ $startrow 7
	global startrow = $startrow + 1
	
******** CASES DIAGNOSED BY A HOSPITAL SPECIALIST ****************
	keep if q1a == 1


	global startrow = $startrow + 1
	putexcel A$startrow = "CASES DIAGNOSED OR TREATED BY A HOSPITAL SPECIALIST", bold
	global startrow = $startrow + 1
	
	foreach def in either cprd both_and either_possop cprd_possop either_edsdrug cprd_edsdrug {
		HSputexcel timelagtodiagcode_`def' "Days between the recorded and confirmed diagnosis date (positive = recorded later)" numeric $startrow 7
	
		HSputexcel timediffbin_`def' "Recorded diagnosis within 6 months before or after confirmed diagnosis" binary $startrow 7
	}
	
	/*putexcel A$startrow = "Methods used to diagnose the patient", bold
	global startrow = $startrow + 1
	
	qui describe q1c*, varlist
	local varlist = "`r(varlist)'"
	*/
	
	local varlist = "q1c_bin"
	foreach var of local varlist {
		di "variable: `var'"
		local varname: variable label `var'
		di "Name: `varname'"
		HSputexcel `var' "`varname'" binary $startrow 7
	}
		
	HSputexcel q4 "Type of narcolepsy" categ $startrow 7
	
	/*HSputexcel q5 "Severity of OSA (AHI)" categ $startrow 7
	
	HSputexcel q5a "ODI score" numeric $startrow 7*/
	
	HSputexcel q5comb "Severity of OSA (AHI or ODI)" categ $startrow 7
	
	HSputexcel q2a "Diagnosis excluded by specialist at a later date" binary $startrow 7
	
	
/******** CASES REFERRED TO A HOSPITAL SPECIALIST ****************

	use `temp', clear
	keep if q3a==1 &  medcondition == "`medcondition'"
	
	global startrow = $startrow + 1
	putexcel A$startrow = "CASES REFERRED TO A HOSPITAL SPECIALIST BUT NOT DIAGNOSED", bold
	global startrow = $startrow + 1
	
	foreach def in either both_and cprd hesapc either_anyop either_possop {

		HSputexcel timelagtorefcode_`def' "Months between index and referral date (positive = index later)" numeric $startrow 7
	}
	
	putexcel A$startrow = "Result of the referral", bold
	global startrow = $startrow + 1
	
	qui describe q3c*, varlist
	local varlist = "`r(varlist)'"
	
	foreach var of local varlist {
		local varname: variable label `var'
		di "`varname'"
		HSputexcel `var' "`varname'" binary $startrow 7
	}
	
******** CASES NOT REFERRED TO HOSPITAL SPECIALIST ***************

	use `temp', clear
	keep if q3a==0 &  medcondition == "`medcondition'"


	global startrow = $startrow + 1
	putexcel A$startrow = "CASES NOT REFERRED TO A HOSPITAL SPECIALIST", bold
	global startrow = $startrow + 1
	
	putexcel A$startrow = "Information included in patient's record", bold
	global startrow = $startrow + 1
	
	qui describe q3d*, varlist
	local varlist = "`r(varlist)'"
	
	foreach var of local varlist {
		local varname: variable label `var'
		di "`varname'"
		HSputexcel `var' "`varname'" binary $startrow 7
	}	
*/	
}




capture log close
