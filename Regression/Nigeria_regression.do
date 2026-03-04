cd "D:\climate_gender\Nigeria\output_figure"

**Summary statistics
estpost summarize tfp_cd intercrop crop_diversity maize sorghum millet parea labor_mday dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection soil_limiting_z female age edu_primary married married_poly spousal_hh have_child separated joint_decision livestock nonfarm_work female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio
esttab using summary.csv, cells("mean(fmt(2)) sd(fmt(2)) count") noobs replace //overall indicator

estpost ttest tfp_cd intercrop crop_diversity maize sorghum millet parea labor_mday dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection soil_limiting_z age edu_primary married married_poly spousal_hh have_child separated joint_decision livestock nonfarm_work female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, by(male)
esttab . using uncon_balance.csv, cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2)) p(fmt(2))") //unconditional difference

**Balance tests
*conditional difference(within variation)
foreach var in dist_hh plot_slope plot_elev plot_wet soil_fertility_pca erosion_protection{
	reghdfe `var' female age edu_primary married female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(ea state#year) vce(cluster ea)
}
reghdfe soil_limiting_z female age edu_primary married female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(state#year) vce(cluster state) //geo-data

foreach var in nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts toxicity workability{
	reghdfe `var' female age edu_primary married female_hhead fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(ea state#year) vce(cluster ea)	
}

*balance tests for predetermined gender(selection)
reghdfe female dist_hh plot_slope plot_elev plot_wet nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts workability erosion_protection c.soil_limiting#i.year, absorb(hhid state#year) vce(cluster hhid)

global controls "pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio"

//Dep.Var:Land Yield
xtset pid_ year
**Threshod validation
reghdfe lnland_yield gdd_33_che hdd_33_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year main_crop soil_type) vce(cluster hhid)

reghdfe lnland_yield gdd_34_che hdd_34_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year main_crop soil_type) vce(cluster hhid)

reghdfe lnland_yield gdd_35_che hdd_35_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year main_crop soil_type) vce(cluster hhid)

**# Gender-yield disparity estimates
replace female_hdd33 = female*hdd_33_che
replace female_gdd33 = female*gdd_33_che

reghdfe lnland_yield hdd_33_che female_hdd33 gdd_33_che female_gdd33 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

replace female_hdd34 = female*hdd_34_che
replace female_gdd34 = female*gdd_34_che
replace female_hddlag = female*hdd_34_lag
replace female_gddlag = female*gdd_34_lag

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che hdd_34_lag female_hdd34 female_hddlag gdd_34_che gdd_34_lag female_gdd34 female_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //lagged temperature: experience & adaptation

replace female_hdd35 = female*hdd_35_che
replace female_gdd35 = female*gdd_35_che

reghdfe lnland_yield hdd_35_che female_hdd35 gdd_35_che female_gdd35 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**Heterogeneity analysis
*Pre-shock exposure to temperatures
reghdfe lnland_yield hdd_34_che hdd_34_lag female_hdd34 c.hdd_34_lag#c.female_hdd34 female_hddlag gdd_34_che gdd_34_lag female_gdd34 c.gdd_34_lag#c.female_gdd34 female_gddlag c.hdd_34_che#c.hdd_34_lag c.gdd_34_che#c.gdd_34_lag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

*Productivity quantiles
egen prod_quantile = xtile(lnland_yield), nq(5) by(year)
forvalues i = 1/5{
	g prod_q`i' = (prod_quantile == `i')
}
drop prod_quantile
forvalues i = 1/5{
	g prodq`i'_fhdd34 = prod_q`i'*female_hdd34
	g prodq`i'_fgdd34 = prod_q`i'*female_gdd34
	g prodq`i'_hdd34 = prod_q`i'*hdd_34_che
	g prodq`i'_gdd34 = prod_q`i'*gdd_34_che
	g female_prodq`i' = female*prod_q`i'
}
reghdfe lnland_yield prodq*_hdd34 prodq*_fhdd34 prodq*_gdd34 prodq*_fgdd34 female_prodq* prod_q* pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

*Cropping pattern & intra-crop analysis
g female_intercrop = female*intercrop
g intercrop_fhdd34 = intercrop*female_hdd34
g intercrop_fgdd34 = intercrop*female_gdd34
g intercrop_hdd34 = intercrop*hdd_34_che
g intercrop_gdd34 = intercrop*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 intercrop_fhdd34 intercrop_hdd34 gdd_34_che female_gdd34 intercrop_fgdd34 intercrop_gdd34 female_intercrop intercrop pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
lincom female_hdd34+intercrop_fhdd34

g female_diversity = female*crop_diversity
g diversity_fhdd34 = crop_diversity*female_hdd34
g diversity_fgdd34 = crop_diversity*female_gdd34
g diversity_hdd34 = crop_diversity*hdd_34_che
g diversity_gdd34 = crop_diversity*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 diversity_fhdd34 diversity_hdd34 gdd_34_che female_gdd34 diversity_fgdd34 diversity_gdd34 female_diversity crop_diversity pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

local crop "cassava sorghum maize millet yam cowpea rice"
replace other_crop = 1
foreach i of local crop {
	g `i'_fhdd34 = `i'*female_hdd34
	g `i'_fgdd34 = `i'*female_gdd34
	g `i'_hdd34 = `i'*hdd_34_che
	g `i'_gdd34 = `i'*gdd_34_che
	replace other_crop = other_crop-`i'
}
g other_fhdd34 = other_crop*female_hdd34
g other_fgdd34 = other_crop*female_gdd34
g other_hdd34 = other_crop*hdd_34_che
g other_gdd34 = other_crop*gdd_34_che

reghdfe lnland_yield cassava_hdd34 sorghum_hdd34 maize_hdd34 millet_hdd34 yam_hdd34 cowpea_hdd34 rice_hdd34 other_hdd34 cassava_fhdd34 sorghum_fhdd34 maize_fhdd34 millet_fhdd34 yam_fhdd34 cowpea_fhdd34 rice_fhdd34 other_fhdd34 cassava_gdd34 sorghum_gdd34 maize_gdd34 millet_gdd34 yam_gdd34 cowpea_gdd34 rice_gdd34 other_gdd34 cassava_fgdd34 sorghum_fgdd34 maize_fgdd34 millet_fgdd34 yam_fgdd34 cowpea_fgdd34 rice_fgdd34 other_fgdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //care-intensive/saving crops

*Farm scale (plot-size decile)
egen parea_quantile = xtile(parea), nq(10) by(year)
forvalues i = 1/10{
	g parea_q`i' = (parea_quantile == `i')
}
drop parea_quantile
bysort ea_id household year: egen farm_size = sum(parea)
bysort country ea hhid year: egen farm_size = sum(parea)

forvalues i = 1/10{
	g pareaq`i'_fhdd34 = parea_q`i'*female_hdd34
	g pareaq`i'_fgdd34 = parea_q`i'*female_gdd34
	g pareaq`i'_hdd34 = parea_q`i'*hdd_34_che
	g pareaq`i'_gdd34 = parea_q`i'*gdd_34_che
	g female_pareaq`i' = female*parea_q`i'
}
reghdfe lnland_yield pareaq*_hdd34 pareaq*_fhdd34 pareaq*_gdd34 pareaq*_fgdd34 female_pareaq* parea_q* pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

*Plot location (travel costs/distance)
local dist "5 3.5 1.5 1 0.5"
foreach i of local dist{
	reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if dist_hh <= `i', absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

*Age cohort (generation)
g age_1 = (age < 30) //1980s-later
g age_2 = (age < 40 & age >= 30) //1970s
g age_3 = (age < 50 & age >= 40) //1960s
g age_4 = (age < 60 & age >= 50) //1950s
g age_5 = (age >= 60) //1950s-earlier

forvalues i = 1/5{
    reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if age_`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

*Education (return)
reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if edu_primary == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if edu_primary == 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

*Religion (culture)
g islam_fhdd34 = islam*female_hdd34
g chris_fhdd34 = christianity*female_hdd34
g other_relig_fhdd34 = other_relig*female_hdd34

local var "islam christianity other_relig"
foreach i of local var{
	g `i'_hdd34 = `i'*hdd_34_che
	g `i'_gdd34 = `i'*gdd_34_che
	g female_`i' = `i'*female
}

reghdfe lnland_yield islam_hdd34 christianity_hdd34 other_relig_hdd34 islam_fhdd34 christianity_fhdd34 other_relig_fhdd34 islam_gdd34 christianity_gdd34 other_relig_gdd34 islam_fgdd34 christianity_fgdd34 other_relig_fgdd34 islam christianity pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

*Female head (hh structure)
g fhead_hdd34 = female_hhead*hdd_34_che
g fhead_gdd34 = female_hhead*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 fhead_hdd34 gdd_34_che female_gdd34 fhead_gdd34 female_hhead pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

g female_fhead = female*female_hhead
g fhead_fhdd34 = female_hdd34*female_hhead
g fhead_fgdd34 = female_gdd34*female_hhead

reghdfe lnland_yield hdd_34_che female_hdd34 fhead_fhdd34 fhead_hdd34 gdd_34_che female_gdd34 fhead_fgdd34 fhead_gdd34 female_hhead female_fhead pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
lincom female_hdd34+fhead_fhdd34

*Relationship to household head (status)
collect create table
collect:tab relation_hhead //relationship of plot manager to household head(% of plots)
collect export "result.xlsx", replace

g junior_male = (relation_hhead != 1 & female == 0)
g junior_female = (relation_hhead != 1 & relation_hhead != 2 & female == 1)
local var "whead wife junior_male junior_female"
foreach i of local var{
	g `i'_hdd34 = `i'*hdd_34_che
	g `i'_gdd34 = `i'*gdd_34_che
} //gender & generation
rename junior_male_* mjunior_*
rename junior_female_* fjunior_*

reghdfe lnland_yield hdd_34_che whead_hdd34 wife_hdd34 mjunior_hdd34 fjunior_hdd34 gdd_34_che whead_gdd34 wife_gdd34 mjunior_gdd34 fjunior_gdd34 whead wife junior_male pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //hh status & position

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if machine < 2250, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //large capital goods, assets, and cooperative behaviors

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if machine >= 2250, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //difficult to sub-divide

*joint decision-making with primary manager
g joint_hdd34 = joint_decision*hdd_34_che
g joint_gdd34 = joint_decision*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 joint_hdd34 gdd_34_che female_gdd34 joint_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

g female_joint = female*joint_decision
g joint_fhdd34 = female_hdd34*joint_decision
g joint_fgdd34 = female_gdd34*joint_decision

reghdfe lnland_yield hdd_34_che female_hdd34 joint_fhdd34 joint_hdd34 gdd_34_che female_gdd34 joint_fgdd34 joint_gdd34 female_joint pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
lincom female_hdd34+joint_fhdd34

**Sample restriction for validating "Gender"
*wife/mother roles for robustness checks
reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if married == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if spousal_hh == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if child_num >= 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if dependency_ratio > 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**Agricultural TFP
*conventional C-D
reghdfe lnland_yield lnland_labor lnland_input, absorb(hhid year) vce(cluster hhid)
replace l = _b[lnland_labor]
replace i = _b[lnland_input]
replace tfp_cd_con = lnland_yield-l*lnland_labor-i*lnland_input
*translog C-D
reghdfe lnland_yield lnland_labor lnland_input lnland_labor_2 lnland_input_2 lnland_labor_input, absorb(hhid year) vce(cluster hhid)
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
xtset id_ year
**Threshod validation
reghdfe tfp_cd gdd_33_che hdd_33_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year main_crop soil_type) vce(cluster hhid)

reghdfe tfp_cd gdd_34_che hdd_34_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year main_crop soil_type) vce(cluster hhid)

reghdfe tfp_cd gdd_35_che hdd_35_che pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year main_crop soil_type) vce(cluster hhid)

**# Gender-TFP disparity estimates
reghdfe tfp_cd hdd_33_che female_hdd33 gdd_33_che female_gdd33 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe tfp_cd hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe tfp_cd hdd_34_che hdd_34_lag female_hdd34 female_hddlag gdd_34_che gdd_34_lag female_gdd34 female_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //lagged temperature: experience & adaptation

reghdfe tfp_cd hdd_35_che female_hdd35 gdd_35_che female_gdd35 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

//Tempreture bins(3-degree bins (26-29 omitted))
**Number of days
replace female_d1720 = female*d_17_20
replace female_d2023 = female*d_20_23
replace female_d2326 = female*d_23_26
replace female_d2932 = female*d_29_32
replace female_d3235 = female*d_32_35
replace female_d35 = female*d_35

replace male_d1720 = male*d_17_20
replace male_d2023 = male*d_20_23
replace male_d2326 = male*d_23_26
replace male_d2932 = male*d_29_32
replace male_d3235 = male*d_32_35
replace male_d35 = male*d_35

reghdfe lnland_yield female_d1720 male_d1720 female_d2023 male_d2023 female_d2326 male_d2326 female_d2932 male_d2932 female_d3235 male_d3235 female_d35 male_d35 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) level(90)

reghdfe tfp_cd female_d1720 male_d1720 female_d2023 male_d2023 female_d2326 male_d2326 female_d2932 male_d2932 female_d3235 male_d3235 female_d35 male_d35 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) level(90)

//Degree-days
g female_d2629 = female*dd_26_29
g male_d2629 = male*dd_26_29

replace female_d1720 = female*dd_17_20
replace female_d2023 = female*dd_20_23
replace female_d2326 = female*dd_23_26
replace female_d2932 = female*dd_29_32
replace female_d3235 = female*dd_32_35
replace female_d35 = female*dd_35

replace male_d1720 = male*dd_17_20
replace male_d2023 = male*dd_20_23
replace male_d2326 = male*dd_23_26
replace male_d2932 = male*dd_29_32
replace male_d3235 = male*dd_32_35
replace male_d35 = male*dd_35

reghdfe lnland_yield female_d1720 male_d1720 female_d2023 male_d2023 female_d2326 male_d2326 female_d2629 male_d2629 female_d2932 male_d2932 female_d3235 male_d3235 female_d35 male_d35 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) level(90)

reghdfe tfp_cd female_d1720 male_d1720 female_d2023 male_d2023 female_d2326 male_d2326 female_d2629 male_d2629 female_d2932 male_d2932 female_d3235 male_d3235 female_d35 male_d35 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) level(90)

//Seasonal average temperature
replace group = 22
forvalues i = 1/20{
	replace group = 22+(`i'*0.5) if tmean >= 22+(`i'*0.5) & tmean < 23+(`i'*0.5)
} //non/semi-parametric regression with fixed effects
egen tmean_bin = mean(tmean),by(group)
egen flandyield_bin = mean(f_landyield),by(group)
egen mlandyield_bin = mean(m_landyield),by(group)

**Local polynomial(degree:2)
twoway (scatter mlandyield_bin tmean_bin, mlcolor("69 117 180%60") mfcolor(white) msize(medlarge)) (scatter flandyield_bin tmean_bin, mlcolor("215 48 39%60") mfcolor(white) msize(medlarge)) (lpolyci lnland_yield_hh tmean if female == 0, alwidth(none) lcolor("69 117 180") lwidth(thick) lp(dash) fcolor("69 117 180%60") fintensity(40) degree(2) level(90)) (lpolyci lnland_yield_hh tmean if female == 1, alwidth(none) lcolor("215 48 39") lwidth(thick) lp(dash) fcolor("215 48 39%60") fintensity(40) degree(2) level(90)), legend(off) xline(30, lp(dash) lc("69 117 180%40") lw(0.4)) xline(29, lp(dash) lc("215 48 39%40") lw(0.4)) graphregion(fcolor(white) lcolor(white)) xsize(4.5) ysize(6) yscale(r(-1.6 1.2)) ylabel(-1.6(0.4)1.2) xscale(r(23 31)) xlabel(23(2)31) xtitle(Seasonal Average Temperature (℃)) ytitle(Log change in Yield)

//# Robustness
**planting share
reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio portion_planted, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if portion_planted != 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //dropped 1206/11402 samples

**harvest completion
reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio harvest_complete, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if harvest_complete != 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //dropped 1878/11402 samples

**history & culture: variation across ethnic groups
encode ethnic_group, gen(ethnic_group_)
reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type ethnic_group_#year) vce(cluster hhid)

**(un)observed plot characteristics - soil quality
reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type c.soil_limiting#year) vce(cluster hhid) //geo-data of most-limiting indicator

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet nutrient_availability nutrient_retention rooting_conditions oxygen_availability excess_salts workability improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //use 6 soil-quality indicators

reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection organic_fertilizer age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //practices of organic fertilizer

**gender-plot characteristics interactions
reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh c.dist_hh#c.female plot_slope c.plot_slope#c.female plot_elev c.plot_elev#c.female plot_wet c.plot_wet#c.female soil_fertility_pca c.soil_fertility_pca#c.female improved irrigated crop_diversity erosion_protection c.erosion_protection#c.female age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**omitted variable bias: selection on unobservables
*residual deviation
reghdfe lnland_yield, absorb(hhid#indiv state#year female#main_crop female#soil_type) resid
predict lnland_yield_ind, resid
reghdfe lnland_yield, absorb(hhid state#year female#main_crop female#soil_type) resid
predict lnland_yield_hh, resid
reghdfe lnland_yield, absorb(ea state#year female#main_crop female#soil_type) resid
predict lnland_yield_ea, resid

drop _reghdfe_resid
twoway (kdensity lnland_yield_ind)(kdensity lnland_yield_hh)(kdensity lnland_yield_ea)

*Oster tests on unobservables
reghdfe lnland_yield hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
local r = e(r2)*1.3 //psacalc2 treating all parameters as nuisance but those in `absorb()`

psacalc2 delta female_hdd34, beta(0) rmax(`r') mcontrol(hdd_34_che gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock)
psacalc2 beta female_hdd34, delta(1) rmax(`r') mcontrol(hdd_34_che gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock)

//# Adaptation strategies
**Farm labor
reghdfe ln_labor hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe ln_labor female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe ln_homelabor hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe ln_homelabor female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe hirelabor_dummy hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe hirelabor_dummy female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**Farm input
reghdfe ln_input hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe ln_input female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**Seed purchase
reghdfe ln_seed hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe ln_seed female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**Pesticide purchase
reghdfe ln_pestherb hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe ln_pestherb female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**Crop diversity
reghdfe intercrop female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe crop_diversity female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**Fertilizer value
reghdfe ln_fertilizer hdd_34_che female_hdd34 gdd_34_che female_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe ln_fertilizer female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe organic_fertilizer female_hdd34 female_hddlag male_hdd34 male_hddlag female_gdd34 female_gddlag male_gdd34 male_gddlag pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

//# Barriers to adaptation
**Structural mechanism:
*Marital status
gen married = (marital <= 2)
gen married_mono = (marital == 1)
gen married_poly = (marital == 2)
gen separated = (marital>=4 & marital<=6)
gen unmarried = (marital==7)

g unmarried_fhdd34 = c_unmarried*female_hdd34
g unmarried_fgdd34 = c_unmarried*female_gdd34
g married_poly_fhdd34 = c_married_poly*female_hdd34
g married_poly_fgdd34 = c_married_poly*female_gdd34
g separated_fhdd34 = c_separated*female_hdd34
g separated_fgdd34 = c_separated*female_gdd34

g female_unmarried = c_unmarried*female
g female_married_poly = c_married_poly*female
g female_separated = c_separated*female
g hdd34_unmarried = c_unmarried*hdd_34_che
g gdd34_unmarried = c_unmarried*gdd_34_che
g hdd34_married_poly = c_married_poly*hdd_34_che
g gdd34_married_poly = c_married_poly*gdd_34_che
g hdd34_separated = c_separated*hdd_34_che
g gdd34_separated = c_separated*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 unmarried_fhdd34 married_poly_fhdd34 separated_fhdd34 gdd_34_che female_gdd34 unmarried_fgdd34 married_poly_fgdd34 separated_fgdd34 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd34_unmarried gdd34_unmarried hdd34_married_poly gdd34_married_poly hdd34_separated gdd34_separated pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 unmarried_fhdd34 married_poly_fhdd34 separated_fhdd34 gdd_34_che female_gdd34 unmarried_fgdd34 married_poly_fgdd34 separated_fgdd34 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd34_unmarried gdd34_unmarried hdd34_married_poly gdd34_married_poly hdd34_separated gdd34_separated $controls if joint_decision == 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //cooperation in polygynous households

reghdfe lnland_yield hdd_34_che female_hdd34 unmarried_fhdd34 married_poly_fhdd34 separated_fhdd34 gdd_34_che female_gdd34 unmarried_fgdd34 married_poly_fgdd34 separated_fgdd34 unmarried married_poly separated female_unmarried female_married_poly female_separated hdd34_unmarried gdd34_unmarried hdd34_married_poly gdd34_married_poly hdd34_separated gdd34_separated $controls if joint_decision == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //1255 samples remained

*Co-habiting
replace hhspousal_fhdd34 = c_spousal_hh*female_hdd34
replace hhspousal_fgdd34 = c_spousal_hh*female_gdd34
g female_hhspousal = c_spousal_hh*female
g hdd34_hhspousal = c_spousal_hh*hdd_34_che
g gdd34_hhspousal = c_spousal_hh*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 hhspousal_fhdd34 gdd_34_che female_gdd34 hhspousal_fgdd34 spousal_hh female_hhspousal hdd34_hhspousal gdd34_hhspousal pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

*Childcare
g childnum_fhdd34 = c_child_num*female_hdd34
g childnum_fgdd34 = c_child_num*female_gdd34
g female_childnum = c_child_num*female
g hdd34_childnum = c_child_num*hdd_34_che
g gdd34_childnum = c_child_num*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 childnum_fhdd34 gdd_34_che female_gdd34 childnum_fgdd34 child_num female_childnum hdd34_childnum gdd34_childnum pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if married == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 childnum_fhdd34 gdd_34_che female_gdd34 childnum_fgdd34 child_num female_childnum hdd34_childnum gdd34_childnum $controls if married == 1 & joint_decision == 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //cooperation for child

reghdfe lnland_yield hdd_34_che female_hdd34 childnum_fhdd34 gdd_34_che female_gdd34 childnum_fgdd34 child_num female_childnum hdd34_childnum gdd34_childnum $controls if married == 1 & joint_decision == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid) //1090 samples remained

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 childnum_fhdd34 gdd_34_che female_gdd34 childnum_fgdd34 child_num female_childnum hdd34_childnum gdd34_childnum $controls if age_`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

g adults = home_size/(1+dependency_ratio)
g elder65 = adults*dependency_ratio-child15

g child15_rate = child15/adults
center child15_rate
g child15r_fhdd34 = c_child15_rate*female_hdd34
g child15r_fgdd34 = c_child15_rate*female_gdd34
g child15r_hdd34 = c_child15_rate*hdd_34_che
g child15r_gdd34 = c_child15_rate*gdd_34_che
g female_child15r = female*c_child15_rate

reghdfe lnland_yield hdd_34_che female_hdd34 child15r_fhdd34 gdd_34_che female_gdd34 child15r_fgdd34 child15_rate female_child15r child15r_hdd34 child15r_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if child_num == 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 child15r_fhdd34 gdd_34_che female_gdd34 child15r_fgdd34 child15_rate female_child15r child15r_hdd34 child15r_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio if child_num >= 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 child15r_fhdd34 gdd_34_che female_gdd34 child15r_fgdd34 child15_rate female_child15r child15r_hdd34 child15r_gdd34 $controls if age_`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

g elder65_rate = elder65/adults
center elder65_rate
g elder65r_fhdd34 = c_elder65_rate*female_hdd34
g elder65r_fgdd34 = c_elder65_rate*female_gdd34
g elder65r_hdd34 = c_elder65_rate*hdd_34_che
g elder65r_gdd34 = c_elder65_rate*gdd_34_che
g female_elder65r = female*c_elder65_rate

reghdfe lnland_yield hdd_34_che female_hdd34 elder65r_fhdd34 gdd_34_che female_gdd34 elder65r_fgdd34 elder65_rate female_elder65r elder65r_hdd34 elder65r_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

center dependency_ratio
g depend_fhdd34 = c_dependency_ratio*female_hdd34
g depend_fgdd34 = c_dependency_ratio*female_gdd34
g depend_hdd34 = c_dependency_ratio*hdd_34_che
g depend_gdd34 = c_dependency_ratio*gdd_34_che
g female_depend = female*c_dependency_ratio

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 depend_fhdd34 gdd_34_che female_gdd34 depend_fgdd34 dependency_ratio female_depend depend_hdd34 depend_gdd34 $controls if age_`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

*Village-level labor market
replace rhire_gap = men_hire-women_hire
replace vhire_fhdd34 = rhire_gap*female_hdd34
replace vhire_fgdd34 = rhire_gap*female_gdd34
replace female_vhire = rhire_gap*female
replace hdd34_vhire = rhire_gap*hdd_34_che
replace gdd34_vhire = rhire_gap*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 vhire_fhdd34 gdd_34_che female_gdd34 vhire_fgdd34 rhire_gap female_vhire hdd34_vhire gdd34_vhire pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

**Resource mechanism
*Household-level and EA-level aggregate gender-gap etimates
*extension
reghdfe exten_dummy female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(hhid state#year) vce(cluster hhid#indiv)
reghdfe exten_dummy female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(ea state#year) vce(cluster hhid#indiv)

*market
reghdfe market_control female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(hhid state#year) vce(cluster hhid#indiv)
reghdfe market_control female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(ea state#year) vce(cluster hhid#indiv)

*tenure
reghdfe parcel_owner female edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(hhid state#year) vce(cluster hhid#indiv)
reghdfe parcel_owner female edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(ea state#year) vce(cluster hhid#indiv)

reghdfe parcel_certified female edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(hhid state#year) vce(cluster hhid#indiv)
reghdfe parcel_certified female edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(ea state#year) vce(cluster hhid#indiv)

*machine
reghdfe ln_machine female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(hhid state#year) vce(cluster hhid#indiv)
reghdfe ln_machine female parcel_owner edu_primary unmarried married_poly separated have_child age_1-age_5 parea_q* islam christianity, absorb(ea state#year) vce(cluster hhid#indiv)

**# Access to advisory service (human capital)
*Plot level
replace exten_fhdd34 = c_exten_dummy*female_hdd34
replace exten_fgdd34 = c_exten_dummy*female_gdd34
replace female_exten = c_exten_dummy*female
replace hdd34_exten = c_exten_dummy*hdd_34_che
replace gdd34_exten = c_exten_dummy*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 exten_dummy female_exten hdd34_exten gdd34_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 exten_dummy female_exten hdd34_exten gdd34_exten $controls if married == 1 & dependency_ratio > 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 exten_dummy female_exten hdd34_exten gdd34_exten $controls if parea_q`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 exten_dummy female_exten hdd34_exten gdd34_exten $controls if prod_q`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 exten_dummy female_exten hdd34_exten gdd34_exten $controls if age_`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

replace exten_fhdd34 = c_exten_frequency*female_hdd34
replace exten_fgdd34 = c_exten_frequency*female_gdd34
replace female_exten = c_exten_frequency*female
replace hdd34_exten = c_exten_frequency*hdd_34_che
replace gdd34_exten = c_exten_frequency*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 exten_frequency female_exten hdd34_exten gdd34_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 exten_frequency female_exten hdd34_exten gdd34_exten $controls if married == 1 & dependency_ratio > 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

*District level
bysort state year: egen state_fexten = sum(exten_female)
bysort state year: egen state_mexten = sum(exten_male)

replace state_extengap = state_mexten/state_male-state_fexten/state_female
replace exten_fhdd34 = c_state_extengap*female_hdd34
replace exten_fgdd34 = c_state_extengap*female_gdd34
replace female_exten = c_state_extengap*female
replace hdd34_exten = c_state_extengap*hdd_34_che
replace gdd34_exten = c_state_extengap*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 female_exten hdd34_exten gdd34_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster state)

**# Intra-household resource allocation/bargaining power
*Control over market earning(financial agency)
replace market_fhdd34 = c_market_control*female_hdd34
replace market_fgdd34 = c_market_control*female_gdd34
replace female_market = c_market_control*female
replace hdd34_market = c_market_control*hdd_34_che
replace gdd34_market = c_market_control*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 market_fhdd34 gdd_34_che female_gdd34 market_fgdd34 market_control female_market hdd34_market gdd34_market pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 market_fhdd34 gdd_34_che female_gdd34 market_fgdd34 market_control female_market hdd34_market gdd34_market $controls if married == 1 & dependency_ratio > 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_34_che female_hdd34 market_fhdd34 gdd_34_che female_gdd34 market_fgdd34 market_control female_market hdd34_market gdd34_market $controls if parea_q`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 market_fhdd34 gdd_34_che female_gdd34 market_fgdd34 market_control female_market hdd34_market gdd34_market $controls if prod_q`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 market_fhdd34 gdd_34_che female_gdd34 market_fgdd34 market_control female_market hdd34_market gdd34_market $controls if age_`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

*District level
replace state_marketgap = state_mmarket/state_male-state_fmarket/state_female
replace market_fhdd34 = c_state_marketgap*female_hdd34
replace market_fgdd34 = c_state_marketgap*female_gdd34
replace female_market = c_state_marketgap*female
replace hdd34_market = c_state_marketgap*hdd_34_che
replace gdd34_market = c_state_marketgap*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 market_fhdd34 gdd_34_che female_gdd34 market_fgdd34 female_market hdd34_market gdd34_market pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster state)

**# Land ownership(secure property/tenure right)
*Plot level
replace property_fhdd34 = c_parcel_owner*female_hdd34
replace property_fgdd34 = c_parcel_owner*female_gdd34
replace female_property = c_parcel_owner*female
replace hdd34_property = c_parcel_owner*hdd_34_che
replace gdd34_property = c_parcel_owner*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 property_fhdd34 gdd_34_che female_gdd34 property_fgdd34 parcel_owner female_property hdd34_property gdd34_property pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 property_fhdd34 gdd_34_che female_gdd34 property_fgdd34 parcel_owner female_property hdd34_property gdd34_property $controls if married == 1 & dependency_ratio > 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_34_che female_hdd34 property_fhdd34 gdd_34_che female_gdd34 property_fgdd34 parcel_owner female_property hdd34_property gdd34_property $controls if parea_q`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 property_fhdd34 gdd_34_che female_gdd34 property_fgdd34 parcel_owner female_property hdd34_property gdd34_property $controls if prod_q`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 property_fhdd34 gdd_34_che female_gdd34 property_fgdd34 parcel_owner female_property hdd34_property gdd34_property $controls if age_`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

*District level
replace state_landgap = state_mland/state_male-state_fland/state_female
replace property_fhdd34 = c_state_landgap*female_hdd34
replace property_fgdd34 = c_state_landgap*female_gdd34
replace female_property = c_state_landgap*female
replace hdd34_property = c_state_landgap*hdd_34_che
replace gdd34_property = c_state_landgap*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 property_fhdd34 gdd_34_che female_gdd34 property_fgdd34 female_property hdd34_property gdd34_property pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster state)

replace state_certigap = state_mcerti/state_male-state_fcerti/state_female
replace certified_fhdd34 = c_state_certigap*female_hdd34
replace certified_fgdd34 = c_state_certigap*female_gdd34
replace female_certified = c_state_certigap*female
replace hdd34_certified = c_state_certigap*hdd_34_che
replace gdd34_certified = c_state_certigap*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 certified_fhdd34 gdd_34_che female_gdd34 certified_fgdd34 female_certified hdd34_certified gdd34_certified pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster state)

**# Farm machinery (physical capital/technology)
replace machine_fhdd34 = c_ln_machine*female_hdd34
replace machine_fgdd34 = c_ln_machine*female_gdd34
replace female_machine = c_ln_machine*female
replace hdd34_machine = c_ln_machine*hdd_34_che
replace gdd34_machine = c_ln_machine*gdd_34_che

reghdfe lnland_yield hdd_34_che female_hdd34 machine_fhdd34 gdd_34_che female_gdd34 machine_fgdd34 ln_machine female_machine hdd34_machine gdd34_machine pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

reghdfe lnland_yield hdd_34_che female_hdd34 machine_fhdd34 gdd_34_che female_gdd34 machine_fgdd34 ln_machine female_machine hdd34_machine gdd34_machine $controls if married == 1 & dependency_ratio > 0, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)

forvalues i = 1/10{
	reghdfe lnland_yield hdd_34_che female_hdd34 machine_fhdd34 gdd_34_che female_gdd34 machine_fgdd34 ln_machine female_machine hdd34_machine gdd34_machine $controls if parea_q`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 machine_fhdd34 gdd_34_che female_gdd34 machine_fgdd34 ln_machine female_machine hdd34_machine gdd34_machine $controls if prod_q`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

forvalues i = 1/5{
	reghdfe lnland_yield hdd_34_che female_hdd34 machine_fhdd34 gdd_34_che female_gdd34 machine_fgdd34 ln_machine female_machine hdd34_machine gdd34_machine $controls if age_`i' == 1, absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
}

//# Simulation of women's empowerment
*baseline
reghdfe lnland_yield female_hdd34 male_hdd34 female_gdd34 male_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
predict landyield_110, xb

reghdfe lnland_yield female_hdd34 male_hdd34 female_gdd34 male_gdd34 pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
forvalues i = 2/9{
	replace female_hdd34 = female_hdd34_2`i'0
    replace male_hdd34 = male_hdd34_2`i'0
	replace female_gdd34 = female_gdd34_2`i'0
    replace male_gdd34 = male_gdd34_2`i'0
	predict landyield_2`i'0, xb
}

replace female_hdd34 = female_hdd34_origin
replace male_hdd34 = male_hdd34_origin
replace female_gdd34 = female_gdd34_origin
replace male_gdd34 = male_gdd34_origin

*extension
reghdfe lnland_yield hdd_34_che female_hdd34 exten_fhdd34 gdd_34_che female_gdd34 exten_fgdd34 exten_dummy female_exten hdd34_exten gdd34_exten pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
predict landyield_exten_110, xb
forvalues i = 2/9{
	replace hdd_34_che = hdd_34_2`i'0
	replace female_hdd34 = female_hdd34_2`i'0
	replace gdd_34_che = gdd_34_2`i'0
	replace female_gdd34 = female_gdd34_2`i'0
	predict landyield_exten_2`i'0, xb
}

replace hdd_34_che = hdd_34_origin
replace female_hdd34 = female_hdd34_origin
replace gdd_34_che = gdd_34_origin
replace female_gdd34 = female_gdd34_origin

*market
reghdfe lnland_yield hdd_34_che female_hdd34 market_fhdd34 gdd_34_che female_gdd34 market_fgdd34 market_control female_market hdd34_market gdd34_market pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
predict landyield_mark_110, xb
forvalues i = 2/9{
	replace hdd_34_che = hdd_34_2`i'0
	replace female_hdd34 = female_hdd34_2`i'0
	replace gdd_34_che = gdd_34_2`i'0
	replace female_gdd34 = female_gdd34_2`i'0
	predict landyield_mark_2`i'0, xb
}

replace hdd_34_che = hdd_34_origin
replace female_hdd34 = female_hdd34_origin
replace gdd_34_che = gdd_34_origin
replace female_gdd34 = female_gdd34_origin

*property
reghdfe lnland_yield hdd_34_che female_hdd34 property_fhdd34 gdd_34_che female_gdd34 property_fgdd34 parcel_owner female_property hdd34_property gdd34_property pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
predict landyield_prop_110, xb
forvalues i = 2/9{
	replace hdd_34_che = hdd_34_2`i'0
	replace female_hdd34 = female_hdd34_2`i'0
	replace gdd_34_che = gdd_34_2`i'0
	replace female_gdd34 = female_gdd34_2`i'0
	predict landyield_prop_2`i'0, xb
}

replace hdd_34_che = hdd_34_origin
replace female_hdd34 = female_hdd34_origin
replace gdd_34_che = gdd_34_origin
replace female_gdd34 = female_gdd34_origin

*machine
reghdfe lnland_yield hdd_34_che female_hdd34 machine_fhdd34 gdd_34_che female_gdd34 machine_fgdd34 ln_machine female_machine hdd34_machine gdd34_machine pr pr2 ws ws2 sr sr2 pests_shock drought_shock flood_shock dist_hh plot_slope plot_elev plot_wet soil_fertility_pca improved irrigated crop_diversity erosion_protection age edu_primary married female_hhead joint_decision livestock nonfarm_work fallow_plots electricity_access home_size farm_size dependency_ratio[pw = pw], absorb(hhid state#year female#main_crop female#soil_type) vce(cluster hhid)
predict landyield_mach_110, xb
forvalues i = 2/9{
	replace hdd_34_che = hdd_34_2`i'0
	replace female_hdd34 = female_hdd34_2`i'0
	replace gdd_34_che = gdd_34_2`i'0
	replace female_gdd34 = female_gdd34_2`i'0
	predict landyield_mach_2`i'0, xb
}

replace hdd_34_che = hdd_34_origin
replace female_hdd34 = female_hdd34_origin
replace gdd_34_che = gdd_34_origin
replace female_gdd34 = female_gdd34_origin

estpost ttest landyield_110 landyield_220-landyield_290 ///
landyield_exten_110 landyield_exten_220-landyield_exten_290 ///
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
