/* ==========================================================================
   Tanzania LSMS-ISA NPS Waves 2, 3, 4 (Survey years 2010, 2012, 2014)
   ========================================================================== */

global raw2010 "D:\climate_gender\Tanzania\TZA_2010_NPS-R2_v03_M_STATA8"
global raw2012 "D:\climate_gender\Tanzania\TZA_2012_NPS-R3_v01_M_STATA8"
global raw2014 "D:\climate_gender\Tanzania\TZA_2014_NPS-R4_v03_M_STATA11"


// ==========================================================================
// SECTION 1: WAVE 2010 (NPS Round 2)
// Agricultural files: AG_SEC3A.dta (plot level), AG_SEC4A.dta (crop level)
// ==========================================================================

// --------------------------------------------------------------------------
// 1.1  Household Roster – sex and household head gender
// --------------------------------------------------------------------------
use "${raw2010}\HH_SEC_B.dta", clear
keep y2_hhid indidy2 hh_b02 hh_b05
rename y2_hhid       hhid
rename indidy2        indiv
rename hh_b02         sex            
rename hh_b05         relation_hhead 
gen year = 2010

// Female household head indicator
gen sex_hhead = sex - 1 if relation_hhead == 1
bysort hhid year: egen female_hhead = max(sex_hhead)
drop sex_hhead
save "${out}\2010_hhroster.dta", replace

// --------------------------------------------------------------------------
// 1.2  Plot Area
//      GPS acres × 0.405 ≈ hectares; self-reported as fallback
// --------------------------------------------------------------------------
use "${raw2010}\AG_SEC2A.dta", clear
rename y2_hhid hhid
rename plotnum plotid
gen parea = ag2a_09 * 0.405
replace parea = ag2a_04 * 0.405 if parea == .
bysort hhid year: egen farm_size = sum(parea)
gen year = 2010
keep hhid plotid parea year
duplicates drop hhid plotid year, force
save "${out}\2010_plotarea.dta", replace

// --------------------------------------------------------------------------
// 1.3  Plot Manager, Joint Decision, and Agricultural Inputs
//      AG_SEC3A is plot-level (one row per plot in long-rain season)
// --------------------------------------------------------------------------
use "${raw2010}\AG_SEC3A.dta", clear
rename y2_hhid hhid
rename plotnum plotid
gen year = 2010

// Keep only long rainy season (Masika) plots
rename ag3a_03 season
keep if season == 1

// Primary plot manager individual ID
rename ag3a_08_1 indiv

// Joint decision: any additional co-manager listed?
keep hhid plotid indiv ag3a_08_2 ag3a_08_3 ag3a_08_4 year
save "joint_decision.dta"

g joint_decision = 0
replace joint_decision = 1 if ag3a_08_2 != .
replace joint_decision = 1 if ag3a_08_3 != .
replace joint_decision = 1 if ag3a_08_4 != ""
merge m:1 hhid indiv year using hh_roster_dup
drop if _merge == 2
drop _merge female_hhead sex
g spouse_joint = (relation_hhead1 == 2|relation_hhead2 == 2)
keep hhid plotid year joint_decision spouse_joint

// Inorganic fertilizer
recode ag3a_45 (1=1)(2=0), gen(inorganic_fertilizer)

// Inorganic fertilizer value
gen fert_val2 = ag3a_49
replace fert_val2 = 0 if fert_val1 == .
gen fert_val3 = ag3a_56
replace fert_val3 = 0 if fert_val2 == .
gen inorganic_fertilizer_value = fert_val1 + fert_val2
replace inorganic_fertilizer_value = . if inorganic_fertilizer == 0
drop fert_val1 fert_val2

// Organic fertilizer
recode ag3a_39 (1=1)(2=0), gen(organic_fertilizer)

// Pesticides/herbicides
capture recode ag3a_59 (1=1)(.=.)(else=0), gen(used_pesticides)
if _rc != 0 gen used_pesticides = .
capture replace used_pesticides = 1 if ag3a_58 == 1
capture replace used_pesticides = 0 if ag3a_58 == 2
gen pesticide_cost = ag3a_61 //add herbicides
replace pesticide_cost = 0 if pesticide_cost == .

// Irrigation
recode ag3a_17 (1=1)(2=0), gen(irrigated)

// Land tenure
recode ag3a_24 (1=1)(5=1)(else=0), gen(owned)
rename (ag3a_29_1 ag3a_29_2) (owner1 owner2)

// Plot certificate
recode ag3a_27 (1=1)(2=0), gen(parcel_certified)

// Family labor days
egen homelabor_mday = rowtotal(ag3a_70_1 ag3a_70_2 ag3a_70_3 ag3a_70_4 ag3a_70_5 ag3a_70_6 ag3a_70_13 ag3a_70_14 ag3a_70_15 ag3a_70_16 ag3a_70_17 ag3a_70_18 ag3a_70_37 ag3a_70_38 ag3a_70_39 ag3a_70_40 ag3a_70_41 ag3a_70_42)

// Hired labor days
capture egen hirelabor_mday = rowtotal(ag3a_72_1 ag3a_72_2 ag3a_72_21 ///
                                       ag3a_72_4 ag3a_72_5 ag3a_72_51 ///
									   ag3a_72_61 ag3a_72_62 ag3a_72_63)
replace hirelabor_mday = 0 if ag3a_71 == 2   // no hired labour used
egen labor_mday = rowtotal(homelabor_mday hirelabor_mday)

keep hhid plotid indiv year season joint_decision comgr_id2 comgr_id3 comgr_id4 ///
     inorganic_fertilizer inorganic_fertilizer_value_LCU organic_fertilizer ///
     used_pesticides pesticide_cost irrigated parcel_owner parcel_certified ///
     homelabor_mday hirelabor_mday ///
     ag3a_43 ag3a_49 ag3a_56 ag3a_61   // kept for total_input computation

save "${out}\2010_plotmg.dta", replace

// --------------------------------------------------------------------------
// 1.4  Crop Harvest and Seed Inputs
//      AG_SEC4A is crop-level (multiple rows per plot)
// --------------------------------------------------------------------------
use "${raw2010}\AG_SEC4A.dta", clear
rename y2_hhid hhid
rename plotnum plotid
rename zaocode cropid
gen year = 2010

// Intercropping: ag4a_04 (1=intercropped, 2=monocrop)
recode ag4a_04 (1=1)(2=0), gen(intercrop)

// Harvest quantity and value
// ag4a_06: was crop harvested? (1=yes, 2=no)
// ag4a_15: harvest quantity (kg – unit conversion done by LSMS team)
// ag4a_16: harvest value (TZS)
gen harvest_kg  = ag4a_15
replace harvest_kg  = 0 if ag4a_06 == 2
gen harvest_val = ag4a_16
replace harvest_val = 0 if ag4a_06 == 2

// Improved seed
recode ag4a_08 (1=1)(3=1)(2=0)(4=.), gen(improved)

// Seed purchase value (used to compute total input cost)
// ag4a_21 = seed value paid (TZS)
capture gen seed_val = ag4a_21
if _rc != 0 gen seed_val = .
replace seed_val = 0 if seed_val == .
bysort hhid plotid year: egen seed_input = sum(seed_val)

// Plot-level yield: sum harvest value across all crops on plot
bysort hhid plotid year: egen pyield  = sum(harvest_val)
bysort hhid plotid year: egen yieldkg = sum(harvest_kg)

// Crop names: decode crop code to string, then normalise to lowercase
decode cropid, gen(cropname_raw)
gen cropname = strtrim(strlower(cropname_raw))

// Crop-specific yield (kg) for key commodities
local croplist "maize paddy sorghum beans groundnut"
foreach c of local croplist {
    gen `c' = 0
}
replace maize     = harvest_kg if regexm(cropname, "maize|corn")
replace paddy     = harvest_kg if regexm(cropname, "paddy|rice")
replace sorghum   = harvest_kg if regexm(cropname, "sorghum")
replace beans     = harvest_kg if regexm(cropname, "bean")
replace groundnut = harvest_kg if regexm(cropname, "groundnut|peanut|g.nut")

foreach c of local croplist {
    bysort hhid plotid year: egen `c'_kg = sum(`c')
    drop `c'
}

duplicates drop hhid plotid year, force
keep hhid plotid year intercrop improved seed_kg seed_input ///
     pyield yieldkg ///
     maize_kg paddy_kg sorghum_kg beans_kg groundnut_kg

save "${out}\2010_harvest.dta", replace

// --------------------------------------------------------------------------
// 1.5  Planting Share (portion of plot actually planted)
// --------------------------------------------------------------------------
use "${raw2010}\AG_SEC4A.dta", clear
rename y2_hhid hhid
rename plotnum plotid
rename zaocode cropid
gen year = 2010

// ag4a_01: was this plot cultivated in the season? (1=yes fully, 2=partial?)
// ag4a_02: share of plot planted with this crop (1=25%, 2=50%, 3=75%)
gen crop_share = 25 if ag4a_02 == 1
replace crop_share = 50 if ag4a_02 == 2
replace crop_share = 75 if ag4a_02 == 3
bysort hhid plotid year: egen plant_share = sum(crop_share)
replace plant_share = . if ag4a_01 == 1   // whole plot planted → no portion concern
gen portion_planted = (plant_share < 100 & plant_share != .)

keep hhid plotid year portion_planted
duplicates drop hhid plotid year, force
save "${out}\2010_plantshare.dta", replace

// --------------------------------------------------------------------------
// 1.6  Harvest Completion Status
// --------------------------------------------------------------------------
use "${raw2010}\AG_SEC4B.dta", clear
rename y2_hhid hhid
rename plotnum plotid
gen year = 2010

// ag4b_07==2: harvest incomplete/failed; ag4b_12==2: additional incomplete flag
gen harvest_less    = (ag4b_07 == 2 | ag4b_12 == 2)
// ag4b_14: loss percentage → harvest_percent = 100 - loss%
gen harvest_percent = 100 - ag4b_14

bysort hhid plotid: egen harvest_comp_flag = max(harvest_less)
bysort hhid plotid: egen harvest_portion   = mean(harvest_percent)
gen harvest_complete = 1 - harvest_comp_flag
drop harvest_comp_flag harvest_less harvest_percent

duplicates drop hhid plotid year, force
keep hhid plotid year harvest_complete harvest_portion
save "${out}\2010_harvestcomp.dta", replace

// --------------------------------------------------------------------------
// 1.7  Farm Equipment / Machine Value
// --------------------------------------------------------------------------
use "${raw2010}\AG_SEC11.dta", clear
rename y2_hhid hhid
gen year = 2010

// ag11_04==1: household owns the item  ag11_02: current value of owned item
// ag11_09: rental value paid for hired item
gen value_used = 0
replace value_used = ag11_02 if ag11_04 == 1
egen value_total = rowtotal(value_used ag11_09)

// Irrigation/watering equipment (item code 11)
gen water_value = 0
replace water_value = value_total if itemcode == 11
bysort hhid: egen hh_machine_value = sum(value_total)
bysort hhid: egen HH_WATERING      = sum(water_value)

keep hhid year hh_machine_value HH_WATERING
duplicates drop hhid year, force
save "${out}\2010_machine.dta", replace

// --------------------------------------------------------------------------
// 1.8  Extension Services
//      AG_SEC12A: one row per extension source; ag12a_03_1..4 = recipient IDs
// --------------------------------------------------------------------------
use "${raw2010}\AG_SEC12A.dta", clear
rename y2_hhid hhid
gen year = 2010
recode ag12a_01 (2=0)
rename ag12a_01 exten_dummy

// Recode channels
forvalues i = 1/5 {
    capture recode ag12a_02_`i' (2=0)
}
// Total channels received per extension source
capture egen channel = rowtotal(ag12a_02_*)
if _rc != 0 gen channel = .

// Extension visit frequency
capture rename ag12a_06 frequency
save "${out}\2010_ext_raw.dta", replace

// Expand to individual level
forvalues i = 1/4 {
    use "${out}\2010_ext_raw.dta", clear
    capture confirm variable ag12a_03_`i'
    if _rc == 0 {
        keep hhid channel frequency ag12a_03_`i' year
        rename ag12a_03_`i' indiv
        drop if indiv == .
        bysort hhid indiv: egen exten`i'_channel   = sum(channel)
        bysort hhid indiv: egen exten`i'_frequency = sum(frequency)
        duplicates drop hhid indiv, force
        keep hhid indiv year exten`i'_*
        save "${out}\2010_ext_indiv`i'.dta", replace
    }
}

// Merge across recipients and collapse to one row per household-individual
use "${out}\2010_ext_indiv1.dta", clear
forvalues i = 2/4 {
    capture merge 1:1 hhid indiv year using "${out}\2010_ext_indiv`i'.dta", nogen
}

// Aggregate across multiple sources: take max channel count and total frequency
capture {
    egen exten_channel   = rowmax(exten1_channel   exten2_channel   exten3_channel   exten4_channel)
    egen exten_frequency = rowmax(exten1_frequency exten2_frequency exten3_frequency exten4_frequency)
}
if _rc != 0 {
    gen exten_channel   = .
    gen exten_frequency = .
}
replace exten_channel   = 0 if exten_channel   == .
replace exten_frequency = 0 if exten_frequency == .

keep hhid indiv year exten_channel exten_frequency
save "${out}\2010_extension.dta", replace

// --------------------------------------------------------------------------
// 1.9  Individual Characteristics
// --------------------------------------------------------------------------
use "${raw2010}\HH_SEC_B.dta", clear
rename y2_hhid hhid
rename indidy2 indiv
rename hh_b02  sex
gen year = 2010

rename hh_b04 age
rename hh_b05 relation_hhead
capture rename hh_b19 marital

// Marital status recode
gen married      = (marital <= 3 & marital != .)
gen married_mono = (marital == 1)
gen married_poly = (marital == 2)
gen separated    = ((marital >= 4 & marital <= 5) | marital == 7) if marital != .
gen unmarried    = (marital == 6) if marital != .

keep hhid indiv sex age relation_hhead year marital ///
     married married_mono married_poly separated unmarried
save "${out}\2010_individual.dta", replace

// --------------------------------------------------------------------------
// 1.10  Geovariables: EA identifier, latitude, longitude
// --------------------------------------------------------------------------
use "${raw2010}\HH.Geovariables_Y2.dta", clear
rename y2_hhid hhid
gen year = 2010

capture rename lat_modified lat
capture rename lon_modified lon
capture rename ea_id ea

keep hhid year ea lat lon
duplicates drop hhid year, force
save "${out}\2010_geo.dta", replace

// --------------------------------------------------------------------------
// 1.11  Merge All 2010 Files → Plot-level Dataset
// --------------------------------------------------------------------------
use "${out}\2010_plotmg.dta", clear

merge m:1 hhid plotid year using "${out}\2010_plotarea.dta", keep(1 3) nogen
merge m:1 hhid plotid year using "${out}\2010_harvest.dta", keep(1 3) nogen
merge m:1 hhid plotid year using "${out}\2010_harvestcomp.dta", keep(1 3) nogen
merge m:1 hhid plotid year using "${out}\2010_plantshare.dta", keep(1 3) nogen
merge m:1 hhid year using "${out}\2010_machine.dta", keep(1 3) nogen
merge m:1 hhid indiv year using "${out}\2010_extension.dta", keep(1 3) nogen
merge m:1 hhid indiv year using "${out}\2010_individual.dta", keep(1 3) nogen
merge m:1 hhid indiv year using "${out}\2010_hhroster.dta", keep(1 3) nogen
merge m:1 hhid year using "${out}\2010_geo.dta", keep(1 3) nogen

// ---- Derived variables ----

// Total input cost
// ag3a_43, ag3a_49, ag3a_56, ag3a_61 retained from plotmg file
foreach v in ag3a_43 ag3a_49 ag3a_56 ag3a_61 seed_input pesticide_cost {
    replace `v' = 0 if `v' == .
}
gen input = seed_input + ag3a_43 + ag3a_49 + ag3a_56 + pesticide_cost
drop ag3a_43 ag3a_49 ag3a_56 ag3a_61

// Female plot manager indicator
gen female = (sex == 2) if sex != .
gen male   = (sex == 1) if sex != .
save "${out}\2010_plot.dta", replace


// ==========================================================================
// SECTION 2 and 3: WAVE 2012 and 2014 (NPS Round 3 and 4)
// Variable structure mirrors Wave 2010 but file prefix is 2012_ and 2014_
// ==========================================================================


// ==========================================================================
// SECTION 4: APPEND ALL WAVES AND HARMONIZE
// ==========================================================================

use "${out}\2010_plot.dta", clear
append using "${out}\2012_plot.dta"
append using "${out}\2014_plot.dta"

// Only long-rain season plots (already filtered per wave)
// Confirm and drop any residual non-season observations
drop if season != 1
drop season

// ---- Zero-fill commodity kg (missing = crop not grown on plot) ----
foreach v in maize_kg paddy_kg sorghum_kg beans_kg groundnut_kg {
    replace `v' = 0 if `v' == .
}

// ---- Other fills ----
replace intercrop       = 0 if intercrop       == .
replace improved        = 0 if improved        == .
replace exten_channel   = 0 if exten_channel   == .
replace exten_frequency = 0 if exten_frequency == .
replace input           = 0 if input           == .

// ---- Log-transformed yield variables ----
gen ln_yield      = ln(pyield)       if pyield > 0
gen lnland_yield  = ln(pyield/parea) if pyield > 0 & parea > 0


/*============================================================================
  SECTION 4: CLIMATE DATA MERGE
  Merge EA-level gridded climate variables
============================================================================*/

* Expected climate variables:
*   hdd_32_che   : heat degree days > 32°C
*   gdd_10_32    : growing degree days 10–32°C
*   pr pr2       : precipitation and squared
*   ws ws2       : wind speed and squared
*   sr sr2       : solar radiation and squared

// ==========================================================================
// SECTION 5: VARIABLE ORDER AND FINAL SAVE
// ==========================================================================

order country year hhid indiv plotid ea ///
      parea female male female_hhead ///
      pyield maize_kg paddy_kg sorghum_kg beans_kg groundnut_kg ///
      labor_mday homelabor_mday hirelabor_mday ///
      input hh_machine_value ///
      inorganic_fertilizer inorganic_fertilizer_value_LCU ///
      organic_fertilizer used_pesticides seed_kg ///
      improved irrigated parcel_owner parcel_certified ///
      intercrop harvest_complete harvest_portion portion_planted ///
      joint_decision spouse_joint farm_size ///
      age sex marital married married_mono married_poly separated unmarried ///
      relation_hhead female_hhead ///
      lat lon ///
      ln_yield lnland_yield