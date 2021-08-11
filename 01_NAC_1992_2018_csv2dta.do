* Preamble:
cls
clear all
set more off

* Start timer:
timer on 1

* Define source and destination directories:
local sourcedir "$rawdata/DEIS/Nacimientos_1992_2018"
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
cd "`destindir'"

* Start log:
capture log close _all
log using "$logdir/NAC_1992_2018_csv2dta", text replace name(NAC_1992_2018_csv2dta)

* Import data (original .csv is 1.3gb, so this step may take a while depending
* on your system)
import delimited "`sourcedir'/NAC_1992_2018.csv", ///
	delimiter(";") varnames(2) case(preserve) ///
	encoding(windows-1252) stringcols(_all)

/* LABEL VARIABLES AND DESTRING ACCORDINGLY */
label var ID_RECIEN_NACIDO "Identificador único y anónimo de recién nacido vivo"
	
destring SEXO, replace
label def SEXO 1 "Hombre" 2 "Mujer" 9 "Indeterminado"
label val SEXO SEXO
label var SEXO "Código del sexo biológico del recién nacido vivo"

destring DIA_NAC MES_NAC ANO_NAC, replace
label var DIA_NAC "Día de la fecha de nacimiento"
label var MES_NAC "Mes de la fecha de nacimiento"
label var ANO_NAC "Año de la fecha de nacimiento"
format ANO_NAC %ty

gen FECHA_NACIMIENTO_SIF = date(FECHA_NACIMIENTO, "DMY")
order FECHA_NACIMIENTO_SIF, after(FECHA_NACIMIENTO)
format FECHA_NACIMIENTO_SIF %td
list FECHA_NACIMIENTO FECHA_NACIMIENTO_SIF in 1/5
drop FECHA_NACIMIENTO
label var FECHA_NACIMIENTO_SIF "Fecha de nacimiento del recién nacido vivo, en relación DIA_NAC/MES_NAC/ANO_NAC"
note FECHA_NACIMIENTO_SIF: Variable en formato interno Stata (SIF)

destring TIPO_PARTO, replace
label def TIPO_PARTO 1 "Simple" 2 "Doble" 3 "Triple" 4 "Otro" 9 "Ignorado"
label val TIPO_PARTO TIPO_PARTO
label var TIPO_PARTO "Tipo de parto"

destring TIPO_ATEN, replace
label def TIPO_ATEN 1 "Médico" 2 "Matrona" 3 "Sin Atención Profesional" 4 "Otro Personal de Salud" 9 "Desconocido"
label val TIPO_ATEN TIPO_ATEN
label var TIPO_ATEN "Código del profesional de salud que realiza la atención del parto"

destring PARTO_LOCAL, replace
label def PARTO_LOCAL 1 "Hospital o Clínica" 2 "Casa Habitación" 3 "Otro" 9 "Ignorado"
label val PARTO_LOCAL PARTO_LOCAL
label var PARTO_LOCAL "Código del lugar donde ocurre el nacimiento"

destring SEMANAS PESO TALLA, replace
label var SEMANAS "Semanas de gestación, al momento del nacimiento"
label var PESO "Peso al nacer en gramos, al momento del nacimiento"
label var TALLA "Talla en centímetros, al momento del nacimiento"

destring EDAD_*, replace
label var EDAD_MADRE "Edad de la madre en años (declarado)"
label var EDAD_PADRE "Edad del padre en años (declarado)"

destring CURSO_*, replace
label var CURSO_MADRE "Último curso de instrucción de la madre."
label var CURSO_PADRE "Último curso de instrucción del padre."

destring NIVEL_*, replace
label def NIVEL_X 1 "Superior" 2 "Medio" 3 "Secundario" 4 "Básico o primario" 5 "Ninguno" 9 "Ignorado"
label val NIVEL_* NIVEL_X
label var NIVEL_PADRE "Código del nivel educacional del padre"
label var NIVEL_MADRE "Código del nivel educacional de la madre"

label var ACTIV_PADRE "Código de la actividad del padre"
label var ACTIV_MADRE "Código de la actividad de la madre"
label var OCUPA_PADRE "Código de ocupación del padre, está condicionado al código de la  actividad"
label var OCUPA_MADRE "Código de ocupación de la madre, está condicionado al código de la  actividad"
label var CATEG_PADRE "Código de la categoría ocupacional del padre (Condicionado a la actividad)"
note CATEG_PADRE: Full label: "Código de la categoría ocupacional del padre. El código  está condicionado al dato de la  actividad" ($id_user_short on $S_DATE)
label var CATEG_MADRE "Código de la categoría ocupacional de la madre (Condicionado a la actividad)"
note CATEG_MADRE: Full label: "Código de la categoría ocupacional de la madre. El código  está condicionado al dato de la  actividad" ($id_user_short on $S_DATE)

notes ACTIV_PADRE: Revisar ($id_user_short on $S_DATE)
notes ACTIV_MADRE: Revisar ($id_user_short on $S_DATE)
notes OCUPA_PADRE: Revisar ($id_user_short on $S_DATE)
notes OCUPA_MADRE: Revisar ($id_user_short on $S_DATE)
notes CATEG_PADRE: Revisar ($id_user_short on $S_DATE)
notes CATEG_MADRE: Revisar ($id_user_short on $S_DATE)

label var ID_MADRE "Identificador único y anónimo de la madre del recién nacido vivo"

destring EST_CIV_MADRE, replace
label def EST_CIV_MADRE 1 "Soltera" 2 "Casada" 3 "Viuda" 4 "Divorciada" ///
	5 "Separada Judicial" 6 "Conviviente Civil" 9 "Ignorado"
label val EST_CIV_MADRE EST_CIV_MADRE
label var EST_CIV_MADRE "Estado civil de la madre al momento del nacimiento del recién nacido (declarado)"

replace NACIONALIDAD_MADRE = strtrim(upper(NACIONALIDAD_MADRE))
replace NACIONALIDAD_MADRE = "1" if NACIONALIDAD_MADRE == "C"
replace NACIONALIDAD_MADRE = "2" if NACIONALIDAD_MADRE == "E"
replace NACIONALIDAD_MADRE = "3" if NACIONALIDAD_MADRE == "N"
destring NACIONALIDAD_MADRE, replace
label def NACIONALIDAD_MADRE 1 "C: Chilena" 2 "E: Extranjera" 3 "N: Nacionalizada"
label val NACIONALIDAD_MADRE NACIONALIDAD_MADRE
label var NACIONALIDAD_MADRE "Nacionalidad de la madre"

label var PAIS_ORIGEN_MADRE "País que informó como origen al momento de solicitar su 1ra cédula (declarada)"
notes PAIS_ORIGEN_MADRE: Pendiente codificar ($id_user_short on $S_DATE)
notes PAIS_ORIGEN_MADRE: Full label: "País que informó como origen al momento de solicitar su primera cédula (declarada)" ($id_user_short on $S_DATE)

destring COMUNA_RESIDENCIA, replace
label var COMUNA_RESIDENCIA "Código de la comuna de residencia de la madre (DPA 2018)"
notes COMUNA_RESIDENCIA: Full label: "Código de la comuna de residencia de la madre, correspondiente la División Político Administrativa 2018 (DPA)." ($id_user_short on $S_DATE)

destring REGION_RESIDENCIA, replace
label var REGION_RESIDENCIA "Código de región de residencia de la madre (DPA 2018)"
notes REGION_RESIDENCIA: Full label: "Código de región de residencia de la madre, correspondiente la División Político Administrativa 2018 (DPA)." ($id_user_short on $S_DATE)

label var GLOSA_COMUNA_RESIDENCIA "Nombre de la comuna de residencia de la madre"
label var GLOSA_REGION_RESIDENCIA "Nombre de región de residencia de la madre"

destring SERV_RES, replace
label var SERV_RES "Código del Servicio de Salud asociado a la residencia de la madre"

label var GLOSA_SERV_RES "Nombre del Servicio de Salud asociado a la residencia de la madre (DPA 2018)"
notes GLOSA_SERV_RES: Full label: "Nombre del Servicio de Salud asociado a la residencia de la madre, correspondiente la División Político Administrativa 2018 (DPA)." ($id_user_short on $S_DATE)

destring URBANO_RURAL, replace
label def URBANO_RURAL 1 "Urbano" 2 "Rural"
label val URBANO_RURAL URBANO_RURAL
label var URBANO_RURAL "Código para identificar el área Urbano Rural"

/* SAVE FILE WITH GLOSAS */
* Compress, label, annotate, and save:
compress
label data "Nacimientos 1992-2018 en Chile (DEIS)"
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
note: Fuente: https://deis.minsal.cl/#datosabiertos
save "`destindir'/NAC_1992_2018.dta", replace

/* SAVE FILE WITHOUT GLOSAS */
* Remove glosa variables and label corresponding variables:
labmask COMUNA_RESIDENCIA, values(GLOSA_COMUNA_RESIDENCIA)
note COMUNA_RESIDENCIA: La etiqueta se generó a partir de la variable GLOSA_COMUNA_RESIDENCIA
drop GLOSA_COMUNA_RESIDENCIA

labmask REGION_RESIDENCIA, values(GLOSA_REGION_RESIDENCIA)
note REGION_RESIDENCIA: La etiqueta se generó a partir de la variable GLOSA_REGION_RESIDENCIA
drop GLOSA_REGION_RESIDENCIA

labmask SERV_RES, values(GLOSA_SERV_RES)
note SERV_RES: La etiqueta se generó a partir de la variable GLOSA_SERV_RES
drop GLOSA_SERV_RES

* Compress, label, annotate, and save:
compress
label data "Nacimientos 1992-2018 en Chile (DEIS) / Sin Glosas"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
note: Fuente: https://deis.minsal.cl/#datosabiertos
save "`destindir'/NAC_1992_2018_NOGLOSAS.dta", replace

* Save labels to do file:
label save using "$labeldos/(auto)labels_NAC_1992_2018.do", replace

* Final report:
cls
describe, fullnames
notes _dta

* Stop timer and list:
timer off 1
timer list 1

* Close log
log close _all
