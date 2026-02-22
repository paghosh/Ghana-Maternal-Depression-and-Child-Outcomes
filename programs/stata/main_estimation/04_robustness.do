/*==============================================================================
    Project:    Maternal Depression, Parental Investment, and Child Cognitive
                Development in Ghana
    File:       04_robustness.do
    Purpose:    Robustness checks for main results:
                (1) Alternative depression measures
                (2) Different fixed effects specifications
                (3) Subsample analyses (urban/rural, by region)
                (4) Lagged depression (value-added model)
                (5) Falsification / placebo tests
                (6) Non-linear effects
                (7) Attrition-corrected estimates (IPW)
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

log using "$programs/04_robustness.log", replace

/* Load analysis dataset */
use "$programs/analysis_data.dta", clear
keep if analysis_sample == 1

/* Standard control variables */
global child_controls "c_age i.c_female"
global maternal_controls "m_age_harmonized m_mother_educ_years"
global hh_controls "hh_size ln_pc_consumption"

/* Install packages */
cap ssc install estout, replace
cap ssc install reghdfe, replace


/*==============================================================================
    ROBUSTNESS 1: ALTERNATIVE DEPRESSION MEASURES
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 1: ALTERNATIVE DEPRESSION MEASURES"
di "=============================================="

eststo clear

/* R1a. Baseline (standardized K10 score) */
cap noi eststo r1a: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R1b. Raw K10 score (10-50) */
cap noi eststo r1b: reghdfe cog_index m_k10_score $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R1c. Binary depression (K10 >= 20) */
cap noi eststo r1c: reghdfe cog_index m_depressed_binary $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R1d. Depression categories (mild, moderate, severe) */
gen dep_mild = (m_depression_cat == 1) if m_depression_cat < .
gen dep_moderate = (m_depression_cat == 2) if m_depression_cat < .
gen dep_severe = (m_depression_cat == 3) if m_depression_cat < .

cap noi eststo r1d: reghdfe cog_index dep_mild dep_moderate dep_severe ///
    $child_controls $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R1e. Top 3 K10 items (core depression symptoms):
   depressed, hopeless, worthless */
/* Reconstruct using Wave 1 item names */
/* For pooled data, we need to use the harmonized item scores */
/* These were saved as tired_n, nervous_n, etc. in Waves 2 and 3
   and s10ai_a1_n through s10ai_a10_n in Wave 1 */

/* Use pre-constructed depression_score_precoded if available (Wave 1) */
cap noi eststo r1e: reghdfe cog_index m_depression_score_precoded $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export */
local models_list ""
foreach m in r1a r1b r1c r1d r1e {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/TableA1_RobDepMeasure.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Alternative Depression Measures") ///
    mtitles("Std. K10" "Raw K10" "Binary" "Categories" "Pre-coded") ///
    coeflabels( ///
        m_k10_std "K10 score (standardized)" ///
        m_k10_score "K10 score (raw, 10--50)" ///
        m_depressed_binary "Depressed (K10 $\geq$ 20)" ///
        dep_mild "Mild (K10: 20--24)" ///
        dep_moderate "Moderate (K10: 25--29)" ///
        dep_severe "Severe (K10: 30--50)" ///
    ) ///
    indicate("Controls = c_age 1.c_female m_age_harmonized m_mother_educ_years hh_size ln_pc_consumption") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Dependent variable: composite cognitive index." ///
             "All models include EA and wave fixed effects." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/TableA1_RobDepMeasure.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Std. K10" "Raw K10" "Binary" "Categories") ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    ROBUSTNESS 2: DIFFERENT FIXED EFFECTS SPECIFICATIONS
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 2: FIXED EFFECTS SPECIFICATIONS"
di "=============================================="

eststo clear

/* R2a. Pooled OLS (no FE) */
cap noi eststo r2a: reg cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls i.wave, ///
    cluster(ea_id)

/* R2b. EA fixed effects */
cap noi eststo r2b: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R2c. District fixed effects */
cap noi eststo r2c: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(districtcode wave) cluster(ea_id)

/* R2d. Region x Wave fixed effects */
cap noi eststo r2d: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id i.regioncode#i.wave) cluster(ea_id)

/* R2e. Household fixed effects (within-HH, across-sibling variation) */
cap noi eststo r2e: reghdfe cog_index m_k10_std c_age i.c_female hh_size, ///
    absorb(hh_id wave) cluster(ea_id)

/* R2f. Child fixed effects (within-child, across-wave variation) */
cap noi eststo r2f: reghdfe cog_index m_k10_std c_age hh_size, ///
    absorb(person_id) cluster(ea_id)

/* Export */
local models_list ""
foreach m in r2a r2b r2c r2d r2e r2f {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/TableA2_RobFESpecs.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Alternative Fixed Effects Specifications") ///
    mtitles("Pooled OLS" "EA FE" "District FE" "Region$\times$Wave" "HH FE" "Child FE") ///
    coeflabels(m_k10_std "Maternal depression (std. K10)") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Dependent variable: composite cognitive index." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/TableA2_RobFESpecs.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Pooled OLS" "EA FE" "District FE" "Region*Wave" "HH FE" "Child FE") ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    ROBUSTNESS 3: SUBSAMPLE ANALYSES
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 3: SUBSAMPLE ANALYSES"
di "=============================================="

eststo clear

/* Create urban/rural indicator that handles both string and numeric */
cap confirm string variable urbrur
if _rc == 0 {
    gen urban = (urbrur == "Urban") if !missing(urbrur)
}
else {
    decode urbrur, gen(_urb_str)
    gen urban = (_urb_str == "Urban") if !missing(urbrur)
    drop _urb_str
}

/* R3a. Urban only */
cap noi eststo r3a: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls ///
    if urban == 1, ///
    absorb(ea_id wave) cluster(ea_id)

/* R3b. Rural only */
cap noi eststo r3b: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls ///
    if urban == 0, ///
    absorb(ea_id wave) cluster(ea_id)

/* R3c. Below-median consumption (poor) */
bysort wave: egen median_cons = median(ln_pc_consumption)
gen poor = (ln_pc_consumption < median_cons) if !missing(ln_pc_consumption)

cap noi eststo r3c: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls if poor == 1, ///
    absorb(ea_id wave) cluster(ea_id)

/* R3d. Above-median consumption (non-poor) */
cap noi eststo r3d: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls if poor == 0, ///
    absorb(ea_id wave) cluster(ea_id)

/* R3e. Mother has no education */
cap noi eststo r3e: reghdfe cog_index m_k10_std $child_controls ///
    hh_size ln_pc_consumption ///
    if m_educ_cat == 0, ///
    absorb(ea_id wave) cluster(ea_id)

/* R3f. Mother has some education */
cap noi eststo r3f: reghdfe cog_index m_k10_std $child_controls ///
    hh_size ln_pc_consumption ///
    if m_educ_cat >= 1 & m_educ_cat < ., ///
    absorb(ea_id wave) cluster(ea_id)

/* Export */
local models_list ""
foreach m in r3a r3b r3c r3d r3e r3f {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/TableA3_RobSubsamples.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Subsample Analyses") ///
    mtitles("Urban" "Rural" "Poor" "Non-Poor" "No Educ" "Some Educ") ///
    coeflabels(m_k10_std "Maternal depression (std. K10)") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Poor/Non-poor split at wave-specific median log per capita consumption." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/TableA3_RobSubsamples.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Urban" "Rural" "Poor" "Non-Poor" "No Educ" "Some Educ") ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    ROBUSTNESS 4: VALUE-ADDED MODEL WITH LAGGED DEPRESSION
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 4: VALUE-ADDED / LAGGED MODELS"
di "=============================================="

/* Create lagged depression and lagged cognitive scores */
sort person_id wave
bysort person_id (wave): gen m_k10_std_lag = m_k10_std[_n-1]
bysort person_id (wave): gen m_depressed_lag = m_depressed_binary[_n-1]
bysort person_id (wave): gen cog_index_lag = cog_index[_n-1]

eststo clear

/* R4a. Value-added: current cognition = f(lagged cognition, current depression) */
cap noi eststo r4a: reghdfe cog_index m_k10_std cog_index_lag $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R4b. Lagged depression predicting current cognition */
cap noi eststo r4b: reghdfe cog_index m_k10_std_lag $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R4c. Both current and lagged depression */
cap noi eststo r4c: reghdfe cog_index m_k10_std m_k10_std_lag $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R4d. Change in depression predicting change in cognition */
bysort person_id (wave): gen delta_k10 = m_k10_std - m_k10_std[_n-1]
bysort person_id (wave): gen delta_cog = cog_index - cog_index[_n-1]

cap noi eststo r4d: reg delta_cog delta_k10 $child_controls ///
    i.wave if wave > 1, cluster(ea_id)

/* R4e. Full value-added with lagged outcomes and all channels */
cap noi eststo r4e: reghdfe cog_index m_k10_std cog_index_lag ///
    m_read_hw_time haz_approx ///
    $child_controls $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export */
local models_list ""
foreach m in r4a r4b r4c r4d r4e {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/TableA4_RobValueAdded.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Value-Added and Lagged Models") ///
    mtitles("VA Model" "Lag Dep" "Both" "$\Delta$ Model" "VA + Channels") ///
    coeflabels( ///
        m_k10_std "Depression$_t$ (std. K10)" ///
        m_k10_std_lag "Depression$_{t-1}$ (lagged)" ///
        delta_k10 "$\Delta$ Depression" ///
        cog_index_lag "Cognitive index$_{t-1}$" ///
        m_read_hw_time "Read/homework time" ///
        haz_approx "Height-for-age z-score" ///
    ) ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Column 4 estimated in first differences ($\Delta$ model)." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/TableA4_RobValueAdded.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("VA Model" "Lag Dep" "Both" "Delta" "VA + Chan") ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    ROBUSTNESS 5: PLACEBO / FALSIFICATION TESTS
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 5: PLACEBO TESTS"
di "=============================================="

eststo clear

/* R5a. Placebo: Depression of OTHER adults (not mother) on child cognition
   If result is driven by household-level confounders, non-mother depression
   should also predict child cognition. If our effect is mother-specific,
   non-mother adults' depression should be insignificant. */

/* Identify fathers or other adult males in the household */
/* This would require going back to the data and extracting
   depression scores for non-mother adults. For now, use a proxy. */

/* R5b. Reverse causality check: child cognition at t predicting
   maternal depression at t+1 */
bysort person_id (wave): gen cog_lead = cog_index[_n+1]
bysort person_id (wave): gen m_k10_std_lead = m_k10_std[_n+1]

/* Does current child cognition predict future maternal depression? */
cap noi eststo r5a: reghdfe m_k10_std_lead cog_index $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R5c. Does current depression predict future cognition? (should be yes) */
cap noi eststo r5b: reghdfe cog_lead m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R5d. Placebo outcome: child height conditional on being adult (age 18+)
   Depression should not affect adult height (determined earlier in life) */
cap noi eststo r5c: reghdfe c_height m_k10_std $child_controls ///
    $maternal_controls $hh_controls ///
    if c_age >= 15 & c_age <= 17, ///
    absorb(ea_id wave) cluster(ea_id)

/* R5e. Balanced panel only (present in all waves) */
bysort person_id: gen n_waves_obs = _N
cap noi eststo r5d: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls ///
    if n_waves_obs >= 2, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export */
local models_list ""
foreach m in r5a r5b r5c r5d {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/TableA5_RobPlacebo.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Placebo and Falsification Tests") ///
    mtitles("Dep$_{t+1}$" "Cog$_{t+1}$" "Height (15--17)" "Balanced") ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        cog_index "Cognitive index" ///
    ) ///
    indicate("Controls = c_age 1.c_female m_age_harmonized m_mother_educ_years hh_size ln_pc_consumption") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Col 1: reverse causality test (current cognition $\rightarrow$ future depression)." ///
             "Col 2: temporal precedence (current depression $\rightarrow$ future cognition)." ///
             "Col 3: placebo outcome (adolescent height, largely determined before survey)." ///
             "Col 4: restricted to children observed in $\geq$ 2 waves." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/TableA5_RobPlacebo.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Dep(t+1)" "Cog(t+1)" "Height 15-17" "Balanced") ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    ROBUSTNESS 6: NON-LINEAR EFFECTS
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 6: NON-LINEAR EFFECTS"
di "=============================================="

eststo clear

/* R6a. Quadratic depression */
gen m_k10_std_sq = m_k10_std^2

cap noi eststo r6a: reghdfe cog_index m_k10_std m_k10_std_sq $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R6b. Depression terciles */
xtile dep_tercile = m_k10_score, nq(3)
gen dep_t2 = (dep_tercile == 2) if dep_tercile < .
gen dep_t3 = (dep_tercile == 3) if dep_tercile < .

cap noi eststo r6b: reghdfe cog_index dep_t2 dep_t3 $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R6c. Depression quintiles */
xtile dep_quintile = m_k10_score, nq(5)
gen dep_q2 = (dep_quintile == 2) if dep_quintile < .
gen dep_q3 = (dep_quintile == 3) if dep_quintile < .
gen dep_q4 = (dep_quintile == 4) if dep_quintile < .
gen dep_q5 = (dep_quintile == 5) if dep_quintile < .

cap noi eststo r6c: reghdfe cog_index dep_q2 dep_q3 dep_q4 dep_q5 $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R6d. Spline at K10 = 20 (clinical threshold) */
gen k10_below20 = min(m_k10_score, 20) - 10
gen k10_above20 = max(m_k10_score - 20, 0)

cap noi eststo r6d: reghdfe cog_index k10_below20 k10_above20 $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* Export */
local models_list ""
foreach m in r6a r6b r6c r6d {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/TableA6_RobNonLinear.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Non-Linear Effects of Maternal Depression") ///
    mtitles("Quadratic" "Terciles" "Quintiles" "Spline") ///
    coeflabels( ///
        m_k10_std "Depression (std.)" ///
        m_k10_std_sq "Depression$^2$" ///
        dep_t2 "Tercile 2" ///
        dep_t3 "Tercile 3 (most depressed)" ///
        dep_q2 "Quintile 2" ///
        dep_q3 "Quintile 3" ///
        dep_q4 "Quintile 4" ///
        dep_q5 "Quintile 5 (most depressed)" ///
        k10_below20 "K10 (below 20)" ///
        k10_above20 "K10 (above 20)" ///
    ) ///
    indicate("Controls = c_age 1.c_female m_age_harmonized m_mother_educ_years hh_size ln_pc_consumption") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Reference: Tercile 1 / Quintile 1 (least depressed)." ///
             "Spline model allows different slopes below and above K10 = 20." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/TableA6_RobNonLinear.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Quadratic" "Terciles" "Quintiles" "Spline") ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    ROBUSTNESS 7: INVERSE PROBABILITY WEIGHTING (ATTRITION CORRECTION)
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 7: ATTRITION CORRECTION (IPW)"
di "=============================================="

/* Step 1: Estimate attrition probability */
/* For each wave transition, predict who drops out */
preserve
    /* Create attrition indicator */
    bysort person_id: gen present_next = (wave[_n+1] == wave + 1) if _n < _N

    /* Predict attrition using Wave t characteristics */
    cap noi logit present_next m_k10_score c_age c_female m_age_harmonized ///
        m_mother_educ_years hh_size ln_pc_consumption ///
        i.wave if wave < 3

    /* Predicted probability of staying */
    cap predict p_stay if e(sample), pr

    /* IPW weight = 1 / p_stay */
    cap gen ipw = 1 / p_stay if !missing(p_stay)

    /* Trim extreme weights (at 1st and 99th percentiles) */
    cap qui summ ipw, detail
    cap replace ipw = r(p99) if ipw > r(p99) & !missing(ipw)
    cap replace ipw = r(p1) if ipw < r(p1) & !missing(ipw)

    /* For wave 1 obs or if logit failed, set weight = 1 */
    cap gen ipw = 1
    replace ipw = 1 if missing(ipw)

    save "$programs/analysis_data_ipw.dta", replace
restore

/* IPW-weighted regression */
use "$programs/analysis_data_ipw.dta", clear
keep if analysis_sample == 1

eststo clear

cap noi eststo ipw1: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls [pw=ipw], ///
    absorb(ea_id wave) cluster(ea_id)

/* Compare with unweighted */
cap noi eststo ipw2: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* Survey-weighted with provided sampling weights */
cap gen combined_weight = ipw * hh_weight
cap noi eststo ipw3: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls [pw=combined_weight], ///
    absorb(ea_id wave) cluster(ea_id)

local models_list ""
foreach m in ipw1 ipw2 {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/TableA7_RobIPW.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Attrition-Corrected Estimates (Inverse Probability Weighting)") ///
    mtitles("IPW-Weighted" "Unweighted") ///
    coeflabels(m_k10_std "Maternal depression (std. K10)") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "IPW weights estimated from logit model predicting panel continuation" ///
             "using depression, age, education, household size, consumption, and wave." ///
             "Weights trimmed at 1st and 99th percentiles." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/TableA7_RobIPW.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("IPW-Weighted" "Unweighted") ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    ROBUSTNESS 8: ALTERNATIVE COGNITIVE OUTCOMES
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 8: ALTERNATIVE COGNITIVE OUTCOMES"
di "=============================================="

/* Go back to main data */
use "$programs/analysis_data.dta", clear
keep if analysis_sample == 1

eststo clear

/* R8a. Principal Component of cognitive scores */
/* Run PCA on available test scores */
cap pca ravens_correct dsf_score dsb_score math_correct english_correct
cap predict cog_pca1, score
cap eststo r8a: reghdfe cog_pca1 m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R8b. Only Raven's (non-verbal, less culture-dependent) */
cap noi eststo r8b: reghdfe ravens_std m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R8c. Only verbal tests (math + English) */
egen verbal_index = rowmean(math_std english_std)
cap noi eststo r8c: reghdfe verbal_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R8d. Only executive function (digit span backward) -- may have insufficient obs */
cap noi eststo r8d: reghdfe dsb_std m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R8e. NEPSY (Wave 3 only) */
cap noi eststo r8e: reghdfe nepsy_naming m_k10_std $child_controls ///
    $maternal_controls $hh_controls ///
    if wave == 3, ///
    absorb(ea_id) cluster(ea_id)

cap noi eststo r8f: reghdfe nepsy_inhibit m_k10_std $child_controls ///
    $maternal_controls $hh_controls ///
    if wave == 3, ///
    absorb(ea_id) cluster(ea_id)

/* Build model list for Table A8 -- skip missing models */
local a8_models ""
foreach m in r8a r8b r8c r8d r8e r8f {
    cap estimates describe `m'
    if _rc == 0 local a8_models "`a8_models' `m'"
}

cap noi esttab `a8_models' ///
    using "$results/TableA8_RobAltCogOutcomes.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Alternative Cognitive Outcome Measures") ///
    mtitles("Raven's" "Verbal" "Exec. Func." "NEPSY Name" "NEPSY Inhib.") ///
    coeflabels(m_k10_std "Maternal depression (std. K10)") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Raven's = non-verbal fluid intelligence. Verbal = avg(math, English)." ///
             "Exec. Function = digit span backward. NEPSY = Wave 3 only." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `a8_models' ///
    using "$results/TableA8_RobAltCogOutcomes.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Raven's" "Verbal" "Exec. Func." "NEPSY Name" "NEPSY Inhib.") ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    ROBUSTNESS 9: CLUSTERING ALTERNATIVES
==============================================================================*/

di _n "=============================================="
di "ROBUSTNESS 9: ALTERNATIVE CLUSTERING"
di "=============================================="

eststo clear

/* R9a. Cluster at EA level (baseline) */
cap noi eststo r9a: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id)

/* R9b. Cluster at household level */
cap noi eststo r9b: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(hh_id)

/* R9c. Cluster at district level */
cap noi eststo r9c: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(districtcode)

/* R9d. Two-way clustering: EA and wave */
cap noi eststo r9d: reghdfe cog_index m_k10_std $child_controls ///
    $maternal_controls $hh_controls, ///
    absorb(ea_id wave) cluster(ea_id wave)

local models_list ""
foreach m in r9a r9b r9c r9d {
    cap estimates describe `m'
    if _rc == 0 local models_list "`models_list' `m'"
}

cap noi esttab `models_list' ///
    using "$results/TableA9_RobClustering.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness: Alternative Standard Error Clustering") ///
    mtitles("EA Cluster" "HH Cluster" "District" "Two-Way") ///
    coeflabels(m_k10_std "Maternal depression (std. K10)") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("All models include EA and wave fixed effects with full controls." ///
             "Point estimates are identical; only standard errors differ." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `models_list' ///
    using "$results/TableA9_RobClustering.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("EA Cluster" "HH Cluster" "District" "Two-Way") ///
    stats(N r2, fmt(%9.0fc %9.3f))


log close

/*==============================================================================
    END OF ROBUSTNESS CHECKS
==============================================================================*/
