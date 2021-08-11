* Start log:
capture log close _all
log using "$logdir/MOTHER_BIRTHDATA", replace text name(MOTHER_BIRTHDATA)

clear all
set more off

* Preamble:
cls
clear all
set more off

* Define source and destination directories:
local sourcedir "$dtadir/DEIS"
local destindir "$dtadir/DEIS"

* Check destination directory exists:
capture cd "`destindir'"
if _rc != 0 {
	mkdir "`destindir'"
	display "Destination directory created"
}
else {
	display "Destination directory already exists."
}

* Switch to destination directory:
cd "`sourcedir'"

* Load full birth data (including duplicates and NAs):
use NAC_1992_2018_NOGLOSAS.dta, clear

* Get list of unique mother IDs, and save them as ID_RECIEN_NACIDO:
keep ID_MADRE
drop if ID_MADRE == "NA" | ID_MADRE == ""
duplicates drop ID_MADRE, force
rename ID_MADRE ID_RECIEN_NACIDO
label var ID_RECIEN_NACIDO "" // remove variable label
save "`destindir'/ID_RECIEN_NACIDO_of_unique_ID_MADRE.dta", replace

* Load full birth data, excluding ID duplicates and NAs:
use NAC_1992_2018_NOGLOSAS_NODUPS_NONAS, clear

* Merge in list of unique mother ID's:
merge 1:1 ID_RECIEN_NACIDO using "`destindir'/ID_RECIEN_NACIDO_of_unique_ID_MADRE.dta", keep(match) nogen

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
label data "Mother birth data (based on DEIS's Nacimientos 1992-2018)"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save "`destindir'/MOTHER_BIRTHDATA.dta", replace

********************************************************************************
//// Merge mother's birth data back to main dataset ////

* Load full birth data (not including duplicates and NAs):
use NAC_1992_2018_NOGLOSAS_NODUPS_NONAS.dta, clear

* Perform merge:
merge m:1 ID_MADRE using "`destindir'/MOTHER_BIRTHDATA.dta", gen(mrg_mbdata2main)

* Drop mothers of duplicates:
drop if mrg_mbdata2main == 2

* label merge variable:
label var mrg_mbdata2main "Merge m:1 ID_MADRE using MOTHER_BIRTHDATA.dta"

* Compress, label, sign, and save:
compress
label data "Nacimientos 1992-2018 en Chile (DEIS) / Sin Glosas / Con data madre"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save "`destindir'/NAC_1992_2018_NOGLOSAS_NODUPS_NONAS_WITH_MBDATA.dta", replace

* Close log
log close _all
