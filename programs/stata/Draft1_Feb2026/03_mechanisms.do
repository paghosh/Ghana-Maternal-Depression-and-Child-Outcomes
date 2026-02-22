/*==============================================================================
    Project:    Maternal Depression, Parental Investment, and Child Cognitive
                Development in Ghana
    File:       03_mechanisms.do
    Purpose:    Test empirical channels through which maternal depression
                affects child cognitive development:
                (1) Time Investment Channel
                (2) Financial Investment Channel
                (3) Nutritional Investment Channel
                (4) Emotional/Stimulation Quality Channel
    Author:     Pallab Ghosh, University of Oklahoma
    Created:    February 2026
    Data:       Analysis dataset from 00_data_cleaning.do
==============================================================================*/

clear all
set more off
cap log close

/*------------------------------------------------------------------------------
    Global Paths
------------------------------------------------------------------------------*/
global project  "/Users/pallab.ghosh/Library/CloudStorage/Dropbox/D/Study/My_Papers/OU/Health/Ghana_mental_health/maternal_depression_child_cog_devlopment"
global programs "$project/programs/stata/Draft1_Feb2026"
global results  "$project/rersults/Draft1_Feb2026"

log using "$programs/03_mechanisms.log", replace

/* Load analysis dataset */
use "$programs/analysis_data.dta", clear
keep if analysis_sample == 1

/* Control variable sets (same as main estimation) */
global child_controls "c_age i.c_female"
global maternal_controls "m_age_harmonized m_mother_educ_years"
global hh_controls "hh_size ln_pc_consumption"


/*==============================================================================
    CHANNEL 1: TIME INVESTMENT CHANNEL
    Does maternal depression reduce time spent with children?
    ReadTime_it = a + b1*Depression_it + X'_it*g + d_v + n_t + e_it
==============================================================================*/

di _n "=============================================="
di "CHANNEL 1: TIME INVESTMENT"
di "=============================================="

eststo clear

/*--- 1a. Effect of depression on reading/homework time ---*/
cap noi eststo tc1: reghdfe m_read_hw_time m_k10_std ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 1b. Effect of depression on total child time ---*/
cap noi eststo tc2: reghdfe m_total_child_time m_k10_std ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 1c. Effect of depression on childcare participation ---*/
cap noi eststo tc3: reghdfe m_careforkids_yn m_k10_std ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 1d. Effect of depression on days per week of childcare ---*/
/* Combine Wave 1 and Wave 2/3 days variable */
gen days_childcare = m_days_childcare_week_w1 if wave == 1
replace days_childcare = m_daysworkperweek if wave == 2 | wave == 3

cap noi eststo tc4: reghdfe days_childcare m_k10_std ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 1e. Binary depression ---*/
cap noi eststo tc5: reghdfe m_read_hw_time m_depressed_binary ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo tc6: reghdfe m_total_child_time m_depressed_binary ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export Table: Time Investment Channel */
local models_list ""
foreach m in tc1 tc2 tc3 tc4 tc5 tc6 {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/Table13_Channel1_TimeInvestment.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Channel 1: Maternal Depression and Parental Time Investment") ///
    mtitles("Read/HW Hrs" "Total Hrs" "Care Y/N" "Days/Wk" "Read/HW Hrs" "Total Hrs") ///
    keep(m_k10_std) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        m_depressed_binary "Mother depressed (K10 $\geq$ 20)" ///
    ) ///
    indicate("Maternal controls = m_age_harmonized m_mother_educ_years" ///
             "Household controls = hh_size ln_pc_consumption" ///
             ) ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Dependent variables: (1)--(2) hours per day mother spends reading/doing" ///
             "homework and total time with child; (3) binary indicator for providing" ///
             "childcare; (4) days per week of childcare." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/Table13_Channel1_TimeInvestment.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Read/HW Hrs" "Total Hrs" "Care Y/N" "Days/Wk" "Read/HW Hrs" "Total Hrs") ///
    keep(m_k10_std) ///
    stats(N r2, fmt(%9.0fc %9.3f))

cap noi esttab `models_list' ///
    using "$results/Table13_Channel1_TimeInvestment.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) csv ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    CHANNEL 2: FINANCIAL INVESTMENT CHANNEL
    Does depression reduce household resources allocated to children?
    ln(Expenditure_ht) = a + b1*Depression_it + b2*ln(TotalExp) + X + d_v + n_t + e
==============================================================================*/

di _n "=============================================="
di "CHANNEL 2: FINANCIAL INVESTMENT"
di "=============================================="

eststo clear

/*--- 2a. Effect on total food expenditure ---*/
gen ln_food_exp = ln(total_food_exp) if total_food_exp > 0

cap noi eststo fc1: reghdfe ln_food_exp m_k10_std ///
    $maternal_controls hh_size, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 2b. Effect on food share of consumption ---*/
gen food_share = total_food_exp / (total_food_exp + clothing_exp + ///
    other_exp + fuel_exp) if total_food_exp > 0

cap noi eststo fc2: reghdfe food_share m_k10_std ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 2c. Per capita food expenditure ---*/
gen pc_food_exp = total_food_exp / hh_size
gen ln_pc_food = ln(pc_food_exp) if pc_food_exp > 0

cap noi eststo fc3: reghdfe ln_pc_food m_k10_std ///
    $maternal_controls hh_size, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 2d. Binary depression ---*/
cap noi eststo fc4: reghdfe ln_food_exp m_depressed_binary ///
    $maternal_controls hh_size, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo fc5: reghdfe food_share m_depressed_binary ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export Table: Financial Investment Channel */
local models_list ""
foreach m in fc1 fc2 fc3 fc4 fc5 {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/Table14_Channel2_FinancialInvestment.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Channel 2: Maternal Depression and Financial Investment in Children") ///
    mtitles("Ln(Food Exp)" "Food Share" "Ln(PC Food)" "Ln(Food Exp)" "Food Share") ///
    keep(m_k10_std) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        m_depressed_binary "Mother depressed (K10 $\geq$ 20)" ///
    ) ///
    indicate("Maternal controls = m_age_harmonized m_mother_educ_years" ///
             "Household controls = hh_size ln_pc_consumption" ///
             ) ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Food expenditure includes own-produced and purchased food (Section 11a)." ///
             "Food share = food expenditure / total consumption." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/Table14_Channel2_FinancialInvestment.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Ln(Food Exp)" "Food Share" "Ln(PC Food)" "Ln(Food Exp)" "Food Share") ///
    keep(m_k10_std) ///
    stats(N r2, fmt(%9.0fc %9.3f))

cap noi esttab `models_list' ///
    using "$results/Table14_Channel2_FinancialInvestment.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) csv ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    CHANNEL 3: NUTRITIONAL INVESTMENT CHANNEL
    Does depression affect child nutrition (HAZ)?
    HAZ_ct = a + b1*Depression_it + b2*HAZ_c,t-1 + X + d_v + n_t + e
==============================================================================*/

di _n "=============================================="
di "CHANNEL 3: NUTRITIONAL INVESTMENT"
di "=============================================="

eststo clear

/*--- 3a. Depression -> Child HAZ ---*/
cap noi eststo nc1: reghdfe haz_approx m_k10_std $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 3b. Depression -> Child WAZ ---*/
cap noi eststo nc2: reghdfe waz_approx m_k10_std $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 3c. Dynamic model: HAZ_t as function of depression + lagged HAZ ---*/
/* Create lagged HAZ */
sort person_id wave
bysort person_id (wave): gen haz_lag = haz_approx[_n-1]
bysort person_id (wave): gen waz_lag = waz_approx[_n-1]

cap noi eststo nc3: reghdfe haz_approx m_k10_std haz_lag $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 3d. Depression -> Arm circumference (alternative nutrition measure) ---*/
cap noi eststo nc4: reghdfe c_arm_circ m_k10_std $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 3e. Binary depression ---*/
cap noi eststo nc5: reghdfe haz_approx m_depressed_binary $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export Table: Nutritional Channel */
local models_list ""
foreach m in nc1 nc2 nc3 nc4 nc5 {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/Table15_Channel3_Nutrition.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Channel 3: Maternal Depression and Child Nutritional Status") ///
    mtitles("HAZ" "WAZ" "HAZ (dyn.)" "Arm Circ." "HAZ") ///
    keep(m_k10_std haz_lag) ///
    order(m_k10_std haz_lag) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        m_depressed_binary "Mother depressed (K10 $\geq$ 20)" ///
        haz_lag "Lagged HAZ (t-1)" ///
    ) ///
    indicate("Child controls = c_age *.c_female" ///
             "Maternal controls = m_age_harmonized m_mother_educ_years" ///
             "Household controls = hh_size ln_pc_consumption" ///
             ) ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "HAZ = height-for-age z-score; WAZ = weight-for-age z-score." ///
             "Column 3 includes lagged HAZ to estimate dynamic persistence." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/Table15_Channel3_Nutrition.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("HAZ" "WAZ" "HAZ (dyn.)" "Arm Circ." "HAZ") ///
    keep(m_k10_std haz_lag) ///
    stats(N r2, fmt(%9.0fc %9.3f))

cap noi esttab `models_list' ///
    using "$results/Table15_Channel3_Nutrition.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) csv ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    CHANNEL 4: EMOTIONAL/STIMULATION QUALITY CHANNEL
    Does the quality of parental stimulation differ for depressed mothers?
    Cognitive_c,t+1 = a + b1*Dep + b2*ReadTime + b3*(Dep x ReadTime) + X + d_v + n_t + e
==============================================================================*/

di _n "=============================================="
di "CHANNEL 4: STIMULATION QUALITY"
di "=============================================="

eststo clear

/*--- 4a. Depression x Reading time interaction ---*/
gen dep_x_readtime = m_k10_std * m_read_hw_time

cap noi eststo qc1: reghdfe cog_index m_k10_std m_read_hw_time dep_x_readtime ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 4b. Depression x Total child time interaction ---*/
gen dep_x_totaltime = m_k10_std * m_total_child_time

cap noi eststo qc2: reghdfe cog_index m_k10_std m_total_child_time dep_x_totaltime ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 4c. Same with Raven's as outcome ---*/
cap noi eststo qc3: reghdfe ravens_std m_k10_std m_read_hw_time dep_x_readtime ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 4d. Same with math as outcome ---*/
cap noi eststo qc4: reghdfe math_std m_k10_std m_read_hw_time dep_x_readtime ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/*--- 4e. Binary depression x reading time ---*/
gen dep_binary_x_read = m_depressed_binary * m_read_hw_time

cap noi eststo qc5: reghdfe cog_index m_depressed_binary m_read_hw_time ///
    dep_binary_x_read ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export Table: Stimulation Quality Channel */
local models_list ""
foreach m in qc1 qc2 qc3 qc4 qc5 {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/Table16_Channel4_StimulationQuality.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Channel 4: Depression, Parental Stimulation Quality, and Child Cognition") ///
    mtitles("Cog Index" "Cog Index" "Raven's" "Math" "Cog Index") ///
    keep(m_k10_std m_read_hw_time m_total_child_time ///
         dep_x_readtime dep_x_totaltime) ///
    order(m_k10_std m_read_hw_time m_total_child_time ///
          dep_x_readtime dep_x_totaltime) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        m_depressed_binary "Mother depressed" ///
        m_read_hw_time "Reading/homework time (hrs)" ///
        m_total_child_time "Total child time (hrs)" ///
        dep_x_readtime "Depression $\times$ Read time" ///
        dep_x_totaltime "Depression $\times$ Total time" ///
        dep_binary_x_read "Depressed $\times$ Read time" ///
    ) ///
    indicate("Child controls = c_age *.c_female" ///
             "Maternal controls = m_age_harmonized m_mother_educ_years" ///
             "Household controls = hh_size ln_pc_consumption" ///
             ) ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "A negative coefficient on Depression $\times$ Read time implies" ///
             "depressed mothers generate less cognitive gain per hour of stimulation." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/Table16_Channel4_StimulationQuality.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Cog Index" "Cog Index" "Raven's" "Math" "Cog Index") ///
    keep(m_k10_std m_read_hw_time m_total_child_time ///
         dep_x_readtime dep_x_totaltime) ///
    stats(N r2, fmt(%9.0fc %9.3f))

cap noi esttab `models_list' ///
    using "$results/Table16_Channel4_StimulationQuality.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) csv ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    TABLE 17: MEDIATION ANALYSIS — SEQUENTIAL DECOMPOSITION
    Step 1: Full effect (depression -> cognition)
    Step 2: Add time investment (does beta on depression shrink?)
    Step 3: Add nutrition (does beta shrink further?)
    Step 4: Add all channels
==============================================================================*/

di _n "=============================================="
di "MEDIATION ANALYSIS"
di "=============================================="

eststo clear

/* Step 1: Base — depression only */
cap noi eststo med1: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Step 2: Add time investment */
cap noi eststo med2: reghdfe cog_index m_k10_std m_read_hw_time m_total_child_time ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Step 3: Add nutrition */
cap noi eststo med3: reghdfe cog_index m_k10_std m_read_hw_time m_total_child_time ///
    haz_approx ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Step 4: Add food expenditure */
cap noi eststo med4: reghdfe cog_index m_k10_std m_read_hw_time m_total_child_time ///
    haz_approx ln_food_exp ///
    $child_controls $maternal_controls hh_size, ///
    absorb(ea_id wave) cluster(ea_id)

/* Step 5: Add interaction (quality channel) */
cap noi eststo med5: reghdfe cog_index m_k10_std m_read_hw_time m_total_child_time ///
    haz_approx ln_food_exp dep_x_readtime ///
    $child_controls $maternal_controls hh_size, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export Table: Mediation Analysis */
local models_list ""
foreach m in med1 med2 med3 med4 med5 {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/Table17_MediationAnalysis.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Mediation Analysis: Sequential Decomposition of Depression Effect") ///
    mtitles("Base" "+ Time" "+ Nutrition" "+ Food Exp" "+ Quality") ///
    keep(m_k10_std m_read_hw_time m_total_child_time haz_approx ///
         ln_food_exp dep_x_readtime) ///
    order(m_k10_std m_read_hw_time m_total_child_time haz_approx ///
          ln_food_exp dep_x_readtime) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        m_read_hw_time "Reading/homework time" ///
        m_total_child_time "Total child time" ///
        haz_approx "Height-for-age z-score" ///
        ln_food_exp "Log food expenditure" ///
        dep_x_readtime "Depression $\times$ Read time" ///
    ) ///
    indicate("Child controls = c_age *.c_female" ///
             "Maternal controls = m_age_harmonized m_mother_educ_years" ///
             "Household controls = hh_size ln_pc_consumption" ///
             ) ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "This table sequentially adds mediator variables to decompose" ///
             "the total effect of maternal depression on child cognition." ///
             "A reduction in the depression coefficient indicates mediation." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/Table17_MediationAnalysis.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Base" "+ Time" "+ Nutrition" "+ Food Exp" "+ Quality") ///
    keep(m_k10_std m_read_hw_time m_total_child_time haz_approx ///
         ln_food_exp dep_x_readtime) ///
    stats(N r2, fmt(%9.0fc %9.3f))

cap noi esttab `models_list' ///
    using "$results/Table17_MediationAnalysis.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) csv ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    TABLE 18: HEALTH CHANNEL — CHILD MORBIDITY
==============================================================================*/

di _n "=============================================="
di "SUPPLEMENTARY: CHILD HEALTH CHANNEL"
di "=============================================="

eststo clear

/* Depression -> child illness in past 2 weeks */
/* ill_2weeks may be string or numeric with value labels */
cap destring ill_2weeks, replace force
cap confirm string variable ill_2weeks
if _rc == 0 {
    decode ill_2weeks, gen(_tmp_ill)
    gen child_ill = (_tmp_ill == "Yes") if !missing(ill_2weeks)
    drop _tmp_ill
}
else {
    gen child_ill = (ill_2weeks == 1) if !missing(ill_2weeks)
}

cap noi eststo hc1: reghdfe child_ill m_k10_std $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Depression -> days sick */
cap noi eststo hc2: reghdfe days_sick m_k10_std $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Depression -> consulted facility when sick */
cap destring consulted_facility, replace force
cap confirm string variable consulted_facility
if _rc == 0 {
    decode consulted_facility, gen(_tmp_cf)
    gen sought_care = (_tmp_cf == "Yes") if !missing(consulted_facility)
    drop _tmp_cf
}
else {
    gen sought_care = (consulted_facility == 1) if !missing(consulted_facility)
}

cap noi eststo hc3: reghdfe sought_care m_k10_std $child_controls ///
    $maternal_controls hh_size ln_pc_consumption ///
    if child_ill == 1, ///
    absorb(ea_id wave) cluster(ea_id)

/* Depression -> child immunization rate */
cap noi eststo hc4: reghdfe immun_rate m_k10_std $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export */
local models_list ""
foreach m in hc1 hc2 hc3 hc4 {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/Table18_ChildHealthChannel.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Supplementary Channel: Maternal Depression and Child Health") ///
    mtitles("Ill (2 wks)" "Days Sick" "Sought Care" "Immun. Rate") ///
    keep(m_k10_std) ///
    coeflabels(m_k10_std "Maternal depression (std. K10)") ///
    indicate("Child controls = c_age *.c_female" ///
             "Maternal controls = m_age_harmonized m_mother_educ_years" ///
             "Household controls = hh_size ln_pc_consumption" ///
             ) ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Column 3 conditional on child being ill in past 2 weeks." ///
             "Immunization rate = vaccines received / 7 recommended vaccines." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/Table18_ChildHealthChannel.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Ill (2 wks)" "Days Sick" "Sought Care" "Immun. Rate") ///
    keep(m_k10_std) ///
    stats(N r2, fmt(%9.0fc %9.3f))


log close

/*==============================================================================
    END OF MECHANISMS
==============================================================================*/
