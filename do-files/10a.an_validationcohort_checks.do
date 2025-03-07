capture log close
log using "$logdir\10a.an_validationcohort_checks.txt", replace text

/*******************************************************************************
# Stata do file:    10a.an_validationcohort_checks.do
#
# Author:      Helen Strongman
#
# Date:        08/01/2024
#
# Description: 	This do file flags was used to decide a post-hoc sampling strategy
#				that balances the need to recruit a random sample with minimal
#				clustering whilst recognising practical constraints i.e. that
#				practices need a minimum return of investment to complete
#				questionnaires.
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off


use 


use "$datadir_an\10.cr_validationcohort_an_flowchart_OSA_aurum_linked.dta", clear
rename indexdate indexdate_OSA
rename indexcode indexcode_OSA
merge 1:1 patid using "$datadir_an\10.cr_validationcohort_an_flowchart_narcolepsy_aurum_linked.dta"
rename indexdate indexdate_narcolepsy
rename indexcode indexcode_narcolepsy
*matches have both narcolepsy and OSA


foreach medcondition in OSA narcolepsy {
	gen `medcondition' = 0
	replace `medcondition' = 1 if indexdate_`medcondition' != .
	distinct pracid if `medcondition' == 1
}
distinct pracid

tab OSA narcolepsy, m

*** how many practices/number per practice?

bysort pracid: gen _indexprac = 1 if _n == 1
bysort pracid: egen praccount = total(patid)
foreach medcondition in OSA narcolepsy {
	bysort pracid (indexdate_`medcondition'): egen praccount_`medcondition' = total(`medcondition')
	
}

tab praccount_narcolepsy if _indexprac == 1, m
summ praccount_OSA if _indexprac == 1 & praccount_OSA >0, d

gen praccount_OSA_cat = 0 if praccount_OSA == 0 & _indexprac == 1
replace praccount_OSA_cat = 1 if praccount_OSA > 0 & praccount_OSA <10 & _indexprac == 1
replace praccount_OSA_cat = 2 if praccount_OSA >= 10 & praccount_OSA <25 & _indexprac == 1
replace praccount_OSA_cat = 3 if praccount_OSA >= 25 & praccount_OSA <50 & _indexprac == 1
replace praccount_OSA_cat = 4 if praccount_OSA >= 50 & praccount_OSA <100 & _indexprac == 1
replace praccount_OSA_cat = 5 if praccount_OSA >= 100 & praccount_OSA <150 & _indexprac == 1
replace praccount_OSA_cat = 6 if praccount_OSA >= 150 & _indexprac == 1

label define praccount_OSA_cat_lab 0 "0" 1 "0 to 9" 2 "10 to 24" 3 "25 to 49" 4 "50 to 99" 5 "100 to 149" 6 "150 plus", replace
label values praccount_OSA_cat praccount_OSA_cat_lab
tab praccount_OSA_cat if _indexprac == 1, m

gen praccount_narcolepsy_cat = 0 if praccount_narcolepsy == 0 & _indexprac == 1
replace praccount_narcolepsy_cat = 1 if praccount_narcolepsy == 1 & _indexprac == 1
replace praccount_narcolepsy_cat = 2 if praccount_narcolepsy == 2 & _indexprac == 1
replace praccount_narcolepsy_cat = 3 if praccount_narcolepsy == 3 & _indexprac == 1
replace praccount_narcolepsy_cat = 4 if praccount_narcolepsy >= 4 & _indexprac == 1

label define praccount_narcolepsy_cat_lab 0 "0" 1 "1" 2 "2" 3 "3" 4 "4 plus"
label values praccount_narcolepsy_cat praccount_narcolepsy_cat_lab

tab praccount_OSA_cat praccount_narcolepsy_cat if _indexprac == 1, m

*tabstat praccount_OSA if _indexprac == 1, by(praccount_narcolepsy) stats (p25, p50, p75)


		
*does this vary by pracsize?
tabstat pracsize if _indexprac == 1, by(praccount_narcolepsy) stats (p25, p50, p75)
list pracsize if _indexprac == 1 & praccount_narcolepsy == 7

tabstat pracsize if _indexprac == 1, by(praccount_OSA_cat) stats (p25, p50, p75)
		
*** proportion linked only etc? - variation between practices?
tab cprdvshesapc if OSA == 1
tab cprdvshesapc if narcolepsy == 1
		
*** sleep apnoea codes used? - variation between practices?
tab indexcode_OSA if OSA == 1
		
*** time range 
summ indexdate, d format
		




