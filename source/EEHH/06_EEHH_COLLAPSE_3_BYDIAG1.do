* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/EEHH_06c_COLLAPSEBYDIAG1_`datetag'", replace text name(EEHH_06c_COLLAPSEBYDIAG1)

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load data:
use "${eehh_original}_NODUPS_NONAS_NEWVARS.dta", clear

* Get minimum and maximum EEHH year:
sum $eyear_var
scalar min_ano_eehh = r(min)
scalar max_ano_eehh = r(max)

* Store variable labels:
foreach var of varlist days_y* days_m* days_s* olap nvsts {
	local vlbl_`var' : variable label `var'
}

********************************************************************************
* Collapse by patient and DIAG1 chapter:
collapse (sum) days_* nvsts_* olap, by(ID_PACIENTE cap_diag1)

* Relabel variables:
foreach var of varlist days_* nvsts_* olap {
	label var `var' "`vlbl_`var''"
}

* Compress, label, sign, and save:
compress
label data "Days hospitalized `=min_ano_eehh'-`=max_ano_eehh' by diagnosis (long, from EEHH database)"
notes drop _dta
save "hospdays_by_diagnosis1_long.dta", replace

********************************************************************************
* RESHAPE WIDE:
replace cap_diag1 = subinstr(cap_diag1, "-", "_", .)
replace cap_diag1 = "Missing" if cap_diag1 == ""

* Get variable names ready for reshape:
foreach var of varlist days_* nvsts_* olap {
	rename `var' `var'_
}

* Get list of diag1 chapters:
levelsof cap_diag1, local(cap_diag1_list)

* Apply reshape:
reshape wide days_*_ nvsts_*_ olap_, i(ID_PACIENTE) j(cap_diag1) string

* Reapply labels:
foreach cap of local cap_diag1_list {
	foreach var of varlist days_*_`cap' nvsts_*_`cap' olap_`cap' {
		local prefix = subinstr("`var'", "_`cap'", "", 1)
		label var `var' `"`vlbl_`prefix'': `=subinstr("`cap'", "_", "-", 1)'"'
	}
}

* Compress, label, sign, and save:
compress
label data "Days hospitalized `=min_ano_eehh'-`=max_ano_eehh' by diagnosis (wide, from EEHH database)"
notes drop _dta
save "hospdays_by_diagnosis1_wide.dta", replace

* Close log:
log close _all
