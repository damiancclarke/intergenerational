* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/EEHH_06b_COLLAPSET_`datetag'", replace text name(EEHH_06b_COLLAPSET)

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

********************************************************************************
* Load data by patient and public/private:
use hospdays_by_public_long.dta, clear

* Store variable labels:
foreach var of varlist days_* nvsts_* olap {
	local vlbl_`var' : variable label `var'
}

* Collapse:
collapse (sum) days_* nvsts_* olap ///
	(max) any_public = public_hosp ///
	(min) any_private = public_hosp, by(ID_PACIENTE)

replace any_private = 1 - any_private

* Relabel variables:
foreach var of varlist days_* nvsts_* olap {
	label var `var' "`vlbl_`var''"
}

* Label other variables:
label var any_public "=1 if any hospitalization in a public hospital"
label var any_private "=1 if any hospitalization in a private hospital"

* Compress, label, sign, and save:
compress
local data_label : data label
label data `"`=subinstr("`data_label'", "by public/private hospital", "by patient", 1)'"'
notes drop _dta
notes: Last modified on $S_DATE at $S_TIME
save hospdays_by_patient.dta, replace
********************************************************************************

* Close log:
log close _all
