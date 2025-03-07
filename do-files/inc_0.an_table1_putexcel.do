/*******************************************************************************
# Stata do file:    inc_0.an_table1_putexcel.do
#
# Author:      Helen Strongman
#
# Date:        2019
#
# Description: Programme to create a typical table 1 for a matched cohort. This
#				programme is also used in the main study.
#
#				NB labels for binary variables not in bold text in this version
#				Plus added removing small cells for categorical and binary variables
#				 
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/



********* PROGRAM TO CREATE COVARIATES TABLE ***************************
* https://blog.stata.com/2013/09/25/export-tables-to-excel/ 

capture program drop HSputexcel

program HSputexcel
	args varname vardescription vartype startrow expgroups
	di "Variable: `varname'" 
	di "Variable description: `vardescription'"
	di "Variable type: `vartype'" 
	di "startrow: `startrow'"
	di "Number of exposure groups: `expgroups'"
	
	local expcols = `expgroups' * 2
	
	/*loop added to this version*/
	if "`vartype'" == "binary" {
		local font = ""
		}
		else {
			local font = "bold"
		}
		
	putexcel A`startrow' = "`vardescription'", `font'

	if "`vartype'" == "numeric" {
	
		local meanrow = `startrow' + 1
		local medianrow = `startrow' + 2

		putexcel A`meanrow' = "Mean (SD)", txtindent(3)
		putexcel A`medianrow' = "Median (IQR)", txtindent(3)
		
		local letterstring = substr("`c(ALPHA)'", 3, `expcols') /*2nd number should be 2 x number of exposure groups*/
		di "`letterstring'"

		local i = 0
		foreach col of local letterstring {
			summ `varname' if exposed == `i', d
			local meanstring=string(r(mean),"%6.1f") + " (" + string(r(sd),"%6.1f") + ")"
			sleep 2000
			local cell = "`col'" + "`meanrow'"
			putexcel `cell' = "`meanstring'", hcenter
			sleep 2000
			
			local medianstring=string(r(p50),"%6.1f") + " (" + string(r(p25),"%6.1f") + ", " + string(r(p75),"%6.1f") + ")"
			di "`medianstring'"
			sleep 2000
			local cell = "`col'" + "`medianrow'"
			putexcel `cell' = "`medianstring'", hcenter
			sleep 2000
			
			local i = `i' + 1
			}
			
		local row = `startrow' + 3
			
		} /*numeric*/
	
	if "`vartype'" == "categ" {
	
		**labels
		tab `varname' if exposed !=., matrow(names) m
		local row = `startrow' + 1
		local rows = rowsof(names)
		forvalues i = 1/`rows' {
			local val = names[`i',1]
			local val_lab : label (`varname') `val'
			putexcel A`row'=("`val_lab'"), txtindent(3)
			sleep 2000
			if "`val_lab'" == "." putexcel A`row'=("missing"), txtindent(3)
			sleep 2000
			local row = `row' + 1
			}
		
		**values
		local letterstring = substr("`c(ALPHA)'", 3, `expcols') /*2nd number should be 2 x number of exposure groups*/
		di "`letterstring'"

		
		tab `varname' exposed, matcell(freq) matcol(varvals) m
		qui summ `varname'
		local j = 1
		foreach col of local letterstring {	
			local row = `startrow' + 1
			count if exposed == varvals[1,`j']
			local denom = `r(N)'
			forvalues i = 1/`rows' {
				local freq_val = freq[`i',`j']
				if `freq_val' >=5 | `freq_val' == 0 {
					local freq_str = string(`freq_val', "%9.0fc")
					local percent_val = `freq_val'/`denom'*100
					local percent_str = string(`percent_val', "%6.1f")
					}
					else {
						local percent_val = 5/`denom'*100
						local freq_str = "<5"
						local percent_str = "<" + string(`percent_val', "%6.1f")
					}
				local catstring="`freq_str'" + " (`percent_str')"
				di "`catstring'"
				putexcel `col'`row'=("`catstring'"), hcenter
				sleep 2000
				local row = `row' + 1
				}
			local j = `j' + 1
			}
				
		} /*categ*/
		
	if "`vartype'" == "binary" {
		local letterstring = substr("`c(ALPHA)'", 3, `expcols') /*2nd number should be 2 x number of exposure groups*/
		di "`letterstring'"

		local i = 0
		foreach col of local letterstring {
			count if exposed == `i' & `varname' ! = . /*& `varname' ! = . added 02/09/2023)*/
			local denom = r(N)
			count if `varname' == 1 & exposed == `i'
			local freq_val = r(N)
			if `freq_val' >=5 | `freq_val' == 0 {
					local freq_str = string(`freq_val', "%9.0fc")
					local percent_val = `freq_val'/`denom'*100
					local percent_str = string(`percent_val', "%6.1f")
					}
					else {
						local percent_val = 5/`denom'*100
						local freq_str = "<5"
						local percent_str = "<" + string(`percent_val', "%6.1f")
					}
			local catstring="`freq_str'" + " (`percent_str')"
			di "`catstring'"
			putexcel `col'`startrow'=("`catstring'"), hcenter
			sleep 2000
			local i = `i' + 1
			}
		
		local row = `startrow' + 1
		}
		
	global startrow = `row'
	di $startrow

end

