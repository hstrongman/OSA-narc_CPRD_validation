/*******************************************************************************
# Stata do file:    inc_v3.an_flowchart_simplerow.do
#
# Author:      Helen Strongman
#
# Date:        08/07/2024. 
#
# Description: 	This include do file generates locals for flowchart
#				rows with one inclusion or exclusion critieria for the sleep
#				disorder and sleep disorder free groups
#
# Inspired and adapted from: 
#				N/A
*******************************************************************************/

di "rownumber: `row'"
di "criteria number: `criteriano'"
di "include/exclude: `inclusion'" /*0 = exclusion. 1 = inclusion*/

	
*foreach col in left right {
foreach medcondition in OSA narcolepsy {
	if "`medcondition'" == "OSA" local col = "left"
	if "`medcondition'" == "narcolepsy" local col = "right"
	local row`row'`col'name: label criterialab `criteriano'
	*change "sleep disorder" to specific sleep disorder*/
	local row`row'`col'name = subinstr("`row`row'`col'name'", "sleep disorder", "`medcondition'", 1)
	local row`row'`col'name = subinstr("`row`row'`col'name'", "Sleep disorder", "`medcondition'", 1)
	*add "Exclude:" prefix to exclusion criteria
	if `inclusion' == 0 local row`row'`col'name "Excluded: `row`row'`col'name'"
	*make inclusions bold text (Latex script)
	if `inclusion' == 1 local row`row'`col'name "\textbf{`row`row'`col'name'}"
	di "`row`row'`col'name'"
	*number of patients
	local row`row'`col'no = aurumlinked`medcondition'[`criteriano']
	di "`row`row'`col'no'"
	}

