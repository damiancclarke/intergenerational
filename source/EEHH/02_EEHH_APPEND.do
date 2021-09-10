* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/EEHH_02_APPEND_`datetag'", text replace name(EEHH_02_APPEND)						  
			 
* Preamble:
cls
clear all
set more off

* Change directory to destination directory:
cd "$dtadir/DEIS"

* Get list of EEHH files:
local files : dir "$dtadir/DEIS" files "EEHH_????.dta", respect

timer on 1
* Append EEHH files: (warning: file sizes sum up to 15.4gb)
append using `files'

* Destring all numeric variables:
destring, replace

* Encode BENEFICIARIO:
encode BENEFICIARIO, gen(_BENEFICIARIO)
order _BENEFICIARIO, after(BENEFICIARIO)
drop BENEFICIARIO
rename _BENEFICIARIO BENEFICIARIO

* Create value labels and apply them:
label def seremi ///
15 "SEREMI De Arica y Parinacota" ///
1 "SEREMI De Tarapacá" ///
2 "SEREMI De Antofagasta" ///
3 "SEREMI De Atacama" ///
4 "SEREMI De Coquimbo" ///
5 "SEREMI De Valparaíso" ///
13 "SEREMI Metropolitana De Santiago" ///
6 "SEREMI Del Libertador B. O´Higgins" ///
7 "SEREMI Del Maule" ///
8 "SEREMI Del Biobío" ///
9 "SEREMI De La Araucanía" ///
14 "SEREMI De Los Rios" ///
10 "SEREMI De Los Lagos" ///
11 "SEREMI De Aisén del Gral.C.Ibañez del Campo" ///
12 "SEREMI De Magallanes  y de La Antártica chilena"
label val SEREMI seremi

label def servicio_de_salud ///
1 "Servicio de Salud Arica" ///
2 "Servicio de Salud Iquique" ///
3 "Servicio de Salud Antofagasta" ///
4 "Servicio de Salud Atacama" ///
5 "Servicio de Salud Coquimbo" ///
6 "Servicio de Salud Valparaíso San Antonio" ///
7 "Servicio de Salud Viña del Mar Quillota" ///
8 "Servicio de Salud Aconcagua" ///
15 "Servicio de Salud Del Libertador B. O´Higgins" ///
16 "Servicio de Salud Del Maule" ///
17 "Servicio de Salud Ñuble" ///
18 "Servicio de Salud Concepción" ///
19 "Servicio de Salud Talcahuano" ///
20 "Servicio de Salud Biobío" ///
28 "Servicio de Salud Arauco" ///
29 "Servicio de Salud Araucanía Norte" ///
21 "Servicio de Salud Araucanía Sur" ///
33 "Servicio de Salud Chiloé" ///
23 "Servicio de Salud Osorno" ///
24 "Servicio de Salud Del Reloncaví" ///
25 "Servicio de Salud Aisén" ///
26 "Servicio de Salud Magallanes" ///
9 "Servicio de Salud Metropolitano Norte" ///
10 "Servicio de Salud Metropolitano Occidente" ///
11 "Servicio de Salud Metropolitano Central" ///
12 "Servicio de Salud Metropolitano Oriente" ///
13 "Servicio de Salud Metropolitano Sur" ///
14 "Servicio de Salud Metropolitano Sur Oriente" ///
22 "Servicio de Salud Valdivia"
label val SERVICIO_DE_SALUD servicio_de_salud

label def sexo ///
1 "Hombre" ///
2 "Mujer" ///
3 "Intersex(Indeterminado)" ///
9 "Desconocido"
label val SEXO sexo

label def tipo_edad ///
1 "años" ///
2 "meses" ///
3 "días" ///
4 "horas"
label val TIPO_EDAD tipo_edad

label def prevision ///
1 "FONASA" ///
2 "ISAPRE" ///
3 "CAPREDENA" ///
4 "DIPRECA" ///
5 "SISA" ///
96 "NINGUNA" ///
99 "DESCONOCIDO"
label val PREVISION prevision

label def modalidad ///
1 "MODALIDAD DE ATENCIÓN INSTITUCIONAL (MAI)" ///
2 "MODALIDAD DE LIBRE ELECCIÓN(MLE)"
label val MODALIDAD modalidad

label def procedencia ///
1 "Unidad de Emergencia (mismo establecimiento)" ///
3 "Atención Especialidades( mismo establecimiento)" ///
4 "Otro Establecimiento" ///
5 "Otra Procedencia" ///
6 "Área de Cirugía Mayor Ambulatoria (mismo establecimiento)" ///
7 "Hospital comunitario o de baja complejidad"
label val PROCEDENCIA procedencia

label def area_funcional_egreso ///
0 "NO EXISTE ACTUALMENTE " ///
10 "ÁREA MÉDICA INDIFERENCIADA" ///
20 "ÁREA QUIRÚRGICA INDIFERENCIADA" ///
110 "MEDICINA BÁSICA" ///
111 "NEUMOLOGÍA" ///
112 "INFECCIOSOS ADULTOS" ///
113 "TRATAMIENTO ANTIALCOHÓLICO" ///
114 "NUTRICIÓN" ///
115 "MEDICINA AGUDOS" ///
116 "AGUDO INDIFERENCIADO" ///
119 "ÁREA MÉDICA QUIRÚRGICA INDIFERENCIADA" ///
120 "CIRUGÍA BÁSICA" ///
121 "CIRUGÍA TÓRAX" ///
122 "CIRUGÍA CARDIOVASCULAR" ///
123 "CIRUGÍA PLÁSTICA-QUEMADOS ADULTOS" ///
124 "CIRUGÍA MÁXILO FACIAL" ///
125 "CIRUGÍA AGUDOS" ///
130 "TRAUMATOLOGÍA Y ORTOPEDIA ADULTOS" ///
131 "TRAUMATOLOGÍA AGUDOS" ///
132 "Traumatología-Ortopedia Indif." ///
140 "CIRUGÍA INFANTIL" ///
141 "CIRUGÍA PARTES BLANDAS INFANTIL" ///
142 "CIRUGÍA PLÁSTICA-QUEMADOS INFANTIL" ///
143 "TRAUMATOLOGÍA Y ORTOPEDIA INFANTIL" ///
144 "CARDIOCIRUGIA INFANTIL" ///
145 "ÁREA QUIRÚRGICA INFANTIL INDIFERENCIADA" ///
150 "PEDIATRÍA INDIFERENCIADA" ///
151 "NEONATOLOGÍA INCUBADORAS" ///
152 "NEONATOLOGÍA CUNAS" ///
153 "LACTANTES" ///
154 "SEGUNDA INFANCIA" ///
155 "INFECCIOSOS NIÑOS" ///
156 "PEDIATRÍA AGUDOS" ///
160 "OBSTETRICIA Y GINECOLOGÍA" ///
161 "OBSTETRICIA" ///
162 "GINECOLOGÍA" ///
170 "DERMATOLOGÍA" ///
180 "NEUROPSIQUIATRÍA INFANTIL" ///
190 "NEUROLOGÍA ADULTO" ///
191 "NEUROLOGÍA ADULTO AGUDOS" ///
200 "NEUROCIRUGÍA INDIFERENCIADO" ///
201 "NEUROCIRUGÍA ADULTO" ///
202 "NEUROCIRUGÍA INFANTIL" ///
210 "PSIQUIATRÍA" ///
211 "PSIQUIATRÍA CORTA ESTADIA" ///
212 "PSIQUIATRÍA CRÓNICO" ///
213 "DESINTOXICACION ALCOHOL Y DROGAS" ///
214 "PSIQUIATRÍA FORENSE MEDIANA COMPLEJIDAD" ///
215 "PSIQUIATRÍA FORENSE ALTA COMPLEJIDAD" ///
216 "PSIQUIATRÍA MEDIANA ESTADÍA" ///
217 "EXTERNALIZACIÓN (Unidad Forense)" ///
218 "UNIDAD EVALUACIÓN DE PERSONAS IMPUTADAS (UEPI)" ///
220 "OFTALMOLOGÍA" ///
230 "ONCOLOGÍA" ///
231 "ONCOLOGÍA ADULTOS" ///
232 "ONCOLOGÍA INFANTIL" ///
240 "OTORRINOLARINGOLOGÍA" ///
250 "UROLOGÍA" ///
260 "MEDICINA FÍSICA Y REHABILITACIÓN" ///
270 "DERIVACIÓN MEDICO QUIRÚRGICO" ///
271 "DERIVACIÓN MEDICO QUIRÚRGICO RESPIRATORIO" ///
280 "TISIOLOGÍA CRÓNICOS" ///
290 "GERIATRÍA" ///
300 "UNID.EMERG.INDIFERENCIADO" ///
301 "UNID.EMERG.ADULTO" ///
302 "UNID.EMERG.NIÑOS" ///
310 "UNIDAD DE CUIDADOS INTENSIVOS (UCI) INDIFERENCIADO" ///
311 "UNIDAD DE CUIDADOS INTENSIVOS (UCI) NEONATOLOGÍA" ///
312 "UNIDAD DE CUIDADOS INTENSIVOS (UCI) ADULTO" ///
313 "UNIDAD DE CUIDADOS INTENSIVOS (UCI) PEDIATRÍA" ///
314 "UNIDAD DE CUIDADOS INTENSIVOS (UCI) CORONARIA" ///
315 "UNIDAD DE CUIDADOS INTENSIVOS (UCI) QUEMADOS" ///
320 "UNIDAD DE TRATAMIENTO INTERMEDIO (UTI) INDIFERENCIADO" ///
321 "UNIDAD DE TRATAMIENTO INTERMEDIO (UTI) MEDICINA" ///
322 "UNIDAD DE TRATAMIENTO INTERMEDIO (UTI) CIRUGÍA" ///
323 "UNIDAD DE TRATAMIENTO INTERMEDIO (UTI) PEDIATRÍA" ///
324 "UNIDAD DE TRATAMIENTO INTERMEDIO (UTI) NEONATOLOGÍA" ///
325 "UNIDAD DE TRATAMIENTO INTERMEDIO (UTI) QUEMADOS" ///
326 "UNIDAD DE TRATAMIENTO INTERMEDIO (UTI) NEUROCIRUGÍA" ///
327 "UNIDAD CORONARIO INTERMEDIO" ///
330 "Área Pensionado" ///
330 "PENSIONADO" ///
331 "PENSIONADO OFTALMOLOGÍA" ///
401 "Área Médica Adulto Cuidados Básicos" ///
402 "Área Médica Adulto Cuidados Medios" ///
403 "Área Médico-Quirúrgico Cuidados Básicos" ///
404 "Área Médico-Quirúrgico Cuidados Medios" ///
405 "Área Cuidados Intensivos Adultos" ///
406 "Área Cuidados Intermedios Adultos" ///
407 "Área Médica Pediátrica Cuidados Básicos" ///
408 "Área Médica Pediátrica Cuidados Medios" ///
409 "Área Médico-Quirúrgico Pediátrica Cuidados Básicos" ///
410 "Área Médico-Quirúrgico Pediátrica Cuidados Medios" ///
411 "Área Cuidados Intensivos Pediátricos" ///
412 "Área Cuidados Intermedios Pediátricos" ///
413 "Área Neonatología Cuidados Básicos" ///
414 "Área Neonatología Cuidados Intensivos" ///
415 "Área Neonatología Cuidados Intermedios" ///
416 "Área Obstetricia" ///
418 "Área Psiquiatría Adulto Corta estadía" ///
419 "Área Psiquiatría Adulto Mediana estadía" ///
420 "Área Psiquiatría Adulto Larga estadía" ///
421 "Área Psiquiatría Infanto-adolescente corta estadía" ///
422 "Área Psiquiatría Infanto-adolescente mediana estadía" ///
423 "Área Psiquiatría Forense Adulto evaluación e inicio tto." ///
424 "Área Psiquiatría Forense Adulto tratamiento" ///
425 "Área Psiquiatría Forense Infanto Adolescente evaluación e inicio tto." ///
426 "Área Psiquiatría Forense Infanto Adolescente tratamiento" ///
427 "Área Sociosanitaria Adulto" ///
428 "Área de Hospitalización de Cuidados Intensivos en Psiquatría Adulto" ///
429 "Área de Hospitalización de Cuidados Intensivos en Psiquatría Infanto Adolescente" ///
999 "INDIFERENCIADO"
label val AREA_FUNCIONAL_EGRESO area_funcional_egreso

label def condicion_egreso ///
1 "Vivo" ///
2 "Fallecido"
label val CONDICION_EGRESO condicion_egreso

label def interv_q ///
1 "Sí" ///
2 "No"
label val INTERV_Q interv_q

label def proced ///
1 "Sí" ///
2 "No"
label val PROCED proced

********************************************************************************
* Label variables:
label var ID_PACIENTE "Identificador único y anónimo del paciente"
label var ESTABLECIMIENTO_SALUD "Código del Establecimiento"
label var PERTENENCIA_SNSS "Tipo de pertenencia (Perteneciente o No perteneciente al SNSS)"
label var SEREMI "Código SEREMI"
label var SERVICIO_DE_SALUD "Código Servicio de salud"
label var SEXO "Código del sexo biologico del paciente"
label var FECHA_NACIMIENTO "Fecha de Nacimiento del paciente"
label var EDAD_CANT "Registro numérico de la edad del paciente al ingreso"
label var TIPO_EDAD "Unidad de Medida de la edad, según modalidad descrita en valores"
label var EDAD_A_OS "Edad en años del paciente al momento del ingreso"
label var PUEBLO_ORIGINARIO "Código del Pueblo originario"
label var PAIS_ORIGEN "Código País de origen"
label var COMUNA_RESIDENCIA "Código comuna de residencia del paciente"
label var REGION_RESIDENCIA "Código región de residencia del paciente"
label var PREVISION "Código de previsión de salud del paciente al momento del ingreso"
label var BENEFICIARIO "Código clase Beneficiario FONASA"
label var MODALIDAD "Código modalidad de Atención FONASA"
label var PROCEDENCIA "Código de procedencia del paciente al momento del ingreso"
label var ANO_EGR "Año Egreso"
label var FECHA_EGR "Fecha de egreso"
label var AREA_FUNCIONAL_EGRESO "Código del nivel de Cuidado o área funcional del que egreso el paciente"
label var DIAS_ESTAD "Días de estadía total"
label var CONDICION_EGRESO "Código de la condición al egreso del paciente"
label var DIAG1 "Código CIE-10 del diagnostico principal"
label var GLOSA_DIAG1 "Glosa del diagnóstico principal"
label var DIAG2 "Código de la causa externa"
label var GLOSA_DIAG2 "Glosa de la causa externa"
label var INTERV_Q "Código Intervención Quirúrgica"
label var CODIGO_INTERV_Q_PPAL "Código FONASA Intervención Quirúrgica Principal"
label var PROCED "Código Procedimiento"
label var CODIGO_PROCED_PPAL "Código FONASA Procedimiento Principal"
********************************************************************************

* Get minimum and maximum EEHH year:
sum $eyear_var
scalar min_ano_eehh = r(min)
scalar max_ano_eehh = r(max)

* Compress, label, sign and save:
compress
label data "Egresos Hospitalarios en Chile, `=min_ano_eehh'-`=max_ano_eehh' (DEIS/MINSAL)"
char _dta[Fuente] "https://deis.minsal.cl/#datosabiertos"
save "${eehh_original}.dta", replace
	
* End timer:
timer off 1
timer list

* Close log:
log close _all
