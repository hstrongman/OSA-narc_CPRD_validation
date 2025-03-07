

/*******************************************************************************
# Stata do file:    v7.cr_validationcohort_allvars.do
#
# Author:      Helen Strongman
#
# Date:       20/08/2024
#
# Description: Dataset with all validation questions and covariates
#                                
# Requirements: 
#                               
# Inspired and adapted from: 
#                               N/A     
*******************************************************************************/

/***************************************************************************
read in cohort data
****************************************************************************/
         
*read in cohort file
use "$datadir_an/37a.cr_unmatchedcohort_stsplit_allvars_OSA_linked.dta", clear

gen medcondition = "OSA"

append using "$datadir_an/37a.cr_unmatchedcohort_stsplit_allvars_narcolepsy_linked.dta"

replace medcondition = "narcolepsy" if medcondition == ""


/***************************************************************************
add questionnaire data
****************************************************************************/

merge 1:1 patid medcondition using "$datadir_dm/v2.cr_formatted_validation_data.dta"

assert _merge !=2

keep if _merge == 3

drop _merge


/**********************************************************************
alternative definitions
**********************************************************************/
distinct patid
merge m:1 patid using "$datadir_dm\9.cr_studypopulation_an_flowchart_aurum.dta", keep(3) nogen keepusing(SAdate_hesapc SASdate_hesapc OSAdate_pc OSASdate_pc SAdate_pc SASdate_pc narcolepsydate_hesapc narcolepsydate_pc)

*generate index date for primary care and secondary care OSA overall
gen OSAcombdate_pc = min(OSAdate_pc, OSASdate_pc, SAdate_pc, SASdate_pc)
format OSAcombdate_pc %td
label variable OSAcombdate_pc "OSA recorded diagnosis date, CPRD data only"

gen OSAcombdate_hesapc = min(SAdate_hesapc, SASdate_hesapc)
format OSAcombdate_hesapc %td
label variable OSAcombdate_hesapc "OSA recorded diagnosis date, HES APC data only"

*both CPRD and HES, record required in both data sources (index date = latest of the 2)
gen def_both_and = 0
replace def_both_and = 1 if cprdvshesapc <=3
gen index_both_and = max(OSAcombdate_hesapc, OSAcombdate_pc) if medcondition == "OSA" & def_both_and == 1
replace index_both_and = max(narcolepsydate_hesapc, narcolepsydate_pc) if medcondition == "narcolepsy" & def_both_and == 1
format index_both %td
label variable def_both "Diagnostic code in both CPRD and HES APC data"
label variable index_both "Recorded diagnosis date (date of first record in second dataset)"

*CPRD or HES (index date = 1st) - check same as main index date
gen _test = min(OSAcombdate_hesapc, OSAcombdate_pc) if medcondition == "OSA"
assert _test == indexdate if  medcondition == "OSA"
drop _test
gen def_either = 1
rename indexdate index_either
label variable index_either "Diagnostic code in either CPRD or HES APC data"
label variable index_either "Recorded diagnosis date (date of first record in first dataset)"

*CPRD data
gen def_cprd = 0
replace def_cprd = 1 if cprdvshesapc ! = 5 /*5 = HES APC only*/
gen index_cprd = narcolepsydate_pc if medcondition == "narcolepsy" & def_cprd == 1
replace index_cprd = OSAcombdate_pc if medcondition == "OSA" & def_cprd == 1
format index_cprd %td
label variable def_cprd "Diagnostic code in CPRD data"
label variable index_cprd "Recorded diagnosis date (date of first record in CPRD)"

*HES APC data
gen def_hesapc = 0
replace def_hesapc = 1 if cprdvshesapc !=4 /*4 = CPRD only*/
gen index_hesapc = narcolepsydate_hesapc if medcondition == "narcolepsy" & def_hesapc == 1
replace index_hesapc = OSAcombdate_hesapc if medcondition == "OSA" & def_hesapc == 1
format index_hesapc %td
label variable index_hesapc "Diagnostic code in HES APC data"
label variable index_hesapc "Recorded diagnosis date (Date of first record in HES APC)"


*CPRD or HES and CPRD only, with OP visits

foreach source in either cprd {
foreach optype in outpatient /*respiratory neurology ent paediatrics anaesthetics*/ posssleep {
	di "`optype'"
	if "`optype'" == "outpatient" local short = "any"
	*if "`optype'" == "neurology" local short = "neuro"
	*if "`optype'" == "respiratory" local short = "resp"
	*if "`optype'" == "ent" local short = "ent"
	if "`optype'" == "posssleep" local short = "poss"
	di "`short'"
	
	gen def_`source'_`short'op = def_`source'
	tab `optype', m
	replace def_`source'_`short'op = 0 if `optype' == 0
	replace def_`source'_`short'op = . if `optype' == . /*not included in linkage processing*/
	gen index_`source'_`short'op = max(index_`source', `optype'date) if def_`source'_`short'op == 1
	format index_`source'_`short'op %td
	*label variable def_either_`short'op "Code in either source and `short' OP visit"
	*label variable index_either_`short'op "Index date (latest of date of first code and first valid OP visit)"
}
}

label variable def_either_anyop "Code in either source and any OP visit"
label variable def_either_possop "Code in either source and OP visit to possible sleep specialist"
label variable def_cprd_anyop "Code in CPRD and any OP visit"
label variable def_cprd_possop "Code in CPRD and OP visit to possible sleep specialist" 

drop SAdate_hesapc SASdate_hesapc OSAdate_pc OSASdate_pc SAdate_pc SASdate_pc narcolepsydate_hesapc narcolepsydate_pc OSAcombdate_hesapc OSAcombdate_pc

*CPRD or HES and CPRD only, with EDS drugs
foreach source in either cprd {
	gen def_`source'_edsdrug = 0
	replace def_`source'_edsdrug = 1 if def_`source' == 1 & edsdrug == 1
	gen index_`source'_edsdrug = max(index_`source', edsdrugdate) if def_`source'_edsdrug == 1
	format index_`source'_edsdrug %td
}

label variable def_either_edsdrug "Code in either source and EDS drug"
label variable def_cprd_edsdrug "Code in CPRD and EDS drug"

*time lag variables for each definition
foreach def in both_and either cprd hesapc either_anyop either_possop cprd_anyop cprd_possop either_edsdrug cprd_edsdrug {
	gen _missing = 1 if q1a == 0 | q1b ==. |  def_`def'!=1
	gen timelagtodiagcode_`def' = index_`def' - q1b if _missing !=1
	label variable timelagtodiagcode_`def' "Days between recorded and confirmed diagnosis date (positive = recorded later)"
	summ timelagtodiagcode_`def', d format

	gen timediffcat_`def' = 1 if timelagtodiagcode_`def' <-183
	replace timediffcat_`def' = 2 if timelagtodiagcode_`def' >=-183 & timelagtodiagcode_`def' <-30
	replace timediffcat_`def' = 3 if timelagtodiagcode_`def' >=-30 & timelagtodiagcode_`def' <= 30
	*replace timediffcat = 4 if timelagtodiagcode == 0
	*replace timediffcat = 4 if timelagtodiagcode>=0 & timelagtodiagcode <=30
	replace timediffcat_`def' = 4 if timelagtodiagcode_`def' >30 & timelagtodiagcode_`def' <=183
	replace timediffcat_`def' = 5 if timelagtodiagcode_`def' > 183 & timelagtodiagcode_`def' !=.
	replace timediffcat_`def' = . if _missing == 1

	label define timediffcatlab 1 "> 6 months before" ///
	2 "1 to 6 months before" ///
	3 "within 1 month" ///
	4 "1 to 6 months after" ///
	5 "> 6 months after", replace
	label values timediffcat_`def' timediffcatlab
	label variable timediffcat_`def' "Recorded diagnosis date compared to confirmed date"
	tab timediffcat_`def' medcondition, col

	gen timediffbin_`def' = 1 if _missing !=1
	recode timediffbin_`def' 1 = 0 if abs(timelagtodiagcode_`def') > 183
	label define timediffbinlab 0 "More than 6 months" 1 "Within 6 months", replace
	label values timediffbin_`def' timediffbinlab
	label variable timediffbin_`def' "Diagnosis recorded within +/- 6 months of confirmed diagnosis date"
	tab timediffbin_`def', m
	tab timediffcat_`def' timediffbin_`def', m

	gen timelagtorefcode_`def' = (index_`def' - q3b)/30 if q3b !=. & def_`def'==1
	label variable timelagtorefcode_`def' "Months between recorded diagnosis and referral date (positive = recorded diagnosis later)"
	summ timelagtorefcode_`def', d format
	drop _missing
}

/**********************************************************************
save dataset
***********************************************************************/

save "$datadir_an/v7.cr_validationcohort_allvars.dta", replace

capture log close