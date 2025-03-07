
capture log close
log using "$logdir\53.cr_raw_matchedcohort_extract.txt", replace text

/*******************************************************************************
# Stata do file:    53.cr_raw_matchedcohort_extract.do
#
# Author:      Helen Strongman
#
# Date:        10/07/2023
#
# Description: 	(1) Check that all files and have been extracted from the CPRD online
#				tools
#				(2) Import all files, format dates, replace medcodeid and prodcodeids
#				with project codes, drop redundant snomed vars and save
#				individual files.
#
# Requirements: Extract primary care data for the matched cohort from CPRD's
#				on-line tools first
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off

***FIRST CHECK THAT ALL FILES HAVE BEEN EXTRACTED FROM THE ONLINE TOOLS

qui foreach medcondition in narcolepsy OSA {
qui foreach database in aurum gold {
qui foreach linkedtext in linked primary {

if "`medcondition'" == "OSA" & "`linkedtext'" == "primary" continue
	
local foldername = "$datadir_raw/`medcondition'_`database'_`linkedtext'"

noi di "`foldername'"

/**import globals file that comes with the extract and denotes the number of
extracted files for each file type**/
import delimited using "`foldername'/globals.log", delimiter(" " tab) clear
drop v1 v3
rename v2 filetype
rename v4 filetotal
tempfile tempglobals
save `tempglobals', replace

/**create a local containing the name of each file type**/
levelsof filetype, local(filetypelist)

foreach filetype of local filetypelist {
	/*create a local containing the total number of files extracted by the tool*/
	use `tempglobals', clear
	summ filetotal if filetype == "`filetype'"
	local filetotal = `r(max)'
	/*create a local to list missing files*/
	local missingfiles = ""
	/*create a local listing all Extract files for the filetype*/
	local myfiles: dir "`foldername'/" files "*`filetype'*.txt", respectcase
	/*assign 1st macro (file name) in local as `1'*/
	tokenize `"`myfiles'"'
	/*start loop at i=1*/
	local i=1
	while "`1'" !="" {
		di "`1'"
		/*create a local with the file number*/
		local pos = strpos("`1'", "_0") + 1
		local nostr = substr("`1'", `pos', 3)
		local nonum = `nostr' * 1
		/*check that the file number is sequential to the previous number*/
		if `nonum' != `i' {
			*if not add missing file number to missing files local
			*next loop checks tht the current file in the next number in the sequence
			local missingfiles = "`missingfiles' `i'"
			local i=`i'+1
		}
		else {
			*if sequential, move to next sequentital number and next file
			local i=`i'+1
			mac shift
		}
	}
	*check that the final file number matches the total number of expected files
	noisily display  "Missing `filetype' files: `missingfiles'"
	capture assert `nonum' == `filetotal'
	if _rc != 0 di "The final file number does not matched the expected total"
	pause
}

}
}
}

***NEXT IMPORT AND FORMAT FILES
*ONLY THINGS THAT SAVE SPACE
*INCLUDING PROJECT SPECIFIC MEDICAL/PRODUCT CODES
*DATE VARIABLES
*REMOVE EXCESS VARS

qui foreach medcondition in narcolepsy OSA {
qui foreach database in gold aurum {
qui foreach linkedtext in linked primary {

if "`medcondition'" == "OSA" & "`linkedtext'" == "primary" continue
	
local foldername = "$datadir_raw/`medcondition'_`database'_`linkedtext'"

noi di "`foldername'"

/**import globals file that comes with the extract and denotes the number of
extracted files for each file type**/
import delimited using "`foldername'/globals.log", delimiter(" " tab) clear
drop v1 v3
rename v2 filetype
rename v4 filetotal
tempfile tempglobals
save `tempglobals', replace

/**create a local containing the name of each file type**/
levelsof filetype, local(filetypelist)

qui foreach filetype of local filetypelist {
	/*create a local listing all Extract files for the filetype*/
	local myfiles: dir "`foldername'/" files "*`filetype'*.txt", respectcase
	/*assign 1st macro (file name) in local as `1'*/
	tokenize `"`myfiles'"'
	/*start loop at i=1*/
	local i=1
	while "`1'" !="" {
		noi di "`1'"
		*import file
		import delimited using "`foldername'/`1'", ///
		varnames(1) case(lower) stringcols(_all) clear
		*format date variables
		capture describe *date*, varlist
		if _rc == 0 {
		local datevarlist = "`r(varlist)'"
		di "`datevarlist'"
		foreach var of local datevarlist {
			di "`var'"
			gen tempdate = date("`var'", "DMY")
			format tempdate %td
			drop `var'
			if "`var'" == "eventdate" | "`var'" == "obsdate" {
				rename tempdate evdate
				}
				else {
					rename tempdate `var'
				}
		} /*dates*/
		} /*confirm dates*/
		*drop lengthy snomed variables
		capture drop sct* /*lengthy snomed variables*/
		

		*replace Aurum medcodeids and prodcodeids with project codes
		if "`database'" == "aurum" {
			capture confirm var medcodeid
			if _rc == 0 {
				merge m:1 medcodeid using "$codedir/medcodeid_projectmedcode_lookup.dta", keep(1 3) keepusing(projectmedcode) nogen
				drop medcodeid
			}
			capture confirm var prodcodeid
			if _rc == 0 {
				merge m:1 prodcodeid using "$codedir/prodcodeid_projectprodcode_lookup.dta", keep(1 3) keepusing(projectprodcode) nogen
				drop prodcodeid
			}
		} /*aurum codes*/
		
		*change all variables to numeric, where possible
		describe, varlist
		local varlist = "`r(varlist)'"
		foreach var of local varlist {
			if "`var'" == "consmedcodeid" continue /*added - 22/03/2024*/
			capture destring `var', replace
		}
		
		*lookups
		/*note - decided not to sort out lookups because this will not reduce
		the size of the files*/
		
		local filename = subinstr("`1'", ".txt", ".dta", 1)
		compress
		save "`foldername'/`filename'", replace
		
		local i=`i'+1
		mac shift
	} /*individual file*/
} /*filetype*/

}
}
}
	
capture log close