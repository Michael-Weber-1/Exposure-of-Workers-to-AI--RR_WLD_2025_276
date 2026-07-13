




use "$data/I2D2/USA_2018_I2D2_CPS.dta", clear


** recode I2D2 to GLD: 

	* Rename weight (no capture as it makes no sense w/o)
	rename  wgt weight
	
	* Rename, recode male
	
	    rename  gender male
		recode male 2=0
		label define male  0 "Female" 1 "Male"
		label val male male
	
	
	* Rename, recode urban

	    rename  urb urban
		recode urban 2=0
		label define urban 1 "Urban" 0 "Rural"
		label val urban urban
	
	
	* Generate Country Code
	gen str countrycode=ccode
	label var countrycode "Country Code"

	* Generate Household ID
	cap gen hhid=.
	cap replace hhid=idh
	label var hhid "Household ID"
	
	* Rename Household size
		rename hhsize hsize
	
	
	
	* Rename educat7 
	    rename  edulevel1 educat7
	

	* Rename educat5 
	    rename  edulevel2 educat5

	
	* Rename educat4 
	    rename  edulevel3 educat4
	
	
	* Rename industrycat10 
	    rename  industry industrycat10
	
	
	* Rename industrycat4 
	    rename  industry1 industrycat4
	
	
	* Rename wage info
	  gen wage_no_compen=.
	
	
	* Rename regional code
	    rename  reg01 subnatid1
	


	
	
	
	
	
	
	
	
save "$data/I2D2/USA_GLD.dta", replace	