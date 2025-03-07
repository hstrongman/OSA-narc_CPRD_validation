/*********************************************************
# Stata do file:    0.master.do
#
# Author:      Helen Strongman
#
# Date:        07/11/2023
#
# Description: This Master file lists all code lists that
				have been created for 22_001887_validation
#
# Inspired and adapted from: 
# 				N/A
**********************************************************/

/**********************************************************
# Study conventions
**********************************************************/

* The names of temporary variables should be prefixed with _ 

/**********************************************************
# Copy markdown settings files to metadata folder
These are needed to format the HTML output
**********************************************************/

cd "$metadir"
copy "http://www.stata-press.com/data/r17/reporting/header.txt" ., replace
copy "http://www.stata-press.com/data/r17/reporting/stmarkdown.css" ., replace

/*DYNDOC HELP DOCUMENTS AND TIPS:
https://www.stata.com/manuals/rptdyndoc.pdf
https://www.stata.com/manuals/rptdynamictags.pdf

You can read and adapt the .txt files in the Stata do editor.

Other than the arguments described above, locals can't be used with the
HTML text.

You can find guidance about ~~~~ in the Stata documentation. I found it easiest
to add it before and after each header.

Error messages: these sometimes apply to a much later line of text than first
appears.

error message "attribute : not valid in dd_do tag" appears when an attribute 
(e.g. quietly or nocommands) has been specified
*/

do "$dodir/codelist_define_format.do" /*use this do file to transform
code lists to the format required by CPRD's online Define tool*/

/**********************************************************
# Create code list lookup for Aurum so that medcodeid and
prodcodeid strings can be replaced with mapped numeric ids saving
space and time. These ids need to be added to each
codelist.
For this project, this step was completed after the study
population was defined. Ideally it would be at the start of
the project #
**********************************************************/

*Created using the September 2023 build
do "$dodir/medcodeid_projectmedcode_lookup.do"
do "$dodir/prodcodeid_projectprodcode_lookup.do"

/**********************************************************
# Define study populations. These do files create:
- HTML files describing the code list and phenotype (_description)
- HTML files describing how the code list was generated (_derivation)
- .dta code lists files including key variables 
- .txt code list files including all variables from the dictionary
Code list files are named codelist_condition_source
**********************************************************/

do "$dodir/codelist_sleep_apnoea.do"
do "$dodir/codelist_narcolepsy.do"

/**********************************************************
# Covariates: These do files create:
- HTML files describing the code list and phenotype (_description)
- HTML files describing how the code list was generated (_derivation)
- .dta code lists files including key variables 
- .txt code list files including all variables from the dictionary
Code list files are named codelist_condition_source
**********************************************************/

do "$dodir/codelist_bmi_ethnicity.do" /*use codelists from main study - update
projectmedcode*/

do "$dodir/codelist_dexamfetamine.do"
do "$dodir/codelist_modafinil.do"
do "$dodir/codelist_methylphenidate.do"




