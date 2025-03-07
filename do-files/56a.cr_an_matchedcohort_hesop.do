
capture log close
log using "$logdir\56a.cr_an_matchedcohort_hesop.txt", text replace

/*******************************************************************************
# Stata do file:    56a.cr_an_matchedcohort_hesop.do
#
# Author:      Helen Strongman
#
# Date:        29/01/2024
#
# Description: 	This do file creates an analysis data file for HES outpatient
#				count outcomes (attendance overall and by specialty)
#
#				Outpatient attendance definition: all outpatient visits marked
#				as attended in HES OP data
#
#				NOTE - ADAPTATION FROM MAIN STUDY = 
#				COUNTS NOT NEEDED - JUST ID THE FIRST NEUROLOGY, RESPIRATORY AND
#				ALL OUTPATIENT VISITS WITHIN 6 MONTHS OF THE INDEX DATE
#
# Before running this do file: Create lookups using HES Data Dictionaries
#				referenced in CPRD HES OP documentation
#				(https://digital.nhs.uk/data-and-information/data-tools-and-services/data-services/hospital-episode-statistics/hospital-episode-statistics-data-dictionary)
#				I pasted the excel cell contents into Word and replaced
#				`= ' with `^t' and `""' with `', added variable labels (variable name, description), then saved to a text file
#					
# Post-protocol decisions: 
# 				CWG grouped specialties with High level grouping based on NHS 
#				Data model and dictionary 
#				https://www.datadictionary.nhs.uk/supporting_information/main_specialty_and_treatment_function_codes_table.html?hl=main%2Cspecialty%2Ctreatment%2Cfunction%2Ccodes
#				see also "$dofiles/labels/mainspef_groups.xlsx"
#
#				Decision to drop "Pseudo MAIN SPECIALTY CODES" i.e.
#				560 Midwifery, 950 Nursing, 960 "Allied Health Professional"
#				These are used for lead CARE PROFESSIONALS other than CONSULTANT 
#				medical and dental staff e.g. 560, 950 and 960 and are not
#				attributed to a speciality (HES OP coverage is likely to have
#				changed over time for these appointments - see 
#				https://digital.nhs.uk/data-and-information/publications/statistical/hospital-outpatient-activity/outpatient-data-quality-report)
#
#				Only count 1 appt with the same specialty in one day. Note, this
#				drops more appointments for 2018/2019 than other years, leaving fewer appointments than in previous years
#
# Questions: OP- group clinical oncology and medical oncology? plus opthalmology and cardiology
#				add medical microbiology and virology to infectious diseases?
#
# Requirements: inc_0.
#				
*******************************************************************************/

***generate labels from lookups
*can't do this for diag3 and treat3 because coding scheme is not numeric
foreach varname in attended mainspef tretspef {
	include "$dodir/inc_0.cr_do_labels.do"
}

pause off

foreach medcondition in OSA narcolepsy {
	
	*** HES OP DATA ***
	use patid attendkey tretspef mainspef using "$datadir_raw_orig/55.hesop_clinical_22_001887_DM_`medcondition'.dta", clear
	

	/*LABEL AND GROUP SPECIALTY VARIABLES
	mainspef = The specialty under which the consultant is contracted. Compare with the treatment specialty (TRETSPEF), the specialty under which the consultant worked
	tretspef = The specialty in which the consultant was working during the period of care. It can be compared with MAINSPEF, the specialty under which the consultant is contracted. Prior to 1 April 1996, this data item contained the code for the sub-specialty. From April 2004 a new list of treatment specialities was introduced, which describes the specialised service within which the patient was treated.
	*/

	foreach varname in mainspef tretspef {
		replace `varname' = "" if `varname' == "&"
		destring `varname', replace
		do "$dodir/labels/`varname'.do"
		label values `varname' `varname'lab
	}
	

	label variable mainspef "Consultant speciality"
	label variable tretspef "Specialist service"
	
	/* drop pseudo-main speciality codes (see above)*/
	drop if mainspef == 560 | mainspef == 950 | mainspef == 960

	tab mainspef, m sort
	tab tretspef, m sort
	count if mainspef != tretspef
	
	label define mainspef_highlab 0 "Medical" 1 "Surgery" 2 "Psychiatry" 3 "Other"

	gen mainspef_high = .
	label variable mainspef_high "Consultant speciality group"
	replace mainspef_high = 1 if mainspef >=100 & mainspef <=171
	replace mainspef_high = 0 if mainspef >=180 & mainspef <=620
	replace mainspef_high = 2 if mainspef >=700 & mainspef <=715
	replace mainspef_high = 3 if mainspef >=800 

	replace mainspef_high = 1 if mainspef == 191
	replace mainspef_high = 0 if mainspef == 831
	replace mainspef_high = 0 if mainspef == 833
	replace mainspef_high = 0 if mainspef == 834
	replace mainspef_high = 3 if mainspef == 199
	replace mainspef_high = 3 if mainspef == 499
	replace mainspef_high = 3 if mainspef == 560
	label values mainspef_high mainspef_highlab
	tab mainspef mainspef_high

	gen mainspef_tidy = mainspef
	label variable mainspef_tidy "Consultant speciality"
	note mainspef_tidy: "Original categories with Obs/gyn and oral/dentisty grouped by CWG"
	label copy mainspeflab mainspef_tidylab
	label define mainspef_tidylab 991 "Oral/Dentistry" 992 "OBS/GYN", add
	label values mainspef_tidy mainspef_tidylab
	
	replace mainspef_tidy = 991 if mainspef >=140 & mainspef <=149
	replace mainspef_tidy = 991 if mainspef == 450
	replace mainspef_tidy = 991 if mainspef == 451
	replace mainspef_tidy = 991 if mainspef == 601
	replace mainspef_tidy = 991 if mainspef == 902
	replace mainspef_tidy = 991 if mainspef == 904
	tab mainspef if mainspef_tidy == 991

	replace mainspef_tidy = 992 if mainspef == 501
	replace mainspef_tidy = 992 if mainspef == 502
	replace mainspef_tidy = 992 if mainspef >=510 & mainspef <=560
	replace mainspef_tidy = 992 if mainspef == 610
	tab mainspef if mainspef_tidy == 992
	
	tab mainspef_tidy mainspef_high, m

	/**MERGE WITH APPOINTMENT FILE TO ADD "ATTENDED" AND "APPTDATE VARIABLES"**/
	isid patid attendkey
	merge 1:1 patid attendkey using "$datadir_raw_orig/55.hesop_appointment_22_001887_DM_`medcondition'.dta", keepusing(attended apptdate)
	keep if _merge == 3 /*using only = pseudo specialty codes*/
	drop _merge

	*format apptdate
	rename apptdate _apptdate
	gen apptdate = date(_apptdate, "DMY")
	format apptdate %td
	summ apptdate, format
	drop _apptdate
	label variable apptdate "Appointment date"

	/*format attended
	A code to indicate whether a patient attended an appointment or not. 
	If the patient did not attend it also indicates whether or not advanced warning was given.
	*/

	local varname "attended"
	do "$dodir/labels/`varname'.do"
	label values `varname' `varname'lab
	tab attended, m
	label list attendedlab

	gen attendsumm = .
	replace attendsumm = 1 if attended == 5 | attended == 6
	replace attendsumm = . if attended == 9
	replace attendsumm = 2 if attended <=4 | attended == 7
	label define attendsummlab 1 "attended" 2 "did not attend/cancelled"
	label values attendsumm attendsummlab
	tab attended attendsumm, m
	tab attendsum, m

	tab mainspef attendsumm, m

	keep if attendsumm == 1
	gen event = 1
	label variable event "Outpatient visit"
	
	/*outpatient visits to the same specialty on the same day*/
	duplicates tag patid mainspef_tidy apptdate, gen(_dup)
	tab _dup, m
	gen _appyear = year(apptdate)
	tab _appyear _dup, row
	/*higher levels of duplication in 2018/2019*/
	bysort patid apptdate mainspef_tidy: keep if _n==1
	
	
	/*label neurology and respiratory appointments (added)*/
	gen neurology = 0
	replace neurology = 1 if mainspef_tidy == 400 | mainspef_tidy == 401 | mainspef_tidy == 421
	label variable neurology "Neurology outpatient attendance (includes paediatric neurology & clinical neurophysiology)"
	
	gen respiratory = 0
	replace respiratory = 1 if mainspef_tidy == 340
	label variable respiratory "Respiratory outpatient attendance"
	
	/*gen neuroresp = 0
	replace neuroresp = 1 if neurology == 1 | respiratory == 1
	label variable neuroresp "Outpatient attendance to neurology or respiratory service"*/
	
	gen ent = 0
	replace ent = 1 if mainspef_tidy == 120
	label variable ent "ENT outpatient attendance"
	
	gen paediatrics = 0
	replace paediatrics = 1 if mainspef_tidy == 420
	label variable paediatrics "Paediatric (NOS) outpatient attendance"
	
	gen anaesthetics = 0
	replace anaesthetics = 1 if mainspef_tidy == 420
	label variable anaesthetics "Anaesthetics outpatient attendance"
	
	gen posssleep = 0
	replace posssleep = 1 if neurology == 1 | respiratory == 1 | paediatrics == 1 |ent == 1
	label variable posssleep "Outpatient attendance with neurology, respiratory, ENT or paediatric consultant"
	
	assert mainspef_tidy != 223 & mainspef_tidy != 291
	/*223 = paediatric epilepsy service, 291 = paediatric neurodisability service*/
	
	keep patid event neurology respiratory ent paediatrics anaesthetics posssleep apptdate mainspef_tidy
	duplicates drop
	
	/*merge with incident file and create variables identifying the first outpatient
	event within 6 months of the index date (added)*/
	merge m:1 patid using "$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_aurum_linked.dta", keepusing(patid indexdate)
	drop if _merge == 1
	drop _merge
	
	*calculate abs difference between OP appt and indexdate
	gen _diff = abs(apptdate - indexdate)
	*assert _diff != .
	tab mainspef_tidy if _diff <= 182.625, sort
	
	drop mainspef_tidy
	
	rename event outpatient
	
	foreach var in outpatient neurology respiratory ent paediatrics anaesthetics posssleep {
		/*set all events that are more than 1 year before or after the index
		date to missing*/
		replace `var' = . if `var' == 0
		replace `var' = . if _diff > 182.625
		/*set variable specific date for valid events*/
		gen _`var'date = apptdate if `var' == 1
		format _`var'date %td
		/*add count of number of valid events to all rows*/
		bysort patid: egen _`var'count = count(`var')
		/*add index date for OP variable to all rows. This is the first
		event in the plus/minus 6 month window*/
		bysort patid (_`var'date): egen `var'date = min(_`var'date)
		format `var'date %td
		label variable `var'date "First `var' attendance within 6 months of index"
		/*reset variable identifier to 1 for all rows with at least one valid
		event*/
		replace `var' = 1 if _`var'count > 0
		replace `var' = 0 if _`var'count == 0
		label variable `var' "At least one `var' attendance within 6 months of index"
	}

	*** linked data requested / eligible for HES OP
	tempfile temp
	save `temp'
	*patient file used for type 2 linkage request
	use patid using "$datadir_dm_orig\12.cr_getmatchedcohort_`medcondition'_aurum_linked.dta", clear
	duplicates drop
	gen oplinkage = 1 /*note diagnostic codes for narc and OSA requested for all eligible patients
	so there is not problem with the sleep disorder definitions*/
	merge 1:1 patid using "$datadir_dm\4.cr_dm_all_registered_patients_aurum.dta", keepusing(hes_op_e)
	drop if _merge == 1 /*data requested but not in all registered patient list*/
	drop if _merge == 2 /*in current build but OP data not requested*/
	drop _merge
	tab oplinkage hes_op_e, m
	replace oplinkage = 0 if hes_op_e != 1
	drop hes_op_e
	merge 1:m patid using `temp'
	drop if _merge == 1 /*master only - in all registered pt list but not incident*/
	replace oplinkage = 0 if _merge == 2 /*not in patient list for link data request*/
	tab oplinkage
	drop _merge
	
	/**account for difference in linkage coverage period (added)*/
	replace oplinkage = 0 if indexdate < $studystart_hesop + 182.625
	replace oplinkage = 0 if indexdate > $studyend_hesop - 182.625
	label variable oplinkage "OP data requested and covers 6 months before and after index"
	foreach var in outpatient neurology respiratory ent paediatrics anaesthetics posssleep outpatientdate neurologydate respiratorydate entdate anaestheticsdate paediatricsdate posssleepdate {
		replace `var' = . if oplinkage == 0
	}
	
	drop _* apptdate 
	distinct patid
	local patcount = `r(ndistinct)'
	duplicates drop
	isid patid
	count
	assert `r(N)' == `patcount'
	
	compress
	save "$datadir_dm/56a.cr_an_matchedcohort_hesop_`medcondition'_linked.dta", replace

	/*/*outpatient visits to different specialties on the same day*/
	duplicates tag patid apptdate, gen(_dupcount)
	tab _dupcount, m
	summ _dupcount
	local maxdup = `r(max)'
	
	*generate variables with "extra" specialities visited on each day
	gen mainspef_tidyextra = ""
	label variable mainspef_tidyextra "additional specialties visited on same day"
	forvalues x = 1/`maxdup' {
		bysort patid apptdate (mainspef_tidy): ///
		replace mainspef_tidyextra = mainspef_tidyextra + "e" + string(mainspef_tidy[_n+`x']) ///
		if _dupcount >= `x' & _n == 1
	}

	gen mainspef_highextra = ""
	label variable mainspef_highextra "additional specialty group visited on same day"
	forvalues x = 1/`maxdup' {
		/*note sort on mainspef_tidy to keep same order as previous loop*/
		bysort patid apptdate (mainspef_tidy): ///
		replace mainspef_highextra = mainspef_highextra + "e" + string(mainspef_high[_n+`x']) ///
		if _dupcount >= `x' & _n == 1 & mainspef_high != mainspef_high[_n+`x']
	}
	
	*change event count to number of specialities visited on that day
	replace event = _dupcount + 1 if _dupcount >=1
	
	*keep row with extra specialities defined
	bysort patid apptdate (mainspef_tidy): gen _drop = 1 if _N >=2 & _n>=2
	tab _drop, m
	assert mainspef_tidyextra == "" if _drop == 1
	assert mainspef_highextra == "" if _drop == 1
	assert _dupcount > 0 if _drop == 1
	drop if _drop == 1
	
	keep patid mainspef_tidy mainspef_tidyextra mainspef_high mainspef_highextra apptdate event
	rename apptdate evdate
	label variable evdate "Appointment date"
	
	
	/*MERGE WITH MATCHED COHORT COVAR FOLDER*/
	local restrictcoverage = 1
	local linkedtext = "linked"
	local datasource = "hesop"
	local varsneeded = "mainspef_tidy mainspef_tidyextra mainspef_high mainspef_highextra"
	include "$dodir/inc_56+.cr_merge_counts_covars.do"
	
	compress
	save "$datadir_an/56.cr_an_matchedcohort_hesop_`medcondition'_linked.dta", replace
	pause
	*/
}



capture log close



