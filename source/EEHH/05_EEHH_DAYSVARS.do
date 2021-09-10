* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/EEHH_05_DAYSVARS_`datetag'", replace text name(EEHH_05_DAYSVARS)

* Preamble:
cls
clear all
set more off

* Switch to source directory:
cd "$dtadir/DEIS"

* Load data:
use "${eehh_original}_NODUPS_NONAS_NEWVARS.dta", clear

********************************************************************************
* Extract some important scalars from database:
sum ANO_EGRESO
scalar dbyear1 = r(min)
scalar dbyearT = r(max)

* Max life year of analysis:
gen year_nac_cons = year(fecha_nac_cons)
sum year_nac_cons if mrg_NAC2EEHH_fixed == 3
scalar max_window = dbyearT - r(min)

********************************************************************************
******** Number and days of hospitalization for years 1-15 after birth *********

** Create variables for year 1
* Find date of first birthday:
display "Find date of first birthday:"
gen int birthday01 = mdy(month(fecha_nac_cons), day(fecha_nac_cons), year(fecha_nac_cons) + 1)
replace birthday01 = mdy(2, 28, year(fecha_nac_cons) + 1) if day(fecha_nac_cons) == 29 & month(fecha_nac_cons) == 2 & birthday01 == .
format birthday01 %td
label var birthday01 "Date of birthday 1 (w/ leap year fix)"

* Number of visits starting during year 1:
display "Number of visits starting during year 1:"
gen byte nvsts_y01 = fecha_ingreso >= fecha_nac_cons & fecha_ingreso < birthday01 
label var nvsts_y01 "Number of hospital visits, starting during year 1 after birth"

* Do not count visits if any of the critical dates are missing:
display "Do not count visits if any of the critical dates are missing:"
replace nvsts_y01 = . if birthday01 == . | fecha_ingreso == .

* Do not count visits that begin before birth:
display "Do not count visits that begin before birth:"
replace nvsts_y01 = . if fecha_ingreso < fecha_nac_cons

/*
* Do not count visits for those born too early and year 1 is not fully covered by EEHH database:
display "Do not count visits for those born too early and year 1 is not fully covered by EEHH database:"
replace nvsts_y01 = . if year(fecha_nac_cons) <= dbyear1 - 1 

* Do not count visits for those born too late and haven't lived year 1 fully:
display "Do not count visits for those born too later and haven't lived year 1 fully:"
replace nvsts_y01 = . if birthday01 > mdy(12, 31, dbyearT)
*/

* Days admitted in hospital during year 1:
display "Days admitted in hospital during year 1:"
gen int days_y01 = max(birthday01 - fecha_ingreso, 0) - max(birthday01 - FECHA_EGRESO, 0) if nvsts_y01 != .
label var days_y01 "Days spent hospitalized, during year 1 after birth"

** Create variables for years 2 to the maximum year range:
forval y = 2/`=max_window' {
	local yy = string(`y', "%02.0f")
	local xx = string(`=`y'-1', "%02.0f")
	
	* Find date of birthday `y':
	display "Find date of birthday `y':"
	gen int birthday`yy' = mdy(month(fecha_nac_cons), day(fecha_nac_cons), year(fecha_nac_cons) + `y')
	replace birthday`yy' = mdy(2, 28, year(fecha_nac_cons) + `y') if day(fecha_nac_cons) == 29 & month(fecha_nac_cons) == 2 & birthday`yy' == .
	format birthday`yy' %td
	label var birthday`yy' "Date of birthday `y' (w/ leap year fix)"
	
	* Calculate running sum of days:
	display "Calculate running sum of days:"
	egen int aux_y`xx' = rowtotal(days_y??)
	
	* Number of visits during year `y':
	display "Number of visits during year `y':"
	gen byte nvsts_y`yy' = fecha_ingreso >= birthday`xx' & fecha_ingreso < birthday`yy'
	label var nvsts_y`yy' "Number of hospital visits, starting during year `y' after birth"
	
	* Do not count visits if any of the critical dates are missing:
	display "Do not count visits if any of the critical dates are missing:"
	replace nvsts_y`yy' = . if birthday`yy' == . | fecha_ingreso == .

	* Do not count visits that begin before birth:
	display "Do not count visits that begin before birth:"
	replace nvsts_y`yy' = . if fecha_ingreso < fecha_nac_cons
	
	/*
	* Do not count visits for those born too early and year `y' is not fully covered by EEHH database:
	display "Do not count visits for those born too early and year `y' is not fully covered by EEHH database:"
	replace nvsts_y`yy' = . if year(fecha_nac_cons) <= dbyear1 - `y'
	
	* Do not count visits for those born too late and haven't lived year `y' fully:
	display "Do not count visits for those born too later and haven't lived year `y' fully:"
	replace nvsts_y`yy' = . if birthday`yy' > mdy(12, 31, dbyearT)
	*/
	
	* Days spent in hospital during year `y':
	display "Days spent in hospital during year `y':"
	gen int days_y`yy' = max(birthday`yy' - fecha_ingreso, 0) - max(birthday`yy' - FECHA_EGRESO, 0) - aux_y`xx' if nvsts_y`yy' != .
	label var days_y`yy' "Days spent hospitalized, during year `y' after birth"
}

********************************************************************************
******* Number and days of hospitalization for months 1-12 after birth *********

* Create variables for month 1:
display "Create variables for month 1:"
gen int fecha_month01 = fecha_nac_cons + round(1*365/12)
format fecha_month01 %td
label var fecha_month01 "Date of month 1"

* Number of visits starting during month 1:
display "Number of visits starting during month 1:"
gen byte nvsts_m01 = fecha_ingreso >= fecha_nac_cons & fecha_ingreso < fecha_month01 
label var nvsts_m01 "Number of hospital visits, starting during month 1 after birth"

* Do not count visits if any of the critical dates are missing:
display "Do not count visits if any of the critical dates are missing:"
replace nvsts_m01 = . if fecha_month01 == . | fecha_ingreso == .

* Do not count visits that begin before birth:
display "Do not count visits that begin before birth:"
replace nvsts_m01 = . if fecha_ingreso < fecha_nac_cons

/*
* Do not count visits for those born too early and month 1 is not fully covered by EEHH database:
display "Do not count visits for those born too early and month 1 is not fully covered by EEHH database:"
replace nvsts_m01 = . if mofd(fecha_nac_cons) <= mofd(mdy(1, 1, dbyear1)) - 1

* Do not count visits for those born too late and haven't lived month 1 fully:
display "Do not count visits for those born too late and haven't lived month 1 fully:"
replace nvsts_m01 = . if fecha_month01 > mdy(12, 31, dbyearT)
*/

* Days admitted in hospital during month 1:
display "Days admitted in hospital during month 1:"
gen int days_m01 = max(fecha_month01 - fecha_ingreso, 0) - max(fecha_month01 - FECHA_EGRESO, 0) if nvsts_m01 != .
label var days_m01 "Days spent hospitalized, during month 1 after birth"

* Create variables for months 2 to 12:
forval m = 2/12 {
	local mm = string(`m', "%02.0f")
	local ll = string(`=`m'-1', "%02.0f")
	
	* Find date of month `m':
	display "Find date of month `m':"
	gen int fecha_month`mm' = fecha_nac_cons + round(`m'*365/12)
	format fecha_month`mm' %td
	label var fecha_month`mm' "Date of month `m'"
	
	* Running sum of days:
	display "Find date of month `m':"
	egen int aux_m`ll' = rowtotal(days_m??)
	
	* Number of visits during month `y':
	display "Number of visits during month `y':"
	gen byte nvsts_m`mm' = fecha_ingreso >= fecha_month`ll' & fecha_ingreso < fecha_month`mm' 
	label var nvsts_m`mm' "Number of hospital visits, month `m' after birth"
	
	* Do not count visits if any of the critical dates are missing:
	display "Do not count visits if any of the critical dates are missing:"
	replace nvsts_m`mm' = . if fecha_month`mm' == . | fecha_ingreso == .
	
	* Do not count visits that begin before birth:
	display "Do not count visits that begin before birth:"
	replace nvsts_m`mm' = . if fecha_ingreso < fecha_nac_cons
	
	/*
	* Do not count visits for those born too early and month `m' is not fully covered by EEHH database:
	display "Do not count visits for those born too early and month `m' is not fully covered by EEHH database:"
	replace nvsts_m`mm' = . if mofd(fecha_nac_cons) <= mofd(mdy(1, 1, dbyear1)) - `m'
	
	* Do not count visits for those born too late and haven't lived month `m' fully:
	display "Do not count visits for those born too late and haven't lived month `m' fully:"
	replace nvsts_m`mm' = . if fecha_month`mm' > mdy(12, 31, dbyearT)
	*/
	
	* Days spent in hospital during month `m':
	display "Days spent in hospital during month `m':"
	gen int days_m`mm' = max(fecha_month`mm' - fecha_ingreso, 0) - max(fecha_month`mm' - FECHA_EGRESO, 0) - aux_m`ll' if nvsts_m`mm' != .
	label var days_m`mm' "Days spent hospitalized, during month `m' after birth"
}

********************************************************************************
******* Number and days of hospitalization by cutoff days after birth **********
***************** Bharadwaj, Loken, and Neilson (2013) *************************

* Calculate difference in days between birth and hospital admittance:
gen int diff = fecha_ingreso - fecha_nac_cons if fecha_ingreso != . & fecha_nac_cons != .
replace diff = . if fecha_ingreso - fecha_nac_cons < 0

* Create variables for every 5 days until 30 days after birth:
forval d = 0(5)30 {
	local dd = string(`d', "%02.0f")
	
	* Number of visits starting within `d' days after birth:
	gen nvsts_s`dd' = diff <= `d' if diff >= 0 & diff != .
	label var nvsts_s`dd' "Number of hospital visits, starting within `d' days after birth"
	
	* Days spent hospitalized, for hospitalizations starting within `d' days after birth:
	gen days_s`dd' = DIAS_ESTADA if nvsts_s`dd' == 1
	label var days_s`dd' "Days spent hospitalized, starting within `d' days after birth"
}

********************************************************************************

* Compress, sort, label, sign, and save:
compress
sort ID_PACIENTE orden
label data "EEHH `=dbyear1'-`=dbyearT' en Chile (DEIS/MINSAL), -duplicados/NAs, +nuevas variables, +dias"
notes drop _dta
notes: Last modified on $S_DATE at $S_TIME
save "${eehh_original}_daysvars.dta", replace

* Close log:
log close _all
