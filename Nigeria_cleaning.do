/*===========================================================================
Plot-level panel dataset for Nigeria 
GHS Waves 1-3: 2010, 2012, 2015
===========================================================================*/

** Wave 1 (2010) raw data roots
global w1root   "D:/climate_gender/Nigeria/Nigeria_Survey_Data/NGA_2010_GHSP-W1_v03_M_STATA"
global w1ppa    "$w1root/Post Planting Wave 1/Agriculture"
global w1pph    "$w1root/Post Planting Wave 1/Household"
global w1pha    "$w1root/Post Harvest Wave 1/Agriculture"
global w1phh    "$w1root/Post Harvest Wave 1/Household"
global w1geo    "$w1root/Geodata"
global w1conv   "$w1root/w1agnsconversion.dta"

** Wave 2 (2012) raw data roots
global w2root   "D:/climate_gender/Nigeria/Nigeria_Survey_Data/2012_Survey"
global w2ppa    "$w2root/Post Planting Wave 2/Agriculture"
global w2pph    "$w2root/Post Planting Wave 2/Household"
global w2pha    "$w2root/Post Harvest Wave 2/Agriculture"
global w2phh    "$w2root/Post Harvest Wave 2/Household"
global w2geo    "$w2root/Geodata Wave 2"
global w2conv   "$w2root/w2agnsconversion.dta"

** Wave 3 (2015) raw data root (all files in one directory)
global w3root   "D:/climate_gender/Nigeria/Nigeria_Survey_Data/2015_Survey"
global w3conv   "$w3root/ag_conv_w3.dta"


/*===========================================================================
  SECTION 1 – WAVE 1 (2010)
===========================================================================*/

/*--- 1A. Household cover ---*/
use "$w1pph/sect1a_plantingw1.dta", clear
keep hhid zone state lga ea
duplicates drop hhid, force
tempfile w1_cover
save `w1_cover'

/*--- 1B. Plot roster: plotid, crop list, manager ---*/
use "$w1ppa/sect11a1_plantingw1.dta", clear
rename s11aq1 cropcode
bysort hhid plotid (cropcode): gen crop_seq = _n

** Plot manager individual ID
gen manager_id = s11aq6a
replace manager_id = s11aq6b if missing(s11aq6a)

keep hhid plotid main_crop manager_id
duplicates drop hhid plotid, force
tempfile w1_plotroster
save `w1_plotroster'

/*--- 1C. Plot area ---*/
use "$w1ppa/sect11a1_plantingw1.dta", clear
** GPS area: square metres → convert to hectares
gen gps_area = s11aq4c / 10000 if s11aq4c > 0 & !missing(s11aq4c)

** Farmer-reported area
merge m:1 hhid using `w1_cover', keep(1 3) nogen
gen rep_area = .
replace rep_area = s11aq4b * 5.5  / 10000 if s11aq4a == 1
replace rep_area = s11aq4b * 15   / 10000 if s11aq4a == 2
replace rep_area = s11aq4b * 0.5  / 10000 if s11aq4a == 3
replace rep_area = s11aq4b * 0.04 if s11aq4a == 4
replace rep_area = s11aq4b * 0.404686 if s11aq4a == 5
replace rep_area = s11aq4b if s11aq4a == 6
replace rep_area = s11aq4b / 10000 if s11aq4a == 7

** Prefer GPS if available
gen parea = gps_area if !missing(gps_area)
replace parea = rep_area if missing(parea) & !missing(rep_area)
bysort hhid: egen farm_size = sum(parea)
keep hhid plotid parea gps_area rep_area farm_size
duplicates drop hhid plotid, force
tempfile w1_area
save `w1_area'

** Planted share (status)
use "crop_area" //converted to hectare
keep zone hhid plotid year plant_area //self-reported area
duplicates drop zone hhid plotid year,force
merge 1:1 zone hhid plotid year using plot_size
keep if _merge == 3
drop _merge
g parea_threshold = parea*0.5
g portion_planted = (plant_area < parea_threshold)
save "planting_share.dta"

/*--- 1D. Conversion table: quantity units → kg ---*/
** Wave 1/2 use nscode-based conversion
use "$w1conv", clear
rename agcropid cropcode
tempfile w1_convtable
save `w1_convtable'

/*--- 1E. Harvest quantities and crop value ---*/
use "$w1pha/secta3_harvestw1.dta", clear
keep if sa3q3 == 1
rename sa3q6a2 nscode
rename sa3q6a  qty_harvest
rename sa3q2   cropcode

** Merge conversion factors
merge m:1 nscode cropcode using `w1_convtable', keep(1 3) nogen
** Convert to kg
gen qty_kg = qty_harvest * conversion
replace qty_kg = 0 if qty_kg < 0 | missing(qty_kg)

** Crop value
gen harvest_value = sa3q18 if !missing(sa3q18) & sa3q18 > 0
** Compute mean price from plots that sold and have non-missing price
gen unit_price = sa3q18 / qty_kg if qty_kg > 0 & !missing(sa3q18)
bysort cropcode: egen mean_price = mean(unit_price)
replace harvest_value = qty_kg * mean_price if missing(harvest_value) | harvest_value == 0

** Aggregate to plot level (sum across crops on same plot)
collapse (sum) harvest_value qty_kg, by(hhid plotid)
tempfile w1_harvest
save `w1_harvest'

** Harvested share (status)
keep zone ea hhid plotid sa3q1 sa3q4 sa3q4b
g harvest_less = (sa3q4 == 9|sa3q4b == "NO FRUIT YET"|sa3q4b == "BEEB HAR,BEFORE VISI"|sa3q4b == "HAARVESTED BEFORE"|sa3q4b == "HAEVESTED BEFORE"|sa3q4b == "HAR B/F LAST VISIT"|sa3q4b == "HAR.B/F LAST  VISIT"|sa3q4b == "HAR.B/F LAST VISIT"|sa3q4b == "HARVCESTED BEFORE"|sa3q4b == "HARVESSTED BEFORE"|sa3q4b == "HARVEST B/4 LAST"|sa3q4b == "HARVEST BEFORE"|sa3q4b == "HARVEST BEFORE VISIT"|sa3q4b == "HARVESTED"|sa3q4b == "HARVESTED BEFORE"|sa3q4b == "HARVESTED BEFOREW"|sa3q4b == "HARVESTED EARLIER"|sa3q4b == "HAVESTED BEFORE"|sa3q4b == "IMMATURE"|sa3q4b == "IMMATURED"|sa3q4b == "NO FRIUT YET"|sa3q4b == "NO FRUIT"|sa3q4b == "NO FRUIT YET"|sa3q4b == "NOT AVAILABLE SEASON"|sa3q4b == "NOT JET MATURE"|sa3q4b == "NOT MATURE"|sa3q4b == "NOT MATURE YET"|sa3q4b == "NOT MATURED"|sa3q4b == "NOT MATURED FOR HARV"|sa3q4b == "NOT NATURED"|sa3q4b == "NOT READY"|sa3q4b == "NOT RIPE FOR HARVEST"|sa3q4b == "NOT YET READ"|sa3q4b == "Not due for harvest"|sa3q4b == "UNMATURED FOR HARVT"|sa3q4b == "WAITING FOR CROP BUY"|sa3q4b == "WAITING FOR CROP HAR")
g year = 2010
bysort zone ea hhid plotid: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1-harvest_complete
keep zone ea hhid plotid year harvest_complete
duplicates drop zone ea hhid plotid year,force

/*--- 1F. Post-Planting labor ---*/
use "$w1ppa/sect11c_plantingw1.dta", clear
** Wave 1: sect11c (combined file, unlike W2/W3 which separate labor/pesticide)
** Family labor (4 household members a-d): days × weeks
foreach m in a b c d {
    gen pp_fam_`m' = s11cq1`m'2 * s11cq1`m'3 if !missing(s11cq1`m'2) & !missing(s11cq1`m'3)
    replace pp_fam_`m' = 0 if missing(pp_fam_`m')
}
gen pp_fam_days = pp_fam_a + pp_fam_b + pp_fam_c + pp_fam_d

** Hired labor: man-days, woman-days, child-days
gen pp_hire_man   = s11cq2 * s11cq3   if !missing(s11cq2) & !missing(s11cq3)
gen pp_hire_woman = s11cq5 * s11cq6   if !missing(s11cq5) & !missing(s11cq6)
gen pp_hire_child = s11cq8 * s11cq9   if !missing(s11cq8) & !missing(s11cq9)
foreach v of varlist pp_hire_* { replace `v' = 0 if missing(`v') }
gen pp_hire_days  = pp_hire_man + pp_hire_woman + pp_hire_child

gen pp_labor = pp_fam_days + pp_hire_days

collapse (sum) pp_labor pp_fam_days pp_hire_days, by(hhid plotid)
tempfile w1_pplabor
save `w1_pplabor'

/*--- 1H. Fertilizer ---*/
use "$w1ppa/sect11d_plantingw1.dta", clear
** N-equivalents: UREA × 0.46, NPK × 0.2, others 0.15

** Source 1: Leftover from previous season
** s11dq3 = fertilizer type, s11dq4 = quantity (kg)
gen fert_n_s1 = s11dq4 * 0.46 if s11dq3 == 1
replace fert_n_s1 = s11dq4 * 0.20 if s11dq3 == 2
replace fert_n_s1 = s11dq4 * 0.15 if !inlist(s11dq3,1,2) & !missing(s11dq3)
replace fert_n_s1 = 0 if missing(fert_n_s1)

** Source 2: Free/subsidized fertilizer
** s11dq7 = type, s11dq8 = quantity
gen fert_n_s2 = s11dq8 * 0.46 if s11dq7 == 1
replace fert_n_s2 = s11dq8 * 0.20 if s11dq7 == 2
replace fert_n_s2 = s11dq8 * 0.15 if !inlist(s11dq7,1,2) & !missing(s11dq7)
replace fert_n_s2 = 0 if missing(fert_n_s2)

** Source 3: Commercial purchase 1
** s11dq15 = type, s11dq16 = quantity
gen fert_n_s3 = s11dq16 * 0.46 if s11dq15 == 1
replace fert_n_s3 = s11dq16 * 0.20 if s11dq15 == 2
replace fert_n_s3 = s11dq16 * 0.15 if !inlist(s11dq15,1,2) & !missing(s11dq15)
replace fert_n_s3 = 0 if missing(fert_n_s3)

** Source 4: Commercial purchase 2
** s11dq27 = type, s11dq28 = quantity
gen fert_n_s4 = s11dq28 * 0.46 if s11dq27 == 1
replace fert_n_s4 = s11dq28 * 0.20 if s11dq27 == 2
replace fert_n_s4 = s11dq28 * 0.15 if !inlist(s11dq27,1,2) & !missing(s11dq27)
replace fert_n_s4 = 0 if missing(fert_n_s4)

gen fertilizer_n = fert_n_s1 + fert_n_s2 + fert_n_s3 + fert_n_s4
gen fert_any     = (fertilizer_n > 0) if !missing(fertilizer_n)

** Fertilizer cost (for input value)
gen fertilizer_cost = 0
capture replace fertilizer_cost = fertilizer_cost + s11dq17 if !missing(s11dq18)
capture replace fertilizer_cost = fertilizer_cost + s11dq29 if !missing(s11dq31)

collapse (sum) fertilizer_n fert_any fertilizer_cost, by(hhid plotid)
tempfile w1_fert
save `w1_fert'

/*--- 1I. Seeds ---*/
use "$w1ppa/sect11e_plantingw1.dta", clear
** 4 sources of seed: leftover, free, commercial1, commercial2
gen seed_cost = 0
capture replace seed_cost = seed_cost + s11eq21 if !missing(s11eq20)
capture replace seed_cost = seed_cost + s11eq33 if !missing(s11eq31)

** Seed quantity (kg, for calculation of seed input value if no cost data)
** s11eq6a = leftover qty, s11eq10a = free qty, s11eq18a = commercial1 qty, s11eq30a = commercial2 qty
gen seed_qty = 0
capture replace seed_qty = seed_qty + s11eq6a  if !missing(s11eq6a)
capture replace seed_qty = seed_qty + s11eq10a if !missing(s11eq10a)
capture replace seed_qty = seed_qty + s11eq18a if !missing(s11eq18a)
capture replace seed_qty = seed_qty + s11eq30a if !missing(s11eq30a)

collapse (sum) seed_cost seed_qty, by(hhid plotid)
** Use seed_cost as seed value input
gen seed_value = seed_cost
tempfile w1_seeds
save `w1_seeds'

/*--- 1J. Pesticides / Herbicides ---*/
use "$w1ppa/sect11c_plantingw1.dta", clear
** Pesticide use
gen pesticide = (s11cq1 == 1) if !missing(s11cq1)
replace pesticide = 0 if missing(pesticide)

gen herbicide = (s11cq10 == 1) if !missing(s11cq10)
replace herbicide = 0 if missing(herbicide)

** Pesticide cost
egen pest_cost = rowtotal(s11cq4a s11cq4b s11cq5a s11cq5b)
egen herb_cost = rowtotal(s11cq14a s11cq14b)

collapse (max) pesticide herbicide (sum) pest_cost herb_cost, by(hhid plotid)
tempfile w1_pest
save `w1_pest'

/*--- 1K. Plot geovars ---*/
use "$w1geo/NGA_PlotGeovariables_Y1.dta", clear
** srtmslp_nga = slope (%), srtm_nga = elevation (m), twi_nga = TWI
keep hhid plotid srtmslp_nga srtm_nga twi_nga
rename srtmslp_nga plot_slope
rename srtm_nga    plot_elev
rename twi_nga     plot_wet
** Impute missing with sample means (from reference code)
replace plot_slope = 2.970942 if missing(plot_slope)
replace plot_elev  = 330.1089 if missing(plot_elev)
replace plot_wet   = 14.54859 if missing(plot_wet)
tempfile w1_plotgeo
save `w1_plotgeo'

/*--- 1L. Household geovars for soil quality PCA ---*/
use "$w1geo/NGA_HouseholdGeovariables_Y1.dta", clear
rename ea ea_id
forvalues i=1/7{
recode sq`i' (1=1) (2/7=0), gen(sq`i'_d)
}
factor sq1_d-sq7_d, pcf 
predict soil_fertility_pca

local names "nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability"
forvalues n =1/7 {
local lab: word `n' of `names'
rename sq`n'_d `lab'
}

keep hhid nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability soil_fertility_pca
duplicates drop hhid, force
tempfile w1_hhgeo
save `w1_hhgeo'

/*--- 1M. Manager characteristics (gender, age, education, marital status) ---*/
** Step 1: Get manager individual ID from plot roster (already in w1_plotroster)
** Step 2: Merge to harvest-round household roster for sex/age/marital
use "$w1phh/sect1_harvestw1.dta", clear
keep hhid indiv s1q2 s1q4 s1q7
rename indiv  manager_id
rename s1q2   sex
rename s1q4   age
rename s1q7   marital
tempfile w1_roster
save `w1_roster'

** Step 3: Education from harvest-round individual questionnaire
use "$w1phh/sect2a_harvestw1.dta", clear
keep hhid indiv s2aq6 s2aq9
duplicates drop hhid indiv, force
gen primary_edu = (s2aq9 >= 1 & s2aq9 <= 6) if !missing(s2aq9)
gen edu_years   = s2aq9 if s2aq9 >= 0 & s2aq9 < 99
rename indiv manager_id
tempfile w1_edu
save `w1_edu'

** Merge manager characteristics to plot-level
use `w1_plotroster', clear
merge m:1 hhid manager_id using `w1_roster', keep(1 3) nogen
merge m:1 hhid manager_id using `w1_edu', keep(1 3) nogen

gen female = (sex == 2) if !missing(sex)
gen age2   = age^2
gen married= (marital == 1) if !missing(marital)

keep hhid plotid manager_id female age age2 married primary_edu edu_years main_crop
tempfile w1_manager
save `w1_manager'

/*--- 1N. HH characteristics ---*/
** Electricity access
use "$w1phh/sect8_harvestw1.dta", clear
keep hhid s8q17
recode s8q17 (1=1) (2=0), gen(electricity)
duplicates drop hhid, force
tempfile w1_elec
save `w1_elec'

** Livestock value
use "$w1ppa/sect11i_plantingw1.dta", clear
capture gen livestock_value = s11iq2 * s11iq3
if _rc != 0 gen livestock_value = 0
collapse (sum) livestock_value, by(hhid)
tempfile w1_livestock
save `w1_livestock'

** Dependency ratio (% household members < 15 or > 65 / total)
use "$w1pph/sect1_plantingw1.dta", clear
keep hhid indiv s1q4
capture rename s1q3 age_p
gen child = (age_p < 15)  if !missing(age_p)
gen elderly = (age_p > 65) if !missing(age_p)
bysort hhid: gen hhsize = _N
collapse (sum) child elderly (mean) hhsize, by(hhid)
gen child_depend = (child + elderly) / hhsize
drop child elderly
tempfile w1_hhsize
save `w1_hhsize'

** Religion of HH head
use "$w1pph/sect1_plantingw1.dta", clear
** religion: 1=Christian, 2=Muslim, etc. 
capture gen religion = s1q12 if !missing(s1q16)
if _rc != 0 gen religion = .
gen muslim  = (religion == 2) if !missing(religion)
gen hhhsex  = s1q2 if !missing(s1q2)
keep hhid indiv religion muslim hhhsex
tempfile w1_religion
save `w1_religion'

** Plot tenure and irrigation
use "$w1ppa/sect11b_plantingw1.dta", clear
rename s11bq6 owner
capture gen irrigate = (s11b1q39 == 1) if !missing(s11b1q39)
capture gen irrigate = (s11bq39  == 1) if !missing(s11bq39)   // !! VERIFY
if _rc != 0 gen irrigate = .
** Fallow: s11b1q28/q27  !! VERIFY
capture gen fallow = (s11b1q28 == 1 | s11b1q27 == 1)
capture gen fallow = (s11bq28  == 1 | s11bq27  == 1)   // !! VERIFY
if _rc != 0 gen fallow = .
keep hhid plotid owner irrigate fallow
duplicates drop hhid plotid, force
tempfile w1_tenure
save `w1_tenure'

/*--- 1O. Plot characteristics ---*/
capture {
    use "$w1geo/NGA_PlotGeovariables_Y1.dta", clear
    keep hhid plotid dist_household srtmslp_nga srtm_nga twi_nga
    tempfile w1_dist
    save `w1_dist'
}

/*--- 1P. Assemble Wave 1 plot-level dataset ---*/
use `w1_harvest', clear
merge 1:1 hhid plotid using `w1_area',     keep(1 3) nogen
merge 1:1 hhid plotid using `w1_pplabor',  keep(1 3) nogen
merge 1:1 hhid plotid using `w1_fert',     keep(1 3) nogen
merge 1:1 hhid plotid using `w1_seeds',    keep(1 3) nogen
merge 1:1 hhid plotid using `w1_pest',     keep(1 3) nogen
merge 1:1 hhid plotid using `w1_plotgeo',  keep(1 3) nogen
merge 1:1 hhid plotid using `w1_manager',  keep(1 3) nogen
merge 1:1 hhid plotid using `w1_tenure',   keep(1 3) nogen
merge m:1 hhid using `w1_cover',           keep(1 3) nogen
merge m:1 hhid using `w1_elec',            keep(1 3) nogen
merge m:1 hhid using `w1_livestock',       keep(1 3) nogen
merge m:1 hhid using `w1_hhsize',          keep(1 3) nogen
merge m:1 hhid using `w1_religion',        keep(1 3) nogen
merge m:1 hhid using `w1_hhgeo',           keep(1 3) nogen
capture merge m:1 hhid using `w1_dist',    keep(1 3) nogen

** Total labor days
gen total_labor = pp_labor + ph_labor
replace total_labor = 0 if missing(total_labor)

** Year identifier
gen year = 2010

** Replace any remaining missing values in key variables
foreach v of varlist fertilizer_n seed_cost pesticide tractor fallow {
    replace `v' = 0 if missing(`v')
}

save "$intdir/2010_harvest.dta", replace

/*===========================================================================
  SECTION 2 – WAVE 2 (2012)
===========================================================================*/

/*--- 2A. Household cover ---*/
use "$w2pph/sect1_plantingw2.dta", clear
keep hhid zone state lga ea
duplicates drop hhid, force
tempfile w2_cover
save `w2_cover'

/*--- 2B. Plot roster ---*/
use "$w2ppa/sect11a1_plantingw2.dta", clear
rename s11aq1 cropcode
bysort hhid plotid (cropcode): gen crop_seq = _n
gen main_crop_code = cropcode if crop_seq == 1
bysort hhid plotid: egen main_crop = max(main_crop_code)
gen manager_id = s11aq6a
replace manager_id = s11aq6b if missing(s11aq6a)
keep hhid plotid main_crop manager_id
duplicates drop hhid plotid, force
tempfile w2_plotroster
save `w2_plotroster'

/*--- 2C. Plot area ---*/
use "$w2ppa/sect11a1_plantingw2.dta", clear
gen gps_area = s11aq4c / 10000 if s11aq4c > 0 & !missing(s11aq4c)
merge m:1 hhid using `w2_cover', keep(1 3) nogen
gen rep_area = .
replace rep_area = s11aq4b * 5.5  / 10000 if s11aq4a == 1
replace rep_area = s11aq4b * 15   / 10000 if s11aq4a == 2
replace rep_area = s11aq4b * 0.5  / 10000 if s11aq4a == 3
replace rep_area = s11aq4b * 0.04          if s11aq4a == 4
replace rep_area = s11aq4b * 0.404686      if s11aq4a == 5
replace rep_area = s11aq4b                 if s11aq4a == 6
replace rep_area = s11aq4b / 10000         if s11aq4a == 7
gen parea = gps_area if !missing(gps_area)
replace parea = rep_area if missing(parea) & !missing(rep_area)
bysort hhid: egen farm_size = sum(parea)
keep hhid plotid parea gps_area rep_area farm_size
duplicates drop hhid plotid, force
tempfile w2_area
save `w2_area'

** Planted share (status)
use "crop_area" //converted to hectare
keep zone hhid plotid year plant_area //self-reported area
duplicates drop zone hhid plotid year,force
merge 1:1 zone hhid plotid year using plot_size
keep if _merge == 3
drop _merge
g parea_threshold = parea*0.5
g portion_planted = (plant_area < parea_threshold)
save "planting_share.dta"

/*--- 2D. Conversion table ---*/
use "$w2conv", clear
tempfile w2_convtable
save `w2_convtable'

/*--- 2E. Harvest ---*/
use "$w2pha/secta3_harvestw2.dta", clear
keep if sa3q3 == 1
rename sa3q6a2 nscode
rename sa3q6a  qty_harvest
rename sa3q2   cropcode
merge m:1 nscode cropcode using `w2_convtable', keep(1 3) nogen
gen qty_kg = qty_harvest * conversion
replace qty_kg = 0 if qty_kg < 0 | missing(qty_kg)
gen unit_price = sa3q18 / qty_kg if qty_kg > 0 & !missing(sa3q18)
bysort cropcode_h: egen median_price = median(unit_price)
gen harvest_value = sa3q18 if !missing(sa3q18) & sa3q18 > 0
replace harvest_value = qty_kg * median_price if missing(harvest_value) | harvest_value == 0
collapse (sum) harvest_value qty_kg, by(hhid plotid)
tempfile w2_harvest
save `w2_harvest'

** Harvested share (status)
keep zone ea hhid plotid cropname sa3q4 sa3q4b
g harvest_less = (sa3q4 == 8|sa3q4 == 9|sa3q4b == "NO FRUIT YET"|sa3q4b == "BEEB HAR,BEFORE VISI"|sa3q4b == "HAARVESTED BEFORE"|sa3q4b == "HAEVESTED BEFORE"|sa3q4b == "HAR B/F LAST VISIT"|sa3q4b == "HAR.B/F LAST  VISIT"|sa3q4b == "HAR.B/F LAST VISIT"|sa3q4b == "HARVCESTED BEFORE"|sa3q4b == "HARVESSTED BEFORE"|sa3q4b == "HARVEST B/4 LAST"|sa3q4b == "HARVEST BEFORE"|sa3q4b == "HARVEST BEFORE VISIT"|sa3q4b == "HARVESTED"|sa3q4b == "HARVESTED BEFORE"|sa3q4b == "HARVESTED BEFOREW"|sa3q4b == "HARVESTED EARLIER"|sa3q4b == "HAVESTED BEFORE"|sa3q4b == "IMMATURE"|sa3q4b == "IMMATURED"|sa3q4b == "NO FRIUT YET"|sa3q4b == "NO FRUIT"|sa3q4b == "NO FRUIT YET"|sa3q4b == "NOT AVAILABLE SEASON"|sa3q4b == "NOT JET MATURE"|sa3q4b == "NOT MATURE"|sa3q4b == "NOT MATURE YET"|sa3q4b == "NOT MATURED"|sa3q4b == "NOT MATURED FOR HARV"|sa3q4b == "NOT NATURED"|sa3q4b == "NOT READY"|sa3q4b == "NOT RIPE FOR HARVEST"|sa3q4b == "NOT YET READ"|sa3q4b == "Not due for harvest"|sa3q4b == "UNMATURED FOR HARVT"|sa3q4b == "WAITING FOR CROP BUY"|sa3q4b == "WAITING FOR CROP HAR"|strmatch(sa3q4b,"*MATURE*")|strmatch(sa3q4b,"*HARVESTED*")|strmatch(sa3q4b,"*PP*")|strmatch(sa3q4b,"*BEFORE*")|strmatch(sa3q4b,"*ALREADY*")|strmatch(sa3q4b,"*DUE*")|strmatch(sa3q4b,"*YET*"))
g year = 2012
bysort zone ea hhid plotid: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1-harvest_complete
keep zone ea hhid plotid year harvest_complete
duplicates drop zone ea hhid plotid year,force

/*--- 2F. PP Labor (Wave 2: separate file sect11c1) ---*/
use "$w2ppa/sect11c1_plantingw2.dta", clear
foreach m in a b c d {
    gen pp_fam_`m' = s11c1q1`m'2 * s11c1q1`m'3 if !missing(s11c1q1`m'2) & !missing(s11c1q1`m'3)
    replace pp_fam_`m' = 0 if missing(pp_fam_`m')
}
gen pp_fam_days = pp_fam_a + pp_fam_b + pp_fam_c + pp_fam_d
gen pp_hire_man   = s11c1q2 * s11c1q3 if !missing(s11c1q2) & !missing(s11c1q3)
gen pp_hire_woman = s11c1q5 * s11c1q6 if !missing(s11c1q5) & !missing(s11c1q6)
gen pp_hire_child = s11c1q8 * s11c1q9 if !missing(s11c1q8) & !missing(s11c1q9)
foreach v of varlist pp_hire_* { replace `v' = 0 if missing(`v') }
gen pp_hire_days  = pp_hire_man + pp_hire_woman + pp_hire_child
gen pp_labor = pp_fam_days + pp_hire_days
collapse (sum) pp_labor pp_fam_days pp_hire_days, by(hhid plotid)
tempfile w2_pplabor
save `w2_pplabor'

/*--- 2G. Fertilizer ---*/
use "$w2ppa/sect11d_plantingw2.dta", clear
** Same 4-source structure as Wave 1
gen fert_n_s1 = s11dq4  * 0.46 if s11dq3  == 1
replace fert_n_s1 = s11dq4  * 0.20 if s11dq3  == 2
replace fert_n_s1 = s11dq4  * 0.15 if !inlist(s11dq3, 1,2) & !missing(s11dq3)
replace fert_n_s1 = 0 if missing(fert_n_s1)

gen fert_n_s2 = s11dq8  * 0.46 if s11dq7  == 1
replace fert_n_s2 = s11dq8  * 0.20 if s11dq7  == 2
replace fert_n_s2 = s11dq8  * 0.15 if !inlist(s11dq7, 1,2) & !missing(s11dq7)
replace fert_n_s2 = 0 if missing(fert_n_s2)

gen fert_n_s3 = s11dq16 * 0.46 if s11dq15 == 1
replace fert_n_s3 = s11dq16 * 0.20 if s11dq15 == 2
replace fert_n_s3 = s11dq16 * 0.15 if !inlist(s11dq15,1,2) & !missing(s11dq15)
replace fert_n_s3 = 0 if missing(fert_n_s3)

gen fert_n_s4 = s11dq28 * 0.46 if s11dq27 == 1
replace fert_n_s4 = s11dq28 * 0.20 if s11dq27 == 2
replace fert_n_s4 = s11dq28 * 0.15 if !inlist(s11dq27,1,2) & !missing(s11dq27)
replace fert_n_s4 = 0 if missing(fert_n_s4)

gen fertilizer_n = fert_n_s1 + fert_n_s2 + fert_n_s3 + fert_n_s4
gen fert_any     = (fertilizer_n > 0) if !missing(fertilizer_n)
gen fertilizer_cost = 0
capture replace fertilizer_cost = fertilizer_cost + s11dq17 if !missing(s11dq17)
capture replace fertilizer_cost = fertilizer_cost + s11dq29 if !missing(s11dq29)
collapse (sum) fertilizer_n fert_any fertilizer_cost, by(hhid plotid)
tempfile w2_fert
save `w2_fert'

/*--- 2H. Seeds ---*/
use "$w2ppa/sect11e_plantingw2.dta", clear
gen seed_cost = 0
capture replace seed_cost = seed_cost + s11eq21 if !missing(s11eq21)
capture replace seed_cost = seed_cost + s11eq33 if !missing(s11eq33)
gen improved = .   // not available for Wave 2
gen seed_qty = 0
capture replace seed_qty = seed_qty + s11eq6a  if !missing(s11eq6a)
capture replace seed_qty = seed_qty + s11eq10a if !missing(s11eq10a)
capture replace seed_qty = seed_qty + s11eq18a if !missing(s11eq18a)
capture replace seed_qty = seed_qty + s11eq30a if !missing(s11eq30a)
collapse (sum) seed_cost seed_qty, by(hhid plotid)
gen seed_value = seed_cost
tempfile w2_seeds
save `w2_seeds'

/*--- 2I. Pesticides ---*/
use "$w2ppa/sect11c2_plantingw2.dta", clear
** Pesticide use
gen pesticide = (s11cq1 == 1) if !missing(s11cq1)
replace pesticide = 0 if missing(pesticide)

gen herbicide = (s11cq10 == 1) if !missing(s11cq10)
replace herbicide = 0 if missing(herbicide)

** Pesticide cost
egen pest_cost = rowtotal(s11cq4a s11cq4b s11cq5a s11cq5b)
egen herb_cost = rowtotal(s11cq13a s11cq13b s11cq14a s11cq14b)

collapse (max) pesticide herbicide (sum) pest_cost herb_cost, by(hhid plotid)
tempfile w2_pest
save `w2_pest'

/*--- 2J. Plot geovars ---*/
use "$w2geo/NGA_PlotGeovariables_Y2.dta", clear
keep hhid plotid srtmslp_nga srtm_nga twi_nga
rename srtmslp_nga plot_slope
rename srtm_nga    plot_elev
rename twi_nga     plot_wet
replace plot_slope = 2.970942 if missing(plot_slope)
replace plot_elev  = 330.1089 if missing(plot_elev)
replace plot_wet   = 14.54859 if missing(plot_wet)
tempfile w2_plotgeo
save `w2_plotgeo'

/*--- 2K. HH geovars (soil quality) ---*/
use "$w2geo/NGA_HouseholdGeovars_Y2.dta", clear
capture {
    gen soil1 = (sq1_d == 1)
    foreach j of numlist 2/7 {
        gen soil`j' = (sq`j'_d == 0) if !missing(sq`j'_d)
    }
    pca soil1 soil2 soil3 soil4 soil5 soil6 soil7
    predict soil_quality_pca, score
}
if _rc != 0 gen soil_quality_pca = .
keep hhid soil_quality_pca
duplicates drop hhid, force
tempfile w2_hhgeo
save `w2_hhgeo'

/*--- 2L. Manager characteristics ---*/
use "$w2phh/sect1_harvestw2.dta", clear
keep hhid indiv s1q2 s1q4 s1q7
rename indiv  manager_id
rename s1q2   sex
rename s1q4   age
rename s1q7   marital
tempfile w2_roster
save `w2_roster'

use "$w2phh/sect2a_harvestw2.dta", clear
keep hhid indiv s2aq4 s2aq9
duplicates drop hhid indiv, force
gen primary_edu = (s2aq9 >= 1 & s2aq9 <= 6) if !missing(s2aq9)
gen edu_years   = s2aq9 if s2aq9 >= 0 & s2aq9 < 99
rename indiv manager_id
tempfile w2_edu
save `w2_edu',replace

use `w2_plotroster', clear
merge m:1 hhid manager_id using `w2_roster', keep(1 3) nogen
merge m:1 hhid manager_id using `w2_edu',   keep(1 3) nogen
gen female = (sex == 2) if !missing(sex)
gen age2   = age^2
gen married= (marital == 1) if !missing(marital)
keep hhid plotid manager_id female age age2 married primary_edu edu_years main_crop
tempfile w2_manager
save `w2_manager'

/*--- 2M. HH characteristics ---*/
use "$w2phh/sect8_harvestw2.dta", clear
keep hhid s8q17
recode s8q17 (1=1) (2=0), gen(electricity)
duplicates drop hhid, force
tempfile w2_elec
save `w2_elec'

use "$w2ppa/sect11i_plantingw2.dta", clear
capture gen livestock_value = s11iq2 * s11iq3
capture gen livestock_value = s11i_value
if _rc != 0 gen livestock_value = 0
collapse (sum) livestock_value, by(hhid)
tempfile w2_livestock
save `w2_livestock'

use "$w2pph/sect1_plantingw2.dta", clear
keep hhid indiv s1q3 s1q4
capture rename s1q3 age_p
capture rename s1q4 age_p
gen child = (age_p < 15) if !missing(age_p)
gen elderly = (age_p > 65) if !missing(age_p)
bysort hhid: gen hhsize = _N
collapse (sum) child elderly (mean) hhsize, by(hhid)
gen child_depend = (child + elderly) / hhsize
gen n_children = child
drop child elderly
tempfile w2_hhsize
save `w2_hhsize'

use "$w2phh/sect9_harvestw2.dta", clear
capture gen nfe = (s9q1 == 1) if !missing(s9q1)
capture gen nfe = (s9q2 == 1) if !missing(s9q2)
if _rc != 0 gen nfe = .
collapse (max) nfe, by(hhid)
tempfile w2_nfe
save `w2_nfe'

use "$w2pph/sect1_plantingw2.dta", clear
keep if s1q1 == 1 | s1q1 == .
duplicates drop hhid, force
capture gen religion = s1q16 if !missing(s1q16)
capture gen religion = s1q15 if !missing(s1q15)
if _rc != 0 gen religion = .
gen muslim  = (religion == 2) if !missing(religion)
gen hhhsex  = s1q2
keep hhid muslim hhhsex
tempfile w2_religion
save `w2_religion'

use "$w2ppa/sect11b1_plantingw2.dta", clear
recode s11b1q4 (1 4 = 1) (2 3 = 0), gen(own)
capture gen irrigate = (s11b1q39 == 1) if !missing(s11b1q39)
capture gen fallow   = (s11b1q28 == 1 | s11b1q27 == 1)
if _rc != 0 { gen irrigate = .; gen fallow = . }
keep hhid plotid own irrigate fallow
duplicates drop hhid plotid, force
tempfile w2_tenure
save `w2_tenure'

/*--- 2N. Assemble Wave 2 ---*/
use `w2_harvest', clear
merge 1:1 hhid plotid using `w2_area',     keep(1 3) nogen
merge 1:1 hhid plotid using `w2_pplabor',  keep(1 3) nogen
merge 1:1 hhid plotid using `w2_fert',     keep(1 3) nogen
merge 1:1 hhid plotid using `w2_seeds',    keep(1 3) nogen
merge 1:1 hhid plotid using `w2_pest',     keep(1 3) nogen
merge 1:1 hhid plotid using `w2_plotgeo',  keep(1 3) nogen
merge 1:1 hhid plotid using `w2_manager',  keep(1 3) nogen
merge 1:1 hhid plotid using `w2_tenure',   keep(1 3) nogen
merge m:1 hhid using `w2_cover',           keep(1 3) nogen
merge m:1 hhid using `w2_elec',            keep(1 3) nogen
merge m:1 hhid using `w2_livestock',       keep(1 3) nogen
merge m:1 hhid using `w2_hhsize',          keep(1 3) nogen
merge m:1 hhid using `w2_nfe',             keep(1 3) nogen
merge m:1 hhid using `w2_religion',        keep(1 3) nogen
merge m:1 hhid using `w2_hhgeo',           keep(1 3) nogen

gen total_labor = pp_labor + ph_labor
replace total_labor = 0 if missing(total_labor)
gen year = 2012
foreach v of varlist fertilizer_n seed_cost pesticide tractor fallow {
    replace `v' = 0 if missing(`v')
}

save "$intdir/2012_harvest.dta", replace

/*===========================================================================
  SECTION 3 – WAVE 3 (2015)
===========================================================================*/

/*--- 3A. Household cover ---*/
use "$w3root/secta_plantingw3.dta", clear
keep hhid zone state lga ea
duplicates drop hhid, force
tempfile w3_cover
save `w3_cover'

/*--- 3B. Plot roster ---*/
use "$w3root/sect11a1_plantingw3.dta", clear
rename s11aq1 cropcode
bysort hhid plotid (cropcode): gen crop_seq = _n
gen main_crop_code = cropcode if crop_seq == 1
bysort hhid plotid: egen main_crop = max(main_crop_code)
gen manager_id = s11aq6a
replace manager_id = s11aq6b if missing(s11aq6a)
keep hhid plotid main_crop manager_id
duplicates drop hhid plotid, force
tempfile w3_plotroster
save `w3_plotroster'

/*--- 3C. Plot area ---*/
use "$w3root/sect11a1_plantingw3.dta", clear
gen gps_area = s11aq4c / 10000 if s11aq4c > 0 & !missing(s11aq4c)
merge m:1 hhid using `w3_cover', keep(1 3) nogen
gen rep_area = .
replace rep_area = s11aq4b * 5.5  / 10000 if s11aq4a == 1
replace rep_area = s11aq4b * 15   / 10000 if s11aq4a == 2
replace rep_area = s11aq4b * 0.5  / 10000 if s11aq4a == 3
replace rep_area = s11aq4b * 0.04          if s11aq4a == 4
replace rep_area = s11aq4b * 0.404686      if s11aq4a == 5
replace rep_area = s11aq4b                 if s11aq4a == 6
replace rep_area = s11aq4b / 10000         if s11aq4a == 7
gen parea = gps_area if !missing(gps_area)
replace parea = rep_area if missing(parea) & !missing(rep_area)
bysort hhid: egen farm_size = sum(parea)
keep hhid plotid parea gps_area rep_area farm_size
duplicates drop hhid plotid, force
tempfile w3_area
save `w3_area'

** Planted share (status)
use "crop_area" //converted to hectare
keep zone hhid plotid year plant_area //self-reported area
duplicates drop zone hhid plotid year,force
merge 1:1 zone hhid plotid year using plot_size
keep if _merge == 3
drop _merge
g parea_threshold = parea*0.5
g portion_planted = (plant_area < parea_threshold)
save "planting_share.dta"

/*--- 3D. Conversion table ---*/
use "$w3root/ag_conv_w3.dta",clear
drop crop_name unit_name
rename crop_cd cropid
rename unit_cd unitid
tempfile w3_convtable
save `w3_convtable'

/*--- 3E. Harvest ---*/
use "$w3root/secta3i_harvestw3.dta", clear
** sa3iq3 = any harvest (1=yes), sa3iq6ii = unit code (unit_cd), sa3iq6i = quantity, sa3iq4 = shock type
keep if sa3iq3 == 1
rename sa3iq6ii unitid
rename sa3iq6i  qty_harvest
rename sa3iq2   cropid   // !! VERIFY: cropcode variable name in secta3i
merge m:1 hhid using `w3_cover', keep(1 3) nogen
merge m:1 cropid unitid using `w3_convtable', keep(1 3) nogen
gen qty_kg = qty_harvest * conv_national
replace qty_kg = 0 if qty_kg < 0 | missing(qty_kg)

** Sold quantity for price computation
use "$w2conv", clear
keep hhid plotid cropid sa3iiq5a sa3iiq5b sa3iiq6
rename sa3iiq6 sold_value   // sale revenue (Naira)
rename sa3iiq5b unitid
merge m:1 cropid unitid using `w3_convtable', keep(master match) nogen
gen sold_qty_kg = sa3iiq5a * conv_national // qty sold in kg
tempfile w3_sold
save `w3_sold'

** Use mean price × kg for harvest value
gen unit_price = sold_value / qty_kg if qty_kg > 0 & !missing(sold_value)
capture replace unit_price = sa3iiq5 / qty_kg if missing(unit_price)   // !! VERIFY
bysort cropcode_h: egen mean_price = median(unit_price)
gen harvest_value = qty_kg * mean_price
replace harvest_value = 0 if missing(harvest_value)

collapse (sum) harvest_value qty_kg, by(hhid plotid)
tempfile w3_harvest
save `w3_harvest'

** Harvested share (status)
keep zone ea hhid plotid cropname sa3iq4
g harvest_less = (sa3iq4 == 9|sa3iq4 == 10)
g year = 2015
bysort zone ea hhid plotid: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1-harvest_complete
keep zone ea hhid plotid year harvest_complete
duplicates drop zone ea hhid plotid year,force

/*--- 3F. PP Labor (same file as Wave 2: sect11c1_plantingw3) ---*/
use "$w3root/sect11c1_plantingw3.dta", clear
foreach m in a b c d {
    gen pp_fam_`m' = s11c1q1`m'2 * s11c1q1`m'3 if !missing(s11c1q1`m'2) & !missing(s11c1q1`m'3)
    replace pp_fam_`m' = 0 if missing(pp_fam_`m')
}
gen pp_fam_days = pp_fam_a + pp_fam_b + pp_fam_c + pp_fam_d
gen pp_hire_man   = s11c1q2 * s11c1q3 if !missing(s11c1q2) & !missing(s11c1q3)
gen pp_hire_woman = s11c1q5 * s11c1q6 if !missing(s11c1q5) & !missing(s11c1q6)
gen pp_hire_child = s11c1q8 * s11c1q9 if !missing(s11c1q8) & !missing(s11c1q9)
foreach v of varlist pp_hire_* { replace `v' = 0 if missing(`v') }
gen pp_hire_days  = pp_hire_man + pp_hire_woman + pp_hire_child
gen pp_labor = pp_fam_days + pp_hire_days
collapse (sum) pp_labor pp_fam_days pp_hire_days, by(hhid plotid)
tempfile w3_pplabor
save `w3_pplabor'

/*--- 3G. Fertilizer (Wave 3: 5 sources, from harvest file) ---*/
use "$w3root/secta11d_harvestw3.dta", clear
** Source 1: Leftover (s11dq3 = type indicator, s11dq4a = kg, s11dq4b = cost)
gen fert_n_s1 = s11dq4a * 0.46 if s11dq3 == 1
replace fert_n_s1 = s11dq4a * 0.20 if s11dq3 == 2
replace fert_n_s1 = s11dq4a * 0.15 if !inlist(s11dq3,1,2) & !missing(s11dq3)
replace fert_n_s1 = 0 if missing(fert_n_s1)

** Source 2: Free/subsidized (sect11dq7 = type, sect11dq8a = kg, sect11dq8b = cost)
gen fert_n_s2 = sect11dq8a * 0.46 if sect11dq7 == 1
replace fert_n_s2 = sect11dq8a * 0.20 if sect11dq7 == 2
replace fert_n_s2 = sect11dq8a * 0.15 if !inlist(sect11dq7,1,2) & !missing(sect11dq7)
replace fert_n_s2 = 0 if missing(fert_n_s2)

** Source 3: E-wallet subsidy (NEW in Wave 3: s11dq5b = type, s11dq5c1 = kg, s11dq5c2 = cost)
gen fert_n_s3 = s11dq5c1 * 0.46 if s11dq5b == 1
replace fert_n_s3 = s11dq5c1 * 0.20 if s11dq5b == 2
replace fert_n_s3 = s11dq5c1 * 0.15 if !inlist(s11dq5b,1,2) & !missing(s11dq5b)
replace fert_n_s3 = 0 if missing(fert_n_s3)

** Source 4: Commercial purchase 1 (s11dq15 = type, s11dq16a = kg, s11dq16b = cost)
gen fert_n_s4 = s11dq16a * 0.46 if s11dq15 == 1
replace fert_n_s4 = s11dq16a * 0.20 if s11dq15 == 2
replace fert_n_s4 = s11dq16a * 0.15 if !inlist(s11dq15,1,2) & !missing(s11dq15)
replace fert_n_s4 = 0 if missing(fert_n_s4)

** Source 5: Commercial purchase 2 (s11dq27 = type, s11dq28a = kg, s11dq28b = cost)
gen fert_n_s5 = s11dq28a * 0.46 if s11dq27 == 1
replace fert_n_s5 = s11dq28a * 0.20 if s11dq27 == 2
replace fert_n_s5 = s11dq28a * 0.15 if !inlist(s11dq27,1,2) & !missing(s11dq27)
replace fert_n_s5 = 0 if missing(fert_n_s5)

gen fertilizer_n = fert_n_s1 + fert_n_s2 + fert_n_s3 + fert_n_s4 + fert_n_s5
gen fert_any     = (fertilizer_n > 0) if !missing(fertilizer_n)
gen fertilizer_cost = 0
capture replace fertilizer_cost = fertilizer_cost + s11dq4b     if !missing(s11dq4b)
capture replace fertilizer_cost = fertilizer_cost + sect11dq8b  if !missing(sect11dq8b)
capture replace fertilizer_cost = fertilizer_cost + s11dq5c2    if !missing(s11dq5c2)
capture replace fertilizer_cost = fertilizer_cost + s11dq16b    if !missing(s11dq16b)
capture replace fertilizer_cost = fertilizer_cost + s11dq28b    if !missing(s11dq28b)
collapse (sum) fertilizer_n fert_any fertilizer_cost, by(hhid plotid)
tempfile w3_fert
save `w3_fert'

/*--- 3H. Seeds (Wave 3: improved seed variable available) ---*/
use "$w3root/sect11e_plantingw3.dta", clear
gen seed_cost = 0
capture replace seed_cost = seed_cost + s11eq21 if !missing(s11eq21)
capture replace seed_cost = seed_cost + s11eq33 if !missing(s11eq33)
** Improved seed (Wave 3 only): s11eq3b (1/2=Yes, 3/4=No)
recode s11eq3b (3 4 = 0) (1 2 = 1), gen(improved)
gen seed_qty = 0
capture replace seed_qty = seed_qty + s11eq6a  if !missing(s11eq6a)
capture replace seed_qty = seed_qty + s11eq10a if !missing(s11eq10a)
capture replace seed_qty = seed_qty + s11eq18a if !missing(s11eq18a)
capture replace seed_qty = seed_qty + s11eq30a if !missing(s11eq30a)
collapse (sum) seed_cost seed_qty (max) improved, by(hhid plotid)
gen seed_value = seed_cost
tempfile w3_seeds
save `w3_seeds'

/*--- 3I. Pesticides ---*/
use "$w3root/secta11c2_harvestw3.dta", clear
** Pesticide use
gen pesticide = (s11c2q1 == 1) if !missing(s11c2q1)
replace pesticide = 0 if missing(pesticide)

gen herbicide = (s11c2q10 == 1) if !missing(s11c2q10)
replace herbicide = 0 if missing(herbicide)

** Pesticide cost
egen pest_cost = rowtotal(s11c2q4a s11c2q4b s11c2q5a s11c2q5b)
egen herb_cost = rowtotal(s11c2q13a s11c2q13b s11c2q14a s11c2q14b)

collapse (max) pesticide herbicide (sum) pest_cost herb_cost, by(hhid plotid)
tempfile w3_pest
save `w3_pest'

/*--- 3J. Plot geovars ---*/
use "$w3root/NGA_PlotGeovariables_Y3.dta", clear
keep hhid plotid srtmslp_nga srtm_nga twi_nga
rename srtmslp_nga plot_slope
rename srtm_nga    plot_elev
rename twi_nga     plot_wet
replace plot_slope = 2.970942 if missing(plot_slope)
replace plot_elev  = 330.1089 if missing(plot_elev)
replace plot_wet   = 14.54859 if missing(plot_wet)
tempfile w3_plotgeo
save `w3_plotgeo'

/*--- 3K. HH geovars ---*/
use "$w3root/NGA_HouseholdGeovars_Y3.dta", clear
capture {
    gen soil1 = (sq1_d == 1)
    foreach j of numlist 2/7 {
        gen soil`j' = (sq`j'_d == 0) if !missing(sq`j'_d)
    }
    pca soil1 soil2 soil3 soil4 soil5 soil6 soil7
    predict soil_quality_pca, score
}
if _rc != 0 gen soil_quality_pca = .
keep hhid soil_quality_pca
duplicates drop hhid, force
tempfile w3_hhgeo
save `w3_hhgeo'

/*--- 3L. Manager characteristics ---*/
use "$w3root/sect1_harvestw3.dta", clear
keep hhid indiv s1q2 s1q4 s1q7
rename indiv  manager_id
rename s1q2   sex
rename s1q4   age
rename s1q7   marital
tempfile w3_roster
save `w3_roster'

** Education (Wave 3: single file)
use "$w3root/sect2_harvestw3.dta", clear
keep hhid indiv s2aq6 s2aq9   // s2aq6 = ever attended, s2aq9 = highest grade  !! VERIFY
gen primary_edu = (s2aq9 >= 1 & s2aq9 <= 6) if !missing(s2aq9)
gen edu_years   = s2aq9 if s2aq9 >= 0 & s2aq9 < 99
rename indiv manager_id
tempfile w3_edu
save `w3_edu'

use `w3_plotroster', clear
merge m:1 hhid manager_id using `w3_roster', keep(1 3) nogen
merge m:1 hhid manager_id using `w3_edu',   keep(1 3) nogen
gen female = (sex == 2) if !missing(sex)
gen age2   = age^2
gen married= (marital == 1) if !missing(marital)
keep hhid plotid manager_id female age age2 married primary_edu edu_years main_crop
tempfile w3_manager
save `w3_manager'

/*--- 3O. HH characteristics ---*/
** Electricity
use "$w3root/sect11_plantingw3.dta", clear
keep hhid s11q17b
recode s11q17b (1=1) (2=0), gen(electricity)
duplicates drop hhid, force
tempfile w3_elec
save `w3_elec'

use "$w3root/sect11i_plantingw3.dta", clear
capture gen livestock_value = s11iq2 * s11iq3
capture gen livestock_value = s11i_value
if _rc != 0 gen livestock_value = 0
collapse (sum) livestock_value, by(hhid)
tempfile w3_livestock
save `w3_livestock'

use "$w3root/sect1_plantingw3.dta", clear
keep hhid indiv s1q6
capture rename s1q6 age_p
gen child   = (age_p < 15)  if !missing(age_p)
gen elderly = (age_p > 65)  if !missing(age_p)
bysort hhid: gen hhsize = _N
collapse (sum) child elderly (mean) hhsize, by(hhid)
gen child_depend = (child + elderly) / hhsize
gen n_children = child
drop child elderly
tempfile w3_hhsize
save `w3_hhsize'

use "$w3root/sect1_plantingw3.dta", clear
keep if s1q1 == 1 | s1q1 == .
duplicates drop hhid, force
capture gen religion = s1q16 if !missing(s1q16)
capture gen religion = s1q15 if !missing(s1q15)
if _rc != 0 gen religion = .
gen muslim  = (religion == 2) if !missing(religion)
gen hhhsex  = s1q2
keep hhid muslim hhhsex
tempfile w3_religion
save `w3_religion'

use "$w3root/sect11b1_plantingw3.dta", clear
recode s11b1q4 (1 4 5 = 1) (2 3 = 0) (6=.), gen(own)
capture gen irrigate = (s11b1q39 == 1) if !missing(s11b1q39)
capture gen fallow   = (s11b1q28 == 1 | s11b1q27 == 1)
if _rc != 0 { gen irrigate = .; gen fallow = . }
keep hhid plotid own irrigate fallow
duplicates drop hhid plotid, force
tempfile w3_tenure
save `w3_tenure'

/*--- 3P. Assemble Wave 3 ---*/
use `w3_harvest', clear
merge 1:1 hhid plotid using `w3_area',     keep(1 3) nogen
merge 1:1 hhid plotid using `w3_pplabor',  keep(1 3) nogen
merge 1:1 hhid plotid using `w3_fert',     keep(1 3) nogen
merge 1:1 hhid plotid using `w3_seeds',    keep(1 3) nogen
merge 1:1 hhid plotid using `w3_pest',     keep(1 3) nogen
merge 1:1 hhid plotid using `w3_tractor',  keep(1 3) nogen
merge 1:1 hhid plotid using `w3_plotgeo',  keep(1 3) nogen
merge 1:1 hhid plotid using `w3_manager',  keep(1 3) nogen
merge 1:1 hhid plotid using `w3_tenure',   keep(1 3) nogen
merge m:1 hhid using `w3_cover',           keep(1 3) nogen
merge m:1 hhid using `w3_elec',            keep(1 3) nogen
merge m:1 hhid using `w3_livestock',       keep(1 3) nogen
merge m:1 hhid using `w3_hhsize',          keep(1 3) nogen
merge m:1 hhid using `w3_religion',        keep(1 3) nogen
merge m:1 hhid using `w3_hhgeo',           keep(1 3) nogen

gen total_labor = pp_labor + ph_labor
replace total_labor = 0 if missing(total_labor)
gen year = 2015
foreach v of varlist fertilizer_n seed_cost pesticide tractor fallow {
    replace `v' = 0 if missing(`v')
}

save "$intdir/2015_harvest.dta", replace

/*===========================================================================
  SECTION 4 – APPEND ALL WAVES; CONSTRUCT PANEL ID
===========================================================================*/

use "$intdir/2010_harvest.dta", clear
append using "$intdir/2012_harvest.dta"
append using "$intdir/2015_harvest.dta"

** Plot ID (string key for merging)
tostring hhid plotid, replace force
egen plot_id = concat(hhid plotid), punct("")
encode plot_id, gen(pid_)
save "$intdir/2010_2012_2015_harvest.dta", replace

/*===========================================================================
  SECTION 5 – MERGE CLIMATE VARIABLES
===========================================================================*/

foreach yr in 2010 2012 2015 {
    use "$intdir/`yr'_che34.dta", clear
    gen year = `yr'
    tempfile clim_`yr'
    save `clim_`yr''
}

use `clim_2010', clear
append using `clim_2012'
append using `clim_2015'
** Expected: hhid, hdd_34_che, gdd_34_che (EA-level or HH-level)
tempfile clim_all
save `clim_all'

** Weather controls (precipitation, wind speed, solar radiation)
foreach yr in 2010 2012 2015 {
    capture use "$intdir/`yr'_weather.dta", clear
    if _rc != 0 {
        ** Try alternative path  !! VERIFY
        use "$climate/`yr'_weather.dta", clear
    }
    gen year = `yr'
    tempfile weather_`yr'
    save `weather_`yr''
}

use `weather_2010', clear
append using `weather_2012'
append using `weather_2015'
tempfile weather_all
save `weather_all'

** Merge climate to plot panel
use "$intdir/2010_2012_2015_harvest.dta", clear
destring hhid, replace force
merge m:1 hhid year using `clim_all', keep(1 3) nogen
merge m:1 hhid year using `weather_all', keep(1 3) nogen

/*===========================================================================
  SECTION 6 – ANALYTICAL VARIABLE CONSTRUCTION AND SAMPLE RESTRICTIONS
===========================================================================*/

/*--- 6A. Sample restrictions ---*/
centile parea, centile(3 97)
drop if parea < 0.02 | parea > 3.14   // trim extreme plot sizes per reference code

** Keep plots with positive harvest
drop if harvest_value <= 0 | missing(harvest_value)

** Keep plots with non-missing female indicator
drop if missing(female)

/*--- 6B. Yield and productivity measures ---*/
** Yield value per hectare (Naira/ha)
gen land_yield = harvest_value / parea
replace land_yield = . if land_yield <= 0
gen lnland_yield = ln(land_yield) if land_yield > 0

/*--- 6D. Input value per hectare ---*/
** (for value-based input measure)
replace fertilizer_cost = 0 if missing(fertilizer_cost)
replace seed_value      = 0 if missing(seed_value)
replace pest_cost       = 0 if missing(pest_cost)
replace herb_cost       = 0 if missing(herb_cost)
gen total_input = fertilizer_cost + seed_value + pest_cost + herb_cost + fertilizer + animal_rent
gen land_input  = total_input / parea

/*--- 6E. Climate variables (threshold 34°C) ---*/
** hdd_34_che = growing-season HDD above 34°C
** gdd_34_che = growing-season GDD below 34°C
gen female_hdd34 = female * hdd_34_che
gen female_gdd34 = female * gdd_34_che

/*--- 6F. Weather controls (quadratic) ---*/
** pr = precipitation (mm), ws = wind speed (m/s), sr = solar radiation (MJ/m²)
gen pr2 = pr^2
gen ws2 = ws^2
gen sr2 = sr^2

gen sample = !missing(lnland_yield) & !missing(female) & !missing(hdd_34_che) ///
           & !missing(parea) & !missing(state) & !missing(year)
keep if sample