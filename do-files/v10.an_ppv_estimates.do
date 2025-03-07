

capture log close
log using "$logdir\v10.an_ppv_estimates.txt", replace text

/*******************************************************************************
# Stata do file:    v10.an_ppv_estimates.do
#
# Author:      Helen Strongman
#
# Date:      02/09/2024
#
# Description: PPV estimates
#				- based on Q1a
#				- all definitions with and without direct standardisation by source
#					when either CPRD or HES are used
#				- crude only for other definitions
#
#				Also estimating internal sensitivity. This is the proportion of
#				confirmed
#				cases from the original definition that are identified with the
#				definition. It is not the true sensitivity as we are missing
#				cases that are not recorded in CPRD or HES.	
#				Ideally, this would be standardised if possible ...
#				 
# Requirements: inc_0.an_table1_putexcel.do
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/


/***************************************************************************
temporary file with standard source distribution
****************************************************************************/

*source population = incident cohort file
use "$datadir_an/37a.cr_unmatchedcohort_stsplit_allvars_OSA_linked.dta", clear

gen medcondition = "OSA"

append using "$datadir_an/37a.cr_unmatchedcohort_stsplit_allvars_narcolepsy_linked.dta"

replace medcondition = "narcolepsy" if medcondition == ""

keep patid medcondition cprdvshesapc 
gen sample = 1

gen strata = 1 if cprdvshesapc <= 3
replace strata = 2 if cprdvshesapc == 4
replace strata = 3 if cprdvshesapc == 5
label define stratalab 1 "Both" 2 "CPRD only" 3 "HES APC only"
label values strata stratalab
label variable strata "Source strata"

collapse (count) sample, by(medcondition strata)

/*
*standard sample = % of people in each strata by medcondition
count if medcondition == "OSA"
local OSAcount = `r(N)'

count if medcondition == "narcolepsy"
local narcolepsycount = `r(N)'

bysort medcondition: egen _total = total(_sample)
gen standardsample = (_sample/_total)*100
drop _*
*/

tempfile tempstandard
save `tempstandard'

/***************************************************************************
estimate 'PPV's by source
****************************************************************************/

*prepare validation study data

use "$datadir_an/v7.cr_validationcohort_allvars.dta", clear

keep patid medcondition cprdvshesapc index_* def_* q1a
drop def_hesapc index_hesapc def_either_anyop def_cprd_anyop index_either_anyop index_cprd_anyop

gen strata = 1 if cprdvshesapc <= 3
replace strata = 2 if cprdvshesapc == 4
replace strata = 3 if cprdvshesapc == 5
label define stratalab 1 "Both" 2 "CPRD only" 3 "HES APC only"
label values strata stratalab
label variable strata "Source strata"
tab strata, m

*label sample/denominator and valid definitions
gen sample = 1
gen valid = 1 if q1a == 1

/*not going to consider changed diagnoses. our gold standard is hospital
confirmed diagnoses.
gen valid_current = 1 if q1a == 1 & q2a == 0
tab valid_initial valid_current, m
*/
tempfile tempvalid
save `tempvalid'

*noi foreach def in initial current {
	*/

/**************************************************************************
Estimate standardised proportions for orginal (CPRD or HES) and Primary
plus outpatient visit definitions 
**************************************************************************/
	
foreach def in either either_possop either_edsdrug {
	use `tempvalid', clear
	
	***restrict to sample for the definition
	keep if def_`def' == 1
	
	***data set with count of sample and valid cases in each source
	collapse (sum) valid sample, by(strata medcondition)
	*rename sample standardsample

	*** estimate standardised PPV
	dstdize valid sample strata, using(`tempstandard') by(medcondition)

	*** post results into matrix
	matrix C = r(Nobs)\r(crude)\r(adj)\r(lb_adj)\r(ub_adj)\r(se)
	matrix list C
	matrix D = C'
	matrix colnames D = Nobs ppv_crude ppv_st ppv_st_lci ppv_st_uci se_st
	matrix list D

	*** collapse dataset to a single row per each medical condition and add variables from matrix
	collapse (sum) valid sample, by(medcondition)
	svmat D, names(col)
	assert sample == Nobs
	drop Nobs
	
	/*if "`def'" == "initial" gen validdef = 1
	if "`def'" == "current" gen validdef = 2
	*/
	rename valid confirmedcases
	
	*value labels for definition match previous do file
	if "`def'" == "either" gen def = 0
	if "`def'" == "either_possop" gen def = 3
	if "`def'" == "either_edsdrug" gen def = 5
	
	if "`def'" != "either" append using `tempstresults'
	
	tempfile tempstresults
	save `tempstresults'
	
}

	
/*** estimate crude PPVs for each additional confirmed cases definition
**********************/

local i = 0	
foreach def in either cprd both_and either_possop cprd_possop either_edsdrug cprd_edsdrug {
	
	noi di "`def' `i'"
	
	*not needed for "either" definitions - already estimated above
	if `i' != 0 & `i' !=3 & `i' !=5  {
		
		use `tempvalid', clear
		keep if def_`def' == 1
				
		collapse (sum) valid sample, by(medcondition)
				
		gen ppv_crude = valid/sample
		list medcondition ppv_crude
		/*if "`def'" == "initial" gen validdef = 1
		if "`def'" == "current" gen validdef = 2*/
		rename valid confirmedcases

		gen def = `i'
				
		append using `tempstresults'
		tempfile tempstresults
		save `tempstresults'
		
	}
	
	local i = `i' + 1
}
	
/*** estimate confidence intervals for crude proportions using exact methods*/
gen ppv_crude_lci = .
gen ppv_crude_uci = .

*gen _order = _n
count
forvalues row = 1/`r(N)' {

	local obs = sample[`row']
	local cases = confirmedcases[`row']
			
	cii proportions `obs' `cases', exact
	replace ppv_crude_lci = r(lb) in `row'
	replace ppv_crude_uci = r(ub) in `row'
}



/*** estimate crude internal senstivities for each additional confirmed cases definition
**********************/

gen valid_orig = .
gen sens_crude = .
gen sens_crude_lci = .
gen sens_crude_uci = .

tempfile tempstresults
save `tempstresults'

foreach medcondition in OSA narcolepsy {
	*number of valid cases using the main definition
	use "$datadir_an/v7.cr_validationcohort_allvars.dta", clear
	count if def_either == 1 & q1a == 1 & medcondition == "`medcondition'"
	local maxvalid_main = `r(N)'
	*as above with OP data available
	gen _opelig = 1 if oplinkage == 1 & index_either >= $studystart_hesop & index_either <= $studyend_hesop
	tab _opelig def_either_anyop, m
	count if def_either == 1 & _opelig == 1 & q1a == 1 & medcondition == "`medcondition'"
	local maxvalid_op = `r(N)'
	drop _opelig
	
	use `tempstresults', clear
	replace valid_orig = `maxvalid_main' if medcondition == "`medcondition'"
	replace valid_orig = `maxvalid_op' if (def ==3 | def==4) & medcondition == "`medcondition'"
	replace sens_crude = confirmedcases/valid_orig if medcondition == "`medcondition'"
	
	gen _temp = 0 if medcondition == "`medcondition'"
	sort _temp
	count if _temp == 0
	forvalues row = 1/`r(N)' {
		local valid = confirmedcases[`row']
		local valid_orig = valid_orig[`row']
		cii proportions `valid_orig' `valid', exact
		replace sens_crude_lci = r(lb) in `row'
		replace sens_crude_uci = r(ub) in `row'
		}
	drop _temp
	tempfile tempstresults
	save `tempstresults'
}
	
	*drop _order
	
*tempfile tempresults
*save `tempresults'


drop se_st

label variable medcondition "Sleep disorder"
label variable confirmedcases "Confirmed cases (count)"
label variable sample "Validation sample (count)"
/*label variable validdef "Confirmed case definition"
label define validdeflab 1 "Diagnosed by hospital specialist" 2 "Original hospital diagnosis excluded at a later date"
label values validdef validdeflab*/
label variable def "Data sources included in case definition"
label variable valid_orig "Valid cases using the Primary definition restricted by OP data availabilty where appropriate"
		
label define deflab 0 "Primary (CPRD or HES APC)" ///
1 "CPRD" ///
2 "CPRD & HES APC" ///
3 "Primary with OP visit to sleep-related specialty" ///
4 "CPRD with OP visit to sleep-related specialty" ///
5 "Primary with EDS drug prescription" ///
6 "CPRD with EDS drug prescription"
label values def deflab

label variable ppv_crude "Crude PPV (%)"
label variable ppv_crude_lci "lower 95% confidence bound (%)"
label variable ppv_crude_uci "upper 95% confidence bound (%)"
note ppv_crude_lci: "Exact crude confidence intervals estimated using binomial methods"
label variable ppv_st "Standardised PPV (%)"
note ppv_st: "standardised using age and sex stratified ONS population estimates for each year"
label variable ppv_st_lci "lower 95% confidence bound (%)"
label variable ppv_st_uci "upper 95% confidence bound (%)"
note ppv_st_lci: "Exact standardised confidence intervals estimated using poisson process"
label variable sens_crude "Crude internal sensitivity (%)"
note sens_crude: "Do we need to / can we standardise this?"
label variable sens_crude_lci "lower 95% confidence bound (%)"
label variable sens_crude_uci "upper 95% confidence bound (%)"
note sens_crude_lci: "Exact crude confidence intervals estimated using binomial methods"

foreach measure in ppv_crude ppv_st sens_crude {
	replace `measure' = `measure' * 100
	foreach ci in lci uci {
		replace `measure'_`ci' = `measure'_`ci' * 100
	}
}


foreach measure in ppv_crude ppv_st sens_crude {
	gen `measure'_str = string(`measure', "%9.1fc") + " (" + string(`measure'_lci, "%9.1fc") + "-" + string(`measure'_uci, "%9.1fc") + ")"
}

label variable ppv_crude_str "Crude PPV % (95% CI)"
label variable ppv_st_str "Standardised PPV % (95% CI)"
label variable sens_crude_str "Internal sensitivity % (95% CI)"

order medcondition def confirmedcases sample ppv_crude_str ppv_st_str sens_crude_str ppv_crude ppv_crude_lci ppv_crude_uci ppv_st ppv_st_lci ppv_st_uci sens_crude sens_crude_lci sens_crude_uci
sort medcondition def

compress
save "$estimatesdir/v10.an_ppv_estimates.dta", replace




capture log close
