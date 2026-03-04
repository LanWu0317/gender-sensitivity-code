/*==============================================================================
  Data cleaning for Mali EACI 2014 survey (MLI_2014_EACI_v03_M_STATA11)
==============================================================================*/

global raw  "D:/climate_gender/Mali/MLI_2014_EACI_v03_M_STATA11"
global mid  "D:/climate_gender/Mali"
global out  "D:/climate_gender/Sub-sahara"

*==============================================================================
* SECTION 1: Individual roster
*==============================================================================
use "$raw/EACIIND_p1.dta", clear

rename grappe  ea
rename menage  hhid
rename s01q00  indiv          // individual line number within household

// Sex: 1=male, 2=female  →  female dummy
rename s01q01  sex
gen    female  = sex - 1      // 0=male, 1=female
gen    male    = 1 - female

// Age in years
rename s01q02a age

// Relationship to household head (1=head, 2=spouse, 3=child, ...)
rename s01q04  relation_hhead

// Marital status
rename s01q09  marital
gen married      = (marital == 2 | marital == 3) if marital != .
gen married_mono = (marital == 2)                if marital != .
gen married_poly = (marital == 3)                if marital != .
gen separated    = (marital >= 4 & marital <= 6) if marital != .
gen unmarried    = (marital == 1)                if marital != .

// Female-headed household flag
gen sex_hhead = sex - 1 if relation_hhead == 1   // 1=female head, 0=male head
bysort ea hhid: egen female_hhead = max(sex_hhead)
drop sex_hhead

gen year = 2014

keep ea hhid indiv year sex female male age relation_hhead marital ///
     married married_mono married_poly separated unmarried female_hhead

save "$mid/2014_sex_age.dta", replace


*==============================================================================
* SECTION 2: Plot management
*==============================================================================
use "$raw/EACIEXPLOI_p1.dta", clear

rename grappe  ea
rename menage  hhid
rename s1bq00a plotid         // plot identifier

// Plot area in hectares
gen parea = s1bq05a           // GPS measured
replace parea = . if parea == 99
gen self_reported = s1bq10    // farmer-perceived
replace self_reported = . if self_reported == 99
replace parea = self_reported if parea == .
bysort ea hhid: egen farm_size = sum(parea)

// Main crop and Intercrop
rename s1bq08a main_crop
g intercrop = (s1cq05 == 2)
g count = 1
bysort ea hhid plotid: egen crop_type = sum(count)
bysort ea hhid plotid: egen main_area = max(s1cq06)
keep if main_area == s1cq06

// Distance from household residence to plot
rename s1bq12  dist_hh //km
replace dist_hh = . if dist_hh >= 90

// Primary plot manager
rename s1bq09  indiv
// If manager is missing or coded as non-member (90 or 0), use joint manager
replace indiv = s1bq35a if (indiv == 0  | indiv == .)
replace indiv = s1bq35a if  indiv == 90

// Joint decision making on this plot
g joint_decision = (s1bq34 == 1|s1bq34 == 2)
local var "b c d e f g"
foreach i of local var{
	replace s1bq35`i' = . if s1bq35`i' == 90
}
merge m:1 ea hhid indiv year using hh_roster
drop if _merge == 2
drop _merge female_hhead sex
forvalues i = 1/6{
	replace relation_hhead`i' = . if s1bq34 == 3
	replace relation_hhead`i' = . if s1bq34 == 9
}
g spouse_joint = (relation_hhead1 == 2|relation_hhead2 == 2|relation_hhead3 == 2|relation_hhead4 == 2|relation_hhead5 == 2|relation_hhead6 == 2)
keep ea hhid plotid year joint_decision spouse_joint

gen year = 2014
keep ea hhid plotid parea main_crop dist_hh indiv ///
     joint_decision intercrop farm_size year

save "$mid/2014_plot.dta", replace


*==============================================================================
* SECTION 3: Harvest and yield
*==============================================================================

//-------- Status of planting & harvesting --------
cd "D:\climate_gender\Mali\"
bysort ea hhid blocid year: egen plant_share = sum(crop_share)
replace plant_share = . if s1cq05 == 1
bysort ea hhid year: egen hh_plant_share = sum(crop_share)
replace hh_plant_share = . if s1cq05 == 1
g portion_planted = (plant_share < 100 & hh_plant_share < 100)
keep ea hhid plotid year portion_planted
duplicates drop ea hhid plotid year,force
save "planting_share_dup.dta"

keep grappe menage s3aq0 s3aq03a s3aq05 s3aq06
harvest_less = (s3aq05 == 2)
bysort ea hhid plotid: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1-harvest_complete
g harvest_percent = 100-s3aq06 //100-non yet harvested
bysort ea hhid plotid: egen harvest_portion = mean(harvest_percent)
keep ea hhid plotid harvest_complete harvest_portion
duplicates drop ea hhid plotid,force
g year = 2014

//-------- 3a. Annual crop harvest --------
use "$raw/EACIS3A_p2.dta", clear

rename grappe  ea
rename menage  hhid
rename s3aq01  plotid

// Crop identifiers
rename s3aq03a cropid         // numeric crop code
capture rename s3aq03b cropname_raw   // crop name string

// Harvest quantity
// s3aq08a=quantity, s3aq08b=unit, s3aq08c=equivalent kg after conversion
gen harvest_kg = .
replace harvest_kg = s3aq08c if s3aq08c != . & s3aq08c > 0
gen CF = s3aq08c/ s3aq08a
gen conversion = s3aq08c
gen unit = s3aq08b
bysort unit (CF) : replace conversion = CF if CF[1] == CF[_N] 
replace conversion = 1 if unit == 1
replace harvest_kg = s3aq08a * conversion if harvest == .
replace harvest_kg =. if s3aq08a == 9999

// Sold quantity
// same unit structure as seed
gen sale_kg = .
replace seed_kg = s3aq23c if s3aq23c != . & s3aq23c > 0
gen CF = s3aq23c/ s3aq23a
gen conversion = s3aq23c
gen unit = s3aq23b
bysort unit (CF) : replace conversion = CF if CF[1] == CF[_N] 
replace conversion = 1 if unit == 1
replace seed_kg = s3aq23a * conversion if seed == .
replace seed_kg =. if s3aq23a == 9999

// Sale value in FCFA
capture rename s3aq24  sale_value
if _rc != 0 capture rename s3aq24a sale_value
rename s3aq25a controller1
rename s3aq26a controller2
gen year = 2014
save "$mid/2014_harvest_crops.dta", replace


//-------- 3c. Compute crop prices and plot-level yield --------
use "$mid/2014_harvest_crops.dta", clear

// Price per kg: sale value / sale quantity
gen price = sale_value / sale_kg if sale_kg > 0 & sale_kg != .
bysort cropid year: egen crop_price = mean(price)

// Plot-level yield = sum of (harvest_kg × crop_price) across all crops on plot
gen harvest_value = harvest_kg * crop_price if harvest_kg != . & crop_price != .
bysort ea hhid plotid year: egen yield = sum(harvest_value)
drop harvest_value

// Aggregate total harvest kg per plot
bysort ea hhid plotid year: egen harvest_kg_plot = sum(harvest_kg)

// Retain one record per plot: keep row with highest-value crop as representative
bysort ea hhid plotid year (crop_price harvest_kg): keep if _n == _N

replace harvest_kg = harvest_kg_plot
drop harvest_kg_plot

// Crop name string for merge file
capture rename cropname_raw cropname
if _rc != 0 {
    capture decode cropid, gen(cropname)
    if _rc != 0 gen cropname = ""
}

keep ea hhid plotid cropid controller harvest_kg sale_kg sale_value ///
     price crop_price yield cropname year

save "$mid/2014_harvest.dta", replace
erase "$mid/2014_harvest_crops.dta"


*==============================================================================
* SECTION 4: Extension services
*==============================================================================
use "$raw/EACIINTRANT_p1.dta", clear

rename grappe  ea
rename menage  hhid
rename s2aq00  plotid

// Extension
//how many distinct sources/types of agricultural extension received?
gen exten_ch1 = (s2aq05 == 1)
capture gen exten_ch2 = (s2aq07 = 1)
capture gen exten_ch3 = (s2aq09 = 1)
capture gen exten_ch4 = (s2aq011 = 1)

gen exten_dummy = (exten_ch1|exten_ch2|exten_ch3|exten_ch4)
gen exten_channel = exten_ch1 + exten_ch2 + exten_ch3 + exten_ch4
drop exten_ch1 exten_ch2 exten_ch3
gen year = 2014

duplicates drop ea hhid plotid year, force
keep ea hhid plotid year exten_dummy exten_channel

save "$mid/2014_extension.dta", replace


*==============================================================================
* SECTION 5: Labor
*==============================================================================

//-------- 5a. Pre-harvest labor --------
use "$raw/EACIMAINOUVRE_p1.dta", clear

rename grappe  ea
rename menage  hhid
capture rename s2bq00 plotid

// Replace missing with 0 before multiplication
foreach v in s2bq05a s2bq05b s2bq05d s2bq05e s2bq05g s2bq05h ///
             s2bq07a s2bq07b s2bq07d s2bq07e s2bq07g s2bq07h ///
             s2bq09a s2bq09b s2bq09d s2bq09e s2bq09g s2bq09h {
    capture replace `v' = 0 if `v' == .
}

// Home (family) labor: persons × days
gen homelabor_mday = s2bq05a * s2bq05b + s2bq05d * s2bq05e + s2bq05g * s2bq05h

// Hired labor: persons × days
gen hirelabor_mday = s2bq07a * s2bq07b + s2bq07d * s2bq07e + s2bq07g * s2bq07h
gen labor_mday     = homelabor_mday + hirelabor_mday

gen year = 2014
keep ea hhid plotid year homelabor_pp hirelabor_pp
save "$mid/2014_labor_pp.dta", replace


*==============================================================================
* SECTION 6: Fertilizer inputs
*==============================================================================
use "$raw/EACIS2C_p2.dta", clear

rename grappe  ea
rename menage  hhid
capture rename s2cq00 plotid

// UREA (s2cq25a = qty, s2cq25b = unit)
gen urea_kg = .
replace urea_kg = s2cq25a         if s2cq25b == 1
replace urea_kg = s2cq25a * 50    if s2cq25b == 2
replace urea_kg = s2cq25a * 200   if s2cq25b == 3|s2cq25b == 4
replace urea_kg = 0               if urea_kg == .

// DAP (s2cq25c = qty, s2cq25d = unit)
gen dap_kg = .
replace dap_kg = s2cq25c          if s2cq25d == 1
replace dap_kg = s2cq25c * 50     if s2cq25d == 2
replace dap_kg = s2cq25c * 200    if s2cq25d == 3|s2cq25b == 4
replace dap_kg = 0                if dap_kg == .

// NPK (s2cq25e = qty, s2cq25f = unit)
gen npk_kg = .
replace npk_kg = s2cq25e          if s2cq25f == 1
replace npk_kg = s2cq25e * 50     if s2cq25f == 2
replace npk_kg = s2cq25e * 200    if s2cq25f == 3|s2cq25b == 4
replace npk_kg = 0                if npk_kg == .

// Other fertilizer (s2cq25g = qty, s2cq25h = unit)
gen other_kg = .
replace other_kg = s2cq25g        if s2cq25h == 1
replace other_kg = s2cq25g * 50   if s2cq25h == 2
replace other_kg = s2cq25g * 200  if s2cq25h == 3|s2cq25b == 4
replace other_kg = 0              if other_kg == .

// Convert to nitrogen-equivalent kg
gen fertilizer_1 = urea_kg  * 0.46   // UREA: 46% N
gen fertilizer_2 = dap_kg   * 0.18   // DAP:  18% N
gen fertilizer_3 = npk_kg   * 0.20   // NPK:  20% N (common compound)
gen fertilizer_4 = other_kg * 0.15   // Other: N-content assumption
gen fertilizer_kg = fertilizer_1 + fertilizer_2 + fertilizer_3 + fertilizer_4
gen year = 2014

// HH-level aggregate input
use "$raw/EACIS2D_p2.dta", clear
bysort ea hhid year: egen hh_input = sum(s2dq09c)

keep ea hhid plotid year fertilizer_1 fertilizer_2 fertilizer_3 fertilizer_4 ///
     fertilizer_kg hh_input
save "$mid/2014_input.dta", replace


*==============================================================================
* SECTION 7: Seeds
*==============================================================================

use "$raw/EACICULTURE_p1.dta"", clear

rename grappe  ea
rename menage  hhid
capture rename s2cq00 plotid

gen improved = 1 if s1cq09 >= 2 & s1cq09 <= 5
replace improved = 0 if s1cq09 == 1

gen seed_kg_temp = s1cq10a if s1cq10b==2
replace seed_kg_temp = . if seed_kg_temp>=9999 | seed_kg_temp>=999 & seed_kg_temp<1000
gen seed_gram= s1cq10a * 0.001 if s1cq10b==1  
egen seed_kg = rowtotal(seed_kg_temp seed_gram), missing

use "$raw/EACIS1E_p2.dta", clear

rename grappe  ea
rename menage  hhid

replace seed_kg = s1eq05a if seed_kg==.
replace seed_kg = s1eq05a * 0.001 if s1eq05b==1
replace seed_kg =. if seed_kg>=9999

gen year = 2014
bysort ea hhid plotid year: egen seed_kg_plot = sum(seed_kg)
duplicates drop ea hhid plotid year, force
drop seed_kg
rename seed_kg_plot seed_kg
keep ea hhid plotid year seed_kg
save "$mid/2014_seed.dta", replace


*==============================================================================
* SECTION 8: Machinery and household agricultural assets
*==============================================================================
use "$raw/EACIS5_p2.dta", clear

rename grappe  ea
rename menage  hhid

// Machinery owned: qty × unit value
gen machine_own_cost = as05q03 * as05q05
bysort ea hhid year: egen hh_machine_value  = sum(machine_own_cost)

gen year = 2014
replace hh_machine_value = 0 if hh_machine_value == .
duplicates drop ea hhid year, force
keep ea hhid year hh_machine_value
save "$mid/2014_machine.dta", replace


*==============================================================================
* SECTION 9: Final merge, climate data, analytical variables, save
*==============================================================================

//-------- Base dataset: harvest (plot × dominant-crop level) --------
use "$mid/2014_harvest.dta", clear

//-------- Merge plot management info --------
merge m:1 ea hhid plotid year using "$mid/2014_plot.dta", ///
    keep(1 3) nogenerate

//-------- Merge individual characteristics (plot manager) --------
merge m:1 ea hhid indiv year using "$mid/2014_sex_age.dta", ///
    keep(1 3) nogenerate

//-------- Female-headed household: fill from HH-level merge --------
// female_hhead was already merged through sex_age; confirm for non-matched
merge m:1 ea hhid using "$mid/2014_sex_age.dta", ///
    keepusing(female_hhead) update keep(1 3 4 5) nogenerate force

//-------- Spouse joint management flag --------
// spouse_joint = 1 if any of the joint managers (s1bq35a-g) is the spouse
merge m:1 ea hhid year using "$mid/2014_sex_age.dta", ///
    keepusing(indiv relation_hhead) keep(1 3 4 5) ///
    nogenerate force

//-------- Extension --------
merge m:1 ea hhid plotid year using "$mid/2014_extension.dta", ///
    keep(1 3) nogenerate
replace exten_channel = 0 if exten_channel == .

//-------- Labor --------
merge 1:1 ea hhid plotid year using "$mid/2014_labor.dta", ///
    keep(1 3) nogenerate
foreach v in homelabor_mday hirelabor_mday labor_mday {
    replace `v' = 0 if `v' == .
}

//-------- Fertilizer inputs --------
merge 1:1 ea hhid plotid year using "$mid/2014_input.dta", ///
    keepusing(fertilizer_kg hh_input) keep(1 3) nogenerate
replace fertilizer_kg = 0 if fertilizer_kg == .
replace hh_input      = 0 if hh_input      == .

//-------- Seeds --------
merge 1:1 ea hhid plotid year using "$mid/2014_seed.dta", ///
    keep(1 3) nogenerate
replace seed_kg = 0 if seed_kg == .

//-------- Machinery --------
merge m:1 ea hhid year using "$mid/2014_machine.dta", ///
    keep(1 3) nogenerate
replace hh_machine_value = 0 if hh_machine_value == .

//-------- Administrative geography --------
merge m:1 ea hhid year using "$mid/2014_admin.dta", ///
    keep(1 3) nogenerate

//-------- Climate data — primary (hdd_30 / gdd_10_30) --------
// Source: hdd_ssa.dta (ea × year level)
merge m:1 ea year using "$mid/hdd_ssa.dta", ///
    keep(1 3) nogenerate

//-------- Climate data — extended (hdd_32 / gdd_10_32 + weather controls) --------
preserve
import delimited "$mid/2014_ssa1.csv", varnames(1) clear case(lower)
// Standardise to lowercase column names (already done with case(lower))
// Expected columns: ea year gdd_10_31 hdd_31 gdd_10_32 hdd_32
//                   prec d2m sp sr t2m u10 v10 (wind speed u/v-component)
save "$mid/2014_ssa1_temp.dta", replace
restore

merge m:1 ea year using "$mid/2014_ssa1_temp.dta", ///
    keep(1 3) nogenerate

capture gen ws = sqrt(ws_u^2 + ws_v^2)
capture gen pr2 = pr^2 // precipitation
capture gen sr2 = sr^2 // solar radiation
capture gen ws2 = ws^2 // wind speed

* sp: surface pressure
* d2m: dew point

//-------- Sample restrictions --------
// Keep only main-season annual crop plots with valid core variables
drop if yield    == . | yield    <= 0
drop if parea    == . | parea    <= 0
drop if indiv    == . | indiv   == 0 | indiv == 90
gen lnland_yield = ln(yield / parea) if yield > 0 & parea > 0 & parea != .

order ea hhid plotid parea main_crop indiv year dist_hh ///
      s0aq01 s0aq02 s0aq03 s0aq04 cropname intercrop exten_channel ///
      harvest_kg controller controller1 yield fertilizer_kg hh_input ///
      homelabor_mday hirelabor_mday labor_mday hh_machine_value seed_kg ///
      sex female male age marital married married_mono married_poly ///
      separated unmarried country exrate gdd_10_30 hdd_30 ///
      relation_hhead female_hhead joint_decision spouse_joint