* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/NAC_REMOVE_DUPSNAMISS_`datetag'", replace text name(NAC_REMOVE_DUPSNAMISS)

* Preamble:
cls
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load birth data:
use "${nac_original}_NOGLOSAS.dta", clear

* Save database minimum and maximum year:
sum $byear_var
scalar min_ano_nac = r(min)
scalar max_ano_nac = r(max)

* Drop exact duplicates:
duplicates drop

* Drop births with NA IDs:
drop if ID_RECIEN_NACIDO == "NA"

* Drop missing IDs:
drop if ID_RECIEN_NACIDO == ""

* Drop duplicates in terms of ID_RECIEN_NACIDO:
duplicates tag ID_RECIEN_NACIDO, gen(dups_IDRN)
drop if dups_IDRN > 0
drop dups_IDRN

* Compress, label, and save:
compress
label data "Nacimientos `=min_ano_nac'-`=max_ano_nac' en Chile (DEIS/MINSAL), Sin Duplicados, Sin NAs"
save "${nac_original}_NOGLOSAS_NODUPS_NONAS.dta", replace

* Close log:
log close _all
