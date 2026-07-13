
*This do file contains the imputations for the AIOE 

use "$data\GLD_All_AI_last.dta", clear



** The following countries have an electricity rate of 99 or 100 percent. Electricity access at home or at the workplace is, hence, assumed
replace electricity=1 if electricity==. & (countrycode=="BOL" | countrycode=="BRA" | countrycode=="CHL" | countrycode=="COL" |  countrycode=="EGY" | countrycode=="GEO" | countrycode=="IND" | countrycode=="IDN" | countrycode=="LKA" | ///
countrycode=="MEX" | countrycode=="MNG" | countrycode=="THA" | countrycode=="TUN" | countrycode=="TUR" | countrycode=="USA")

bys countrycode year: gen q=_n


preserve
tempfile RWA
keep if countrycode=="RWA"
logit electricity urban industrycat10  occup whours educat4 [pweight=weight]
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=electricity
replace elec_imp=0 if elec_imp==. & elec_3<0.5
replace elec_imp=1 if elec_imp==. & elec_3>=0.5
keep countrycode year q elec_imp
save `RWA', replace
restore 


merge 1:1 countrycode year q using `RWA'
tab _merge

replace electricity=elec_imp if electricity==. & countrycode=="RWA"

drop _merge elec_imp



**************************************************************************************************************************************************
** Low income countries in SSA: Ethiopia, Gambia and Sierra Leone **
**************************************************************************************************************************************************

** Ethiopia
preserve
tempfile ETH
keep if countrycode=="RWA" | countrycode=="ETH" | countrycode=="TZA"
logit electricity urban industrycat10 educat4  [pweight=weight]
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=.
replace elec_imp=electricity 
replace elec_imp=0 if elec_imp==. & elec_3<=0.5
replace elec_imp=1 if elec_imp==. & elec_3>0.5
keep countrycode year q elec_imp
keep if countrycode=="ETH"
save `ETH', replace
restore 

merge 1:1 countrycode year q using `ETH'
tab _merge
replace electricity=elec_imp if electricity==. & countrycode=="ETH"
drop _merge elec_imp

** Sierra Leone
preserve
tempfile SLE
keep if countrycode=="RWA" |  countrycode=="TZA" | countrycode=="SLE" 
append using "$data\Imputation\SLE_2011.dta" 
logit electricity urban industrycat10  educat4  [pweight=weight]    
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=.
replace elec_imp=electricity 
replace elec_imp=0 if elec_imp==. & elec_3<=0.5
replace elec_imp=1 if elec_imp==. & elec_3>0.5
keep if countrycode=="SLE" & year==2014
keep countrycode year q elec_imp
save `SLE', replace
restore 

merge 1:1 countrycode year q using `SLE'
tab _merge
replace electricity=elec_imp if electricity==. & countrycode=="SLE"
drop _merge elec_imp

** Gambia 
preserve
tempfile GMB
keep if countrycode=="RWA" |  countrycode=="TZA" | countrycode=="GMB" 
logit electricity urban industrycat10 educat4 [pweight=weight]     
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=.
replace elec_imp=electricity 
replace elec_imp=0 if elec_imp==. & elec_3<=0.5
replace elec_imp=1 if elec_imp==. & elec_3>0.5

keep if countrycode=="GMB" & year==2023
keep countrycode year q elec_imp
save `GMB', replace
restore 

merge 1:1 countrycode year q using `GMB'
tab _merge
replace electricity=elec_imp if electricity==. & countrycode=="GMB"
drop _merge elec_imp


*****************************************************************************************************************************************************************
** Split the sample in Pakistan (including I2D2), Bangladesh, Nepal, Philippines, and India and estimate the electricity access for Pakistan and Philippines ****
*****************************************************************************************************************************************************************

* Pakistan => can make use of 2015 survey with electricity access for Pakistan 
preserve
tempfile PAK 
keep if countrycode=="PAK" |  countrycode=="BGD" 
append using "$data\Imputation\PAK_2015.dta" 
logit electricity urban industrycat10  educat4  [pweight=weight]  // whours not used because not availabe in PAK 2015
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=.
replace elec_imp=electricity 
replace elec_imp=0 if elec_imp==. & elec_3<=0.5
replace elec_imp=1 if elec_imp==. & elec_3>0.5
keep if year==2020 & countrycode=="PAK"
keep countrycode year q elec_imp
save `PAK', replace
restore 

merge 1:1 countrycode year q using `PAK'
tab _merge
replace electricity=elec_imp if electricity==. & countrycode=="PAK" 
drop _merge elec_imp



* Philippines 
preserve
tempfile PHL 
keep if countrycode=="PAK" |  countrycode=="BGD" | countrycode=="NPL" | countrycode=="PHL" 
logit electricity urban industrycat10  educat4  [pweight=weight]
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=.
replace elec_imp=electricity 
replace elec_imp=0 if elec_imp==. & elec_3<=0.5
replace elec_imp=1 if elec_imp==. & elec_3>0.5
keep if countrycode=="PHL"
keep countrycode year q elec_imp
save `PHL', replace
restore 

merge 1:1 countrycode year q using `PHL'
tab _merge
replace electricity=elec_imp if electricity==. & countrycode=="PHL" 
drop _merge elec_imp


*****************************************************************
** Lower middle income countries in SSA: Zimbabwe and Zambia ****
*****************************************************************

* Zambia 
preserve
tempfile ZMB 
keep if countrycode=="ZMB" 
append using "$data\Imputation\ZMB_2015.dta" 
logit electricity urban industrycat10   educat4  [pweight=weight]
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=.
replace elec_imp=electricity 
replace elec_imp=0 if elec_imp==. & elec_3<=0.5
replace elec_imp=1 if elec_imp==. & elec_3>0.5
keep if year==2022 & countrycode=="ZMB"
keep countrycode year q elec_imp
save `ZMB', replace
restore 


merge 1:1 countrycode year q using `ZMB'
tab _merge
replace electricity=elec_imp if electricity==. & countrycode=="ZMB" 
drop _merge elec_imp


*Zimbabwe 

preserve
tempfile ZWE 
keep if countrycode=="ZWE" | countrycode=="TZA"
append using "$data\Imputation\ZWE_2017.dta" 
logit electricity urban industrycat10    [pweight=weight] 
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=.
replace elec_imp=electricity 
replace elec_imp=0 if elec_imp==. & elec_3<=0.5
replace elec_imp=1 if elec_imp==. & elec_3>0.5
keep if year==2022 & countrycode=="ZWE"
keep countrycode year q elec_imp
save `ZWE', replace
restore 


merge 1:1 countrycode year q using `ZWE'
tab _merge
replace electricity=elec_imp if electricity==. & countrycode=="ZWE" 
drop _merge elec_imp


* South Africa [=upper middle income but no benchmark data/country available in SSA, take Colombia and Tansania]

preserve
tempfile ZAF 
keep if countrycode=="ZAF" | countrycode=="TZA" | countrycode=="COL"
logit electricity urban industrycat10 educat4     [pweight=weight]
predict elec_3
sum elec_3, det
sum electricity, det
gen elec_imp=.
replace elec_imp=electricity 
replace elec_imp=0 if elec_imp==. & elec_3<=0.5
replace elec_imp=1 if elec_imp==. & elec_3>0.5
keep if year==2020 & countrycode=="ZAF"
keep countrycode year q elec_imp
save `ZAF', replace
restore 


merge 1:1 countrycode year q using `ZAF'
tab _merge
replace electricity=elec_imp if electricity==. & countrycode=="ZAF" 
cap drop _merge elec_imp q x 



save "$data\GLD_All_AI_last_imputed.dta", replace
