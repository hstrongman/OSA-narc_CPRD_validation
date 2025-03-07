
capture log close
log using "$logdir\v11.an_ppv_sens_graph.txt", replace text

/*******************************************************************************
# Stata do file:    4v11.an_ppv_sens_graph.do
#
# Author:      Helen Strongman
#
# Date:        24/10/2024
#
# Description: 	Forest plots of "PPVs" and "Internal sensivities"
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off




foreach medcondition in OSA narcolepsy {
*foreach est in ppv sens {
	
	
	*** create dataset with time between index and diagnosis date variables for each definition
	import excel using "$resultdir\v9.an_validation_data_table_bydef.xlsx", sheet("`medcondition'") clear
	rename A varname
	keep if varname == "Median (IQR)" | strmatch(varname, "*within 6 months*")
	*Days between the index and diagnosis date (positive = index later)
	
	
	*there are separate rows for each definition in the Excel file
	*reformat dataset to have two rows, one for median and one for within 6 months vars
	describe, varlist
	local varlist = "`r(varlist)'"
	di "`varlist'"
	
	local i = 1
	foreach var of local varlist {
		if "`var'" == "varname" continue
		replace `var' = "" if `var' == ". (., .)" | `var' == "0 (.)"
		replace `var' = `var'[`i'] in 1
		local i = `i' + 1
		replace `var' = `var'[`i'] in 2
		local i = `i' + 1
	}
	keep if B !=""
	replace varname = "mediantime" in 1
	replace varname = "within6" in 2
	
	*transpose so that rows = definitions and columns = median and within6 vars
	*xpose command doesn't work with strings so here goes ...
	capture postclose results
	tempname memhold
	tempfile results
	
	postfile `memhold' int def str20 mediantime str15 within6 using "`results'", replace
	
	if "`medcondition'" == "OSA" local maxdef = 4
	if "`medcondition'" == "narcolepsy" local maxdef = 6
	forvalues def = 0/`maxdef' {
		local y = `def' + 2
		local column : word `y' of `c(ALPHA)'
		noi di "column `column'"
		levelsof `column' if varname == "mediantime", local(median)
		levelsof `column' if varname == "within6", local(within6)
		post `memhold' (`def') (`median') (`within6') 
	}
	
	postclose `memhold'
	use `results', clear
	
	label variable mediantime "Days between recorded and confirmed diagnosis date (positive = recorded later)"
	label variable within6 "Diagnosis recorded within +/- 6 months of confirmed diagnosis date"
	
	label define deflab ///
	0 "Primary (CPRD or HES APC)" ///
	1 "CPRD" ///
	2 "CPRD & HES APC" ///
	3 "Original with OP visit to sleep-related specialty" ///
	4 "CPRD with OP visit to sleep-related specialty"
	
	if "`medcondition'" == "narcolepsy" {
		label define deflab ///
		5 "Original with EDS drug prescription" ///
		6 "CPRD with EDS drug prescription", add
	}
	label values def deflab
	
	
	*** merge with PPV ans sens estimates
	
	merge 1:m def using "$estimatesdir/v10.an_ppv_estimates.dta"
	
	
	/*if "`est'" == "ppv" {
		local estlong "% cases confirmed (`medcondition')"
		local estshort = "% cases confirmed"
	}
	
	if "`est'" == "sens" {
		local estlong "% confirmed cases retained (`medcondition')"
		local estshort "% cases retained"
	}*/
	
	keep if medcondition == "`medcondition'"
	
	*gen estimate labels
	*decode def, gen(estlab)
	
	gen sens_st = .
	gen sens_st_lci = .
	gen sens_st_uci = .
	gen sens_st_str = ""
	
	*need ppv and sens estimates to be separate rows
	expand 2, gen(_expand)

	gen est = "ppv" if _expand == 0
	replace est = "sens" if _expand == 1
	drop _expand
	
	
	foreach suffix in crude crude_lci crude_uci st st_lci st_uci  {
		gen `suffix' = .
		foreach est in ppv sens {
		replace `suffix' = `est'_`suffix' if est == "`est'"
		drop `est'_`suffix'
	}
	}

	

	foreach model in crude st {
		gen `model'_str = ppv_`model'_str if est == "ppv"
		replace `model'_str = sens_`model'_str if est == "sens"
		drop ppv_`model'_str
		drop sens_`model'_str
	}
		
	replace st_str = "" if st_str == ". (.-.)"
	keep def est crude crude_lci crude_uci crude_str st st_lci st_uci st_str mediantime within6
	
	/*gsort -def
	gen obs = _n*/
	
	/*number observations with one gap between definitions to represent separator 
	row and covariate label row in graphs*/
	gsort -def -est
	gen obs = _n
	expand 2 if est == "ppv", gen(expand)
		
	qui describe, varlist
	local varlist = "`r(varlist)'"
	di "`varlist'"
	foreach var of local varlist {
			if "`var'" == "def" continue
			if "`var'" == "obs" continue
			if "`var'" == "expand" continue
		capture confirm numeric variable `var'
		if !_rc replace `var' = . if expand == 1
		capture confirm string variable `var'
		capture replace `var' = "" if expand == 1
		}
	replace obs = obs + 0.1 if expand == 1
	sort obs
	replace obs = _n
	
	/*split definition labels across 2 rows*/
	label define deflab 3 "Original with specific OP visit", modify
	label define deflab 4 "CPRD with specific OP visit", modify

	/*graph column and axis headings*/
	count
	insobs 2, after(r(N))
	qui summ obs
	global headingobs = r(max) + 2
	global subheadingobs = r(max) + 1
	sort obs
	replace obs = _n
	di $headingobs
	replace obs=$headingobs if obs==. & _n==_N 
	gen estheading = "% (95% CI)" if obs == $headingobs
	gen defheading = "Sleep disorder definition" if obs == $headingobs
	gen timeheading = "Median time lag (days)" if obs == $headingobs
	
	di $subheadingobs
	replace timeheading = "n (%) within 6 months" if obs ==  $subheadingobs
	
	*replace obs=$subheadingobs if obs==. & _n==_N-1
	*/

	*gen estheading ="{bf:`estshort' (95% CI)}" if obs==$headingobs
	*gen pheading = "{bf:p-value}" if obs==$headingobs

	gen estlabpos = 150 /*location of estimates*/
	gen deflabpos = -60 /*location of variable labels*/
		*gen valuelabpos = 0.065 /*local of value labels*/
	gen timelabpos = 200

		
	if  "`medcondition'" == "OSA" {
		local titleletter "A"
	}
	if  "`medcondition'" == "narcolepsy" local titleletter "B"
		
		*include "$dodir/inc_0.figurecolours.do"
		
		qui summ obs
		local yscalemax = `r(max)'
		
		local xmin = 0
	
		/*******************************************************************************
		#draw graph
		*******************************************************************************/
		
		set scheme stcolor
		
		graph twoway ///
		/// % and cis (crude PPV)
		|| scatter obs crude if st == . & est == "ppv", msymbol(circle) msize(small) mcolor(black) /// data points 
		|| rcap crude_lci crude_uci obs if st == . & est == "ppv", horizontal lw(vthin) color(black) msize(vtiny) /// add the CIs	
		/// % and cis (standardised PPV)
		|| scatter obs st if st != . & est == "ppv", msymbol(square) msize(small) mcolor(black) /// data points 
		|| rcap st_lci st_uci obs if st != . & est == "ppv", horizontal lw(vthin) color(black) msize(vtiny) /// add the CIs	
		/// % and cis (crude sens)
		|| scatter obs crude if st == . & est == "sens", msymbol(circle_hollow) msize(small) mcolor(black) /// data points 
		|| rcap crude_lci crude_uci obs if st == . & est == "sens", horizontal lw(vthin) color(black) msize(vtiny) /// add the CIs			
		/// add results labels
		|| scatter obs estlabpos if st == ., m(i) mlab(crude_str) mlabcol(black) mlabsize(9pt) mlabposition(9)  ///
		|| scatter obs estlabpos if st != ., m(i) mlab(st_str) mlabcol(black) mlabsize(9pt) mlabposition(9)  ///
		/// add time difference variables
		|| scatter obs timelabpos if est == "ppv", m(i) mlab(mediantime) mlabcol(black) mlabsize(9pt) mlabposition(9)  ///
		|| scatter obs timelabpos if est == "sens", m(i) mlab(within6) mlabcol(black) mlabsize(9pt) mlabposition(9)  ///
		/// The definition labels (only for ppv)
		|| scatter obs deflabpos if est == "ppv", m(i) mlab(def) mlabcol(black) mlabsize(9pt) ///
		/// Headings for estimate labels and results
		|| scatter obs timelabpos if obs==$headingobs, m(i) mlab(timeheading) mlabcol(black) mlabsize(9pt) mlabpos(9) ///
		|| scatter obs timelabpos if obs==$subheadingobs, m(i) mlab(timeheading) mlabcol(black) mlabsize(9pt) mlabpos(9) ///
		|| scatter obs estlabpos if obs==$headingobs, m(i) mlab(estheading) mlabcol(black) mlabsize(9pt) mlabpos(9) ///
		|| scatter obs deflabpos if obs==$headingobs, m(i) mlab(defheading) mlabcol(black) mlabsize(9pt) ///
		/// graph options
				,  ///
				title("`titleletter': `medcondition'", size(9pt)) ///
				xtitle("`estshort' (95% CI)", size(9pt)) 		/// x-axis title - legend off margin(0 2 0 0)
				xlab(0(20)100, labsize(vsmall) noticks) /// x-axis tick marks
				xscale(range(`xmin' 150))						///	resize x-axis
				,ylab(1 " ", nogrid) /// Invisible y-axis labels for alignment
				ytitle("") yscale(r(0 `yscalemax') off) ysize(8)	 /// y-axis no labels or title 
				legend(order(1 3 5 2) label(1 "Crude PPV") label(3 "Standardised PPV") label(5 "Crude % confirmed cases retained") label(2 "95% CI") ///
				size(7pt) rows(1) nobox region(lstyle(none) col(none) margin(zero)) bmargin(zero) position(6)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(none) ilwidth(none) margin(zero)) ///
				plotregion(fcolor(white) lcolor(black) lwidth(none) ilwidth(none) margin(vsmall)) ///
				name("`medcondition'", replace)
			
} /*medcondition*/




*/// Headings for estimate labels and results
*|| scatter obs estlabpos if obs==$headingobs, m(i) mlab(estheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///

grc1leg OSA narcolepsy, ///
legendfrom(OSA) position(6) ///
graphregion(fcolor(white) lcolor(white) lwidth(none) ilwidth(none) margin(zero)) ///
plotregion(fcolor(white) lcolor(black) lwidth(none) ilwidth(none) margin(vsmall)) ///
imargin(zero) ///
rows(2) ///
name(main_graph, replace)
graph display main_graph, xsize(6.5) /*margins(tiny)*/
graph export "$resultdir/v11.an_ppv_sens_graph", as(emf) replace

*ycommon ///


capture log close
