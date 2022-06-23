clear all 

****USE ACS 2009-2013 & 2015-2019 Uninsurance Rate Data****



set more off
  quietly log
  local logon = r(status)
  if "`logon'" == "on" { 
	log close 
	}
log using semprini_qrq, replace text

gen expansion=post*medicaid

global controls x_fpl100 x_ue x_bachdegree x_snap
 
estimates clear

****requires: rqr schemepack****

gen code=geoid
destring(code), force replace 
egen id=group(code)


***OLS results****

eststo: reg ya1864_uninsured 1.expansion  , vce(cluster statefips) 
eststo: areg ya1864_uninsured 1.expansion i.post, vce(cluster statefips) absorb(id)
eststo: areg ya1864_uninsured 1.expansion i.post [fw=ta1864], vce(cluster statefips) absorb(id)
eststo: areg ya1864_uninsured 1.expansion i.post c.($controls) [fw=ta1864], vce(cluster statefips) absorb(id)


esttab using t1ols.csv, b(3) se(3) replace keep(1.expansion) 
esttab using t1olsci.csv, b(3) ci(3) replace keep(1.expansion) 
esttab using t1olsp.csv, b(3) p(3) replace keep(1.expansion) 

estimates clear

***summary stats***

tabstat ya1864_uninsured [fweight = ta1864] if post==0, statistics( mean p50 min p10 p25 p75 p90 max ) by(medicaid) casewise noseparator save

****naieve qr****

set rmsg on

eststo: qreg ya1864_uninsured 1.expansion, vce(robust)
set rmsg off

set rmsg on

eststo: bsqreg ya1864_uninsured  1.expansion, quantile (.5) reps (10)
set rmsg off

set rmsg on

eststo: rifhdreg ya1864_uninsured 1.expansion, vce(cluster statefips) rif(q(50))
set rmsg off

set rmsg on

eststo: rqr ya1864_uninsured expansion , quantile(.5) 
set rmsg off



esttab using t2naieveqrg.csv, b(3) se(3) replace keep(1.expansion)

****qr w/ FE***

****naieve qr****
***qreg and bsqreg not feasile for census FE, computationally inefficient for state FE****
set rmsg on

eststo: qreg ya1864_uninsured 1.expansion i.post i.statefips, vce(robust)
set rmsg off

set rmsg on

eststo: bsqreg ya1864_uninsured  1.expansion i.post i.statefips, quantile (.5) reps (10)
set rmsg off

set rmsg on

eststo: rifhdreg ya1864_uninsured expansion i.post,  rif(q(50)) absorb(geoid)
set rmsg off

set rmsg on

eststo: rqr ya1864_uninsured expansion , quantile(.5) absorb(geoid post)
set rmsg off

esttab using t3feqrg.csv, b(3) se(3) replace keep(1.expansion)
****compare OLS & RQR****

eststo: areg ya1864_uninsured 1.post 1.expansion  , vce(cluster statefips) absorb(id)

set rmsg on

eststo: bootstrap, cluster(statefips) reps(1000): rifhdreg ya1864_uninsured expansion i.post,  rif(q(50)) absorb(geoid)

set rmsg off

set rmsg on

eststo: bootstrap, cluster(statefips) reps(1000): rqr ya1864_uninsured expansion , quantile(.5) absorb(geoid post)

set rmsg off


esttab using t4comparefeqreg.csv, b(3) se(3) replace keep(*expansion*) 


****distribution****

estimates clear

set rmsg on
eststo: bootstrap, cluster(statefips) reps(1000): rqr ya1864_uninsured expansion , quantile(.1(.1).9) absorb(geoid post)
estimates store a1
rqrplot

matrix ma=r(plotmat)


graph save f1.base.gph, replace

set rmsg off

esttab using t5_rqr_dist.csv, b(3) se(3) replace keep(*expansion*)


***use matrix to create a better graph****


frame create b
frame b{
	
	svmat ma



tw (line ma2 ma1, lcolor(black) lpattern(dot)) ///
(rarea ma4 ma5 ma1, color(%40)) ///
, ytitle(QTE)  xtitle(Uninsurance Quantile)  scheme(swift_red)  xlabel(.1(.1).9) title("Effect of Medicaid Expansion on Uninsurance Rates") yline(0)

graph save f2q.gph, replace
}
frame drop b

 

 
 


estimates clear
***test function***

areg expansion i.post, absorb(id) vce(cluster statefips)
predict resid, r

eststo: reg ya1864_uninsured resid i.post, vce(cluster statefips)
eststo: areg ya1864_uninsured expansion i.post, vce(cluster statefips) absorb(id)

eststo: rqr ya1864_uninsured resid

eststo: rqr ya1864_uninsured expansion , quantile(.5) absorb(geoid post)

esttab using t6_testfunc.csv, b(3) se(3) replace

