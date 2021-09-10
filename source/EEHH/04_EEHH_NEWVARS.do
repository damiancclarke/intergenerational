* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/EEHH_04_NEWVARS_`datetag'", replace text name(EEHH_NEWVARS)

* Preamble:
cls
clear all
set more off

* Switch to source directory:
cd "$dtadir/DEIS"

* Load data:
use "${eehh_original}_NODUPS_NONAS.dta", clear

********************************************************************************
* DIAGNOSTICS:
* Number of missing discharge dates:
count if FECHA_EGRESO == .

********************************************************************************
* CREATE NEW VARIABLES:
* Tag one observation by ID:
egen tag_idp = tag(ID_PACIENTE)

* Create fecha ingreso:
gen int fecha_ingreso = FECHA_EGRESO - DIAS_ESTADA + 1
format fecha_ingreso %td
label var fecha_ingreso "Admission to hospital date (FECHA_EGRESO - DIAS_ESTADA + 1)"

* Sort and declare panel:
sort ID_PACIENTE fecha_ingreso
by ID_PACIENTE: gen int orden = _n
label var orden "Hospital visit order (by admission date)"
by ID_PACIENTE: gen int nvsts = _N
label var nvsts "Total number of hospital visits"
egen idp = group(ID_PACIENTE)

* Tag overlapping visits:
xtset idp orden
gen byte olap = fecha_ingreso < L1.FECHA_EGRESO if orden > 1
replace olap = 0 if orden == 1
label var olap "Number of overlapping hospital visits"

* Create dummy variable for public/private hospital:
gen byte public_hosp = PERTENENCIA_SNSS == 2 if PERTENENCIA_SNSS != .
label var public_hosp "Private = 0 / Public = 1"

********************************************************************************
* FIX ORIGINAL BIRTH DATE:
* Find inconsistencies between recorded birth date and discharge variables:
gen int ano_nac_aux = year(fecha_ingreso) - EDAD_A_OS
gen int ano_nac_1 = year(FECHA_NACIMIENTO)
gen int diff_ano_nac_aux1 = ano_nac_1 - ano_nac_aux
gen byte fecha_nac_ok1 = abs(diff_ano_nac_aux1) <= 1 if diff_ano_nac_aux1 != . // error window = +- 1 year

* Tabulate discharge year by status:
tab ANO_EGRESO fecha_nac_ok1, m

* Determine if there is consensus in FECHA_NACIMIENTO, among correct and 
* non-missing values, for individuals that visited a hospital multiple times 
* between 2001 and 2019:
bys ID_PACIENTE: egen int max_FECHA_NACIMIENTO = max(cond(fecha_nac_ok1 == 1, FECHA_NACIMIENTO, .))
bys ID_PACIENTE: egen int min_FECHA_NACIMIENTO = min(cond(fecha_nac_ok1 == 1, FECHA_NACIMIENTO, .))
format %td max_FECHA_NACIMIENTO min_FECHA_NACIMIENTO
gen byte cons_FECHA_NACIMIENTO = max_FECHA_NACIMIENTO == min_FECHA_NACIMIENTO ///
	if max_FECHA_NACIMIENTO != . & min_FECHA_NACIMIENTO != .

* Create new FECHA_NACIMIENTO based on original:
gen int FECHA_NACIMIENTO_fixed = FECHA_NACIMIENTO
format %td FECHA_NACIMIENTO_fixed

* Fill in missing values with consensus correct date:
replace FECHA_NACIMIENTO_fixed = min_FECHA_NACIMIENTO ///
	if FECHA_NACIMIENTO_fixed == . /// only replace missing values
	& cons_FECHA_NACIMIENTO == 1 /// if there is a consensus correct date

* Recheck:
gen int ano_nac_2 = year(FECHA_NACIMIENTO_fixed)
gen int diff_ano_nac_aux2 = ano_nac_2 - ano_nac_aux
gen byte fecha_nac_ok2 = abs(diff_ano_nac_aux2) <= 1 if diff_ano_nac_aux2 != .

* Tabulate discharge year by status:
tab ANO_EGRESO fecha_nac_ok2, m

* Fill in incorrect non-missing values with consensus correct date:
replace FECHA_NACIMIENTO_fixed = min_FECHA_NACIMIENTO ///
	if FECHA_NACIMIENTO_fixed != . /// only replace non-missing values
	& cons_FECHA_NACIMIENTO == 1 /// if there is a consensus correct date
	& fecha_nac_ok2 == 0 /// and the original date is not ok

* Recheck:
gen int ano_nac_3 = year(FECHA_NACIMIENTO_fixed)
gen int diff_ano_nac_aux3 = ano_nac_3 - ano_nac_aux
gen byte fecha_nac_ok3 = abs(diff_ano_nac_aux3) <= 1 if diff_ano_nac_aux3 != .

* Tabulate discharge year by status:
tab ANO_EGRESO fecha_nac_ok3, m

* Check how many IDs have full ok birthdate:
bys ID_PACIENTE: egen byte min_fecha_nac_ok3 = min(fecha_nac_ok3)
bys ID_PACIENTE: egen byte max_fecha_nac_ok3 = max(fecha_nac_ok3)
tab min_fecha_nac_ok3 if tag_idp == 1, m

********************************************************************************
* Merge in birthdate from births database:
gen ID_RECIEN_NACIDO = ID_PACIENTE
merge m:1 ID_RECIEN_NACIDO using NAC_1992_2018_NOGLOSAS_NODUPS_NONAS.dta, ///
	keepusing(FECHA_NACIMIENTO_SIF) keep(master match) gen(mrg_NAC2EEHH)
rename FECHA_NACIMIENTO_SIF NAC_FECHA_NACIMIENTO_SIF
compare FECHA_NACIMIENTO NAC_FECHA_NACIMIENTO_SIF
compare FECHA_NACIMIENTO_fixed NAC_FECHA_NACIMIENTO_SIF

* Check if merged in birth date is ok:
gen int ano_nac_4 = year(NAC_FECHA_NACIMIENTO_SIF)
gen int diff_ano_nac_aux4 = ano_nac_4 - ano_nac_aux
gen byte fecha_nac_ok4 = abs(diff_ano_nac_aux4) <= 1 if diff_ano_nac_aux4 != .

* Tabulate discharge year by status:
tab ANO_EGRESO fecha_nac_ok4, m

* Check how many IDs have full ok birthdate:
bys ID_PACIENTE: egen byte min_fecha_nac_ok4 = min(fecha_nac_ok4)
bys ID_PACIENTE: egen byte max_fecha_nac_ok4 = max(fecha_nac_ok4)
tab min_fecha_nac_ok4 if tag_idp == 1

********************************************************************************
* Tag observations that appear to have the wrong ID:
gen byte mrg_NAC2EEHH_fixed = mrg_NAC2EEHH
label val mrg_NAC2EEHH_fixed _merge

* Replace as master only if birth date from births database is not ok, but there is at least one ok match for that ID:
replace mrg_NAC2EEHH_fixed = 1 if mrg_NAC2EEHH == 3 & fecha_nac_ok4 == 0 & max_fecha_nac_ok4 == 1

* Replace as master only if birth date from births database is later than discharge date:
replace mrg_NAC2EEHH_fixed = 1 if mrg_NAC2EEHH == 3 & NAC_FECHA_NACIMIENTO_SIF > FECHA_EGRESO & NAC_FECHA_NACIMIENTO_SIF != .

* Consolidate birthdate:
gen int fecha_nac_cons = NAC_FECHA_NACIMIENTO_SIF if mrg_NAC2EEHH_fixed == 3 // use births database birthdate first
replace fecha_nac_cons = FECHA_NACIMIENTO_fixed if mrg_NAC2EEHH_fixed == 1 // use EEHH birth date (fixed) for master only obs
format fecha_nac_cons %td
label var fecha_nac_cons "Birth date (NAC to EEHH consensus)"

* Fill in missing values of fecha_nac_cons if there is consensus:
bys ID_PACIENTE: egen int min_fecha_nac_cons = min(fecha_nac_cons)
bys ID_PACIENTE: egen int max_fecha_nac_cons = max(fecha_nac_cons)
replace fecha_nac_cons = min_fecha_nac_cons ///
	if fecha_nac_cons == . ///
	& min_fecha_nac_cons == max_fecha_nac_cons ///
	& min_fecha_nac_cons != . ///
	& max_fecha_nac_cons != .

* Check if consolidated birth date is ok according to birth year:
gen int ano_nac_5 = year(fecha_nac_cons)
gen int diff_ano_nac_aux5 = ano_nac_5 - ano_nac_aux
gen byte fecha_nac_ok5 = abs(diff_ano_nac_aux5) <= 1 if diff_ano_nac_aux5 != .

* Check how many IDs have full ok birthdate:
bys ID_PACIENTE: egen byte min_fecha_nac_ok5 = min(fecha_nac_ok5) if mrg_NAC2EEHH_fixed == 3
bys ID_PACIENTE: egen byte max_fecha_nac_ok5 = max(fecha_nac_ok5) if mrg_NAC2EEHH_fixed == 3
tab min_fecha_nac_ok5 if tag_idp == 1 & mrg_NAC2EEHH_fixed == 3, m

* Tabulate discharge year by status:
tab ANO_EGRESO fecha_nac_ok5, m

* Check if consolidated birth date is ok according to hospital admission:
gen ingreso_too_early = fecha_ingreso < fecha_nac_cons
bys ID_PACIENTE: egen num_ingreso_too_early = total(ingreso_too_early)

********************************************************************************
* Categorizations by diagnosis

* Categorize diagnoses by chapter:
decode DIAG1, gen(_DIAG1)
gen cap_diag1 = "A00-B99" if substr(_DIAG1, 1, 1) == "A" | substr(_DIAG1, 1, 1) == "B"
replace cap_diag1 = "C00-D48" if substr(_DIAG1, 1, 1) == "C"
replace cap_diag1 = "C00-D48" if substr(_DIAG1, 1, 1) == "D" & real(substr(_DIAG1, 2, 3)) < 500
replace cap_diag1 = "D50-D89" if substr(_DIAG1, 1, 1) == "D" & real(substr(_DIAG1, 2, 3)) >= 500
replace cap_diag1 = "E00-E90" if substr(_DIAG1, 1, 1) == "E"
replace cap_diag1 = "F00-E99" if substr(_DIAG1, 1, 1) == "F"
replace cap_diag1 = "G00-G99" if substr(_DIAG1, 1, 1) == "G"
replace cap_diag1 = "H00-H59" if substr(_DIAG1, 1, 1) == "H" & real(substr(_DIAG1, 2, 3)) < 600
replace cap_diag1 = "H60-H95" if substr(_DIAG1, 1, 1) == "H" & real(substr(_DIAG1, 2, 3)) >= 600
replace cap_diag1 = "I00-I99" if substr(_DIAG1, 1, 1) == "I"
replace cap_diag1 = "K00-K93" if substr(_DIAG1, 1, 1) == "K"
replace cap_diag1 = "L00-L99" if substr(_DIAG1, 1, 1) == "L"
replace cap_diag1 = "M00-M99" if substr(_DIAG1, 1, 1) == "M"
replace cap_diag1 = "N00-N99" if substr(_DIAG1, 1, 1) == "N"
replace cap_diag1 = "O00-O99" if substr(_DIAG1, 1, 1) == "O"
replace cap_diag1 = "P00-P96" if substr(_DIAG1, 1, 1) == "P"
replace cap_diag1 = "Q00-Q99" if substr(_DIAG1, 1, 1) == "Q"
replace cap_diag1 = "R00-R99" if substr(_DIAG1, 1, 1) == "R"
replace cap_diag1 = "S00-T98" if substr(_DIAG1, 1, 1) == "S" | substr(_DIAG1, 1, 1) == "T"
replace cap_diag1 = "V00-Y98" if substr(_DIAG1, 1, 1) == "V" | substr(_DIAG1, 1, 1) == "W" | substr(_DIAG1, 1, 1) == "X" | substr(_DIAG1, 1, 1) == "Y"
replace cap_diag1 = "Z00-Z99" if substr(_DIAG1, 1, 1) == "Z"
replace cap_diag1 = "U00-U99" if substr(_DIAG1, 1, 1) == "U"
drop _DIAG1

decode DIAG2, gen(_DIAG2)
gen cap_diag2 = "A00-B99" if substr(_DIAG2, 1, 1) == "A" | substr(_DIAG2, 1, 1) == "B"
replace cap_diag2 = "C00-D48" if substr(_DIAG2, 1, 1) == "C"
replace cap_diag2 = "C00-D48" if substr(_DIAG2, 1, 1) == "D" & real(substr(_DIAG2, 2, 3)) < 500
replace cap_diag2 = "D50-D89" if substr(_DIAG2, 1, 1) == "D" & real(substr(_DIAG2, 2, 3)) >= 500
replace cap_diag2 = "E00-E90" if substr(_DIAG2, 1, 1) == "E"
replace cap_diag2 = "F00-E99" if substr(_DIAG2, 1, 1) == "F"
replace cap_diag2 = "G00-G99" if substr(_DIAG2, 1, 1) == "G"
replace cap_diag2 = "H00-H59" if substr(_DIAG2, 1, 1) == "H" & real(substr(_DIAG2, 2, 3)) < 600
replace cap_diag2 = "H60-H95" if substr(_DIAG2, 1, 1) == "H" & real(substr(_DIAG2, 2, 3)) >= 600
replace cap_diag2 = "I00-I99" if substr(_DIAG2, 1, 1) == "I"
replace cap_diag2 = "K00-K93" if substr(_DIAG2, 1, 1) == "K"
replace cap_diag2 = "L00-L99" if substr(_DIAG2, 1, 1) == "L"
replace cap_diag2 = "M00-M99" if substr(_DIAG2, 1, 1) == "M"
replace cap_diag2 = "N00-N99" if substr(_DIAG2, 1, 1) == "N"
replace cap_diag2 = "O00-O99" if substr(_DIAG2, 1, 1) == "O"
replace cap_diag2 = "P00-P96" if substr(_DIAG2, 1, 1) == "P"
replace cap_diag2 = "Q00-Q99" if substr(_DIAG2, 1, 1) == "Q"
replace cap_diag2 = "R00-R99" if substr(_DIAG2, 1, 1) == "R"
replace cap_diag2 = "S00-T98" if substr(_DIAG2, 1, 1) == "S" | substr(_DIAG2, 1, 1) == "T"
replace cap_diag2 = "V00-Y98" if substr(_DIAG2, 1, 1) == "V" | substr(_DIAG2, 1, 1) == "W" | substr(_DIAG2, 1, 1) == "X" | substr(_DIAG2, 1, 1) == "Y"
replace cap_diag2 = "Z00-Z99" if substr(_DIAG2, 1, 1) == "Z"
replace cap_diag2 = "U00-U99" if substr(_DIAG2, 1, 1) == "U"
drop _DIAG2


********************************************************************************

* Get minimum and maximum EEHH year:
sum $eyear_var
scalar min_ano_eehh = r(min)
scalar max_ano_eehh = r(max)

* Compress, sort, label, sign, and save:
compress
sort ID_PACIENTE orden
label data "EEHH `=min_ano_eehh'-`=max_ano_eehh' en Chile (DEIS/MINSAL), -duplicados/NAs, +nuevas variables"
notes drop _dta
notes: Last modified on $S_DATE at $S_TIME
save "${eehh_original}_NODUPS_NONAS_NEWVARS.dta", replace

* Close log:
log close _all
