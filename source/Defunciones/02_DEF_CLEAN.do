* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
log using "$logdir/DEF_CLEAN_`datetag'", replace text name(DEF_CLEAN)			  
			  
* Preamble:
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load data:
use "${def_original}.dta", clear

////////////////////////////////////////////////////////////////////////////////
* Destring numeric variables without value labels:
destring DIA_DEF MES_DEF ANO_DEF, replace
destring DIA_NAC MES_NAC ANO_NAC, replace
destring DIA_PARTO MES_PARTO ANO_PARTO, replace
destring CER_MES CER_ANO, replace
destring EDAD_CANT, replace
destring CURSO_INS, replace
destring ANO_INSCR, replace
destring ANO_PARTO, replace
format %ty ANO_*
destring HIJ_*, replace
destring PESO, replace
destring GESTACION, replace

sum $dyear_var
scalar min_ano_def = r(min)
scalar max_ano_def = r(max)

* String dates to numeric:
gen FECHA_NACIMIENTO_SIF = date(FECHA_NACIMIENTO, "YMD")
format FECHA_NACIMIENTO_SIF %td
order FECHA_NACIMIENTO_SIF, after(FECHA_NACIMIENTO)
local varlabel : variable label FECHA_NACIMIENTO
compress FECHA_NACIMIENTO_SIF
drop FECHA_NACIMIENTO
label var FECHA_NACIMIENTO_SIF "`varlabel' (SIF)"

gen FECHA_DEF_SIF = date(FECHA_DEF, "YMD")
format FECHA_DEF_SIF %td
order FECHA_DEF_SIF, after(FECHA_DEF)
local varlabel : variable label FECHA_DEF
compress FECHA_DEF_SIF
drop FECHA_DEF
label var FECHA_DEF_SIF "`varlabel' (SIF)"

gen FECHA_PARTO_SIF = date(FECHA_PARTO, "YMD")
format FECHA_PARTO_SIF %td
order FECHA_PARTO_SIF, after(FECHA_PARTO)
local varlabel : variable label FECHA_PARTO
compress FECHA_PARTO_SIF
drop FECHA_PARTO
label var FECHA_PARTO_SIF "`varlabel' (SIF)"

compress

////////////////////////////////////////////////////////////////////////////////
* Encode variables and remove their glosas...

********************************************************************************
* SEXO:
destring SEXO, replace
labmask SEXO, values(GLOSA_SEXO)
drop GLOSA_SEXO

********************************************************************************
* EDAD_TIPO:
destring EDAD_TIPO , replace
labmask EDAD_TIPO, values(GLOSA_EDAD_TIPO)
drop GLOSA_EDAD_TIPO

********************************************************************************
* EST_CIVIL:
destring EST_CIVIL, replace
labmask EST_CIVIL, values(GLOSA_EST_CIVIL)
drop GLOSA_EST_CIVIL

********************************************************************************
* NIVEL_INS:
destring NIVEL_INS, replace
labmask NIVEL_INS, values(GLOSA_NIVEL_INS)
drop GLOSA_NIVEL_INS

********************************************************************************
* ACTIVIDAD:
destring ACTIVIDAD, replace
labmask ACTIVIDAD, values(GLOSA_ACTIVIDAD)
drop GLOSA_ACTIVIDAD

********************************************************************************
* OCUPACION:
* Pendiente...


********************************************************************************
* CATEGORIA:
* Pendiente...


********************************************************************************
* LOCAL_DEF:
destring LOCAL_DEF, replace
labmask LOCAL_DEF, values(GLOSA_LOCAL_DEF)
drop GLOSA_LOCAL_DEF

********************************************************************************
* REG_RES:
destring REG_RES, replace
labmask REG_RES, values(GLOSA_REG_RES)
drop GLOSA_REG_RES

********************************************************************************
* SERV_RES:
destring SERV_RES, replace
labmask SERV_RES, values(GLOSA_SERV_RES)
drop GLOSA_SERV_RES

********************************************************************************
* COMUNA:
destring COMUNA, replace
labmask COMUNA, values(GLOSA_COMUNA_RESIDENCIA)
drop GLOSA_COMUNA_RESIDENCIA

********************************************************************************
* URBANO_RURAL:
destring URBANO_RURAL, replace
label def URBANO_RURAL 1 "Urbano" 2 "Rural"
label val URBANO_RURAL URBANO_RURAL

********************************************************************************
* DIAG1 y GLOSA_SUBCATEGORIA_DIAG1:
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
gen _GLOSA_SUBCATEGORIA_DIAG1 = DIAG1
order _GLOSA_SUBCATEGORIA_DIAG1, after(GLOSA_SUBCATEGORIA_DIAG1)
compress _GLOSA_SUBCATEGORIA_DIAG1

* store original variable label in a local macro:
local varlabel : variable label GLOSA_SUBCATEGORIA_DIAG1

* store list of notes of original label in local macros:
local char_list : char GLOSA_SUBCATEGORIA_DIAG1[]
foreach c of local char_list {
	local GLOSA_SUBCATEGORIA_DIAG1_`c' : char GLOSA_SUBCATEGORIA_DIAG1[`c']
	display "`GLOSA_SUBCATEGORIA_DIAG1_`c''"
}

* remove blanks from original glosa:
replace GLOSA_SUBCATEGORIA_DIAG1 = ustrtrim(stritrim(GLOSA_SUBCATEGORIA_DIAG1))

* assign values in string glosa as value labels to numeric glosa:
labmask _GLOSA_SUBCATEGORIA_DIAG1, values(GLOSA_SUBCATEGORIA_DIAG1) // very long process more than 30m on a i7 machine

* drop original:
drop GLOSA_SUBCATEGORIA_DIAG1

* rename copy as original and apply variable label:
rename _GLOSA_SUBCATEGORIA_DIAG1 GLOSA_SUBCATEGORIA_DIAG1
label var GLOSA_SUBCATEGORIA_DIAG1 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`GLOSA_SUBCATEGORIA_DIAG1_`c''") == . {
		notes GLOSA_SUBCATEGORIA_DIAG1: `GLOSA_SUBCATEGORIA_DIAG1_`c''
	}
}

********************************************************************************
* CODIGO_CATEGORIA_DIAG1 y GLOSA_CATEGORIA_DIAG1:
* encode original into new numeric variable (and organize right after original):
encode CODIGO_CATEGORIA_DIAG1, gen(_CODIGO_CATEGORIA_DIAG1)
order _CODIGO_CATEGORIA_DIAG1, after(CODIGO_CATEGORIA_DIAG1)
compress _CODIGO_CATEGORIA_DIAG1

* store original variable label in a local macro:
local varlabel : variable label CODIGO_CATEGORIA_DIAG1

* store list of notes of original label in local macros:
local char_list : char CODIGO_CATEGORIA_DIAG1[]
foreach c of local char_list {
	local CODIGO_CATEGORIA_DIAG1_`c' : char CODIGO_CATEGORIA_DIAG1[`c']
	display "`CODIGO_CATEGORIA_DIAG1_`c''"
}

* drop original:
drop CODIGO_CATEGORIA_DIAG1

* rename copy as original and apply variable label:
rename _CODIGO_CATEGORIA_DIAG1 CODIGO_CATEGORIA_DIAG1
label var CODIGO_CATEGORIA_DIAG1 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`CODIGO_CATEGORIA_DIAG1_`c''") == . {
		notes CODIGO_CATEGORIA_DIAG1: `CODIGO_CATEGORIA_DIAG1_`c''
	}
}

* create copy of numeric variable as numeric glosa:
gen _GLOSA_CATEGORIA_DIAG1 = CODIGO_CATEGORIA_DIAG1
order _GLOSA_CATEGORIA_DIAG1, after(GLOSA_CATEGORIA_DIAG1)
compress _GLOSA_CATEGORIA_DIAG1

* store original variable label in a local macro:
local varlabel : variable label GLOSA_CATEGORIA_DIAG1

* store list of notes of original label in local macros:
local char_list : char GLOSA_CATEGORIA_DIAG1[]
foreach c of local char_list {
	local GLOSA_CATEGORIA_DIAG1_`c' : char GLOSA_CATEGORIA_DIAG1[`c']
	display "`GLOSA_CATEGORIA_DIAG1_`c''"
}

* remove blanks from original glosa:
replace GLOSA_CATEGORIA_DIAG1 = ustrtrim(stritrim(GLOSA_CATEGORIA_DIAG1))

* assign values in string glosa as value labels to numeric glosa:
labmask _GLOSA_CATEGORIA_DIAG1, values(GLOSA_CATEGORIA_DIAG1)

* drop original:
drop GLOSA_CATEGORIA_DIAG1

* rename copy as original and apply variable label:
rename _GLOSA_CATEGORIA_DIAG1 GLOSA_CATEGORIA_DIAG1
label var GLOSA_CATEGORIA_DIAG1 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`GLOSA_CATEGORIA_DIAG1_`c''") == . {
		notes GLOSA_CATEGORIA_DIAG1: `GLOSA_CATEGORIA_DIAG1_`c''
	}
}

********************************************************************************
* CODIGO_GRUPO_DIAG1 y GLOSA_GRUPO_DIAG1:
* encode original into new numeric variable (and organize right after original):
encode CODIGO_GRUPO_DIAG1, gen(_CODIGO_GRUPO_DIAG1)
order _CODIGO_GRUPO_DIAG1, after(CODIGO_GRUPO_DIAG1)
compress _CODIGO_GRUPO_DIAG1

* store original variable label in a local macro:
local varlabel : variable label CODIGO_GRUPO_DIAG1

* store list of notes of original label in local macros:
local char_list : char CODIGO_GRUPO_DIAG1[]
foreach c of local char_list {
	local CODIGO_GRUPO_DIAG1_`c' : char CODIGO_GRUPO_DIAG1[`c']
	display "`CODIGO_GRUPO_DIAG1_`c''"
}

* drop original:
drop CODIGO_GRUPO_DIAG1

* rename copy as original and apply variable label:
rename _CODIGO_GRUPO_DIAG1 CODIGO_GRUPO_DIAG1
label var CODIGO_GRUPO_DIAG1 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`CODIGO_GRUPO_DIAG1_`c''") == . {
		notes CODIGO_GRUPO_DIAG1: `CODIGO_GRUPO_DIAG1_`c''
	}
}

* create copy of numeric variable as numeric glosa:
gen _GLOSA_GRUPO_DIAG1 = CODIGO_GRUPO_DIAG1
order _GLOSA_GRUPO_DIAG1, after(GLOSA_GRUPO_DIAG1)
compress _GLOSA_GRUPO_DIAG1

* store original variable label in a local macro:
local varlabel : variable label GLOSA_GRUPO_DIAG1

* store list of notes of original label in local macros:
local char_list : char GLOSA_GRUPO_DIAG1[]
foreach c of local char_list {
	local GLOSA_GRUPO_DIAG1_`c' : char GLOSA_GRUPO_DIAG1[`c']
	display "`GLOSA_GRUPO_DIAG1_`c''"
}

* remove blanks from original glosa:
replace GLOSA_GRUPO_DIAG1 = ustrtrim(stritrim(GLOSA_GRUPO_DIAG1))

* assign values in string glosa as value labels to numeric glosa:
labmask _GLOSA_GRUPO_DIAG1, values(GLOSA_GRUPO_DIAG1)

* drop original:
drop GLOSA_GRUPO_DIAG1

* rename copy as original and apply variable label:
rename _GLOSA_GRUPO_DIAG1 GLOSA_GRUPO_DIAG1
label var GLOSA_GRUPO_DIAG1 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`GLOSA_GRUPO_DIAG1_`c''") == . {
		notes GLOSA_GRUPO_DIAG1: `GLOSA_GRUPO_DIAG1_`c''
	}
}

********************************************************************************
* CAPITULO_DIAG1 y GLOSA_CAPITULO_DIAG1:
* encode original into new numeric variable (and organize right after original):
encode CAPITULO_DIAG1, gen(_CAPITULO_DIAG1)
order _CAPITULO_DIAG1, after(CAPITULO_DIAG1)
compress _CAPITULO_DIAG1

* store original variable label in a local macro:
local varlabel : variable label CAPITULO_DIAG1

* store list of notes of original label in local macros:
local char_list : char CAPITULO_DIAG1[]
foreach c of local char_list {
	local CAPITULO_DIAG1_`c' : char CAPITULO_DIAG1[`c']
	display "`CAPITULO_DIAG1_`c''"
}

* drop original:
drop CAPITULO_DIAG1

* rename copy as original and apply variable label:
rename _CAPITULO_DIAG1 CAPITULO_DIAG1
label var CAPITULO_DIAG1 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`CAPITULO_DIAG1_`c''") == . {
		notes CAPITULO_DIAG1: `CAPITULO_DIAG1_`c''
	}
}

* create copy of numeric variable as numeric glosa:
gen _GLOSA_CAPITULO_DIAG1 = CAPITULO_DIAG1
order _GLOSA_CAPITULO_DIAG1, after(GLOSA_CAPITULO_DIAG1)
compress _GLOSA_CAPITULO_DIAG1

* store original variable label in a local macro:
local varlabel : variable label GLOSA_CAPITULO_DIAG1

* store list of notes of original label in local macros:
local char_list : char GLOSA_CAPITULO_DIAG1[]
foreach c of local char_list {
	local GLOSA_CAPITULO_DIAG1_`c' : char GLOSA_CAPITULO_DIAG1[`c']
	display "`GLOSA_CAPITULO_DIAG1_`c''"
}

* remove blanks from original glosa:
replace GLOSA_CAPITULO_DIAG1 = ustrtrim(stritrim(GLOSA_CAPITULO_DIAG1))

* assign values in string glosa as value labels to numeric glosa:
labmask _GLOSA_CAPITULO_DIAG1, values(GLOSA_CAPITULO_DIAG1)

* drop original:
drop GLOSA_CAPITULO_DIAG1

* rename copy as original and apply variable label:
rename _GLOSA_CAPITULO_DIAG1 GLOSA_CAPITULO_DIAG1
label var GLOSA_CAPITULO_DIAG1 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`GLOSA_CAPITULO_DIAG1_`c''") == . {
		notes GLOSA_CAPITULO_DIAG1: `GLOSA_CAPITULO_DIAG1_`c''
	}
}

********************************************************************************
* DIAG2 y GLOSA_SUBCATEGORIA_DIAG2:
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
gen _GLOSA_SUBCATEGORIA_DIAG2 = DIAG2
order _GLOSA_SUBCATEGORIA_DIAG2, after(GLOSA_SUBCATEGORIA_DIAG2)
compress _GLOSA_SUBCATEGORIA_DIAG2

* store original variable label in a local macro:
local varlabel : variable label GLOSA_SUBCATEGORIA_DIAG2

* store list of notes of original label in local macros:
local char_list : char GLOSA_SUBCATEGORIA_DIAG2[]
foreach c of local char_list {
	local GLOSA_SUBCATEGORIA_DIAG2_`c' : char GLOSA_SUBCATEGORIA_DIAG2[`c']
	display "`GLOSA_SUBCATEGORIA_DIAG2_`c''"
}

* remove blanks from original glosa:
replace GLOSA_SUBCATEGORIA_DIAG2 = ustrtrim(stritrim(GLOSA_SUBCATEGORIA_DIAG2))

* assign values in string glosa as value labels to numeric glosa:
labmask _GLOSA_SUBCATEGORIA_DIAG2, values(GLOSA_SUBCATEGORIA_DIAG2) // very long process more than 30m on a i7 machine

* drop original:
drop GLOSA_SUBCATEGORIA_DIAG2

* rename copy as original and apply variable label:
rename _GLOSA_SUBCATEGORIA_DIAG2 GLOSA_SUBCATEGORIA_DIAG2
label var GLOSA_SUBCATEGORIA_DIAG2 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`GLOSA_SUBCATEGORIA_DIAG2_`c''") == . {
		notes GLOSA_SUBCATEGORIA_DIAG2: `GLOSA_SUBCATEGORIA_DIAG2_`c''
	}
}

********************************************************************************
* CODIGO_CATEGORIA_DIAG2 y GLOSA_CATEGORIA_DIAG2:
* encode original into new numeric variable (and organize right after original):
encode CODIGO_CATEGORIA_DIAG2, gen(_CODIGO_CATEGORIA_DIAG2)
order _CODIGO_CATEGORIA_DIAG2, after(CODIGO_CATEGORIA_DIAG2)
compress _CODIGO_CATEGORIA_DIAG2

* store original variable label in a local macro:
local varlabel : variable label CODIGO_CATEGORIA_DIAG2

* store list of notes of original label in local macros:
local char_list : char CODIGO_CATEGORIA_DIAG2[]
foreach c of local char_list {
	local CODIGO_CATEGORIA_DIAG2_`c' : char CODIGO_CATEGORIA_DIAG2[`c']
	display "`CODIGO_CATEGORIA_DIAG2_`c''"
}

* drop original:
drop CODIGO_CATEGORIA_DIAG2

* rename copy as original and apply variable label:
rename _CODIGO_CATEGORIA_DIAG2 CODIGO_CATEGORIA_DIAG2
label var CODIGO_CATEGORIA_DIAG2 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`CODIGO_CATEGORIA_DIAG2_`c''") == . {
		notes CODIGO_CATEGORIA_DIAG2: `CODIGO_CATEGORIA_DIAG2_`c''
	}
}

* create copy of numeric variable as numeric glosa:
gen _GLOSA_CATEGORIA_DIAG2 = CODIGO_CATEGORIA_DIAG2
order _GLOSA_CATEGORIA_DIAG2, after(GLOSA_CATEGORIA_DIAG2)
compress _GLOSA_CATEGORIA_DIAG2

* store original variable label in a local macro:
local varlabel : variable label GLOSA_CATEGORIA_DIAG2

* store list of notes of original label in local macros:
local char_list : char GLOSA_CATEGORIA_DIAG2[]
foreach c of local char_list {
	local GLOSA_CATEGORIA_DIAG2_`c' : char GLOSA_CATEGORIA_DIAG2[`c']
	display "`GLOSA_CATEGORIA_DIAG2_`c''"
}

* remove blanks from original glosa:
replace GLOSA_CATEGORIA_DIAG2 = ustrtrim(stritrim(GLOSA_CATEGORIA_DIAG2))

* assign values in string glosa as value labels to numeric glosa:
labmask _GLOSA_CATEGORIA_DIAG2, values(GLOSA_CATEGORIA_DIAG2)

* drop original:
drop GLOSA_CATEGORIA_DIAG2

* rename copy as original and apply variable label:
rename _GLOSA_CATEGORIA_DIAG2 GLOSA_CATEGORIA_DIAG2
label var GLOSA_CATEGORIA_DIAG2 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`GLOSA_CATEGORIA_DIAG2_`c''") == . {
		notes GLOSA_CATEGORIA_DIAG2: `GLOSA_CATEGORIA_DIAG2_`c''
	}
}

********************************************************************************
* CODIGO_GRUPO_DIAG2 y GLOSA_GRUPO_DIAG2:
* encode original into new numeric variable (and organize right after original):
encode CODIGO_GRUPO_DIAG2, gen(_CODIGO_GRUPO_DIAG2)
order _CODIGO_GRUPO_DIAG2, after(CODIGO_GRUPO_DIAG2)
compress _CODIGO_GRUPO_DIAG2

* store original variable label in a local macro:
local varlabel : variable label CODIGO_GRUPO_DIAG2

* store list of notes of original label in local macros:
local char_list : char CODIGO_GRUPO_DIAG2[]
foreach c of local char_list {
	local CODIGO_GRUPO_DIAG2_`c' : char CODIGO_GRUPO_DIAG2[`c']
	display "`CODIGO_GRUPO_DIAG2_`c''"
}

* drop original:
drop CODIGO_GRUPO_DIAG2

* rename copy as original and apply variable label:
rename _CODIGO_GRUPO_DIAG2 CODIGO_GRUPO_DIAG2
label var CODIGO_GRUPO_DIAG2 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`CODIGO_GRUPO_DIAG2_`c''") == . {
		notes CODIGO_GRUPO_DIAG2: `CODIGO_GRUPO_DIAG2_`c''
	}
}

* create copy of numeric variable as numeric glosa:
gen _GLOSA_GRUPO_DIAG2 = CODIGO_GRUPO_DIAG2
order _GLOSA_GRUPO_DIAG2, after(GLOSA_GRUPO_DIAG2)
compress _GLOSA_GRUPO_DIAG2

* store original variable label in a local macro:
local varlabel : variable label GLOSA_GRUPO_DIAG2

* store list of notes of original label in local macros:
local char_list : char GLOSA_GRUPO_DIAG2[]
foreach c of local char_list {
	local GLOSA_GRUPO_DIAG2_`c' : char GLOSA_GRUPO_DIAG2[`c']
	display "`GLOSA_GRUPO_DIAG2_`c''"
}

* remove blanks from original glosa:
replace GLOSA_GRUPO_DIAG2 = ustrtrim(stritrim(GLOSA_GRUPO_DIAG2))

* assign values in string glosa as value labels to numeric glosa:
labmask _GLOSA_GRUPO_DIAG2, values(GLOSA_GRUPO_DIAG2)

* drop original:
drop GLOSA_GRUPO_DIAG2

* rename copy as original and apply variable label:
rename _GLOSA_GRUPO_DIAG2 GLOSA_GRUPO_DIAG2
label var GLOSA_GRUPO_DIAG2 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`GLOSA_GRUPO_DIAG2_`c''") == . {
		notes GLOSA_GRUPO_DIAG2: `GLOSA_GRUPO_DIAG2_`c''
	}
}

********************************************************************************
* CAPITULO_DIAG2 y GLOSA_CAPITULO_DIAG2:
* encode original into new numeric variable (and organize right after original):
encode CAPITULO_DIAG2, gen(_CAPITULO_DIAG2)
order _CAPITULO_DIAG2, after(CAPITULO_DIAG2)
compress _CAPITULO_DIAG2

* store original variable label in a local macro:
local varlabel : variable label CAPITULO_DIAG2

* store list of notes of original label in local macros:
local char_list : char CAPITULO_DIAG2[]
foreach c of local char_list {
	local CAPITULO_DIAG2_`c' : char CAPITULO_DIAG2[`c']
	display "`CAPITULO_DIAG2_`c''"
}

* drop original:
drop CAPITULO_DIAG2

* rename copy as original and apply variable label:
rename _CAPITULO_DIAG2 CAPITULO_DIAG2
label var CAPITULO_DIAG2 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`CAPITULO_DIAG2_`c''") == . {
		notes CAPITULO_DIAG2: `CAPITULO_DIAG2_`c''
	}
}

* create copy of numeric variable as numeric glosa:
gen _GLOSA_CAPITULO_DIAG2 = CAPITULO_DIAG2
order _GLOSA_CAPITULO_DIAG2, after(GLOSA_CAPITULO_DIAG2)
compress _GLOSA_CAPITULO_DIAG2

* store original variable label in a local macro:
local varlabel : variable label GLOSA_CAPITULO_DIAG2

* store list of notes of original label in local macros:
local char_list : char GLOSA_CAPITULO_DIAG2[]
foreach c of local char_list {
	local GLOSA_CAPITULO_DIAG2_`c' : char GLOSA_CAPITULO_DIAG2[`c']
	display "`GLOSA_CAPITULO_DIAG2_`c''"
}

* remove blanks from original glosa:
replace GLOSA_CAPITULO_DIAG2 = ustrtrim(stritrim(GLOSA_CAPITULO_DIAG2))

* assign values in string glosa as value labels to numeric glosa:
labmask _GLOSA_CAPITULO_DIAG2, values(GLOSA_CAPITULO_DIAG2)

* drop original:
drop GLOSA_CAPITULO_DIAG2

* rename copy as original and apply variable label:
rename _GLOSA_CAPITULO_DIAG2 GLOSA_CAPITULO_DIAG2
label var GLOSA_CAPITULO_DIAG2 "`varlabel'"

* reapply notes:
foreach c of local char_list {
	if real("`GLOSA_CAPITULO_DIAG2_`c''") == . {
		notes GLOSA_CAPITULO_DIAG2: `GLOSA_CAPITULO_DIAG2_`c''
	}
}

********************************************************************************
* AT_MEDICA:
destring AT_MEDICA, replace
labmask AT_MEDICA, values(GLOSA_AT_MEDICA)
drop GLOSA_AT_MEDICA

********************************************************************************
* CAL_MEDICO:
destring CAL_MEDICO, replace
labmask CAL_MEDICO, values(GLOSA_CAL_MEDICO)
drop GLOSA_CAL_MEDICO

********************************************************************************
* FUND_CAUSA:
destring FUND_CAUSA, replace
labmask FUND_CAUSA, values(GLOSA_FUND_CAUSA)
drop GLOSA_FUND_CAUSA

********************************************************************************
* COD_MENOR:
* Pendiente... (inconsistencies with GLOSA)


********************************************************************************
* NUTRITIVO:
destring NUTRITIVO, replace
labmask NUTRITIVO, values(GLOSA_NUTRITIVO)
drop GLOSA_NUTRITIVO

********************************************************************************
* EST_CIV_MADRE:
destring EST_CIV_MADRE, replace
labmask EST_CIV_MADRE, values(GLOSA_EST_CIV_MADRE)
drop GLOSA_EST_CIV_MADRE

********************************************************************************
* ACTIV_MADRE:
destring ACTIV_MADRE, replace
labmask ACTIV_MADRE, values(GLOSA_ACTIV_MADRE)
drop GLOSA_ACTIV_MADRE

********************************************************************************
* OCUPA_MADRE:
* Pending...


********************************************************************************
* CATEG_MADRE:
* Pending...


********************************************************************************
* NIVEL_MADRE:
destring NIVEL_MADRE, replace
labmask NIVEL_MADRE, values(GLOSA_NIVEL_MADRE)
drop GLOSA_NIVEL_MADRE

********************************************************************************
* PARTO_ABORTO:
destring PARTO_ABORTO, replace
labmask PARTO_ABORTO, values(GLOSA_PARTO_ABORTO)
drop GLOSA_PARTO_ABORTO

********************************************************************************
* ACTIV_PADRE:
destring ACTIV_PADRE, replace
labmask ACTIV_PADRE, values(GLOSA_ACTIV_PADRE)
drop GLOSA_ACTIV_PADRE

********************************************************************************
* OCUPA_PADRE:
* Pending...


********************************************************************************
* CATEG_PADRE:
* Pending...


********************************************************************************
* NIVEL_PADRE:
destring NIVEL_PADRE, replace
labmask NIVEL_PADRE, values(GLOSA_NIVEL_PADRE)
drop GLOSA_NIVEL_PADRE

////////////////////////////////////////////////////////////////////////////////
/* FINAL THINGS */
* Compress, label, and metadata:
compress
label data "Defunciones `=min_ano_def'-`=max_ano_def' en Chile (DEIS/MINSAL) (sin glosas)"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
note: Fuente: https://deis.minsal.cl/#datosabiertos

* Save file:
save "${def_original}_NOGLOSAS.dta", replace

* Save labels to do file:
label save using "$dodir/(auto)labels_${def_original}.do", replace

* Final report:
cls
describe, fullnames
notes _dta

* Close log
log close _all
