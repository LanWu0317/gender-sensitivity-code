/*==============================================================================
Reference: Bentze, T., Wollburg, P. A longitudinal cross-country dataset on agricultural productivity and welfare in Sub-Saharan Africa. Sci Data 12, 1843 (2025). 
https:doi.org/10.1038/s41597-025-05639-9
==============================================================================*/

**# individual dataset

g hhid = hh_id_merge if country == "Ethiopia"
replace hhid = substr(hh_id_merge,1,6)+substr(hh_id_merge,11,8) if length(hhid) > 14
g ea = ea_id_merge if country == "Ethiopia"
replace ea = substr(ea_id_merge,1,6)+substr(ea_id_merge,11,5) if length(ea) > 11
g indiv = indiv_id_merge if country == "Ethiopia"
replace indiv = substr(indiv_id_merge,1,6)+substr(indiv_id_merge,11,10) if length(indiv) > 16
replace indiv = substr(indiv,15,2)
destring indiv,replace

cd "D:\climate_gender\Malawi\"
merge m:1 country hh_id_merge using 2010_2013_hhid.dta
drop if _merge == 2
drop _merge
merge m:1 country indiv_id_merge using 2013_pid.dta
drop if _merge == 2
drop _merge
replace hhid = case_id if year == 2013 & country == "Malawi"
replace ea = ea_id_merge if year == 2013 & country == "Malawi"
replace indiv = hh_c01 if year == 2013 & country == "Malawi"
drop case_id hh_c01

replace hhid = subinstr(hh_id_merge,"-","",.) if country == "Mali"
replace ea = ea_id_merge if country == "Mali"
g indiv_str = subinstr(indiv_id_merge,"-","",.) if country == "Mali"
replace indiv_str = subinstr(indiv_str,hhid,"",1) if country == "Mali"
destring indiv_str,replace
replace indiv = indiv_str if country == "Mali"
drop indiv_str

replace hhid = hh_id_merge if year == 2011 & country == "Niger"
replace ea = substr(hh_id_merge,1,length(hh_id_merge)-2) if year == 2011 & country == "Niger"
g indiv_str = subinstr(indiv_id_merge,"-","",.) if year == 2011 & country == "Niger"
replace indiv_str = subinstr(indiv_str,hhid,"",1) if year == 2011 & country == "Niger"
destring indiv_str,replace
replace indiv = indiv_str if year == 2011 & country == "Niger"
drop indiv_str
replace ea = substr(hh_id_merge,1,strpos(hh_id_merge,"-")-1) if year == 2014 & country == "Niger"
g ea_num = ea if year == 2014 & country == "Niger"
destring ea_num,replace
g hh_num = substr(hh_id_merge,strpos(hh_id_merge,"-")+1,strrpos(hh_id_merge,"-")-strpos(hh_id_merge,"-")-1) if year == 2014 & country == "Niger"
destring hh_num,replace
replace hh_num = ea_num*100+hh_num
tostring hh_num,replace
replace hhid = hh_num if year == 2014 & country == "Niger"
drop ea_num hh_num
g indiv_str = substr(indiv_id_merge,strrpos(indiv_id_merge,"-")+1,.) if year == 2014 & country == "Niger"
destring indiv_str,replace
replace indiv = indiv_str if year == 2014 & country == "Niger"
drop indiv_str

replace hhid = hh_id_merge if country == "Nigeria"
replace ea = substr(ea_id_merge,strpos(ea_id_merge,"-")+1,.) if country == "Nigeria"
g indiv_str = substr(indiv_id_merge,strpos(indiv_id_merge,"-")+1,.) if country == "Nigeria"
destring indiv_str,replace
replace indiv = indiv_str if country == "Nigeria"
drop indiv_str

replace hhid = hh_id_merge if country == "Tanzania"
replace ea = ea_id_merge if country == "Tanzania" //remain as original code
g indiv_str = substr(indiv_id_merge,strrpos(indiv_id_merge,"-")+1,.) if country == "Tanzania"
destring indiv_str,replace
replace indiv = indiv_str if country == "Tanzania"
drop indiv_str
cd "D:\climate_gender\Tanzania\"
merge m:1 country hh_id_merge year using 2010_2012_hhid
drop if _merge == 2
drop _merge
replace hhid = hh_a09 if year == 2012 & country == "Tanzania"
drop hh_a09

replace hhid = hh_id_merge if country == "Uganda"
replace ea = substr(hh_id_merge,1,8) if country == "Uganda"
g indiv_str = substr(indiv_id_merge,length(indiv_id_merge)-1,2) if country == "Uganda"
destring indiv_str,replace
replace indiv = indiv_str if country == "Uganda"
drop indiv_str

***aggregate to indiv-level
drop *merge ea
local var "livestock"
foreach i of local var{
	bysort country year hhid indiv: egen `i'_m = max(`i')
	replace `i' = `i'_m
	drop `i'_m
}
duplicates drop country year hhid indiv,force

g nonfarm_work = (SOB_work == 1|wage_work == 1|(SB_hrs > 0 & SB_hrs != .)|(wage_hrs > 0 & wage_hrs != .)|ind_mining == 1|ind_manuf == 1|ind_const == 1|ind_serv == 1)


**# plot dataset

g hhid = hh_id_merge if country == "Ethiopia"
replace hhid = substr(hh_id_merge,1,6)+substr(hh_id_merge,11,8) if length(hhid) > 14
g ea = ea_id_merge if country == "Ethiopia"
replace ea = substr(ea_id_merge,1,6)+substr(ea_id_merge,11,5) if length(ea) > 11
g plotid = substr(parcel_id_merge,strrpos(parcel_id_merge,"-")+1,.) if country == "Ethiopia"
rename manager_id_merge indiv
replace indiv = "" if country != "Ethiopia"
replace indiv = substr(indiv,1,6)+substr(indiv,11,10) if length(indiv) > 16
replace indiv = substr(indiv,15,2)
destring indiv,replace

cd "D:\climate_gender\Malawi\"
merge m:1 country hh_id_merge using 2010_2013_hhid.dta
drop if _merge == 2
drop _merge
replace hhid = case_id if year == 2013 & country == "Malawi"
replace ea = ea_id_merge if year == 2013 & country == "Malawi"
replace plotid = substr(plot_id_merge,strrpos(plot_id_merge,"-")+1,.) if country == "Malawi"
replace plotid = subinstr(plotid,"0","",1) if country == "Malawi"
drop case_id

replace hhid = subinstr(hh_id_merge,"-","",.) if country == "Mali"
replace ea = ea_id_merge if country == "Mali"
g bloc = substr(parcel_id_merge,strrpos(parcel_id_merge,"-")+1,.) if country == "Mali"
g parcel = substr(plot_id_merge,strrpos(plot_id_merge,"-")+1,.) if country == "Mali"
destring bloc parcel,replace
cd "D:\climate_gender\Mali\"
merge m:1 country hhid bloc parcel using 2014_plotid
drop if _merge == 2
drop _merge
tostring s1cq00,replace
replace plotid = s1cq00 if country == "Mali"
drop s1cq00 bloc parcel

replace hhid = hh_id_merge if year == 2011 & country == "Niger"
replace ea = substr(hh_id_merge,1,length(hh_id_merge)-2) if year == 2011 & country == "Niger"
replace ea = substr(hh_id_merge,1,strpos(hh_id_merge,"-")-1) if year == 2014 & country == "Niger"
g ea_num = ea if year == 2014 & country == "Niger"
destring ea_num,replace
g hh_num = substr(hh_id_merge,strpos(hh_id_merge,"-")+1,strrpos(hh_id_merge,"-")-strpos(hh_id_merge,"-")-1) if year == 2014 & country == "Niger"
destring hh_num,replace
replace hh_num = ea_num*100+hh_num
tostring hh_num,replace
replace hhid = hh_num if year == 2014 & country == "Niger"
drop ea_num hh_num
g field = substr(parcel_id_merge,strrpos(parcel_id_merge,"-")+1,.) if country == "Niger"
g parcel = substr(plot_id_merge,strrpos(plot_id_merge,"-")+1,.) if country == "Niger"
destring field parcel,replace
cd "D:\climate_gender\Niger\"
merge m:1 country year hhid field parcel using 2011_2014_plotid
drop if _merge == 2
drop _merge
tostring id_num,replace
replace plotid = id_num if country == "Niger"
drop id_num field parcel

replace hhid = hh_id_merge if country == "Nigeria"
replace ea = substr(ea_id_merge,strpos(ea_id_merge,"-")+1,.) if country == "Nigeria"
replace plotid = substr(plot_id_merge,strpos(plot_id_merge,"-")+1,.) if country == "Nigeria"

replace hhid = hh_id_merge if country == "Tanzania"
replace ea = ea_id_merge if country == "Tanzania"
replace plotid = substr(plot_id_merge,strrpos(plot_id_merge,"-")+1,.) if country == "Tanzania"
cd "D:\climate_gender\Tanzania\"
merge m:1 country hh_id_merge year using 2010_2012_hhid
drop if _merge == 2
drop _merge
replace hhid = hh_a09 if year == 2012 & country == "Tanzania"
drop hh_a09

replace hhid = hh_id_merge if country == "Uganda"
replace ea = substr(hh_id_merge,1,8) if country == "Uganda"
replace plotid = substr(plot_id_merge,strrpos(plot_id_merge,"-")+1,.) if country == "Uganda"

***aggregate to plot-level
drop *merge ea
local var "crop_shock drought_shock rain_shock pests_shock flood_shock"
foreach i of local var{
	bysort country year hhid plotid indiv: egen `i'_m = max(`i')
	replace `i' = `i'_m
	drop `i'_m
}
duplicates drop country year hhid plotid indiv,force

local var "improved irrigated"
foreach i of local var{
	bysort country year hhid plotid indiv: egen `i'_m = max(`i')
	replace `i' = `i'_m
	drop `i'_m
}
duplicates drop country year hhid plotid indiv,force

foreach var in dist_popcenter dist_market elevation twi plot_dist_household plot_slope{
	bysort country year hhid plotid indiv: egen `var'_m = mean(`var')
	replace `var' = `var'_m
	drop `var'_m
}
duplicates drop country year hhid plotid indiv,force

foreach var in plot_certificate nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability erosion_protection organic_fertilizer{
    bysort country year hhid plotid indiv: egen `var'_m = max(`var')
	replace `var' = `var'_m
	drop `var'_m
}
duplicates drop country year hhid plotid indiv,force

foreach var in inorganic_fertilizer used_pesticides{
    bysort country year hhid plotid indiv: egen `var'_m = max(`var')
	replace `var' = `var'_m
	drop `var'_m
}
foreach var in seed_kg seed_value_LCU seed_value_USD nitrogen_kg inorganic_fertilizer_value_LCU inorganic_fertilizer_value_USD{
    bysort country year hhid plotid indiv: egen `var'_m = mean(`var')
	replace `var' = `var'_m
	drop `var'_m
}
duplicates drop country year hhid plotid indiv,force
