/*==============================================================================
  Ethiopia ESS Data Cleaning — Waves 1/2/3 (2011, 2013, 2015)
  Unit:   Parcel × year (a parcel = holder_id × parcel_id, main season only)
==============================================================================*/

global root    "D:\climate_gender\Ethiopia"
global survey  "${root}\Ethiopia_Survey_Data"
global w1      "${survey}\ETH_2011_ESS_v02_M_Stata8"
global w2      "${survey}\ETH_2013_ESS_v03_M_STATA"
global w3pp    "${survey}\ETH_2015_ESS_v03_M_STATA\Post-Planting"
global w3ph    "${survey}\ETH_2015_ESS_v03_M_STATA\Post-Harvest"
global w3hh    "${survey}\ETH_2015_ESS_v03_M_STATA\Household"
global w3geo   "${survey}\ETH_2015_ESS_v03_M_STATA\Geovariables"
global w3ls    "${survey}\ETH_2015_ESS_v03_M_STATA\Livestock"
global w3cf    "${survey}\ETH_2015_ESS_v03_M_STATA\Food and Crop Conversion Factors"
global w3land  "${survey}\ETH_2015_ESS_v03_M_STATA\Land Area Conversion Factor"
global w3root  "${survey}\ETH_2015_ESS_v03_M_STATA"

global clim    "${root}"               // HDD/GDD/weather_control.dta files live here
global tmp     "${root}\tmp_cleaning"  // temp files during cleaning
cap mkdir "${tmp}"


/*==============================================================================
  SECTION 1 — WAVE 1 (2011)
==============================================================================*/

*------------------------------------------------------------------------------
* 1A. Harvest quantities and crop prices
*------------------------------------------------------------------------------

** -- Harvest quantities --
use "${w1}/sect9_ph_w1.dta", clear
//Harvests have been converted into kg/gram
gen harvest_gram = ph_s9q12_b * 0.001
egen harvest_kg  = rowtotal(ph_s9q12_a harvest_gram), missing
recode ph_s9q07 (1=1)(2=0), gen(crop_shock)
replace crop_shock = 1 if ph_s9q09 == 1
replace harvest_kg = . if harvest_kg == 0 & crop_shock != 1

// Crop shocks (drought, pests, flood)
recode ph_s9q08_a (1=1)(2/6 8/999=0), gen(drought_s1)
recode ph_s9q08_b (1=1)(2/6 8/999=0), gen(drought_s2)
recode ph_s9q10  (2=1)(1 3/100=0),    gen(drought_s3)
foreach s in 1 2 3 { replace drought_s`s' = 0 if ph_s9q07 == 2 }
gen drought_shock = (drought_s1==1 | drought_s2==1 | drought_s3==1)
replace drought_shock = . if drought_s1==. & drought_s2==. & drought_s3==.

recode ph_s9q08_a (4=1)(1/3 5/6 8/999=0), gen(pests_s1)
recode ph_s9q08_b (4=1)(1/3 5/6 8/999=0), gen(pests_s2)
recode ph_s9q10  (3 10=1)(1 2 4/9 11/100=0), gen(pests_s3)
foreach s in 1 2 3 { replace pests_s`s' = 0 if ph_s9q07 == 2 }
gen pests_shock = (pests_s1==1 | pests_s2==1 | pests_s3==1)

recode ph_s9q10 (7=1)(1/6 8/999=0), gen(flood_shock)
replace flood_shock = 0 if ph_s9q09 == 2

keep household_id holder_id parcel_id field_id crop_code ///
     harvest_kg crop_shock drought_shock pests_shock flood_shock
save "${tmp}/w1_harvest_kg.dta", replace

** -- Crop sale prices (to value harvest) --
use "${w1}/sect11_ph_w1.dta", clear
replace ph_s11q03_b = ph_s11q03_b / 1000
replace ph_s11q04_b = ph_s11q04_b / 1000
replace ph_s11q03_b = . if ph_s11q03_a == .
replace ph_s11q04_b = . if ph_s11q04_a == .
egen quan_sold  = rowtotal(ph_s11q03_a ph_s11q03_b), missing
egen value_sold = rowtotal(ph_s11q04_a ph_s11q04_b), missing
gen  price = value_sold / quan_sold if quan_sold > 0

bysort crop_code: egen crop_price_w1 = mean(price)

keep household_id holder_id crop_code crop_price_w1
duplicates drop household_id holder_id crop_code, force
save "${tmp}/w1_crop_price.dta", replace

** -- Parcel-level yields --
use "${tmp}/w1_harvest_kg.dta", clear
merge m:1 household_id holder_id crop_code using "${tmp}/w1_crop_price.dta", nogen keep(master match)
gen crop_value = crop_price_w1 * harvest_kg

// Aggregate to parcel level (sum across fields and crops)
bysort household_id holder_id parcel_id: egen pyield = total(crop_value)
bysort household_id holder_id parcel_id: gen n_crops = _N
bysort household_id holder_id parcel_id: gen intercrop = (n_crops > 1)

keep household_id holder_id parcel_id pyield intercrop crop_diversity main_crop ///
     crop_shock drought_shock pests_shock flood_shock
duplicates drop household_id holder_id parcel_id, force
save "${tmp}/w1_yield.dta", replace

// Harvested share (status)
keep holder_id household_id ea_id parcel_id field_id crop_code ph_s9q06
g harvest_less = (ph_s9q06 == 1) //crop used before harvest
bysort ea_id household_id holder_id parcel_id: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1-harvest_complete
duplicates drop ea_id household_id holder_id parcel_id,force
keep ea_id household_id holder_id parcel_id harvest_complete
g year = 2011


*------------------------------------------------------------------------------
* 1B. Plot area
*------------------------------------------------------------------------------

use "${w1}/sect3_pp_w1.dta", clear
rename saq01 region
rename saq02 zone_code
rename saq03 woreda
rename pp_s3q02_c local_unit

merge m:1 region zone_code woreda local_unit ///
    using "${w1}/ET_local_area_unit_conversion.dta", nogen keep(master match)

gen area_GPS           = pp_s3q05_a * 0.0001             
gen area_rope_compass  = pp_s3q08_b * 0.0001             
gen area_self_reported = pp_s3q02_a * conversion          
replace area_self_reported = pp_s3q02_a          if local_unit == 1  
replace area_self_reported = pp_s3q02_a          if local_unit == 2  
replace area_self_reported = area_self_reported  * 0.0001             

gen field_area = area_GPS
replace field_area = area_rope_compass if missing(field_area) & !missing(area_rope_compass)
replace field_area = area_self_reported if missing(field_area) & !missing(area_self_reported)

// Aggregate to parcel level
bysort household_id holder_id parcel_id: egen parea = total(field_area)
bysort household_id: egen farm_size = sum(parea)
keep household_id holder_id parcel_id field_id parea farm_size field_area ///
     pp_s3q12 pp_s3q32   // irrigation flag, erosion protection
duplicates drop household_id holder_id parcel_id field_id, force

// Parcel-level flags: irrigated field share, erosion protection
recode pp_s3q12 (1=1)(2=0), gen(irrigated_field)
recode pp_s3q32 (2=1)(1=0), gen(erosion_field)
bysort household_id holder_id parcel_id: egen iarea     = total(cond(irrigated_field==1, field_area, 0))
bysort household_id holder_id parcel_id: egen erosion_protection = max(erosion_field)
gen irrigation_rate = iarea / parea

duplicates drop household_id holder_id parcel_id, force
keep household_id holder_id parcel_id parea iarea irrigation_rate erosion_protection
save "${tmp}/w1_area.dta", replace

// Planted share (status)
append using 2013_crop_area 2015_crop_area
bysort holder_id parcel_id field_id year: egen plant_share = sum(pp_s4q03)
replace plant_share = . if pp_s4q02 == 1 //self-reported share
g field_portion = (plant_share < 100 & plant_share != .)
bysort holder_id parcel_id year: egen portion_planted = max(field_portion)
keep household_id holder_id parcel_id year portion_planted
duplicates drop holder_id parcel_id year,force
save "planting_share_dup.dta"


*------------------------------------------------------------------------------
* 1C. Labor
*------------------------------------------------------------------------------

** -- Post-planting family labor --
use "${w1}/sect3_pp_w1.dta", clear
local alet "b f j n r v"
local blet "c g k o s w"
local clet "a e i m q u"
forvalues n = 1/6 {
    local a: word `n' of `alet'
    local b: word `n' of `blet'
    local c: word `n' of `clet'
    gen weeks`n'     = pp_s3q27_`a'
    gen daysperweek`n' = pp_s3q27_`b'
    replace weeks`n'      = 0 if pp_s3q27_`c' == 0
    replace daysperweek`n' = 0 if pp_s3q27_`c' == 0
    gen fam_days_pp`n' = weeks`n' * daysperweek`n'
}
egen PPfam_days = rowtotal(fam_days_pp*), missing

// Post-planting hired labor
gen PP_hired_man   = pp_s3q28_a * pp_s3q28_b
gen PP_hired_woman = pp_s3q28_d * pp_s3q28_e
gen PP_hired_child = pp_s3q28_g * pp_s3q28_h
foreach v in PP_hired_man PP_hired_woman PP_hired_child {
    replace `v' = 0 if missing(`v')
}
egen PPhire_days = rowtotal(PP_hired_man PP_hired_woman PP_hired_child), missing

bysort household_id holder_id parcel_id: egen homelabor  = total(PPfam_days),  missing
bysort household_id holder_id parcel_id: egen hirelabor = total(PPhire_days), missing
gen labor_mday = rowtotal(homelabor hirelabor)

duplicates drop household_id holder_id parcel_id, force
keep household_id holder_id parcel_id labor_mday homelabor hirelabor
save "${tmp}/w1_labor_pp.dta", replace


*------------------------------------------------------------------------------
* 1D. Material inputs: fertilizer and seeds
*------------------------------------------------------------------------------

** -- Fertilizer cost (UREA + DAP valued at median price) --
use "${w1}/sect3_pp_w1.dta", clear
recode pp_s3q15 (1=1)(2=0), gen(used_UREA)
recode pp_s3q18 (1=1)(2=0), gen(used_DAP)
gen UREA_kg = pp_s3q16_c
gen DAP_kg  = pp_s3q19_c
replace UREA_kg = 0 if used_UREA == 0
replace DAP_kg  = 0 if used_DAP  == 0

// Median prices (~12.6 birr/kg UREA, ~15.5 birr/kg DAP)
gen UREA_price = pp_s3q16_d / pp_s3q16_c if pp_s3q16_c > 0
gen DAP_price  = pp_s3q19_d / pp_s3q19_c if pp_s3q19_c > 0
quietly su UREA_price, detail
local urea_med = r(p50)
quietly su DAP_price,  detail
local dap_med  = r(p50)
gen ffertilizer = UREA_kg * `urea_med' + DAP_kg * `dap_med'
replace ffertilizer = 0 if missing(ffertilizer) & (used_UREA==0 & used_DAP==0)

bysort household_id holder_id parcel_id: egen pfertilizer = total(ffertilizer), missing
duplicates drop household_id holder_id parcel_id, force
keep household_id holder_id parcel_id pfertilizer
save "${tmp}/w1_fertilizer.dta", replace

** -- Seeds: quantity purchased and valued at median price --
use "${w1}/sect5_pp_w1.dta", clear
gen seed_gram = pp_s5q19_b * 0.001
egen seed_kg  = rowtotal(pp_s5q19_a seed_gram), missing

gen seed_purch_gram = pp_s5q05_b * 0.001
egen seed_purch_kg  = rowtotal(pp_s5q05_a seed_purch_gram), missing
replace seed_purch_kg = 0 if pp_s5q03 == 2   // not purchased

gen seed_value_unit = pp_s5q08 / seed_purch_kg if seed_purch_kg > 0
bysort crop_code: egen crop_seed_price = median(seed_value_unit)
gen seed_cost = seed_kg * crop_seed_price

bysort household_id holder_id parcel_id: egen pseed = total(seed_cost), missing
duplicates drop household_id holder_id parcel_id, force
keep household_id holder_id parcel_id pseed
save "${tmp}/w1_seeds.dta", replace


*------------------------------------------------------------------------------
* 1E. Plot geovariables and characteristics
*------------------------------------------------------------------------------

use "${w1}/Pub_ETH_PlotGeovariables_Y1.dta", clear
rename plot_srtmslp plot_slope
rename dist_household dist_hh_plot
rename plot_srtm     plot_elev
rename plot_twi      plot_wet

// Aggregate to parcel level
bysort holder_id parcel_id: egen dist_hh    = mean(dist_hh_plot)
bysort holder_id parcel_id: egen plot_slope_p = mean(plot_slope)
bysort holder_id parcel_id: egen plot_elev_p  = mean(plot_elev)
bysort holder_id parcel_id: egen plot_wet_p   = mean(plot_wet)

duplicates drop holder_id parcel_id, force
rename plot_slope_p plot_slope
rename plot_elev_p  plot_elev
rename plot_wet_p   plot_wet
keep holder_id parcel_id dist_hh plot_slope plot_elev plot_wet
save "${tmp}/w1_plotgeo.dta", replace


*------------------------------------------------------------------------------
* 1F. Improved seeds
*------------------------------------------------------------------------------

use "${w1}/sect4_pp_w1.dta", clear
cap recode pp_s4q11 (1 3=0)(2=1), gen(improved)
if _rc != 0 gen improved = .    // mark as unknown if variable absent
bysort household_id holder_id parcel_id: egen improved_p = max(improved)
duplicates drop household_id holder_id parcel_id, force
rename improved_p improved
keep household_id holder_id parcel_id improved
save "${tmp}/w1_improved.dta", replace


*------------------------------------------------------------------------------
* 1G. Manager gender and individual characteristics
*------------------------------------------------------------------------------

// The plot holder/manager comes from the post-planting cover sheet
use "${w1}/sect1_pp_w1.dta", clear
rename pp_saq07 manager_member_id
keep household_id holder_id manager_member_id
duplicates drop household_id holder_id, force

// Merge with household roster to get gender, age, marital status, religion
merge m:1 household_id using "${w1}/sect1_hh_w1.dta", keep(master match) nogen
keep if hh_s1q00 == manager_member_id | missing(manager_member_id)

recode hh_s1q03 (2=1 "Female")(1=0 "Male"), gen(female)
rename hh_s1q04_a age
gen married      = inrange(hh_s1q08, 2, 3)
gen married_poly = (hh_s1q08 == 3)
gen separated    = inrange(hh_s1q08, 4, 6)
gen unmarried    = (hh_s1q08 == 1)

cap rename hh_s1q07 religion
if _rc != 0 gen religion = .

keep household_id holder_id female age married married_poly separated unmarried religion
duplicates drop household_id holder_id, force
save "${tmp}/w1_manager.dta", replace

** -- Education (sect2_hh_w1) --
use "${w1}/sect2_hh_w1.dta", clear
recode hh_s2q05 ///
    (0 98 1/3 93/96 4/7 = 0) ///
    (8/35              = 1), gen(edu_primary)
replace edu_primary = 0 if hh_s2q03 == 2   // never attended
keep household_id hh_s2q00 edu_primary
rename hh_s2q00 manager_member_id
duplicates drop household_id manager_member_id, force
save "${tmp}/w1_education.dta", replace


*------------------------------------------------------------------------------
* 1H. Household-level characteristics
*------------------------------------------------------------------------------

** -- Female household head --
use "${w1}/sect1_hh_w1.dta", clear
gen is_head   = (hh_s1q02 == 1)
recode hh_s1q03 (2=1)(1=0), gen(female_temp)
gen female_head_temp = female_temp if is_head == 1
bysort household_id: egen female_hhead = max(female_head_temp)
keep household_id female_hhead
duplicates drop household_id, force
save "${tmp}/w1_femhead.dta", replace

** -- Dependency ratio --
use "${w1}/sect1_hh_w1.dta", clear
rename hh_s1q04_a age
gen dep_temp    = !inrange(age, 15, 65) & !missing(age)
gen nondep_temp = inrange(age, 15, 65)  & !missing(age)
bysort household_id: egen dep    = total(dep_temp)
bysort household_id: egen nondep = total(nondep_temp)
gen dependency_ratio = dep / nondep
replace dependency_ratio = dep if nondep == 0
collapse (max) dependency_ratio, by(household_id)
save "${tmp}/w1_dependency.dta", replace

** -- Household size and electricity --
use "${w1}/sect9_hh_w1.dta", clear
recode hh_s9q19 (1/4=1)(5/13=0), gen(electricity_access)
keep household_id electricity_access
duplicates drop household_id, force
save "${tmp}/w1_elec.dta", replace

use "${w1}/sect_cover_hh_w1.dta", clear
gen home_size = hh_saq09
keep household_id home_size
duplicates drop household_id, force
save "${tmp}/w1_homesize.dta", replace

** -- Livestock --
use "${w1}/sect_cover_pp_w1.dta", clear
recode pp_saq13 (2 3=1)(1=0), gen(livestock)
keep holder_id livestock
duplicates drop holder_id, force
save "${tmp}/w1_livestock.dta", replace

** -- Fallow plots --
use "${w1}/sect3_pp_w1.dta", clear
recode pp_s3q03 (3=1)(.*=0)(.=.), gen(fallow_plot)
bysort household_id: egen fallow_plots = total(fallow_plot), missing
keep household_id fallow_plots
duplicates drop household_id, force
save "${tmp}/w1_fallow.dta", replace

** -- Nonfarm work --
use "${w1}/sect4_hh_w1.dta", clear
recode hh_s4q07 (0=0)(.=.)(else=1), gen(wage_work)
bysort household_id: egen nonfarm_work = max(wage_work)

gen ind_ag = hh_s4q11_b == 1  // agriculture 
gen ind_fish = hh_s4q11_b == 2	// fishing
gen ind_mining = hh_s4q11_b == 3	// mining
gen ind_manuf = hh_s4q11_b == 4 | hh_s4q11_b == 5	// manuf
gen ind_const = hh_s4q11_b == 6	// construction
gen ind_serv = hh_s4q11_b >= 7 & hh_s4q11_b<= 18	// service
foreach var in ind_ag ind_const ind_fish ind_manuf ind_mining ind_serv {
	replace `var' = 0 if hh_s4q09==2 | hh_s4q09==.
	replace nonfarm_work = 1 if `var' == 1
}

keep household_id nonfarm_work
duplicates drop household_id, force
save "${tmp}/w1_nonfarm.dta", replace

** -- Joint decision-making (2011 missing-use 2013 status) --
keep holder_id parcel_id field_id pp_s3q10a pp_s3q10b pp_s3q10c_a pp_s3q10c_b

g holder = substr(holder_id,15,2)
destring holder, replace
g field_joint = (pp_s3q10b == 1)
replace field_joint = 1 if pp_s3q10b == 2 & holder != pp_s3q10a
merge m:1 household_id indiv year using hh_roster
drop if _merge == 2
drop _merge female_hhead sex
replace relation_hhead = . if indiv == holder
g field_spouse = (relation_hhead1 == 2|relation_hhead2 == 2|relation_hhead3 == 2)
bysort household_id holder parcel_id year: egen joint_decision = max(field_joint)
bysort household_id holder parcel_id year: egen spouse_joint = max(field_spouse)
keep household_id parcel_id year holder joint_decision spouse_joint
duplicates drop household_id parcel_id year holder,force
save "${tmp}/w1_jointdec.dta", replace   // placeholder

** -- Extension service --
use "${w1}/sect7_pp_w1.dta", clear
foreach v of varlist pp_s7q04 pp_s7q06 pp_s7q08 {
    recode `v' (1=1)(2 .=0), gen(`v'_d)
}
rename pp_s7q04 exten_program
rename pp_s7q06 exten_credit
rename pp_s7q08 exten_advising
egen exten_dummy = (exten_program|exten_credit|exten_advising)
egen exten_channel = rowtotal(exten_program exten_credit exten_advising)
keep household_id holder_id exten_*
duplicates drop household_id holder_id, force
save "${tmp}/w1_extension.dta", replace

** -- Control over revenue (financial autonomy) --
use "${w1}/sect11_ph_w1.dta", clear
rename ph_s11q05_a controller1 
ph_s11q05_b controller2
keep household_id holder_id crop_code controller*
save "${tmp}/w1_market_control.dta", replace //merge managerID

** -- Land ownership (parcel owner) --
use "${w1}/sect2_pp_w1.dta", clear
recode pp_s2q03 (1 2=1)(3/12=0), gen(parcel_owner)
keep holder_id parcel_id parcel_owner
duplicates drop holder_id parcel_id, force
save "${tmp}/w1_parcelowner.dta", replace

** -- Farm machinery --
use "${w1}/sect10_hh_w1.dta", clear
keep if hh_s10q00 >= 18 & hh_s10q00 <= 34
drop if inrange(hh_s10q00, 19, 32)
bysort household_id: egen machine_num = total(hh_s10q01)
keep household_id machine_num
duplicates drop household_id, force
save "${tmp}/w1_machine.dta", replace

** -- Soil quality --
use "${w1}/Pub_ETH_HouseholdGeovariables_Y1.dta", clear
forvalues i = 1/7 {
    recode sq`i' (1=1)(2/7=0), gen(sq`i'_d)
}
pca sq1_d-sq7_d
predict soil_fertility_pca, score
local names "nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability"
forvalues n = 1/7 {
    local lab: word `n' of `names'
    rename sq`n'_d `lab'
}
rename srtm elevation
keep household_id soil_fertility_pca `names' elevation
duplicates drop household_id, force
save "${tmp}/w1_soil.dta", replace

** -- EA id harmonisation --
use "${w1}/sect_cover_hh_w1.dta", clear
merge 1:m household_id using "${w2}/sect_cover_hh_w2.dta", ///
    keepusing(ea_id2) keep(match master) nogen
bys ea_id (ea_id2): replace ea_id2 = ea_id2[_N] if ea_id2 == ""
drop ea_id
rename ea_id2 ea_id
// Zone: from saq01 (region) and saq02 (zone)
gen zone = string(saq01) + "_" + string(saq02)
keep household_id ea_id zone
duplicates drop household_id, force
save "${tmp}/w1_ea.dta", replace


*------------------------------------------------------------------------------
* 1I. Assemble wave 1 parcel-level dataset
*------------------------------------------------------------------------------

use "${tmp}/w1_yield.dta", clear
merge 1:1 household_id holder_id parcel_id using "${tmp}/w1_area.dta",       nogen keep(master match)
merge 1:1 holder_id parcel_id             using "${tmp}/w1_plotgeo.dta",     nogen keep(master match)
merge 1:1 household_id holder_id parcel_id using "${tmp}/w1_labor.dta",      nogen keep(master match)
merge 1:1 household_id holder_id parcel_id using "${tmp}/w1_fertilizer.dta", nogen keep(master match)
merge 1:1 household_id holder_id parcel_id using "${tmp}/w1_seeds.dta",      nogen keep(master match)
merge 1:1 household_id holder_id parcel_id using "${tmp}/w1_improved.dta",   nogen keep(master match)
merge m:1 household_id holder_id            using "${tmp}/w1_manager.dta",   nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_femhead.dta",   nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_dependency.dta",nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_elec.dta",      nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_homesize.dta",  nogen keep(master match)
merge m:1 holder_id                         using "${tmp}/w1_livestock.dta", nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_fallow.dta",    nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_nonfarm.dta",   nogen keep(master match)
merge m:1 household_id holder_id            using "${tmp}/w1_extension.dta", nogen keep(master match)
merge m:1 household_id holder_id            using "${tmp}/w1_market_control.dta", nogen keep(master match)
merge m:1 holder_id parcel_id               using "${tmp}/w1_parcelowner.dta", nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_machine.dta",   nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_soil.dta",      nogen keep(master match)
merge m:1 household_id                      using "${tmp}/w1_ea.dta",        nogen keep(master match)

// Education: merge using manager_member_id
merge m:1 household_id holder_id using "${tmp}/w1_manager.dta", keepusing(manager_member_id) nogen
merge m:1 household_id manager_member_id using "${tmp}/w1_education.dta", nogen keep(master match)
gen year = 2011
save "${tmp}/wave1_parcel.dta", replace


/*==============================================================================
  SECTION 2 and 3 — WAVE 2 and 3 (2013 - 2015)
  Variable structure mirrors Wave 1 but file suffix is _w2 and _w3
==============================================================================*/

// EA id (wave 2)
use "${w2}/sect_cover_hh_w2.dta", clear
replace household_id2 = substr(household_id2,1,6) + substr(household_id2,11,8) if length(household_id2) > 14
replace ea_id2        = substr(ea_id2,1,6)         + substr(ea_id2,11,5)        if length(ea_id2) > 11
rename ea_id2 ea_id
rename household_id2 household_id
gen zone = string(saq01) + "_" + string(saq02)
keep household_id ea_id zone
duplicates drop household_id, force
save "${tmp}/w2_ea.dta", replace

// EA id (wave 3)
use "${w3hh}/sect_cover_hh_w3.dta", clear
gen zone = string(saq01) + "_" + string(saq02)
keep household_id ea_id zone
duplicates drop household_id, force
save "${tmp}/w3_ea.dta", replace

//Harvested share (status)
keep holder_id household_id2 ea_id2 parcel_id field_id crop_code ph_s9q06* ph_s9q08 ph_s9q09 ph_s9q10_a ph_s9q10_a_other ph_s9q10_b
g harvest_less = (ph_s9q06_other == "CROP CUT IS NOT COMPLETED"|ph_s9q06_other == "NOT HARVESTED"|ph_s9q06_other == "NOT YET READY FOR HARVEST")
replace harvest_less = 1 if ph_s9q10_a == 7
replace harvest_less = 1 if ph_s9q10_a_other == "NOT READY/NOT FINISHED"
replace harvest_less = 1 if ph_s9q10_b == 7
g harvest_percent = ph_s9q09*harvest_less //What percentage of area planted has been harvested?
replace harvest_percent = . if harvest_less == 0
bysort ea_id household_id holder_id parcel_id: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1-harvest_complete
bysort ea_id household_id holder_id parcel_id: egen harvest_portion = mean(harvest_percent)
duplicates drop ea_id household_id holder_id parcel_id,force
keep ea_id household_id holder_id parcel_id harvest_complete harvest_portion
g year = 2013

keep holder_id household_id ea_id parcel_id field_id crop_code ph_s9q06 ph_s9qo6_other ph_s9q08 ph_s9q09 ph_s9q10_a ph_s9q10_b
g harvest_less = (ph_s9qo6_other == "STILL ON THE FARM")
replace harvest_less = 1 if ph_s9q10_a == 7
replace harvest_less = 1 if ph_s9q10_b == 7
g harvest_percent = ph_s9q09*harvest_less
replace harvest_percent = . if harvest_less == 0
bysort ea_id household_id holder_id parcel_id: egen harvest_complete = max(harvest_less)
replace harvest_complete = 1-harvest_complete
bysort ea_id household_id holder_id parcel_id: egen harvest_portion = mean(harvest_percent)
duplicates drop ea_id household_id holder_id parcel_id,force
keep ea_id household_id holder_id parcel_id harvest_complete harvest_portion
g year = 2015


/*==============================================================================
  SECTION 4 — APPEND WAVES AND HARMONISE
==============================================================================*/

use  "${tmp}/wave1_parcel.dta", clear
append using "${tmp}/wave2_parcel.dta"
append using "${tmp}/wave3_parcel.dta"

// Harmonise household IDs (Wave 1 vs Wave 2 string formatting)
replace household_id = substr(household_id,1,6) + substr(household_id,11,8) ///
    if length(household_id) > 14 & year == 2013

// Parcel panel ID
gen pid = holder_id + "0" + parcel_id if length(parcel_id) == 1
replace pid = holder_id + parcel_id   if length(parcel_id) == 2
encode pid, gen(pid_)


/*==============================================================================
  SECTION 5 — MERGE CLIMATE VARIABLES
==============================================================================*/

merge m:1 ea_id year using "${clim}/CHE_HDD31.dta",  nogen keep(master match)
merge m:1 ea_id year using "${clim}/CHE_DD.dta",      nogen keep(master match)
merge m:1 ea_id year using "${clim}/HH_EA_TMEANBINS.dta", nogen keep(master match)
merge m:1 ea_id year using "${clim}/weather_control.dta", nogen keep(master match)
gen pr2 = pr^2 //cumulative precipitation
gen ws2 = ws^2 //wind speed
gen sr2 = sr^2 //solar radiation
merge m:1 ea_id year using "${clim}/HDD_LAG.dta", nogen keep(master match)


/*==============================================================================
  SECTION 6 — ANALYTICAL VARIABLE CONSTRUCTION
==============================================================================*/

*--- Land yield ---
// Sample trimming: drop parcels in bottom 3% and top 97% of area
centile parea, centile(3 97)
drop if parea < r(c_1) | parea > r(c_2)

// Yield per hectare and log
gen land_yield    = pyield / parea if parea > 0
gen lnland_yield  = ln(land_yield) if land_yield > 0

*--- Inputs (per hectare, log) ---
gen land_labor    = labor_days    / parea
gen land_homelabor = homelabor_days / parea
gen land_hirelabor = hirelabor_days / parea
gen input         = pfertilizer + pseed   // total material input cost
gen land_input    = input / parea

gen ln_labor      = ln(labor_days)
gen ln_homelabor  = ln(homelabor_days)
gen ln_hirelabor  = ln(hirelabor_days)
gen ln_input      = ln(input)
gen ln_seed       = ln(pseed)

gen lnland_labor  = ln(land_labor+0.001)
gen lnland_input  = ln(land_input+0.001)
gen lnland_labor_2     = lnland_labor^2
gen lnland_input_2     = lnland_input^2
gen lnland_labor_input = lnland_labor*lnland_input

*--- TFP (translog Cobb-Douglas residual) ---
// Step 1: estimate production function coefficients
xtset pid_ year
reghdfe lnland_yield lnland_labor lnland_input ///
    lnland_labor_2 lnland_input_2 lnland_labor_input, ///
    absorb(household_id year) vce(cluster household_id)

// Step 2: compute TFP as residual
gen l   = _b[lnland_labor]
gen i_  = _b[lnland_input]
gen l2  = _b[lnland_labor_2]
gen i2  = _b[lnland_input_2]
gen li  = _b[lnland_labor_input]
gen tfp_cd = lnland_yield - l*lnland_labor - i_*lnland_input ///
           - l2*lnland_labor_2 - i2*lnland_input_2 - li*lnland_labor_input

*--- Interaction terms (gender × climate) ---
gen female_hdd31 = female * hdd_31_che
gen female_gdd31 = female * gdd_31_che
gen female_hddlag = female * hdd_31_lag
gen female_gddlag = female * gdd_31_lag
gen female_hdd30 = female * hdd_30_che
gen female_gdd30 = female * gdd_30_che
gen female_hdd32 = female * hdd_32_che
gen female_gdd32 = female * gdd_32_che

*--- Male equivalents ---
gen male_hdd31 = male * hdd_31_che
gen male_gdd31 = male * gdd_31_che

drop if missing(lnland_yield)
drop if missing(female)
drop if missing(hdd_31_che) | missing(gdd_31_che)

*--- Ethnicity ---
cd "D:\climate_gender\African_Ethnic_Groups\"
shp2dta using "D:\climate_gender\African_Ethnic_Groups\African_Ethnic_Groups_Proj", database(ethnicdb) coordinates(ethnicoord) genid(_ID)
geoinpoly lat lon using ethnicoord.dta
merge m:1 _ID using ethnicdb.dta
drop if _merge == 2
drop _merge *ID* *CNTRY* *Shape*
rename Ethnic_g ethnic_group