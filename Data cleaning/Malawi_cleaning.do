/* ============================================================
   Raw data:
     Wave 1: MWI_2010_IHS-III_v01_M_STATA8\Full_Sample\
     Wave 2: MWI_2010-2013_IHPS_v01_M_Stata\
   ============================================================ */

* Wave 1 — IHS-III 2010
global w1    "D:/climate_gender/Malawi/MWI_2010_IHS-III_v01_M_STATA8/Full_Sample"
global w1ag  "${w1}/Agriculture"
global w1hh  "${w1}/Household"
global w1geo "${w1}/Geovariables"

* Wave 2 — IHPS 2013 (*_13.dta files)
global w2    "D:/climate_gender/Malawi/MWI_2010-2013_IHPS_v01_M_Stata"


/* ============================================================
   SECTION 1: WAVE 1 — IHS-III 2010
   ============================================================ */

/* -------- 1.1 Crop prices (from sales module) -------- */

use "${w1ag}/ag_mod_i.dta", clear
rename case_id hhid
rename ea_id   ea
g year = 2010
capture rename ag_i0b cropid

rename (ag_i06a ag_i06b)(controller1 controller2) //merge with manager

* Sale quantity in kg (lack conversion factors)
g sale_kg = ag_i02a              if ag_i02b == 1   /* kg           */
replace sale_kg = ag_i02a * 50   if ag_i02b == 2   /* 50-kg bag    */
replace sale_kg = ag_i02a * 90   if ag_i02b == 3   /* 90-kg bag    */
rename ag_i03 sale_value
g price = sale_value / sale_kg if sale_kg > 0 & sale_kg != .

bysort cropid year: egen crop_price = mean(price)
keep cropid year crop_price
duplicates drop cropid year, force
save "${tmp}/2010_crop_price.dta", replace


/* -------- 1.2 Harvest quantity and plot yield -------- */

use "${w1ag}/ag_mod_g.dta", clear
rename case_id hhid
rename ea_id   ea
g year = 2010
rename ag_g0b plotid
rename ag_g0d cropid

* Harvest quantity in kg (lack conversion factors)
g harvest_kg = ag_g13a              if ag_g13b == 1   /* kg        */
replace harvest_kg = ag_g13a * 50   if ag_g13b == 2   /* 50-kg bag */
replace harvest_kg = ag_g13a * 90   if ag_g13b == 3   /* 90-kg bag */
merge m:1 cropid year using "${tmp}/2010_crop_price.dta", ///
    keep(1 3) nogenerate
g harvest_value = harvest_kg * crop_price

* Plot-level yields
bysort hhid ea plotid year: egen yield = sum(harvest_value)

* Intercropping
bysort hhid ea plotid year: egen n_crop = count(cropid)
g intercrop = (n_crop > 1)

* Crop composition
g maize     = (cropid >= 1  & cropid <= 4)
g tobacco   = (cropid >= 5  & cropid <= 9)
g groundnut = (cropid >= 10 & cropid <= 15)
capture g sorghum  = (cropname == "SORGHUM.") if cropname != ""
capture g soybean  = (cropname == "beans" | cropname == "soyabean") if cropname != ""
capture replace sorghum = 0 if sorghum == .
capture replace soybean = 0 if soybean == .

foreach crop in maize tobacco groundnut sorghum soybean {
    replace `crop' = `crop' * harvest_kg
    bysort hhid plotid year: egen `crop'_kg = sum(`crop')
}
bysort hhid ea plotid year: egen plot_seedkg_tmp = count(harvest_kg)

duplicates drop hhid ea plotid year, force
keep hhid ea plotid year yield n_crop intercrop ///
     maize_kg tobacco_kg groundnut_kg sorghum_kg soybean_kg
save "${tmp}/2010_harvest.dta", replace


/* -------- 1.3 Plot area -------- */

use "${w1ag}/ag_mod_c.dta", clear
rename case_id hhid
rename ea_id ea
g year = 2010
capture rename ag_c00 plotid

* Preferred: GPS area in acres → ha; fallback: self-reported
g parea = ag_c04c * 0.405                          /* GPS acres → ha  */
replace parea = ag_c04a            if ag_c04b == 2 & parea == .  /* reported ha     */
replace parea = ag_c04a * 0.0001   if ag_c04b == 3 & parea == .  /* reported m² → ha*/
replace parea = ag_c04a * 0.405    if ag_c04b == 1 & parea == .  /* reported ac → ha*/
bysort ea hhid year: egen farm_size = sum(parea)

* Plot ownership: merge with manager
rename ag_d04a parcel_owner1
rename ag_d04b parcel_owner2
keep hhid ea plotid year parea parcel_owner1 parcel_owner2
duplicates drop hhid ea plotid year, force
save "${tmp}/2010_parea.dta", replace


/* -------- 1.4 Labor (plot manager, home and hired labor) -------- */

use "${w1ag}/ag_mod_d.dta", clear
rename case_id hhid
rename ea_id ea
g year = 2010
capture rename ag_d00 plotid

* Family/household labor
forvalues i = 1/12 {
    capture replace ag_d42d`i' = ag_d42b`i' * ag_d42c`i' * ag_d42d`i'
    capture replace ag_d43d`i' = ag_d43b`i' * ag_d43c`i' * ag_d43d`i'
}
capture {
    egen homelabor_mday = rowtotal(ag_d42d* ag_d43d*)
    replace homelabor_mday = homelabor_mday / 24
}

* Hired labor (man-days)
egen hiredlabor_mday= rowtotal(ag_d47a ag_d47b ag_d47c)
capture g labor_mday = homelabor_mday + hirelabor_mday

capture confirm var labor_mday
if _rc != 0 {
    gen labor_mday      = .
    gen homelabor_mday  = .
    gen hirelabor_mday  = .
    gen otherlabor_mday = .
}

* Plot manager individual ID
rename ag_d01 indiv
keep hhid ea plotid year indiv labor_mday homelabor_mday hirelabor_mday
duplicates drop hhid ea plotid year, force
save "${tmp}/2010_labor.dta", replace


/* -------- 1.5 Fertilizer and pesticide inputs -------- */
/* In IHS-III 2010, fertilizer questions are in ag_mod_d (management section) */

use "${w1ag}/ag_mod_d.dta", clear
rename case_id hhid
rename ea_id   ea
g year = 2010
capture rename ag_d0b plotid
capture rename ag_d00 plotid

* Inorganic fertilizer
g n_equiv1 = 0
capture {
    replace n_equiv1 = ag_d39d * 0.23 if ag_d39a == 1   /* NPK          */
    replace n_equiv1 = ag_d39d * 0.46 if ag_d39a == 4   /* Urea         */
    replace n_equiv1 = ag_d39d * 0.18 if ag_d39a == 2   /* DAP          */
    replace n_equiv1 = ag_d39d * 0.26 if ag_d39a == 3   /* CAN          */
    replace n_equiv1 = ag_d39d * 0.07 if ag_d39a == 5   /* D-compound   */
}

g n_equiv2 = 0
capture {
    replace n_equiv2 = ag_d39i * 0.23 if ag_d39f == 1
    replace n_equiv2 = ag_d39i * 0.46 if ag_d39f == 4
    replace n_equiv2 = ag_d39i * 0.18 if ag_d39f == 2
    replace n_equiv2 = ag_d39i * 0.26 if ag_d39f == 3
    replace n_equiv2 = ag_d39i * 0.07 if ag_d39f == 5
}

g inorganic_fertilizer = n_equiv1 + n_equiv2
capture replace inorganic_fertilizer = 0 if ag_d38 == 2   /* explicitly no fert */

* Pesticide use (binary)
capture g pest_herb = (ag_d40 == 1)        if ag_d40 != .
recode ag_d41a (7 = 1 "Yes") (.=.) (else = 0 "No"), gen(used_pesticides) label(used_pesticides)
replace used_pesticides=0 if ag_d40==2

* Irrigation
recode ag_d28a (7 = 0 "No") (1/6 = 1 "Yes") (8=.), gen(irrigated) label(irrigated)

* Erosion protection
recode ag_d25a (1 = 0 "No") (2/9 = 1 "Yes"), gen(erosion_protection)  label(erosion_protection)

keep hhid ea plotid year inorganic_fertilizer pesticide irrigation erosion_prot
duplicates drop hhid ea plotid year, force
save "${tmp}/2010_inputs.dta", replace


/* -------- 1.6 Expenditure (input cost proxy) -------- */

use "${w1ag}/ag_mod_f.dta", clear
rename case_id hhid
rename ea_id   ea
g year = 2010
capture bysort hhid year: egen hh_input = sum(ag_f10)
capture {
    keep hhid ea year hh_input
    duplicates drop hhid year, force
    save "${tmp}/2010_hh_input.dta", replace
}


/* -------- 1.7 Seeds -------- */

use "${w1ag}/ag_mod_h.dta", clear
rename case_id hhid
g year = 2010
bysort hhid year: egen hh_seed = sum(ag_h10)

rename ag_h0b crop_code
forvalues n= 1/2 {
gen seed_purchased`n'_gram = ag_h`n'6a * 0.001 if ag_h`n'6b==1
gen seed_purchased`n'_kg = ag_h`n'6a  if ag_h`n'6b==2
gen seed_purchased`n'_2kg = ag_h`n'6a * 2 if ag_h`n'6b==3
gen seed_purchased`n'_3kg = ag_h`n'6a * 3 if ag_h`n'6b==4
gen seed_purchased`n'_37kg = ag_h`n'6a * 3.7 if ag_h`n'6b==5
gen seed_purchased`n'_5kg = ag_h`n'6a * 5 if ag_h`n'6b==6
gen seed_purchased`n'_10g = ag_h`n'6a * 10 if ag_h`n'6b==7
gen seed_purchased`n'_50kg = ag_h`n'6a * 50 if ag_h`n'6b==8

egen seed_purch_kg`n' = rowtotal(seed_purchased`n'_*)
replace seed_purch_kg`n'= . if inlist(ag_h`n'9, ., 0)
}
egen seeds_amount_purchased_kg = rowtotal(seed_purch_kg*)

* Seed quantity in kg — unit conversion
use "${w1ag}/ag_mod_g.dta", clear
rename case_id hhid
rename ag_g00 plotid
rename ag_g0b cropcode

capture {
    g seed_kg = ag_g04a * 0.001 if ag_g04b == 1   /* gram → kg      */
    replace seed_kg = ag_g04a       if ag_g04b == 2   /* kg             */
    replace seed_kg = ag_g04a * 2   if ag_g04b == 3   /* 2-kg bag       */
    replace seed_kg = ag_g04a * 3   if ag_g04b == 4   /* 3-kg bag       */
    replace seed_kg = ag_g04a * 3.7 if ag_g04b == 5   /* 3.7-kg bag     */
    replace seed_kg = ag_g04a * 5   if ag_g04b == 6   /* 5-kg bag       */
    replace seed_kg = ag_g04a * 10  if ag_g04b == 7   /* 10-kg bag      */
    replace seed_kg = ag_g04a * 50  if ag_g04b == 8   /* 50-kg bag      */
    bysort hhid plotid year: egen plot_seedkg = sum(seed_kg)
}
capture {
    keep hhid ea plotid year plot_seedkg
    duplicates drop hhid plotid year, force
    save "${tmp}/2010_seeds.dta", replace
}


/* -------- 1.8 Extension contacts -------- */

use "${w1ag}/ag_mod_t2.dta", clear
rename case_id hhid
g year = 2010
capture rename ag_t05a indiv //a-d:merge with manager

g source = 1
bysort hhid indiv year: egen exten_channel = sum(source)

capture {
    egen frequency = rowtotal(ag_t06a ag_t07 ag_t08)
    bysort hhid indiv year: egen exten_frequency = sum(frequency)
}
capture gen exten_frequency = 0 if exten_frequency == .

keep hhid ea indiv year exten_channel exten_frequency
duplicates drop hhid indiv year, force
save "${tmp}/2010_extension.dta", replace


/* -------- 1.9 Household roster (sex, age, marital status) -------- */

use "${w1hh}/hh_mod_b.dta", clear
rename case_id hhid
g year = 2010
capture rename hh_b01 indiv
capture rename hh_b03  sex
capture rename hh_b04  relation_hhead
capture rename hh_b05a age

g female_ind = (sex == 2) if sex != .
g male_ind   = (sex == 1) if sex != .

* Sex of household head
g sex_hhead = sex - 1 if relation_hhead == 1
bysort hhid: egen female_hhead = max(sex_hhead)

* Marital status
capture rename hh_b24 marital
g married      = (marital <= 2 & marital != .)
g married_mono = (marital == 1)
g married_poly = (marital == 2)
g separated    = (marital >= 3 & marital <= 5)
g unmarried    = (marital == 6)

* Dependency ratio
g working_age = (age >= 15 & age <= 64) if age != .
bysort hhid: egen n_hhmember = count(indiv)
bysort hhid: egen n_working  = sum(working_age)
g dep_ratio = (n_hhmember - n_working) / n_working if n_working > 0

keep hhid ea indiv year sex female_ind male_ind age relation_hhead marital ///
     married married_mono married_poly separated unmarried ///
     female_hhead dep_ratio
save "${tmp}/2010_hhroster.dta", replace


/* -------- 1.10 Education -------- */

use "${w1hh}/hh_mod_c.dta", clear
rename case_id hhid
rename ea_id   ea
g year = 2010
capture rename id_code indiv
capture rename hh_c06 ever_attended
capture rename hh_c08 grade_attended
g edu_primary = (grade_attended >= 8 & grade_attended <= 23) if grade_attended != .
replace edu_primary = 0 if hh_c08 == 8 & hh_c12 == 7
replace edu_primary = 0 if ever_attended == 2

keep hhid ea indiv year edu_primary
duplicates drop hhid indiv year, force
save "${tmp}/2010_edu.dta", replace


/* -------- 1.11 Household assets and enterprise -------- */

* Electricity
use "${w1hh}/hh_mod_f.dta", clear
rename case_id hhid
rename ea_id   ea
g year = 2010
capture rename hh_f19 electricity_code
capture g electricity = (electricity_code == 1) if electricity_code != .
capture replace electricity = 0 if electricity_code == 2
keep hhid ea year electricity
duplicates drop hhid year, force
save "${tmp}/2010_electricity.dta", replace

* Livestock ownership
use "${w1ag}/ag_mod_r1.dta", clear
rename case_id hhid
rename ea_id   ea
g year = 2010
capture rename ag_r00 livestock_code
g livestock = (livestock_code == 1) if livestock_code != .
keep hhid ea year livestock
duplicates drop hhid year, force
save "${tmp}/2010_livestock.dta", replace

* Agricultural machinery
use "${w1hh}/hh_mod_m.dta", clear
rename case_id hhid
rename ea_id   ea
g year = 2010
capture {
    replace hh_m03 = hh_m03 * hh_m01 if hh_m03 != . & hh_m01 != .
    rename hh_m03 hh_m03_total
    bysort hhid year: egen machine_own = sum(hh_m03_total)
    capture rename hh_m14 machine_rent
    capture replace machine_rent = 0 if machine_rent == .
    gen hh_machine_value = machine_own + machine_rent
}
capture gen hh_machine_value = 0 if hh_machine_value == .
keep hhid ea year hh_machine_value
duplicates drop hhid year, force
save "${tmp}/2010_machinery.dta", replace


/* -------- 1.12 Geovariables -------- */

* Household-level
use "${w1geo}/HH_level/householdgeovariables.dta", clear
rename case_id hhid
capture rename dist_road   dist_road
capture rename dist_admarc dist_market
capture rename srtm_eaf   elevation
capture rename afmnslp_pct slope

forvalues i=1/7{
	recode sq`i' (1=1) (2/7=0), gen(sq`i'_d)
}
factor sq1_d-sq7_d, pcf 
predict soil_fertility_pca

local names "nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability"
forvalues n =1/7 {
local lab: word `n' of `names'
rename	sq`n'_d `lab'
}

keep hhid dist_road dist_market elevation slope nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability soil_fertility_pca
save "${tmp}/2010_hhgeo.dta", replace

* Plot-level (slope, topographic wetness, soil quality)
use "${w1geo}/Plot_level/plotgeovariables.dta", clear
rename case_id hhid
capture rename plot_id plotid
keep hhid plotid dist_hh
save "${tmp}/2010_plotgeo.dta", replace


/* -------- 1.13 Merge Wave 1 into plot-level dataset -------- */

use "${tmp}/2010_harvest.dta", clear

merge m:1 hhid ea plotid year using "${tmp}/2010_parea.dta", ///
    keep(1 3) nogenerate

merge m:1 hhid ea plotid year using "${tmp}/2010_labor.dta", ///
    keep(1 3) nogenerate

merge m:1 hhid ea plotid year using "${tmp}/2010_inputs.dta", ///
    keep(1 3) nogenerate

merge m:1 hhid plotid         using "${tmp}/2010_plotgeo.dta", ///
    keep(1 3) nogenerate

* Merge plot manager's personal characteristics from HH roster
merge m:1 hhid indiv year     using "${tmp}/2010_hhroster.dta", ///
    keep(1 3) nogenerate keepusing(sex female_ind male_ind age marital ///
        married married_mono married_poly separated unmarried)

rename female_ind female
rename male_ind   male
rename sex        sex

merge m:1 hhid indiv year     using "${tmp}/2010_extension.dta", ///
    keep(1 3) nogenerate

* HH-level covariates
merge m:1 hhid year           using "${tmp}/2010_electricity.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid year           using "${tmp}/2010_livestock.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid year           using "${tmp}/2010_nfe.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid year           using "${tmp}/2010_machinery.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid                using "${tmp}/2010_hhgeo.dta", ///
    keep(1 3) nogenerate

* Input for production function: expenditure
capture merge m:1 hhid year   using "${tmp}/2010_hh_input.dta", ///
    keep(1 3) nogenerate

save "${tmp}/2010_plot.dta", replace


/* ============================================================
   SECTION 2: WAVE 2 — IHPS 2013
   ============================================================ */

/* -------- 2.0 Status of planting & harvesting -------- */
cd "D:\climate_gender\Malawi\"
append using 2013_crop_area
g crop_share = . if ag_g01 == 1
replace crop_share = 100 if ag_g02 == 1
replace crop_share = 10 if ag_g03 == 1
replace crop_share = 25 if ag_g03 == 2
replace crop_share = 50 if ag_g03 == 3
replace crop_share = 75 if ag_g03 == 4
replace crop_share = 90 if ag_g03 == 5
bysort ea hhid plotid year: egen plant_share = max(crop_share)
bysort ea hhid plotid year: egen mixed_share = sum(crop_share)
replace plant_share = mixed_share if plant_share < 100 & plant_share != .
g portion_planted = (plant_share < 100 & plant_share != .)
keep ea hhid plotid year portion_planted
duplicates drop ea hhid plotid year,force
save "planting_share_dup.dta"

keep case_id ea_id ag_g0b ag_g0d ag_g10 ag_g11a ag_g11a_os ag_g11b ag_g11b_os
g harvest_less = (strmatch(ag_g11a_os,"*LATE*")|strmatch(ag_g11b_os,"*LATE*"))
g year = 2010
bysort ea hhid plotid: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1-harvest_complete
keep ea hhid plotid year harvest_complete
duplicates drop ea hhid plotid year,force
replace harvest_complete = 1 if year == 2013 & country == "Malawi"

/* -------- 2.1 Crop prices (from sales module) -------- */

use "${w2}/AG_MOD_I_13.dta", clear
rename y2_hhid hhid
rename ea_id   ea
g year = 2013
rename ag_i0b cropid

g sale_kg = ag_i02a             if ag_i02b == 1
replace sale_kg = ag_i02a * 50  if ag_i02b == 2
* lack conversion factor

rename ag_i03 sale_value
g price = sale_value / sale_kg if sale_kg > 0 & sale_kg != .

bysort cropid year: egen crop_price = mean(price)
keep cropid year crop_price
duplicates drop cropid year, force
save "${tmp}/2013_crop_price.dta", replace


/* -------- 2.2 Harvest quantity and plot yield -------- */

use "${w2}/AG_MOD_G_13.dta", clear
rename y2_hhid hhid
rename ea_id   ea
g year = 2013
rename ag_g00 plotid
capture rename ag_g0b cropid

g harvest_kg = ag_g13a             if ag_g13b == 1
replace harvest_kg = ag_g13a * 50 if ag_g13b == 2
replace harvest_kg = ag_g13a * 90 if ag_g13b == 3
* lack conversion factor

merge m:1 cropid year using "${tmp}/2013_crop_price.dta", ///
    keep(1 3) nogenerate
g harvest_value = harvest_kg * crop_price

bysort hhid ea plotid year: egen yield   = sum(harvest_value)
bysort hhid ea plotid year: egen n_crop  = count(cropid)
g intercrop = (n_crop > 1)

* Crop composition
g maize     = (cropid >= 1 & cropid <= 4)
g tobacco   = (cropid >= 5 & cropid <= 8)
g groundnut = (cropid >= 9 & cropid <= 14)
capture g sorghum = (cropname == "SORGHUM")  if cropname != ""
capture g soybean = (cropname == "BEANS" | cropname == "SOYABEAN") if cropname != ""
capture replace sorghum = 0 if sorghum == .
capture replace soybean = 0 if soybean == .

foreach crop in maize tobacco groundnut sorghum soybean {
    replace `crop' = `crop' * harvest_kg
    bysort hhid plotid year: egen `crop'_kg = sum(`crop')
}

duplicates drop hhid ea plotid year, force
keep hhid ea plotid year yield n_crop intercrop ///
     maize_kg tobacco_kg groundnut_kg sorghum_kg soybean_kg
save "${tmp}/2013_harvest.dta", replace


/* -------- 2.3 Plot area -------- */

use "${w2}/AG_MOD_C_13.dta", clear
rename y2_hhid hhid
rename ea_id   ea
g year = 2013
capture rename ag_c00 plotid

g parea = ag_c04c * 0.405
replace parea = ag_c04a            if ag_c04b == 2 & parea == .
replace parea = ag_c04a * 0.0001   if ag_c04b == 3 & parea == .
replace parea = ag_c04a * 0.405    if ag_c04b == 1 & parea == .
bysort ea hhid year: egen farm_size = sum(parea)

* Plot ownership: merge with manager
rename ag_d04a parcel_owner1
rename ag_d04b parcel_owner2
keep hhid ea plotid year parea parcel_owner1 parcel_owner2
duplicates drop hhid ea plotid year, force
save "${tmp}/2013_parea.dta", replace


/* -------- 2.4 Labor -------- */

use "${w2}/AG_MOD_D_13.dta", clear
rename y2_hhid hhid
rename ea_id   ea
g year = 2013
rename ag_d00 plotid

forvalues i = 1/12 {
    capture replace ag_d42d`i' = ag_d42b`i' * ag_d42c`i' * ag_d42d`i'
    capture replace ag_d43d`i' = ag_d43b`i' * ag_d43c`i' * ag_d43d`i'
}
capture {
    egen homelabor_mday = rowtotal(ag_d42d* ag_d43d*)
    replace homelabor_mday = homelabor_mday / 24
}
capture eigen hirelabor_mday = rowtotal(ag_d47a*)
capture g otherlabor_mday = ag_d50 if ag_d50 != .
capture replace otherlabor_mday = 0 if otherlabor_mday == .
capture g labor_mday = homelabor_mday + hirelabor_mday + otherlabor_mday

capture confirm var labor_mday
if _rc != 0 {
    gen labor_mday      = .
    gen homelabor_mday  = .
    gen hirelabor_mday  = .
}

* Plot manager and joint decision
rename ag_d01 indiv
keep y2_hhid ag_d00 ag_d01 ag_d01_1 ag_d01_2a ag_d01_2b
rename y2_* * //w/o year
rename ag_d00 plotid

cd "D:\climate_gender\Malawi"
merge m:1 hhid using 2010_2013_hhid
keep if _merge == 3
drop _merge hhid
rename case_id hhid
save "joint_decision.dta" //2013 (2010 missing-use 2013 status)

g joint_decision = (ag_d01_1 == 1)
merge m:1 hhid indiv year using hh_roster
drop if _merge == 2
drop _merge female_hhead sex
g spouse_joint = (relation_hhead1 == 2|relation_hhead2 == 2)
keep hhid plotid joint_decision spouse_joint

keep hhid ea plotid year indiv labor_mday homelabor_mday hirelabor_mday
duplicates drop hhid ea plotid year, force
save "${tmp}/2013_labor.dta", replace


/* -------- 2.5 Fertilizer and inputs -------- */

use "${w2}/AG_MOD_D_13.dta", clear
rename y2_hhid hhid
rename ag_d00 plotid
g year = 2013

* Inorganic fertilizer
g n_equiv1 = 0
capture {
    replace n_equiv1 = ag_d39d * 0.23 if ag_d39a == 1   /* NPK          */
    replace n_equiv1 = ag_d39d * 0.46 if ag_d39a == 4   /* Urea         */
    replace n_equiv1 = ag_d39d * 0.18 if ag_d39a == 2   /* DAP          */
    replace n_equiv1 = ag_d39d * 0.26 if ag_d39a == 3   /* CAN          */
    replace n_equiv1 = ag_d39d * 0.07 if ag_d39a == 5   /* D-compound   */
}

g n_equiv2 = 0
capture {
    replace n_equiv2 = ag_d39i * 0.23 if ag_d39f == 1
    replace n_equiv2 = ag_d39i * 0.46 if ag_d39f == 4
    replace n_equiv2 = ag_d39i * 0.18 if ag_d39f == 2
    replace n_equiv2 = ag_d39i * 0.26 if ag_d39f == 3
    replace n_equiv2 = ag_d39i * 0.07 if ag_d39f == 5
}

g inorganic_fertilizer = n_equiv1 + n_equiv2
capture replace inorganic_fertilizer = 0 if ag_d38 == 2   /* explicitly no fert */

* Input expenditure
use "${w2}/AG_MOD_F_13.dta", clear
rename y2_hhid hhid
g year = 2013

capture {
    gen input_cost = 0
    capture replace input_cost = input_cost + ag_f19 if ag_f19 != .
    capture replace input_cost = input_cost + ag_f29 if ag_f29 != .
    bysort hhid year: egen hh_input = sum(input_cost)
}

* Pesticide and other field management
capture g pesticide   = (ag_d40 == 2) if ag_d40 != .
capture g irrigation  = (ag_d28a != 7) if ag_d28a != .
capture g erosion_prot = (ag_d25a >= 2) if ag_d25a != .

keep hhid ea plotid year inorganic_fertilizer pesticide ///
     irrigation erosion_prot hh_input
duplicates drop hhid ea plotid year, force
save "${tmp}/2013_inputs.dta", replace


/* -------- 2.6 Seeds -------- */

use "${w2}/AG_MOD_G_13.dta", clear
rename case_id hhid
rename ag_g00 plotid
rename ag_g0b cropcode

capture {
    g seed_kg = ag_g04a * 0.001 if ag_g04b == 1   /* gram → kg      */
    replace seed_kg = ag_g04a       if ag_g04b == 2   /* kg             */
    replace seed_kg = ag_g04a * 2   if ag_g04b == 3   /* 2-kg bag       */
    replace seed_kg = ag_g04a * 3   if ag_g04b == 4   /* 3-kg bag       */
    replace seed_kg = ag_g04a * 3.7 if ag_g04b == 5   /* 3.7-kg bag     */
    replace seed_kg = ag_g04a * 5   if ag_g04b == 6   /* 5-kg bag       */
    replace seed_kg = ag_g04a * 10  if ag_g04b == 7   /* 10-kg bag      */
    replace seed_kg = ag_g04a * 50  if ag_g04b == 8   /* 50-kg bag      */
    bysort hhid plotid year: egen plot_seedkg = sum(seed_kg)
}

keep hhid ea plotid year plot_seedkg
duplicates drop hhid plotid year, force
save "${tmp}/2013_seeds.dta", replace


/* -------- 2.7 Extension contacts -------- */

use "${w2}/AG_MOD_T2_13.dta", clear
rename y2_hhid hhid
g year = 2013
capture rename ag_t05a indiv //a-d:merge with manager

g source = 1
bysort hhid indiv year: egen exten_channel = sum(source)
capture {
    egen frequency = rowtotal(ag_t06a ag_t07 ag_t08)
    bysort hhid indiv year: egen exten_frequency = sum(frequency)
}
capture gen exten_frequency = 0 if exten_frequency == .

keep hhid ea indiv year exten_channel exten_frequency
duplicates drop hhid indiv year, force
save "${tmp}/2013_extension.dta", replace


/* -------- 2.8 Household roster -------- */

use "${w2}/HH_MOD_B_13.dta", clear
rename y2_hhid hhid
rename ea_id   ea
g year = 2013
capture rename hh_b01 indiv
capture rename hh_b03  sex
capture rename hh_b04  relation_hhead
capture rename hh_b05a age

g female_ind = (sex == 2) if sex != .
g male_ind   = (sex == 1) if sex != .

g sex_hhead = sex - 1 if relation_hhead == 1
bysort hhid: egen female_hhead = max(sex_hhead)

capture rename hh_b24 marital 
g married      = (marital <= 2 & marital != .)
g married_mono = (marital == 1)
g married_poly = (marital == 2)
g separated    = (marital >= 3 & marital <= 5)
g unmarried    = (marital == 6)

g working_age = (age >= 15 & age <= 64) if age != .
bysort hhid: egen n_hhmember = count(indiv)
bysort hhid: egen n_working  = sum(working_age)
g dep_ratio = (n_hhmember - n_working) / n_working if n_working > 0

keep hhid ea indiv year sex female_ind male_ind age relation_hhead marital ///
     married married_mono married_poly separated unmarried ///
     female_hhead dep_ratio
save "${tmp}/2013_hhroster.dta", replace


/* -------- 2.9 HH assets (2013) -------- */

use "${w2}/HH_MOD_F_13.dta", clear
rename y2_hhid hhid
rename ea_id   ea
g year = 2013
capture rename hh_f19 electricity_code
capture g electricity = (electricity_code == 1) if electricity_code != .
capture replace electricity = 0 if electricity_code == 2
capture gen electricity = . if electricity == .
keep hhid ea year electricity
duplicates drop hhid year, force
save "${tmp}/2013_electricity.dta", replace

* Livestock
capture {
    use "${w2}/AG_MOD_R1_13.dta", clear
    rename y2_hhid hhid
    rename ea_id   ea
    g year = 2013
    capture rename ag_r00 livestock_code
    g livestock = (livestock_code == 1) if livestock_code != .
    keep hhid ea year livestock
    duplicates drop hhid year, force
    save "${tmp}/2013_livestock.dta", replace
}

* Non-farm enterprise
capture {
    use "${w2}/HH_MOD_N1_13.dta", clear
    rename y2_hhid hhid
    rename ea_id   ea
    g year = 2013
    capture rename hh_n0b nfe_code
    g nfe = (nfe_code == 1) if nfe_code != .
    keep hhid ea year nfe
    duplicates drop hhid year, force
    save "${tmp}/2013_nfe.dta", replace
}

* Machinery
use "${w2}/HH_MOD_M_13.dta", clear
rename y2_hhid hhid
rename ea_id   ea
g year = 2013
capture {
    replace hh_m03 = hh_m03 * hh_m01 if hh_m03 != . & hh_m01 != .
    rename hh_m03 hh_m03_total
    bysort hhid year: egen machine_own = sum(hh_m03_total)
    capture rename hh_m14 machine_rent
    capture replace machine_rent = 0 if machine_rent == .
    gen hh_machine_value = machine_own + machine_rent
}
capture gen hh_machine_value = 0 if hh_machine_value == .
keep hhid ea year hh_machine_value
duplicates drop hhid year, force
save "${tmp}/2013_machinery.dta", replace


/* -------- 2.10 Geovariables (2013) -------- */

use "${w2}/HouseholdGeovariables_IHPS_13.dta", clear
rename y2_hhid hhid
capture rename dist_road   dist_road
capture rename dist_agmrkt dist_market
capture rename srtm_1k   elevation

forvalues i=1/7{
	recode sq`i' (1=1) (2/7=0), gen(sq`i'_d)
}
factor sq1_d-sq7_d, pcf 
predict soil_fertility_pca

local names "nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability"
forvalues n =1/7 {
local lab: word `n' of `names'
rename	sq`n'_d `lab'
}

keep hhid dist_road dist_market elevation nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability soil_fertility_pca
save "${tmp}/2013_hhgeo.dta", replace

use "${w2}/PlotGeovariables_IHPS_13.dta", clear
rename y2_hhid hhid
capture rename ag_c00  plotid
capture rename slope plot_slope
capture rename elevation plot_elevation
capture rename twi plot_wetness
keep hhid plotid dist_hh plot_slope plot_elevation plot_wetness
save "${tmp}/2013_plotgeo.dta", replace


/* -------- 2.11 Merge Wave 2 into plot-level dataset -------- */

use "${tmp}/2013_harvest.dta", clear

merge m:1 hhid ea plotid year using "${tmp}/2013_parea.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid ea plotid year using "${tmp}/2013_labor.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid ea plotid year using "${tmp}/2013_inputs.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid plotid         using "${tmp}/2013_plotgeo.dta", ///
    keep(1 3) nogenerate

merge m:1 hhid indiv year     using "${tmp}/2013_hhroster.dta", ///
    keep(1 3) nogenerate ///
    keepusing(sex female_ind male_ind age marital ///
        married married_mono married_poly separated unmarried)
rename female_ind female
rename male_ind   male

merge m:1 hhid indiv year     using "${tmp}/2013_extension.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid year           using "${tmp}/2013_electricity.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid year           using "${tmp}/2013_livestock.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid year           using "${tmp}/2013_nfe.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid year           using "${tmp}/2013_machinery.dta", ///
    keep(1 3) nogenerate
merge m:1 hhid                using "${tmp}/2013_hhgeo.dta", ///
    keep(1 3) nogenerate

gen input = inorganic_fertilizer
replace input = 0 if input == .

g country   = "Malawi"
g countryid = 5   /* !! VERIFY */
capture g market_control = (dist_market <= 10) if dist_market != .
capture replace market_control = 0 if market_control == .

save "${tmp}/2013_plot.dta", replace


/* ============================================================
   SECTION 3: MERGE CLIMATE DATA
   ============================================================ */

* Build combined climate file
use "${clim}/2010_ssa.dta", clear
capture rename d   district
capture rename r   region
g year_clim = 2010
capture keep ea year gdd_10_30 hdd_30 pr pr2 ws ws2 sr sr2
save "${clim}/2010_climate_merge.dta", replace

use "${clim}/2013_ssa.dta", clear
g year_clim = 2013
capture keep ea year gdd_10_30 hdd_30 pr pr2 ws ws2 sr sr2
capture keep ea year gdd_10_30 hdd_30
save "${clim}/2013_climate_merge.dta", replace

use "${clim}/2010_climate_merge.dta", clear
append using "${clim}/2013_climate_merge.dta"
duplicates drop ea year, force
save "${clim}/malawi_climate.dta", replace

* Merge climate into plot dataset
use "${tmp}/2010_plot.dta", clear    /* re-load stacked dataset */
append using "${tmp}/2013_plot.dta"
gen id = hhid + "_" + string(plotid) + "_" + string(year)

merge m:1 ea year using "${clim}/malawi_climate.dta", ///
    keep(1 3) nogenerate


/* ============================================================
   SECTION 4: ANALYTICAL VARIABLES
   ============================================================ */

/* -------- Yield measures -------- */

g land_yield     = yield / parea         if parea > 0 & yield != .
g lnland_yield   = ln(land_yield)        if land_yield > 0
g ln_yield       = ln(yield)             if yield > 0

g labor_yield    = yield / labor_mday    if labor_mday > 0 & yield != .
g lnlabor_yield  = ln(labor_yield)       if labor_yield > 0

/* -------- Log labor -------- */

g lnland_labor   = ln(labor_mday / parea)  if labor_mday > 0 & parea > 0
g ln_labor       = ln(labor_mday)          if labor_mday > 0
g ln_homelabor   = ln(homelabor_mday)      if homelabor_mday > 0
g ln_hirelabor   = ln(hirelabor_mday)      if hirelabor_mday > 0

/* -------- Log input -------- */

replace input = . if input <= 0
g lnland_input   = ln(input / parea)       if input > 0 & parea > 0
g ln_input       = ln(input)               if input > 0

/* -------- Climate interaction terms -------- */

g female_hdd30  = female * hdd_30
g female_gdd30  = female * gdd_10_30


/* ============================================================
   SECTION 5: SAMPLE RESTRICTIONS AND SAVE
   ============================================================ */

/* -------- Sample restrictions -------- */

* Drop observations missing key regression variables
drop if yield      == . | yield <= 0
drop if parea      == . | parea <= 0
drop if female     == .

/* -------- Variable ordering and save -------- */

order id hhid plotid year country countryid ea indiv ///
    female male sex age ///
    married married_mono married_poly separated unmarried ///
    parcel_owner parea main_crop input n_crop intercrop ///
    labor_mday hirelabor_mday homelabor_mday ///
    yield land_yield lnland_yield ln_yield lnlabor_yield tfp_cd ///
    lnland_labor ln_labor ln_homelabor ln_hirelabor ///
    lnland_input ln_input ///
    maize_kg tobacco_kg groundnut_kg sorghum_kg soybean_kg ///
    hdd_30 gdd_10_30 female_hdd30 female_gdd30 ///
    exrate exten_channel exten_frequency market_control hh_machine_value

save "${out}/Malawi_sample.dta", replace
