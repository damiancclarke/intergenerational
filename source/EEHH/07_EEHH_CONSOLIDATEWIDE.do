* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/EEHH_07_CONSWIDE_`datetag'", replace text name(EEHH_CONSWIDE)

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

********************************************************************************
* Load fully collapsed data:
use hospdays_by_patient.dta, clear

* Merge in data by public/private (should be a perfect merge):
merge 1:1 ID_PACIENTE using hospdays_by_public_wide.dta, nogen

* Merge in data by diagnosis (original dataset is huge, >15gb, so use the option
* keepusing to get specific variables...)
* merge 1:1 ID_PACIENTE using hospdays_by_diagnosis1_wide.dta, nogen keepusing()

********************************************************************************
* Need to separate ambulatory visits in y and m variables:
/* ambulatory visits are counted originally as a 1 day visit, but when spreading
 over years or months, they show up as 0s.

On the other hand, collapse assigns 0s to the sum of missings.

nvsts is going to be 0 if the days var is spilling over from the previous period
because the visit is recorded only once (when it began).

so we need to assign the days variable to missing if the visits are 0 and the 
days are 0, because this would identify a 0 day visit produced by the collapse 
command.

if days are not 0 but visits are 0, it means that some days have spilled over 
from the previous period, so the days variable shouldn't be assigned as missing.
*/

* Display statistics of example variables before:
sum *_y01

foreach nvsts_var of varlist nvsts_y* nvsts_m* {
	* Show which var we're processing:
	display "Now processing `nvsts_var'"
	
	* Get name of days variable:
	local days_var = subinstr("`nvsts_var'", "nvsts", "days", 1)
	
	* Replace with missing non ambulatory 0 day non-visits:
	replace `days_var' = . if `nvsts_var' == 0 & `days_var' == 0
}

* Display statistics of example variables after:
sum *_y01

********************************************************************************
* Assign MISSING to public and private visits if total visits is 0:
/*
When using the collapse command, if a person visited a public hospital some
time in their life, she's going to get assigned a 0 in other years of her life.

Given that we wouldn't know the split between public/public in a given year if
she visited neither, then the variable nvsts should be missing if her total
visits to hospital are 0.
*/

foreach nvsts_var of varlist nvsts_y?? nvsts_m?? {
	* Show which variable we're processing:
	display "Now processing `nvsts_var':"
	
	* Get name of days variable:
	local days_var = subinstr("`nvsts_var'", "nvsts", "days", 1)
	
	* Get name of public variable:
	local nvsts_var_publ = "`nvsts_var'_publ"
	
	* Get name of private variable:
	local nvsts_var_priv = "`nvsts_var'_priv"
	
	* Replace public variable with ZERO if individual visited only private:
	replace `nvsts_var_publ' = . if `nvsts_var' == 0
	
	* Replace private variable with ZERO if individual visited only public:
	replace `nvsts_var_priv' = . if `nvsts_var' == 0
}

********************************************************************************

* Assign ZERO to public when individual visited only private and vice-versa:
foreach nvsts_var of varlist nvsts_y?? nvsts_m?? {
	* Show which variable we're processing:
	display "Now processing `nvsts_var':"
	
	* Get name of public number of visits variable:
	local nvsts_var_publ = "`nvsts_var'_publ"
	
	* Get name of public days variable:
	local days_var_publ = subinstr("`nvsts_var_publ'", "nvsts", "days", 1)
	
	* Get name of private number of visits variable:
	local nvsts_var_priv = "`nvsts_var'_priv"
	
	* Get name of public days variable:
	local days_var_priv = subinstr("`nvsts_var_priv'", "nvsts", "days", 1)
	
	* Replace public variables with ZERO if individual visited only private:
	replace `nvsts_var_publ' = 0 if `nvsts_var_publ' == . &  `nvsts_var_priv' != . & `nvsts_var_priv' == `nvsts_var'
	replace `days_var_publ' = 0 if `days_var_publ' == . &  `days_var_priv' != . & `nvsts_var_publ' == 0
	
	* Replace private variable with ZERO if individual visited only public:
	replace `nvsts_var_priv' = 0 if `nvsts_var_priv' == . &  `nvsts_var_publ' != . & `nvsts_var_publ' == `nvsts_var'
	replace `days_var_priv' = 0 if `days_var_priv' == . &  `days_var_publ' != . & `nvsts_var_priv' == 0
}

********************************************************************************
* Compress, label, sign, and save:
compress
label data "Days hospitalized, consolidate wide by ID_PACIENTE"
notes drop _dta
notes: Last modified on $S_DATE at $S_TIME
save hospdays_conswide.dta, replace

* Close log:
log close _all
