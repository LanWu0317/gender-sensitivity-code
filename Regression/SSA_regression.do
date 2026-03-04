cd "D:\climate_gender\Sub-sahara\output_figure"
*note:code of main_crop differs across countries, but country-year FEs restrict cross-country comparisons

append using Malawi_sample Mali_sample Niger_sample Nigeria_sample Tanzania_sample Uganda_sample
replace country_ea = country+ea
replace country_hhid = country+hhid

**USD exchange rate
cd "D:\climate_gender\Sub-sahara\"
local list "Ethiopia Malawi Mali Niger Nigeria Tanzania Uganda"
foreach i of local list{
	use `i'_sample.dta
	replace yield = yield*exrate //US dollars
	replace land_yield = yield/parea
	replace labor_yield = yield/labor_mday
	replace lnland_yield = ln(land_yield)
	replace lnlabor_yield = ln(labor_yield)
	replace input = input*exrate //US dollars
	replace lnland_input = ln(input/parea+0.001)
	replace lnland_input_2 = lnland_input^2
	replace lnland_labor_input = lnland_labor*lnland_input
	save `i'_sample.dta,replace
}

reghdfe lnland_yield lnland_labor lnland_input lnland_labor_2 lnland_input_2 lnland_labor_input, absorb(country hhid year) vce(cluster hhid)
replace l = _b[lnland_labor]
replace l2 = _b[lnland_labor_2]
replace i = _b[lnland_input]
replace i2 = _b[lnland_input_2]
replace li = _b[lnland_labor_input]
replace tfp_cd = lnland_yield-l*lnland_labor-i*lnland_input-l2*lnland_labor_2-i2*lnland_input_2-li*lnland_labor_input

**Weather controls
g ws = sqrt(u10^2+v10^2)
local list "pr sr ws"
foreach i of local list{
    g `i'2 = `i'^2
}

**Summary statistics
estpost summarize pyield land_yield intercrop maize_kg sorghum_kg millet_kg parea labor_mday input dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection soil_limiting_z female age edu_primary married married_poly separated joint_decision livestock nonfarm_work female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio
esttab using summary.csv, cells("mean(fmt(2)) sd(fmt(2)) count") noobs replace //overall indicator

estpost ttest pyield land_yield intercrop maize_kg sorghum_kg millet_kg parea labor_mday input dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection soil_limiting_z age edu_primary married married_poly separated joint_decision livestock nonfarm_work female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, by(male)
esttab . using uncon_balance.csv, cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2)) p(fmt(2))") //unconditional difference

**Balance tests
*conditional difference(within variation)
reghdfe dist_hh female age edu_primary married, absorb(countryid#year) vce(robust)
reghdfe plot_slope female age edu_primary married, absorb(countryid#year) vce(robust)
reghdfe plot_elev female age edu_primary married, absorb(countryid#year) vce(robust)
reghdfe plot_wet female age edu_primary married, absorb(countryid#year) vce(robust)
reghdfe erosion_protection female age edu_primary married, absorb(countryid#year) vce(robust)
reghdfe soil_fertility_pca female age edu_primary married, absorb(countryid#year) vce(robust)
reghdfe soil_limiting_z female age edu_primary married, absorb(countryid#year) vce(robust) //geo-data

global controls "pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio"

//# Gender-yield disparity estimates
reghdfe ln_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year) vce(robust) //total output

reghdfe ln_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust) //land productivity

reghdfe tfp_cd hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust) //total factor productivity

*note:differences here indicate expanded cropping area under heat stress

//# Robustness
**planting share
reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio portion_planted, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if portion_planted != 1, absorb(countryid#female#year main_crop soil_type) vce(robust) //dropped 5624/77858 samples

**harvest completion
reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio harvest_complete, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if harvest_complete != 0, absorb(countryid#female#year main_crop soil_type) vce(robust) //dropped 3046/77858 samples

g share_lnyield = land_yield*100/harvest_portion
replace share_lnyield = land_yield if harvest_portion == .
replace share_lnyield = ln(share_lnyield)

reghdfe share_lnyield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

**history & culture: variation across ethnic groups
encode ethnic_group, gen(ethnic_group_)
reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type ethnic_group_#year) vce(robust)

foreach var in malavi amhara wayao mandingo hausa galla tuaregs fulbe ibo tigrai jukun_idoma{ //grouped reg-SSA
	reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if `var' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

**(un)observed plot characteristics - soil quality
reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type c.soil_limiting#year) vce(robust) //geo-data of most-limiting indicator

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts workability improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust) //use 6 soil-quality indicators

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection organic_fertilizer age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust) //practices of organic fertilizer

**gender-plot characteristics interactions
reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh c.dist_hh#c.female plot_slope c.plot_slope#c.female plot_elev c.plot_elev#c.female plot_wet c.plot_wet#c.female soil_fertility_pca c.soil_fertility_pca#c.female improved irrigated intercrop erosion_protection c.erosion_protection#c.female age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#c.female#year main_crop soil_type) vce(robust)

**omitted variable bias: selection on unobservables
reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust) //Oster tests on unobservables
local r = e(r2)*1.3 //psacalc2 treating all parameters as nuisance but those in `absorb()`

psacalc2 delta female_hdd32, beta(0) rmax(`r') mcontrol(hdd_32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock)
psacalc2 beta female_hdd32, delta(1) rmax(`r') mcontrol(hdd_32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock)

//# Adaptation strategies
**Labor
reghdfe ln_labor hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe ln_homelabor hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe hirelabor_dummy hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

**Material input
reghdfe ln_input hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe ln_seedvalue hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe used_pesticides hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe intercrop hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

**Fertilizer
reghdfe ln_nitrogenkg hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe ln_fertivalue hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

**Sample restriction for validating "Gender"(marriage & caregiving)
reghdfe ln_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if married == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe ln_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if dependency_ratio > 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if married == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if dependency_ratio > 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

//# Heterogeneity analysis
*Productivity quantiles
egen prod_quantile = xtile(lnland_yield), nq(5) by(year)
forvalues i = 1/5{
	g prod_q`i' = (prod_quantile == `i')
}
drop prod_quantile
forvalues i = 1/5{
	g prodq`i'_fhdd32 = prod_q`i'*female_hdd32
	g prodq`i'_fgdd32 = prod_q`i'*female_gdd32
	g prodq`i'_hdd32 = prod_q`i'*hdd_32
	g prodq`i'_gdd32 = prod_q`i'*gdd_10_32
	g female_prodq`i' = female*prod_q`i'
}

reghdfe lnland_yield prodq*_hdd32 prodq*_fhdd32 prodq*_gdd32 prodq*_fgdd32 female_prodq* prod_q* pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

*Cropping pattern & intra-crop analysis
g female_intercrop = female*intercrop
g intercrop_fhdd32 = intercrop*female_hdd32
g intercrop_fgdd32 = intercrop*female_gdd32
g intercrop_hdd32 = intercrop*hdd_32
g intercrop_gdd32 = intercrop*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 intercrop_fhdd32 intercrop_hdd32 gdd_10_32 female_gdd32 intercrop_fgdd32 intercrop_gdd32 female_intercrop intercrop pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)
lincom female_hdd32+intercrop_fhdd32

local list "maize sorghum millet groundnut cowpea soybean cassava"
foreach i of local list{
	reghdfe ln_`i'kg hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year soil_type) vce(robust)
} //crop-specific regressions(care-intensive/saving crops)

*Farm scale (plot-size decile)
egen parea_quantile = xtile(parea), nq(10) by(year)
forvalues i = 1/10{
	g parea_q`i' = (parea_quantile == `i')
}
drop parea_quantile
bysort ea_id household year: egen farm_size = sum(parea)
bysort country ea hhid year: egen farm_size = sum(parea)

forvalues i = 1/10{
	g pareaq`i'_fhdd32 = parea_q`i'*female_hdd32
	g pareaq`i'_fgdd32 = parea_q`i'*female_gdd32
	g pareaq`i'_hdd32 = parea_q`i'*hdd_32
	g pareaq`i'_gdd32 = parea_q`i'*gdd_10_32
	g female_pareaq`i' = female*parea_q`i'
}

reghdfe lnland_yield pareaq*_hdd32 pareaq*_fhdd32 pareaq*_gdd32 pareaq*_fgdd32 female_pareaq* parea_q* pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

*Plot location (travel costs/distance)
local dist "5 3.5 1.5 1 0.5"
foreach i of local dist{
	reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if dist_hh <= `i', absorb(countryid#female#year main_crop soil_type) vce(robust)
}

*Age cohort (generation)
g age_1 = (age < 30) //1980s-later
g age_2 = (age < 40 & age >= 30) //1970s
g age_3 = (age < 50 & age >= 40) //1960s
g age_4 = (age < 60 & age >= 50) //1950s
g age_5 = (age >= 60) //1950s-earlier

forvalues i = 1/5{
    reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if age_`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

*Education (return)
reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if edu_primary == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if edu_primary == 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

*Female head (hh structure)
g fhead_hdd32 = female_hhead*hdd_32
g fhead_gdd32 = female_hhead*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 fhead_hdd32 gdd_10_32 female_gdd32 fhead_gdd32 female_hhead pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

g female_fhead = female*female_hhead
g fhead_fhdd32 = female_hdd32*female_hhead
g fhead_fgdd32 = female_gdd32*female_hhead

reghdfe lnland_yield hdd_32 female_hdd32 fhead_fhdd32 fhead_hdd32 gdd_10_32 female_gdd32 fhead_fgdd32 fhead_gdd32 female_hhead female_fhead pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)
lincom female_hdd32+fhead_fhdd32

*Relationship to household head (status)
collect create table
collect:tab relation_hhead //relationship of plot manager to household head(% of plots)
collect export "result.xlsx", replace

g junior_male = (relation_hhead != 1 & female == 0)
g junior_female = (relation_hhead != 1 & relation_hhead != 2 & female == 1)
local var "whead wife junior_male junior_female"
foreach i of local var{
	g `i'_hdd32 = `i'*hdd_32
	g `i'_gdd32 = `i'*gdd_10_32
} //gender & generation
rename junior_male_* mjunior_*
rename junior_female_* fjunior_*

reghdfe lnland_yield hdd_32 whead_hdd32 wife_hdd32 mjunior_hdd32 fjunior_hdd32 gdd_10_32 whead_gdd32 wife_gdd32 mjunior_gdd32 fjunior_gdd32 whead wife junior_male pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust) //junior_female omitted

bysort country ea hhid year: egen wife_manager = sum(wife)

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if wife_manager < 2, absorb(countryid#female#year main_crop soil_type) vce(robust) //number of wife-managers

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if wife_manager >= 2, absorb(countryid#female#year main_crop soil_type) vce(robust) //co-wive cooperative behaviors

*joint decision-making with primary manager
g joint_hdd32 = joint_decision*hdd_32
g joint_gdd32 = joint_decision*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 joint_hdd32 gdd_10_32 female_gdd32 joint_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

g female_joint = female*joint_decision
g joint_fhdd32 = female_hdd32*joint_decision
g joint_fgdd32 = female_gdd32*joint_decision

reghdfe lnland_yield hdd_32 female_hdd32 joint_fhdd32 joint_hdd32 gdd_10_32 female_gdd32 joint_fgdd32 joint_gdd32 female_joint pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)
lincom female_hdd32+joint_fhdd32

//# Barriers to adaptation
**Resource mechanism
*Access to advisory service (human capital)
replace exten_fhdd32 = c_exten_dummy*female_hdd32
replace exten_fgdd32 = c_exten_dummy*female_gdd32
replace female_exten = c_exten_dummy*female
replace hdd32_exten = c_exten_dummy*hdd_32
replace gdd32_exten = c_exten_dummy*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 exten_fhdd32 gdd_10_32 female_gdd32 exten_fgdd32 exten_dummy female_exten hdd32_exten gdd32_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 exten_fhdd32 gdd_10_32 female_gdd32 exten_fgdd32 exten_dummy female_exten hdd32_exten gdd32_exten $controls if married == 1 & dependency_ratio > 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_32 female_hdd32 exten_fhdd32 gdd_10_32 female_gdd32 exten_fgdd32 exten_dummy female_exten hdd32_exten gdd32_exten $controls if parea_q`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_32 female_hdd32 exten_fhdd32 gdd_10_32 female_gdd32 exten_fgdd32 exten_dummy female_exten hdd32_exten gdd32_exten $controls if prod_q`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_32 female_hdd32 exten_fhdd32 gdd_10_32 female_gdd32 exten_fgdd32 exten_dummy female_exten hdd32_exten gdd32_exten $controls if age_`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

replace exten_fhdd32 = c_exten_channel*female_hdd32
replace exten_fgdd32 = c_exten_channel*female_gdd32
replace female_exten = c_exten_channel*female
replace hdd32_exten = c_exten_channel*hdd_32
replace gdd32_exten = c_exten_channel*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 exten_fhdd32 gdd_10_32 female_gdd32 exten_fgdd32 exten_channel female_exten hdd32_exten gdd32_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 exten_fhdd32 gdd_10_32 female_gdd32 exten_fgdd32 exten_channel female_exten hdd32_exten gdd32_exten $controls if married == 1 & dependency_ratio > 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

*Intra-household resource allocation/bargaining power
*Control over market earning(financial agency)
replace market_fhdd32 = c_market_control*female_hdd32
replace market_fgdd32 = c_market_control*female_gdd32
replace female_market = c_market_control*female
replace hdd32_market = c_market_control*hdd_32
replace gdd32_market = c_market_control*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 market_fhdd32 gdd_10_32 female_gdd32 market_fgdd32 market_control female_market hdd32_market gdd32_market pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 market_fhdd32 gdd_10_32 female_gdd32 market_fgdd32 market_control female_market hdd32_market gdd32_market $controls if married == 1 & dependency_ratio > 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_32 female_hdd32 market_fhdd32 gdd_10_32 female_gdd32 market_fgdd32 market_control female_market hdd32_market gdd32_market $controls if parea_q`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_32 female_hdd32 market_fhdd32 gdd_10_32 female_gdd32 market_fgdd32 market_control female_market hdd32_market gdd32_market $controls if prod_q`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_32 female_hdd32 market_fhdd32 gdd_10_32 female_gdd32 market_fgdd32 market_control female_market hdd32_market gdd32_market $controls if age_`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

*Land ownership(secure property/tenure right)
replace property_fhdd32 = c_parcel_owner*female_hdd32
replace property_fgdd32 = c_parcel_owner*female_gdd32
replace female_property = c_parcel_owner*female
replace hdd32_property = c_parcel_owner*hdd_32
replace gdd32_property = c_parcel_owner*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 property_fhdd32 gdd_10_32 female_gdd32 property_fgdd32 parcel_owner female_property hdd32_property gdd32_property pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 property_fhdd32 gdd_10_32 female_gdd32 property_fgdd32 parcel_owner female_property hdd32_property gdd32_property $controls if married == 1 & dependency_ratio > 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_32 female_hdd32 property_fhdd32 gdd_10_32 female_gdd32 property_fgdd32 parcel_owner female_property hdd32_property gdd32_property $controls if parea_q`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_32 female_hdd32 property_fhdd32 gdd_10_32 female_gdd32 property_fgdd32 parcel_owner female_property hdd32_property gdd32_property $controls if prod_q`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_32 female_hdd32 property_fhdd32 gdd_10_32 female_gdd32 property_fgdd32 parcel_owner female_property hdd32_property gdd32_property $controls if age_`i' == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)
}

replace certified_fhdd32 = c_parcel_certified*female_hdd32
replace certified_fgdd32 = c_parcel_certified*female_gdd32
replace female_certified = c_parcel_certified*female
replace hdd32_certified = c_parcel_certified*hdd_32
replace gdd32_certified = c_parcel_certified*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 certified_fhdd32 gdd_10_32 female_gdd32 certified_fgdd32 parcel_certified female_certified hdd32_certified gdd32_certified pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 certified_fhdd32 gdd_10_32 female_gdd32 certified_fgdd32 parcel_certified female_certified hdd32_certified gdd32_certified $controls if married == 1 & dependency_ratio > 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

**# Structural mechanism
*Marital status
g unmarried_fhdd32 = c_unmarried*female_hdd32
g unmarried_fgdd32 = c_unmarried*female_gdd32
g married_poly_fhdd32 = c_married_poly*female_hdd32
g married_poly_fgdd32 = c_married_poly*female_gdd32
g separated_fhdd32 = c_separated*female_hdd32
g separated_fgdd32 = c_separated*female_gdd32

g female_unmarried = c_unmarried*female
g female_married_poly = c_married_poly*female
g female_separated = c_separated*female
g hdd32_unmarried = c_unmarried*hdd_32
g gdd32_unmarried = c_unmarried*gdd_10_32
g hdd32_married_poly = c_married_poly*hdd_32
g gdd32_married_poly = c_married_poly*gdd_10_32
g hdd32_separated = c_separated*hdd_32
g gdd32_separated = c_separated*gdd_10_32

reghdfe lnland_yield hdd_32 female_hdd32 unmarried_fhdd32 married_poly_fhdd32 separated_fhdd32 gdd_10_32 female_gdd32 unmarried_fgdd32 married_poly_fgdd32 separated_fgdd32 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd32_unmarried gdd32_unmarried hdd32_married_poly gdd32_married_poly hdd32_separated gdd32_separated pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)

center dependency_ratio
g depend_fhdd32 = c_dependency_ratio*female_hdd32
g depend_fgdd32 = c_dependency_ratio*female_gdd32
g depend_hdd32 = c_dependency_ratio*hdd_32
g depend_gdd32 = c_dependency_ratio*gdd_10_32
g female_depend = female*c_dependency_ratio

reghdfe lnland_yield hdd_32 female_hdd32 depend_fhdd32 gdd_10_32 female_gdd32 depend_fgdd32 dependency_ratio female_depend depend_hdd32 depend_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size, absorb(countryid#female#year main_crop soil_type) vce(robust)

*cooperation in polygynous households
reghdfe lnland_yield hdd_32 female_hdd32 unmarried_fhdd32 married_poly_fhdd32 separated_fhdd32 gdd_10_32 female_gdd32 unmarried_fgdd32 married_poly_fgdd32 separated_fgdd32 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd32_unmarried gdd32_unmarried hdd32_married_poly gdd32_married_poly hdd32_separated gdd32_separated $controls if joint_decision == 0, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 unmarried_fhdd32 married_poly_fhdd32 separated_fhdd32 gdd_10_32 female_gdd32 unmarried_fgdd32 married_poly_fgdd32 separated_fgdd32 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd32_unmarried gdd32_unmarried hdd32_married_poly gdd32_married_poly hdd32_separated gdd32_separated $controls if joint_decision == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)

*cooperative husbands-wives vs cooerative co-wives
reghdfe lnland_yield hdd_32 female_hdd32 unmarried_fhdd32 married_poly_fhdd32 separated_fhdd32 gdd_10_32 female_gdd32 unmarried_fgdd32 married_poly_fgdd32 separated_fgdd32 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd32_unmarried gdd32_unmarried hdd32_married_poly gdd32_married_poly hdd32_separated gdd32_separated $controls if spouse_joint == 1 & relation_hhead == 1, absorb(countryid#female#year main_crop soil_type) vce(robust)

reghdfe lnland_yield hdd_32 female_hdd32 unmarried_fhdd32 married_poly_fhdd32 separated_fhdd32 gdd_10_32 female_gdd32 unmarried_fgdd32 married_poly_fgdd32 separated_fgdd32 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd32_unmarried gdd32_unmarried hdd32_married_poly gdd32_married_poly hdd32_separated gdd32_separated $controls if spouse_joint == 1 & wife == 1, absorb(countryid#female#year main_crop soil_type) vce(robust) //138 samples remained(cautious)

//# Future projection
reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(countryid#female#year main_crop soil_type) vce(robust)
predict landyield_110, xb
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_2`i'5
	replace gdd_10_32 = gdd_32_2`i'5
	replace female_hdd32 = female_hdd32_2`i'5
	replace female_gdd32 = female_gdd32_2`i'5
	predict landyield_2`i'5, xb
}
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_5`i'5
	replace gdd_10_32 = gdd_32_5`i'5
	replace female_hdd32 = female_hdd32_5`i'5
	replace female_gdd32 = female_gdd32_5`i'5
	predict landyield_5`i'5, xb
}

replace hdd_32 = hdd_32_origin
replace gdd_10_32 = gdd_32_origin
replace female_hdd32 = female_hdd32_origin
replace female_gdd32 = female_gdd32_origin

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(countryid#female#year main_crop soil_type) vce(robust)
predict landyield_pw_110,xb
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_2`i'5
	replace gdd_10_32 = gdd_32_2`i'5
	replace female_hdd32 = female_hdd32_2`i'5
	replace female_gdd32 = female_gdd32_2`i'5
	predict landyield_pw_2`i'5, xb
}
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_5`i'5
	replace gdd_10_32 = gdd_32_5`i'5
	replace female_hdd32 = female_hdd32_5`i'5
	replace female_gdd32 = female_gdd32_5`i'5
	predict landyield_pw_5`i'5, xb
}

replace hdd_32 = hdd_32_origin
replace gdd_10_32 = gdd_32_origin
replace female_hdd32 = female_hdd32_origin
replace female_gdd32 = female_gdd32_origin

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if joint_decision == 0 [pw = pw], absorb(countryid#female#year main_crop soil_type) vce(robust)
predict landyield_joint_110,xb
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_2`i'5
	replace gdd_10_32 = gdd_32_2`i'5
	replace female_hdd32 = female_hdd32_2`i'5
	replace female_gdd32 = female_gdd32_2`i'5
	predict landyield_joint_2`i'5, xb
}

replace hdd_32 = hdd_32_origin
replace gdd_10_32 = gdd_32_origin
replace female_hdd32 = female_hdd32_origin
replace female_gdd32 = female_gdd32_origin

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if spouse_joint == 0 [pw = pw], absorb(countryid#female#year main_crop soil_type) vce(robust)
predict landyield_spouse_110,xb
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_2`i'5
	replace gdd_10_32 = gdd_32_2`i'5
	replace female_hdd32 = female_hdd32_2`i'5
	replace female_gdd32 = female_gdd32_2`i'5
	predict landyield_spouse_2`i'5, xb
}

replace hdd_32 = hdd_32_origin
replace gdd_10_32 = gdd_32_origin
replace female_hdd32 = female_hdd32_origin
replace female_gdd32 = female_gdd32_origin

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if soil_fertility_pca <= 0.223 [pw = pw], absorb(countryid#female#year main_crop soil_type) vce(robust)
predict landyield_soil_110,xb
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_2`i'5
	replace gdd_10_32 = gdd_32_2`i'5
	replace female_hdd32 = female_hdd32_2`i'5
	replace female_gdd32 = female_gdd32_2`i'5
	predict landyield_soil_2`i'5, xb
}

replace hdd_32 = hdd_32_origin
replace gdd_10_32 = gdd_32_origin
replace female_hdd32 = female_hdd32_origin
replace female_gdd32 = female_gdd32_origin

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if parcel_owner != 1|parcel_certified != 1 [pw = pw], absorb(countryid#female#year main_crop soil_type) vce(robust)
predict landyield_tenure_110,xb
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_2`i'5
	replace gdd_10_32 = gdd_32_2`i'5
	replace female_hdd32 = female_hdd32_2`i'5
	replace female_gdd32 = female_gdd32_2`i'5
	predict landyield_tenure_2`i'5, xb
}

replace hdd_32 = hdd_32_origin
replace gdd_10_32 = gdd_32_origin
replace female_hdd32 = female_hdd32_origin
replace female_gdd32 = female_gdd32_origin

reghdfe lnland_yield hdd_32 female_hdd32 gdd_10_32 female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated intercrop erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if (parea_q1|parea_q2|parea_q3|parea_q4|parea_q5) == 1 [pw = pw], absorb(countryid#female#year main_crop soil_type) vce(robust)
predict landyield_pareaq_110,xb
forvalues i = 5(4)9{
	replace hdd_32 = hdd_32_2`i'5
	replace gdd_10_32 = gdd_32_2`i'5
	replace female_hdd32 = female_hdd32_2`i'5
	replace female_gdd32 = female_gdd32_2`i'5
	predict landyield_pareaq_2`i'5, xb
}

replace hdd_32 = hdd_32_origin
replace gdd_10_32 = gdd_32_origin
replace female_hdd32 = female_hdd32_origin
replace female_gdd32 = female_gdd32_origin

estpost ttest landyield_110 landyield_255-landyield_pw_595, by(female)
esttab . using mean_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

estpost ttest landyield_joint_255-landyield_spouse_295, by(female)
esttab . using migration_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

estpost ttest landyield_tenure_255-landyield_tenure_295, by(female)
esttab . using consolidate_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

estpost ttest landyield_soil_255-landyield_soil_295, by(female)
esttab . using productivity_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

forvalues i = 5(4)9{
	replace dlandyield_2`i'5 = (exp(landyield_2`i'5-landyield_110)-1)*100
}
forvalues i = 5(4)9{
	replace dlandyield_5`i'5 = (exp(landyield_5`i'5-landyield_110)-1)*100
}
forvalues i = 5(4)9{
	replace dlandyield_pw_2`i'5 = (exp(landyield_pw_2`i'5-landyield_pw_110)-1)*100
}
forvalues i = 5(4)9{
	replace dlandyield_pw_5`i'5 = (exp(landyield_pw_5`i'5-landyield_pw_110)-1)*100
}
forvalues i = 5(4)9{
	replace dlandyield_joint_2`i'5 = (exp(landyield_joint_2`i'5-landyield_joint_110)-1)*100
}
forvalues i = 5(4)9{
	replace dlandyield_spouse_2`i'5 = (exp(landyield_spouse_2`i'5-landyield_spouse_110)-1)*100
}
forvalues i = 5(4)9{
	replace dlandyield_tenure_2`i'5 = (exp(landyield_tenure_2`i'5-landyield_tenure_110)-1)*100
}
forvalues i = 5(4)9{
	replace dlandyield_soil_2`i'5 = (exp(landyield_soil_2`i'5-landyield_soil_110)-1)*100
}
estpost tabstat dlandyield_255-dlandyield_pw_595, by(female) stat(mean p50 p5 p95 p25 p75) columns(statistics)
esttab . using diff_project.csv, replace cell("mean(fmt(2)) p50(fmt(2)) p5(fmt(2)) p95(fmt(2)) p25(fmt(2)) p75(fmt(2))")

estpost tabstat dlandyield_joint_255-dlandyield_soil_295, by(female) stat(mean p50 p5 p95 p25 p75) columns(statistics)
esttab . using diff_project_migration.csv, replace cell("mean(fmt(2)) p50(fmt(2)) p5(fmt(2)) p95(fmt(2)) p25(fmt(2)) p75(fmt(2))")

**Visualization at the EA level
g landyield_110_female = landyield_pw_110 if female == 1
g landyield_110_male = landyield_pw_110 if male == 1
bysort lat lon: egen landyield_110_female_mean = mean(landyield_110_female)
bysort lat lon: egen landyield_110_male_mean = mean(landyield_110_male)

g landyield_255_female = landyield_pw_255 if female == 1
g landyield_255_male = landyield_pw_255 if male == 1
bysort lat lon: egen landyield_255_female_mean = mean(landyield_255_female)
bysort lat lon: egen landyield_255_male_mean = mean(landyield_255_male)

g yieldchange_255 = (exp(landyield_255_female_mean-landyield_110_female_mean)-1)*100

g gapchange_255 = (1-1/exp(landyield_255_male_mean-landyield_255_female_mean))*100-(1-1/exp(landyield_110_male_mean-landyield_110_female_mean))*100
