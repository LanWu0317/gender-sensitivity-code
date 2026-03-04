/*==============================================================================
Uganda LSMS-ISA UNPS Wave 2 (2010/11) — Data Cleaning
==============================================================================*/

global raw  "D:\climate_gender\Uganda\UGA_2010_UNPS_v02_M_STATA12"
global yr    2010


/*============================================================================
  1. HOUSEHOLD ROSTER
============================================================================*/

use "$raw\GSEC2.dta", clear
keep HHID PID h2q3 h2q4
rename HHID           hhid
rename PID            indiv
rename h2q3           sex             // 0 = female, 1 = male
rename h2q4           relation_hhead  // 1=head, 2=spouse, 3=child, ...
g year = $yr

* Female household head
g sex_hhead = 1 - sex if relation_hhead == 1
bysort hhid year: egen female_hhead = max(sex_hhead)
drop sex_hhead

save "$out\hh_roster.dta", replace


/*============================================================================
  2. ENUMERATION AREA AND HOUSEHOLD WEIGHT
============================================================================*/

use "$raw\GSEC1.dta", clear
rename HHID hhid
g year = $yr

capture confirm variable comm
if _rc == 0 {
    rename comm ea_id
}
else {
    capture merge 1:1 hhid using ///
        "D:\气候与性别\Uganda\UGA_2009_UNPS\GSEC1.dta", ///
        keepusing(comm) keep(1 3) nogen
    capture rename comm ea_id
    if _rc != 0 {
        capture rename district ea_id
        if _rc != 0 rename region ea_id
        di "WARNING: EA (comm) not found — using region as proxy."
        di "         Verify path to 2009 GSEC1 for correct EA merge."
    }
}

keep hhid ea_id wgt10 year
save "$out\2010_ea_wgt.dta", replace


/*============================================================================
  3. PLOT AREA AND MANAGER
============================================================================*/

use "$raw\AGSEC2A.dta", clear
rename HHID  hhid
rename prcid plotid         // parcel = analysis-level plot unit
g year = $yr

* Plot area in hectares (GPS preferred; self-reported as fallback)
g parea = a2aq4 * 0.405
replace parea = a2aq5 * 0.405 if parea == .
bysort hhid year: egen farm_size = sum(parea)

* Primary plot manager individual ID
rename a2aq27a indiv

* Joint management: second manager listed implies joint decision
keep hhid plotid indiv a2aq27b year
save "joint_decision.dta"
g joint_decision = (a2aq27b != .)
merge m:1 hhid indiv using hh_roster_dup
drop if _merge == 2
drop _merge female_hhead sex
g spouse_joint = (relation_hhead1 == 2)

* Check whether second manager is the head's spouse
preserve
    use "$out\hh_roster.dta", clear
    rename indiv indiv2
    rename relation_hhead relation2
    keep hhid indiv2 relation2
    tempfile roster2
    save `roster2'
restore

rename a2aq27b indiv2
merge m:1 hhid indiv2 using `roster2', keep(1 3) nogen
replace spouse_joint = (relation2 == 2)   // relation2==2: spouse of head
replace spouse_joint = 0 if indiv2 == .
drop relation2 indiv2

keep hhid plotid indiv parea joint_decision spouse_joint year
save "$out\2010_plot.dta", replace


/*============================================================================
  4. INPUT COSTS AND LABOR
============================================================================*/

use "$raw\AGSEC3A.dta", clear
rename HHID  hhid
rename prcid plotid
g year = $yr

* --- Input costs (UGX) ---
egen input_cost = rowtotal(a3aq8 a3aq11 a3aq12 a3aq19 a3aq23 ///
                            a3aq24 a3aq31 a3aq35 a3aq36)

* --- Family labor (man-days) ---
g homelabor = a3aq38 * a3aq39

* --- Hired labor (man-days) ---
egen hirelabor = rowtotal(a3aq42a a3aq42b a3aq42c)

* --- Aggregate to parcel level (sum over sub-plots) ---
bysort hhid plotid:   egen input           = sum(input_cost)
bysort hhid plotid:   egen homelabor_mday  = sum(homelabor)
bysort hhid plotid:   egen hirelabor_mday  = sum(hirelabor)
bysort hhid year:     egen hh_input        = sum(input_cost)

keep hhid plotid input homelabor_mday hirelabor_mday hh_input year
egen labor_mday = rowtotal(homelabor_mday hirelabor_mday)
duplicates drop hhid plotid year, force
save "$out\2010_input.dta", replace


/*============================================================================
  5. CROP MANAGEMENT — INTERCROPPING, PLANTED AREA, SEEDS
============================================================================*/

use "$raw\AGSEC4A.dta", clear
rename HHID hhid
rename prcid plotid
g year = $yr

* Intercrop indicator (a4aq7: 1=pure stand, 2=intercropped)
recode a4aq7 (1=0)(2=1), gen(intercrop)
* Any sub-plot intercropped → parcel flagged as intercropped
bysort hhid plotid: egen intercrop_parcel = max(intercrop)
drop intercrop
rename intercrop_parcel intercrop

* Crop area in hectares
* Pure stand: 100% of area; intercrop: a4aq9 = share of plot (%)
replace a4aq9 = 100 if a4aq7 == 1
g area_ha = a4aq8 * (a4aq9 / 100) * 0.405
bysort hhid plotid cropID: egen crop_area_ha = sum(area_ha)

* Predominant crop by planted area
bysort hhid plotid: egen max_crop_ha = max(crop_area_ha)
gen main_crop_tmp = cropID if crop_area_ha == max_crop_ha & crop_area_ha != .
bysort hhid plotid: egen main_crop = max(main_crop_tmp)
drop main_crop_tmp max_crop_ha

* Total planted area per parcel
bysort hhid plotid: egen total_planted_ha = sum(crop_area_ha)

* Total seed value per parcel
bysort hhid plotid: egen plot_seed = sum(a4aq11)

* Crop name string (requires labeled cropID)
capture decode cropID, gen(cropname)

keep hhid plotid pltid cropID cropname intercrop crop_area_ha ///
     total_planted_ha plot_seed main_crop year
save "$out\2010_crop_seed.dta", replace


/*============================================================================
  6. CROP HARVEST, PRICES, AND PARCEL-LEVEL YIELD
============================================================================*/

use "$raw\AGSEC5A.dta", clear
rename HHID hhid
rename prcid plotid
g year = $yr

* Harvest quantity → kg
* a5aq6a = quantity harvested (local unit), a5aq6d = conversion factor to kg
g harvest_kg = a5aq6a * a5aq6d
replace harvest_kg = 0 if harvest_kg == .

* Sale quantity → kg and sale value
g sale_kg = a5aq7a * a5aq6d
rename a5aq8 sale_value

* Unit price from sellers
g price = sale_value / sale_kg
replace price = . if sale_kg == . | sale_kg == 0

* National mean crop price (UGX/kg)
bysort cropID year: egen crop_price = mean(price)
g harvest_value = harvest_kg * crop_price

* Parcel-level yield = sum over all sub-plots and crops on parcel
bysort hhid plotid: egen yield    = sum(harvest_value)
bysort hhid plotid: egen yield_kg = sum(harvest_kg)

* Crop-specific harvest kg (parcel level)
capture decode cropID, gen(cropname)
local crops "MAIZE SORGHUM BEANS CASSAVA GROUNDNUTS"
foreach crop of local crops {
    g `crop' = (cropname == "`crop'") * harvest_kg
    bysort hhid plotid year: egen `crop'_kg = sum(`crop')
    drop `crop'
}

* Reduce to one observation per parcel
duplicates drop hhid plotid year, force
drop if yield == 0 | yield == .

keep hhid plotid year yield yield_kg maize_kg sorghum_kg beans_kg ///
     cassava_kg groundnuts_kg
save "$out\2010_harvest_sale.dta", replace


/*============================================================================
  7. MACHINE AND EQUIPMENT VALUE
============================================================================*/

use "$raw\AGSEC10.dta", clear
rename HHID hhid
g year = $yr

* a10q2 = current value of owned equipment (UGX)
* a10q8 = annual rental payments for equipment (UGX)
replace a10q2 = 0 if a10q2 == .
replace a10q8 = 0 if a10q8 == .
g machine_value = a10q2 + a10q8

bysort hhid year: egen hh_machine_value = sum(machine_value)
keep hhid hh_machine_value year
duplicates drop hhid year, force
save "$out\2010_machine.dta", replace


/*============================================================================
  8. EXTENSION SERVICES
============================================================================*/

* --- Step A: Compute channel and frequency variables ---
use "$raw\AGSEC9.dta", clear
rename HHID hhid
g year = $yr

* Recode contact channel
foreach v in a9q5a a9q5b a9q5c a9q5d {
    capture replace `v' = 0 if `v' == 2
}
capture drop channel
capture egen channel = rowtotal(a9q5a a9q5b a9q5c a9q5d)

* Visit frequency
egen frequency = rowtotal(a9q6* a9q7)
save "$out\2010_extension.dta"

* --- Step B: Reshape to individual-level extension records ---
foreach suff in a b c d {
    use "$out\2010_extension.dta", clear
    capture confirm variable a9q4`suff'
    if _rc == 0 {
        keep hhid a9q4`suff' channel frequency year
        rename a9q4`suff' indiv
        drop if indiv == .
        bysort hhid indiv: egen exten_channel   = sum(channel)
        bysort hhid indiv: egen exten_frequency = sum(frequency)
        duplicates drop hhid indiv year, force
        keep hhid indiv year exten_channel exten_frequency
        save "$out\2010_extension_indiv`suff'.dta", replace
    }
}

* --- Step C: Combine into one individual-level extension file ---
use "$out\2010_extension_indiva.dta", clear
foreach suff in b c d {
    capture append using "$out\2010_extension_indiv`suff'.dta"
}
bysort hhid indiv year: keep if _n == 1    // deduplicate
save "$out\2010_extension_all.dta", replace


/*============================================================================
  9. INDIVIDUAL CHARACTERISTICS
============================================================================*/

use "$raw\GSEC2.dta", clear
rename HHID hhid
rename PID indiv
g year = $yr

rename h2q3  sex     // 0=female, 1=male
rename h2q8  age
rename h2q10 marital

gen married      = (marital <= 2 & marital != .)
gen married_mono = (marital == 1)
gen married_poly = (marital == 2)
gen separated    = (marital >= 3 & marital <= 4)
gen unmarried    = (marital == 5)

keep hhid indiv sex age marital married married_mono married_poly ///
     separated unmarried year
save "$out\2010_sex_age.dta", replace


/*============================================================================
  10. GEOGRAPHIC VARIABLES
============================================================================*/

use "$raw\UNPS_Geovars_1011.dta",clear
rename HHID hhid
g year = $yr
keep hhid lat_mod lon_mod year
save "$out\2010_geovars.dta", replace


/*============================================================================
  11. PLANTING SHARE INDICATOR
============================================================================*/

use "$out\2010_crop_seed.dta", clear

* Reduce to parcel level
duplicates drop hhid plotid year, force

merge m:1 hhid plotid year using "$out\2010_plot.dta", ///
    keep(1 3) nogen keepusing(parea)

* Definition of "partially planted":
* flag parcels where total planted area < 50% of GPS parcel area
g parea_threshold = parea * 0.5
g portion_planted = (total_planted_ha < parea_threshold & ///
                     total_planted_ha != . & parea != .)

keep hhid plotid portion_planted year
duplicates drop hhid plotid year, force
save "$out\planting_share.dta", replace


/*============================================================================
  12. FINAL MERGE
      Base: 2010_harvest_sale.dta  (one obs per parcel × year)
============================================================================*/

use "$out\2010_harvest_sale.dta", clear

* --- Plot-level merges ---
merge m:1 hhid plotid year using "$out\2010_plot.dta",    keep(1 3) nogen
merge m:1 hhid plotid year using "$out\2010_input.dta",   keep(1 3) nogen
merge m:1 hhid plotid year using "$out\planting_share.dta", keep(1 3) nogen

* Add intercrop and main_crop from crop management file
preserve
    use "$out\2010_crop_seed.dta", clear
    duplicates drop hhid plotid year, force
    keep hhid plotid year intercrop total_planted_ha plot_seed main_crop
    tempfile crop_mgmt
    save `crop_mgmt'
restore
merge m:1 hhid plotid year using `crop_mgmt', keep(1 3) nogen

* --- Household-level merges ---
merge m:1 hhid year using "$out\hh_roster.dta",    keep(1 3) nogen
merge m:1 hhid year using "$out\2010_ea_wgt.dta",  keep(1 3) nogen
merge m:1 hhid year using "$out\2010_machine.dta", keep(1 3) nogen

* --- Plot manager individual characteristics ---
merge m:1 hhid indiv year using "$out\2010_sex_age.dta",       keep(1 3) nogen
capture merge m:1 hhid indiv year using "$out\2010_extension_all.dta", ///
    keep(1 3) nogen

* --- Geographic variables ---
merge m:1 hhid year using "$out\2010_geovars.dta", keep(1 3) nogen


/*============================================================================
  13. VARIABLE CONSTRUCTION
============================================================================*/

* Female plot manager
gen female = (sex == 0) if sex != .
rename ea_id ea

* Log transformations for regression
gen lnyield  = ln(yield)                      if yield  > 0 & yield  != .
gen lnparea  = ln(parea)                      if parea  > 0 & parea  != .
gen lninput  = ln(input)
gen lnlabor  = ln(labor_mday)

drop if yield == . | yield == 0
drop if parea == . | parea == 0
drop if sex == .


/*============================================================================
  14. CLIMATE DATA MERGE
      Merge EA-level gridded climate variables
============================================================================*/

* Expected climate variables:
*   hdd_32_che   : heat degree days > 32°C
*   gdd_10_32    : growing degree days 10–32°C
*   pr pr2       : precipitation and squared
*   ws ws2       : wind speed and squared
*   sr sr2       : solar radiation and squared