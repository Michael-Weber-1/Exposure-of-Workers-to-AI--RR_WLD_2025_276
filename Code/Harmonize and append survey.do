
********************************************************
***** Harmonize and Append GLD surveys *********** 
********************************************************


set varabbrev off // to always specify the correct variable



*******************************
**** Create GLD-ADD dataset ***

* Set to the path where the datasets are stored
cd "$data/GLD-Add"


capture erase "$data/GLD-Add/original/filelist.dta"
global sub_search "$data/GLD-Add/last_survey"

filelist, dir("$sub_search") pat(*.dta) save("$sub_search/filelist.dta") //List all .dta files in the folder

use "$sub_search/filelist.dta", clear

* Open all files in the folder and reduce to the key variables

levels filename
foreach var in `r(levels)'{
cd "$data/GLD-Add/last_survey"
use "`var'", clear
cap noisily gen isco_version=.
cap noisily gen empstat=.
cap noisily gen wage_no_compen=.
cap noisily gen unitwage=.
cap noisily gen whours=.
cap noisily gen urban=.
cap noisily gen occup=.
cap noisily gen educat4=.
cap destring occup_orig, replace
cap noisily gen electricity=.
cap noisily gen internet=.
keep countrycode survey  isco_version year  industry* occup* weight  male age lstatus empstat wage_no_compen unitwage whours urban educat4 electricity internet 
  
cd "$data/GLD-Add/append" 
save `var', replace
}
erase "$sub_search/filelist.dta"


* Append all data files in the directory: and generate variable sample as data file name in case missing

! dir *.dta /a-d /b >filelist.txt

file open myfile using filelist.txt, read

file read myfile line
while r(eof)==0 { /* while you're not at the end of the file */
	append using `line', force
	capture replace sample1="`line'" if sample1==""
	erase `line'
	file read myfile line
}
file close myfile
erase filelist.txt

keep countrycode survey  isco_version year  weight industry_orig industrycat_isic industrycat10 industrycat4 occup occup_orig occup_isco occup_skill  male age lstatus empstat wage_no_compen unitwage whours urban educat4 electricity internet
  

gen harmonise="GLD"
label var harmonise "Original data source"
compress

save "$data/GLD_All_last", replace  
