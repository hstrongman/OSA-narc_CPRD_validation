
capture log close
log using "$logdir\v3.an_validation_data_table.txt", replace text


/*******************************************************************************
# Stata do file:    v3.an_validation_data_table.do
#
# Author:      Helen Strongman
#
# Date:        28/06/2024
#
# Description: Descriptive data table from validation survey data
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
	use "$datadir_dm/v2.cr_formatted_validation_data.dta", clear
	
	*create exposed variable to mirror format of a cohort study table 1
	gen exposed = .
	replace exposed = 0 if medcondition == "OSA"
	replace exposed = 1 if medcondition == "narcolepsy"
	label define exposedlab 0 "OSA" 1 "narcolepsy"
	label values exposed exposedlab
	
	tempfile validationdata
	save `validationdata'
/*******************************************************************************
tabulate all variables in dataset against medical condition
*******************************************************************************/

	putexcel set "$resultdir\v3.an_validation_data_table.xlsx", replace 

	putexcel B1 = "OSA", bold hcenter
	putexcel C1 = "Narcolepsy", bold hcenter

	putexcel A2 = "N+", bold

	local expgroups = 2
	local expcols = `expgroups' * 2
	local letterstring = substr("`c(ALPHA)'", 3, 4) /*2nd number should be 2 x number of exposure groups*/
	di "`letterstring'"

	local i = 0
	foreach col of local letterstring {
		count if exposed == `i'
		local string = string(r(N), "%9.0fc")
		putexcel `col'2 = "`string'", hcenter
		sleep 2000
		local i = `i' + 1
		}

	include "$dodir/inc_0.an_table1_putexcel.do" /*run program to enter exposed / control values*/
	

	global startrow = 3


******** ALL CASES **********************************************
	
	putexcel A$startrow = "ALL CASES", bold
	sleep 2000
	global startrow = $startrow + 1
	
	HSputexcel summary "Recorded role of hospital specialist" categ $startrow 2
	global startrow = $startrow + 1
	
******** CASES DIAGNOSED BY A HOSPITAL SPECIALIST ****************
	keep if q1a == 1
	foreach medcondition in OSA narcolepsy {
		count if medcondition == "`medcondition'"
		local `medcondition' = `r(N)'
	}
	
	global startrow = $startrow + 1
	putexcel A$startrow = "CASES DIAGNOSED OR TREATED BY A HOSPITAL SPECIALIST (OSA n = `OSA', narcolepsy n = `narcolepsy')", bold
	global startrow = $startrow + 1
	
	HSputexcel timelagtodiagcode "Days between the index and diagnosis date (positive = index later)" numeric $startrow 2
	
	HSputexcel timediffcat "Months between the index and diagnosis date " categ $startrow 2
	
	putexcel A$startrow = "Methods used to diagnose the patient", bold
	global startrow = $startrow + 1
	
	qui describe q1c*, varlist
	local varlist = "`r(varlist)'"
	
	foreach var of local varlist {
		local varname: variable label `var'
		di "`varname'"
		HSputexcel `var' "`varname'" binary $startrow 2
	}
		
	HSputexcel q4 "Type of narcolepsy" categ $startrow 2
	
	HSputexcel q5 "Severity of OSA (AHI)" categ $startrow 2
	
	HSputexcel q5a "ODI score" numeric $startrow 2
	
	HSputexcel q5comb "Severity of OSA (AHI or ODI)" categ $startrow 2
	
	HSputexcel q2a "Diagnosis excluded by specialist at a later date" binary $startrow 2
	
	
******** CASES REFERRED TO A HOSPITAL SPECIALIST ****************

	use `validationdata', clear
	keep if q3a==1
	foreach medcondition in OSA narcolepsy {
		count if medcondition == "`medcondition'"
		local `medcondition' = `r(N)'
	}
	
	global startrow = $startrow + 1
	putexcel A$startrow = "CASES REFERRED TO A HOSPITAL SPECIALIST BUT NOT DIAGNOSED (OSA n = `OSA', narcolepsy n = `narcolepsy')", bold
	global startrow = $startrow + 1
	
	HSputexcel timelagtorefcode "Months between index and referral date (positive = index later)" numeric $startrow 2
	
	putexcel A$startrow = "Result of the referral", bold
	global startrow = $startrow + 1
	
	qui describe q3c*, varlist
	local varlist = "`r(varlist)'"
	
	foreach var of local varlist {
		local varname: variable label `var'
		di "`varname'"
		HSputexcel `var' "`varname'" binary $startrow 2
	}
	
******** CASES NOT REFERRED TO HOSPITAL SPECIALIST ***************

	use `validationdata', clear
	keep if q3a==0
	foreach medcondition in OSA narcolepsy {
		count if medcondition == "`medcondition'"
		local `medcondition' = `r(N)'
	}

	global startrow = $startrow + 1
	putexcel A$startrow = "CASES NOT REFERRED TO A HOSPITAL SPECIALIST (OSA n = `OSA', narcolepsy n = `narcolepsy')", bold
	global startrow = $startrow + 1
	
	putexcel A$startrow = "Information included in patient's record", bold
	global startrow = $startrow + 1
	
	qui describe q3d*, varlist
	local varlist = "`r(varlist)'"
	
	foreach var of local varlist {
		local varname: variable label `var'
		di "`varname'"
		HSputexcel `var' "`varname'" binary $startrow 2
	}
	


capture log close
