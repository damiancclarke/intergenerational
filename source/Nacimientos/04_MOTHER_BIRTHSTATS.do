* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/MOTHER_OUTSTATS_`datetag'", replace text name(MOTHER_OUTSTATS)

* Preamble:
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load data:
use NAC_1992_2018_NOGLOSAS_NODUPS_NONAS_WITH_MBDATA.dta, clear

********************************************************************************
* Calculate important scalars:
sum ANO_NAC
scalar max_mother_age = r(max) - r(min)

********************************************************************************

* Sort:
sort ID_MADRE FECHA_NACIMIENTO_SIF

* Tag one observation per mother:
egen tag_id_madre = tag(ID_MADRE) if ID_MADRE != "NA"

* Get birth order:
by ID_MADRE: egen birth_order_by_mother_u = rank(FECHA_NACIMIENTO_SIF) if ID_MADRE != "NA", unique
by ID_MADRE: egen birth_order_by_mother_t = rank(FECHA_NACIMIENTO_SIF) if ID_MADRE != "NA", track

* Calculate some stats:
by ID_MADRE: egen nbirths_by_mother = count(ID_RECIEN_NACIDO) if ID_MADRE != "NA"
by ID_MADRE: egen age_at_first_child = min(EDAD_MADRE) if ID_MADRE != "NA"

* Calculate fertility variables by age for analysis:
forval y = 15/`=max_mother_age' {
	by ID_MADRE: egen mother_had_child_at_`y' = max(cond(EDAD_MADRE == `y', 1, 0, .)) if ID_MADRE != "NA"
	by ID_MADRE: egen mother_nchilds_by_`y' = max(cond(EDAD_MADRE <= `y', birth_order_by_mother_u, ., .)) if ID_MADRE != "NA"
	by ID_MADRE: egen mother_nbirths_by_`y' = max(cond(EDAD_MADRE <= `y', birth_order_by_mother_t, ., .)) if ID_MADRE != "NA"
}

* Recode missing values for some of BLN(2013)'s control variables:
recode TIPO_ATEN NIVEL_MADRE EST_CIV_MADRE (9 = .), ///
	gen(tipo_aten_recode nivel_madre_recode est_civ_madre_recode)

* Mother's education:
gen edmom = CURSO_MADRE if CURSO_MADRE <= 8 & (nivel_madre_recode == 4 | nivel_madre_recode == 5) 
replace edmom = 8 if CURSO_MADRE == 9 & (nivel_madre_recode == 4 | nivel_madre_recode == 5)
replace edmom = 8 + CURSO_MADRE if CURSO_MADRE <= 4 & nivel_madre_recode == 2
replace edmom = 12 if CURSO_MADRE >= 5 & CURSO_MADRE <= 9 & nivel_madre_recode == 2
replace edmom = 8 + CURSO_MADRE if CURSO_MADRE <= 4 & nivel_madre_recode == 3
replace edmom = 12 if CURSO_MADRE >= 5 & CURSO_MADRE <= 9 & nivel_madre_recode == 3
replace edmom = 12 + CURSO_MADRE if nivel_madre_recode == 1
label var edmom "Mother's years of education"
note edmom: Basado en CURSO_MADRE y nivel_madre_recode ($id_user_short on $S_DATE)
sum edmom, d
count if edmom == .

* Calculate education variables by birth, for analysis:
forval b = 1(1)5 {
	by ID_MADRE: egen mother_educ_bychild_`b' = max(cond(birth_order_by_mother_t == `b', edmom, .)) if ID_MADRE != "NA" & nbirths_by_mother >= `b'
}

* Keep one observation per mother:
drop if ID_MADRE == "NA"
keep if tag_id_madre == 1

* Keep relevant variables:
keep ID_MADRE nbirths_by_mother age_at_first_child mother_had_child_at_* mother_nchilds_by_* mother_nbirths_by_* mother_educ_bychild_*

* Rename variables:
rename ID_MADRE ID_RECIEN_NACIDO
label var ID_RECIEN_NACIDO ""
rename nbirths_by_mother nbirths
foreach var of varlist mother_* {
	rename `var' `=subinstr("`var'", "mother_", "", .)'
}

* Label variables:
label var nbirths "Total number of births 2001-2018 (women only)"
label var age_at_first_child "Age at first child (women only)"

foreach var of varlist had_child_at_* {
	local y = word(subinstr("`var'", "_", " ", .), -1)
	label var `var' "=1 if person had a child at age `y'"
}

foreach var of varlist nchilds_by_* {
	local y = word(subinstr("`var'", "_", " ", .), -1)
	label var `var' "Number of children by age `y'"
}

foreach var of varlist nbirths_by_* {
	local y = word(subinstr("`var'", "_", " ", .), -1)
	label var `var' "Number of births by age `y'"
}

foreach var of varlist educ_bychild_* {
	local b = word(subinstr("`var'", "_", " ", .), -1)
	label var `var' "Years of schooling by birth of child `b'"
}

* Compress, label, sign, and save:
compress
label data "Motherhood outcomes"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save "MOTHER_OUTSTATS.dta", replace

********************************************************************************
//// Merge mother's outcome data back to main dataset ////

* Load full birth data (not including duplicates and NAs):
use NAC_1992_2018_NOGLOSAS_NODUPS_NONAS_WITH_MBDATA.dta, clear

* Perform merge:
merge 1:1 ID_RECIEN_NACIDO using "MOTHER_OUTSTATS.dta", ///
	gen(mrg_mostats2main) keep(match master)

* label merge variable:
label var mrg_mostats2main "Merge 1:1 ID_RECIEN_NACIDO using MOTHER_OUTSTATS.dta"

* Compress, label, sign, and save:
compress
label data "Nacimientos 92-18 Chile (DEIS) -Glosas +bdata madre +outcomes maternidad"
notes drop _dta
note: Last modified by: $id_user_full ($id_user_email)
note: Last modification timestamp: $S_DATE at $S_TIME
save "NAC_1992_2018_NOGLOSAS_NODUPS_NONAS_WITH_MBDATA_MOSTATS.dta", replace

* Close log
log close _all
