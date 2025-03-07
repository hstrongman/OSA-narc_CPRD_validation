
/*********************************************************
# Stata do file:    0.globals.do
#
# Author:      Helen Strongman
#
# Date:        01/08/2022
#
# Description: Globals for 22_001887_sleep-chronology project.
				Designed to allow study to be replicated for different 
				medical conditions using different filepaths
#
# Inspired and adapted from: 
# 				N/A
**********************************************************/

/*Set Stata version number*/
version 18

/**********************************************************
# STUDY SPECIFIC GLOBALS
**********************************************************/
***CPRD builds / linkage set
*SEE CPRD RELEASE NOTES ON THIS BUILD SAVED IN DOCS FOLDER
global buildyear "2023"
global buildmonth "09"
global buildmonthalph "SEP"
global cprdbuild 2023_09
global linkageset "22"

***Study start and end dates
*used in study population denominators up to weekly counts
global studystart_primary d(01/01/1990)
global studyend_primary d(30/04/2022)
global studystart_linked d(02/01/1998)
global studyend_linked d(29/03/2021) /*This is the end of HES APC /
ONS mortality data coverage (set 22/January 2022)*/

global studystart_hesop d(01/04/2003) /*(set 21/August 2021)*/
global studyend_hesop d(30/10/2020)


/**********************************************************
# STUDY CONVENTIONS
**********************************************************/

/*Abbreviations for file, variable names and locals
medcondition (narcolepsy, sleep_apnoea)
database (gold, aurum, hesapc)
filename suffix (`medcondition'_`database')
*/

/*formats
- format dates as %td
- use _prefix for temporary variables and datasets
*/


/**********************************************************
# ROUTE PATHS
**********************************************************/

/*file paths are used throughout. These follow LSHTM's license
agreement with CPRD. */

/*Raw and interim data - saved in extra secure data drive*/
*global rawdrivedir ""
global xsecuredrivedir ""
global xsecuredatadir "$xsecuredrivedir/xxx/xxx"
global xsecuredatadir_orig "$xsecuredrivedir/xxx/xxx/"

/*Analysis data and other files*/
*global maindir ""
global maindir ""
global ehrdir ""
global projectdir ""

/*CPRD monthly looksups folder*/
global cprddir ""

/**********************************************************
# PROJECT FOLDER FILEPATHS
**********************************************************/

global dodir "$projectdir/dofiles" /*Stata do files*/
global logdir "$projectdir/logfiles" /*Stata log files*/
global codedir "$projectdir/codelists/stata" /*Stata code lists - 
note code list do files are in the codelists subdirectory*/
global estimatesdir "$projectdir/estimates" /*raw estimates outputted from Stata
commands*/
global resultdir "$projectdir/results" /*aggregated table/graphs for manuscript 
or other outputs*/
global metadir "$projectdir/metadata" /*markdown output for Github*/


/*DATA FILES - Data type definitions are from CPRD multi-study license agreement*/ 
global datadir_raw "$xsecuredatadir/rawdata" /*data as provided by CPRD*/
global datadir_raw_orig "$xsecuredatadir_orig/rawdata"
global datadir_dm "$xsecuredatadir/managementdata" /*data management files - 
intermediate between `raw data' and `analysis data' - useful for data
management. May be required for additional analyses/validation requested*
by journal reviewers (subject to RDG approval)*/
global datadir_dm_orig "$xsecuredatadir_orig/managementdata" 
global datadir_an "$xsecuredatadir/analysisdata" /*analysis data*/


/**********************************************************
# CPRD DENOMINATOR FILES AND LOOK-UPS
**********************************************************/

/*CPRD provides denominator file and look-ups for each database build and
linkage set. These files are requested from CPRD by LSHTM's data managers.
Data specifications are available on CPRD's website.*/


/*DENOMINATOR FILES - this can be requested from CPRD by license holders.*/
local denomdir_aurum ""
global denom_aurum ""
global practice_aurum ""

local denomdir_gold ""
global denom_gold ""
global practice_gold ""

/*FILE IDENTYING PRACTICES THAT HAVE CONTRIBUTED TO BOTH GOLD AND AURUM*/
global visiontoemis ""

/*LINKAGE ELIGIBILITY FILE*/
local linkagesourcedir ""
global linkagefile_gold ""
global linkagefile_aurum ""

/*LOOK-UPS*/
global lookupdir_aurum ""
global lookupdir_gold ""
global dict_aurummed ""



