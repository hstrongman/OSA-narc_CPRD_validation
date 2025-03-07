capture log close
log using "$logdir\23a.cr_dm_validationstudy_patlists_aurumextract.txt", replace text

/*******************************************************************************
# Stata do file:    23a.cr_dm_validationstudy_patlists.do
#
# Author:      Helen Strongman
#
# Date:        21/06/2024
#
# Description: 	This do file prepares patient lists to extract CPRD Aurum data
#				for the validation study. This would not be necessary if the
#				studies were run in the same build.
#
#				I am extracting data for the full incident narcolepsy and OSA
#				groups to compare the samples.	
#
#				I will extract data from the December 2023 build as the 
#				September 2023 build is no longer available 			
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/


foreach medcondition in OSA narcolepsy {
	use "$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_aurum_linked.dta", clear
	qui count
	di "`medcondition' count: `r(N)'"
	keep patid
	format patid %15.0g
	tostring patid, replace format(%20.0g)
	*merge with December 2023 build to check
	merge 1:1 patid using "$cprddir/CPRD Aurum/Denominator files/2023_12/202312_CPRDAurum_AllPats.dta", keepusing(patid)
	count if _merge == 1
	di as yellow "Not included in December 2023 build: `r(N)'"
	keep if _merge == 3
	drop _merge
	export delimited using "$datadir_raw\23a.cr_dm_validationstudy_patlists_aurumextract_`medcondition'.txt", replace
}


log close

