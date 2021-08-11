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


* OTHER:
global id_user_full "Nicolás A. Lillo Bustos"
global id_user_short "Nicolás Lillo"
global id_user_email "niclillo@fen.uchile.cl"
global id_user_prefix "nlillob"

***************
cls
macro dir
