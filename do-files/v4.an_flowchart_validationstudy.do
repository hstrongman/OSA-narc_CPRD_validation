capture log close
log using "$logdir\v4.an_flowchart_validationstudy.txt", replace text

/*******************************************************************************
# Stata do file:    v4.an_flowchart_validationstudy
#
# Author:      Helen Strongman
#
# Date:       08/07/2024
#
# Description: 	This do file creates a CONSORT style flow chart for the validation
#				cohort
#
# Requirements: Latex editor - Overleaf free version
#				https://github.com/IsaacDodd/flowchart/blob/master/flowchart_example1.do
#
# Inspired and adapted from: 
#				This do file uses the PGF/TikZ package
# 				Author  : Morten Vejs Willert (July 2010)
# 				License : Creative Commons attribution license
*******************************************************************************/

/**** FLOWCHART COMMAND SETUP *********************/
*net get flowchart
*flowchart setup, update
flowchart getstarted

/*** SPECIFY COHORTS FOR FLOWCHARTS ***************/
/*options are:
- primary combined (largest study population)
- linked combined (more complete data, minimal difference between cohorts for
each analysis)
- linked aurum only (might not be v different to linked combined)
*/


	/**** DISPOSITION SUBANALYSIS: ********************/
				
	/***flowchart labels, numbers and boxes for study population*/
	use "$resultdir/9.cr_studypopulation_an_flowchart.dta", clear

	*people in CPRD build
	local row1incname: label criterialab 1
	local row1incno = aurumlinked[1]

	*exclusions to create study population
	local datarow = 2
	local excno = 1
	local row1exctot = 0
	while `excno' <=8 {
		*if `excno' == 4 & "linked" == "primary" continue
		local row1excname`excno': label criterialab `datarow'
		local row1excno`excno' = aurumlinked[`datarow']
		di `row1excno1'
		local row1exctot = `row1exctot' + `row1excno`excno''
		local datarow = `datarow' + 1
		local excno = `excno' + 1
	}

	
	*study population box
	local row2incname: label criterialab `datarow'
	local row2incno = aurumlinked[`datarow']

	di `row1exctot'
	pause


	/***flowchart labels, numbers and boxes for incident cohort*/
	use "$resultdir/10.cr_incidentcohort_an_flowchart.dta", clear
	
	*split into OSA and narcolepsy
	
	*row 3 left: >= 1 code record of OSA, right >=1 coded record of narcolepsy
	local row = 3
	local criteriano = 3
	local inclusion = 1
	include "$dodir/inc_v4.an_flowchart_simplerow.do"
	

	*row 4: exclusions for incident cohort, left = OSA< right = narcolepsy
	*NB combines exclusions for prevalent and incident cohort
	
	
	foreach medcondition in OSA narcolepsy {
		local excrows = 6 /*number of exclusion rows + extra for prevalent cases*/
		if "`medcondition'" == "OSA" local col = "left"
		if "`medcondition'" == "narcolepsy" local col = "right"
		local row4`col'excname "Excluded"
		local datarow = 4 /*row of first exclusion in data*/
		local excno = 1
		local row4`col'exctot = 0
			while `excno' <=`excrows' {
				if `datarow' == 9 | `datarow' == 6 { /*skips row for prevalent cases and irrelevent criteria for validation study*/
					local datarow = `datarow' + 1
				}
				else { 
					noi di "`col'" `excno' `datarow'
					local row4`col'excname`excno': label criterialab `datarow'
					noi di aurumlinked`medcondition'[`datarow']
					local row4`col'excno`excno' = aurumlinked`medcondition'[`datarow']
					noi di `row4`col'exctot' + `row4`col'excno`excno''
					local row4`col'exctot = `row4`col'exctot' + `row4`col'excno`excno''
					local datarow = `datarow' + 1
					local excno = `excno' + 1
				}
			}
	}

	/*rows not applicable to narcolepsy*/
	forvalues excno = 3/4 {
		local row4rightexcno`excno' = "NA"
	}

	
	
	/*row 5: left = OSA incident analysis group, right = narcolepsy incident group*/
	use "$resultdir\11a.cr_validationcohort_an_flowchart.dta", clear
	
	foreach medcondition in OSA narcolepsy {
		local excrows = 2 /*copying exclusion method to count patients and practices*/
		if "`medcondition'" == "OSA" local col = "left"
		if "`medcondition'" == "narcolepsy" local col = "right"
		local row5`col'excname "Incident `medcondition' cohort"
		local datarow = 2 /*row of first patient count in data*/
		local excno = 1
		*local row4`col'exctot = 0
			while `excno' <=`excrows' {
				local row5`col'excname`excno': label criterialab `datarow'
				local row5`col'excno`excno' = aurumlinked`medcondition'[`datarow']
				*local row5`col'exctot = `row4`col'exctot' + `row4`col'excno`excno''
				local datarow = `datarow' + 1
				local excno = `excno' + 1
				}
	}
	

	
	
	*row 6: exclusions for to create recruitment sample, left = OSA< right = narcolepsy
	*NB combines exclusions for prevalent and incident cohort
	
	foreach medcondition in OSA narcolepsy {
		local excrows = 3 /*number of exclusion rows*/
		if "`medcondition'" == "OSA" local col = "left"
		if "`medcondition'" == "narcolepsy" local col = "right"
		local row6`col'excname "Exclusions"
		local datarow = 5 /*row of first exclusion in data*/
		local excno = 1
		local row6`col'exctot = 0
		while `excno' <=`excrows' {
			local row6`col'excname`excno': label criterialab `datarow'
			local row6`col'excno`excno' = aurumlinked`medcondition'[`datarow']
			local row6`col'exctot = `row6`col'exctot' + `row6`col'excno`excno''
			local datarow = `datarow' + 1
			local excno = `excno' + 1
			}
				
		*deal with small numbers by adding exclusions to row above
		if `row6`col'excno2' < 5 {
			local row6`col'excno1 = `row6`col'excno1' + `row6`col'excno2'
			local row6`col'excno2 = "$<$5"
			local row6`col'excname1 = "`row6`col'excname1'" + "*"
			/* * = to avoid reporting small numbers, the exclusions in the next
			row are included in this figure*/
		}
		
	}
	
	/*row 7: left = OSA recruitment sample, right = narcolepsy recruitment sample*/
	
	foreach medcondition in OSA narcolepsy {
		local excrows = 2 /*copying exclusion method to count patients and practices*/
		if "`medcondition'" == "OSA" local col = "left"
		if "`medcondition'" == "narcolepsy" local col = "right"
		local row7`col'excname "Recruitment sample"
		local datarow = 9 /*row of patient count in data*/
		local excno = 1
		*local row4`col'exctot = 0
			while `excno' <=`excrows' {
				local row7`col'excname`excno': label criterialab `datarow'
				local row7`col'excno`excno' = aurumlinked`medcondition'[`datarow']
				*local row5`col'exctot = `row4`col'exctot' + `row4`col'excno`excno''
				local datarow = `datarow' + 1
				local excno = `excno' + 1
				}
	}
	
	/*row 8: left = OSA validation sample, right = narcolepsy validation sample*/
	
	
	foreach medcondition in OSA narcolepsy {
		local excrows = 2 /*copying exclusion method to count patients and practices*/
		if "`medcondition'" == "OSA" local col = "left"
		if "`medcondition'" == "narcolepsy" local col = "right"
		local row8`col'excname "Questionnaires completed (validation sample)"
		local datarow = 12 /*row of first exclusion in data*/
		local excno = 1
		*local row4`col'exctot = 0
			while `excno' <=`excrows' {
				local row8`col'excname`excno': label criterialab `datarow'
				local row8`col'excno`excno' = aurumlinked`medcondition'[`datarow']
				*local row5`col'exctot = `row4`col'exctot' + `row4`col'excno`excno''
				local datarow = `datarow' + 1
				local excno = `excno' + 1
				}
	}

	
	/**** DIAGRAM:  **************************************/
	* Run this code to produce a similar flowchart to M. Willert's CONSORT-style 
	*   flowchart: http://www.texample.net/tikz/examples/consort-flowchart/
	* It should resemble that flowchart.

	* Initiate a flowchart by specifying the subanalysis data file to write: 


	*flowchart init using "$resultdir/methods--figure-flowchart.data"
	flowchart init using "$resultdir/v4.an_flowchart_validationstudy.data"


	* Format: flowchart writerow(rowname): [center-block triplet lines] , [left-block triplet lines]
	*   Triplet Format: "variable_name" n= "Descriptive text."

	flowchart writerow(row1): ///
		"row1start" `row1incno' "`row1incname'", ///
		"row1exc" `row1exctot' "Excluded" ///
			"row1ex1" `row1excno1' "`row1excname1'" ///
			"row1ex2" `row1excno2' "`row1excname2'" ///
			"row1ex3" `row1excno3' "`row1excname3'" ///
			"row1ex4" `row1excno4' "`row1excname4'" ///
			"row1ex5" `row1excno5' "`row1excname5'" ///
			"row1ex6" `row1excno6' "`row1excname6'" ///
			"row1ex7" `row1excno7' "`row1excname7'" ///
			"row1ex8" `row1excno8' "`row1excname8'" 

	flowchart writerow(row2): "row2" `row2incno' "`row2incname'", flowchart_blank // Box with total study population


	flowchart writerow(row3): /// split OSA and narcolepsy
		"row3left" `row3leftno' "`row3leftname'", ///
		"row3right" `row3rightno' "`row3rightname'"
	

	flowchart writerow(row4): /// Exclusions to create incident cohort
		"row4leftexc" `row4leftexctot' "`row4leftexcname'" ///
			"row4leftexc1" `row4leftexcno1' "`row4leftexcname1'" ///
			"row4leftexc2" `row4leftexcno2' "`row4leftexcname2'" ///
			"row4leftexc3" `row4leftexcno3' "`row4leftexcname3'" ///
			"row4leftexc4" `row4leftexcno4' "`row4leftexcname4'" ///
			"row4leftexc5" `row4leftexcno5' "`row4leftexcname5'" ///
			"row4leftexc6" `row4leftexcno6' "`row4leftexcname6'", ///
		"row4rightexctot" `row4rightexctot' "`row4rightexcname'" ///
			"row4rightexc1" `row4rightexcno1' "`row4rightexcname1'" ///
			 "row4rightexc2" `row4rightexcno2' "`row4rightexcname2'" ///
			 "row4rightexc3" `row4rightexcno3' "`row4rightexcname3'" ///
			 "row4rightexc4" `row4rightexcno4' "`row4rightexcname4'" ///
			 "row4rightexc5" `row4rightexcno5' "`row4rightexcname5'" ///
			 "row4rightexc7" `row4rightexcno6' "`row4rightexcname6'"
			 
	flowchart writerow(row5): /// incident sample
		"row5leftexc1" `row5leftexcno1' "`row5leftexcname': \\ \h `row5leftexcname1'" ///
			"row5leftexc2" `row5leftexcno2' "`row5leftexcname2'", ///
		"row5rightexc1" `row5rightexcno1' "`row5rightexcname': \\ \h `row5rightexcname1'" ///
			"row5rightexc2" `row5rightexcno2' "`row5rightexcname2'" 
	
	flowchart writerow(row6): /// Exclusions to create recruitment sample
		"row6leftexc" `row6leftexctot' "`row6leftexcname'" ///
			"row6leftexc1" `row6leftexcno1' "`row6leftexcname1'" ///
			"row6leftexc2" "`row6leftexcno2'" "`row6leftexcname2'" ///
			"row6leftexc3" `row6leftexcno3' "`row6leftexcname3'", ///
		"row6rightexctot" `row6rightexctot' "`row6rightexcname'" ///
			"row6rightexc1" `row6rightexcno1' "`row6rightexcname1'" ///
			 "row6rightexc2" `row6rightexcno2' "`row6rightexcname2'" ///
			 "row6rightexc3" `row6rightexcno3' "`row6rightexcname3'"
	
	flowchart writerow(row7): /// incident sample
		"row7leftexc1" `row7leftexcno1' "`row7leftexcname': \\ \h `row7leftexcname1'" ///
			"row7leftexc2" `row7leftexcno2' "`row7leftexcname2'", ///
		"row7rightexc1" `row7rightexcno1' "`row7rightexcname': \\ \h `row7rightexcname1'" ///
			"row7rightexc2" `row7rightexcno2' "`row7rightexcname2'" 
			
	flowchart writerow(row8): /// incident sample
		"row8leftexc1" `row8leftexcno1' "`row8leftexcname': \\ \h `row8leftexcname1'" ///
			"row8leftexc2" `row8leftexcno2' "`row8leftexcname2'", ///
		"row8rightexc1" `row8rightexcno1' "`row8rightexcname': \\ \h `row8rightexcname1'" ///
			"row8rightexc2" `row8rightexcno2' "`row8rightexcname2'" 
		
	*/

	* Format: rowname_blockorientation rowname_blockorientation
	* This command connects the blocks with arrows by their assigned orientation. 
	*   Use rowname_center for the center-block (first block of triplets), which will appear on the left of the diagram.
	*   Use rowname_left for the left-block (second blow of triplets), which will appear on the right of the diagram.


	flowchart connect row1_center row1_left
	
	flowchart connect row1_center row2_center
	
	
	flowchart connect row2_center row3_center
	flowchart connect row2_center row3_left, arrow(angled)
	
	local penrow = 7 /*penultimate row*/
	local row = 3
	while `row' <= `penrow' {
		local nextrow = `row' + 1
		flowchart connect row`row'_center row`nextrow'_center
		flowchart connect row`row'_left row`nextrow'_left
		local row = `nextrow'
		}

		
	*flowchart finalize, template("$metadir/14.an_flowchart_full.tex") output("$resultdir/14.an_flowchart_full.tikz")

	flowchart finalize, template("$dodir/v4.an_flowchart_validationstudy.texdoc") output("$resultdir/v4.an_flowchart_validationstudy.tikz")
	pause




* Now, using LaTeX, compile the manuscript.tex file -- This file is already setup to tie all of these files together.
* REMEMBER TO 
* (1) FIND "DOLSIGN" IN TIKZ FILE AND REPLACE WITH "$" 
* (2) FIND "sleep disorder" IN TIKZ FILE AND REPLACE WITH "OSA" or "narcolepsy"
* (3) Specify narcolepsy or OSA in 3 places in the tex file 
*   This file shows you how you would use \input{} to include the new .tikz file as a figure diagram into a 'figure' tex LaTeX document.
*   The preamble in the ancillary manuscript file is a guide on which packages and commands to include in your LaTeX setup.

* THEN RECOMPILE MANUSCRIPT.TEX

/*uploaded files from results file and working directory to overleaf project. compiled manuscript.tex*/

