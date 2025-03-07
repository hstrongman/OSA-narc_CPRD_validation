X THIS IS HERE TO STOP ME ACCIDENTALLY RUNNING THE FULL DO FILE


/*********************************************************
# Stata do file:    0.master.do
#
# Author:      Helen Strongman
#
# Date:        08/11/2023
#
# Description: All do files for 22_001887_validation project
#
# Do file prefixes: x.cr_raw (imports and saves raw data file)
#					x.cr_dm (creates interim/data management file)
#					x.cr_a (creates analysis file)
#					x.an (runs analysis)	
#					
#					where x is sequential from 1
#					inclusion files that are unique to the do file have the 
#					same prefix preceded by "inc_"
#					inclusion files that are used in multiple do files are
#					prefixed by inc_0.
#
# Inspired and adapted from: 
# 				N/A
**********************************************************/

/*THE FOLLOWING STATA USER-WRITTEN PACKAGES/COMMANDS ARE USED IN ONE
OR MORE DO-FILES AND NEED TO BE DOWNLOADED
distinct (used in multiple do files)
mipolate/stripolate (first used in 2.cr_a_minimum-baseline-period)
flowchart (see 14.an_flowchart_full.do)
distrate (first used in 18.an_prevalence_estimates.do)
grc1leg (first used in 29.an_prevalence_graphs.do)
*/

/*NOTE ON PATIENT IDENTIFIERS.
CPRD advise importing large numeric identifiers as strings to avoid formatting
issues when denominators are imported into software such as Excel and Stata. 
For this project, string versions of patid are used until the end of 
4.cr_dm_all_registered_patients when they are converted to numeric versions.
String patids are then sent to CPRD.

I used the following code to check that this would not cause any problems:
use "$denom_`database'", clear
destring patid, gen(patid_num)
tostring patid_num, gen(patid_str) format(%20.0g)
assert patid == patid_str
*/

/*NOTE ON CODE IDENTIFIERS
Raw CPRD date includes long medcodeids and prodcode ids that must be imported
as strings, taking up lots of space and processing time. I have replaced
these with project specific numeric ids when importing data. This step was
not applied to the study population files (see codelists folder)*/

/**********************************************************
# GLOBALS AND SET UP DO FILES
**********************************************************/
do "$dodir\0.globals.do" /*run this file at the beginning of each session*/
do "$dodir\0.cr_do_aurumlabels.do" /*creates labels from aurum lookups and saves*
as do files*/
do "$dodir\0.cr_do_categorylabels.do" /*creates category labels from code list 
files and saves as do files - needed for 2.cr_raw_hesapcicd10files.do */
do "$dodir\0.markdown_setup.do" /*settings and instructions to format HTML output*/


/**********************************************************
# RERUN DO FILES FROM MAIN STUDY ON LATEST CPRD BUILD
# do files with an a next to the number have been adapted
# do files with an n next to the number are new
**********************************************************/
/*EXTRACT DATA NEEDED TO DEFINE STUDY POPULATION
You will need:
1. the denominator files listed in globals.do
2. codelists for the medical condition (see codelists folder)
3. to extract files from CPRD's Define tool that include the patient identifer,
	medical code and event data for ALL events in the CPRD database matching
	the code list.
4. to request linked HES APC data (patid, icd 10 code, event date) from CPRD for primary
	and secondary codes matching the code list.
5. to request ONS mortality data (patid, date of death) for all linked records.
*/

do "$dodir\1.cr_raw_cprddefinefiles.do" /*add counts from define logs before running*/
do "$dodir\2.cr_raw_hesapcicd10files.do"
do "$dodir\3.cr_raw_onsmortalitydodfiles.do"

do "$dodir\4.cr_dm_all_registered_patients.do"
/*DEFINE STUDY POPULATION AND COHORT*/
/*Define minimum baseline period by visually inspected sleep disorder incidence
rates in the months following registration at the practice*/
do "$dodir\5.cr_an_minimum_baseline_period_stsplit.do" /*prepare data*/
do "$dodir\6.an_minimum_baseline_period_estimates.do" /*generate estimates*/
do "$dodir\7.an_minimum_baseline_period_table.do" /*combine estimates in a table*/

copy "$dodir\8.an_minimum_baseline_period_figures.txt" ., replace
dyndoc "$dodir\8.an_minimum_baseline_period_figures.txt", ///
saving("8.an_minimum_baseline_period_figures.html") replace

/*DEFINE STUDY POPULATION AND COHORT*/

/*DON'T RERUN FOR VALIDATION STUDY - 
/*Define minimum baseline period by visually inspected sleep disorder incidence
rates in the months following registration at the practice*/
do "$dodir\5.cr_an_minimum_baseline_period_stsplit.do" /*prepare data*/
do "$dodir\6.an_minimum_baseline_period_estimates.do" /*generate estimates*/
do "$dodir\7.an_minimum_baseline_period_table.do" /*combine estimates in a table*/

copy "$dodir\8.an_minimum_baseline_period_figures.txt" ., replace
dyndoc "$dodir\8.an_minimum_baseline_period_figures.txt", ///
saving("8.an_minimum_baseline_period_figures.html") replace
*/

/*Define study population and unmatched cohort + export numbers for flow chart*/


do "$dodir/9.cr_studypopulation_an_flowchart.do"
do "$dodir/10.cr_incidentcohort_an_flowchart.do" - ideally remove from here but can't repeat this part at this stage
do "$dodir/10a.an_validationcohort_checks.do"
do "$dodir/11.cr_validationcohort_an_flowchart.do" /*see also 11a...do below - doesn't create a dataset (wrong prefix)*/
do "$dodir/11a.an_validationcohort_flowchart.do"
do "$dodir/23.cr_dm_validationstudy_patlists.do"
do "$dodir/23a.cr_dm_validationstudy_patlists_aurumextract.do" /*should have done
this when the population was defined (see notes in do file)*/


/*import CPRD Aurum data and create file with covariates (see do files that
 import raw CPRD data, 25/26 for ethnicity, 29/30 for BMI and 37 for other covariates)*/

do "$dodir/53.cr_raw_matchedcohort_extract.do"
do "$dodir/25a.cr_raw_ethnicity_drefine.do"
do "$dodir/26.cr_temp_ethnicity_primarycare.do" 
do "$dodir/29a.cr_raw_bmi_drefine.do"
do "$dodir/30.cr_bmi_datamanagement.do"


do "$dodir/31n.cr_problemfile.do" /*new do file to extract data from problem file - decided not to go ahead with this - see do file*/
do "$dodir/32n.cr_referralfile_aurum.do" /*new do file -decided not to go ahead with this - see do file*/
do "$dodir/33n.cr_edsdrugs_aurum.do" /*new do file - Excessive daytime sleepiness drugs used to treat narcolepsy in 1st/2nd line*/
do "$dodir/56a.cr_an_matchedcohort_hesop" /*substantially adapted do file - identifies OP records within 6 months of index*/


do "$dodir/37a.cr_unmatchedcohort_stsplit_allvars.do" /*adds stratification
vars from incidence/prevalence study and extras!*/




/**********************************************************
# VALIDATION STUDY SPECIFIC DO FILES
**********************************************************/

do "$dodir/v1.an_sample_size_clusters.do"
do "$dodir/v2.cr_formatted_validation_data.do"
do "$dodir/v3.an_validation_data_table.do"
do "$dodir/v4.an_flowchart_validationstudy.do" /*restructured version of flowchart to include practice numbers and add completed questionnaire counts*/
do "$dodir/v5.cr_raw_validation_extract.do" /*import all raw data for validation study - this is adapted from do file 53 from main study*/

do "$dodir/v6.an_table1.do" /*characteristics of sample - main = full incident sample vs validation sample*/ 
do "$dodir/v7.cr_validationcohort_allvars.do" 
do "$dodir/v8.an_compare_true_vs_false.do"
do "$dodir/v9.an_validation_data_table_bydef.do" /*validation data table for different definitions*/ 
do "$dodir/v10.an_ppv_estimates.do" /* "PPV" and "sensitivity" estimates - overall*/
do "$dodir/v11.an_ppv_sens_graph.do" /*main graph with "PPV", "sensitivity" and time difference estimates*/
do "$dodir/v12.an_ppv_stratification_ratios.do" /*PPV ratios for stratification covars*/
do "$dodir/v13.an_ppv_ratios_processout.do" /*add PPV ratios to table*/





