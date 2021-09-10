* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/MERGE_01_DEF2NAC_`datetag'", replace text name(MERGE_DEF2NAC)

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load birth data (no duplicates) with mother birth variables:
use "${nac_original}_NOGLOSAS_NODUPS_NONAS_WITH_MBDATA_MOSTATS.dta", clear

* Save database minimum and maximum year:
sum $byear_var
scalar min_ano_nac = r(min)
scalar max_ano_nac = r(max)

* Copy ID variable:
gen ID_FALLECIDO = ID_RECIEN_NACIDO

* Add prefix to birth data variable names:
foreach var of varlist * {
	if "`var'" != "ID_FALLECIDO" & "`var'" != "ID_RECIEN_NACIDO" {
		rename `var' NAC_`var'
	}
}

* Merge with deaths data (also without duplicates and w/o NAs):
merge 1:1 ID_FALLECIDO ///
	using "${def_original}_NOGLOSAS_NODUPS_NONAS.dta", ///
	gen(mrg_DEF2NAC)

label var mrg_DEF2NAC "Merge 1:1 ID_FALLECIDO/RECIEN_NACIDO"

* Get minimum and maximum death years:
sum $dyear_var
scalar min_ano_def = r(min)
scalar max_ano_def = r(max)	

* Drop unmatched deaths:
drop if mrg_DEF2NAC == 2 & COD_MENOR != "1"

* Rename death data variable data:
ds NAC_* ID_* mrg_DEF2NAC, not
foreach var of varlist `r(varlist)' {
	rename `var' DEF_`var'
}


* Save merged dataset:
compress
label data "`=min_ano_def'-`=max_ano_def' deaths merged to `=min_ano_nac'-`=max_ano_nac' births"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save MERGED_DEF2NAC.dta, replace

* Close log:
log close _all
