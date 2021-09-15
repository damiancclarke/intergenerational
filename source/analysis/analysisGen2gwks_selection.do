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

* Set seed for random varible generation:
set seed $myseed

* Declare dependent variable:
global mydepvar NAC_SEMANAS

* Declare abbrev:
global abbrev g2s_gwks

* Start log:
local logfilename = "${id_user_prefix}_`datetag'_${abbrev}"
capture log close _all
log using "$logdir/`logfilename'", replace text name(masterlog)

* Set graph options:
global gphoptns scheme(lean2) ///
				ytitle("Child's gestational weeks (2nd generation)") ///
				xtitle("Mother's birth weight in grams (1st generation)") ///
				legend(off) ylabel(37(1)40) 

////////////////////////////////////////////////////////////////////////////////
* Change to directory:
cd "$dtadir/DEIS"

* Load data:
use "${lastworkdata}.dta", clear

* Append counterfactual mothers:
append using COUNTERFACTUAL_MOTHERS.dta, gen(app_deadmom)

* Fill in missing variables for dead mothers:
replace sem32m = 1 if NAC_SEMANAS_MADRE >=32 & app_deadmom == 1
replace sem32m = 0 if NAC_SEMANAS_MADRE <=31 & app_deadmom == 1
replace round100m = 1 if mod(NAC_PESO_MADRE, 100) == 0 & mod(NAC_PESO_MADRE, 100) != . & app_deadmom == 1
replace round100m = 0 if mod(NAC_PESO_MADRE, 100) != 0 & mod(NAC_PESO_MADRE, 100) != . & app_deadmom == 1

* Base sample for second generation:
/* 
-> children for whom we have mother's birth data: NAC_mrg_mbdata2main == 3
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

////////////////////////////////////////////////////////////////////////////////
* Create 20 gram bins according to mother's birth weight:
gen int bin20gm = 20*floor(NAC_PESO_MADRE/20)

* Create dummy for surviving year 1 (using the mean and point estimate of the
* "first stage"):
gen survivor = rbinomial(1, 1-(0.144-0.0290)) if app_deadmom == 1

* Create dummy for ever having a child (to calculate fertility rates by birth year):
gen g1_ever_had_child_0118 = NAC_nbirths !=. & NAC_nbirths > 0 if NAC_SEXO == 2

* Create empty variable which will equal 1 if we will impute a birth to a dead girl:
gen imputed_child = .

* Get birth years of non dead girls that had a child:
levelsof NAC_ANO_NAC if g1_ever_had_child_0118 == 1 & muerte_1a == 0, local(yearlist)

* Loop over years...
foreach yyyy of local yearlist {
	* Calculate share of women that ever had a child by birth year:
	sum g1_ever_had_child_0118 if muerte_1a == 0 & NAC_ANO_NAC == `yyyy'
	
	* Replace empty variable:
	replace imputed_child = rbinomial(1, r(mean)) if survivor == 1 & NAC_ANO_NAC_MADRE == `yyyy'
}

* Summarize birth years of the mothers:
sum NAC_ANO_NAC_MADRE if g2smpl == 1

* Define imputed sample:
gen imputed_sample = imputed_child == 1 & NAC_PESO_MADRE > 1500 & sem32m == 1 ///
	& NAC_ANO_NAC_MADRE >= r(min) & NAC_ANO_NAC_MADRE <= r(max)

* Drop unused observations to speed things up:
keep if g2smpl == 1 | imputed_sample == 1
compress

* Display quantiles of the dependent variable by mother's birth weight bin:
tabstat ${mydepvar} if g2smpl == 1 & sem32m == 1 & app_deadmom == 0, ///
	by(bin20gm) s(N mean min p10 p25 p50 p75 p90 max)

* Impute dependent variable for imputed children of dead mothers:
forval p = 10(10)90 {
	bys bin20gm: egen ${mydepvar}_p`p' = pctile(cond(g2smpl == 1 & sem32m == 1 & app_deadmom == 0, ${mydepvar}, .)), p(`p')
	gen ${mydepvar}_imp`p' = ${mydepvar} if app_deadmom == 0
	replace ${mydepvar}_imp`p' = ${mydepvar}_p`p' if app_deadmom == 1
}	
	
////////////////////////////////////////////////////////////////////////////////

* Over 32 weeks gestation (of the mother):
rdbwselect $mydepvar NAC_PESO_MADRE if g2smpl == 1 & sem32m == 1, c(1500)
scalar RBW_o32 = e(h_mserd)
scalar LBW_o32 = e(h_mserd)
scalar maxwt_o32 = 1500 + RBW_o32
scalar minwt_o32 = 1500 - LBW_o32
gen optbw_o32 = NAC_PESO_MADRE >= minwt_o32 & NAC_PESO_MADRE <= maxwt_o32 

* Baseline:
* graph:
rdplot $mydepvar NAC_PESO_MADRE ///
	if optbw_o32 == 1 & g2smpl == 1 & sem32m == 1, ///
	c(1500) nbins(10) p(2) ///
	graph_options(${gphoptns} name(${abbrev}_o32_optbw_10bins, replace))

* robust rd estimation:
rdrobust $mydepvar NAC_PESO_MADRE if g2smpl == 1 & sem32m==1, c(1500) scalepar(-1) all
est store ${abbrev}_o32_optbw
estadd scalar Hopt = e(h_l)
estadd scalar Nl  = e(N_h_l)
estadd scalar Nr  = e(N_h_r)
local ef = e(N_h_l)+e(N_h_r)
estadd scalar effopt = `ef'
sum $mydepvar if optbw_o32 == 1 & (g2smpl == 1 | app_deadmom == 1) & sem32m == 1
estadd scalar dvmean = r(mean)

* Imputing percentile birth weight of a hypothetical child for dead potential mothers:
forval p = 10(10)90 {
	* graph:
	rdplot ${mydepvar}_imp`p' NAC_PESO_MADRE ///
	if optbw_o32 == 1 & (g2smpl == 1 | app_deadmom == 1) & sem32m == 1, ///
	c(1500) nbins(10) p(2) ///
	graph_options(${gphoptns} name(${abbrev}i`p'_o32_optbw_10bins, replace))
	
	* robust rd estimation:
	rdrobust ${mydepvar}_imp`p' NAC_PESO_MADRE if (g2smpl == 1 | app_deadmom == 1) & sem32m==1 , c(1500) scalepar(-1) all
	est store ${abbrev}i`p'_o32_optbw
	estadd scalar Hopt = e(h_l)
	estadd scalar Nl  = e(N_h_l)
	estadd scalar Nr  = e(N_h_r)
	local ef = e(N_h_l)+e(N_h_r)
	estadd scalar effopt = `ef'
	sum ${mydepvar}_imp`p' if optbw_o32 == 1 & (g2smpl == 1 | app_deadmom == 1) & sem32m == 1 & ${mydepvar}_imp`p' != . & NAC_PESO_MADRE != . & abs(NAC_PESO_MADRE - 1500) <= e(h_l)
	estadd scalar dvmean = r(mean)
	
	count if (g2smpl == 1 | app_deadmom == 1) & sem32m == 1 & ${mydepvar}_imp`p' != . & NAC_PESO_MADRE != . & abs(NAC_PESO_MADRE - 1500) <= e(h_l) & NAC_PESO_MADRE < 1500 & app_deadmom == 1
	estadd scalar N_l_i = r(N)
	
	count if (g2smpl == 1 | app_deadmom == 1) & sem32m == 1 & ${mydepvar}_imp`p' != . & NAC_PESO_MADRE != . & abs(NAC_PESO_MADRE - 1500) <= e(h_l) & NAC_PESO_MADRE >= 1500 & app_deadmom == 1
	estadd scalar N_r_i = r(N)
}

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


////////////////////////////////////////////////////////////////////////////////
* Prepare tables:
local ests ${abbrev}_o32_optbw ${abbrev}i??_o32_optbw

* Display results:
esttab `ests', ///
	cells(b(fmt(%-9.4f) star) se(fmt(%-9.4f) par([ ]) )) label ///
	nonotes nogaps collabels(none) modelwidth(10) ///
	stats(dvmean N Hopt effopt Nl Nr N_l_i N_r_i, fmt(%05.3f %12.0gc %5.1f %9.0gc %9.0gc %9.0gc %9.0gc %9.0gc) ///
   label("Mean of Dep. Var." "Observations" "Optimal Bandwidth" ///
      "Effective Observations" "Observations (left)" "Observations (right)" ///
			"Imputed Obs. (left)" "Imputed Obs. (right)")) ///
	starlevel("*" 0.1 "**" 0.05 "***" 0.01) ///
	mtitles("Baseline" "10th" "20th" "30th" "40th" "Median" "60th" "70th" "80th" "90th")

	
/*
Statistically significant effects at the baseline: treated are born aproximately
0.5 weeks earlier than control group.

The effect cannot made to dissappear (coefficient doesn't switch sign for any
imputed level of outcome). 

An interpretation is that girls that died within 1 year of birth would have had
to have a child somewhere below the 10th percentile of weeks of gestation to
make the treatment zero.
*/


********************************************************************************
* Export results:
local texfilename = `"${id_user_prefix}_`=subinstr("${S_DATE}", " ", "", .)'_${abbrev}_selection"'
#delimit ;
esttab `ests' using "$tbldir/`texfilename'.tex",
replace booktabs cells(b(fmt(%-9.4f) star) se(fmt(%-9.4f) par([ ]) )) label
stats(dvmean N Hopt effopt Nl Nr N_l_i N_r_i, fmt(%05.3f %12.0gc %5.1f %9.0gc %9.0gc %9.0gc %9.0gc %9.0gc)
   label("Mean of Dep. Var." "Observations" "Optimal Bandwidth" 
      "Effective Observations" "Observations (left)" "Observations (right)" 
			"Imputed Obs. (left)" "Imputed Obs. (right)")) 
nonotes nogaps nonumbers style(tex) fragment noline collabels(none) 
mtitles("Baseline" "10th" "20th" "30th" "40th" "Median" "60th" "70th" "80th" "90th")
starlevel("*" 0.1 "**" 0.05 "***" 0.01);
#delimit cr

* close log:
log close _all
