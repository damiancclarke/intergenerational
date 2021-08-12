* Start log:
capture log close _all
log using "$logdir/DEF_REMOVE_DUPSNAMISS", replace text name(DEF_REMOVE_DUPSNAMISS)

* Preamble:
cls
clear all
set more off

* Define source and destination directories:
local sourcedir "$dtadir/DEIS"
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
cd "`sourcedir'"

* Load birth data:
use DEF_1990-2018_NOGLOSAS.dta, clear

* Drop deaths prior to 1992:
drop if ANO_DEF < 1992

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
label data "Defunciones 1990-2018 en Chile (DEIS/MINSAL), Sin Glosas, Sin Duplicados, Sin NAs"
save "`destindir'/DEF_1990-2018_NOGLOSAS_NODUPS_NONAS.dta", replace

* Close log:
log close _all
