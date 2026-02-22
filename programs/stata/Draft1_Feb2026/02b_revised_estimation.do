/*==============================================================================
    Project:    Maternal Depression, Parental Investment, and Child Cognitive
                Development in Ghana
    File:       02b_revised_estimation.do
    Purpose:    Revised main estimation — addresses sample selection from
                maternal education, adds full-sample EA FE specifications,
                age-restricted estimates, lagged depression, and Ravens-only
    Author:     Pallab Ghosh, University of Oklahoma
    Created:    February 2026

    KEY CHANGE: The original Table 6 drops from N=11,981 to N=1,213 when
    maternal education is included (available for only 10% of sample).
    This file runs the preferred EA FE specification WITHOUT maternal
    education, preserving the full sample.
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

log using "$programs/02b_revised_estimation.log", replace

/* Load analysis dataset */
use "$programs/analysis_data.dta", clear
keep if analysis_sample == 1

/* Install required packages */
cap ssc install estout, replace
cap ssc install reghdfe, replace
cap ssc install ftools, replace

di _n "=============================================="
di "REVISED ESTIMATION: FULL-SAMPLE SPECIFICATIONS"
di "=============================================="
di "Analysis sample N = " _N

/* Report sample sizes with/without maternal education */
count
local N_full = r(N)
count if !missing(m_mother_educ_years)
local N_educ = r(N)
di _n "Full analysis sample: `N_full'"
di "With maternal education: `N_educ'"
di "Sample loss from including education: " `N_full' - `N_educ' " (" %4.1f 100*(1 - `N_educ'/`N_full') "%)"

/* Count EAs */
qui tab ea_id
di "Number of EAs in full sample: " r(r)
preserve
    keep if !missing(m_mother_educ_years)
    qui tab ea_id
    di "Number of EAs in education subsample: " r(r)
restore


/*==============================================================================
    TABLE 6 (REVISED): MAIN RESULTS — FULL SAMPLE EA FE
    Key innovation: Cols 1-4 do NOT include maternal education,
    preserving the full ~12,000 sample
==============================================================================*/

di _n "=============================================="
di "TABLE 6 REVISED: MAIN RESULTS (FULL SAMPLE)"
di "=============================================="

eststo clear

/* Column 1: Bivariate OLS — No controls (full sample) */
eststo r1: reg cog_index m_k10_std, ///
    cluster(ea_id)
estadd local child_ctrl "No"
estadd local mother_ctrl "No"
estadd local hh_ctrl "No"
estadd local ea_fe "No"
estadd local wave_fe "No"

/* Column 2: OLS + child + mother's age + HH controls (NO education — full sample) */
eststo r2: reg cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption, ///
    cluster(ea_id)
estadd local child_ctrl "Yes"
estadd local mother_ctrl "Age only"
estadd local hh_ctrl "Yes"
estadd local ea_fe "No"
estadd local wave_fe "No"

/* Column 3: EA FE + controls (NO education — full sample) *** PREFERRED *** */
eststo r3: reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local child_ctrl "Yes"
estadd local mother_ctrl "Age only"
estadd local hh_ctrl "Yes"
estadd local ea_fe "Yes"
estadd local wave_fe "Yes"

/* Column 4: EA FE + full controls INCLUDING education (restricted sample) */
eststo r4: reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    m_mother_educ_years hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local child_ctrl "Yes"
estadd local mother_ctrl "Age + Educ"
estadd local hh_ctrl "Yes"
estadd local ea_fe "Yes"
estadd local wave_fe "Yes"

/* Column 5: Child FE (full sample, time-invariant vars absorbed) */
eststo r5: reghdfe cog_index m_k10_std c_age hh_size, ///
    absorb(person_id wave) cluster(ea_id)
estadd local child_ctrl "Absorbed"
estadd local mother_ctrl "Absorbed"
estadd local hh_ctrl "HH size"
estadd local ea_fe "Child FE"
estadd local wave_fe "Yes"

/* Column 6: EA FE — Children ages 5-10 only (NO education) */
eststo r6: reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption if c_age >= 5 & c_age <= 10, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local child_ctrl "Yes"
estadd local mother_ctrl "Age only"
estadd local hh_ctrl "Yes"
estadd local ea_fe "Yes"
estadd local wave_fe "Yes"

/* LaTeX output — Revised Table 6 */
esttab r1 r2 r3 r4 r5 r6 using "$results/Table6_Revised_MainResults.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Maternal Depression on Child Cognitive Development (Revised)") ///
    mtitles("OLS" "OLS" "EA FE" "EA FE" "Child FE" "EA FE") ///
    mgroups("Full Sample" "Educ Sample" "Full" "Ages 5--10", ///
        pattern(1 0 0 1 1 1) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    keep(m_k10_std c_age m_age_harmonized m_mother_educ_years ///
         hh_size ln_pc_consumption) ///
    order(m_k10_std c_age m_age_harmonized m_mother_educ_years ///
          hh_size ln_pc_consumption) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        c_age "Child age" ///
        m_age_harmonized "Mother's age" ///
        m_mother_educ_years "Mother's education (years)" ///
        hh_size "Household size" ///
        ln_pc_consumption "Log per capita consumption" ///
    ) ///
    stats(ea_fe wave_fe N r2 r2_a, ///
        labels("EA/Child FE" "Wave FE" "Observations" "\$R^2$" "Adj. \$R^2$") ///
        fmt(%s %s %9.0fc %9.3f %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Columns (1)--(3) and (5)--(6) exclude maternal education to preserve the full sample." ///
             "Column (4) includes maternal education, restricting sample to ~10\% of observations." ///
             "Column (6) restricts to children aged 5--10." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

/* Text output */
esttab r1 r2 r3 r4 r5 r6 using "$results/Table6_Revised_MainResults.txt", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Maternal Depression on Child Cognitive Development (Revised)") ///
    mtitles("OLS" "OLS" "EA FE (Pref)" "EA FE (Educ)" "Child FE" "EA FE (5-10)") ///
    keep(m_k10_std c_age m_age_harmonized m_mother_educ_years ///
         hh_size ln_pc_consumption) ///
    stats(ea_fe wave_fe N r2 r2_a, ///
        labels("EA/Child FE" "Wave FE" "Observations" "R-squared" "Adj. R-squared") ///
        fmt(%s %s %9.0fc %9.3f %9.3f))


/*==============================================================================
    TABLE 6b: ADDITIONAL SPECIFICATIONS
    Ravens-only, lagged depression, age interactions, persistent depression,
    binary depression on full sample
==============================================================================*/

di _n "=============================================="
di "TABLE 6b: ADDITIONAL SPECIFICATIONS"
di "=============================================="

eststo clear

/* --- A. Ravens-only outcome with EA FE (no education) --- */
eststo a1: reghdfe ravens_std m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local spec "Ravens only"
estadd local fe "EA + Wave"

/* --- B. Binary depression on full sample (no education) --- */
eststo a2: reghdfe cog_index m_depressed_binary c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local spec "Binary dep"
estadd local fe "EA + Wave"

/* --- C. Depression severity on full sample (no education) --- */
/* Generate severity dummies if not already present */
cap drop dep_mild dep_moderate dep_severe
gen dep_mild = (m_depression_cat == 1) if m_depression_cat < .
gen dep_moderate = (m_depression_cat == 2) if m_depression_cat < .
gen dep_severe = (m_depression_cat == 3) if m_depression_cat < .

eststo a3: reghdfe cog_index dep_mild dep_moderate dep_severe ///
    c_age i.c_female m_age_harmonized hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local spec "Severity cats"
estadd local fe "EA + Wave"

/* --- D. Depression × Child Age interaction --- */
gen k10_age = m_k10_std * c_age

eststo a4: reghdfe cog_index m_k10_std k10_age c_age i.c_female ///
    m_age_harmonized hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local spec "Age interaction"
estadd local fe "EA + Wave"

/* --- E. Lagged depression (wave t-1 depression → wave t cognition) --- */
/* Create lagged K10 */
sort person_id wave
by person_id: gen m_k10_std_lag = m_k10_std[_n-1] if wave[_n-1] < wave

eststo a5: reghdfe cog_index m_k10_std_lag c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption if !missing(m_k10_std_lag), ///
    absorb(ea_id wave) cluster(ea_id)
estadd local spec "Lagged K10"
estadd local fe "EA + Wave"

/* --- F. Persistent depression (depressed in 2+ waves) --- */
bysort person_id: egen n_waves_dep = total(m_depressed_binary) if !missing(m_depressed_binary)
bysort person_id: egen n_waves_obs = count(m_depressed_binary)
gen persistent_dep = (n_waves_dep >= 2) if n_waves_obs >= 2

eststo a6: reghdfe cog_index persistent_dep c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption if !missing(persistent_dep), ///
    absorb(ea_id wave) cluster(ea_id)
estadd local spec "Persistent dep"
estadd local fe "EA + Wave"

/* LaTeX output — Table 6b */
esttab a1 a2 a3 a4 a5 a6 using "$results/Table6b_AdditionalSpecs.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Additional Specifications: Depression and Child Cognitive Outcomes") ///
    mtitles("Ravens" "Binary" "Severity" "Age Int." "Lagged" "Persistent") ///
    keep(m_k10_std m_depressed_binary dep_mild dep_moderate dep_severe ///
         k10_age m_k10_std_lag persistent_dep c_age) ///
    order(m_k10_std m_depressed_binary dep_mild dep_moderate dep_severe ///
          k10_age m_k10_std_lag persistent_dep c_age) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        m_depressed_binary "Depressed (K10 $\geq$ 20)" ///
        dep_mild "Mild (K10: 20--24)" ///
        dep_moderate "Moderate (K10: 25--29)" ///
        dep_severe "Severe (K10: 30--50)" ///
        k10_age "Depression $\times$ Child age" ///
        m_k10_std_lag "Lagged depression (std. K10, $t-1$)" ///
        persistent_dep "Persistent depression ($\geq$ 2 waves)" ///
        c_age "Child age" ///
    ) ///
    stats(spec fe N r2, ///
        labels("Specification" "Fixed Effects" "Observations" "\$R^2$") ///
        fmt(%s %s %9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "All specifications exclude maternal education to preserve the full sample." ///
             "All include EA and wave fixed effects, child age, gender, mother's age," ///
             "household size, and log per capita consumption." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

/* Text output */
esttab a1 a2 a3 a4 a5 a6 using "$results/Table6b_AdditionalSpecs.txt", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Additional Specifications: Depression and Child Cognitive Outcomes") ///
    mtitles("Ravens" "Binary" "Severity" "Age Int." "Lagged" "Persistent") ///
    keep(m_k10_std m_depressed_binary dep_mild dep_moderate dep_severe ///
         k10_age m_k10_std_lag persistent_dep c_age) ///
    stats(spec fe N r2, ///
        labels("Specification" "Fixed Effects" "Observations" "R-squared") ///
        fmt(%s %s %9.0fc %9.3f))


/*==============================================================================
    TABLE 6c: EA FE BY AGE GROUP (full sample, no education)
==============================================================================*/

di _n "=============================================="
di "TABLE 6c: HETEROGENEITY BY AGE (FULL SAMPLE)"
di "=============================================="

eststo clear

/* Ages 0-4 (very small N expected) */
cap noi eststo h1: reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption if c_age_group == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local fe "EA + Wave"
}

/* Ages 5-9 */
cap noi eststo h2: reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption if c_age_group == 2, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local fe "EA + Wave"
}

/* Ages 10-14 */
cap noi eststo h3: reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption if c_age_group == 3, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local fe "EA + Wave"
}

/* Ages 15-17 */
cap noi eststo h4: reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption if c_age_group == 4, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local fe "EA + Wave"
}

/* Pooled with age-group interactions */
cap noi eststo h5: reghdfe cog_index c.m_k10_std##ib1.c_age_group ///
    c_age i.c_female m_age_harmonized hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local fe "EA + Wave"
}

local h_models ""
foreach m in h1 h2 h3 h4 h5 {
    cap estimates describe `m'
    if _rc == 0 local h_models "`h_models' `m'"
}

cap noi esttab `h_models' using "$results/Table6c_HeterogeneityAge_FullSample.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Heterogeneous Effects by Child Age Group (Full Sample, No Education Control)") ///
    mtitles("Ages 0--4" "Ages 5--9" "Ages 10--14" "Ages 15--17" "Interactions") ///
    keep(m_k10_std 1.c_age_group#c.m_k10_std 2.c_age_group#c.m_k10_std ///
         3.c_age_group#c.m_k10_std 4.c_age_group#c.m_k10_std) ///
    coeflabels( ///
        m_k10_std "Depression (std. K10)" ///
        1.c_age_group#c.m_k10_std "Dep $\times$ Ages 0--4" ///
        2.c_age_group#c.m_k10_std "Dep $\times$ Ages 5--9" ///
        3.c_age_group#c.m_k10_std "Dep $\times$ Ages 10--14" ///
        4.c_age_group#c.m_k10_std "Dep $\times$ Ages 15--17" ///
    ) ///
    stats(fe N r2, labels("Fixed Effects" "Observations" "\$R^2$") ///
        fmt(%s %9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Full sample (no maternal education control)." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `h_models' using "$results/Table6c_HeterogeneityAge_FullSample.txt", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Heterogeneous Effects by Child Age Group (Full Sample)") ///
    mtitles("Ages 0-4" "Ages 5-9" "Ages 10-14" "Ages 15-17" "Interactions") ///
    keep(m_k10_std 1.c_age_group#c.m_k10_std 2.c_age_group#c.m_k10_std ///
         3.c_age_group#c.m_k10_std 4.c_age_group#c.m_k10_std) ///
    stats(fe N r2, labels("Fixed Effects" "Observations" "R-squared") ///
        fmt(%s %9.0fc %9.3f))


/*==============================================================================
    DIAGNOSTIC: Print key comparison
==============================================================================*/

di _n(3) "=============================================="
di "COMPARISON: WITH vs WITHOUT MATERNAL EDUCATION"
di "=============================================="

di _n "--- EA FE WITHOUT maternal education (full sample) ---"
reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

di _n "--- EA FE WITH maternal education (restricted sample) ---"
reghdfe cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    m_mother_educ_years hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

di _n "--- OLS WITHOUT maternal education (full sample) ---"
reg cog_index m_k10_std c_age i.c_female m_age_harmonized ///
    hh_size ln_pc_consumption, ///
    cluster(ea_id)

di _n(3) "=============================================="
di "ALL REVISED ESTIMATION COMPLETE"
di "=============================================="


log close

/*==============================================================================
    END OF REVISED ESTIMATION
==============================================================================*/
