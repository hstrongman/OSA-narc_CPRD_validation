capture log close
log using "$logdir\v12.an_ppv_stratification_ratios.txt", replace text

/*******************************************************************************
# Stata do file:    v12.an_ppv_stratification_ratios.do
#
# Author:      Helen Strongman
#
# Date:        04/11/2024
#
# Description: 	robust methods to estimate PPV ratios by covariate
#				replaces plans to stratify
#				easier to compare on a graph and to estimate certainty		
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off

foreach def in either cprd {
foreach medcondition in OSA narcolepsy {
	
	/*import patient level dataset*/
	use "$datadir_an/v7.cr_validationcohort_allvars.dta", clear
	keep if medcondition == "`medcondition'" & def_`def' == 1
	
	foreach covar in gender agebin carstairs_bin bmi_bin calendaryear_bin pracsize_bin {
		
		*skip bmi  for narcolepsy
		if "`medcondition'" == "narcolepsy" & "`covar'" == "bmi_bin" continue
		
		di "`i' `def' `medcondition' `covar'"
	
	qui {
		
		*specify baselevel
		summ `covar'
		local bl = `r(min)'
		
		/*** estimate PPV ratios **/
		
		*crude
		glm q1a ib`bl'.`covar', allbaselevels family(poisson) link(log) eform vce(robust)
		pause
		estimates save "$estimatesdir/v12.an_ppv_stratification_ratio_`medcondition'_`def'_`covar'", replace

		}
	} /*covar*/
}
}


capture log close
