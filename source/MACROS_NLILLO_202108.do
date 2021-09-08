clear all
set more off

macro drop _all

* SEED:
global myseed 30081985

* DIRECTORIES
global maindir "C:\Users\nicol\Dropbox\Research Projects\Intergenerational"
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
global nac_original NAC_1992_2018
global def_original DEF_1990_2018

* VARIABLES:
global byear_var ANO_NAC
global dyear_var ANO_DEF

* OTHER:
global id_user_full "Nicolás A. Lillo Bustos"
global id_user_short "Nicolás Lillo"
global id_user_email "niclillo@fen.uchile.cl"
global id_user_prefix "nlillob"

***************
cls
macro dir
