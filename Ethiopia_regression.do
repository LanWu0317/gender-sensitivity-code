cd "D:\climate_gender\Ethiopia\output_figure"

**Summary statistics
estpost summarize tfp_cd intercrop crop_diversity maize sorghum millet parea labor_mday dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection soil_limiting_z female age edu_primary married married_poly spousal_hh have_child separated joint_decision livestock nonfarm_work female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio
esttab using summary.csv, cells("mean(fmt(2)) sd(fmt(2)) count") noobs replace //overall indicator

estpost ttest tfp_cd intercrop crop_diversity maize sorghum millet parea labor_mday dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection soil_limiting_z age edu_primary married married_poly spousal_hh have_child separated joint_decision livestock nonfarm_work female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, by(male)
esttab . using uncon_balance.csv, cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2)) p(fmt(2))") //unconditional difference

**Balance tests
*conditional difference(within variation)
foreach var in dist_hh plot_slope plot_elev plot_wet soil_fertility_pca erosion_protection{
	reghdfe `var' female age edu_primary married female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(ea_id zone#year) vce(cluster ea_id)
}
reghdfe soil_limiting_z female age edu_primary married female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(zone#year) vce(cluster zone) //geo-data

foreach var in nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability{
	reghdfe `var' female age edu_primary married female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(ea_id zone#year) vce(cluster ea_id)	
}

*balance tests for predetermined gender(selection)
reghdfe female dist_hh plot_slope plot_elev plot_wet nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts workability erosion_protection c.soil_limiting#i.year, absorb(household_id zone#year) vce(cluster household_id)

global controls "pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio"

//Dep.Var:Land Yield
xtset pid_ year
**Threshod validation
reghdfe lnland_yield gdd_30_che hdd_30_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year main_crop soil_type) vce(cluster household_id)

reghdfe lnland_yield gdd_31_che hdd_31_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year main_crop soil_type) vce(cluster household_id)

reghdfe lnland_yield gdd_32_che hdd_32_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year main_crop soil_type) vce(cluster household_id)

**# Gender-yield disparity estimates
replace female_hdd30 = female*hdd_30_che
replace female_gdd30 = female*gdd_30_che

reghdfe lnland_yield hdd_30_che female_hdd30 gdd_30_che female_gdd30 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

replace female_hdd31 = female*hdd_31_che
replace female_gdd31 = female*gdd_31_che
replace female_hddlag = female*hdd_31_lag
replace female_gddlag = female*gdd_31_lag

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che hdd_31_lag female_hdd31 female_hddlag gdd_31_che gdd_31_lag female_gdd31 female_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //lagged temperature: experience & adaptation

replace female_hdd32 = female*hdd_32_che
replace female_gdd32 = female*gdd_32_che

reghdfe lnland_yield hdd_32_che female_hdd32 gdd_32_che female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**Heterogeneity analysis
*Pre-shock exposure to temperatures
reghdfe lnland_yield hdd_31_che hdd_31_lag female_hdd31 c.hdd_31_lag#c.female_hdd31 female_hddlag gdd_31_che gdd_31_lag female_gdd31 c.gdd_31_lag#c.female_gdd31 female_gddlag c.hdd_31_che#c.hdd_31_lag c.gdd_31_che#c.gdd_31_lag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

*Productivity quantiles
egen prod_quantile = xtile(lnland_yield), nq(5) by(year)
forvalues i = 1/5{
	g prod_q`i' = (prod_quantile == `i')
}
drop prod_quantile
forvalues i = 1/5{
	g prodq`i'_fhdd31 = prod_q`i'*female_hdd31
	g prodq`i'_fgdd31 = prod_q`i'*female_gdd31
	g prodq`i'_hdd31 = prod_q`i'*hdd_31_che
	g prodq`i'_gdd31 = prod_q`i'*gdd_31_che
	g female_prodq`i' = female*prod_q`i'
}
reghdfe lnland_yield prodq*_hdd31 prodq*_fhdd31 prodq*_gdd31 prodq*_fgdd31 female_prodq* prod_q* pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

*Cropping pattern & intra-crop analysis
g female_intercrop = female*intercrop
g intercrop_fhdd31 = intercrop*female_hdd31
g intercrop_fgdd31 = intercrop*female_gdd31
g intercrop_hdd31 = intercrop*hdd_31_che
g intercrop_gdd31 = intercrop*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 intercrop_fhdd31 intercrop_hdd31 gdd_31_che female_gdd31 intercrop_fgdd31 intercrop_gdd31 female_intercrop intercrop pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
lincom female_hdd31+intercrop_fhdd31

g female_diversity = female*crop_diversity
g diversity_fhdd31 = crop_diversity*female_hdd31
g diversity_fgdd31 = crop_diversity*female_gdd31
g diversity_hdd31 = crop_diversity*hdd_31_che
g diversity_gdd31 = crop_diversity*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 diversity_fhdd31 diversity_hdd31 gdd_31_che female_gdd31 diversity_fgdd31 diversity_gdd31 female_diversity crop_diversity pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

local crop "maize teff sorghum wheat barley coffee millet"
replace other_crop = 1
foreach i of local crop {
	g `i'_fhdd31 = `i'*female_hdd31
	g `i'_fgdd31 = `i'*female_gdd31
	g `i'_hdd31 = `i'*hdd_31_che
	g `i'_gdd31 = `i'*gdd_31_che
	replace other_crop = other_crop-`i'
}
g other_fhdd31 = other_crop*female_hdd31
g other_fgdd31 = other_crop*female_gdd31
g other_hdd31 = other_crop*hdd_31_che
g other_gdd31 = other_crop*gdd_31_che

reghdfe lnland_yield maize_hdd31 teff_hdd31 sorghum_hdd31 wheat_hdd31 barley_hdd31 coffee_hdd31 millet_hdd31 other_hdd31 maize_fhdd31 teff_fhdd31 sorghum_fhdd31 wheat_fhdd31 barley_fhdd31 coffee_fhdd31 millet_fhdd31 other_fhdd31 maize_gdd31 teff_gdd31 sorghum_gdd31 wheat_gdd31 barley_gdd31 coffee_gdd31 millet_gdd31 other_gdd31 maize_fgdd31 teff_fgdd31 sorghum_fgdd31 wheat_fgdd31 barley_fgdd31 coffee_fgdd31 millet_fgdd31 other_fgdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //care-intensive/saving crops

*Farm scale (plot-size decile)
egen parea_quantile = xtile(parea), nq(10) by(year)
forvalues i = 1/10{
	g parea_q`i' = (parea_quantile == `i')
}
drop parea_quantile
bysort ea_id household year: egen farm_size = sum(parea)
bysort country ea hhid year: egen farm_size = sum(parea)

forvalues i = 1/10{
	g pareaq`i'_fhdd31 = parea_q`i'*female_hdd31
	g pareaq`i'_fgdd31 = parea_q`i'*female_gdd31
	g pareaq`i'_hdd31 = parea_q`i'*hdd_31_che
	g pareaq`i'_gdd31 = parea_q`i'*gdd_31_che
	g female_pareaq`i' = female*parea_q`i'
}
reghdfe lnland_yield pareaq*_hdd31 pareaq*_fhdd31 pareaq*_gdd31 pareaq*_fgdd31 female_pareaq* parea_q* pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

*Plot location (travel costs/distance)
local dist "5 3.5 1.5 1 0.5"
foreach i of local dist{
	reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if dist_hh <= `i', absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

*Age cohort (generation)
g age_1 = (age < 30) //1980s-later
g age_2 = (age < 40 & age >= 30) //1970s
g age_3 = (age < 50 & age >= 40) //1960s
g age_4 = (age < 60 & age >= 50) //1950s
g age_5 = (age >= 60) //1950s-earlier

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if age_`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

*Education (return)
reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if edu_primary == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if edu_primary == 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

*Religion (culture)
g muslem = (religion == 4)
g orthodox = (religion == 1)
g protestant = (religion == 3)
g other_relig = (relig_1 == 0 & relig_2 == 0 & relig_3 == 0)

local var "muslem orthodox protestant other_relig"
foreach i of local var{
	g `i'_fhdd31 = `i'*female_hdd31
	g `i'_fgdd31 = `i'*female_gdd31
	g `i'_hdd31 = `i'*hdd_31_che
	g `i'_gdd31 = `i'*gdd_31_che
	g female_`i' = `i'*female
}
reghdfe lnland_yield muslem_hdd31 orthodox_hdd31 protestant_hdd31 other_relig_hdd31 muslem_fhdd31 orthodox_fhdd31 protestant_fhdd31 other_relig_fhdd31 muslem_gdd31 orthodox_gdd31 protestant_gdd31 other_relig_gdd31 muslem_fgdd31 orthodox_fgdd31 protestant_fgdd31 other_relig_fgdd31 muslem orthodox protestant pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

*Female head (hh structure)
g fhead_hdd31 = female_hhead*hdd_31_che
g fhead_gdd31 = female_hhead*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 fhead_hdd31 gdd_31_che female_gdd31 fhead_gdd31 female_hhead pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

g female_fhead = female*female_hhead
g fhead_fhdd31 = female_hdd31*female_hhead
g fhead_fgdd31 = female_gdd31*female_hhead

reghdfe lnland_yield hdd_31_che female_hdd31 fhead_fhdd31 fhead_hdd31 gdd_31_che female_gdd31 fhead_fgdd31 fhead_gdd31 female_hhead female_fhead pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
lincom female_hdd31+fhead_fhdd31

*Relationship to household head (status)
collect create table
collect:tab relation_hhead //relationship of plot manager to household head(% of plots)
collect export "result.xlsx", replace

g junior_male = (relation_hhead != 1 & female == 0)
g junior_female = (relation_hhead != 1 & relation_hhead != 2 & female == 1)
local var "whead wife junior_male junior_female"
foreach i of local var{
	g `i'_hdd31 = `i'*hdd_31_che
	g `i'_gdd31 = `i'*gdd_31_che
} //gender & generation
rename junior_male_* mjunior_*
rename junior_female_* fjunior_*

reghdfe lnland_yield hdd_31_che whead_hdd31 wife_hdd31 fjunior_hdd31 gdd_31_che whead_gdd31 wife_gdd31 fjunior_gdd31 whead wife pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //hh status & position

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if machine_num < 2, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //large capital goods, assets, and cooperative behaviors

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if machine_num >= 2, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //difficult to sub-divide

*joint decision-making with primary manager
g joint_hdd31 = joint_decision*hdd_31_che
g joint_gdd31 = joint_decision*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 joint_hdd31 gdd_31_che female_gdd31 joint_gdd31 joint_decision pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

g female_joint = female*joint_decision
g joint_fhdd31 = female_hdd31*joint_decision
g joint_fgdd31 = female_gdd31*joint_decision

reghdfe lnland_yield hdd_31_che female_hdd31 joint_fhdd31 joint_hdd31 gdd_31_che female_gdd31 joint_fgdd31 joint_gdd31 female_joint joint_decision pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
lincom female_hdd31+joint_fhdd31

**Sample restriction for validating "Gender"
*wife/mother roles for robustness checks
reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if married == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if spousal_hh == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if child_num >= 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if dependency_ratio > 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**Agricultural TFP
*conventional C-D
reghdfe lnland_yield lnland_labor lnland_input, absorb(household_id year) vce(cluster household_id)
replace l = _b[lnland_labor]
replace i = _b[lnland_input]
replace tfp_cd_con = lnland_yield-l*lnland_labor-i*lnland_input
*translog C-D
reghdfe lnland_yield lnland_labor lnland_input lnland_labor_2 lnland_input_2 lnland_labor_input, absorb(household_id year) vce(cluster household_id)
replace l = _b[lnland_labor]
replace l2 = _b[lnland_labor_2]
replace i = _b[lnland_input]
replace i2 = _b[lnland_input_2]
replace li = _b[lnland_labor_input]
replace tfp_cd = lnland_yield-l*lnland_labor-i*lnland_input-l2*lnland_labor_2-i2*lnland_input_2-li*lnland_labor_input
*conventional SFA
frontier lnland_yield lnland_labor lnland_input i.year
replace l = _b[lnland_labor]
replace i = _b[lnland_input]
replace tfp_sfa_con = lnland_yield-l*lnland_labor-i*lnland_input
*translog SFA
frontier lnland_yield lnland_labor lnland_input lnland_labor_2 lnland_input_2 lnland_labor_input i.year
replace l = _b[lnland_labor]
replace l2 = _b[lnland_labor_2]
replace i = _b[lnland_input]
replace i2 = _b[lnland_input_2]
replace li = _b[lnland_labor_input]
replace tfp_sfa = lnland_yield-l*lnland_labor-i*lnland_input-l2*lnland_labor_2-i2*lnland_input_2-li*lnland_labor_input

//Dep.Var:TFP
xtset pid_ year
**Threshod validation
reghdfe tfp_cd gdd_30_che hdd_30_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year main_crop soil_type) vce(cluster household_id)

reghdfe tfp_cd gdd_31_che hdd_31_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year main_crop soil_type) vce(cluster household_id)

reghdfe tfp_cd gdd_32_che hdd_32_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year main_crop soil_type) vce(cluster household_id)

**# Gender-TFP disparity estimates
reghdfe tfp_cd hdd_30_che female_hdd30 gdd_30_che female_gdd30 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe tfp_cd hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe tfp_cd hdd_31_che hdd_31_lag female_hdd31 female_hddlag gdd_31_che gdd_31_lag female_gdd31 female_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //lagged temperature: experience & adaptation

reghdfe tfp_cd hdd_32_che female_hdd32 gdd_32_che female_gdd32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

//Temperature bins(3-degree bins (20-23 omitted))
**Number of days
replace female_d1114 = female*d_11_14
replace female_d1417 = female*d_14_17
replace female_d1720 = female*d_17_20
replace female_d2326 = female*d_23_26
replace female_d2629 = female*d_26_29
replace female_d2932 = female*d_29_32
replace female_d32 = female*d_32

replace male_d1114 = male*d_11_14
replace male_d1417 = male*d_14_17
replace male_d1720 = male*d_17_20
replace male_d2326 = male*d_23_26
replace male_d2629 = male*d_26_29
replace male_d2932 = male*d_29_32
replace male_d32 = male*d_32

reghdfe lnland_yield female_d1114 male_d1114 female_d1417 male_d1417 female_d1720 male_d1720 female_d2326 male_d2326 female_d2629 male_d2629 female_d2932 male_d2932 female_d32 male_d32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) level(90)

reghdfe tfp_cd female_d1114 male_d1114 female_d1417 male_d1417 female_d1720 male_d1720 female_d2326 male_d2326 female_d2629 male_d2629 female_d2932 male_d2932 female_d32 male_d32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) level(90)

//Degree-days
g female_d2023 = female*dd_20_23
g male_d2023 = male*dd_20_23

replace female_d1114 = female*dd_11_14
replace female_d1417 = female*dd_14_17
replace female_d1720 = female*dd_17_20
replace female_d2326 = female*dd_23_26
replace female_d2629 = female*dd_26_29
replace female_d2932 = female*dd_29_32
replace female_d32 = female*dd_32

replace male_d1114 = male*dd_11_14
replace male_d1417 = male*dd_14_17
replace male_d1720 = male*dd_17_20
replace male_d2326 = male*dd_23_26
replace male_d2629 = male*dd_26_29
replace male_d2932 = male*dd_29_32
replace male_d32 = male*dd_32

reghdfe lnland_yield female_d1114 male_d1114 female_d1417 male_d1417 female_d1720 male_d1720 female_d2023 male_d2023 female_d2326 male_d2326 female_d2629 male_d2629 female_d2932 male_d2932 female_d32 male_d32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) level(90)

reghdfe tfp_cd female_d1114 male_d1114 female_d1417 male_d1417 female_d1720 male_d1720 female_d2023 male_d2023 female_d2326 male_d2326 female_d2629 male_d2629 female_d2932 male_d2932 female_d32 male_d32 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) level(90)

//Seasonal average temperature
replace group = 12
forvalues i = 1/42{
	replace group = 12+(`i'*0.5) if tmean >= 12+(`i'*0.5) & tmean < 13+(`i'*0.5)
} //non/semi-parametric regression with fixed effects
egen tmean_bin = mean(tmean),by(group)
egen flandyield_bin = mean(f_landyield),by(group)
egen mlandyield_bin = mean(m_landyield),by(group)

**Local polynomial(degree:4)
twoway (scatter mlandyield_bin tmean_bin, mlcolor("69 117 180%60") mfcolor(white) msize(medlarge)) (scatter flandyield_bin tmean_bin, mlcolor("215 48 39%60") mfcolor(white) msize(medlarge)) (lpolyci lnland_yield_hh tmean if sex == 1, alwidth(none) lcolor("69 117 180") lwidth(thick) lp(dash) fcolor("69 117 180%60") fintensity(40) degree(4) level(90)) (lpolyci lnland_yield_hh tmean if sex == 2, alwidth(none) lcolor("215 48 39") lwidth(thick) lp(dash) fcolor("215 48 39%60") fintensity(40) degree(4) level(90)), legend(off) xline(31.5, lp(dash) lc("69 117 180%40") lw(0.4)) xline(29.5, lp(dash) lc("215 48 39%40") lw(0.4)) graphregion(fcolor(white) lcolor(white)) xsize(4.5) ysize(6) yscale(r(-2.4 1.6)) ylabel(-2.4(0.8)1.6) xscale(r(12 32)) xlabel(12(4)32) xtitle(Seasonal Average Temperature (℃)) ytitle(Log change in Yield)

//# Robustness
**planting share
reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio portion_planted, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if portion_planted != 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //dropped 378/18151 samples

**harvest completion
reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio harvest_complete, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if harvest_complete != 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //dropped 821/18151 samples

g share_lnyield = land_yield*100/harvest_portion
replace share_lnyield = land_yield if harvest_portion == .
replace share_lnyield = ln(share_lnyield)

reghdfe share_lnyield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**history & culture: variation across ethnic groups
encode ethnic_group, gen(ethnic_group_)
reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type ethnic_group_#year) vce(cluster household_id)

**(un)observed plot characteristics - soil quality
reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type c.soil_limiting#year) vce(cluster household_id) //geo-data of most-limiting indicator

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts workability improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //use 6 soil-quality indicators

reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection organic_fertilizer age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id) //practices of organic fertilizer

**gender-plot characteristics interactions
reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh c.dist_hh#c.female plot_slope c.plot_slope#c.female plot_elev c.plot_elev#c.female plot_wet c.plot_wet#c.female soil_fertility_pca c.soil_fertility_pca#c.female improved irrigated crop_diversity erosion_protection c.erosion_protection#c.female age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**omitted variable bias: selection on unobservables
*residual deviation
reghdfe lnland_yield, absorb(pid zone#year female#main_crop female#soil_type) resid
predict lnland_yield_pc, resid //tracked parcels
reghdfe lnland_yield, absorb(holder_id zone#year female#main_crop female#soil_type) resid
predict lnland_yield_ind, resid
reghdfe lnland_yield, absorb(household_id zone#year female#main_crop female#soil_type) resid
predict lnland_yield_hh, resid
reghdfe lnland_yield, absorb(ea_id zone#year female#main_crop female#soil_type) resid
predict lnland_yield_ea, resid

drop _reghdfe_resid
twoway (kdensity lnland_yield_ind)(kdensity lnland_yield_hh)(kdensity lnland_yield_ea)

*Oster tests on unobservables
reghdfe lnland_yield hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
local r = e(r2)*1.3 //psacalc2 treating all parameters as nuisance but those in `absorb()`

psacalc2 delta female_hdd31, beta(0) rmax(`r') mcontrol(hdd_31_che gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock)
psacalc2 beta female_hdd31, delta(1) rmax(`r') mcontrol(hdd_31_che gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock)

//# Adaptation strategies
**Farm labor
reghdfe ln_labor hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe ln_labor female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe ln_homelabor hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe ln_homelabor female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe hirelabor_dummy hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe hirelabor_dummy female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**Farm input
reghdfe ln_input hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe ln_input female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**Seed purchase
reghdfe ln_seed hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe ln_seed female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**Irrigated area
reghdfe iarea_m2 hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe iarea_m2 female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**Crop diversity
reghdfe intercrop female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe crop_diversity female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**Fertilizer value
reghdfe ln_fertilizer hdd_31_che female_hdd31 gdd_31_che female_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe ln_fertilizer female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe organic_fertilizer female_hdd31 female_hddlag male_hdd31 male_hddlag female_gdd31 female_gddlag male_gdd31 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

**Mechanism for labor adjustment
g collect_fhdd31 = c_collect*female_hdd31 //water/wood collect
g collect_fgdd31 = c_collect*female_gdd31
g female_collect = c_collect*female
g hdd31_collect = c_collect*hdd_31_che
g gdd31_collect = c_collect*gdd_31_che

reghdfe ln_homelabor hdd_31_che female_hdd31 collect_fhdd31 gdd_31_che female_gdd31 collect_fgdd31 collect female_collect hdd31_collect gdd31_collect pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

replace livestock_fhdd31 = c_livestock*female_hdd31 //livestock breeding
replace livestock_fgdd31 = c_livestock*female_gdd31
replace female_livestock = c_livestock*female
replace hdd31_livestock = c_livestock*hdd_31_che
replace gdd31_livestock = c_livestock*gdd_31_che

reghdfe ln_homelabor hdd_31_che female_hdd31 livestock_fhdd31 gdd_31_che female_gdd31 livestock_fgdd31 livestock female_livestock hdd31_livestock gdd31_livestock pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

replace livestock_fhdd31 = c_livestock_cost*female_hdd31 //livestock cost
replace livestock_fgdd31 = c_livestock_cost*female_gdd31
replace female_livestock = c_livestock_cost*female
replace hdd31_livestock = c_livestock_cost*hdd_31_che
replace gdd31_livestock = c_livestock_cost*gdd_31_che

reghdfe ln_homelabor hdd_31_che female_hdd31 livestock_fhdd31 gdd_31_che female_gdd31 livestock_fgdd31 livestock_cost female_livestock hdd31_livestock gdd31_livestock pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

g temp_fhdd31 = c_temp_dummy*female_hdd31 //temporary work
g temp_fgdd31 = c_temp_dummy*female_gdd31
g female_temp = c_temp_dummy*female
g hdd31_temp = c_temp_dummy*hdd_31_che
g gdd31_temp = c_temp_dummy*gdd_31_che

reghdfe ln_homelabor hdd_31_che female_hdd31 temp_fhdd31 gdd_31_che female_gdd31 temp_fgdd31 temp_dummy female_temp hdd31_temp gdd31_temp pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

g nonfarm_fhdd31 = c_nonfarm_work*female_hdd31 //off-farm work
g nonfarm_fgdd31 = c_nonfarm_work*female_gdd31
g female_nonfarm = c_nonfarm_work*female
g hdd31_nonfarm = c_nonfarm_work*hdd_31_che
g gdd31_nonfarm = c_nonfarm_work*gdd_31_che

reghdfe ln_homelabor hdd_31_che female_hdd31 nonfarm_fhdd31 gdd_31_che female_gdd31 nonfarm_fgdd31 nonfarm_work female_nonfarm hdd31_nonfarm gdd31_nonfarm pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

replace rental_fhdd31 = c_land_rental*female_hdd31 //land rental
replace rental_fgdd31 = c_land_rental*female_gdd31
replace female_rental = c_land_rental*female
replace hdd31_rental = c_land_rental*hdd_31_che
replace gdd31_rental = c_land_rental*gdd_31_che

reghdfe ln_homelabor hdd_31_che female_hdd31 rental_fhdd31 gdd_31_che female_gdd31 rental_fgdd31 land_rental female_rental hdd31_rental gdd31_rental pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

replace rental_fhdd31 = c_perceived_rent*female_hdd31 //perceived rent
replace rental_fgdd31 = c_perceived_rent*female_gdd31
replace female_rental = c_perceived_rent*female
replace hdd31_rental = c_perceived_rent*hdd_31_che
replace gdd31_rental = c_perceived_rent*gdd_31_che

reghdfe ln_homelabor hdd_31_che female_hdd31 rental_fhdd31 gdd_31_che female_gdd31 rental_fgdd31 perceived_rent female_rental hdd31_rental gdd31_rental pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

//# Barriers to adaptation
**Structural mechanism
*Marital status
g married = (marital>=2 & marital<=3) //in marriage
g married_mono = (marital == 2)
g married_poly = (marital == 3) 
g seperated = (marital>=4 & marital<=6)
g unmarried = (marital==1)

g unmarried_fhdd31 = c_unmarried*female_hdd31
g unmarried_fgdd31 = c_unmarried*female_gdd31
g married_poly_fhdd31 = c_married_poly*female_hdd31
g married_poly_fgdd31 = c_married_poly*female_gdd31
g separated_fhdd31 = c_separated*female_hdd31
g separated_fgdd31 = c_separated*female_gdd31

g female_unmarried = c_unmarried*female
g female_married_poly = c_married_poly*female
g female_separated = c_separated*female
g hdd31_unmarried = c_unmarried*hdd_31_che
g gdd31_unmarried = c_unmarried*gdd_31_che
g hdd31_married_poly = c_married_poly*hdd_31_che
g gdd31_married_poly = c_married_poly*gdd_31_che
g hdd31_separated = c_separated*hdd_31_che
g gdd31_separated = c_separated*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 unmarried_fhdd31 married_poly_fhdd31 separated_fhdd31 gdd_31_che female_gdd31 unmarried_fgdd31 married_poly_fgdd31 separated_fgdd31 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd31_unmarried gdd31_unmarried hdd31_married_poly gdd31_married_poly hdd31_separated gdd31_separated pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

*Co-habiting
g hhspousal_fhdd31 = c_spousal_hh*female_hdd31
g hhspousal_fgdd31 = c_spousal_hh*female_gdd31
g female_hhspousal = c_spousal_hh*female
g hdd31_hhspousal = c_spousal_hh*hdd_31_che
g gdd31_hhspousal = c_spousal_hh*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 hhspousal_fhdd31 gdd_31_che female_gdd31 hhspousal_fgdd31 spousal_hh female_hhspousal hdd31_hhspousal gdd31_hhspousal pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

*Childcare
g childnum_fhdd31 = c_child_num*female_hdd31
g childnum_fgdd31 = c_child_num*female_gdd31
g female_childnum = c_child_num*female
g hdd31_childnum = c_child_num*hdd_31_che
g gdd31_childnum = c_child_num*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 childnum_fhdd31 gdd_31_che female_gdd31 childnum_fgdd31 child_num female_childnum hdd31_childnum gdd31_childnum pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if married == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 childnum_fhdd31 gdd_31_che female_gdd31 childnum_fgdd31 child_num female_childnum hdd31_childnum gdd31_childnum $controls if age_`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

g adults = home_size/(1+dependency_ratio)
g elder65 = adults*dependency_ratio-child15

g child15_rate = child15/adults
center child15_rate
g child15r_fhdd31 = c_child15_rate*female_hdd31
g child15r_fgdd31 = c_child15_rate*female_gdd31
g child15r_hdd31 = c_child15_rate*hdd_31_che
g child15r_gdd31 = c_child15_rate*gdd_31_che
g female_child15r = female*c_child15_rate

reghdfe lnland_yield hdd_31_che female_hdd31 child15r_fhdd31 gdd_31_che female_gdd31 child15r_fgdd31 child15_rate female_child15r child15r_hdd31 child15r_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if child_num == 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 child15r_fhdd31 gdd_31_che female_gdd31 child15r_fgdd31 child15_rate female_child15r child15r_hdd31 child15r_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if child_num >= 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 child15r_fhdd31 gdd_31_che female_gdd31 child15r_fgdd31 child15_rate female_child15r child15r_hdd31 child15r_gdd31 $controls if age_`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

g elder65_rate = elder65/adults
center elder65_rate
g elder65r_fhdd31 = c_elder65_rate*female_hdd31
g elder65r_fgdd31 = c_elder65_rate*female_gdd31
g elder65r_hdd31 = c_elder65_rate*hdd_31_che
g elder65r_gdd31 = c_elder65_rate*gdd_31_che
g female_elder65r = female*c_elder65_rate

reghdfe lnland_yield hdd_31_che female_hdd31 elder65r_fhdd31 gdd_31_che female_gdd31 elder65r_fgdd31 elder65_rate female_elder65r elder65r_hdd31 elder65r_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

center dependency_ratio
g depend_fhdd31 = c_dependency_ratio*female_hdd31
g depend_fgdd31 = c_dependency_ratio*female_gdd31
g depend_hdd31 = c_dependency_ratio*hdd_31_che
g depend_gdd31 = c_dependency_ratio*gdd_31_che
g female_depend = female*c_dependency_ratio

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 depend_fhdd31 gdd_31_che female_gdd31 depend_fgdd31 dependency_ratio female_depend depend_hdd31 depend_gdd31 $controls if age_`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

*Village-level marital norms
replace father_poly = father_descent*high_polygamous
replace mother_poly = mother_descent*high_polygamous
replace fpoly_fhdd31 = c_father_poly*female_hdd31
replace fpoly_fgdd31 = c_father_poly*female_gdd31
replace mpoly_fhdd31 = c_mother_poly*female_hdd31
replace mpoly_fgdd31 = c_mother_poly*female_gdd31
replace female_fpoly = c_father_poly*female
replace female_mpoly = c_mother_poly*female
replace hdd31_fpoly = c_father_poly*hdd_31_che
replace hdd31_mpoly = c_mother_poly*hdd_31_che
replace gdd31_fpoly = c_father_poly*gdd_31_che
replace gdd31_mpoly = c_mother_poly*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 fpoly_fhdd31 mpoly_fhdd31 gdd_31_che female_gdd31 fpoly_fgdd31 mpoly_fgdd31 father_descent high_polygamous father_poly female_fpoly female_mpoly hdd31_fpoly hdd31_mpoly gdd31_fpoly gdd31_mpoly pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

//Resource mechanism
**Household-level and EA-level aggregate gender-gap etimates
egen exten_dummy = rowtotal(exten_program exten_credit exten_advising)
replace exten_dummy = 1 if exten_dummy > 1
egen exten_service = rowtotal(exten_credit exten_advising)
replace exten_service = 1 if exten_service > 1

*extension
reghdfe exten_dummy female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(household_id zone#year) vce(cluster holder_id)
reghdfe exten_dummy female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(ea_id zone#year) vce(cluster holder_id)

*market
reghdfe market_control female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(household_id zone#year) vce(cluster holder_id)
reghdfe market_control female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(ea_id zone#year) vce(cluster holder_id)

*tenure
reghdfe parcel_owner female edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(household_id zone#year) vce(cluster holder_id)
reghdfe parcel_owner female edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(ea_id zone#year) vce(cluster holder_id)

reghdfe parcel_certified female edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(household_id zone#year) vce(cluster holder_id)
reghdfe parcel_certified female edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(ea_id zone#year) vce(cluster holder_id)

*machine
reghdfe machine_num female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(household_id zone#year) vce(cluster holder_id)
reghdfe machine_num female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* muslem orthodox protestant, absorb(ea_id zone#year) vce(cluster holder_id)

**# Access to advisory service (human capital)
*Plot level
replace exten_fhdd31 = c_exten_program*female_hdd31
replace exten_fgdd31 = c_exten_program*female_gdd31
replace female_exten = c_exten_program*female
replace hdd31_exten = c_exten_program*hdd_31_che
replace gdd31_exten = c_exten_program*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 exten_program female_exten hdd31_exten gdd31_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

replace exten_fhdd31 = c_exten_advising*female_hdd31
replace exten_fgdd31 = c_exten_advising*female_gdd31
replace female_exten = c_exten_advising*female
replace hdd31_exten = c_exten_advising*hdd_31_che
replace gdd31_exten = c_exten_advising*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 exten_advising female_exten hdd31_exten gdd31_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

replace exten_fhdd31 = c_exten_dummy*female_hdd31
replace exten_fgdd31 = c_exten_dummy*female_gdd31
replace female_exten = c_exten_dummy*female
replace hdd31_exten = c_exten_dummy*hdd_31_che
replace gdd31_exten = c_exten_dummy*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 exten_dummy female_exten hdd31_exten gdd31_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 exten_dummy female_exten hdd31_exten gdd31_exten $controls if married == 1 & dependency_ratio > 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 exten_dummy female_exten hdd31_exten gdd31_exten $controls if parea_q`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 exten_dummy female_exten hdd31_exten gdd31_exten $controls if prod_q`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 exten_dummy female_exten hdd31_exten gdd31_exten $controls if age_`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

*District level
bysort zone year: egen zone_fexten = sum(exten_female)
bysort zone year: egen zone_mexten = sum(exten_male)

replace zone_extengap = zone_mexten/zone_male-zone_fexten/zone_female
replace exten_fhdd31 = c_zone_extengap*female_hdd31
replace exten_fgdd31 = c_zone_extengap*female_gdd31
replace female_exten = c_zone_extengap*female
replace hdd31_exten = c_zone_extengap*hdd_31_che
replace gdd31_exten = c_zone_extengap*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 female_exten hdd31_exten gdd31_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster zone)

**# Intra-household bargaining power
*Control over market earning(financial agency)
replace market_fhdd31 = c_market_control*female_hdd31
replace market_fgdd31 = c_market_control*female_gdd31
replace female_market = c_market_control*female
replace hdd31_market = c_market_control*hdd_31_che
replace gdd31_market = c_market_control*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 market_fhdd31 gdd_31_che female_gdd31 market_fgdd31 market_control female_market hdd31_market gdd31_market pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 market_fhdd31 gdd_31_che female_gdd31 market_fgdd31 market_control female_market hdd31_market gdd31_market $controls if married == 1 & dependency_ratio > 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_31_che female_hdd31 market_fhdd31 gdd_31_che female_gdd31 market_fgdd31 market_control female_market hdd31_market gdd31_market $controls if parea_q`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 market_fhdd31 gdd_31_che female_gdd31 market_fgdd31 market_control female_market hdd31_market gdd31_market $controls if prod_q`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 market_fhdd31 gdd_31_che female_gdd31 market_fgdd31 market_control female_market hdd31_market gdd31_market $controls if age_`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

*District level
replace zone_marketgap = zone_mmarket/zone_male-zone_fmarket/zone_female
replace market_fhdd31 = c_zone_marketgap*female_hdd31
replace market_fgdd31 = c_zone_marketgap*female_gdd31
replace female_market = c_zone_marketgap*female
replace hdd31_market = c_zone_marketgap*hdd_31_che
replace gdd31_market = c_zone_marketgap*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 market_fhdd31 gdd_31_che female_gdd31 market_fgdd31 female_market hdd31_market gdd31_market pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster zone)

**# Land ownership(secure property/tenure right)
*Plot level
replace property_fhdd31 = c_parcel_owner*female_hdd31
replace property_fgdd31 = c_parcel_owner*female_gdd31
replace female_property = c_parcel_owner*female
replace hdd31_property = c_parcel_owner*hdd_31_che
replace gdd31_property = c_parcel_owner*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 property_fhdd31 gdd_31_che female_gdd31 property_fgdd31 parcel_owner female_property hdd31_property gdd31_property pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 property_fhdd31 gdd_31_che female_gdd31 property_fgdd31 parcel_owner female_property hdd31_property gdd31_property $controls if married == 1 & dependency_ratio > 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_31_che female_hdd31 property_fhdd31 gdd_31_che female_gdd31 property_fgdd31 parcel_owner female_property hdd31_property gdd31_property $controls if parea_q`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 property_fhdd31 gdd_31_che female_gdd31 property_fgdd31 parcel_owner female_property hdd31_property gdd31_property $controls if prod_q`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 property_fhdd31 gdd_31_che female_gdd31 property_fgdd31 parcel_owner female_property hdd31_property gdd31_property $controls if age_`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

replace certified_fhdd31 = c_parcel_certified*female_hdd31
replace certified_fgdd31 = c_parcel_certified*female_gdd31
replace female_certified = c_parcel_certified*female
replace hdd31_certified = c_parcel_certified*hdd_31_che
replace gdd31_certified = c_parcel_certified*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 certified_fhdd31 gdd_31_che female_gdd31 certified_fgdd31 parcel_certified female_certified hdd31_certified gdd31_certified pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 certified_fhdd31 gdd_31_che female_gdd31 certified_fgdd31 parcel_certified female_certified hdd31_certified gdd31_certified $controls if married == 1 & dependency_ratio > 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

*District level
replace zone_landgap = zone_mland/zone_male-zone_fland/zone_female
replace property_fhdd31 = c_zone_landgap*female_hdd31
replace property_fgdd31 = c_zone_landgap*female_gdd31
replace female_property = c_zone_landgap*female
replace hdd31_property = c_zone_landgap*hdd_31_che
replace gdd31_property = c_zone_landgap*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 property_fhdd31 gdd_31_che female_gdd31 property_fgdd31 female_property hdd31_property gdd31_property pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster zone)

replace zone_certigap = zone_mcerti/zone_male-zone_fcerti/zone_female
replace certified_fhdd31 = c_zone_certigap*female_hdd31
replace certified_fgdd31 = c_zone_certigap*female_gdd31
replace female_certified = c_zone_certigap*female
replace hdd31_certified = c_zone_certigap*hdd_31_che
replace gdd31_certified = c_zone_certigap*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 certified_fhdd31 gdd_31_che female_gdd31 certified_fgdd31 female_certified hdd31_certified gdd31_certified pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster zone)

**# Farming machinery (physical capital/technology)
replace machine_fhdd31 = c_machine_num*female_hdd31
replace machine_fgdd31 = c_machine_num*female_gdd31
replace female_machine = c_machine_num*female
replace hdd31_machine = c_machine_num*hdd_31_che
replace gdd31_machine = c_machine_num*gdd_31_che

reghdfe lnland_yield hdd_31_che female_hdd31 machine_fhdd31 gdd_31_che female_gdd31 machine_fgdd31 machine_num female_machine hdd31_machine gdd31_machine pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

reghdfe lnland_yield hdd_31_che female_hdd31 machine_fhdd31 gdd_31_che female_gdd31 machine_fgdd31 machine_num female_machine hdd31_machine gdd31_machine $controls if married == 1 & dependency_ratio > 0, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_31_che female_hdd31 machine_fhdd31 gdd_31_che female_gdd31 machine_fgdd31 machine_num female_machine hdd31_machine gdd31_machine $controls if parea_q`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 machine_fhdd31 gdd_31_che female_gdd31 machine_fgdd31 machine_num female_machine hdd31_machine gdd31_machine $controls if prod_q`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_31_che female_hdd31 machine_fhdd31 gdd_31_che female_gdd31 machine_fgdd31 machine_num female_machine hdd31_machine gdd31_machine $controls if age_`i' == 1, absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
}

//# Future projection
**Plot-level projection under SSP-RCP scenarios
reghdfe lnland_yield female_hdd31 male_hdd31 female_gdd31 male_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_110, xb
forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_2`i'0
    replace male_hdd31 = male_hdd31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
    replace male_gdd31 = male_gdd31_2`i'0
	predict landyield_2`i'0, xb
}
forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_5`i'0
    replace male_hdd31 = male_hdd31_5`i'0
	replace female_gdd31 = female_gdd31_5`i'0
    replace male_gdd31 = male_gdd31_5`i'0
	predict landyield_5`i'0, xb
}

replace female_hdd31 = female_hdd31_origin
replace male_hdd31 = male_hdd31_origin
replace female_gdd31 = female_gdd31_origin
replace male_gdd31 = male_gdd31_origin

forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_2`i'0
    replace male_hdd31 = male_hdd31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
    replace male_gdd31 = male_gdd31_2`i'0
	replace pr = pr_2`i'0
	replace pr2 = pr_2`i'0^2
	replace ws = ws_2`i'0
	replace ws2 = ws_2`i'0^2
	replace sr = sr_2`i'0
	replace sr2 = sr_2`i'0^2
	replace age = age*age_2`i'0
	replace age = 75 if age > 75
	predict landyield_multi_2`i'0, xb
}

replace age = age_origin

forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_5`i'0
    replace male_hdd31 = male_hdd31_5`i'0
	replace female_gdd31 = female_gdd31_5`i'0
    replace male_gdd31 = male_gdd31_5`i'0
	replace pr = pr_5`i'0
	replace pr2 = pr_5`i'0^2
	replace ws = ws_5`i'0
	replace ws2 = ws_5`i'0^2
	replace sr = sr_5`i'0
	replace sr2 = sr_5`i'0^2
	replace age = age*age_5`i'0
	replace age = 75 if age > 75
	predict landyield_multi_5`i'0, xb
}

replace female_hdd31 = female_hdd31_origin
replace male_hdd31 = male_hdd31_origin
replace female_gdd31 = female_gdd31_origin
replace male_gdd31 = male_gdd31_origin
replace pr = pr_origin
replace pr2 = pr_origin^2
replace ws = ws_origin
replace ws2 = ws_origin^2
replace sr = sr_origin
replace sr2 = sr_origin^2
replace age = age_origin

reghdfe lnland_yield female_hdd31 male_hdd31 female_gdd31 male_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if joint_decision == 0 [pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_joint_110, xb
forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_2`i'0
    replace male_hdd31 = male_hdd31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
    replace male_gdd31 = male_gdd31_2`i'0
	predict landyield_joint_2`i'0, xb
}

replace female_hdd31 = female_hdd31_origin
replace male_hdd31 = male_hdd31_origin
replace female_gdd31 = female_gdd31_origin
replace male_gdd31 = male_gdd31_origin

reghdfe lnland_yield female_hdd31 male_hdd31 female_gdd31 male_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if spouse_joint == 0 [pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_spouse_110, xb
forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_2`i'0
    replace male_hdd31 = male_hdd31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
    replace male_gdd31 = male_gdd31_2`i'0
	predict landyield_spouse_2`i'0, xb
}

replace female_hdd31 = female_hdd31_origin
replace male_hdd31 = male_hdd31_origin
replace female_gdd31 = female_gdd31_origin
replace male_gdd31 = male_gdd31_origin

reghdfe lnland_yield female_hdd31 male_hdd31 female_gdd31 male_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if spousal_hh == 0 [pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_spouhh_110, xb
forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_2`i'0
    replace male_hdd31 = male_hdd31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
    replace male_gdd31 = male_gdd31_2`i'0
	predict landyield_spouhh_2`i'0, xb
}

replace female_hdd31 = female_hdd31_origin
replace male_hdd31 = male_hdd31_origin
replace female_gdd31 = female_gdd31_origin
replace male_gdd31 = male_gdd31_origin

reghdfe lnland_yield female_hdd31 male_hdd31 female_gdd31 male_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if soil_fertility_pca <= 0.473 [pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_soil_110, xb
forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_2`i'0
    replace male_hdd31 = male_hdd31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
    replace male_gdd31 = male_gdd31_2`i'0
	predict landyield_soil_2`i'0, xb
}

replace female_hdd31 = female_hdd31_origin
replace male_hdd31 = male_hdd31_origin
replace female_gdd31 = female_gdd31_origin
replace male_gdd31 = male_gdd31_origin

reghdfe lnland_yield female_hdd31 male_hdd31 female_gdd31 male_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if parcel_owner == 0|parcel_certified == 0 [pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_tenure_110, xb
forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_2`i'0
    replace male_hdd31 = male_hdd31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
    replace male_gdd31 = male_gdd31_2`i'0
	predict landyield_tenure_2`i'0, xb
}

replace female_hdd31 = female_hdd31_origin
replace male_hdd31 = male_hdd31_origin
replace female_gdd31 = female_gdd31_origin
replace male_gdd31 = male_gdd31_origin

reghdfe lnland_yield female_hdd31 male_hdd31 female_gdd31 male_gdd31 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if (parea_q1|parea_q2|parea_q3|parea_q4|parea_q5) == 1 [pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_pareaq_110, xb
forvalues i = 2/9{
	replace female_hdd31 = female_hdd31_2`i'0
    replace male_hdd31 = male_hdd31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
    replace male_gdd31 = male_gdd31_2`i'0
	predict landyield_pareaq_2`i'0, xb
}

replace female_hdd31 = female_hdd31_origin
replace male_hdd31 = male_hdd31_origin
replace female_gdd31 = female_gdd31_origin
replace male_gdd31 = male_gdd31_origin

estpost ttest landyield_110 landyield_220-landyield_590 landyield_multi_220-landyield_multi_590, by(sex)
esttab . using mean_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

estpost ttest landyield_joint_220-landyield_joint_290 landyield_spouse_220-landyield_spouse_290 landyield_spouhh_220-landyield_spouhh_290, by(sex)
esttab . using migration_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

estpost ttest landyield_pareaq_220-landyield_pareaq_290 landyield_tenure_220-landyield_tenure_290, by(sex)
esttab . using consolidate_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

estpost ttest landyield_soil_220-landyield_soil_290, by(sex)
esttab . using productivity_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

forvalues i = 2/9{
	replace dlandyield_2`i'0 = (exp(landyield_2`i'0-landyield_110)-1)*100
}
forvalues i = 2/9{
	replace dlandyield_5`i'0 = (exp(landyield_5`i'0-landyield_110)-1)*100
}
forvalues i = 2/9{
	replace dlandyield_multi_2`i'0 = (exp(landyield_multi_2`i'0-landyield_110)-1)*100
}
forvalues i = 2/9{
	replace dlandyield_multi_5`i'0 = (exp(landyield_multi_5`i'0-landyield_110)-1)*100
}

forvalues i = 2/9{
	replace dlandyield_joint_2`i'0 = (exp(landyield_joint_2`i'0-landyield_joint_110)-1)*100
}
forvalues i = 2/9{
	replace dlandyield_spouse_2`i'0 = (exp(landyield_spouse_2`i'0-landyield_spouse_110)-1)*100
}
forvalues i = 2/9{
	replace dlandyield_tenure_2`i'0 = (exp(landyield_tenure_2`i'0-landyield_tenure_110)-1)*100
}
estpost tabstat dlandyield_220-dlandyield_590 dlandyield_multi_220-dlandyield_multi_590, by(sex) stat(mean p50 p5 p95) columns(statistics)
esttab . using diff_project.csv, replace cell("mean(fmt(2)) p50(fmt(2)) p5(fmt(2)) p95(fmt(2))")

estpost tabstat dlandyield_joint_220-dlandyield_joint_290 dlandyield_spouse_220-dlandyield_spouse_290, by(sex) stat(mean p50 p5 p95) columns(statistics)
esttab . using diff_project_migration.csv, replace cell("mean(fmt(2)) p50(fmt(2)) p5(fmt(2)) p95(fmt(2))")

estpost tabstat dlandyield_tenure_220-dlandyield_tenure_290, by(sex) stat(mean p50 p5 p95) columns(statistics)
esttab . using diff_project_consolidate.csv, replace cell("mean(fmt(2)) p50(fmt(2)) p5(fmt(2)) p95(fmt(2))")

**# Simulation of women's empowerment
*extension
reghdfe lnland_yield hdd_31_che female_hdd31 exten_fhdd31 gdd_31_che female_gdd31 exten_fgdd31 exten_dummy female_exten hdd31_exten gdd31_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_exten_110, xb
forvalues i = 2/9{
	replace hdd_31_che = hdd_31_2`i'0
	replace female_hdd31 = female_hdd31_2`i'0
	replace gdd_31_che = gdd_31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
	predict landyield_exten_2`i'0, xb
}

replace hdd_31_che = hdd_31_origin
replace female_hdd31 = female_hdd31_origin
replace gdd_31_che = gdd_31_origin
replace female_gdd31 = female_gdd31_origin

*market
reghdfe lnland_yield hdd_31_che female_hdd31 market_fhdd31 gdd_31_che female_gdd31 market_fgdd31 market_control female_market hdd31_market gdd31_market pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_mark_110, xb
forvalues i = 2/9{
	replace hdd_31_che = hdd_31_2`i'0
	replace female_hdd31 = female_hdd31_2`i'0
	replace gdd_31_che = gdd_31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
	predict landyield_mark_2`i'0, xb
}

replace hdd_31_che = hdd_31_origin
replace female_hdd31 = female_hdd31_origin
replace gdd_31_che = gdd_31_origin
replace female_gdd31 = female_gdd31_origin

*property
reghdfe lnland_yield hdd_31_che female_hdd31 property_fhdd31 gdd_31_che female_gdd31 property_fgdd31 parcel_owner female_property hdd31_property gdd31_property pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_prop_110, xb
forvalues i = 2/9{
	replace hdd_31_che = hdd_31_2`i'0
	replace female_hdd31 = female_hdd31_2`i'0
	replace gdd_31_che = gdd_31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
	predict landyield_prop_2`i'0, xb
}

replace hdd_31_che = hdd_31_origin
replace female_hdd31 = female_hdd31_origin
replace gdd_31_che = gdd_31_origin
replace female_gdd31 = female_gdd31_origin

*machine
reghdfe lnland_yield hdd_31_che female_hdd31 machine_fhdd31 gdd_31_che female_gdd31 machine_fgdd31 machine_num female_machine hdd31_machine gdd31_machine pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(household_id zone#year female#main_crop female#soil_type) vce(cluster household_id)
predict landyield_mach_110, xb
forvalues i = 2/9{
	replace hdd_31_che = hdd_31_2`i'0
	replace female_hdd31 = female_hdd31_2`i'0
	replace gdd_31_che = gdd_31_2`i'0
	replace female_gdd31 = female_gdd31_2`i'0
	predict landyield_mach_2`i'0, xb
}

replace hdd_31_che = hdd_31_origin
replace female_hdd31 = female_hdd31_origin
replace gdd_31_che = gdd_31_origin
replace female_gdd31 = female_gdd31_origin

estpost ttest landyield_exten_110 landyield_exten_220-landyield_exten_290 ///
landyield_mark_110 landyield_mark_220-landyield_mark_290 ///
landyield_prop_110 landyield_prop_220-landyield_prop_290 ///
landyield_mach_110 landyield_mach_220-landyield_mach_290 ///
, by(sex)
esttab . using empower_project.csv, replace cells("mu_1(fmt(4)) mu_2(fmt(4)) b(fmt(4)) se(fmt(4))")

forvalues i = 2/9{
	replace dlandyield_exten_2`i'0 = (exp(landyield_exten_2`i'0-landyield_exten_110)-1)*100
}
forvalues i = 2/9{
	replace dlandyield_mark_2`i'0 = (exp(landyield_mark_2`i'0-landyield_mark_110)-1)*100
}
forvalues i = 2/9{
	replace dlandyield_prop_2`i'0 = (exp(landyield_prop_2`i'0-landyield_prop_110)-1)*100
}
forvalues i = 2/9{
	replace dlandyield_mach_2`i'0 = (exp(landyield_mach_2`i'0-landyield_mach_110)-1)*100
}
estpost tabstat dlandyield_exten* dlandyield_mark* dlandyield_prop* dlandyield_mach*, by(sex) stat(mean p50 p5 p95) columns(statistics)
esttab . using empower_project_diff.csv, replace cell("mean(fmt(2)) p50(fmt(2)) p5(fmt(2)) p95(fmt(2))")