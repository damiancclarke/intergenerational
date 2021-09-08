* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Start log:
capture log close _all
log using "$logdir/DEF_REMOVE_DUPSNAMISS_`datetag'", replace text name(DEF_REMOVE_DUPSNAMISS)

* Preamble:
clear all
set more off

* Switch to destination directory:
cd "$dtadir/DEIS"

* Load birth data:
use "${def_original}_NOGLOSAS.dta", clear

* Get minimum and maximum death years:
sum $dyear_var
scalar min_ano_def = r(min)
scalar max_ano_def = r(max)

* Drop exact duplicates:
duplicates drop

* Drop births with NA IDs:
drop if ID_FALLECIDO == "NA"

* Drop missing IDs:
drop if ID_FALLECIDO == ""

* Drop duplicates in terms of ID_RECIEN_NACIDO:
duplicates tag ID_FALLECIDO, gen(dups_IDF)
drop if dups_IDF > 0
drop dups_IDF

* Compress, label, and save:
compress
label data "Defunciones `=min_ano_def'-`=max_ano_def' en Chile (DEIS/MINSAL), Sin Glosas, Sin Duplicados, Sin NAs"
save "${def_original}_NOGLOSAS_NODUPS_NONAS.dta", replace

* Close log:
log close _all
