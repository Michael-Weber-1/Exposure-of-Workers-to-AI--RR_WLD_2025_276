
*This do file contains the descriptives and analysis for the AIOE 

grstyle init
grstyle color p1  "0 85 184"
grstyle color p2  "0 173 228"
grstyle color p3  "0 96 104"
grstyle color p4  "27 117 184"
grstyle color p5  "0 100 80"
grstyle color p6  "109 110 112"
grstyle color p7  "0 128 255"
grstyle color p8  "0 42 255"
grstyle color p9   "0 35 69"
grstyle color p10  "85 107 47"
grstyle color p11 "0 34 204"
grstyle color p12 "153 170 255"



use "$data\GLD_All_AI_last_imputed.dta", clear


** Adjust the AIOE index and normalize it


sum AIOE_adjusted
gen AIOE_adjusted_norm = (AIOE_adjusted - r(min)) / (r(max) - r(min))
replace AIOE_adjusted_norm=AIOE_adjusted_norm*100
drop if AIOE_adjusted_norm==.
compress


drop if occup_isco_08==. & countrycode!="USA"


*Regenerate the occupation on basis of the new occup 08 recoding for consistency for the GLD countries but not the USA that is I2D2 based
gen occup_USA=occup if countrycode=="USA"
cap drop occup
gen occup = real(substr(string(occup_isco_08, "%5.0g"), 1, 1))
replace occup = 10 if occup_isco_08<1000
recast byte occup
replace occup=occup_USA if occup==.
label variable occup "1 digit occupational classification, primary job 7 day recall"
label define occup_lab 1 "Managers" 2 "Professionals" 3 "Technicians" 4 "Clerks" 5 "Service and market sales workers" 6 "Skilled agricultural" 7 "Craft workers" 8 "Machine operators" 9 "Elementary occupations" 10 "Armed forces" 99 "Others"
label values occup occup_lab
replace occup=occup_USA if occup==.
* Exclude armed forces and others
drop if occup==10 | occup==99


sum AIOE_adjusted_norm, det   

_pctile AIOE_adjusted_norm, nq(4)

return list
gen AIOE_bin = 0 if AIOE_adjusted_norm>=0 & AIOE_adjusted_norm<=r(r1)	
replace AIOE_bin = 1 if AIOE_adjusted_norm>r(r1) & AIOE_adjusted_norm<=r(r2)
replace AIOE_bin = 2 if AIOE_adjusted_norm>r(r2) & AIOE_adjusted_norm<=r(r3)
replace AIOE_bin = 3 if AIOE_adjusted_norm>r(r3) & AIOE_adjusted_norm<=100

label def bin 0 "Low exposure" 1 "Moderate low exposure"	2 "Moderate high exposure" 3 "High exposure", modify
label val AIOE_bin bin	
compress

*Cross-check for I2D2
recode male 2=0
recode urban 2=0




* Save dataset
save "$data\GLD_All_AI_last_analysis.dta", replace


use "$data\GLD_All_AI_last_analysis.dta", clear


** Create a temp file for GNI per capita Atlas method, current US $
preserve
tempfile tmp
 wbopendata, language(en - English) indicator(NY.GNP.PCAP.CD) long clear latest
 sort countrycode
 save `tmp', replace
restore 

** Label income level and country year combination for the figures


	label var AIOE_adjusted_norm	"AI Occupation exposure, 0-100"

	g yrs=year
	tostring yrs, replace
	gen country_yr=  countrycode + " " + yrs 
	sort countrycode 

	
	
	merge m:m countrycode  using `tmp'
	keep if _merge==3
	drop _merge
	

	replace incomelevel="LMIC" if incomelevel=="LMC"
	replace incomelevel="UMIC" if incomelevel=="UMC"

	gen		 income=1 if incomelevel=="HIC"
	replace  income=2 if incomelevel=="UMIC"
	replace  income=3 if incomelevel=="LMIC"
	replace  income=4 if incomelevel=="LIC"
	label def income 1 "High Income" 2 "Upper-Middle Income" 3 "Lower-Middle Income" 4 "Low Income"
	label val income income

	replace countryname="Türkiye" if countrycode=="TUR"

	gen name_yr=  countryname + " " + yrs 


************************************************************************************************
****** Calculation of Scatterplot from GNI and AIOE / AIOE for each country ********************
************************************************************************************************


preserve
collapse AIOE_adjusted_norm AIOE_adjusted [aweight=weight] if age>14 & age<65, by(countrycode year)	


label var AIOE_adjusted_norm	"AI Occupation exposure, 0-100"


g yrs=year
tostring yrs, replace

gen country_yr=  countrycode + " " + yrs 

sort countrycode 

merge 1:1 countrycode using `tmp'

keep if _merge==3

drop _merge


replace incomelevel="LMIC" if incomelevel=="LMC"
replace incomelevel="UMIC" if incomelevel=="UMC"

gen		 income=1 if incomelevel=="HIC"
replace  income=2 if incomelevel=="UMIC"
replace  income=3 if incomelevel=="LMIC"
replace  income=4 if incomelevel=="LIC"
label value income income

replace countryname="Türkiye" if countrycode=="TUR"

gen name_yr=  countryname + " " + yrs 



* AIOE scatter plot with GNI per capita


gen log=log(ny_gnp_pcap_cd)
label var log "GNI per capita (current US $), log"

graph    twoway (scatter AIOE_adjusted_norm log if income==1, mcolor(blue))  || (scatter AIOE_adjusted_norm log if income==2, mcolor(red)) || ///
				(scatter AIOE_adjusted_norm log if income==3, mcolor(green)) || (scatter AIOE_adjusted_norm log if income==4, mcolor(orange)), legend(order(4 "Low income" 3 "Lower middle income" 2 "Upper middle income" 1 "High income") position(6) col(4))  title("AI Occupational Exposure by GNI per capita (current US $)", size (medium)) graphregion(color(white))
graph export "$figure\Scatter_GNI_AIOE.png", replace	

restore 


** Occupations and AI


preserve 

tempfile low

gen high_AI=0 if AIOE_bin>=0 & AIOE_bin!=.
replace high_AI=1 if  AIOE_bin==3

gen moderate_AI=0 if AIOE_bin>=0 & AIOE_bin!=.
replace moderate_AI=1 if AIOE_bin==2


collapse high_AI moderate_AI [aweight=weight] if age>14 & age<65, by(countrycode year)
gen ranking_AI=moderate_AI+high_AI
egen rank=rank(ranking_AI)
egen rank2=rank(-ranking_AI)
sort countrycode
save `low', replace
restore 

merge m:m countrycode using `low'

drop _merge moderate_AI high_AI ranking_AI


gen counter=1


gen AIOE_bin_inverse=0 if AIOE_bin==3
replace AIOE_bin_inverse=1 if AIOE_bin==2
replace AIOE_bin_inverse=2 if AIOE_bin==1
replace AIOE_bin_inverse=3 if AIOE_bin==0
label def bin_rev 3 "Low exposure" 2 "Moderate low exposure"	1 "Moderate high exposure" 0 "High exposure", modify
label val AIOE_bin_inverse bin_rev	

	
graph hbar (percent) counter [aweight=weight] if age>14 & age<65, over(AIOE_bin_inverse) stack asyvars	percentage over(name_yr, sort(rank2))  bar(4, color(gs10)) ///
	title("AI Occupational Exposure by Country, age 15-64", size (medium))  ytitle("AI Exposure Index") ///
	 graphregion(color(white)) 
		graph export "$figure\AIOE by country and exposure groups.png", replace
	
	
	
graph hbar (percent) counter [aweight=weight] if age>14 & age<65 & male==1, over(AIOE_bin_inverse)  stack asyvars	percentage over(name_yr, sort(rank2))  bar(4, color(gs10)) ///
	title("Male", size (medium))  ytitle("AI Exposure Index") ///
	 graphregion(color(white))  saving(male, replace) 
	
	
graph hbar (percent) counter [aweight=weight] if age>14 & age<65 & male==0, over(AIOE_bin_inverse)  stack asyvars	percentage over(name_yr, sort(rank2))  bar(4, color(gs10)) ///
	title("Female", size (medium))  ytitle("AI Exposure Index") ///
	 graphregion(color(white))  saving(female, replace) legend(cols(4))
		
grc1leg   male.gph female.gph, title("AI Occupational Exposure by Country and Gender, age 15-64") legendfrom(female.gph) span 
		graph export "$figure\AIOE by each country and gender.png", replace


********************************************************
**************** Distributions *************************
********************************************************



twoway scatteri 0.0019 10.36209 (11) "Roofers" || ||scatteri  0.03 33.1738 (9) "Motor vehicle mechanics and repairers" || scatteri  0.007 57.96186 (5) "Customs and border inspector" || scatteri  0.0083  94.7156 (6) "Payroll clerks" || kdensity AIOE_adjusted_norm [aweight=weight],  bw(3)  xtitle("AI Occupation Exposure") ytitle("Kernel Density") title("") legend(off) graphregion(color(white)) 
graph export "$figure\AIOE Density overall.png", replace


twoway kdensity AIOE_adjusted_norm [aweight=weight],  by(income, title("AI Occupation Exposure by Income group")  note("")  graphregion(color(white))) ytitle("Kernel Density") xtitle("") bw(3)
graph export "$figure\AIOE Density by income level.png", replace


twoway kdensity AIOE_adjusted_norm [aweight=weight],  by(countryname, title("AI Occupation Exposure by Country")  note("")  graphregion(color(white))) ytitle("Kernel Density") xtitle("") bw(3)
graph export "$figure\AIOE Density by countryname.png", replace






*******************************************************
************** Export table and sample information ****
*******************************************************

*** This creates different sheets for the averages by categories
preserve 
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65, by(countryname)
export excel using "$tables\All.xls", sheet("All") firstrow(variables) replace
restore 

preserve 
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65, 
export excel using "$tables\All.xls", sheet("All_average") firstrow(variables) 
restore 

preserve
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65 & male!=., by(countryname male)
export excel using "$tables\All.xls", sheet("Gender") firstrow(variables) 
restore 


preserve
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65 & male!=., by(male)
export excel using "$tables\All.xls", sheet("Gender_average") firstrow(variables) 
restore 



preserve
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65 & urban!=., by(countryname urban)
export excel using "$tables\All.xls", sheet("Location") firstrow(variables) 
restore 

preserve
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65 & urban!=., by( urban)
export excel using "$tables\All.xls", sheet("Location_average") firstrow(variables) 
restore 



preserve
label define education 1 "None " 2 "Primary" 3 "Secondary" 4 "Post-secondary"
label val educat4 education	
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65 & educat4!=., by(countryname educat4)
export excel using "$tables\All.xls", sheet("Education") firstrow(variables) 
restore


preserve
label define education 1 "None " 2 "Primary" 3 "Secondary" 4 "Post-secondary"
label val educat4 education	
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65 & educat4!=., by(educat4)
export excel using "$tables\All.xls", sheet("Education_average") firstrow(variables) 
restore




preserve
gen age_5=.
	replace age_5=1 if age <15
	replace age_5=2 if age >=15 & age <=24
	replace age_5=3 if age >=25 & age <=34
	replace age_5=4 if age >=35 & age <=64
	replace age_5=5 if age >=65

	label def age_5 1"0-15" 2"15-24" 3"25-34" 4"35-64" 5"64-Above"
	label val age_5 age_5
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65 & age!=., by(countryname age_5)
export excel using "$tables\All.xls", sheet("Age") firstrow(variables) 
restore



preserve
gen age_5=.
	replace age_5=1 if age <15
	replace age_5=2 if age >=15 & age <=24
	replace age_5=3 if age >=25 & age <=34
	replace age_5=4 if age >=35 & age <=64
	replace age_5=5 if age >=65

	label def age_5 1"0-15" 2"15-24" 3"25-34" 4"35-64" 5"64-Above"
	label val age_5 age_5
collapse AIOE_adjusted_norm [aweight=weight] if age>14 & age<65 & age!=., by(age_5)
export excel using "$tables\All.xls", sheet("Age_average") firstrow(variables) 
restore

preserve

collapse  (mean) income year (count) age, by(countryname)

label var year "Year of Survey"
label var age  "Sample Size"

gen		 incomelevel="High income" 			if income==1
replace  incomelevel="Upper middle income" 		if income==2 
replace  incomelevel="Lower middle income"   	if income==3
replace  incomelevel="Low income"   			if income==4
drop income

export excel using "$tables\All.xls", sheet("Sample information") firstrow(varlabels)
restore


**************************************************************
******** AI Occupation Exposure for income level *************
**************************************************************




** Occupations and AI
graph hbar (mean) AIOE_adjusted_norm [pw=weight] if age>14 & age<65 ,  over(income) blabel(bar, position(outside) size(small) format(%3.0f))  legend(size(small) colfirst)  ///
	title("AI Occupational Exposure by Income Group, age 15-64", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\AIOE by income level.png", replace

	
	
	
**************************************************************************************
********** AI Occupation Exposure by education, location, age, and gender ************
**************************************************************************************	
	
* Extra variable generation	
gen age_5=.
	replace age_5=1 if age <15
	replace age_5=2 if age >=15 & age <=24
	replace age_5=3 if age >=25 & age <=34
	replace age_5=4 if age >=35 & age <=64
	replace age_5=5 if age >=65

	label def age_5 1"0-15" 2"15-24" 3"25-34" 4"35-64" 5"64-Above"
	label val age_5 age_5
	
label define education 1 "None " 2 "Primary" 3 "Secondary" 4 "Post-secondary"
label val educat4 education	
	
	
	
	
* Gender, Income and AIOE
graph bar (sum) counter [pw=weight] if age>14 & age<65 , over(AIOE_bin) over(male) over(income, label(labsize(small)))  bar(1, color(gs10)) percentages asyvars stack ///
legend(order(4 "High" "Exposure" 3 "Moderate" "High" "Exposure" 2 "Moderate" "Low" "Exposure" 1 "Low" "Exposure") size(small)) ///
blabel(bar, position(center) size(vsmall) format(%3.0f)) ///
title("AI Exposure by Gender and Country Income Level", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\AIOE Gender Income Level_v2.png", replace


	
* Age, Income  and AIOE
graph bar (sum) counter [pw=weight] if age>14 & age<65 , over(AIOE_bin) over(age_5, label(labsize(small))) over(income, label(labsize(small)))  bar(1, color(gs10)) percentages asyvars stack ///
legend(order(4 "High" "Exposure" 3 "Moderate" "High" "Exposure" 2 "Moderate" "Low" "Exposure" 1 "Low" "Exposure") size(small)) ///
blabel(bar, position(center) size(vsmall) format(%3.0f)) ///
title("AI Exposure by Age and Country Income Level", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\AIOE Age Income Level.png", replace	
	

* Urban, Income  and AIOE (*Note: There is no information on locality for Turkey so the country is dropped)
graph bar (sum) counter [pw=weight] if age>14 & age<65 , over(AIOE_bin) over(urban) over(income, label(labsize(small)))  bar(1, color(gs10)) percentages asyvars stack ///
legend(order(4 "High" "Exposure" 3 "Moderate" "High" "Exposure" 2 "Moderate" "Low" "Exposure" 1 "Low" "Exposure") size(small)) ///
blabel(bar, position(center) size(vsmall) format(%3.0f)) ///
title("AI Exposure by Location and Country Income Level", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\AIOE Urban Income Level.png", replace	
	

* Education, Income and AIOE

graph bar (sum) counter [pw=weight] if age>14 & age<65 , over(AIOE_bin) over(educat4, label(labsize(small) angle(45)))  over(income, label(labsize(small)))  ///
bar(1, color(gs10)) percentages asyvars stack ///
legend(order(4 "High" "Exposure" 3 "Moderate" "High" "Exposure" 2 "Moderate" "Low" "Exposure" 1 "Low" "Exposure") size(small)) ///
blabel(bar, position(center) size(vsmall) format(%3.0f)) ///
title("AI Exposure by Education and Country Income Level", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\AIOE Education Income Level.png", replace	

	
	
* Industry share and AIOE	
	
graph bar (sum) counter [pw=weight] if age>14 & age<65 , over(AIOE_bin)  over(industrycat10, label(labsize(vsmall) angle(45))) bar(1, color(gs10))  percentages asyvars stack  legend(size(vsmall) colfirst)  ytitle("") ///
blabel(bar, position(center) size(vsmall) format(%3.0f)) ///
legend(order(4 "High" "Exposure" 3 "Moderate" "High" "Exposure" 2 "Moderate" "Low" "Exposure" 1 "Low" "Exposure") size(small)) ///
title("AI Exposure by Industry Sector", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\AIOE and Industry Level.png", replace	
		
*** Occupation and AIOE
graph bar (sum) counter [pw=weight] if age>14 & age<65 , over(AIOE_bin) over(occup, sort(1) label(labsize(small) angle(45)))  bar(1, color(gs10))   ///
percentages asyvars stack ///
blabel(bar, position(center) size(vsmall) format(%3.0f)) ///
legend(order(4 "High" "Exposure" 3 "Moderate" "High" "Exposure" 2 "Moderate" "Low" "Exposure" 1 "Low" "Exposure") size(small)) ///
title("AI Exposure by Occupation", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\Occupations Exposure.png", replace
			

			

** Regression 


drop ccode

encode countrycode, gen(ccode)
reg  AIOE_adjusted_norm  ib(9).occup ib(1).industrycat10 i.age_5 i.male i.urban i.educat4 i.empstat  i.ccode i.year [pw=weight] if incomelevel=="HIC" & age>14 & age<65, robust cluster(countrycode)
est store income_HIC_all, nocopy

reg  AIOE_adjusted_norm  ib(9).occup ib(1).industrycat10 i.age_5 i.male i.urban i.educat4 i.empstat i.ccode i.year [pw=weight] if incomelevel=="LMIC" & age>14 & age<65, robust cluster(countrycode)
est store income_LMC_all, nocopy

reg  AIOE_adjusted_norm  ib(9).occup ib(1).industrycat10 i.age_5 i.male i.urban  i.educat4 i.empstat i.ccode i.year [pw=weight] if incomelevel=="UMIC" & age>14 & age<65, robust cluster(countrycode)
est store income_UMC_all, nocopy		
		
reg  AIOE_adjusted_norm  ib(9).occup ib(1).industrycat10 i.age_5 i.male i.urban i.educat4 i.empstat i.ccode i.year [pw=weight] if incomelevel=="LIC" & age>14 & age<65, robust cluster(countrycode)
est store income_LIC_all, nocopy				
		
esttab income_HIC_all  income_UMC_all income_LMC_all  income_LIC_all using "$tables/income level AIOE.csv", replace compress nogap label nonumbers  ////
mtitle("HIC" "UMC" "LMC" "LIC") ////
		                 scalars(N ll) star(* 0.1 ** 0.05 *** 0.01) title("AI occupation exposure by income level") 

						 
						 			
			
			
			
			
			
			
	
************************************************	
** Including Electricity into AIOE	
************************************************



** Data preparation for electricity analysis
drop if electricity==.

	
gen 		AIOE_electricity=1 if AIOE_bin==0 & electricity==0
replace 	AIOE_electricity=2 if AIOE_bin==0 & electricity==1
replace 	AIOE_electricity=3 if AIOE_bin==1 & electricity==0
replace 	AIOE_electricity=4 if AIOE_bin==1 & electricity==1
replace 	AIOE_electricity=5 if AIOE_bin==2 & electricity==0
replace 	AIOE_electricity=6 if AIOE_bin==2 & electricity==1
replace 	AIOE_electricity=7 if AIOE_bin==3 & electricity==0
replace 	AIOE_electricity=8 if AIOE_bin==3 & electricity==1


label def elec 1 "Low Exposure, no electricity"	2 "Low Exposure with electricity" 3 "Moderate Low Exposure, no electricity" 4 "Moderate Low Exposure, electricity" 5 "Moderate High Exposure, no electricity" 6 "Moderate High Exposure, electricity" 7 "High Exposure, no electricity" 8 "High Exposure, electricity"

label val AIOE_electricity elec
		
gen 		AIOE_elec_reduc=1 if AIOE_electricity==1 | AIOE_electricity==3
replace 	AIOE_elec_reduc=2 if AIOE_electricity==2 | AIOE_electricity==4
replace 	AIOE_elec_reduc=3 if AIOE_electricity==5 | AIOE_electricity==7
replace 	AIOE_elec_reduc=4 if AIOE_electricity==6 | AIOE_electricity==8

label def elec_reduc  1 "Lower Exposure, no electricity" 2 "Lower Exposure, electricity" 3 "Higher exposure, no electricity" 4 "Higher exposure, electricity"		
label val AIOE_elec_reduc  elec_reduc		
		
** Electricity and Income groups		
graph bar (sum) counter [pweight=weight] if age>14 & age<65 , over(AIOE_elec_reduc) over(income, relabel(4  `"Low Income"' 3  `""Lower-middle" "Income""' 2  `""Upper-middle" "Income""' 1  `"High Income"'))  ///
bar(1, color(gs10)) percentages asyvars stack ///
legend(order(4 "Higher Exposure" "Electricity" 3 "Higher Exposure" "No Electricity"  2 "Lower Exposure" "Electricity" 1 "Lower Exposure" "No Electricity")size(small)) ///
blabel(bar, position(center) size(vsmall) format(%3.0f)) ///
bar(1, fintensity(60) 	fcolor("0 85 184") lcolor(black) lwidth(vthin)) ///
bar(2, fintensity(100)  fcolor("0 85 184") lcolor(black) lwidth(vthin)) ///
bar(3, fintensity(60) 	fcolor("0 96 104") lcolor(black) lwidth(vthin)) ///
bar(4, fintensity(100) 	fcolor("0 96 104") lcolor(black) lwidth(vthin)) ///
title("AI Exposure by Electricity Access and Country Income Level", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\AIOE  Income Level_Electricity_reduced.png", replace			
		
		
		
** Electricity and Income groups		
graph bar (sum) counter [pweight=weight] if age>14 & age<65 , over(AIOE_elec_reduc) over(urban) over(income, relabel(4  `"Low Income"' 3  `""Lower-middle" "Income""' 2  `""Upper-middle" "Income""' 1  `"High Income"'))  ///
bar(1, color(gs10)) percentages asyvars stack ///
legend(order(4 "Higher Exposure" "Electricity" 3 "Higher Exposure" "No Electricity"  2 "Lower Exposure" "Electricity" 1 "Lower Exposure" "No Electricity")size(small)) ///
blabel(bar, position(center) size(vsmall) format(%3.0f)) ///
bar(1, fintensity(60) 	fcolor("0 85 184") lcolor(black) lwidth(vthin)) ///
bar(2, fintensity(100)  fcolor("0 85 184") lcolor(black) lwidth(vthin)) ///
bar(3, fintensity(60) 	fcolor("0 96 104") lcolor(black) lwidth(vthin)) ///
bar(4, fintensity(100) 	fcolor("0 96 104") lcolor(black) lwidth(vthin)) ///
title("AI Exposure by Electricity Access, Location and Country Income Level", size (medium))  ytitle("AI Exposure Index") ///
	graphregion(color(white)) 
	graph export "$figure\AIOE  Income Level_Electricity_urban.png", replace			
		
		

		
		
		
		
		
		
* Analysis on the value added of 4 digit ISCO information vs 2 digit and 1 digit, including entropy measures		
		
		
gen AIOE_reduced=AIOE_adjusted_norm
gen isco_2digit=occup_isco_08/100
replace AIOE_reduced=. if  mod(isco_2digit, 1) != 0
replace isco_2digit=trunc(isco_2digit)

sort isco_2digit
replace AIOE_reduced= AIOE_reduced[_n-1] if AIOE_reduced>= .

						
gen AIOE_reduced_1digit=AIOE_adjusted_norm
gen isco_1digit=occup_isco_08/1000
replace AIOE_reduced_1digit=. if  mod(isco_1digit, 1) != 0
replace isco_1digit=trunc(isco_1digit)

sort isco_1digit
replace AIOE_reduced_1digit= AIOE_reduced_1digit[_n-1] if AIOE_reduced_1digit>= .

sum AIOE_adjusted_norm AIOE_reduced AIOE_reduced_1digit, detail

preserve
entropyetc  isco_2digit, 	 gen(1=distinct_2digit 2=Shannon_2digit 4=Simpson_2digit 5=Simpson1_2digit)
entropyetc occup, 		 	 gen(1=distinct_all 2=Shannon_all 4=Simpson_all 5=Simpson1_all)
entropyetc occup_isco_08,    gen(1=distinct_4digit 2=Shannon_4digit 4=Simpson_4digit 5=Simpson1_4digit)

collapse distinct_all distinct_2digit distinct_4digit Shannon_all Shannon_2digit Shannon_4digit Simpson_all Simpson_2digit Simpson_4digit Simpson1_all Simpson1_2digit Simpson1_4digit

label var distinct_all    "Number of categories for 1 digit ISCO"
label var distinct_2digit "Number of categories for 2 digit ISCO"
label var distinct_4digit "Number of categories for 4 digit ISCO"

label var Shannon_all		  "Shannon index for 1 digit ISCO"
label var Shannon_2digit	  "Shannon index for 2 digit ISCO"
label var Shannon_4digit	  "Shannon index for 4 digit ISCO"

label var Simpson_all		  "Simpson sum of squared probabilities 1 digit ISCO"
label var Simpson_2digit	  "Simpson sum of squared probabilities 2 digit ISCO"
label var Simpson_4digit	  "Simpson sum of squared probabilities 4 digit ISCO"

label var Simpson1_all		  "Simpson 1/n sum of squared probabilities 1 digit ISCO"	
label var Simpson1_2digit	  "Simpson 1/n sum of squared probabilities 2 digit ISCO"
label var Simpson1_4digit	  "Simpson 1/n sum of squared probabilities 4 digit ISCO"



export excel using "$tables\All.xls", sheet("Entropy measures") firstrow(varlabels)
restore 


preserve
collapse AIOE_adjusted_norm AIOE_reduced_1digit AIOE_reduced, by(occup isco_2digit occup_isco_08)
label var AIOE_adjusted_norm "AI Occupation Exposure"
label var occup_isco_08 "Occupation category"
label var AIOE_reduced_1digit "AI Occupation Exposure"
label var AIOE_reduced "AI Occupation Exposure"

gen occup2=occup*1000
gen isco_2000=isco_2digit*100
label var isco_2000 "Occupation category"


graph twoway (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=1000 & occup_isco_08<2000, mcolor(blue))  || (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=2000 & occup_isco_08<3000, mcolor(red)) || (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=3000 & occup_isco_08<4000, mcolor(green)) || (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=4000 & occup_isco_08<5000, mcolor(orange)) ||  (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=5000 & occup_isco_08<6000, mcolor(yellow))  || (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=6000 & occup_isco_08<7000, mcolor(navy)) || (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=7000 & occup_isco_08<8000, mcolor(maroon)) || (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=8000 & occup_isco_08<9000, mcolor(black)) || (scatter AIOE_adjusted_norm occup_isco_08 if occup_isco_08>=9000 & occup_isco_08<10000, mcolor(purple)), legend(order( 1 "Managers" 2 "Professionals" 3 "Technicians and associate professionals" 4 "Clerical support worker" 5 "Service and sales workers" 6 "Skilled agricultural, forestry and fishery workers" 7 "Craft and related trades workers" 8 "Plant and machine operators and assemblers" 9 "Elementary occupations") position(6) col(2))  title("4 digit occupations by occupation categories", size (medium)) graphregion(color(white)) xlabel(0 (1000) 9000) saving(detailed, replace) 


graph twoway (scatter AIOE_reduced isco_2000 if occup_isco_08>=1000 & occup_isco_08<2000, mcolor(blue))  || (scatter AIOE_reduced isco_2000 if occup_isco_08>=2000 & occup_isco_08<3000, mcolor(red)) || (scatter AIOE_reduced isco_2000 if occup_isco_08>=3000 & occup_isco_08<4000, mcolor(green)) || (scatter AIOE_reduced isco_2000 if occup_isco_08>=4000 & occup_isco_08<5000, mcolor(orange)) ||  (scatter AIOE_reduced isco_2000 if occup_isco_08>=5000 & occup_isco_08<6000, mcolor(yellow))  || (scatter AIOE_reduced isco_2000 if occup_isco_08>=6000 & occup_isco_08<7000, mcolor(navy)) || (scatter AIOE_reduced isco_2000 if occup_isco_08>=7000 & occup_isco_08<8000, mcolor(maroon)) || (scatter AIOE_reduced isco_2000 if occup_isco_08>=8000 & occup_isco_08<9000, mcolor(black)) || (scatter AIOE_reduced isco_2000 if occup_isco_08>=9000 & occup_isco_08<10000, mcolor(purple)), legend(order( 1 "Managers" 2 "Professionals" 3 "Technicians and associate professionals" 4 "Clerical support worker" 5 "Service and sales workers" 6 "Skilled agricultural, forestry and fishery workers" 7 "Craft and related trades workers" 8 "Plant and machine operators and assemblers" 9 "Elementary occupations") position(6) col(2))  title("2 digit occupations by occupation categories", size (medium)) graphregion(color(white)) xlabel(0 (1000) 9000) saving(2digit, replace)


graph twoway (scatter AIOE_reduced_1digit occup2 if occup==1, mcolor(blue))  || (scatter AIOE_reduced_1digit occup2 if occup==2, mcolor(red)) || (scatter AIOE_reduced_1digit occup2 if occup==3, mcolor(green)) || (scatter AIOE_reduced_1digit occup2 if occup==4, mcolor(orange)) ||  (scatter AIOE_reduced_1digit occup2 if occup==5, mcolor(yellow))  || (scatter AIOE_reduced_1digit occup2 if occup==6, mcolor(navy)) || (scatter AIOE_reduced_1digit occup2 if occup==7, mcolor(maroon)) || (scatter AIOE_reduced_1digit occup2 if occup==8, mcolor(black)) || (scatter AIOE_reduced_1digit occup2 if occup==9, mcolor(purple)), legend(order( 1 "Managers" 2 "Professionals" 3 "Technicians and associate professionals" 4 "Clerical support worker" 5 "Service and sales workers" 6 "Skilled agricultural, forestry and fishery workers" 7 "Craft and related trades workers" 8 "Plant and machine operators and assemblers" 9 "Elementary occupations") position(6) col(2))  title("1 digit occupations by occupation categories", size (medium)) graphregion(color(white)) xlabel(0 (1000) 9000) saving(broad, replace)


grc1leg  2digit.gph detailed.gph, ycommon xcommon legendfrom(detailed.gph) title("AI occupation exposure information detail for 2 digit and 4 digit ISCO codes") 

graph export "$figure\Occupation_combined.png", replace
restore
		
		

	
	
		
		
		