/*==============================================================================
    Project:    Maternal Depression, Parental Investment, and Child Cognitive
                Development in Ghana
    File:       02_main_estimation.do
    Purpose:    Main regression analysis — OLS, EA FE, Household FE,
                IV estimation, and dynamic skill formation models
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

log using "$programs/02_main_estimation.log", replace

/* Load analysis dataset */
use "$programs/analysis_data.dta", clear
keep if analysis_sample == 1

/* Install required packages */
cap ssc install estout, replace
cap ssc install reghdfe, replace
cap ssc install ftools, replace
cap ssc install ivreg2, replace
cap ssc install ranktest, replace


/*==============================================================================
    DEFINE CONTROL VARIABLE SETS
==============================================================================*/

/* Child-level controls */
global child_controls "c_age i.c_female"

/* Maternal controls */
global maternal_controls "m_age_harmonized m_mother_educ_years"

/* Household controls */
global hh_controls "hh_size ln_pc_consumption"

/* Full controls */
global full_controls "$child_controls $maternal_controls $hh_controls"

/* Fixed effects */
/* EA fixed effects for cross-sectional identification */
/* Household FE for within-household variation (siblings) */
/* Wave FE for time trends */


/*==============================================================================
    TABLE 6: MAIN RESULTS — EFFECT OF MATERNAL DEPRESSION ON CHILD COGNITION
    Outcome: Composite Cognitive Index
==============================================================================*/

eststo clear

/* Column 1: Pooled OLS — No controls */
eststo m1: reg cog_index m_k10_std, ///
    cluster(ea_id)
estadd local ea_fe "No"
estadd local wave_fe "No"

/* Column 2: OLS + Child controls */
eststo m2: reg cog_index m_k10_std $child_controls, ///
    cluster(ea_id)
estadd local ea_fe "No"
estadd local wave_fe "No"

/* Column 3: OLS + Child + Maternal controls */
eststo m3: reg cog_index m_k10_std $child_controls $maternal_controls, ///
    cluster(ea_id)
estadd local ea_fe "No"
estadd local wave_fe "No"

/* Column 4: OLS + Full controls */
eststo m4: reg cog_index m_k10_std $full_controls, ///
    cluster(ea_id)
estadd local ea_fe "No"
estadd local wave_fe "No"

/* Column 5: EA Fixed Effects + Full controls */
eststo m5: reghdfe cog_index m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local ea_fe "Yes"
estadd local wave_fe "Yes"

/* Column 6: Child Fixed Effects */
eststo m6: reghdfe cog_index m_k10_std c_age i.c_female hh_size, ///
    absorb(person_id wave) cluster(ea_id)
estadd local ea_fe "Child FE"
estadd local wave_fe "Yes"

/* LaTeX output */
cap noi esttab m1 m2 m3 m4 m5 m6 using "$results/Table6_MainResults_CogIndex.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Maternal Depression on Child Cognitive Development") ///
    mtitles("OLS" "OLS" "OLS" "OLS" "EA FE" "Child FE") ///
    keep(m_k10_std m_age_harmonized m_mother_educ_years ///
         c_age hh_size ln_pc_consumption) ///
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
             "Dependent variable: composite cognitive index (average of standardized" ///
             "Raven's, digit span forward/backward, math, and English scores)." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

/* Text output */
cap noi esttab m1 m2 m3 m4 m5 m6 using "$results/Table6_MainResults_CogIndex.txt", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Maternal Depression on Child Cognitive Development") ///
    mtitles("OLS" "OLS" "OLS" "OLS" "EA FE" "Child FE") ///
    keep(m_k10_std m_age_harmonized m_mother_educ_years ///
         c_age hh_size ln_pc_consumption) ///
    stats(N r2 r2_a, labels("Observations" "R-squared" "Adj. R-squared") ///
        fmt(%9.0fc %9.3f %9.3f))

/* Excel output */
cap noi esttab m1 m2 m3 m4 m5 m6 using "$results/Table6_MainResults_CogIndex.csv", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0fc %9.3f)) csv


/*==============================================================================
    TABLE 7: RESULTS BY INDIVIDUAL COGNITIVE TEST
    Each column = different cognitive outcome
==============================================================================*/

eststo clear

/* Raven's Progressive Matrices */
eststo t1: reghdfe ravens_std m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
estadd local controls "Yes"
estadd local fe "EA + Wave"

/* Digit Span Forward -- may have insufficient observations */
cap noi eststo t2: reghdfe dsf_std m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local fe "EA + Wave"
}

/* Digit Span Backward -- may have insufficient observations */
cap noi eststo t3: reghdfe dsb_std m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local fe "EA + Wave"
}

/* Math -- may have insufficient observations */
cap noi eststo t4: reghdfe math_std m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local fe "EA + Wave"
}

/* English -- may have insufficient observations */
cap noi eststo t5: reghdfe english_std m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local fe "EA + Wave"
}

/* Composite Index (for reference) */
cap noi eststo t6: reghdfe cog_index m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local fe "EA + Wave"
}

/* LaTeX output -- only include estimates that exist */
local table7_models ""
foreach m in t1 t2 t3 t4 t5 t6 {
    cap estimates describe `m'
    if _rc == 0 local table7_models "`table7_models' `m'"
}

cap noi esttab `table7_models' using "$results/Table7_ResultsByTest.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Maternal Depression on Individual Cognitive Tests") ///
    keep(m_k10_std) ///
    coeflabels(m_k10_std "Maternal depression (std. K10)") ///
    stats(controls fe N r2, ///
        labels("Controls" "Fixed Effects" "Observations" "\$R^2$") ///
        fmt(%s %s %9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "All models include EA and wave fixed effects." ///
             "Controls: child age, child gender, mother's age, mother's education," ///
             "household size, and log per capita consumption." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `table7_models' using "$results/Table7_ResultsByTest.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Raven's" "Digit Fwd" "Digit Bwd" "Math" "English" "Composite") ///
    keep(m_k10_std) ///
    stats(controls fe N r2, fmt(%s %s %9.0fc %9.3f))

cap noi esttab `table7_models' using "$results/Table7_ResultsByTest.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) csv ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    TABLE 8: BINARY DEPRESSION INDICATOR
    Using depressed (K10 >= 20) instead of continuous K10
==============================================================================*/

eststo clear

cap noi eststo b1: reg cog_index m_depressed_binary $full_controls, ///
    cluster(ea_id)

cap noi eststo b2: reghdfe cog_index m_depressed_binary $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo b3: reghdfe ravens_std m_depressed_binary $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo b4: reghdfe math_std m_depressed_binary $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo b5: reghdfe english_std m_depressed_binary $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

local b_models ""
foreach m in b1 b2 b3 b4 b5 {
    cap estimates describe `m'
    if _rc == 0 local b_models "`b_models' `m'"
}

cap noi esttab `b_models' using "$results/Table8_BinaryDepression.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Maternal Depression (Binary) on Child Cognitive Outcomes") ///
    mtitles("Cog Index" "Cog Index" "Raven's" "Math" "English") ///
    keep(m_depressed_binary) ///
    coeflabels(m_depressed_binary "Mother depressed (K10 $\geq$ 20)") ///
    indicate("Child controls = c_age 1.c_female" ///
             "Maternal controls = m_age_harmonized m_mother_educ_years" ///
             "Household controls = hh_size ln_pc_consumption") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Depressed = K10 score $\geq$ 20 (mild, moderate, or severe depression)." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `b_models' using "$results/Table8_BinaryDepression.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Cog Index" "Cog Index" "Raven's" "Math" "English") ///
    keep(m_depressed_binary) ///
    stats(N r2, fmt(%9.0fc %9.3f))

cap noi esttab `b_models' using "$results/Table8_BinaryDepression.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) csv ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    TABLE 9: DEPRESSION SEVERITY CATEGORIES
==============================================================================*/

eststo clear

/* Generate severity dummies (base = Low/no depression) */
gen dep_mild = (m_depression_cat == 1) if m_depression_cat < .
gen dep_moderate = (m_depression_cat == 2) if m_depression_cat < .
gen dep_severe = (m_depression_cat == 3) if m_depression_cat < .

cap noi eststo s1: reghdfe cog_index dep_mild dep_moderate dep_severe ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo s2: reghdfe ravens_std dep_mild dep_moderate dep_severe ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo s3: reghdfe math_std dep_mild dep_moderate dep_severe ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo s4: reghdfe english_std dep_mild dep_moderate dep_severe ///
    $child_controls $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

local s_models ""
foreach m in s1 s2 s3 s4 {
    cap estimates describe `m'
    if _rc == 0 local s_models "`s_models' `m'"
}
cap noi esttab `s_models' using "$results/Table9_DepressionSeverity.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Maternal Depression Severity on Child Cognitive Outcomes") ///
    mtitles("Cog Index" "Raven's" "Math" "English") ///
    keep(dep_mild dep_moderate dep_severe) ///
    coeflabels( ///
        dep_mild "Mild depression (K10: 20--24)" ///
        dep_moderate "Moderate depression (K10: 25--29)" ///
        dep_severe "Severe depression (K10: 30--50)" ///
    ) ///
    indicate("Controls = c_age 1.c_female m_age_harmonized m_mother_educ_years hh_size ln_pc_consumption") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "Reference category: Low/no depression (K10: 10--19)." ///
             "All models include EA and wave fixed effects." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `s_models' using "$results/Table9_DepressionSeverity.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Cog Index" "Raven's" "Math" "English") ///
    keep(dep_mild dep_moderate dep_severe) ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    TABLE 10: EFFECT ON CHILD ANTHROPOMETRY (HAZ, WAZ)
==============================================================================*/

eststo clear

cap noi eststo a1: reghdfe haz_approx m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo a2: reghdfe waz_approx m_k10_std $child_controls $maternal_controls ///
    hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo a3: reghdfe haz_approx m_depressed_binary $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo a4: reghdfe waz_approx m_depressed_binary $child_controls ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

local a_models ""
foreach m in a1 a2 a3 a4 {
    cap estimates describe `m'
    if _rc == 0 local a_models "`a_models' `m'"
}
cap noi esttab `a_models' using "$results/Table10_Anthropometry.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Maternal Depression on Child Anthropometry") ///
    mtitles("HAZ" "WAZ" "HAZ" "WAZ") ///
    keep(m_k10_std m_depressed_binary) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        m_depressed_binary "Mother depressed (K10 $\geq$ 20)" ///
    ) ///
    indicate("Controls = c_age 1.c_female m_age_harmonized m_mother_educ_years hh_size ln_pc_consumption") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "HAZ = height-for-age z-score. WAZ = weight-for-age z-score." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `a_models' using "$results/Table10_Anthropometry.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("HAZ" "WAZ" "HAZ" "WAZ") ///
    keep(m_k10_std m_depressed_binary) ///
    stats(N r2, fmt(%9.0fc %9.3f))

cap noi esttab `a_models' using "$results/Table10_Anthropometry.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) csv ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    TABLE 11: HETEROGENEITY BY CHILD AGE GROUP
==============================================================================*/

eststo clear

forvalues g = 1/3 {
    cap noi eststo age`g': reghdfe cog_index m_k10_std $child_controls ///
        $maternal_controls hh_size ln_pc_consumption ///
        if c_age_group == `g', ///
        absorb(ea_id wave) cluster(ea_id)
}

local age_models ""
foreach m in age1 age2 age3 {
    cap estimates describe `m'
    if _rc == 0 local age_models "`age_models' `m'"
}
cap noi esttab `age_models' using "$results/Table11_HeterogeneityAge.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Heterogeneous Effects of Maternal Depression by Child Age Group") ///
    mtitles("Ages 0--4" "Ages 5--9" "Ages 10--14") ///
    keep(m_k10_std) ///
    coeflabels(m_k10_std "Maternal depression (std. K10)") ///
    indicate("Controls = c_age 1.c_female m_age_harmonized m_mother_educ_years hh_size ln_pc_consumption") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `age_models' using "$results/Table11_HeterogeneityAge.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Ages 0-4" "Ages 5-9" "Ages 10-14") ///
    keep(m_k10_std) ///
    stats(N r2, fmt(%9.0fc %9.3f))


/*==============================================================================
    TABLE 12: HETEROGENEITY BY CHILD GENDER
==============================================================================*/

eststo clear

cap noi eststo girls: reghdfe cog_index m_k10_std c_age $maternal_controls ///
    hh_size ln_pc_consumption if c_female == 1, ///
    absorb(ea_id wave) cluster(ea_id)

cap noi eststo boys: reghdfe cog_index m_k10_std c_age $maternal_controls ///
    hh_size ln_pc_consumption if c_female == 0, ///
    absorb(ea_id wave) cluster(ea_id)

/* Interaction model */
gen k10_female = m_k10_std * c_female

cap noi eststo interact: reghdfe cog_index m_k10_std c_female k10_female c_age ///
    $maternal_controls hh_size ln_pc_consumption, ///
    absorb(ea_id wave) cluster(ea_id)

local g_models ""
foreach m in girls boys interact {
    cap estimates describe `m'
    if _rc == 0 local g_models "`g_models' `m'"
}
cap noi esttab `g_models' using "$results/Table12_HeterogeneityGender.tex", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Heterogeneous Effects of Maternal Depression by Child Gender") ///
    mtitles("Girls" "Boys" "Interaction") ///
    keep(m_k10_std k10_female c_female) ///
    order(m_k10_std c_female k10_female) ///
    coeflabels( ///
        m_k10_std "Maternal depression (std. K10)" ///
        c_female "Child is female" ///
        k10_female "Depression $\times$ Female child" ///
    ) ///
    indicate("Controls = c_age m_age_harmonized m_mother_educ_years hh_size ln_pc_consumption" ///
             "EA FE = " "Wave FE = ") ///
    stats(N r2, labels("Observations" "\$R^2$") fmt(%9.0fc %9.3f)) ///
    addnotes("Standard errors clustered at the EA level in parentheses." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    booktabs

cap noi esttab `g_models' using "$results/Table12_HeterogeneityGender.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Girls" "Boys" "Interaction") ///
    keep(m_k10_std k10_female c_female) ///
    stats(N r2, fmt(%9.0fc %9.3f))


log close

/*==============================================================================
    END OF MAIN ESTIMATION
==============================================================================*/
