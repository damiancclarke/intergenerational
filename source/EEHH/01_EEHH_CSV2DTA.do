/*
LAST RUN ON SEPTEMBER 8-9, 2021:

   1:   1558.06 /        1 =    1558.0590
   2:   1594.95 /        1 =    1594.9520
   3:   1588.87 /        1 =    1588.8650
   4:   3800.72 /        1 =    3800.7230
   5:   1877.91 /        1 =    1877.9120
   6:   3717.93 /        1 =    3717.9310
   7:   1944.13 /        1 =    1944.1260
   8:   1884.21 /        1 =    1884.2130
   9:   2042.34 /        1 =    2042.3360
  10:   1948.30 /        1 =    1948.3030
  11:   1962.87 /        1 =    1962.8730
  12:   1980.90 /        1 =    1980.9010
  13:   2023.54 /        1 =    2023.5410
  14:   2208.05 /        1 =    2208.0510
  15:   2027.55 /        1 =    2027.5450
  16:   1963.91 /        1 =    1963.9150
  17:   1969.97 /        1 =    1969.9700
  18:   1951.25 /        1 =    1951.2540
  19:   1894.77 /        1 =    1894.7650

Approximately 11 hours runtime!
*/



* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Preamble:
cls
clear all
set more off

* Change directory to destination directory:
cd "$dtadir/DEIS"

* Get list of Egresos_Hospitalarios folders in the raw data directory:
local folders : dir "$rawdata/DEIS" dirs "Egresos_Hospitalarios_????", respect

* Loop over folders, converting .csv to .dta:
local t = 0
foreach folder of local folders {
	* Start log:
	log using "$logdir/`folder'_`datetag'", text replace name(`folder')
	
	* Start timer:
	local t = `t' + 1
	timer on `t'
	
	* Extract year from folder name:
	local yyyy = word(subinstr("`folder'", "_", " ", .), -1)
	
	* Construct path to csv file:
	local path_to_file = "$rawdata/DEIS/`folder'/`folder'.csv"
	
	* Import csv:
	import delimited "`path_to_file'", ///
		delimiter(";") varnames(1) case(preserve) stringcols(_all) clear
	
	/* DEAL WITH A BUG IN THE 2014 FILE */
	if `yyyy' == 2014 {
		replace GLOSA_DIAG1 = "POLINEUROPATIA EN OTR ENF ENDOCRINAS Y METABOLICAS (E00-E07+,E15-E16+,E20-E34+,E70-E89+)" ///
		if ID_PACIENTE == "02244437DB2659F340DB492ED22E3CA6D4A8324D" ///
		& GLOSA_DIAG1 == "POLINEUROPATIA EN OTR ENF ENDOCRINAS Y METABOLICAS (E00-E07+"
		
		replace DIAG2 = "" if DIAG2 == "E15-E16+" & ID_PACIENTE == "02244437DB2659F340DB492ED22E3CA6D4A8324D"
		replace GLOSA_DIAG2 = "" if GLOSA_DIAG2 == "E20-E34+" & ID_PACIENTE == "02244437DB2659F340DB492ED22E3CA6D4A8324D"
		replace INTERV_Q = "2" if INTERV_Q == "E70-E89+)" & ID_PACIENTE == "02244437DB2659F340DB492ED22E3CA6D4A8324D"
		replace PROCED = "" if PROCED == "2" & ID_PACIENTE == "02244437DB2659F340DB492ED22E3CA6D4A8324D"
		
		drop v*
	}
	
	**** APPLY LABELS FROM VARIABLES, REDUCING DATABASE SIZE ****
	destring ESTABLECIMIENTO_SALUD, replace
	labmask ESTABLECIMIENTO_SALUD, values(GLOSA_ESTABLECIMIENTO_SALUD)
	drop GLOSA_ESTABLECIMIENTO_SALUD
	
	encode PERTENENCIA_ESTABLECIMIENTO_SALU, gen(PERTENENCIA_SNSS)
	order PERTENENCIA_SNSS, after(PERTENENCIA_ESTABLECIMIENTO_SALU)
	compress PERTENENCIA_SNSS
	drop PERTENENCIA_ESTABLECIMIENTO_SALU
	
	destring PAIS_ORIGEN, replace
	count if PAIS_ORIGEN != .
	if `r(N)' != 0 {
		labmask PAIS_ORIGEN, values(GLOSA_PAIS_ORIGEN)
	}
	drop GLOSA_PAIS_ORIGEN
	
	destring COMUNA_RESIDENCIA, replace
	labmask COMUNA_RESIDENCIA, values(GLOSA_COMUNA_RESIDENCIA)
	drop GLOSA_COMUNA_RESIDENCIA
	
	destring REGION_RESIDENCIA, replace force
	replace REGION_RESIDENCIA = 88 if GLOSA_REGION_RESIDENCIA == "Extranjero"
	labmask REGION_RESIDENCIA, values(GLOSA_REGION_RESIDENCIA)
	drop GLOSA_REGION_RESIDENCIA
	
	destring CODIGO_INTERV_Q_PPAL, replace
	count if CODIGO_INTERV_Q_PPAL != .
	if `r(N)' != 0 {
		labmask CODIGO_INTERV_Q_PPAL, values(GLOSA_INTERV_Q_PPAL)
	}
	drop GLOSA_INTERV_Q_PPAL
	
	destring CODIGO_PROCED_PPAL, replace
	count if CODIGO_PROCED_PPAL != .
	if `r(N)' != 0 {
		labmask CODIGO_PROCED_PPAL, values(GLOSA_PROCED_PPAL)
	}
	drop GLOSA_PROCED_PPAL
	
	* Convert string date variables to numeric:
	count if FECHA_NACIMIENTO != ""
	if `r(N)' != 0 {
		gen _FECHA_NACIMIENTO = date(FECHA_NACIMIENTO, "YMD")
		order _FECHA_NACIMIENTO, after(FECHA_NACIMIENTO)
		drop FECHA_NACIMIENTO
		rename _FECHA_NACIMIENTO FECHA_NACIMIENTO
	}
	else {
		destring FECHA_NACIMIENTO, replace
	}
	
	count if FECHA_EGRESO != ""
	if `r(N)' != 0 {
		gen _FECHA_EGRESO = date(FECHA_EGRESO, "YMD")
		order _FECHA_EGRESO, after(FECHA_EGRESO)
		drop FECHA_EGRESO
		rename _FECHA_EGRESO FECHA_EGRESO
	}
	else {
		destring FECHA_EGRESO, replace
	}
	
	format %td FECHA_*
	
	****************************************************************************
	* DIAG1 y GLOSA_DIAG1:
	* encode original into new numeric variable (and organize right after original):
	encode DIAG1, gen(_DIAG1)
	order _DIAG1, after(DIAG1)
	compress _DIAG1

	* store original variable label in a local macro:
	local varlabel : variable label DIAG1

	* store list of notes of original label in local macros:
	local char_list : char DIAG1[]
	foreach c of local char_list {
		local DIAG1_`c' : char DIAG1[`c']
		display "`DIAG1_`c''"
	}

	* drop original:
	drop DIAG1

	* rename copy as original and apply variable label:
	rename _DIAG1 DIAG1
	label var DIAG1 "`varlabel'"

	* reapply notes:
	foreach c of local char_list {
		if real("`DIAG1_`c''") == . {
			notes DIAG1: `DIAG1_`c''
		}
	}
	
	
	* create copy of numeric variable as numeric glosa:
	gen _GLOSA_DIAG1 = DIAG1
	order _GLOSA_DIAG1, after(GLOSA_DIAG1)
	compress _GLOSA_DIAG1

	* store original variable label in a local macro:
	local varlabel : variable label GLOSA_DIAG1

	* store list of notes of original label in local macros:
	local char_list : char GLOSA_DIAG1[]
	foreach c of local char_list {
		local GLOSA_DIAG1_`c' : char GLOSA_DIAG1[`c']
		display "`GLOSA_DIAG1_`c''"
	}

	* remove blanks from original glosa:
	replace GLOSA_DIAG1 = ustrtrim(stritrim(GLOSA_DIAG1))

	* assign values in string glosa as value labels to numeric glosa:
	labmask _GLOSA_DIAG1, values(GLOSA_DIAG1)

	* drop original:
	drop GLOSA_DIAG1

	* rename copy as original and apply variable label:
	rename _GLOSA_DIAG1 GLOSA_DIAG1
	label var GLOSA_DIAG1 "`varlabel'"

	* reapply notes:
	foreach c of local char_list {
		if real("`GLOSA_DIAG1_`c''") == . {
			notes GLOSA_DIAG1: `GLOSA_DIAG1_`c''
		}
	}
	
	****************************************************************************
	* DIAG2 y GLOSA_DIAG2:
	* encode original into new numeric variable (and organize right after original):
	encode DIAG2, gen(_DIAG2)
	order _DIAG2, after(DIAG2)
	compress _DIAG2

	* store original variable label in a local macro:
	local varlabel : variable label DIAG2

	* store list of notes of original label in local macros:
	local char_list : char DIAG2[]
	foreach c of local char_list {
		local DIAG2_`c' : char DIAG2[`c']
		display "`DIAG2_`c''"
	}

	* drop original:
	drop DIAG2

	* rename copy as original and apply variable label:
	rename _DIAG2 DIAG2
	label var DIAG2 "`varlabel'"

	* reapply notes:
	foreach c of local char_list {
		if real("`DIAG2_`c''") == . {
			notes DIAG2: `DIAG2_`c''
		}
	}
	
	* create copy of numeric variable as numeric glosa:
	gen _GLOSA_DIAG2 = DIAG2
	order _GLOSA_DIAG2, after(GLOSA_DIAG2)
	compress _GLOSA_DIAG2

	* store original variable label in a local macro:
	local varlabel : variable label GLOSA_DIAG2

	* store list of notes of original label in local macros:
	local char_list : char GLOSA_DIAG2[]
	foreach c of local char_list {
		local GLOSA_DIAG2_`c' : char GLOSA_DIAG2[`c']
		display "`GLOSA_DIAG2_`c''"
	}

	* remove blanks from original glosa:
	replace GLOSA_DIAG2 = ustrtrim(stritrim(GLOSA_DIAG2))

	* assign values in string glosa as value labels to numeric glosa:
	labmask _GLOSA_DIAG2, values(GLOSA_DIAG2)

	* drop original:
	drop GLOSA_DIAG2

	* rename copy as original and apply variable label:
	rename _GLOSA_DIAG2 GLOSA_DIAG2
	label var GLOSA_DIAG2 "`varlabel'"

	* reapply notes:
	foreach c of local char_list {
		if real("`GLOSA_DIAG2_`c''") == . {
			notes GLOSA_DIAG2: `GLOSA_DIAG2_`c''
		}
	}
	
	****************************************************************************
	* Compress, label, sign and save:
	compress
	label data "Egresos Hospitalarios en Chile, `yyyy' (DEIS/MINSAL)"
	char _dta[Fuente] "https://deis.minsal.cl/#datosabiertos"
	save "EEHH_`yyyy'.dta", replace

	* End timer:
	timer off `t'
	timer list `t'
	
	* Close log:
	log close `folder'
}
timer list
