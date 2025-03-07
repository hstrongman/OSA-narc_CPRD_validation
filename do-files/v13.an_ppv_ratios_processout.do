capture log close
log using "$logdir\v13.an_ppv_ratios_processout.txt", replace text

/*******************************************************************************
# Stata do file:    v13.an_ppv_ratios_processout.do
#
# Author:      Helen Strongman
#
# Date:        06/11/2024
#
# Description: 	Dataset with PPV rate and PPV ratios (95% CI) for each covariate
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off


/***set up temporary file for results***/
capture postclose results
tempname memhold
tempfile results
#delimit ;
postfile `memhold' str10 medcondition str6 def str20 covar
str65 covarlabel int value str25 valuelabel double confcases sample
ppv ppv_lci ppv_uci ratio_beta ratio_se ratio_p
using "`results'", replace
;
#delimit cr


foreach def in either cprd {
foreach medcondition in OSA narcolepsy {
	use "$datadir_an/v7.cr_validationcohort_allvars.dta", clear
	keep if medcondition == "`medcondition'" & def_`def' == 1
	
	foreach covar in gender agebin carstairs_bin bmi_bin calendaryear_bin pracsize_bin {
	
		*skip bmi  for narcolepsy
		if "`medcondition'" == "narcolepsy" & "`covar'" == "bmi_bin" continue

		*qui {
		
		
		/*** data row for each covariate value ***/
		di "`def' `medcondition' `covar'"
		summ `covar'
		levelsof `covar', local(values)
		foreach i of local values {
			di "`i'"

			*extract risk ratio for each covariate value
			estimates use "$estimatesdir/v12.an_ppv_stratification_ratio_`medcondition'_`def'_`covar'"
			local ratio_beta = _b[`i'.`covar']
			local ratio_se = _se[`i'.`covar']
			test `i'.`covar'
			local ratio_p = r(p)
			
			*crude PPV (%)
			count if `covar' == `i'
			local sample = `r(N)'
			count if `covar' == `i' & q1a == 1
			local confcases = `r(N)'
			
			cii proportions `sample' `confcases', exact
			local ppv = r(proportion) * 100
			local ppv_lci = r(lb) * 100
			local ppv_uci = r(ub) * 100
			local valuelabel: label `covar'lab `i'
			local covarlabel: variable label `covar' 
			noi di "`covarlabel'"
		#delimit ;
		post `memhold' ("`medcondition'") ("`def'") ("`covar'") 
			("`covarlabel'") (`i') ("`valuelabel'") (`confcases') (`sample')
			(`ppv') (`ppv_lci') (`ppv_uci') 
			(`ratio_beta') (`ratio_se') (`ratio_p')
			;
		#delimit cr
		
		} 
	} 
	}
}
*}

postclose `memhold'

use `results', clear
save "$datadir_an/temp.dta", replace


** estimate number of practices per region/country


label variable medcondition "Sleep disorder"
label variable def "Source definition"
label variable confcases "Confirmed cases (n)"
label variable sample "Sample (n)"

label variable ppv "PPV"
label variable ppv_lci "lower 95% confidence bound (%)"
label variable ppv_uci "upper 95% confidence bound (%)"
note ppv_lci: "Exact crude confidence intervals estimated using binomial methods"

gen ppv_str = string(ppv, "%9.1fc") + " (" + string(ppv_lci, "%9.1fc") + "-" + string(ppv_uci, "%9.1fc") + ")"
label variable ppv_str "PPV (95% CI)"

gen ppvratio = exp(ratio_beta)
gen ppvratio_lci = exp(ratio_beta-invnorm(0.975)*ratio_se)
gen ppvratio_uci = exp(ratio_beta+invnorm(0.975)*ratio_se)

gen ppvratio_str  = string(ppvratio, "%9.2fc") + " (" + string(ppvratio_lci, "%9.2fc") + "-" + string(ppvratio_uci, "%9.2fc") + ")"
replace ppvratio_str = "1" if ppvratio == 1 & ratio_se == 0 /*base category*/
	
gen ppvratio_pstr = string(ratio_p, "%5.3fc") if ratio_p >=0.001 & ratio_p <0.01
replace ppvratio_pstr = string(ratio_p, "%4.2f") if ratio_p>=0.01
replace ppvratio_pstr = "<0.001" if ratio_p<0.001
	
label variable ppvratio "PPV ratio"
label variable ppvratio_lci "PPV ratio lower 95% confidence bound"
label variable ppvratio_uci "PPV ratio upper 95% confidence bound"
label variable ppvratio_str "PPV ratio (95% CI)"
label variable ppvratio_pstr "PPV ratio p-value"
	
drop ratio_se ratio_p


note: "PPV ratios estimated using robust poisson methods"
compress
save "$estimatesdir/v13.an_ppv_ratios_processout.dta", replace

keep medcondition def covarlabel valuelabel confcases sample ppv_str ppvratio_str ppvratio_pstr
export excel using "$resultdir/v13.an_ppv_ratios_processout.xlsx", replace firstrow(varlabels)

capture log close
