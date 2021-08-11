* Start log:
capture log close _all
log using "$logdir/NAC_REMOVE_DUPSNAMISS", replace text name(NAC_REMOVE_DUPSNAMISS)

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
use NAC_1992_2018_NOGLOSAS.dta, clear

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
label data "Nacimientos 1992-2018 en Chile (DEIS/MINSAL), Sin Duplicados, Sin NAs"
save "`destindir'/NAC_1992_2018_NOGLOSAS_NODUPS_NONAS.dta", replace

* Close log:
log close _all
