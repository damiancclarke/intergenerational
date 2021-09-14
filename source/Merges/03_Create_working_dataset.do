* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/working_dataset_`datetag'", replace text name(working_dataset)

* Preamble:
cls
clear all
set more off

////////////////////////////////////////////////////////////////////////////////
* Go to directory:
cd "$dtadir/DEIS"

* Load data:
use MERGED_HOSPDATS2DEF2NAC.dta, clear

////////////////////////////////////////////////////////////////////////////////
* CREATE NEW VARIABLES:

* Sort by mother ID and birth date:
sort NAC_ID_MADRE NAC_FECHA_NACIMIENTO_SIF

* Get birth order:
by NAC_ID_MADRE: egen birth_order_by_mother_u = rank(NAC_FECHA_NACIMIENTO_SIF) if NAC_ID_MADRE != "NA", unique
by NAC_ID_MADRE: egen birth_order_by_mother_t = rank(NAC_FECHA_NACIMIENTO_SIF) if NAC_ID_MADRE != "NA", track

* Recode missing values for some of BLN(2013)'s control variables:
recode NAC_TIPO_ATEN NAC_NIVEL_MADRE NAC_EST_CIV_MADRE (9 = .), ///
	gen(nac_tipo_aten_recode nac_nivel_madre_recode nac_est_civ_madre_recode)

* Apply value labels to recoded variables:
foreach var of varlist NAC_TIPO_ATEN NAC_NIVEL_MADRE NAC_EST_CIV_MADRE {
	local val_lbl_`var' : value label `var'
	local trgt_var = lower("`var'") + "_recode"
	label values `trgt_var' `val_lbl_`var''
}

* Create dummy for 32 or more weeks of gestation:
gen sem32 = NAC_SEMANAS >= 32 if NAC_SEMANAS != .
label var sem32 "Gestational Weeks >= 32"
label def sem32 0 "Gestational Weeks <= 31" 1 "Gestational Weeks >= 32"
label val sem32 sem32

* Create dummy for 32 or more weeks of gestation (mother):
gen sem32m = NAC_SEMANAS_MADRE >= 32 if NAC_SEMANAS_MADRE != .
label var sem32m "Mother's Gestational Weeks >= 32"
label def sem32m 0 "Mother's Gestational Weeks <= 31" 1 "Mother's Gestational Weeks >= 32"
label val sem32m sem32m

* Create variables related to infant mortality:
gen dias_muerte = DEF_FECHA_DEF_SIF - NAC_FECHA_NACIMIENTO_SIF /*Días vividos antes de morir*/
gen muerte_1a = 1 if dias_muerte <= 365
replace muerte_1a = 0 if (dias_muerte == . | dias_muerte > 365) /*Missing corresponde a nacidos que permanecen vivos*/
tab muerte_1a, m    /*1.453 fallecidos menores de 1 año*/
label var dias_muerte "Days alive before death (missing for living)"
label var muerte_1a "Infant Mortality (death within 1 year of birth)"

* Create variables related to life duration:
gen durlife_days = td(31dec2018) - NAC_FECHA_NACIMIENTO_SIF if mrg_DEF2NAC == 1
replace durlife_days = dias_muerte if mrg_DEF2NAC == 3
label var durlife_days "Days alive up to 31 december 2018"

* Mother's education:
gen edmom = NAC_CURSO_MADRE if NAC_CURSO_MADRE <= 8 & (nac_nivel_madre_recode == 4 | nac_nivel_madre_recode == 5) 
replace edmom = 8 if NAC_CURSO_MADRE == 9 & (nac_nivel_madre_recode == 4 | nac_nivel_madre_recode == 5)
replace edmom = 8 + NAC_CURSO_MADRE if NAC_CURSO_MADRE <= 4 & nac_nivel_madre_recode == 2
replace edmom = 12 if NAC_CURSO_MADRE >= 5 & NAC_CURSO_MADRE <= 9 & nac_nivel_madre_recode == 2
replace edmom = 8 + NAC_CURSO_MADRE if NAC_CURSO_MADRE <= 4 & nac_nivel_madre_recode == 3
replace edmom = 12 if NAC_CURSO_MADRE >= 5 & NAC_CURSO_MADRE <= 9 & nac_nivel_madre_recode == 3
replace edmom = 12 + NAC_CURSO_MADRE if nac_nivel_madre_recode == 1
label var edmom "Años de educación de la madre"
note edmom: Basado en NAC_CURSO_MADRE y nac_nivel_madre_recode ($id_user_short on $S_DATE)
sum edmom, d
count if edmom == .

* BLN2013 exclusions:
gen exclbln13 = 0
replace exclbln13 = 1 if mrg_DEF2NAC == 2 /* dead not in birth dataset */
replace exclbln13 = 1 if NAC_PESO == 1500
replace exclbln13 = 1 if NAC_PESO == 1400
replace exclbln13 = 1 if NAC_PESO == 1600
label var exclbln13 "Exclusions by Bharadwah, Loken, and Neilson (2013)"

* Tag obs. with a "round" birthweight (to control for heaping):
gen round100 = mod(NAC_PESO, 100) == 0 if mod(NAC_PESO, 100)!=.
gen round100m = mod(NAC_PESO_MADRE, 100) == 0 if mod(NAC_PESO_MADRE, 100)!=.
label var round100 "=1 if person's birthweight is a multiple of 100"
label var round100m "=1 if person's mother's birthweight is a multiple of 100"
note round100m: Available only for people born after 2001

* Create new dependent variables:
gen byte dayofweek = dow(NAC_FECHA_NACIMIENTO_SIF)
label var dayofweek "Birth day of the week (Sunday = 0)"
gen byte wkndbirth = (dayofweek == 0 | dayofweek == 6) if dayofweek != .
label var wkndbirth "Birth during weekend (Saturday or Sunday)"
gen byte wkndbirth2 = (dayofweek == 0 | dayofweek == 5 | dayofweek == 6) if dayofweek != .
label var wkndbirth2 "Birth during weekend (Friday, Saturday, or Sunday)"

* Compress newly created variables:
compress

////////////////////////////////////////////////////////////////////////////////
* FIX "NUMBER OF HOSPITAL VISITS" VARIABLES:

* First, yearly:
foreach var of varlist EEHH_nvsts_y* {
	* Get year cutoff from variable name:
	local y = real(word(subinstr(subinstr("`var'", "EEHH_nvsts_y", "", .), "_", " ", .), 1))
	
	* Assign ZERO to children who never visited the hospital 
	* (they don't show up in the EEHH database):
	replace `var' = 0 if `var' == . & mrg_hosp2DEF2NAC == 1
	
	* Assign MISSING to children who did not survive the cutoff:
	replace `var' = . if `var' != . & dias_muerte < `y'*365 & mrg_DEF2NAC == 3
	
	* Assign MISSING to children not old enough by the cutoff:
	replace `var' = . if `var' != . & durlife_days < `y'*365 & mrg_DEF2NAC == 1
}

* Second, monthly:
foreach var of varlist EEHH_nvsts_m* {
	* Get month cutoff from variable name:
	local m = real(word(subinstr(subinstr("`var'", "EEHH_nvsts_m", "", .), "_", " ", .), 1))

	* Assign ZERO to children who never visited the hospital 
	* (they don't show up in the EEHH database):
	replace `var' = 0 if `var' == . & mrg_hosp2DEF2NAC == 1
	
	* Assign MISSING to children who did not survive the cutoff:
	replace `var' = . if `var' != . & dias_muerte < `m'*365/12 & mrg_DEF2NAC == 3
	
	* Assign MISSING to children not old enough by the cutoff:
	replace `var' = . if `var' != . & durlife_days < `m'*365/12 & mrg_DEF2NAC == 1
}

////////////////////////////////////////////////////////////////////////////////
* FIX "DAYS OF HOSPITAL VISITS" VARIABLES:

* First, yearly:
foreach var of varlist EEHH_days_y* {
	* Get year cutoff from variable name:
	local y = real(word(subinstr(subinstr("`var'", "EEHH_days_y", "", .), "_", " ", .), 1))

	* Assign MISSING to sums that exceed 366 days:
	replace `var' = . if `var' > 366 & `var' != .
	
	* Assign MISSING to children who did not survive the cutoff:
	replace `var' = . if `var' != . & dias_muerte < `y'*365 & mrg_DEF2NAC == 3
	
	* Assign MISSING to children not old enough by the cutoff:
	replace `var' = . if `var' != . & durlife_days < `y'*365 & mrg_DEF2NAC == 1
}

foreach var of varlist EEHH_days_m* {
	* Get month cutoff from variable name:
	local m = real(word(subinstr(subinstr("`var'", "EEHH_days_m", "", .), "_", " ", .), 1))

	* Assign MISSING to sums that exceed 31 days:
	replace `var' = . if `var' > 31 & `var' != .
	
	* Assign MISSING to children who did not survive the cutoff:
	replace `var' = . if `var' != . & dias_muerte < `m'*365/12 & mrg_DEF2NAC == 3
	
	* Assign MISSING to children who were born too late to experience the cutoff:
	replace `var' = . if `var' != . & durlife_days < `m'*365/12 & mrg_DEF2NAC == 1
}

* Third, length of early stay:
foreach var of varlist EEHH_days_s* {
	* Assign MISSING to individuals whose visit lasted 0 days:
	replace `var' = . if `var' == 0
	
	* Get cutoff from variable name:
	local d = real(word(subinstr(subinstr("`var'", "EEHH_days_s", "", .), "_", " ", .), 1))
	
	* Assign MISSING to individuals who do not survive the cutoff:
	replace `var' = . if dias_muerte < `d' & mrg_DEF2NAC == 3
	
	* Assign MISSING to individuals who were born too late to experience the cutoff:
	* (these are children born at the very end of our database, and were alive
	* by the last day, December 31, 2018)
	replace `var' = . if durlife_days < `d' & mrg_DEF2NAC == 1
}


////////////////////////////////////////////////////////////////////////////////
* Create variable for cumulative days in and visits to hospital by age 1-15:

* First, organize variables:
order EEHH_nvsts_y?? EEHH_days_y??, after(ID_PACIENTE)

* Second, create variables:
foreach nvsts_var of varlist EEHH_nvsts_y?? {
	* Get year from variable name:
	local yy = subinstr(word(subinstr("`nvsts_var'", "_", " ", .), -1), "y", "", 1)
	local y = real("`yy'")
	
	* Get name of days variable:
	local days_var = subinstr("`nvsts_var'", "nvsts", "days", 1)
	
	* Sum rowwise (automatically assigns 0s to missings, unless all are missing -> assigns missing):
	egen hospdays_by_`yy' = rowtotal(EEHH_days_y01-`days_var'), missing
	label var hospdays_by_`yy' "Days in hospital by age `y'"
	
	egen hospvsts_by_`yy' = rowtotal(EEHH_nvsts_y01-`nvsts_var'), missing
	label var hospvsts_by_`yy' "Hospital admissions by age `y'"
	
	* Assign MISSING to individuals who died before the given age:
	replace hospdays_by_`yy' = . if dias_muerte <= 365*`y' & mrg_DEF2NAC == 3
	replace hospvsts_by_`yy' = . if dias_muerte <= 365*`y' & mrg_DEF2NAC == 3
	
	* Assign MISSING to individuals who are not old enough by the end of 2018:
	replace hospdays_by_`yy' = . if durlife_days < `y'*365 & mrg_DEF2NAC == 1
	replace hospvsts_by_`yy' = . if durlife_days < `y'*365 & mrg_DEF2NAC == 1
	
	**** Version 2 ****
	* Copy original variable:
	gen hospdays2_by_`yy' = hospdays_by_`yy'
	label var hospdays2_by_`yy' "Days in hospital by age `y'"
	note hospdays2_by_`yy': same as hospdays_by_`yy' but excluding 0s and individuals who never visited a hospital.
	
	* Assign MISSING to individuals who never visited the hospital by that age:
	replace hospdays2_by_`yy' = . if hospvsts_by_`yy' == 0
	
	* Assign MISSING to individuals who matched but visit length is 0:
	replace hospdays2_by_`yy' = . if hospdays2_by_`yy' == 0 & hospvsts_by_`yy' > 0 & hospvsts_by_`yy' != .
}

////////////////////////////////////////////////////////////////////////////////
* Fill in and edit fertility variables:

* First, for the dummies 0/1 had child at a certain age:
foreach var of varlist NAC_had_child_at_* {
	* Get age from variable name:
	local y = real(word(subinstr("`var'", "_", " ", .), -1))
	
	* Assign 0 to women in births database but not in mothers database:
	replace `var' = 0 if NAC_SEXO == 2 & `var' == . & NAC_mrg_mostats2main == 1
	
	* Assign missing to women who died before age in variable name:
	replace `var' = . if dias_muerte < `y'*365 & `var' != . & mrg_DEF2NAC == 3
	
	* Assign missing to people who are not old enough by 2018:
	replace `var' = . if durlife_days < `y'*365 & `var' != . & mrg_DEF2NAC == 1
}

* Second, for the count variable number of CHILDREN by a certain age:
foreach var of varlist NAC_nchilds_by_* {
	* Get age from variable name:
	local y = real(word(subinstr("`var'", "_", " ", .), -1))
	
	* Assign 0s to women who have survived up to the given age:
	replace `var' = 0 if NAC_SEXO == 2 & `var' == . & (dias_muerte >= `y'*365 | mrg_DEF2NAC == 1)
	
	* Assign missing to women who died before age in variable name:
	replace `var' = . if dias_muerte < `y'*365 & `var' != . & mrg_DEF2NAC == 3
	
	* Assign missing to people who are not old enough by 2018:
	replace `var' = . if durlife_days < `y'*365 & `var' != . & mrg_DEF2NAC == 1
}

* Second, for the count variable number of BIRTHS by a certain age:
foreach var of varlist NAC_nbirths_by_* {
	* Get age from variable name:
	local y = real(word(subinstr("`var'", "_", " ", .), -1))
	
	* Assign 0s to women who have survived up to the given age:
	replace `var' = 0 if NAC_SEXO == 2 & `var' == . & (dias_muerte >= `y'*365 | mrg_DEF2NAC == 1)
	
	* Assign missing to women who died before age in variable name:
	replace `var' = . if dias_muerte < `y'*365 & `var' != . & mrg_DEF2NAC == 3
	
	* Assign missing to people who are not old enough by 2018:
	replace `var' = . if durlife_days < `y'*365 & `var' != . & mrg_DEF2NAC == 1
}

////////////////////////////////////////////////////////////////////////////////
* Create variables "had a child by a certain age"

foreach at_var of varlist NAC_had_child_at_* {
	* Get age cutoff from variable name:
	local y = real(word(subinstr("`at_var'", "_", " ", .), -1))
	
	* Define new variable name:
	local by_var = subinstr("`at_var'", "_at_", "_by_", 1)
	
	* Create new variable and label:
	gen byte `by_var' = NAC_age_at_first_child <= `y' if NAC_mrg_mostats2main == 3
	label var `by_var' "=1 if woman had a child by age `y'"
	
	* Assign 0 to women who haven't had a child yet:
	replace `by_var' = 0 if NAC_age_at_first_child == . & NAC_mrg_mostats2main == 1 & NAC_SEXO == 2
	
	* Assign missing to people who die before reaching the given age:
	replace `by_var' = . if dias_muerte < `y'*365 & mrg_DEF2NAC == 3
	
	* Assign missing to people who are not old enough by 2018:
	replace `by_var' = . if durlife_days < `y'*365 & mrg_DEF2NAC == 1
}


////////////////////////////////////////////////////////////////////////////////
* Save dataset:
compress
label data "Working dataset $S_DATE"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save `"workingdata`=string(date("$S_DATE", "DMY"), "%td")'.dta"', replace

* Close log:
log close _all
