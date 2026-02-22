/*==============================================================================
    Project:    Maternal Depression, Parental Investment, and Child Cognitive
                Development in Ghana
    File:       01_summary_stats.do
    Purpose:    Generate professional summary statistics tables for journal
                article (LaTeX, Excel, text, and PDF)
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

log using "$programs/01_summary_stats.log", replace

/* Load analysis dataset */
use "$programs/analysis_data.dta", clear

/* Keep analysis sample */
keep if analysis_sample == 1

di _n "=============================================="
di "ANALYSIS SAMPLE SIZE"
di "=============================================="
count
tab wave


/*==============================================================================
    TABLE 1: SUMMARY STATISTICS — FULL SAMPLE
==============================================================================*/

/* Panel A: Child Characteristics */
local child_vars "c_age c_female ravens_correct dsf_score dsb_score math_correct english_correct cog_index haz_approx waz_approx c_height c_weight attending_school"

/* Panel B: Maternal Characteristics */
local mother_vars "m_age_harmonized m_k10_score m_depressed_binary m_mother_educ_years m_weekly_hours m_pay_amount m_read_hw_time m_total_child_time m_careforkids_yn m_nhis_valid_card m_bmi"

/* Panel C: Household Characteristics */
local hh_vars "hh_size ln_pc_consumption total_food_exp"


/*--- Table 1: Overall Summary Statistics ---*/
/* Using estpost and esttab for professional output */

cap ssc install estout, replace
cap ssc install outreg2, replace

/* Method 1: estpost tabstat */
estpost tabstat c_age c_female ///
    ravens_correct dsf_score dsb_score math_correct english_correct ///
    cog_index haz_approx waz_approx ///
    m_age_harmonized m_k10_score m_depressed_binary ///
    m_mother_educ_years m_weekly_hours ///
    m_read_hw_time m_total_child_time m_careforkids_yn ///
    hh_size ln_pc_consumption, ///
    statistics(count mean sd min max) columns(statistics)

/* LaTeX output */
cap noi esttab using "$results/Table1_SummaryStats.tex", replace ///
    cells("count(fmt(%9.0fc)) mean(fmt(%9.3f)) sd(fmt(%9.3f)) min(fmt(%9.3f)) max(fmt(%9.3f))") ///
    noobs nonumber nomtitle ///
    title("Summary Statistics: Full Analysis Sample") ///
    addnotes("Source: Ghana Socioeconomic Panel Survey (GSPS), Waves 1--3." ///
             "Sample restricted to mother--child pairs with non-missing maternal depression (K10)" ///
             "and at least one child cognitive test score.") ///
    collabels("N" "Mean" "Std. Dev." "Min" "Max") ///
    coeflabels( ///
        c_age "Child age (years)" ///
        c_female "Child is female" ///
        ravens_correct "Raven's score (0--12)" ///
        dsf_score "Digit span forward (0--8)" ///
        dsb_score "Digit span backward (0--7)" ///
        math_correct "Math score (0--8)" ///
        english_correct "English score (0--7)" ///
        cog_index "Cognitive index (std. avg.)" ///
        haz_approx "Height-for-age z-score" ///
        waz_approx "Weight-for-age z-score" ///
        m_age_harmonized "Mother's age" ///
        m_k10_score "Mother's K10 depression score (10--50)" ///
        m_depressed_binary "Mother depressed (K10 $\geq$ 20)" ///
        m_mother_educ_years "Mother's education (years)" ///
        m_weekly_hours "Mother's weekly work hours" ///
        m_read_hw_time "Reading/homework time w/ child (hrs)" ///
        m_total_child_time "Total time with child (hrs)" ///
        m_careforkids_yn "Provides care for children" ///
        hh_size "Household size" ///
        ln_pc_consumption "Log per capita consumption" ///
    ) ///
    booktabs

/* Text output */
cap noi esttab using "$results/Table1_SummaryStats.txt", replace ///
    cells("count(fmt(%9.0fc)) mean(fmt(%9.3f)) sd(fmt(%9.3f)) min(fmt(%9.3f)) max(fmt(%9.3f))") ///
    noobs nonumber nomtitle ///
    title("Summary Statistics: Full Analysis Sample") ///
    collabels("N" "Mean" "Std. Dev." "Min" "Max") ///
    coeflabels( ///
        c_age "Child age (years)" ///
        c_female "Child is female" ///
        ravens_correct "Raven's score (0-12)" ///
        dsf_score "Digit span forward (0-8)" ///
        dsb_score "Digit span backward (0-7)" ///
        math_correct "Math score (0-8)" ///
        english_correct "English score (0-7)" ///
        cog_index "Cognitive index (std. avg.)" ///
        haz_approx "Height-for-age z-score" ///
        waz_approx "Weight-for-age z-score" ///
        m_age_harmonized "Mother's age" ///
        m_k10_score "Mother's K10 depression score (10-50)" ///
        m_depressed_binary "Mother depressed (K10 >= 20)" ///
        m_mother_educ_years "Mother's education (years)" ///
        m_weekly_hours "Mother's weekly work hours" ///
        m_read_hw_time "Reading/homework time w/ child (hrs)" ///
        m_total_child_time "Total time with child (hrs)" ///
        m_careforkids_yn "Provides care for children" ///
        hh_size "Household size" ///
        ln_pc_consumption "Log per capita consumption" ///
    )


/*==============================================================================
    TABLE 2: SUMMARY STATISTICS BY MATERNAL DEPRESSION STATUS
==============================================================================*/

/* Column 1: Not Depressed (K10 < 20) */
/* Column 2: Depressed (K10 >= 20) */
/* Column 3: Difference (with t-test p-value) */

local balance_vars "c_age c_female ravens_correct dsf_score dsb_score math_correct english_correct cog_index haz_approx waz_approx m_age_harmonized m_mother_educ_years m_weekly_hours m_read_hw_time m_total_child_time m_careforkids_yn hh_size ln_pc_consumption"

/* T-tests for each variable */
eststo clear

eststo not_dep: estpost summarize c_age c_female ///
    ravens_correct dsf_score dsb_score math_correct english_correct ///
    cog_index haz_approx waz_approx ///
    m_age_harmonized m_mother_educ_years m_weekly_hours ///
    m_read_hw_time m_total_child_time m_careforkids_yn ///
    hh_size ln_pc_consumption ///
    if m_depressed_binary == 0, detail

eststo depressed: estpost summarize c_age c_female ///
    ravens_correct dsf_score dsb_score math_correct english_correct ///
    cog_index haz_approx waz_approx ///
    m_age_harmonized m_mother_educ_years m_weekly_hours ///
    m_read_hw_time m_total_child_time m_careforkids_yn ///
    hh_size ln_pc_consumption ///
    if m_depressed_binary == 1, detail

/* T-test differences */
eststo diff: estpost ttest c_age c_female ///
    ravens_correct dsf_score dsb_score math_correct english_correct ///
    cog_index haz_approx waz_approx ///
    m_age_harmonized m_mother_educ_years m_weekly_hours ///
    m_read_hw_time m_total_child_time m_careforkids_yn ///
    hh_size ln_pc_consumption, ///
    by(m_depressed_binary) unequal

/* LaTeX output for balance table */
cap noi esttab not_dep depressed diff using "$results/Table2_BalanceByDepression.tex", replace ///
    cells("mean(pattern(1 1 0) fmt(%9.3f)) b(pattern(0 0 1) fmt(%9.3f) star) t(pattern(0 0 1) par fmt(%9.2f))") ///
    noobs nonumber ///
    mtitles("Not Depressed" "Depressed" "Difference") ///
    title("Summary Statistics by Maternal Depression Status") ///
    addnotes("Source: Ghana Socioeconomic Panel Survey (GSPS), Waves 1--3." ///
             "Not Depressed: K10 score $<$ 20. Depressed: K10 score $\geq$ 20." ///
             "$t$-statistics of the difference in parentheses." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    coeflabels( ///
        c_age "Child age (years)" ///
        c_female "Child is female" ///
        ravens_correct "Raven's score" ///
        dsf_score "Digit span forward" ///
        dsb_score "Digit span backward" ///
        math_correct "Math score" ///
        english_correct "English score" ///
        cog_index "Cognitive index" ///
        haz_approx "Height-for-age z-score" ///
        waz_approx "Weight-for-age z-score" ///
        m_age_harmonized "Mother's age" ///
        m_mother_educ_years "Mother's education (years)" ///
        m_weekly_hours "Mother's weekly work hours" ///
        m_read_hw_time "Reading/homework time (hrs)" ///
        m_total_child_time "Total child time (hrs)" ///
        m_careforkids_yn "Provides childcare" ///
        hh_size "Household size" ///
        ln_pc_consumption "Log per capita consumption" ///
    ) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs

/* Text output */
cap noi esttab not_dep depressed diff using "$results/Table2_BalanceByDepression.txt", replace ///
    cells("mean(pattern(1 1 0) fmt(%9.3f)) b(pattern(0 0 1) fmt(%9.3f) star) t(pattern(0 0 1) par fmt(%9.2f))") ///
    noobs nonumber ///
    mtitles("Not Depressed" "Depressed" "Difference") ///
    title("Summary Statistics by Maternal Depression Status") ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    coeflabels( ///
        c_age "Child age (years)" ///
        c_female "Child is female" ///
        ravens_correct "Raven's score" ///
        dsf_score "Digit span forward" ///
        dsb_score "Digit span backward" ///
        math_correct "Math score" ///
        english_correct "English score" ///
        cog_index "Cognitive index" ///
        haz_approx "Height-for-age z-score" ///
        waz_approx "Weight-for-age z-score" ///
        m_age_harmonized "Mother's age" ///
        m_mother_educ_years "Mother's education (years)" ///
        m_weekly_hours "Mother's weekly work hours" ///
        m_read_hw_time "Reading/homework time (hrs)" ///
        m_total_child_time "Total child time (hrs)" ///
        m_careforkids_yn "Provides childcare" ///
        hh_size "Household size" ///
        ln_pc_consumption "Log per capita consumption" ///
    )


/*==============================================================================
    TABLE 3: SUMMARY STATISTICS BY WAVE
==============================================================================*/

eststo clear

forvalues w = 1/3 {
    eststo wave`w': estpost summarize c_age c_female ///
        ravens_correct dsf_score dsb_score math_correct english_correct ///
        cog_index haz_approx waz_approx ///
        m_age_harmonized m_k10_score m_depressed_binary ///
        m_read_hw_time m_total_child_time ///
        hh_size ln_pc_consumption ///
        if wave == `w', detail
}

/* LaTeX output */
cap noi esttab wave1 wave2 wave3 using "$results/Table3_SummaryByWave.tex", replace ///
    cells("mean(fmt(%9.3f)) sd(par fmt(%9.3f)) count(fmt(%9.0f))") ///
    noobs nonumber ///
    mtitles("Wave 1 (2009)" "Wave 2 (2012)" "Wave 3 (2018)") ///
    title("Summary Statistics by Survey Wave") ///
    addnotes("Source: Ghana Socioeconomic Panel Survey (GSPS)." ///
             "Standard deviations in parentheses.") ///
    coeflabels( ///
        c_age "Child age" ///
        c_female "Child is female" ///
        ravens_correct "Raven's score" ///
        dsf_score "Digit span forward" ///
        dsb_score "Digit span backward" ///
        math_correct "Math score" ///
        english_correct "English score" ///
        cog_index "Cognitive index" ///
        haz_approx "Height-for-age z-score" ///
        waz_approx "Weight-for-age z-score" ///
        m_age_harmonized "Mother's age" ///
        m_k10_score "K10 depression score" ///
        m_depressed_binary "Mother depressed (K10 $\geq$ 20)" ///
        m_read_hw_time "Reading/homework time" ///
        m_total_child_time "Total child time" ///
        hh_size "Household size" ///
        ln_pc_consumption "Log per capita consumption" ///
    ) ///
    booktabs

/* Text output */
cap noi esttab wave1 wave2 wave3 using "$results/Table3_SummaryByWave.txt", replace ///
    cells("mean(fmt(%9.3f)) sd(par fmt(%9.3f)) count(fmt(%9.0f))") ///
    noobs nonumber ///
    mtitles("Wave 1 (2009)" "Wave 2 (2012)" "Wave 3 (2018)") ///
    title("Summary Statistics by Survey Wave") ///
    coeflabels( ///
        c_age "Child age" ///
        c_female "Child is female" ///
        ravens_correct "Raven's score" ///
        dsf_score "Digit span forward" ///
        dsb_score "Digit span backward" ///
        math_correct "Math score" ///
        english_correct "English score" ///
        cog_index "Cognitive index" ///
        haz_approx "Height-for-age z-score" ///
        waz_approx "Weight-for-age z-score" ///
        m_age_harmonized "Mother's age" ///
        m_k10_score "K10 depression score" ///
        m_depressed_binary "Mother depressed (K10 >= 20)" ///
        m_read_hw_time "Reading/homework time" ///
        m_total_child_time "Total child time" ///
        hh_size "Household size" ///
        ln_pc_consumption "Log per capita consumption" ///
    )


/*==============================================================================
    TABLE 4: DEPRESSION DISTRIBUTION
==============================================================================*/

/* Depression severity distribution */
tab m_depression_cat wave, col

/* Export depression distribution table */
eststo clear
estpost tabulate m_depression_cat wave, nototal
cap noi esttab using "$results/Table4_DepressionDistribution.tex", replace ///
    cells("b(fmt(%9.0f)) colpct(fmt(%9.1f) par)") ///
    nonumber noobs ///
    title("Distribution of Maternal Depression Severity by Wave") ///
    addnotes("K10 categories: Low (10--19), Mild (20--24), Moderate (25--29), Severe (30--50).") ///
    collabels("N" "\%") ///
    booktabs

/* Text output */
estpost tabulate m_depression_cat wave, nototal
cap noi esttab using "$results/Table4_DepressionDistribution.txt", replace ///
    cells("b(fmt(%9.0f)) colpct(fmt(%9.1f) par)") ///
    nonumber noobs ///
    title("Distribution of Maternal Depression Severity by Wave")


/*==============================================================================
    TABLE 5: CORRELATION MATRIX - KEY VARIABLES
==============================================================================*/

/* Correlation between depression and cognitive outcomes */
/* Note: dsf_score and dsb_score may be all-missing in analysis sample; exclude if so */
correlate m_k10_score cog_index ravens_correct ///
    math_correct english_correct haz_approx m_read_hw_time ///
    m_total_child_time ln_pc_consumption if analysis_sample == 1

/* Export correlation matrix */
estpost correlate m_k10_score cog_index ravens_correct ///
    math_correct english_correct haz_approx m_read_hw_time ///
    m_total_child_time ln_pc_consumption if analysis_sample == 1, ///
    matrix listwise

cap noi esttab using "$results/Table5_Correlations.tex", replace ///
    unstack not noobs compress nonumber ///
    title("Correlation Matrix: Key Variables") ///
    coeflabels( ///
        m_k10_score "K10 Depression" ///
        cog_index "Cognitive Index" ///
        ravens_correct "Raven's" ///
        math_correct "Math" ///
        english_correct "English" ///
        haz_approx "HAZ" ///
        m_read_hw_time "Read/HW Time" ///
        m_total_child_time "Total Child Time" ///
        ln_pc_consumption "Ln(PC Consump.)" ///
    ) ///
    addnotes("Source: GSPS analysis sample." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(%9.3f) ///
    booktabs

cap noi esttab using "$results/Table5_Correlations.txt", replace ///
    unstack not noobs compress nonumber ///
    title("Correlation Matrix: Key Variables") ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(%9.3f)


/*==============================================================================
    EXCEL OUTPUT: ALL SUMMARY STATISTICS
==============================================================================*/

/* Export to Excel using putexcel */
putexcel set "$results/SummaryStatistics.xlsx", sheet("Table1_Full") replace

/* Header */
putexcel A1 = "Table 1: Summary Statistics — Full Analysis Sample"
putexcel A2 = "Variable" B2 = "N" C2 = "Mean" D2 = "Std. Dev." E2 = "Min" F2 = "Max"

/* Child variables */
local row = 3
putexcel A`row' = "Panel A: Child Characteristics"
local row = `row' + 1

foreach var in c_age c_female ravens_correct dsf_score dsb_score ///
    math_correct english_correct cog_index haz_approx waz_approx {

    qui summarize `var'
    local lab: variable label `var'
    if "`lab'" == "" local lab "`var'"

    putexcel A`row' = "`lab'"
    putexcel B`row' = (r(N)), nformat(#,##0)
    putexcel C`row' = (r(mean)), nformat(0.000)
    putexcel D`row' = (r(sd)), nformat(0.000)
    putexcel E`row' = (r(min)), nformat(0.000)
    putexcel F`row' = (r(max)), nformat(0.000)
    local row = `row' + 1
}

/* Maternal variables */
putexcel A`row' = "Panel B: Maternal Characteristics"
local row = `row' + 1

foreach var in m_age_harmonized m_k10_score m_depressed_binary ///
    m_mother_educ_years m_weekly_hours ///
    m_read_hw_time m_total_child_time m_careforkids_yn {

    qui summarize `var'
    local lab: variable label `var'
    if "`lab'" == "" local lab "`var'"

    putexcel A`row' = "`lab'"
    putexcel B`row' = (r(N)), nformat(#,##0)
    putexcel C`row' = (r(mean)), nformat(0.000)
    putexcel D`row' = (r(sd)), nformat(0.000)
    putexcel E`row' = (r(min)), nformat(0.000)
    putexcel F`row' = (r(max)), nformat(0.000)
    local row = `row' + 1
}

/* Household variables */
putexcel A`row' = "Panel C: Household Characteristics"
local row = `row' + 1

foreach var in hh_size ln_pc_consumption {
    qui summarize `var'
    local lab: variable label `var'
    if "`lab'" == "" local lab "`var'"

    putexcel A`row' = "`lab'"
    putexcel B`row' = (r(N)), nformat(#,##0)
    putexcel C`row' = (r(mean)), nformat(0.000)
    putexcel D`row' = (r(sd)), nformat(0.000)
    putexcel E`row' = (r(min)), nformat(0.000)
    putexcel F`row' = (r(max)), nformat(0.000)
    local row = `row' + 1
}

putexcel save


/*==============================================================================
    ATTRITION TABLE
==============================================================================*/

/* Check attrition across waves */
use "$programs/analysis_data.dta", clear

/* Presence in each wave */
bysort person_id: gen in_w1 = (wave == 1)
bysort person_id: gen in_w2 = (wave == 2)
bysort person_id: gen in_w3 = (wave == 3)

bysort person_id: egen present_w1 = max(in_w1)
bysort person_id: egen present_w2 = max(in_w2)
bysort person_id: egen present_w3 = max(in_w3)

bysort person_id: egen n_waves = total(1)

/* Keep one observation per person */
bysort person_id: keep if _n == 1

di _n "=============================================="
di "PANEL ATTRITION"
di "=============================================="
tab present_w1 present_w2
tab present_w2 present_w3
tab n_waves

/* Attrition probit: does Wave 1 depression predict attrition? */
gen attrit_w2 = (present_w1 == 1 & present_w2 == 0)
gen attrit_w3 = (present_w2 == 1 & present_w3 == 0)


log close

/*==============================================================================
    END OF SUMMARY STATISTICS
==============================================================================*/
