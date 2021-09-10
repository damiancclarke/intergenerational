* Create date tag:
local today = date("$S_DATE", "DMY")
local datetag = string(year(`today'), "%02.0f") ///
			  + string(month(`today'), "%02.0f") ///
			  + string(day(`today'), "%02.0f")

* Preamble:
clear all
set more off
set scheme s1mono 
graph set window fontface "Times New Roman"

* Declare dependent variable:
global mydepvar NAC_PESO

* Declare abbrev:
global abbrev g2_peso

* Start log:
local logfilename = "${id_user_prefix}_`datetag'_${abbrev}"
capture log close _all
log using "$logdir/`logfilename'", replace text name(masterlog)

* Set graph options:
global gphoptns scheme(lean2) ///
				ytitle("Child's birthweight in grams (2nd generation)") ///
				xtitle("Mother's birthweight in grams (1st generation)") ///
				legend(off) ylabel(2800(200)3800) xlabel(1100(100)1900)

////////////////////////////////////////////////////////////////////////////////
* Change to directory:
cd "$dtadir/DEIS"

* Load data:
use "${lastworkdata}.dta", clear

* Base sample for second generation:
/* 
-> children for whom we have mother's birth data:  NAC_mrg_mbdata2main == 3
-> children of mothers who were between 15 and 45 years old at time of birth: 
		NAC_EDAD_MADRE >= 15 & NAC_EDAD_MADRE <= 45
-> children born from 2007 onwards (only 12 births between 2001-2006 given above
 constraints): NAC_ANO_NAC >= 2007
*/
gen g2smpl = NAC_mrg_mbdata2main == 3 ///
	& NAC_EDAD_MADRE >= 15 & NAC_EDAD_MADRE <= 45 ///
	& NAC_ANO_NAC >= 2007

* Show birth years for cohorts in sample:
tab NAC_ANO_NAC g2smpl

* Show birth years for the MOTHERS in the sample:
tab NAC_ANO_NAC_MADRE g2smpl if birth_order_by_mother_u == 1

* Summarize dependent variable by birth year, restricted to sample:
tabstat $mydepvar if g2smpl == 1, by(NAC_ANO_NAC) s(N mean min max)

* Drop unused observations to speed things up:
keep if g2smpl == 1
compress

////////////////////////////////////////////////////////////////////////////////
**** RDPLOT GRAPHS ****

********************************************************************************
* Over 32 weeks gestation (of the mother):
rdbwselect $mydepvar NAC_PESO_MADRE if g2smpl == 1 & sem32m == 1, c(1500)
scalar RBW_o32 = e(h_mserd)
scalar LBW_o32 = e(h_mserd)
scalar maxwt_o32 = 1500 + RBW_o32
scalar minwt_o32 = 1500 - LBW_o32
gen optbw_o32 = NAC_PESO_MADRE >= minwt_o32 & NAC_PESO_MADRE <= maxwt_o32

rdplot $mydepvar NAC_PESO_MADRE ///
	if optbw_o32 == 1 & g2smpl == 1 & sem32m == 1, ///
	c(1500) nbins(10) p(2) ///
	graph_options(${gphoptns} name(${abbrev}_o32_optbw_10bins, replace))
					
rdplot $mydepvar NAC_PESO_MADRE ///
	if optbw_o32 == 1 & g2smpl == 1 & sem32m == 1, ///
	c(1500) nbins(20) p(2) ///
	graph_options(${gphoptns} name(${abbrev}_o32_optbw_20bins, replace))
					
rdplot $mydepvar NAC_PESO_MADRE ///
	if optbw_o32 == 1 & g2smpl == 1 & sem32m == 1, ///
	c(1500) p(2) ///
	graph_options(${gphoptns} name(${abbrev}_o32_optbw_optbins, replace))

********************************************************************************
* Under 32 weeks gestation (of the mother):
/* (Note: so few observations that all bin selection procedures yield the same 
quantity of bins */
rdbwselect $mydepvar NAC_PESO_MADRE if g2smpl == 1 & sem32m == 0, c(1500)
scalar RBW_u32 = e(h_mserd)
scalar LBW_u32 = e(h_mserd)
scalar maxwt_u32 = 1500 + RBW_o32
scalar minwt_u32 = 1500 - LBW_o32
gen optbw_u32 = NAC_PESO_MADRE >= minwt_u32 & NAC_PESO_MADRE <= maxwt_u32
				
rdplot $mydepvar NAC_PESO_MADRE ///
	if optbw_u32 == 1 & g2smpl == 1 & sem32m == 0, ///
	c(1500) nbins(10) p(2) ///
	graph_options(${gphoptns} name(${abbrev}_u32_optbw_10bins, replace))
					
rdplot $mydepvar NAC_PESO_MADRE ///
	if optbw_u32 == 1 & g2smpl == 1 & sem32m == 0, ///
	c(1500) nbins(20) p(2) ///
	graph_options(${gphoptns} name(${abbrev}_u32_optbw_20bins, replace))
					
rdplot $mydepvar NAC_PESO_MADRE ///
	if optbw_u32 == 1 & g2smpl == 1 & sem32m == 0, ///
	c(1500) p(2) ///
	graph_options(${gphoptns} name(${abbrev}_u32_optbw_optbins, replace))

////////////////////////////////////////////////////////////////////////////////

* REGRESSIONS:
********************************************************************************
* Over 32 weeks gestation (of the mother):
* No controls:
rdrobust $mydepvar NAC_PESO_MADRE if g2smpl == 1 & sem32m==1, c(1500) scalepar(-1) all
est store ${abbrev}_o32_optbw
estadd scalar Hopt = e(h_l)
estadd scalar Nl   = e(N_h_l)
estadd scalar Nr   = e(N_h_r)
local ef = e(N_h_l)+e(N_h_r)
estadd scalar effopt = `ef'
sum $mydepvar if optbw_o32 == 1 & g2smpl == 1 & sem32m == 1
estadd scalar dvmean = r(mean)

* Heaping control:
rdrobust $mydepvar NAC_PESO_MADRE if g2smpl == 1 & sem32m == 1, c(1500) scalepar(-1) covs(round100m) all
est store ${abbrev}_o32_optbw_heaps
estadd scalar Hopt = e(h_l)
estadd scalar Nl   = e(N_h_l)
estadd scalar Nr   = e(N_h_r)
local ef = e(N_h_l)+e(N_h_r)
estadd scalar effopt = `ef'
sum $mydepvar if optbw_o32 == 1 & g2smpl == 1 & sem32m == 1
estadd scalar dvmean = r(mean)

********************************************************************************
* Under 32 weeks gestation (of the mother):
* No controls:
rdrobust $mydepvar NAC_PESO_MADRE if g2smpl == 1 & sem32m == 0, c(1500) scalepar(-1) all
est store ${abbrev}_u32_optbw
estadd scalar Hopt = e(h_l)
estadd scalar Nl   = e(N_h_l)
estadd scalar Nr   = e(N_h_r)
local ef = e(N_h_l)+e(N_h_r)
estadd scalar effopt = `ef'
sum $mydepvar if optbw_u32 == 1 & g2smpl == 1 & sem32m == 0
estadd scalar dvmean = r(mean)

* Heaping control:
rdrobust $mydepvar NAC_PESO_MADRE if g2smpl == 1 & sem32m == 0, c(1500) scalepar(-1) covs(round100m) all
est store ${abbrev}_u32_optbw_heaps
estadd scalar Hopt = e(h_l)
estadd scalar Nl   = e(N_h_l)
estadd scalar Nr   = e(N_h_r)
local ef = e(N_h_l) + e(N_h_r)
estadd scalar effopt = `ef'
sum $mydepvar if optbw_u32 == 1 & g2smpl == 1 & sem32m == 0
estadd scalar dvmean = r(mean)

gen RD_Estimate = .
lab var RD_Estimate "Birth weight < 1,500"

////////////////////////////////////////////////////////////////////////////////
* OUTPUTS:

********************************************************************************
* Export graphs as .gph:
graph dir
foreach g in `r(list)' {
	graph save `g' "$figsdir/`g'.gph", replace
}

* Export graphs as .eps:
graph dir
foreach g in `r(list)' {
	graph export "$figsdir/`g'.eps", replace name(`g')
}

* Export graphs as .png:
graph dir
foreach g in `r(list)' {
	graph export "$figsdir/`g'.png", replace name(`g')
}

********************************************************************************
* Export results as .ster files:

estimates dir
foreach result in `r(names)' {
	estimates restore `result'
	estimates save "$estdir/`result'", replace
}

********************************************************************************
* TABLES:

* ${abbrev}_o32_optbw: mother 32+ weeks, optimal bandwidth
* ${abbrev}_u32_optbw: mother <32 weeks, optimal bandwidth
* ${abbrev}_o32_optbw_heaps: mother 32+ weeks, optimal bandwidth, control for heaping
* ${abbrev}_u32_optbw_heaps: mother <32 weeks, optimal bandwidth, control for heaping

local ests ${abbrev}_o32_optbw ${abbrev}_u32_optbw ${abbrev}_o32_optbw_heaps ${abbrev}_u32_optbw_heaps 

* Display results:
esttab `ests', ///
	cells(b(fmt(%-9.4f) star) se(fmt(%-9.4f) par([ ]) )) label ///
	nonotes nogaps nonumber collabels(none) modelwidth(12) ///
	stats(dvmean N Hopt effopt Nl Nr, fmt(%05.3f %12.0gc %5.1f %9.0gc %9.0gc %9.0gc) ///
      label("Mean of Dep. Var." "Observations" "Optimal Bandwidth" ///
            "Effective Observations" "Observations (left)" "Observations (right)")) ///
	starlevel("*" 0.1 "**" 0.05 "***" 0.01) ///
	mtitles("32+" "<32" "32+" "<32") ///
	mgroups("No heaping" "Heaping", lhs("Birth Weight < 1500") pattern( 1 0 1 0))

* Export results:
#delimit ;
esttab `ests' using "$tbldir/${abbrev}.tex",
replace booktabs cells(b(fmt(%-9.4f) star) se(fmt(%-9.4f) par([ ]) )) label
stats(dvmean N Hopt effopt Nl Nr, fmt(%05.3f %12.0gc %5.1f %9.0gc %9.0gc %9.0gc) 
      label("\\ Mean of Dep. Var." "Observations" "Optimal Bandwidth" 
            "Effective Observations" "Observations (left)" "Observations (right)"))
nonotes nogaps mlabels(, none) nonumbers style(tex) fragment noline /*keep(RD_Estimate)*/
collabels(none) starlevel("*" 0.1 "**" 0.05 "***" 0.01);
#delimit cr


log close _all
