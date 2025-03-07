
capture log close
log using "$logdir\37a.cr_unmatchedchort_stsplit_allvars.txt", replace text

/*******************************************************************************
# Stata do file:    37a.cr_unmatchedcohort_stsplit_allvars.do
#
# Author:      Helen Strongman
#
# Date:        11/07/2023
#
# Description: 	Add all stratification variables to stsplit data
#
#				CHANGES FOR VALIDATION STUDY - 
#				changed input files
#				change globals to point to main study raw data for linked data 
#				add rows to identify recruitment sample
#
#				Note - copied pracsize cat data file from main study estimates drive
#
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off

noi {
foreach linkedtext in linked /*primary*/ {
foreach medcondition in narcolepsy OSA {
/*don't switch gold and aurum below*/
foreach database in /*gold*/ aurum {

	
	*use "$datadir_dm\18.cr_unmatchedcohort_stsplit_`medcondition'_`database'_`linkedtext'.dta", clear
	use "$datadir_dm\10.cr_incidentcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", clear
	

	*** in recruitment sample (added)
	merge 1:1 patid using "$datadir_an\11.cr_validationcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta"
	assert _merge !=2
	replace forrecruitment = 0 if _merge == 1
	drop _merge
	tab forrecruitment, m
	
	*** age (added)
	gen age_index = (indexdate - dob)/365.25 
	egen agecat = cut(age_index), at(0 9 18 25(10)85 132)
	include "$dodir\0.inc_agecatlabels.do"
	drop _agecatorig
	label variable age_index "Age at recorded diagnosis"
	label variable agecat "Age group"
	
	gen agebin = 0
	summ age_index, d
	replace agebin = 1 if age_index > r(p50)
	label define agebinlab 0 "Younger" 1 "older"
	label values agebin agebinlab
	label variable agebin "Age compared to median in incident cohort"
	tab agebin, m
	
	
	*** categories for codetype (added)

	if "`medcondition'" == "OSA" {
		gen _indexcode = 0
		replace _indexcode = 1 if strmatch(indexcode, "*OSA*")
		tab _indexcode indexcode, m
		*encode indexcode, generate(_indexcode) label(indexcodelab)
		drop indexcode
		rename _indexcode indexcode
		label define indexcodelab 0 "OSA code" 1 "sleep apnoea"
		label values indexcode indexcodelab
		label variable indexcode "Most specific code type on recorded diagnosis date"
		note indexcode: "OSA codes include OSAS"
		tab indexcode, m
	}
	
	if "`medcondition'" == "narcolepsy" {
		drop indexcode
		pause
	}
	
	
	*** source of index record (added)
	tab cprdvshesapc, m
	label list cprdvshesapclab
	
	gen indexsource = 0 if cprdvshesapc == 3 | cprdvshesapc == 4 | cprdvshesapc == 1  /*cprd*/
	replace indexsource = 1 if cprdvshesapc == 2 | cprdvshesapc == 5 /*HES*/
	label variable indexsource "Source of diagnostic code"
	label define indexsourcelab 0 "CPRD Aurum" 1 "HES APC"
	label values indexsource indexsourcelab
	*check that <2% of records have codes in both sources on the index date
	count if cprdvshesapc == 1
	local num = `r(N)'
	di `num'
	count
	local denom = `r(N)'
	di `denom'
	local prop = `num'/`denom'
	di `prop'
	assert `prop' < 0.02
	di `prop'
	note indexsource: "There is an index code for both sources in a small number of records (<2%)."
	note indexsource: "These are coded as primary care to avoid small cell counts"
	tab indexsource, m
	pause
	
	*** outpatient visits recorded in HES OP within 6 months of index date (added)
	merge 1:m patid using "$datadir_dm/56a.cr_an_matchedcohort_hesop_`medcondition'_linked.dta"
	assert _merge == 3
	drop _merge
	tab oplinkage, m
	tab outpatient, m
	pause
	
	*** EDS drug prescription ever
	if "`medcondition'" == "narcolepsy" {
		merge 1:1 patid using "$datadir_dm/33n.cr_edsdrugs_aurum"
		assert _merge == 3
		drop _merge
		tab edsdrug, m
		
		gen edsdrugdiff = edsdrugdate - indexdate
		summ edsdrugdiff, d /*note positive if index date is later*/
		/*huge difference observed between index and first drug prescription*/
		pause
		
		gen edsdrugdiff_cat = 1 if edsdrugdiff <-183
		replace edsdrugdiff_cat = 2 if edsdrugdiff >=-183 & edsdrugdiff <=183
		replace edsdrugdiff_cat = 3 if edsdrugdiff > 183 & edsdrugdiff !=.

		label define edsdrugdiff_catlab 1 "> 6 months before" ///
		2 "within 6 months" ///
		3 "> 6 months after", replace
		label values edsdrugdiff_cat edsdrugdiff_catlab
		label variable edsdrugdiff_cat "Recorded diagnosis date compared to date of first EDS drug prescription"
		tab edsdrugdiff_cat edsdrug, m col

	}
	if "`medcondition'" == "OSA" {
		gen edsdrug = .
		gen edsdrugdiff = .
		gen edsdrugdate = .
		gen edsdrugdiff_cat = .
	}
	*also have edsdrugdate
	
	label variable edsdrug "At least one EDS drug prescription in record"
	label variable edsdrugdate "Date of first EDS drug prescription"
	label variable edsdrugdiff "Days between recorded diagnosis date & 1st EDS drug prescription (positive = recorded first)"
	label variable edsdrugdiff_cat "Recorded diagnosis date compared to date of first EDS drug prescription"
	
	*** practice size quintile
	/*merge m:1 patid using "$datadir_dm\9.cr_studypopulation_an_flowchart_`database'.dta", keepusing(pracid pracsize)
	assert _merge !=1
	keep if _merge == 3
	drop _merge*/
	
	/*local defineboundaries = "no" /*copied practice size cat boundaries from main study*/
	include "$dodir/inc_0.inc_pracsize_cat.do"*/
	
	gen pracsize_bin = 0
	summ pracsize, d
	replace pracsize_bin = 1 if pracsize> r(p50)
	label define pracsize_binlab 0 "Smaller" 1 "larger"
	label values pracsize_bin pracsize_binlab
	label variable pracsize_bin "Practice size compared to median in incident cohort"
	tab pracsize_bin, m
	pause
	
	*** urban rural
	if "`linkedtext'" == "linked" {
		merge m:1 patid using "$datadir_raw_orig/27.cr_raw_studypop_linked_urban_`database'.dta"
		drop if _merge ==2
		drop _merge
		tab urban, m
	}
	pause
	
	*** area based deprivation
	merge m:1 pracid using "$datadir_raw_orig/27.cr_raw_studypop_linked_carstairs_`database'.dta"
	drop if _merge ==2
	drop _merge
	tab carstairs, m
	pause
	
	*binary (new)
	gen carstairs_bin = 0 if carstairs <=3
	replace carstairs_bin = 1 if carstairs == 4 | carstairs == 5
	assert carstairs_bin != .
	label define carstairs_binlab 0 "Less deprived" 1 "More deprived"
	label values carstairs_bin carstairs_binlab
	label variable carstairs_bin "Practice area-based deprivation"
	note carstairs_bin: "Less deprived = quintiles 1 to 3"
	tab carstairs_bin, m
	pause
	
	*** BMI
	
	if "`medcondition'" == "OSA" {
		
		/*modified for validation - one row per patient only*/
		merge 1:m patid using "$datadir_dm/30.cr_bmi_datamanagement_`database'.dta"
		drop if _merge ==2
		drop _merge
		
		*first make BMI missing for people/calendar years whose first BMI record is after their latest fupstart date
		gen _keep = 0
		replace _keep = 1 if (dobmi <= indexdate) | bmi == .
		bysort patid: egen _keeptotal = total(_keep)
		bysort patid: gen _keepextra = 1 if _keeptotal == 0 & _n == 1
		*br patid start_fup end_fup calendaryear bmi dobmi _startyear _fupstart _keep _keeptotal _keepextra
		replace _keep = 1 if _keepextra == 1
		replace bmi = . if _keepextra == 1
		replace dobmi = . if _keepextra == 1
		keep if _keep == 1
		drop _keep*
		*select nearest BMI measurement on or prior to the index date
		gsort patid -dobmi
		bysort patid: keep if _n==1
		summ bmi, d
		count if bmi == .
		
	
	/*
	*split files because there is not enough memory to do this using a single file
	*all patients from the same practice must be in the same file
	
	
	egen _filesplit = cut(pracsize), group(4) icodes
	tab _filesplit, m
	tabstat pracsize, by(_filesplit) stats(min max)
	pause
	tempfile tempmaster
	save "$datadir_dm/temp1.dta", replace /*too big as a temporary file*/
	
	forvalues i = 0/3 {
		
		use "$datadir_dm/temp1.dta", clear
		keep if _filesplit == `i'
		drop _filesplit
		joinby patid using "$datadir_dm/30.cr_bmi_datamanagement_`database'.dta", unmatched(master)
		tab _merge /*bmi missing for people with no bmi measures*/
		drop _merge
		*start of follow-up for each row
		gen _startyear = mdy(01,01,calendaryear)
		gen _fupstart = max(start_fup, _startyear)
		format _fupstart %td
		*for each year in the stsplit date, need BMI records before that date
		*first make BMI missing for people/calendar years whose first BMI record is after their latest fupstart date
		gen _keep = 0
		replace _keep = 1 if (dobmi <= _fupstart) | bmi == .
		bysort patid calendaryear: egen _keeptotal = total(_keep)
		bysort patid calendaryear: gen _keepextra = 1 if _keeptotal == 0 & _n == 1
		*br patid start_fup end_fup calendaryear bmi dobmi _startyear _fupstart _keep _keeptotal _keepextra
		replace _keep = 1 if _keepextra == 1
		replace bmi = . if _keepextra == 1
		replace dobmi = . if _keepextra == 1
		keep if _keep == 1
		drop _keep* _fupstart _startyear
		*select nearest BMI measurement on or prior to the index date
		gsort patid calendaryear -dobmi
		bysort patid calendaryear: keep if _n==1
		summ bmi, d
		
		*save/append split files
		if `i' > 0 append using "$datadir_dm/temp2.dta"
		save "$datadir_dm/temp2.dta", replace
	}
	
	erase "$datadir_dm/temp1.dta"
	*/
	
	*BMI categories
	gen bmicat = bmi
	label variable bmicat "BMI category"
	note bmicat: "World Health Organisation (WHO) Body Mass Index categories"
	note bmicat: "Based on the most recent BMI measurement on or prior to index date"
	*recode bmicat 0/18.4999999999=0 18.50/24.999999999999=1 25/29.999999999999=2 30/34.999999999999=3 35/39.99999999999=4 40/max=5
	recode bmicat 0/24.999999999999=0 25/29.999999999999=1 30/34.999999999999=2 35/39.99999999999=3 40/max=4
	replace bmicat = . if bmi == .
	*label define bmicatlab 0 "Underweight" 1 "Normal weight" 2 "Overweight" 3 "Obesity class I" 4 "Obesity class II" 5 "Obesity class III+"
	label define bmicatlab 0 "Under/normal weight" 1 "Overweight" 2 "Obesity class I" 3 "Obesity class II" 4 "Obesity class III+"
	label values bmicat bmicatlab
	tab bmicat, m
	*Binary BMI (replaces obesity variable)
	gen bmi_bin = bmicat
	recode bmi_bin 0/2=0 3/4=1
	label variable bmi_bin "BMI binary"
	label define bmi_binlab 0 "Obesity Class I and under (BMI<35kg/m2)" 1 "Obesity class II plus (BMI>=35kg/m2)"
	label values bmi_bin bmi_binlab
	tab bmi_bin, m
	pause
	
	} /*BMI*/
	
	*** ethnicity
	merge m:1 patid using "$datadir_dm/26.cr_temp_ethnicity_primary_`database'.dta", keepusing(eth5)
	drop if _merge ==2
	drop _merge
	if "`linkedtext'" == "linked" {
		merge m:1 patid using "$datadir_raw_orig/27.cr_raw_studypop_linked_ethnicity_`database'.dta", keepusing(heseth5)
		drop if _merge ==2
		drop _merge
		replace eth5=heseth5 if eth5>4 & heseth5!=. //replace ethnicity with HES ethnicity if still missing/notstated/equal
		drop heseth5
		}
	tab eth5, m
	replace eth5 = . if eth5 >=5
	assert eth5 !=18
	label variable eth5 "Ethnicity"
	note eth5: "derived using the most commonly recorded ethnicity in primary care data (or latest if equally common)"
	note eth5: "unknown and missing values replaced with most commonly recorded ethnicity in HES where available"
	label copy eth5 eth5lab
	label values eth5 eth5lab /*to follow consistent labelling convention*/
	pause
	
	/*** 5 YEAR CALENDAR YEAR CATEGORIES ***/
	gen calendaryear = year(indexdate) /*added*/
	label variable calendaryear "Year of recorded diagnosis"
	
	** Calendar year relative to median (replaces categorical)
	gen calendaryear_bin = 0
	summ calendaryear, d
	replace calendaryear_bin = 1 if calendaryear> r(p50)
	label define calendaryear_binlab 0 "Before" 1 "After"
	label values calendaryear_bin calendaryear_binlab
	label variable calendaryear_bin "Year of recorded diagnosis compared to median in incident cohort"
	tab calendaryear_bin, m
	pause
	/*
	egen byte calendaryear_cat = cut(calendaryear), at(2000(5)2020) icodes
	replace calendaryear_cat = calendaryear_cat + 1
	recode calendaryear_cat . = 0 if calendaryear < 2000
	recode calendaryear_cat . = 5 if calendaryear > 2019
	label variable calendaryear_cat "Categorical year at index date"
	qui summ calendaryear
	local minyear = `r(min)'
	local maxyear = `r(max)'
	label define calendaryear_catlab 0 "`minyear'-1999" 1 "2000-2004" 2 "2005-2009" 3 "2010-2014" 4 "2015-2019" 5 "2020-`maxyear'", replace
	label values calendaryear_cat calendaryear_catlab
	tab calendaryear calendaryear_cat, m
	label save calendaryear_catlab using "$dodir/labels/calendaryear_catlab", replace
	*/
			
	/*if "`database'" == "gold" gen database = 2
	if "`database'" == "aurum" gen database = 1 
	label variable database "CPRD database"
	label define databaselab 1 "Aurum" 2 "GOLD"
	label values database databaselab
	*/
	
	compress
	*if "`database'" == "aurum" append using "$datadir_an/37.cr_unmatchedcohort_stsplit_allvars_`medcondition'_`linkedtext'.dta"
	save "$datadir_an/37a.cr_unmatchedcohort_stsplit_allvars_`medcondition'_`linkedtext'.dta", replace
	capture erase "$datadir_dm/temp2.dta"
	
	
}
}
}
}

log close

