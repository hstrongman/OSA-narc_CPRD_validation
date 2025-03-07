capture log close
log using "$logdir\23.cr_dm_validationstudy_patlists.txt", replace text

/*******************************************************************************
# Stata do file:    23.cr_dm_validatoinstudy_patlists.do
#
# Author:      Helen Strongman
#
# Date:        15/11/2023
#
# Description: 	This do file prepares patient lists for the validation study.
#				In the protocol, we said that: "we will select a random subset 
#				of 143 people for each sleep disorder leading to 200 (100 x 2) 
#				responses, assuming a 70% response rate."
#
#				The expected response rate is now much lower at x%. The list
#				therefore includes all patids.
#
#				Files for CPRD prove should be provided as excel sheets.
#				
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/


foreach medcondition in OSA narcolepsy {
	use "$datadir_an\11.cr_validationcohort_an_flowchart_`medcondition'_aurum_linked.dta", clear
	distinct pracid
	if "`medcondition'" == "narcolepsy" {
		di as yellow "average number of people with narcolepsy sampled per practice"
		di as yellow `r(N)'/`r(ndistinct)'
	}
	tab narcolepsypraccount, m
	summ OSApraccount, d
	keep patid pracid indexdate
	format patid %15.0g
	tostring patid, replace format(%20.0g)
	count
	display as yellow "Number of patients in validation cohort `database' file: `r(N)'"
	export excel using "$datadir_raw\23.cr_dm_validationstudy_patlists_`medcondition'.xlsx", replace firstrow(variables)
}


log close

