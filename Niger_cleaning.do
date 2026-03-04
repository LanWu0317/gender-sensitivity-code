/*==============================================================================
Clean and harmonize Niger LSMS-ISA data for two survey waves:
ECVMA 2011 (Wave 1) and ECVMA-II 2014 (Wave 2)
==============================================================================*/

global raw11  "D:/climate_gender/Niger/NER_2011_ECVMA_v01_M_Stata8"
global raw14  "D:/climate_gender/Niger/NER_2014_ECVMA-II_v02_M_STATA8"


/*==============================================================================
  WAVE 2011 — ECVMA
  HH IDs : hid (pre-computed in raw data) | grappe (EA code)
  Plot ID : as01qa (pre-combined field+parcel identifier; project convention)
==============================================================================*/

*==============================================================================
* SECTION 1: Admin geography & individual roster (2011)
*==============================================================================

** 1a. Admin geography from cover section
use "${raw11}/ecvmasection00_p1.dta", clear
rename hid    hhid
rename grappe ea
rename ms00q10 admin_1    // region
rename ms00q11 admin_2    // département
rename ms00q12 admin_3    // commune
rename ms00q14 ea_id
g year = 2011
keep hhid ea year admin_1 admin_2 admin_3 ea_id
duplicates drop hhid, force
save "${work}/2011_admin.dta", replace

** 1b. Individual roster: sex, relation, age, marital status
use "${raw11}/ecvmaind_p1p2.dta", clear
rename hid     hhid
rename grappe  ea
rename ms01q00 indiv
rename ms01q01 sex        // 1 = male, 2 = female
rename ms01q02 relation   // 1 = household head
rename ms01q06a age
rename ms01q15 marital    // 1=single, 2=monogamous, 3=polygamous,
                          // 4=widowed, 5=divorced, 6=separated
g year = 2011

* Female indicator
g female = (sex == 2) if sex != .

* Marital status dummies (used for plot manager characteristics)
gen married      = (marital >= 2 & marital <= 3) if marital != .
gen married_mono = (marital == 2)                if marital != .
gen married_poly = (marital == 3)                if marital != .
gen separated    = (marital >= 4 & marital <= 6) if marital != .
gen unmarried    = (marital == 1)                if marital != .

* Household head's sex → female_hhead at HH level
g sex_hhead = (sex == 2) if relation == 1
bysort ea menage year: egen female_hhead = max(sex_hhead)   // 2011 uses ea+menage
drop sex_hhead

* Keep menage alongside ea so merge with plot data (ea menage year indiv) works
keep ea menage hhid year indiv sex female female_hhead age ///
     married married_mono married_poly separated unmarried relation
save "${work}/2011_hhroster.dta", replace


*==============================================================================
* SECTION 2: Plot management, area, joint decision (2011)
*==============================================================================

use "${raw11}/ecvmaas1_p1_en.dta", clear
rename hid hhid
rename grappe ea
g year = 2011

* Plot identifier
rename as01qa plotid

* Plot area: GPS preferred, self-reported as fallback
g parea = as01q09 / 10000
replace parea = as01q08 / 10000 if parea == . | parea == 0
bysort ea hhid year: egen farm_size = sum(parea)

append using 2014_crop_area
bysort hhid plotid year: egen plant_area = sum(crop_area)
replace plant_area = plant_area/10000 if year == 2011
duplicates drop hhid plotid year,force
merge 1:1 hhid plotid year using plot_size
keep if _merge == 3
drop _merge
g parea_threshold = parea*0.5
g portion_planted = (plant_area < parea_threshold)
save "planting_share.dta"

* Plot manager (individual ID)
rename as01q47 manager_id

* Irrigation: 5 = not irrigated
g irrigated = (as01q39 != 5 & as01q39 != .) if as01q39 != .

* Land tenure
rename as01q17 parcel_owner
g land_cert = (as01q18 == 1) if as01q18 != .

*--- Joint decision ---
keep grappe menage as01qa as02aq20a as02aq21a as02aq22a as02aq23a as02aq24a as02aq25a
g year = 2011
save "joint_decision.dta"

forvalues i = 20/25{
	replace as02aq`i'a = . if as02aq`i'a == indiv
}
g joint_decision = 0
forvalues i = 20/25{
	replace joint_decision = 1 if as02aq`i'a != .
}
merge m:1 ea menage indiv year using hh_roster
drop if _merge == 2
drop _merge female_hhead sex
g spouse_joint = (relation_hhead1 == 2|relation_hhead2 == 2|relation_hhead3 == 2|relation_hhead4 == 2|relation_hhead5 == 2|relation_hhead6 == 2)
keep ea menage plotid year joint_decision spouse_joint

keep ea menage hhid year plotid parea manager_id irrigated parcel_owner land_cert ///
     joint_decision spouse_joint
save "${work}/2011_plot.dta", replace


*==============================================================================
* SECTION 3: Harvest & yield (2011)
*==============================================================================

use "${raw11}/ecvmaas2e_p2_en.dta", clear
rename hid hhid
rename grappe ea
g year = 2011

rename as02eq01 field
rename as02eq03 parcel         //merge with id_num
rename as02eq06  cropid
rename as02eq07c harvest_kg    // qty converted to kg by survey team

* Shock and incomplete harvest
g crop_shock = (as02eq08 == 1) if as02eq08 != .  // 1=shock, 2=no
rename as02eq09 pct_not_harvested
g harvest_complete = 1 if year == 2011 //all harvests treated as complete

* Sales
rename as02eq12c sale_kg
rename as02eq13  sale_value    // CFA francs (XOF)

* Crop price: mean sale price per crop-year
g price = sale_value / sale_kg if sale_kg > 0 & sale_kg != .
bysort cropid year: egen crop_price = mean(price)

* Plot-level harvest value (yield proxy)
g harvest_value = harvest_kg * crop_price
bysort ea hhid plotid year: egen yield = sum(harvest_value)

* Crop composition
g millet    = (cropid == 1)    
g sorghum   = (cropid == 2)    
g cowpeas   = (cropid == 8)    
g groundnut = (cropid == 10)   
local croplist "millet sorghum cowpeas groundnut"
foreach c of local croplist {
    replace `c' = `c' * harvest_kg
    bysort hhid plotid year: egen `c'_kg = sum(`c')
    drop `c'
}

bysort ea hhid plotid year: egen plot_harvest = sum(harvest_kg)
duplicates drop ea hhid plotid year, force

keep ea hhid plotid year cropid harvest_kg crop_shock pct_not_harvested ///
     harvest_complete sale_kg sale_value yield plot_harvest crop_price ///
     millet_kg sorghum_kg cowpeas_kg groundnut_kg
save "${work}/2011_harvest.dta", replace


*==============================================================================
* SECTION 4: Labor — pre-planting (2011)
*==============================================================================

use "${raw11}/ecvmaas1_p1_en.dta", clear
rename hid hhid
rename grappe ea
rename as01qa plotid
g year = 2011

* Family labor
egen homelabor_mday = rowtotal(as02aq20b as02aq21b as02aq22b ///
                              as02aq23b as02aq24b as02aq25b)

* Hired labor
egen hirelabor_mday = rowtotal(as02aq26b as02aq26c as02aq26d ///
                              as02aq27b as02aq27c as02aq27d)
egen labor_mday = rowtotal(homelabor_mday hirelabor_mday)
keep hhid ea plotid year homelabor_mday hirelabor_mday labor_mday
save "${work}/2011_labor.dta", replace


*==============================================================================
* SECTION 5: Fertilizer & chemical inputs (2011)
*==============================================================================

use "${raw11}/ecvmaas1_p1_en.dta", clear
rename hid    hhid
rename grappe ea
rename as01qa plotid
g year = 2011

* Unit conversion for inorganic fertilizer
forvalues i = 1/4 {
    replace as02aq1`i'a = as02aq1`i'a * 5  if as02aq1`i'b == 2
    replace as02aq1`i'a = as02aq1`i'a * 10 if as02aq1`i'b == 3
    replace as02aq1`i'a = as02aq1`i'a * 25 if as02aq1`i'b == 4
    replace as02aq1`i'a = as02aq1`i'a * 50 if as02aq1`i'b == 5
    replace as02aq1`i'a = 0 if as02aq1`i'a == .|as02aq10 == 2
}
* as02aq11a=UREA, as02aq12a=DAP, as02aq13a=NPK, as02aq14a=other
egen fertilizer_kg = rowtotal(as02aq11a as02aq12a as02aq13a as02aq14a)
g N_content = as02aq11a*0.46 + as02aq12a*0.18 + as02aq13a*0.15

* Organic fertilizer indicator
g organic_fert = (as02aq06 == 1) if as02aq06 != .

* Pesticide indicator
g pesticide = (as02aq15 == 1) if as02aq15 != .

* Household-level total fertilizer use
bysort hhid year: egen hh_input = sum(fertilizer_kg)

keep hhid ea plotid year fertilizer_kg organic_fert pesticide hh_input
save "${work}/2011_fertilizer.dta", replace


*==============================================================================
* SECTION 6: Crop inputs, seeds, machinery & extension (2011)
*==============================================================================

** 6q. Crops and seed types

use "${raw11}/ecvmaas2b_p1_en.dta", clear
rename hid hhid
rename grappe ea
rename as01qn plotid
g year = 2011

* Intercrop indicator
g intercrop    = (as02bq07 == 2) ///
                 if (as02bq07 != 0 & as02bq07 != 9 & as02bq07 != .)

* Improved seed
g improved_seed = (as02bq09 >= 3 & as02bq09 <= 4) ///
                  if (as02bq09 != 0 & as02bq09 != 9 & as02bq09 != .)

* Crop area within plot
g carea = as02bq08 / 10000
bysort ea hhid plotid year: egen plot_carea = sum(carea)

duplicates drop ea hhid plotid year, force
keep ea hhid plotid year intercrop improved_seed plot_carea
save "${work}/2011_cropinfo.dta", replace

** 6b. Seed quantities

use "${raw11}/ecvmaas2c_p1_en.dta", clear
rename hid hhid
rename grappe ea
g year = 2011

rename as02cq04a seed_qty
rename as02cq04b seed_unit
replace seed_kg = as02cq05a if as02cq05b == 1 
replace seed_kg = as02cq05a if as02cq05b == 8
replace seed_kg = as02cq05a * 5 if as02cq05b == 2
replace seed_kg = as02cq05a * 10 if as02cq05b == 3
replace seed_kg = as02cq05a * 25 if as02cq05b == 4
replace seed_kg = as02cq05a * 50 if as02cq05b == 5
replace seed_kg = 0 if as02cq03 == 2

bysort ea hhid plotid year: cap egen plot_seedkg = sum(seed_kg)
duplicates drop ea hhid plotid year, force
cap keep ea hhid plotid year plot_seedkg
save "${work}/2011_seeds.dta", replace

** 6c. Household machinery / equipment

use "${raw11}/ecvmaas06_p2_en.dta", clear
rename hid hhid
rename grappe ea
g year = 2011

g machine_cost = as06q04 * as06q05
bysort hhid year: egen hh_machine_value = max(machine_cost)

duplicates drop hhid year, force
keep hhid ea year hh_machine_value
save "${work}/2011_machine.dta", replace

** 6d. Extension services

cap use "${raw11}/ecvmaas07_p2_en.dta", clear
if _rc != 0 cap use "${raw11}/ecvmaas07_p2_en.dta", clear

if _rc == 0 {
    rename hid    hhid
    rename grappe ea
    g year = 2011
    g ext_source = 1 if as07q04 > 0 & as07q04 != .
    bysort hhid year: egen exten_channel   = sum(ext_source)
    bysort hhid year: cap egen exten_frequency = sum(as07q06)
    duplicates drop hhid year, force
    keep hhid ea year exten_channel exten_frequency
    save "${work}/2011_extension.dta", replace
}
else {
    di "WARNING: Extension file not found for 2011 — placeholder created."
    di "VERIFY: identify correct extension services module file name."
    use "${work}/2011_machine.dta", clear
    keep hhid ea year
    g exten_channel   = .
    g exten_frequency = .
    save "${work}/2011_extension.dta", replace
}


*==============================================================================
* SECTION 7: Wave 2011 — merge all components into plot-level dataset
*==============================================================================

use "${work}/2011_plot.dta", clear

* Harvest & yield
merge 1:1 ea hhid plotid year using "${work}/2011_harvest.dta", keep(1 3) nogen

* Labor
merge 1:1 ea hhid plotid year using "${work}/2011_labor.dta", keep(1 3) nogen

* Fertilizer
merge 1:1 ea hhid plotid year using "${work}/2011_fertilizer.dta", keep(1 3) nogen

* Crop inputs (intercrop, improved seed, crop area)
merge 1:1 ea hhid plotid year using "${work}/2011_cropinfo.dta", keep(1 3) nogen

* Seed quantities
cap merge 1:1 ea hhid plotid year using "${work}/2011_seeds.dta", keep(1 3) nogen
cap g plot_seedkg = .    // in case seed file was not produced

* Plot manager's individual characteristics from household roster
* 2011 merge key: ea + menage + year + indiv (hhroster uses grappe+menage not hid)
rename manager_id indiv
merge m:1 ea menage year indiv using "${work}/2011_hhroster.dta", ///
    keepusing(sex female female_hhead married married_mono married_poly ///
              separated unmarried age) ///
    keep(1 3) nogen
rename indiv manager_id
rename sex   manager_sex

* Household-level variables
merge m:1 hhid ea year using "${work}/2011_machine.dta",   keep(1 3) nogen
merge m:1 hhid ea year using "${work}/2011_extension.dta", keep(1 3) nogen

* Admin geography
merge m:1 hhid ea year using "${work}/2011_admin.dta", keep(1 3) nogen

* Household-level seed and input aggregates
bysort hhid year: egen hh_seed = sum(plot_seedkg)

save "${work}/2011_merge.dta", replace


/*==============================================================================
  WAVE 2014 — ECVMA-II
  HH IDs : GRAPPE (EA) + MENAGE; constructed hhid = ea * 100 + menage
  Plot ID : AS01Q01 (field) * 100 + AS01Q03 (parcel)
==============================================================================*/

*==============================================================================
* SECTION 8: Admin geography & individual roster (2014)
*==============================================================================

** 8a. Admin geography
use "${raw14}/ECVMA2_MS00P1.dta", clear
rename GRAPPE ea
rename MENAGE menage
g hhid  = ea * 100 + menage
g year  = 2014
rename MS00Q10 admin_1
rename MS00Q11 admin_2
rename MS00Q12 admin_3
rename MS00Q14 ea_id
keep hhid ea year admin_1 admin_2 admin_3 ea_id
duplicates drop hhid, force
save "${work}/2014_admin.dta", replace

** 8b. Individual roster
use "${raw14}/ECVMA2_MS01P1.dta", clear
rename GRAPPE  ea
rename MENAGE  menage
g hhid = ea * 100 + menage
g year = 2014
rename MS01Q0  indiv
rename MS01Q01 sex        // 1 = male, 2 = female
rename MS01Q02 relation_hhead   // 1 = household head
rename MS01Q06A age
rename MS01Q15 marital    // 1=single, 2=mono, 3=poly, 4=widow, 5=divorced, 6=sep.

g female     = (sex == 2) if sex != .
gen married      = (marital >= 2 & marital <= 3) if marital != .
gen married_mono = (marital == 2)                if marital != .
gen married_poly = (marital == 3)                if marital != .
gen separated    = (marital >= 4 & marital <= 6) if marital != .
gen unmarried    = (marital == 1)                if marital != .

g sex_hhead = (sex == 2) if relation == 1
bysort hhid year: egen female_hhead = max(sex_hhead)
drop sex_hhead

keep hhid ea year indiv sex female female_hhead age ///
     married married_mono married_poly separated unmarried relation_hhead
save "${work}/2014_hhroster.dta", replace


*==============================================================================
* SECTION 9: Plot management, area, joint decision (2014)
*==============================================================================

** Source: ECVMA2_AS1P1.dta (plot roster)
use "${raw14}/ECVMA2_AS1P1.dta", clear
rename GRAPPE ea
rename MENAGE menage
rename AS01QA plotid
g hhid = ea * 100 + menage
g year = 2014

* Plot area
g parea = AS01Q07 / 10000
replace parea = AS01Q07_2 / 10000 if parea == . | parea == 0
replace parea = AS01Q06  / 10000  if parea == . | parea == 0
bysort ea hhid year: egen farm_size = sum(parea)

* Plot manager
rename AS01Q45 manager_id

* Irrigation
g irrigated = (AS01Q31 != 5 & AS01Q31 != 7 & AS01Q31 != 9 & AS01Q31 != .) ///
               if AS01Q31 != .
replace irrigated = 1 if AS01Q35 == 1

* Land tenure
rename (AS01Q17A AS01Q17B) (onwer1 owner2)
g land_cert = (AS01Q15 == 1) if AS01Q15 != .

keep hhid ea year plotid parea manager_id irrigated owner1 owner2 land_cert
save "${work}/2014_plot.dta", replace

** Joint decision

keep GRAPPE MENAGE AS02AQA AS02AQ17A AS02AQ18A AS02AQ19A AS02AQ20A AS02AQ21A AS02AQ22A
g year = 2014
save "joint_decision.dta"

forvalues i = 20/25{
	replace as02aq`i'a = . if as02aq`i'a == indiv
}
g joint_decision = 0
forvalues i = 20/25{
	replace joint_decision = 1 if as02aq`i'a != .
}
merge m:1 ea menage indiv year using hh_roster
drop if _merge == 2
drop _merge female_hhead sex
g spouse_joint = (relation_hhead1 == 2|relation_hhead2 == 2|relation_hhead3 == 2|relation_hhead4 == 2|relation_hhead5 == 2|relation_hhead6 == 2)
keep ea menage plotid year joint_decision spouse_joint


*==============================================================================
* SECTION 10: Harvest & yield (2014)
*==============================================================================

** 10a. Harvest quantities
use "${raw14}/ECVMA2_AS2E1P2.dta", clear
rename GRAPPE ea
rename MENAGE menage
rename AS02EQ01 field
rename AS02EQ03 parcel //merge with id_num
g hhid = ea * 100 + menage
g year = 2014

rename CULTURE    cropid
rename AS02EQ07C  harvest_kg // harvest quantity in kg (converted)

keep GRAPPE MENAGE AS02EQ0 CULTURE AS02EQ06A AS02EQ06B AS02EQ07D
g harvest_less = (AS02EQ06A == 0|AS02EQ06B == 99|AS02EQ07D == 2)
bysort ea hhid plotid: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1 - harvest_complete //harvest completion
keep ea hhid plotid harvest_complete
duplicates drop ea hhid plotid,force

keep ea hhid plotid year cropid harvest_kg crop_shock harvest_complete controller
save "${work}/2014_harvest_qty.dta", replace

** 10b. Crop sales
use "${raw14}/ECVMA2_AS2E2P2.dta", clear
rename GRAPPE ea
rename MENAGE menage
rename AS02EQ01 field
rename AS02EQ03 parcel //merge with id_num
g hhid = ea * 100 + menage
g year = 2014

rename AS02EQ110B cropid
rename AS02EQ12C  sale_kg       // sale quantity in kg (converted)
rename AS02EQ13   sale_value    // CFA francs

* Revenue controller
rename AS02EQ17A controller1
rename AS02EQ17B controller2

* Crop price from sales data
g price = sale_value / sale_kg if sale_kg > 0 & sale_kg != .
bysort cropid year: egen crop_price = mean(price)

keep ea hhid plotid year cropid sale_kg sale_value crop_price
save "${work}/2014_sales.dta", replace

** 10c. Merge harvest + sales; compute plot-level yield
use "${work}/2014_harvest_qty.dta", clear
merge m:1 ea hhid plotid year cropid using "${work}/2014_sales.dta", ///
    keep(1 3) nogen

g harvest_value = harvest_kg * crop_price
bysort ea hhid plotid year: egen yield = sum(harvest_value)

* Crop composition
g millet    = (cropid == 1)    
g sorghum   = (cropid == 2)    
g cowpeas   = (cropid == 8)    
g groundnut = (cropid == 10) 
local croplist "millet sorghum cowpeas groundnut"
foreach c of local croplist {
    replace `c' = `c' * harvest_kg
    bysort hhid plotid year: egen `c'_kg = sum(`c')
    drop `c'
}

bysort ea hhid plotid year: egen plot_harvest = sum(harvest_kg)
duplicates drop ea hhid plotid year, force

keep ea hhid plotid year cropid harvest_kg crop_shock harvest_complete ///
     sale_kg sale_value yield plot_harvest crop_price controller ///
     millet_kg sorghum_kg cowpeas_kg groundnut_kg
save "${work}/2014_harvest.dta", replace


*==============================================================================
* SECTION 11: Labor — pre-planting (PP) and harvest (PH) (2014)
*==============================================================================

use "${raw14}/ECVMA2_AS2AP1.dta", clear
rename GRAPPE ea
rename MENAGE menage
rename AS02AQA plotid
g hhid = ea * 100 + menage
g year = 2014

* Family labor
egen homelabor_mday = rowtotal(AS02AQ17B AS02AQ18B AS02AQ19B ///
                              AS02AQ20B AS02AQ21B AS02AQ22B)

* Hired labor
egen hirelabor_mday = rowtotal(AS02AQ23B AS02AQ23C AS02AQ23D ///
                              AS02AQ24B AS02AQ24C AS02AQ24D)
egen labor_mday = rowtotal(homelabor_mday hirelabor_mday)

keep hhid ea plotid year homelabor_mday hirelabor_mday labor_mday
save "${work}/2014_labor.dta", replace


*==============================================================================
* SECTION 12: Fertilizer & chemical inputs (2014)
*==============================================================================

use "${raw14}/ECVMA2_AS2AP1.dta", clear
rename GRAPPE ea
rename MENAGE menage
rename AS02AQA plotid
g hhid = ea * 100 + menage
g year = 2014

* Fertilizer quantities (unit conversion)
replace AS02AQ09B = AS02AQ09B * 5  if AS02AQ09C == 2
replace AS02AQ09B = AS02AQ09B * 10 if AS02AQ09C == 3
replace AS02AQ09B = AS02AQ09B * 25 if AS02AQ09C == 4
replace AS02AQ09B = AS02AQ09B * 50 if AS02AQ09C == 5
replace AS02AQ09B = 0 if AS02AQ09B == .|AS02AQ10B == 2

forvalues i = 0/2 {
    replace AS02AQ1`i'B = AS02AQ1`i'B * 5  if AS02AQ1`i'C == 2
    replace AS02AQ1`i'B = AS02AQ1`i'B * 10 if AS02AQ1`i'C == 3
    replace AS02AQ1`i'B = AS02AQ1`i'B * 25 if AS02AQ1`i'C == 4
    replace AS02AQ1`i'B = AS02AQ1`i'B * 50 if AS02AQ1`i'C == 5
    replace AS02AQ1`i'B = 0 if AS02AQ1`i'B == .|AS02AQ10A == 2
}
egen fertilizer_kg = rowtotal(AS02AQ09B AS02AQ10B AS02AQ11B AS02AQ12B)
replace fertilizer_kg = 0 if fertilizer_kg == .
g N_content = AS02AQ09B*0.46 + AS02AQ10B*0.18 + AS02AQ11B*0.15

* Organic fertilizer
g organic_fert = (AS02AQ06A == 1 | AS02AQ07A == 1) ///
                  if (AS02AQ06A != . | AS02AQ07A != .)

* Pesticide
g pesticide = (AS02AQ13A == 1) if AS02AQ13A != .
bysort hhid year: egen hh_input = sum(AS02CQ08C)

keep hhid ea plotid year fertilizer_kg organic_fert pesticide hh_input
save "${work}/2014_fertilizer.dta", replace


*==============================================================================
* SECTION 13: Crop inputs, seeds, machinery & extension (2014)
*==============================================================================

** 13a. Crop-level inputs: intercrop, improved seed, crop area

use "${raw14}/ECVMA2_AS2BP1.dta", clear
rename GRAPPE ea
rename MENAGE menage
rename AS02EQ01 field
rename AS02EQ03 parcel //merge with id_num
g hhid = ea * 100 + menage
g year = 2014

g intercrop    = (AS02BQ07 == 2) ///
                  if (AS02BQ07 != 0 & AS02BQ07 != 9 & AS02BQ07 != .)

g improved_seed = (AS02BQ09 >= 3 & AS02BQ09 <= 4) ///
                  if (AS02BQ09 != 0 & AS02BQ09 != 9 & AS02BQ09 != .)

duplicates drop ea hhid plotid year, force
keep ea hhid plotid year intercrop improved_seed
save "${work}/2014_cropinfo.dta", replace

** 13b. Seed quantities

use "${raw14}/ECVMA2_AS02CP1.dta", clear
rename GRAPPE ea
rename MENAGE menage
rename AS02CQ04 cropid
g hhid = ea * 100 + menage
g year = 2014

g seed_kg = AS02CQ05A  if AS02CQ05B==1 
replace seed_kg = AS02CQ05A if AS02CQ05B==5 // litre
replace seed_kg = AS02CQ05A * 0.001 if AS02CQ05B==2 // gram 
replace seed_kg = 0 if AS02CQ03==2

cap bysort ea hhid plotid year: egen plot_seedkg = sum(seed_kg)
cap duplicates drop ea hhid plotid year, force
cap keep ea hhid plotid year plot_seedkg
cap save "${work}/2014_seeds.dta", replace

** 13c. Agricultural machinery (household level)

use "${raw14}/ECVMA2_AS03P1.dta", clear
rename GRAPPE ea
rename MENAGE menage
g hhid = ea * 100 + menage
g year = 2014

g machine_cost = AS03Q04 * AS03Q05
bysort hhid year: egen hh_machine_value = max(machine_cost)

duplicates drop hhid year, force
keep hhid ea year hh_machine_value
save "${work}/2014_machine.dta", replace

** 13d. Extension services (2014)

cap use "${raw14}/ECVMA2_AS07P2.dta", clear
if _rc == 0 {
    rename GRAPPE ea
    rename MENAGE menage
    g hhid = ea * 100 + menage
    g year = 2014
    cap g ext_source = 1 if AS07Q04 > 0 & AS07Q04 != .
    cap bysort hhid year: egen exten_channel   = sum(ext_source)
    cap bysort hhid year: egen exten_frequency = sum(AS07Q06)
    duplicates drop hhid year, force
    keep hhid ea year exten_channel exten_frequency
    save "${work}/2014_extension.dta", replace
}
else {
    di "WARNING: Extension file not found for 2014 — placeholder created."
    di "VERIFY: check variable names in ECVMA2_AS07P2.dta"
    use "${work}/2014_machine.dta", clear
    keep hhid ea year
    g exten_channel   = .
    g exten_frequency = .
    save "${work}/2014_extension.dta", replace
}


*==============================================================================
* SECTION 14: Wave 2014 — merge all components
*==============================================================================

use "${work}/2014_plot.dta", clear

merge 1:1 ea hhid plotid year using "${work}/2014_harvest.dta", keep(1 3) nogen
merge 1:1 ea hhid plotid year using "${work}/2014_labor.dta",   keep(1 3) nogen
merge 1:1 ea hhid plotid year using "${work}/2014_fertilizer.dta", keep(1 3) nogen
merge 1:1 ea hhid plotid year using "${work}/2014_cropinfo.dta",   keep(1 3) nogen

cap merge 1:1 ea hhid plotid year using "${work}/2014_seeds.dta", keep(1 3) nogen
cap g plot_seedkg = .    // in case seed file was not produced

merge 1:1 ea hhid plotid year using "${work}/2014_jointdecision.dta", ///
    keep(1 3) nogen

* Plot manager characteristics from household roster
rename manager_id indiv
merge m:1 hhid ea year indiv using "${work}/2014_hhroster.dta", ///
    keepusing(sex female female_hhead married married_mono married_poly ///
              separated unmarried age) ///
    keep(1 3) nogen
rename indiv manager_id
rename sex   manager_sex

merge m:1 hhid ea year using "${work}/2014_machine.dta",   keep(1 3) nogen
merge m:1 hhid ea year using "${work}/2014_extension.dta", keep(1 3) nogen
merge m:1 hhid ea year using "${work}/2014_admin.dta",     keep(1 3) nogen

bysort hhid year: egen hh_seed = sum(plot_seedkg)

save "${work}/2014_merge.dta", replace


*==============================================================================
* SECTION 15: Merge climate, append waves, construct final variables & save
*==============================================================================

use "${work}/2011_merge.dta", clear
merge m:1 ea year using "${work}/2011_ssa.dta", ///
    keepusing(gdd_10_30 hdd_30) keep(1 3) nogen
merge m:1 ea year using "${work}/2011_ssa1.dta", ///
    keepusing(HDD_32 GDD_10_32 pr ws sr) keep(1 3) nogen
save "${work}/2011_climate.dta", replace

use "${work}/2014_merge.dta", clear
merge m:1 ea year using "${work}/2014_ssa.dta", ///
    keepusing(gdd_10_30 hdd_30) keep(1 3) nogen
merge m:1 ea year using "${work}/2014_ssa1.dta", ///
    keepusing(HDD_32 GDD_10_32 pr ws sr) keep(1 3) nogen
save "${work}/2014_climate.dta", replace

use "${work}/2011_climate.dta", clear
append using "${work}/2014_climate.dta"

** 15b. Standardise climate variable names
rename hdd_30    hdd_30_che
rename gdd_10_30 gdd_10_30_che
rename HDD_32    hdd_32_che
rename GDD_10_32 gdd_10_32_che

** 15c. Derived analytical variables

* Log yield per hectare
g land_yield    = yield / parea   if parea > 0 & parea != .
g lnland_yield = ln(land_yield)   if land_yield != .

* Input intensities per hectare
g labor_ha = labor_mday    / parea if parea > 0
g fert_ha  = fertilizer_kg / parea if parea > 0

* Log transformations
g ln_parea  = ln(parea)
g ln_labor  = ln(labor_mday + 1)
g ln_fert   = ln(fertilizer_kg + 1)

* Weather controls (quadratic terms for regression)
g pr2 = pr^2
g ws2 = ws^2
g sr2 = sr^2

** 15e. Sample restrictions

drop if parea == . | parea <= 0
drop if yield == . | yield < 0
drop if female == .