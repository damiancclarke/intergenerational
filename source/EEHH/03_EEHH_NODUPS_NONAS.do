* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/EEHH_03_CLEAN_`datetag'", replace text name(EEHH_CLEAN)

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load data:
use "${eehh_original}.dta", clear

* Drop ID Missing:
drop if ID_PACIENTE == ""

* Drop ID NA:
drop if ID_PACIENTE == "NA"

* Report and drop exact duplicates (after dropping missing/NA IDs):
duplicates report
duplicates drop

* Fix PERTENENCIA_SNNS ex-post:
replace PERTENENCIA_SNSS = PERTENENCIA_SNSS - 1 if ANO_EGRESO == 2001 | ANO_EGRESO == 2004
label drop PERTENENCIA_SNSS
label def PERTENENCIA_SNSS ///
	1 "No Pertenecientes al Sistema Nacional de Servicios de Salud, SNSS" ///
	2 "Pertenecientes al Sistema Nacional de Servicios de Salud, SNSS"
label val PERTENENCIA_SNSS PERTENENCIA_SNSS

* Get minimum and maximum EEHH year:
sum $eyear_var
scalar min_ano_eehh = r(min)
scalar max_ano_eehh = r(max)

* Compress, label, and save:
compress
label data "Egresos Hospitalarios `=min_ano_eehh'-`=max_ano_eehh' en Chile (DEIS/MINSAL), -duplicados/NAs"
notes drop _dta
notes: Last modified on $S_DATE at $S_TIME
save "${eehh_original}_NODUPS_NONAS.dta", replace

* Close log:
log close _all
