* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/EEHH_06a_COLLAPSEBYP_`datetag'", replace text name(EEHH_06a_COLLAPSEBYP)

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

********************************************************************************
* Load data:
use "${eehh_original}_daysvars.dta", clear

* Get minimum and maximum EEHH year:
sum $eyear_var
scalar min_ano_eehh = r(min)
scalar max_ano_eehh = r(max)

* Keep only visits that have been correctly matched to births database:
keep if mrg_NAC2EEHH_fixed == 3

* Keep individuals without any hospital admission before birth:
keep if num_ingreso_too_early == 0

/* what to do with overlapping visits? */

********************************************************************************
* Store variable labels:
foreach var of varlist days_* nvsts_* olap {
	local vlbl_`var' : variable label `var'
}

********************************************************************************
* COLLAPSE LONG:
* Collapse by patient and public/private hospital:
collapse (sum) days_* nvsts_* olap, by(ID_PACIENTE fecha_nac_cons birthday?? fecha_month?? public_hosp)

* Relabel variables:
foreach var of varlist days_* nvsts_* olap {
	label var `var' "`vlbl_`var''"
}


* Compress, label, sign, and save:
compress
label data "Days hospitalized `=min_ano_eehh'-`=max_ano_eehh' by public/private hospital (long, from EEHH database)"
notes drop _dta
notes: Last modified on $S_DATE at $S_TIME
save hospdays_by_public_long.dta, replace

********************************************************************************
* RESHAPE WIDE:
gen hosptype = "priv" if public_hosp == 0
replace hosptype = "publ" if public_hosp == 1
drop public_hosp

* Get variable names ready for reshape:
foreach var of varlist days_* nvsts_* olap {
	rename `var' `var'_
}

* Apply reshape:
reshape wide days_* nvsts_* olap_, i(ID_PACIENTE) j(hosptype) string

* Reapply labels:
foreach var of varlist *_priv *_publ {
	local suffix = substr("`var'", -5, 5)
	local varroot = subinstr("`var'", "`suffix'", "", .)
	
	if "`suffix'" == "_priv" {
		label var `var' "`vlbl_`varroot'': Private"
	}
	else if "`suffix'" == "_publ" {
		label var `var' "`vlbl_`varroot'': Public"
	}
}

* Compress, label, sign, and save:
compress
label data "Days hospitalized `=min_ano_eehh'-`=max_ano_eehh' by public/private hospital (wide, from EEHH database)"
notes drop _dta
notes: Last modified on $S_DATE at $S_TIME
save hospdays_by_public_wide.dta, replace

* Close log:
log close _all
