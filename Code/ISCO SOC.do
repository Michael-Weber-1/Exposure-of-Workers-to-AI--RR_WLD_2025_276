** Create ISCO and SOC crosswalk



** Importing the Excel with the crosswalk from SOC to ISCO and merging the AIOE information on the SOC level
import excel "$data\Excel\ISCO_SOC_Crosswalk.xls", sheet("2010 SOC to ISCO-08") firstrow clear
rename SOCCode SOC_1   // Note that this matches on the SOC 2018 version for the ISCO crosswalk, contrary to the sheet which says 2010 SOC
tostring SOC_1, replace
merge m:1 SOC_1 using  "$data\Excel\SOCAIOE.dta"


** Impute missing AIOE with the average of the 3 digit ISCO code
drop if AIOE==. & ISCO08Code==""  
drop if _merge!=3 
drop Comment81711  E F _merge x

destring ISCO08Code, replace
rename ISCO08Code occup_isco_08

** Impute the missing AIOE with the average of the respective ISO08Code group 
* First step: impute the missing within the group

isid occup_isco_08 SOC_1, sort missok
by occup_isco_08: gen x=_n
by occup_isco_08: egen y=max(x)
by occup_isco_08: egen f=sum(AIOE)
gen AIOE_adjusted=f/y
replace AIOE=AIOE_adjusted if AIOE==.
drop if AIOE==0  
drop x y f AIOE_adjusted

* Second step: Take the average of the group
isid occup_isco_08 SOC_1, sort missok
by occup_isco_08: gen x=_n
by occup_isco_08: egen y=max(x)
by occup_isco_08: egen f=sum(AIOE)
gen AIOE_adjusted=f/y
keep if x==1




* Third step: Impute the average of the 4 digit group to the 3 digit group level to fix miscoding in GLD dataset

preserve 
gen isco_3digit=occup_isco_08/10
replace isco_3digit=trunc(isco_3digit)
gen isco_new_3=isco_3digit*10
collapse AIOE_adjusted, by(isco_new_3)
drop if isco_new_3==. | isco_new_3==0
save "$data/Excel/3_digit", replace

restore


* Fourth step: Impute the average of the 3 digit group to the 2 digit group level to fix miscoding in GLD dataset

preserve 
gen isco_2digit=occup_isco_08/100
replace isco_2digit=trunc(isco_2digit)
gen isco_new_2=isco_2digit*100
collapse AIOE_adjusted, by(isco_new_2)
drop if isco_new_2==. | isco_new_2==0
save "$data/Excel/2_digit", replace
restore


* Fifth step: Impute the average of the 3 digit group to the 2 digit group level to fix miscoding in GLD dataset

preserve 
gen isco_1digit=occup_isco_08/1000
replace isco_1digit=trunc(isco_1digit)
gen isco_new_1=isco_1digit*1000
collapse AIOE_adjusted, by(isco_new_1)
drop if isco_new_1==. | isco_new_1==0
save "$data/Excel/1_digit", replace
restore


* Sixth step: Append the datasets on the 1/2/3 ISCO Level with the imputation

append using "$data/Excel/3_digit"
replace occup_isco_08=isco_new_3 if occup_isco_08==.

append using "$data/Excel/2_digit"
replace occup_isco_08=isco_new_2 if occup_isco_08==.

append using "$data/Excel/1_digit"
replace occup_isco_08=isco_new_1 if occup_isco_08==.

drop x y f isco_new_3 isco_new_2 isco_new_1 AIOE part

* Get rid of duplicats for occup_isco_08 
duplicates tag occup_isco_08, gen(x)
drop if x==1 & SOCCode==""



save "$data/SOCISAIOE.dta", replace



** Add for the US the Census Code
use "$data/SOCISAIOE.dta", clear
collapse AIOE_adjusted, by( CensusCode  )
save "$data/CensusAIOE.dta", replace