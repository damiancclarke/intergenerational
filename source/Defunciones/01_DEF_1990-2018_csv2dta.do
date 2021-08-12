* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/DEF_csv2dta_`datetag'", text replace name(DEF_csv2dta)

* Preamble:
cls
clear all
set more off

* Define source and destination directories:
local sourcedir "$rawdata/DEIS/DEF_1990-2018"
local destindir "$dtadir/DEIS"

* Switch to destination directory:
cd "`destindir'"

* Import data (original .csv is 1.3gb, so this step may take a while depending
* on your system)
import delimited "`sourcedir'/DEF_1990-2018.csv", ///
	delimiter(";") case(preserve)  bindquote(strict) ///
	encoding(windows-1252) stringcols(_all)

* Label variables:
label var ID_FALLECIDO	"Identificador único y anónimo de la persona fallecida"
label var DIA_DEF	"Día de la fecha de defunción"
label var MES_DEF	"Mes de la fecha de defunción"
label var ANO_DEF	"Año de la fecha de defunción"
label var FECHA_DEF	"DIA_DEF + MES_DEF + ANO_DEF. Fecha de defunción"
label var SEXO	"Código que identifica el sexo biológico"
label var GLOSA_SEXO	"Glosa que identifica el sexo"
label var DIA_NAC	"Día de la fecha de nacimiento del fallecido"
label var MES_NAC	"Mes de la fecha de nacimiento del fallecido"
label var ANO_NAC	"Año de la fecha de nacimiento del fallecido"
label var FECHA_NACIMIENTO	"DIA_NAC + MES_NAC + ANO1_NAC + ANO2_NAC. Fecha de Nacimiento"
label var EDAD_CANT	"Edad cantidad: es la cifra de la edad, esta depende de la unidad en que esté medida"
note EDAD_CANT: Etiqueta completa: Edad cantidad: es la cifra de la edad, esta depende de la unidad en que esté medida (edad_tipo: años, meses, días, horas)"
label var EDAD_TIPO	"Tipo de edad : es la unidad en la que se mide la edad: años, meses, días, horas"
label var GLOSA_EDAD_TIPO	"Glosa tipo de edad"
label var EST_CIVIL	"Código del Estado Civil del fallecido"
label var GLOSA_EST_CIVIL	"Glosa del Estado Civil "
label var CURSO_INS	"Último curso aprobado por la persona fallecida"
label var NIVEL_INS	"Código del nivel de instrucción del fallecido"
note NIVEL_INS: Etiqueta completa: Código del nivel de instrucción del fallecido: indica el Nivel educacional de la persona fallecida según lo indicado en el certificado médico de defunción.
label var GLOSA_NIVEL_INS	"Glosa del nivel de instrucción"
label var ACTIVIDAD	"Código para la condición de actividad"
label var GLOSA_ACTIVIDAD	"Glosa del código de actividad"
label var OCUPACION	"Código de la ocupación. El dato está condicionado al dato de la actividad."
label var GLOSA_OCUPACION	"Glosa del código de ocupación, el cual depende de la variable ACTIVIDAD."
note GLOSA_OCUPACION: Etiqueta completa: Glosa del código de ocupación, el cual depende de la variable ACTIVIDAD. La ocupación se basa en los Grandes Grupos de Actividad de la CIUO 88.
label var CATEGORIA	"Código de la categoría ocupacional."
note CATEGORIA: Etiqueta completa: Código de la categoría ocupacional. El valor está condicionado al dato de la actividad.
label var GLOSA_CATEGORIA	"Glosa del código de la categoría"
label var ANO_INSCR	"Año de la fecha de inscripción de la defunción"
label var LOCAL_DEF	"Código del lugar ocurrencia de la defunción"
label var GLOSA_LOCAL_DEF	"Describe el lugar donde ocurre la defuncón"
label var REG_RES	"Código de la región de residencia del fallecido"
label var GLOSA_REG_RES	"Glosa de la región de residencia"
label var SERV_RES	"Código del Servicio de Salud de residencia del fallecido"
label var GLOSA_SERV_RES	"Glosa del servicio de salud de residencia"
label var COMUNA	"Código de la comuna de residencia del fallecido"
label var GLOSA_COMUNA_RESIDENCIA	"Glosa de la comuna de residencia"
label var URBANO_RURAL	"Residencia de la persona fallecida: Urbano/Rural"
note URBANO_RURAL: Etiqueta completa: Código para definir la zona Urbano o Rural de la residencia de la persona fallecida
label var DIAG1	"Causa básica de defunción en caso de muertes por enfermedades."
note DIAG1: Etiqueta completa: Causa básica de defunción en caso de muertes por enfermedades. En el caso de las muertes por causas externas el DIAG1 corresponde a la naturaleza de la lesión y comprende los cógidos que empiezan con letras S y T. (Desde 1997 se comienza a codificar con la CIE 10)
label var GLOSA_SUBCATEGORIA_DIAG1	"Glosa causa básica de defunción en caso de muertes por enfermedades."
note GLOSA_SUBCATEGORIA_DIAG1: Etiqueta completa: Glosa causa básica de defunción en caso de muertes por enfermedades. En el caso de las muertes por causas externas el DIAG1 corresponde a la naturaleza de la lesión y comprende los cógidos que empiezan con letras S y T. (Desde 1997 se comienza a codificar con la CIE 10)
label var CODIGO_CATEGORIA_DIAG1	"Código causa básica de defunción en caso de muertes por enfermedades."
note CODIGO_CATEGORIA_DIAG1: Etiqueta completa: Código causa básica de defunción en caso de muertes por enfermedades. En el caso de las muertes por causas externas el DIAG1 corresponde a la naturaleza de la lesión y comprende los cógidos que empiezan con letras S y T. (Desde 1997 se comienza a codificar con la CIE 10)
label var GLOSA_CATEGORIA_DIAG1	"Glosa del código causa básica de defunción en caso de muertes por enfermedades."
note GLOSA_CATEGORIA_DIAG1: Etiqueta completa: Glosa del código causa básica de defunción en caso de muertes por enfermedades. En el caso de las muertes por causas externas el DIAG1 corresponde a la naturaleza de la lesión y comprende los cógidos que empiezan con letras S y T. (Desde 1997 se comienza a codificar con la CIE 10)
label var CODIGO_GRUPO_DIAG1	"Código grupo DIAG1 según CIE10"
label var GLOSA_GRUPO_DIAG1	"Glosa código grupo DIAG1 según CIE10"
label var CAPITULO_DIAG1	"Capitulo CIE10 según DIAG1"
label var GLOSA_CAPITULO_DIAG1	"Glosa capitulo CIE10 según DIAG1"
label var DIAG2	"Causa externa de defunción."
note DIAG2: Etiqueta completa: Causa externa de defunción. (Desde 1997 se comienza a codificar con la CIE 10), corresponde a los códigos CIE-10  de la V a la Y
label var GLOSA_SUBCATEGORIA_DIAG2	"Glosa causa básica de defunción en caso de muertes por enfermedades."
note GLOSA_SUBCATEGORIA_DIAG2: Etiqueta completa: Glosa causa básica de defunción en caso de muertes por enfermedades. En el caso de las muertes por causas externas el DIAG2 corresponde a la naturaleza de la lesión y comprende los cógidos que empiezan con letras S y T. (Desde 1997 se comienza a codificar con la CIE 10)
label var CODIGO_CATEGORIA_DIAG2	"Código causa básica de defunción en caso de muertes por enfermedades."
note CODIGO_CATEGORIA_DIAG2: Etiqueta completa: Código causa básica de defunción en caso de muertes por enfermedades. En el caso de las muertes por causas externas el DIAG2 corresponde a la naturaleza de la lesión y comprende los cógidos que empiezan con letras S y T. (Desde 1997 se comienza a codificar con la CIE 10)
label var GLOSA_CATEGORIA_DIAG2	"Glosa del código causa básica de defunción en caso de muertes por enfermedades."
note GLOSA_CATEGORIA_DIAG2: Glosa del código causa básica de defunción en caso de muertes por enfermedades. En el caso de las muertes por causas externas el DIAG2 corresponde a la naturaleza de la lesión y comprende los cógidos que empiezan con letras S y T. (Desde 1997 se comienza a codificar con la CIE 10)
label var CODIGO_GRUPO_DIAG2	"Código grupo DIAG2 según CIE10"
label var GLOSA_GRUPO_DIAG2	"Glosa código grupo DIAG2 según CIE10"
label var CAPITULO_DIAG2	"Capitulo CIE10 según DIAG2"
label var GLOSA_CAPITULO_DIAG2	"Glosa capitulo CIE10 según DIAG2"
label var AT_MEDICA	"Código para identificar si tuvo atención médica"
label var GLOSA_AT_MEDICA	"Glosa Atención Médica"
label var CAL_MEDICO	"Código que identifica la calidad de quién certifica la defunción"
label var GLOSA_CAL_MEDICO	"Glosa de la calidad de quien certifica la defunción"
label var CER_MES	"Mes de la certificación médica"
label var CER_ANO	"Año de la certificación médica"
label var FUND_CAUSA	"Fundamento de la causa de muerte"
label var GLOSA_FUND_CAUSA	"Glosa del Fundamento de la causa de muerte"
label var COD_MENOR	"Código para identificar si el fallecido es menor de 1 año."
label var GLOSA_COD_MENOR	"Glosa del código que identifica si el fallecido es un menor de 1 año"
label var PESO	"Peso al nacer en gramos cuando se trata de muerte de menor de un año"
label var GESTACION	"Edad gestacional en semanas cuando se trata de muerte de menor de un año"
label var NUTRITIVO	"Estado nutritivo previo a la enfermedad (muerte de menor de un año)"
note NUTRITIVO: Etiqueta completa: Estado nutritivo previo a la enfermedad cuando se trata de muerte de menor de un año
label var GLOSA_NUTRITIVO	"Glosa estado nutitivo cuando se trata de muerte de menor de un año"
label var EDAD_MADRE	"Edad de la madre en años cuando se trata de muerte de menor de un año"
label var EST_CIV_MADRE	"Estado civil de la madre cuando se trata de muerte de menor de un año"
label var GLOSA_EST_CIV_MADRE	"Glosa del estado civil de la madre cuando se trata de muerte de menor de un año"
label var ACTIV_MADRE	"Actividad de la madre cuando se trata de muerte de menor de un año"
label var GLOSA_ACTIV_MADRE	"Glosa de la actividad de la madre cuando se trata de muerte de menor de un año"
label var OCUPA_MADRE	"Código ocupación madre cuando se trata de muerte de menor de un año."
note OCUPA_MADRE: Etiqueta completa: Código de la categoría ocupacional de la madre cuando se trata de muerte de menor de un año. El código está condicionado al  dato de la actividad
label var GLOSA_OCUPA_MADRE	"Glosa del ocupación madre cuando se trata de muerte de menor de un año"
note GLOSA_OCUPA_MADRE: Etiqueta completa: Glosa del Código de  ocupación de la madre está condicionado al código de la  actividad cuando se trata de muerte de menor de un año
label var CATEG_MADRE	"Código categoría ocupacional madre, por actividad, muerte de menor de un año."
note CATEG_MADRE: Etiqueta completa: Código categoría ocupacional de la madre. El código está condicionado al dato de la actividad.
label var GLOSA_CATEG_MADRE	"Glosa categoría ocupacional madre, por actividad, muerte de menor de un año."
note GLOSA_CATEG_MADRE: Etiqueta completa: Glosa del Código de la categoría ocupacional de la madre cuando se trata de muerte de menor de un año. El código está condicionado al  dato de la actividad
label var CURSO_MADRE	"Último curso de instrucción de la madre, muerte de menor de un año"
note CURSO_MADRE: Etiqueta completa: Último curso de instrucción de la madre cuando se trata de muerte de menor de un año
label var NIVEL_MADRE	"Código del nivel de instrucción cuando se trata de muerte de menor de un año"
label var GLOSA_NIVEL_MADRE	"Glosa del nivel de instrucción de la madre"
label var HIJ_VIVOS	"Número de hijos vivos cuando se trata de muerte de menor de un año"
label var HIJ_FALLECIDOS	"Número de hijos fallecidos cuando se trata de muerte de menor de un año"
label var HIJ_MORTINATOS	"Número de hijos mortinatos cuando se trata de muerte de menor de un año"
label var HIJ_TOTAL	"Número de Hijos total cuando se trata de muerte de menor de un año"
label var PARTO_ABORTO	"Parto o Aborto cuando se trata de muerte de menor de un año"
label var GLOSA_PARTO_ABORTO	"Glosa de parto o aborto cuando se trata de muerte de menor de un año"
label var DIA_PARTO	"Día del último parto o aborto cuando se trata de muerte de menor de un año"
label var MES_PARTO	"Mes del último parto o aborto cuando se trata de muerte de menor de un año"
label var ANO_PARTO	"Año del último parto o aborto cuando se trata de muerte de menor de un año"
label var FECHA_PARTO	"Fecha de nacimiento/parto cuando se trata de muerte de menor de un año"
label var EDAD_PADRE	"Edad del padre en años cuando se trata de muerte de menor de un año"
label var ACTIV_PADRE	"Actividad del padre cuando se trata de muerte de menor de un año"
label var GLOSA_ACTIV_PADRE	"Glosa de la actividad del padre cuando se trata de muerte de menor de un año"
label var OCUPA_PADRE	"Código de la ocupación del padre está condicionado al dato de la  actividad "
label var GLOSA_OCUPA_PADRE	"Texto ocupación del padre"
label var CATEG_PADRE	"Código de la categoría ocupacional del padre."
note CATEG_PADRE: Etiqueta completa: Código de la categoría ocupacional del padre. El código está condicionado al dato de la actividad.
label var GLOSA_CATEG_PADRE	"Glosa código categoría ocupacional padre, por actividad, muerte menor de un año."
note GLOSA_CATEG_PADRE: Etiqueta completa: Glosa del Código de la categoría ocupacional del padre cuando se trata de muerte de menor de un año. El código  está condicionado al dato de la  actividad
label var CURSO_PADRE	"Último curso de instrucción del padre."
label var NIVEL_PADRE	"Código del nivel de instrucción."
label var GLOSA_NIVEL_PADRE	"Glosa código del nivel de instrucción padre, muerte menor de un año"
note GLOSA_NIVEL_PADRE: Etiqueta completa: Glosa del Código del nivel de instrucción cuando se trata de muerte de menor de un año

	
/* FINAL THINGS */
* Compress, label, and metadata:
compress
label data "Defunciones 1990-2018 en Chile (DEIS/MINSAL)"
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
note: Fuente: https://deis.minsal.cl/#datosabiertos

* Save file:
save "`destindir'/DEF_1990-2018.dta", replace

* Save labels to do file:
label save using "$labeldos/(auto)labels_DEF_1990-2018.do", replace

* Final report:
cls
describe, fullnames
notes _dta

* Close log
log close _all
