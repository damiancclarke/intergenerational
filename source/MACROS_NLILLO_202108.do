clear all
set more off

macro drop _all

* SEED:
global myseed 30081985

* DIRECTORIES
global maindir "C:/Users/nicol/Dropbox/Research Projects/Intergenerational"
global datamain "$maindir/data"
global dodir "$maindir/dofiles"
global figsdir "$maindir/figures"
global labeldos "$dodir/labels"
global rawdata "$datamain/raw"
global dtadir "$datamain/dta"
global logdir "$maindir/statalogs"
global tbldir "$maindir/textables"

* FILES:
* Raw csvs:
global rawnaccsv "$rawdata/DEIS/Nacimientos_1992_2018/NAC_1992_2018.csv"
global rawdefcsv "$rawdata/DEIS/DEF_1990-2018/DEF_1990-2018.csv"

* Base dtas:
global nac_original NAC_1992_2018
global def_original DEF_1990_2018
global eehh_original EEHH_2001_2019

* Find latest working dataset:
local files : dir "$dtadir/DEIS" files "workingdata*.dta", respect
macro drop _filedates
foreach file of local files {
	local filenoext = subinstr("`file'", ".dta", "", 1)
	local filedate = subinstr("`filenoext'", "workingdata", "", 1)
	local filedatesif = date("`filedate'", "DMY")
	local filedates `filedates' `filedatesif'
}
local filedates : list sort filedates
local lastfiledate = string(real(word("`filedates'", -1)), "%td")
global lastworkdata = "workingdata`lastfiledate'"
macro drop _filenoext _filedate _filedatesif _filedates _lastfiledate _files

* VARIABLES:
global byear_var ANO_NAC
global dyear_var ANO_DEF
global eyear_var ANO_EGRESO

* OTHER:
global id_user_full "Nicolás A. Lillo Bustos"
global id_user_short "Nicolás Lillo"
global id_user_email "niclillo@fen.uchile.cl"
global id_user_prefix "nlillob"

***************
cls
macro dir
