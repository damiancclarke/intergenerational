* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/MERGE_02_HOSP2DEF2NAC_`datetag'", replace text name(MERGE_HOSP2DEF2NAC)

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load merged Deaths 2 Births data:
use MERGED_DEF2NAC.dta, clear

* Drop unmatched deaths:
drop if mrg_DEF2NAC == 2

* Copy ID variable:
gen ID_PACIENTE = ID_RECIEN_NACIDO

* Perform merge (keeping only master and matched):
merge 1:1 ID_PACIENTE using hospdays_conswide.dta, ///
	keep(match master) gen(mrg_hosp2DEF2NAC)

label var mrg_hosp2DEF2NAC "Merge 1:1 ID_PACIENTE using hospdays_conswide"

* Rename hospital days variables:
ds NAC_* DEF_* mrg_* ID_*, not
foreach var of varlist `r(varlist)' {
	rename `var' EEHH_`var'
}

* Save merged dataset:
compress
local data_lbl : data label
label data "hosp. days merged to `data_lbl'"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save MERGED_HOSPDATS2DEF2NAC.dta, replace

* Close log:
log close _all
