capture log close
log using "$logdir\v2.cr_formatted_validation_data.txt", replace text

/*******************************************************************************
# Stata do file:    v2.cr_formatted_validation_data
#
# Author:      Helen Strongman
#
# Date:        21/06/2024
#
# Description: 	Import and format validation data received from CPRD
#
# Inspired and adapted from: 
#				N/A
#
# Before running this file: Create data dictionary and save in meta data file.
#				Instructions are in the readme sheet.
*******************************************************************************/

**** Create variable labels, value labels and notes
import excel using "$metadir/datadictionary.xlsx", firstrow sheet("dictionary") case(lower) clear

*remove "_" from columnname
replace columnname = subinstr(columnname, "_" , "", .)

*remove "Q:" and "Response:" from columndescription
replace columndescription = subinstr(columndescription, "Q:", "", .)
replace columndescription = subinstr(columndescription, "Response:", "", .)
*remove leading and trailing spaces
*replace columndescription = strtrim(columndescription)


*create variable list and locals for varlabels
levelsof columnname if itemtype != "Header", local(varnames)
di `"`varnames'"'
foreach var of local varnames {
	di "`var'"
	levelsof columndescription if columnname == "`var'", local(`var'label)
	di ``var'label'
}

/*DOING THIS MANUALLY - SEE LATER
*if itemtype == "Header", create local for note and remove from variable list
*this represents questions with "tick all that apply" answers

levelsof columnname if itemtype == "Header", local(headernames)
foreach header of local headernames {
	levelsof columndescription if columnname == "`header'", local(`header'note)
	di ``header'note'
}

*if decodedvalue contains "1/2/3" create value label
levelsof columnname if strmatch(codedvalue, "1/2/3*"), local(valuevars)
foreach var of local valuevars {
	levelsof decodedvalue if columnname == "`var'", local(`var'value)
	di ``var'value'
}

*identify data variables
levelsof columnname if strmatch(format, "*DD/MM/YYYY*"), local(datevars)
di `datevars'
*/

**** Import, format and label data checking that all variables are in the dataset
import delimited using "$datadir_raw/LSHTMSleep Apnoea_P008_finaldataset_19062024/2023_LSHTM_Sleep Apnoea_P008_finaldataset_19062024.csv", clear varnames(1) stringcols(_all)

*remove "_" from varnames
qui describe, varlist
local variables = "`r(varlist)'"
foreach var of local variables {
	local newname = subinstr("`var'", "_" , "", .)
	rename `var' `newname'
}


*confirm variables exist, label variables, replace null with missing, and destring numeric vars
di `varnames'
foreach var of local varnames {
	di "`var'"
	capture confirm string variable `var'
	di `"``var'label'"'
	local label `"``var'label'"'
	di `label'
	label variable `var' `label'
	replace `var' = "" if `var' == "NULL"
	capture destring `var', replace
}

format patid %15.0g
label variable q1a "Has this patient been diagnosed or treated by a hospital specialist at any time?"

*format date values
foreach var in q1b q3b {
	gen _`var' = date(`var', "YMD")
	*assert _`var' !=. if `var' !=.
	drop `var'
	rename _`var' `var'
	format `var' %td
	di `"``var'label'"'
	local label `"``var'label'"'
	di `label'
	label variable `var' `label'
}

*label values
/*can't get this to work - will do it manually - it's probably something to do
with the way the brackets are read in from the Excel file _ I had to rewrite
the manual labels to replace these
foreach var of local valuevars {
	di `"``var'value'"'
	local label `"``var'value'"'
	label define `var'lab "`label'"
	label values `var' `var'lab
	tab "`var'"
}
*/



label define q4lab 1 "Type 1 narcolepsy or cataplexy" 2 "Type 2 narcolepsy or no cataplexy" 3 "No information available" 4 "Other/unclear"
label values q4 q4lab


label define q5lab 1 "Mild (AHI 5 to 14)" 2 "Moderate (AHI 15 to 30)" 3 "Severe (AHI >30)" 4 "Oxygen Desaturation Index score with severity not stated" 5 "Unclear / no information available"
label values q5 q5lab


*add notes

/*can't get this to work - doing it manually
di "`headernames'"
foreach header of local headernames {
	notes: "``header'note'"
}
*/

notes: "q1c: Which of the following methods were used to diagnose the patient?"
notes: "q3c: What was the result of the referral?"
notes: "q3d: Which of the following information about the specified condition is included in the patient's record?"
notes list

*make sure that at least one box is ticked for "tick all that apply" questions
foreach var in q1c q3c q3d {
	di "`var'"
	qui describe `var'*, varlist
	local varlist = "`r(varlist)'"
	egen _`var'total = rowtotal(`varlist')
	tab _`var'total
}

assert _q1ctotal > 0 if q1a == 1
tab _q1ctotal if q1a == 1

capture assert _q3ctotal > 0 if q3a == 1
if _rc {
	di "assert failed"
}
tab _q3ctotal if q3a == 1

assert _q3dtotal > 0 if q3a == 0
tab _q3dtotal if q3a == 0

**** Check routing
*Q1B, Q1C and Q2A - complete if Q1A = yes
*0/1 values have been coded as 0 if the question was skipped
*I've recoded these as missing
foreach var in q1b q1c q2a {
	qui describe `var'*, varlist
	local varlist = "`r(varlist)'"
	foreach var of local varlist {
		di "`var'"
		capture assert `var' !=. if q1a==1
		if _rc {
			qui count if q1a==1 & `var' == .
			di "`r(N)' rows with q1a == yes have a missing value in `var'"
		}
		assert (`var' == 0 | `var' ==.) if q1a==0
		replace `var' = . if q1a==0
	}
}

*Q3A - complete if Q1A = no
assert q3a !=. if q1a == 0
assert q3a ==. if q1a==1

*Q3B/Q3C - complete if Q3A = "Yes"
*0/1 values have been coded as 0 if the question was skipped
*I've recoded these as missing
foreach var in q3b q3c {
	qui describe `var'*, varlist
	local varlist = "`r(varlist)'"
	foreach var of local varlist {
		di "`var'"
		capture assert `var' !=. if q3a == 1
		if _rc {
			qui count if q3a==1 & `var' == .
			di "`r(N)' rows with q3a == yes have a missing value in `var'"
		}
		assert (`var' == 0 | `var' ==.) if q3a==0
		replace `var' = . if q3a==0
	}
}

*Q3D - complete if Q3A = "no"
*0/1 values have been coded as 0 if the question was skipped
*I've recoded these as missing
qui describe q3d*, varlist
local varlist = "`r(varlist)'"
foreach var of local varlist {
	di "`var'"
	capture assert `var' !=. if q3a == 0
	assert (`var' == 0 | `var' ==.) if q3a==1
	replace `var' = . if q3a==1
	}

*Q4 only for narcolepsy and if q1a == 1
replace medcondition = "narcolepsy" if medcondition == "Narcolepsy"
capture assert q4 !=. if q1a == 1 & medcondition == "narcolepsy"
if _rc {
	di "assert failed"
	replace q4 = 4 if q4 == . & q1a == 1
	/*CPRD indicated that the missing detail was associated with a comment that
	we can't see but suggested that it wasn't possible to answer the question*/
}
assert q4 ==. if q1a == 0 & medcondition == "narcolepsy"

*Q5 only for OSA and if q1a == 1
assert q5 !=. if q1a == 1 & medcondition == "OSA"
assert q5 ==. if q1a == 0 & medcondition == "OSA"

*Q5a - only if Q5 == 4
assert q5== 4 if q5a !=.
assert q5a!=. if q5==4 /*need to convert these*/

*** Data management

*combine diagnosed with other sleep disorder categories
*added 14 Feb
egen q3c7c = rowmax(q3c4 q3c5 q3c6 q3c7)
label variable q3c7c "Diagnosed with other sleep disorder"

*create variable for severity combining q5 and q5a
gen q5comb = q5
recode q5comb 4 = 1 if q5a >=5 & q5a <15
recode q5comb 4 = 2 if q5a >=15 & q5a <30
recode q5comb 4 = 3 if q5a >=30 & q5a !=.
recode q5comb 4 = 5 if q5a <5
*https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8889990/
label values q5comb q5lab
label variable q5comb "Severity of OSA"
tab q5comb, m


assert validationquestionnairecomplet == "2"
drop validationquestionnairecomplet completiondate

**** 


qui describe q*, varlist
local varlist = "`r(varlist)'"
foreach var of local varlist {
	describe `var'
	if "`var'" == "q1b" | "`var'" == "q3b" {
		summ `var', d format
	}
	else {
	 tab `var' medcondition, col
	}
}


/*check failures - starred out so these don't appear in the log
*they are different patids
list patid if q1a==1 & q1b == . /*instruction = must provide value*/
list patid if _q3ctotal == 0 & q3a == 1 /*instruction = must provide value*/
list patid if  q4 ==. & q1a == 1 & medcondition == "narcolepsy" /*instruction = must provide value*/
list patid if q1b == d(01/02/1963) /*not a failure as constraints weren't set but weird - will need to deal with this in data management stage*/
*/

drop _*		


**** Create overall variable for basis of coded record
gen summary = 0
recode summary 0 = 1 if q1a == 1
recode summary 0 = 2 if q3a == 1
recode summary 0 = 3 if q3a == 0
label define summarylab 1 "Diagnosis or treatment of sleep disorder" 2 "Referral but no diagnosis" 3 "No referral"
label values summary summarylab
label variable summary "Basis of coded record"
tab summary, m

**** Create variables comparing questionnaire dates to our definition
tempfile validationdata
save `validationdata'

use "$datadir_an\11.cr_validationcohort_an_flowchart_OSA_aurum_linked.dta"
gen medcondition = "OSA"
append using "$datadir_an\11.cr_validationcohort_an_flowchart_narcolepsy_aurum_linked.dta"
replace medcondition = "narcolepsy" if medcondition == ""

keep patid indexdate medcondition yob regstartdate
merge 1:1 patid medcondition using `validationdata'
assert _merge !=2
keep if _merge == 3
drop _merge

*validate q1b (date of diagnosis)
summ q1b, d format
list q1b indexdate yob regstartdate if q1b == `r(min)'
br if q1b == `r(min)'
drop yob regstartdate

gen timelagtodiagcode = indexdate - q1b if q1b !=.
label variable timelagtodiagcode "Days between recorded and confirmed diagnosis date (positive = recorded later)"
summ timelagtodiagcode, d format

gen timediffcat = 1 if timelagtodiagcode <-183
replace timediffcat = 2 if timelagtodiagcode >=-183 & timelagtodiagcode <-30
replace timediffcat = 3 if timelagtodiagcode >=-30 & timelagtodiagcode <= 30
*replace timediffcat = 4 if timelagtodiagcode == 0
*replace timediffcat = 4 if timelagtodiagcode>=0 & timelagtodiagcode <=30
replace timediffcat = 4 if timelagtodiagcode>30 & timelagtodiagcode <=183
replace timediffcat = 5 if timelagtodiagcode > 183 & timelagtodiagcode !=.

label define timediffcatlab 1 "Recorded diagnosis > 6 months before" ///
2 "Recorded diagnosis 1 to 6 months before" ///
3 "Recorded diagnosis within 1 month" ///
4 "Recorded diagnosis 1 to 6 months after" ///
5 "Recorded diagnosis > 6 months after", replace
label values timediffcat timediffcatlab
label variable timediffcat "Months between the recorded and confirmed diagnosis date "
tab timediffcat medcondition, col

gen timediffbin = 1 if timelagtodiagcode !=.
recode timediffbin 1 = 0 if abs(timelagtodiagcode) >= 183
label define timediffbinlab 0 "More than 6 months" 1 "Within 6 months", replace
label values timediffbin timediffbinlab
label variable timediffbin "Diagnosis recorded within +/- 6 months of confirmed diagnosis date"
tab timediffbin, m
tab timediffcat timediffbin, m

gen timelagtorefcode = (indexdate - q3b)/30 if q3b !=.
label variable timelagtorefcode "Months between recorded diagnosis and referral date (positive = recorded diagnosis later)"
summ timelagtorefcode, d format


**** create variable combining objectives methods in q1c
egen _obj = rowtotal(q1c1 q1c2 q1c3 q1c4 q1c5 q1c6 q1c7)
gen q1c_bin = 0 if q1a == 1
recode q1c_bin 0 = 1 if _obj >=1 & medcondition == "OSA"
recode q1c_bin 0 = 1 if q1c1==1 | q1c2 == 1 | q1c4 == 1 | q1c8 == 1
label variable q1c_bin "At least one objective diagnostic method identified"
label define q1c_binlab 0 "no objective methods" 1 "At least one objective method", replace
label values q1c_bin q1c_binlab
tab q1c_bin q1a, m 
drop _obj

*decided not to categorise other variables due to small cell count considerations

**** Save
order q*, alphabetic
order q1c10 q1c11 q1c_bin, after(q1c9)
order patid pracid medcondition, first

compress
save "$datadir_dm/v2.cr_formatted_validation_data.dta", replace

capture log close

