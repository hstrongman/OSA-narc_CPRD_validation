

capture log close
log using "$logdir\v6.an_table1.txt", replace text

/*******************************************************************************
# Stata do file:    v6.an_table1.do
#
# Author:      Helen Strongman
#
# Date:       20/08/2024. Updated 21/07/2024 to count people in the validation
#				cohort in both cohorts
#
# Description: Descriptive table describing composition of incident and validation
#				cohorts
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

***read in cohort file
*narcolepsy first to retain value labels for age that include children
use "$datadir_an/37a.cr_unmatchedcohort_stsplit_allvars_narcolepsy_linked.dta", clear
gen medcondition = "narcolepsy"
append using "$datadir_an/37a.cr_unmatchedcohort_stsplit_allvars_OSA_linked.dta"
replace medcondition = "OSA" if medcondition == ""

*flag validation study cohort
merge 1:1 patid medcondition using "$datadir_dm/v2.cr_formatted_validation_data.dta", keepusing(patid)
assert _merge !=2
gen _validation = 1 if _merge ==3
drop _merge

/*duplicate rows for validation cohort - members should be included in both the
validation and incident cohort*/
expand 2 if _validation == 1, gen(_expand)
replace _validation = 0 if _expand == 0

gen exposed = .
label define exposedlab 0 "OSA incident cohort" 1 "OSA validation sample" 2 "narcolepsy incident cohort" 3 "narcolepsy validation sample"
label values exposed exposedlab
replace exposed = 0 if medcondition == "OSA" & _validation == 0
replace exposed = 1 if medcondition == "OSA" & _validation == 1
replace exposed = 2 if medcondition == "narcolepsy" & _validation == 0
replace exposed = 3 if medcondition == "narcolepsy" & _validation == 1
tab exposed, m

/*******************************************************************************
tabulate all variables in dataset against medical condition
*******************************************************************************/
putexcel set "$resultdir\v6.an_table1.xlsx", replace 
*note: file will be replaced when the first putexcel command is issued.

putexcel B1 = "incident OSA", bold hcenter
putexcel C1 = "validation OSA", bold hcenter

putexcel D1 = "incident narcolepsy", bold hcenter
putexcel E1 = "validation narcolepsy", bold hcenter
putexcel A2 = "N+", bold

local expgroups = 4
local expcols = `expgroups' * 2
di `expcols'

local letterstring = substr("`c(ALPHA)'", 3, `expcols') /*2nd number should be 2 x number of exposure groups*/

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

******** PERSON TIME **********************************************
*global startrow = 3
*** Person years of follow-up
/*make this time since reg?*/

/*putexcel A$startrow = "Follow-up time (person-years)", txtindent(3)
gen pyears_total = (end_linked - start_linked)/365.25
gen pyears_prior = (indexdate - start_linked)/365.25
assert pyears_prior >=0
gen pyears_post = (end_linked - indexdate)/365.25
assert pyears_post >=0  

global startrow = $startrow + 1
local letterstring = substr("`c(ALPHA)'", 3, 4)
di "`letterstring'"

HSputexcel pyears_total "Total person-years of follow-up" numeric $startrow
global startrow = $startrow + 1

putexcel A$startrow = "Range", txtindent(3)
sleep 2000

local i = 0
foreach col of local letterstring {
        qui summ pyears_total if exposed == `i', d
        local rangemin = string(r(min), "%6.1fc")
        local rangemax = string(r(max), "%6.1fc")
        local rangestr = "`rangemin'" + "-" + "`rangemax'"
        putexcel `col'$startrow = ("`rangestr'"), hcenter
        sleep 2000
        local i = `i' + 1
}
global startrow = $startrow + 1
*/

******* DIAGNOSTIC RECORD

global startrow = 3

putexcel A$startrow = "RECORDING OF SLEEP DISORDER DIAGNOSIS", bold

global startrow = $startrow + 1


HSputexcel indexsource "Source of diagnostic code*" categ $startrow 4

HSputexcel indexcode "Most specific code type on recorded diagnosis date" categ $startrow 4

gen pyears_prior = (indexdate - regstartdate)/365.25

assert pyears_prior >=0

HSputexcel pyears_prior "Person-years before recorded diagnosis" numeric $startrow 4

*HSputexcel pyears_post "Person-years after diagnosis/index" numeric $startrow

*HSputexcel calendaryear_cat "Calendar year at index" categ $startrow 4

HSputexcel calendaryear "Year of recorded diagnosis" numeric $startrow 4

drop pyears*

*** SUPPORTING INFORMATION

global startrow = $startrow + 1


putexcel A$startrow = "ADDITIONAL INFORMATION IN ROUTINELY COLLECTED DATA", bold

global startrow = $startrow + 1


putexcel A$startrow = "Outpatient visit within 6 months of recorded diagnosis (HES OP data)", bold

global startrow = $startrow + 1

HSputexcel oplinkage "Linked OP data available" binary $startrow 4
/* i.e. linked data requested for main study and index date with coverage period +/- 6 months*/

HSputexcel outpatient "All" binary $startrow 4

HSputexcel neurology "Neurology" binary $startrow 4

HSputexcel respiratory "Respiratory" binary $startrow 4

HSputexcel paediatrics "Paediatric (NOS)" binary $startrow 4

HSputexcel ent "Ear Nose & Throat" binary $startrow 4

HSputexcel anaesthetics "Anaesthetics" binary $startrow 4

HSputexcel posssleep "Sleep-related consultants combined" binary $startrow 4

global startrow = $startrow + 1


HSputexcel edsdrug "EDS drug prescription ever" binary $startrow 4
HSputexcel edsdrugdiff "Days between recorded diagnosis date & 1st EDS drug prescription (positive = recorded first)" numeric $startrow 4
HSputexcel edsdrugdiff_cat "Recorded diagnosis compared to date of 1st EDS drug prescription" categ $startrow 4

*** Characteristics
putexcel A$startrow = "CHARACTERISTICS", bold

sleep 2000

global startrow = $startrow + 1

HSputexcel age_index "Age at recorded diagnosis (years)" numeric $startrow 4

*HSputexcel agecat "Age at diagnosis (years)" categ $startrow 4

HSputexcel gender "Sex" categ $startrow 4

HSputexcel bmicat "Body Mass Index" categ $startrow 4

HSputexcel eth5 "Ethnicity" categ $startrow 4

HSputexcel carstairs "Carstairs quintile" categ $startrow 4

HSputexcel urban "Urban Rural" categ $startrow 4

*HSputexcel pracsize_cat "Practice size quintile" categ $startrow 4

HSputexcel pracsize "Practice size" numeric $startrow 4

capture log close

