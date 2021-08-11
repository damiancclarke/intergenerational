clear all
set more off

cd "$dtadir\DEIS"
use NAC_1992_2018_NOGLOSAS_NODUPS_NONAS.dta
merge 1:1 ID_RECIEN_NACIDO using workingdata9Jul2021.dta, ///
	keepusing(muerte_1a) nogen

* Keep only girls that died before 1 year:	
keep if muerte_1a == 1 & SEXO == 2

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

foreach var of varlist * {
	rename `var' NAC_`var'
}

compress
label data "Counterfactual mothers: girls that died within 1 year + mother vars"
notes drop _all
note: This dataset contains observations of girls that died within 1 year, as if they had become mothers.
save COUNTERFACTUAL_MOTHERS.dta, replace
