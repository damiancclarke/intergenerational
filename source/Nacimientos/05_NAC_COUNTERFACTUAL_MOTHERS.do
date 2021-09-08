* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/COUNTERFACTUAL_MOTHERS_`datetag'", replace text name(COUNTERFACTUAL_MOTHERS)			  
			  
* Preamble:
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Check necessary files exist:
capture confirm file "${def_original}_NOGLOSAS_NODUPS_NONAS.dta"
if _rc != 0 {
	display "Necessary file not found: ${def_original}_NOGLOSAS_NODUPS_NONAS.dta"
	display "Run steps 01 to 03 for the DEATHS data first"
	log close _all
	stop
}

* Load all births (excluding duplicates and NAs):
use "${nac_original}_NOGLOSAS_NODUPS_NONAS.dta", clear

* Merge with latest working data:
gen ID_FALLECIDO = ID_RECIEN_NACIDO
merge 1:1 ID_FALLECIDO using "${def_original}_NOGLOSAS_NODUPS_NONAS.dta", ///
	keepusing(FECHA_DEF_SIF) nogen
	
* Create variables related to infant mortality:
gen dias_muerte = FECHA_DEF_SIF - FECHA_NACIMIENTO_SIF /*Días vividos antes de morir*/
gen muerte_1a = 1 if dias_muerte <= 365
replace muerte_1a = 0 if (dias_muerte == . | dias_muerte > 365) /*Missing corresponde a nacidos que permanecen vivos*/
tab muerte_1a, m    /*1.453 fallecidos menores de 1 año*/
label var dias_muerte "Days alive before death (missing for living)"
label var muerte_1a "Infant Mortality (death within 1 year of birth)"

* Keep only girls that died before 1 year:	
keep if muerte_1a == 1 & SEXO == 2

* Drop unnecessary variables:
drop dias_muerte muerte_1a ID_FALLECIDO 

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

* Rename the rest of the variables as mother variables:
ds *_ABUELO *_ABUELA ID_RECIEN_NACIDO, not
foreach var of varlist `r(varlist)' {
	local varlbl : variable label `var'
	rename `var' `var'_MADRE
	label var `var'_MADRE "Madre: `varlbl'"
}

* Rename ID variable:
rename ID_RECIEN_NACIDO ID_MADRE
label var ID_MADRE "Identificador único y anónimo de la madre del recién nacido vivo"

* Assign a prefix to all variables:
foreach var of varlist * {
	rename `var' NAC_`var'
}

* Compress, label, sign, and save:
compress
label data "Counterfactual mothers: girls that died within 1 year + mother vars"
notes drop _all
note: This dataset contains observations of girls that died within 1 year, as if they had become mothers.
save COUNTERFACTUAL_MOTHERS.dta, replace

* Close log
log close _all
