/* analysisGen1IMR.do                 KTS                  yyyy-mm-dd:2021-06-08
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

 This file conducts analysis examining infant mortality rates of the first gene-
ration of children, replicating Bharadwaj et al., and extending to optimal mode-
ls and longer horizons.

 This file was originally written by Kathya Tapia.
 - Edits were made by Damian Clarke (2021-06-08)

Reqs (currently not automated install).  Add for replication materials:
 net install gr0002_3, from(http://www.stata-journal.com/software/sj4-3)
 requires estout, reghdfe, rdbwselect, rdplot, rdrobust

TO DO:
 - Can potentially clean up a little data generation
 - Can remove use of rdplot to automate after rdbwselect
 - Add BLN controls to our models
*/

clear all
set more off
capture log close
vers 11
set scheme s1mono

*-------------------------------------------------------------------------------
*--- (0) logs, globals
*-------------------------------------------------------------------------------
*cd "E:\TRABAJO 2021\Bases DEIS\Analysis\Infant Mortality - Infant Weight"

global DAT "/home/damian/investigacion/2021/intergenerational/data"
global OUT "/home/damian/investigacion/2021/intergenerational/results/gen1IMR"
global LOG "/home/damian/investigacion/2021/intergenerational/log"

cap mkdir "$OUT"

log using "$LOG/analysisGen1IMR.txt", replace text


*-------------------------------------------------------------------------------
*--- (1) RD plots
*-------------------------------------------------------------------------------
use "$DAT/MERGED_DEF2NAC.dta", clear
drop if mrg_DEF2NAC==2
keep if NAC_ANO_NAC>=1992&NAC_ANO_NAC<=2007
gen sem32 = NAC_SEMANAS>=32 if NAC_SEMANAS!=.
*Fallecidos menores 1 año
gen dias_muerte=DEF_FECHA_DEF_SIF-NAC_FECHA_NACIMIENTO_SIF /*Días vividos antes de morir*/
gen muerte_1a=1 if dias_muerte<=365
replace muerte_1a=0 if (dias_muerte==. | dias_muerte>365) 
/*Missing corresponde a nacidos que permanecen vivos*/
tab muerte_1a, m    /*1.453 fallecidos menores de 1 año*/
gen round100 = mod(NAC_PESO,100)==0 if mod(NAC_PESO,100)!=.

**works well with 20 bins too.  Have used 10 for now for comparison to BLN
foreach num of numlist 1 0 {
    if `num'==0 local weeks u
    if `num'==1 local weeks o
    *rdbwselect muerte_1a NAC_PESO if sem32==`num', c(1500) bwselect(msetwo)
    *local RBW = e(h_msetwo_r)
    *local LBW = e(h_msetwo_l)
    rdbwselect muerte_1a NAC_PESO if sem32==`num', c(1500)
    local RBW = e(h_mserd)
    local LBW = e(h_mserd)
    local maxwt = 1500+`RBW'
    local minwt = 1500-`LBW'
    preserve
    keep if sem32==`num' & NAC_PESO>=`minwt' & NAC_PESO<=`maxwt'
    #delimit ;
    rdplot muerte_1a NAC_PESO, c(1500) nbins(10) p(2)
    graph_options(scheme(lean2) ytitle("Infant Mortality") xtitle("Weight in grams")
                  legend(off) ylabel(0.05(0.05)0.2));
    #delimit cr
    graph export "$OUT/imrt_`weeks'32_optimal_19922007.eps", replace
    restore
    eststo: rdrobust muerte_1a NAC_PESO if sem32==`num', c(1500) scalepar(-1)
    estadd scalar Hopt = e(h_l)
    estadd scalar Nl   = e(N_h_l)
    estadd scalar Nr   = e(N_h_r)
    local ef = e(N_h_l)+e(N_h_r)
    estadd scalar effopt = `ef'
    sum muerte_1a if NAC_PESO >=`minwt' & NAC_PESO<=`maxwt'
    estadd scalar dvmean = r(mean)
    
    eststo: rdrobust muerte_1a NAC_PESO if sem32==`num', c(1500) scalepar(-1) covs(round100)
    estadd scalar Hopt = e(h_l)
    estadd scalar Nl   = e(N_h_l)
    estadd scalar Nr   = e(N_h_r)
    local ef = e(N_h_l)+e(N_h_r)
    estadd scalar effopt = `ef'
    sum muerte_1a if NAC_PESO >=`minwt' & NAC_PESO<=`maxwt'
    estadd scalar dvmean = r(mean)
}
use "$DAT/MERGED_DEF2NAC.dta", clear
drop if mrg_DEF2NAC==2
keep if NAC_ANO_NAC>=1992&NAC_ANO_NAC<=2001
gen sem32 = NAC_SEMANAS>=32 if NAC_SEMANAS!=.
*Fallecidos menores 1 año
gen dias_muerte=DEF_FECHA_DEF_SIF-NAC_FECHA_NACIMIENTO_SIF /*Días vividos antes de morir*/
gen muerte_1a=1 if dias_muerte<=365
replace muerte_1a=0 if (dias_muerte==. | dias_muerte>365) 
/*Missing corresponde a nacidos que permanecen vivos*/
tab muerte_1a, m    /*1.453 fallecidos menores de 1 año*/
gen round100 = mod(NAC_PESO,100)==0 if mod(NAC_PESO,100)!=.


foreach num of numlist 1 0 {
    if `num'==0 local weeks u
    if `num'==1 local weeks o
    rdbwselect muerte_1a NAC_PESO if sem32==`num', c(1500) 
    local RBW = e(h_mserd)
    local LBW = e(h_mserd)
    local maxwt = 1500+`RBW'
    local minwt = 1500-`LBW'
    preserve
    keep if sem32==`num' & NAC_PESO>=`minwt' & NAC_PESO<=`maxwt'
    #delimit ;
    rdplot muerte_1a NAC_PESO, c(1500) nbins(10) p(2)
    graph_options(scheme(lean2) ytitle("Infant Mortality") xtitle("Weight in grams")
                  legend(off) ylabel(0.05(0.05)0.2));
    #delimit cr
    graph export "$OUT/imrt_`weeks'32_optimal_19922001.eps", replace
    restore
    eststo: rdrobust muerte_1a NAC_PESO if sem32==`num', c(1500) scalepar(-1)
    estadd scalar Hopt = e(h_l)
    estadd scalar Nl   = e(N_h_l)
    estadd scalar Nr   = e(N_h_r)
    local ef = e(N_h_l)+e(N_h_r)
    estadd scalar effopt = `ef'
    sum muerte_1a if NAC_PESO >=`minwt' & NAC_PESO<=`maxwt'
    estadd scalar dvmean = r(mean)
    eststo: rdrobust muerte_1a NAC_PESO if sem32==`num', c(1500) scalepar(-1) covs(round100)
    estadd scalar Hopt = e(h_l)
    estadd scalar Nl   = e(N_h_l)
    estadd scalar Nr   = e(N_h_r)
    local ef = e(N_h_l)+e(N_h_r)
    estadd scalar effopt = `ef'
    sum muerte_1a if NAC_PESO >=`minwt' & NAC_PESO<=`maxwt'
    estadd scalar dvmean = r(mean)
}


*1.- Muestra BLN: 1992-2007, 1992-2018, 1992-2001
local years 2007 2018 2001
local years 2007
foreach num of numlist `years' {
    use "$DAT/MERGED_DEF2NAC.dta", clear

    replace NAC_TIPO_ATEN=.     if NAC_TIPO_ATEN==9
    replace NAC_NIVEL_MADRE=.   if NAC_NIVEL_MADRE==9
    replace NAC_EST_CIV_MADRE=. if NAC_EST_CIV_MADRE==9

    *Años examinados 
    drop if NAC_ANO_NAC<1992
    drop if NAC_ANO_NAC>`num'

    *Descripción
    count if NAC_PESO<1500 /*35.038*/
    count if NAC_PESO>=1400 & NAC_PESO<=1600 /*11.949*/
    count if NAC_PESO>=1400 & NAC_PESO<=1600 & NAC_SEMANAS>=32 /*6.506*/

    *1.400-1.600 gramos
    keep if NAC_PESO>=1385 & NAC_PESO<=1615
    *keep if PESO>=1000 & PESO<=2000

    *32 semanas o más gestación
    gen sem32= 0 if NAC_SEMANAS!=.
    replace sem32=1 if NAC_SEMANAS>=32 & NAC_SEMANAS!=.

    *Fallecidos menores 1 año
    gen dias_muerte=DEF_FECHA_DEF_SIF-NAC_FECHA_NACIMIENTO_SIF /*Días vividos antes de morir*/
    gen muerte_1a=1 if dias_muerte<=365
    replace muerte_1a=0 if (dias_muerte==. | dias_muerte>365) 
    /*Missing corresponde a nacidos que permanecen vivos*/
    tab muerte_1a, m    /*1.453 fallecidos menores de 1 año*/

    *a.- Figura 2
    *a.1.- 32 o más semanas de gestación
    *Derecho mayor o igual 32 semanas
    preserve
    drop if mrg_DEF2NAC==2
    drop if NAC_PESO==1500
    drop if NAC_PESO==1400
    drop if NAC_PESO==1600
    keep if NAC_PESO>=1500 & NAC_PESO<=1600 & NAC_SEMANAS>=32
    gen wt=abs(1600-NAC_PESO)/100
    qui reg muerte_1a NAC_PESO [pw=wt]
    predict muerte_1a_hat
    tempfile D_o32
    keep muerte_1a_hat NAC_PESO
    drop if muerte_1a_hat==. & NAC_PESO==.
    gen side="D"
    save "`D_o32'"
    restore
    *Izquierdo mayor o igual 32 semanas
    preserve
    drop if mrg_DEF2NAC==2
    drop if NAC_PESO==1500
    drop if NAC_PESO==1400
    drop if NAC_PESO==1600
    keep if NAC_PESO<1500 & NAC_PESO>=1400 & NAC_SEMANAS>=32
    gen wt=abs(1400-NAC_PESO)/100
    qui reg muerte_1a NAC_PESO [pw=wt]
    predict muerte_1a_hat
    tempfile I_o32
    keep muerte_1a_hat NAC_PESO
    drop if muerte_1a_hat==. & NAC_PESO==.
    gen side="I"
    save "`I_o32'"
    append using "`D_o32'"
    tempfile B_o32
    save "`B_o32'"
    restore
    *Promedio por bins
    preserve
    drop if mrg_DEF2NAC==2
    drop if NAC_PESO==1500
    drop if NAC_PESO==1400
    drop if NAC_PESO==1600
    keep if NAC_SEMANAS>=32
    *Creamos bins
    foreach n of numlist 1400(10)1480 1520(10)1600{
        gen bin_`n'=.
        qui replace bin_`n'=1 if  abs(NAC_PESO-`n')<=15 
    }
    gen bin_1490=.
    replace bin_1490=1 if abs(NAC_PESO-1490)<=15 & NAC_PESO<1500
    gen bin_1510=.
    replace bin_1510=1 if abs(NAC_PESO-1510)<=15 & NAC_PESO>=1500
    *Obtenemos muerte promedio de menores de un año por bin
    foreach n of numlist 1400(10)1490 1510(10)1600{
        qui sum muerte_1a if bin_`n'==1
        local mean_`n'=r(mean)
    }
    gen bin=.
    gen mean_imrt=.
    local i=1
    foreach n of numlist 1400(10)1490 1510(10)1600{
        qui replace bin=`n'              in `i'
        qui replace mean_imrt=`mean_`n'' in `i'
        local ++i
    }
    keep bin mean_imrt
    keep if bin!=. & mean_imrt!=.
    append using "`B_o32'"
    *Gráfico final 

    format mean_imrt %04.2f
    format muerte_1a_hat %04.2f
    #delimit ;
    line muerte_1a_hat NAC_PESO if side=="I", lwidth(thick) lcolor(gs7)
    || line muerte_1a_hat NAC_PESO if side=="D", lwidth(thick) lcolor(gs7)
    || scatter mean_imrt bin, legend(off) msize(medlarge) ms(Oh)
    ylabel(0.05 (0.05) 0.2) scheme(lean2)
    ytitle("Infant Mortality") xtitle("Weight in grams")
    xlabel(1400 (50) 1600) xline(1500, lpattern(dash) lcolor(black))
    name(imrt_o32_1992_`num');
    graph export "$OUT/imrt_o32_BLN_1992_`num'.eps", replace;
    #delimit cr
    restore

    *a.2.- Menos de 32 semanas de gestación
    *Derecho menor 32 semanas
    preserve
    drop if mrg_DEF2NAC==2
    drop if NAC_PESO==1500
    drop if NAC_PESO==1400
    drop if NAC_PESO==1600
    keep if NAC_PESO>=1500 & NAC_PESO<=1600 & NAC_SEMANAS<32
    gen wt=abs(1600-NAC_PESO)/100
    qui reg muerte_1a NAC_PESO [pw=wt]
    predict muerte_1a_hat
    tempfile D_u32
    keep muerte_1a_hat NAC_PESO
    drop if muerte_1a_hat==. & NAC_PESO==.
    gen side="D"
    save "`D_u32'"
    restore
    *Izquierdo menor 32 semanas
    preserve
    drop if mrg_DEF2NAC==2
    drop if NAC_PESO==1500
    drop if NAC_PESO==1400
    drop if NAC_PESO==1600
    keep if NAC_PESO<1500 & NAC_PESO>=1400 & NAC_SEMANAS<32
    gen wt=abs(1400-NAC_PESO)/100
    qui reg muerte_1a NAC_PESO [pw=wt]
    predict muerte_1a_hat
    tempfile I_u32
    keep muerte_1a_hat NAC_PESO
    drop if muerte_1a_hat==. & NAC_PESO==.
    gen side="I"
    save "`I_u32'"
    tempfile B_u32
    append using "`D_u32'"
    save "`B_u32'"
    restore
    *Promedio por bins
    preserve
    drop if mrg_DEF2NAC==2
    drop if NAC_PESO==1500
    drop if NAC_PESO==1400
    drop if NAC_PESO==1600
    keep if NAC_SEMANAS<32
    *Creamos bins
    foreach n of numlist 1400(10)1480 1520(10)1600{
        gen bin_`n'=.
        qui replace bin_`n'=1 if  abs(NAC_PESO-`n')<=15 
    }
    gen bin_1490=.
    replace bin_1490=1 if abs(NAC_PESO-1490)<=15 & NAC_PESO<1500
    gen bin_1510=.
    replace bin_1510=1 if abs(NAC_PESO-1510)<=15 & NAC_PESO>=1500
    *Obtenemos muerte promedio de menores de un año por bin
    foreach n of numlist 1400(10)1490 1510(10)1600{
        qui sum muerte_1a if bin_`n'==1
        local mean_`n'=r(mean)
    }
    gen bin=.
    gen mean_imrt=.
    local i=1
    foreach n of numlist 1400(10)1490 1510(10)1600{
        qui replace bin=`n'              in `i'
        qui replace mean_imrt=`mean_`n'' in `i'
        local ++i
    }
    keep bin mean_imrt
    keep if bin!=. & mean_imrt!=.
    append using "`B_u32'"

    format mean_imrt %04.2f
    format muerte_1a_hat %04.2f
    *Gráfico final 
    #delimit ;
    line muerte_1a_hat NAC_PESO if side=="I", lwidth(thick) lcolor(gs7)
    || line muerte_1a_hat NAC_PESO if side=="D", lwidth(thick) lcolor(gs7)
    || scatter mean_imrt bin, legend(off) msize(medlarge) ms(Oh)
    ylabel(0.05 (0.05) 0.2) scheme(lean2)
    ytitle("Infant Mortality") xtitle("Weight in grams")
    xlabel(1400 (50) 1600) xline(1500, lpattern(dash) lcolor(black))
    name(imrt_u32_1992_`num');
    graph export "$OUT/imrt_u32_BLN_1992_`num'.eps", replace;
    #delimit cr
    restore
    
    *b.- Tabla 2
    preserve
    drop if mrg_DEF2NAC==2
    keep if NAC_PESO>=1400 & NAC_PESO<=1600
    
    *Madres 15-43
    drop if NAC_EDAD_MADRE<15
    drop if NAC_EDAD_MADRE>43
    
    *Usan Niveles de educación Superior (1), Medio (2) y Básico (4)
    drop if NAC_NIVEL_MADRE==3 /*Secundario*/
    drop if NAC_NIVEL_MADRE==5 /*Ninguno*/
    
    *Considerando "Triangular Weigths"
    gen tweight=1-abs((NAC_PESO-1500)/100)
    
    *Very Low Birth Weight 
    gen vlbw=1 if NAC_PESO<1500 & NAC_PESO!=.
    replace vlbw=0 if NAC_PESO>=1500 & NAC_PESO!=.
    
    *Variables RD 
    gen f1=(NAC_PESO-1500)*vlbw
    gen f2=(1-vlbw)*(NAC_PESO-1500)
    
    *Cluster
    egen cluster_card=group(NAC_PESO)
    
    *Heap 100
    gen heap100 = mod(NAC_PESO,100)==0 if mod(NAC_PESO,100)!=.
    
    *Missing covariables
    #delimit ;
    egen keeper = rowmiss(muerte_1a vlbw f1 f2 NAC_TIPO_ATEN NAC_REGION_RESIDENCIA
                          NAC_NIVEL_MADRE NAC_EDAD_MADRE NAC_EST_CIV_MADRE NAC_ANO_NAC
                          NAC_SEXO heap100 NAC_SEMANAS cluster_card tweight);
    #delimit cr
    tab keeper
    keep if keeper==0
    
    tab sem32 /*6.264 mayor o igual a 32 semanas*/
    tab sem32 if NAC_PESO>1400 & NAC_PESO<1600 /*5.247 mayor o igual a 32 semanas*/
    
    *Regresiones
    local abs abs(NAC_TIPO_ATEN NAC_REGION_RESIDENCIA NAC_NIVEL_MADRE NAC_EST_CIV_MADRE NAC_ANO_NAC NAC_SEXO)
    local opt `abs' cluster(cluster_card)
    local cont f1 f2 NAC_EDAD_MADRE heap100
    local c2 i.NAC_TIPO_ATEN i.NAC_REGION_RESIDENCIA i.NAC_NIVEL_MADRE i.NAC_EST_CIV_MADRE i.NAC_ANO_NAC i.NAC_SEXO

    rename vlbw RD_Estimate
    eststo: reghdfe muerte_1a `cont' RD_Estimate [pw=tweight], `opt'
    sum muerte_1a if e(sample)
    estadd scalar dvmean = r(mean)
    qreg muerte_1a `cont' `c2' RD_Estimate, cluster(cluster_card) 

    
    eststo: reghdfe muerte_1a RD_Estimate `cont' [pw=tweight] if NAC_SEMANAS>=32, `opt'
    sum muerte_1a if e(sample)
    estadd scalar dvmean = r(mean)
    count if NAC_PESO<1500&NAC_SEMANAS>=32
    estadd scalar Nl = r(N)
    count if NAC_PESO>=1500&NAC_SEMANAS>=32
    estadd scalar Nr = r(N)
    qreg muerte_1a `cont' `c2' RD_Estimate if NAC_SEMANAS>=32, cluster(cluster_card)
    
    eststo: reghdfe muerte_1a RD_Estimate `cont' [pw=tweight] if NAC_SEMANAS<32, `opt'
    sum muerte_1a if e(sample)
    estadd scalar dvmean = r(mean)
    count if NAC_PESO<1500&NAC_SEMANAS<32
    estadd scalar Nl = r(N)
    count if NAC_PESO>=1500&NAC_SEMANAS<32
    estadd scalar Nr = r(N)
    qreg muerte_1a `cont' `c2' RD_Estimate if NAC_SEMANAS<32, cluster(cluster_card)
    restore
}
 

*est1: optimal, BLN sample, baseline (>=32 weeks)
*est2: optimal, BLN sample, heaping control (>=32 weeks)
*est3: optimal, BLN sample, baseline (<32 weeks)
*est4: optimal, BLN sample, heaping control (<32 weeks)
*est5: optimal, Intergen sample, baseline (>=32 weeks)
*est6: optimal, Intergen sample, heaping control (>=32 weeks)
*est7: optimal, Intergen sample, baseline (<32 weeks)
*est8: optimal, Intergen sample, heaping control (<32 weeks)
*est9: BLN literal replication (all)
*est10: BLN literal replication (>=32 weeks)
*est11: BLN literal replication (<32 weeks)


gen RD_Estimate = .
lab var RD_Estimate "Birth weight < 1,500"

local ests est10 est11 est1 est3 est5 est7
#delimit ;
esttab `ests' using "$OUT/IMRgen1.tex",
replace booktabs cells(b(fmt(%-9.4f) star) se(fmt(%-9.4f) par([ ]) )) label
stats(dvmean N Hopt effopt Nl Nr, fmt(%05.3f %12.0gc %5.1f %9.0gc %9.0gc %9.0gc) 
      label("\\ Mean of Dep. Var." "Observations" "Optimal Bandwidth" 
            "Effective Observations" "Observations (left)" "Observations (right)"))
nonotes nogaps mlabels(, none) nonumbers style(tex) fragment noline keep(RD_Estimate)
collabels(none) starlevel("*" 0.1 "**" 0.05 "***" 0.01);
#delimit cr
estimates clear


log close
