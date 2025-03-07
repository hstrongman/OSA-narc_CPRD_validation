capture log close
log using "$logdir\v1.an_sample_size_clusters.txt", replace text

/*******************************************************************************
# Stata do file:    v1.an_sample_size_clusters.do
#
# Author:      Helen Strongman
#
# Date:        21/11/2023
#
# Description: 	CPRD advise inviting practices that have >25 cases because these
#				practices have a higher incentive to take part. However, 
#				clustering by practice might affect the validity and power of my
#				analyses. This do file explores the impact of clustering on
#				study power. 
#
# Inspired and adapted from: 
#				N/A
*******************************************************************************/

**standard confidence interval calculations
cii proportions 100 0.9, exact
cii proportions 50 0.9, exact

*****************************************************************************************
***simulate dataset with clustered practices 
***************************************************************************************

clear 

set seed 23112424

set obs 100

gen id = _n 

/*generate simulated dataset based on the following assumptions*/

/*Assuming 40% of practices that respond have more than 1 eligible narcolepsy patient, 
this would result in an average of 1.4 completed narcolepsy questionnaire per practice.
This assumption is based on the proportions in the full eligible patient list.*/

*number of practices needed
local praccount = 100/1.4
local praccount = round(`praccount')
di "total number of practices: `praccount'"

*practices with 2 people = 40% of praccount
local praccount2 = round(0.4*`praccount')
di "practices with 2 people: `praccount2'"

*practices with 1 person
local praccount1 = `praccount' - `praccount2'
di "practices with 1 people: `praccount1'"

local people2 = `praccount2' * 2
di "people in practices with 2 people: `people2'"

egen _prac2 = seq() if _n <= `people2', from(1) to (`people2') block (2)
local start1 = `praccount2' + 1
egen _prac1 = seq() if _n > `people2', from(`start1') to (100) block (1)

gen prac = min(_prac1, _prac2)
summ prac
assert `r(max)' == 72
distinct prac
assert `r(ndistinct)' == 72

drop _*


***randomly simulate true positives assuming an overall Positive Predictive Value of 0.8
*gen sim1=uniform()<0.8
local prop = runiform(0.7,0.9) 

gen sim1=binomial(1, 0.8)
summ sim1, d
x

**simple proportion in sample of 100 
proportion sim1, citype(exact) 

**accounting for random clustering by practice in sample of 100 
proportion sim1, vce(cluster prac) citype(exact) 

*random sample of 50
set seed 672597693
gen _random = runiform(0,1)
gen halfsample = 0
summ _random
sort _random
replace halfsample = 1 if _n <=50


**simple proportion in sample of 50
proportion sim1 if halfsample == 1, citype(exact) 
proportion sim1 if halfsample == 0, citype(exact) 



capture log close

