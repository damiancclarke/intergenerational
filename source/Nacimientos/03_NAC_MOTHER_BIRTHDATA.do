* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/MOTHER_BIRTHDATA_`datetag'", replace text name(MOTHER_BIRTHDATA)

clear all
set more off

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load full birth data (including duplicates and NAs):
use "${nac_original}_NOGLOSAS.dta", clear

* Save database minimum and maximum year:
sum $byear_var
scalar min_ano_nac = r(min)
scalar max_ano_nac = r(max)

* Get list of unique mother IDs, and save them as ID_RECIEN_NACIDO:
keep ID_MADRE
drop if ID_MADRE == "NA" | ID_MADRE == ""
duplicates drop ID_MADRE, force
rename ID_MADRE ID_RECIEN_NACIDO
label var ID_RECIEN_NACIDO "" // remove variable label
save "ID_RECIEN_NACIDO_of_unique_ID_MADRE.dta", replace

* Load full birth data, excluding ID duplicates and NAs:
use "${nac_original}_NOGLOSAS_NODUPS_NONAS.dta", clear

* Merge in list of unique mother ID's:
merge 1:1 ID_RECIEN_NACIDO using "ID_RECIEN_NACIDO_of_unique_ID_MADRE.dta", keep(match) nogen

* Rename father variables to grandfather:
foreach var of varlist *_PADRE {
	local varlbl : variable label `var'
	local nvar = subinstr("`var'", "_PADRE", "_ABUELO", .)
	rename `var' `nvar'
	label var `nvar' "Abuelo: `varlbl'"
}

* Rename mother variables to grandmother:
foreach var of varlist *_MADRE {
	local varlbl : variable label `var'
	local nvar = subinstr("`var'", "_MADRE", "_ABUELA", .)
	rename `var' `nvar'
	label var `nvar' "Abuela: `varlbl'"
}

ds *_ABUELO *_ABUELA ID_RECIEN_NACIDO, not
foreach var of varlist `r(varlist)' {
	local varlbl : variable label `var'
	rename `var' `var'_MADRE
	label var `var'_MADRE "Madre: `varlbl'"
}

rename ID_RECIEN_NACIDO ID_MADRE
label var ID_MADRE "Identificador único y anónimo de la madre del recién nacido vivo"


* Compress, label, sign, and save mother birth data:
compress
label data "Mother birth data (based on DEIS's Nacimientos `=min_ano_nac'-`=max_ano_nac')"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save "MOTHER_BIRTHDATA.dta", replace

********************************************************************************
//// Merge mother's birth data back to main dataset ////

* Load full birth data (not including duplicates and NAs):
use "${nac_original}_NOGLOSAS_NODUPS_NONAS.dta", clear

* Perform merge:
merge m:1 ID_MADRE using "MOTHER_BIRTHDATA.dta", gen(mrg_mbdata2main)

* Drop mothers of duplicates:
drop if mrg_mbdata2main == 2

* label merge variable:
label var mrg_mbdata2main "Merge m:1 ID_MADRE using MOTHER_BIRTHDATA.dta"

* Compress, label, sign, and save:
compress
label data "Nacimientos `=min_ano_nac'-`=max_ano_nac' en Chile (DEIS) / Sin Glosas / Con data madre"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save "${nac_original}_NOGLOSAS_NODUPS_NONAS_WITH_MBDATA.dta", replace

* Close log
log close _all
