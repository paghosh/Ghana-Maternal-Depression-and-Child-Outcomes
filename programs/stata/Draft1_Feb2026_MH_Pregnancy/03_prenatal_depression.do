/*==============================================================================
    Project:    Maternal Depression, Parental Investment, and Child Cognitive
                Development in Ghana
    File:       03_prenatal_depression.do
    Purpose:    Identify prenatal maternal depression using (A) current pregnancy
                status at K10 measurement and (B) retrospective birth timing,
                then estimate effects on child cognitive development
    Author:     Pallab Ghosh, University of Oklahoma
    Created:    February 2026
    Data:       Ghana Socioeconomic Panel Survey (GSPS), Waves 1-3

    STRATEGIES:
    A. Concurrent pregnancy: Mother was pregnant when K10 was measured
    B. Birth timing: Child was born 0-9 months after a previous wave's
       K10 interview, implying in utero exposure to measured depression
==============================================================================*/

clear all
set more off
cap log close

/*------------------------------------------------------------------------------
    Global Paths
------------------------------------------------------------------------------*/
global project  "/Users/pallab.ghosh/Library/CloudStorage/Dropbox/D/Study/My_Papers/OU/Health/Ghana_mental_health/maternal_depression_child_cog_devlopment"
global data     "/Users/pallab.ghosh/Library/CloudStorage/Dropbox/D/Study/My_Papers/OU/Health/Ghana_mental_health/data/Ghana_Panel_Survey/Data"
global programs "$project/programs/stata/Draft1_Feb2026_MH_Pregnancy"
global results  "$project/rersults/Draft1_Feb2026_MH_Pregnancy"
global temp     "$project/programs/stata/Draft1_Feb2026_MH_Pregnancy/temp"
global programs_main "$project/programs/stata/Draft1_Feb2026"

cap mkdir "$temp"
cap mkdir "$results"

log using "$programs/03_prenatal_depression.log", replace

/* Install required packages */
cap ssc install estout, replace
cap ssc install reghdfe, replace
cap ssc install ftools, replace


/*==============================================================================
    PART 1: EXTRACT PREGNANCY STATUS FROM FERTILITY FILES
==============================================================================*/

di _n(3) "=============================================="
di "PART 1: Extracting pregnancy status"
di "=============================================="

/*--- Wave 1: s7a.dta ---*/
use "$data/Wave 1/s7a.dta", clear

/* s7a_24 = pregnant now, s7a_25 = pregnant last year
   These are numeric with value labels (1=Yes, 2=No typically) */
cap confirm string variable s7a_24
if _rc == 0 {
    gen pregnant_now = (s7a_24 == "Yes") if !missing(s7a_24)
}
else {
    decode s7a_24, gen(_tmp_pn)
    gen pregnant_now = (upper(strtrim(_tmp_pn)) == "YES") if !missing(s7a_24)
    drop _tmp_pn
}

cap confirm string variable s7a_25
if _rc == 0 {
    gen pregnant_last_year = (s7a_25 == "Yes") if !missing(s7a_25)
}
else {
    decode s7a_25, gen(_tmp_ply)
    gen pregnant_last_year = (upper(strtrim(_tmp_ply)) == "YES") if !missing(s7a_25)
    drop _tmp_ply
}

/* FPrimary is int32 in Wave 1 — convert to string */
cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

rename hhmid mother_hhmid
cap drop wave
gen wave = 1
keep FPrimary mother_hhmid wave pregnant_now pregnant_last_year
duplicates drop FPrimary mother_hhmid, force

di "Wave 1 pregnancy:"
tab pregnant_now, m
tab pregnant_last_year, m

save "$temp/w1_pregnancy.dta", replace


/*--- Wave 2: 07a_fertility.dta ---*/
use "$data/Wave 2/07a_fertility.dta", clear

/* pregnantnow, pregnantlastyear — numeric with value labels */
cap confirm string variable pregnantnow
if _rc == 0 {
    gen pregnant_now = (pregnantnow == "Yes") if !missing(pregnantnow)
}
else {
    decode pregnantnow, gen(_tmp_pn)
    gen pregnant_now = (upper(strtrim(_tmp_pn)) == "YES") if !missing(pregnantnow)
    drop _tmp_pn
}

cap confirm string variable pregnantlastyear
if _rc == 0 {
    gen pregnant_last_year = (pregnantlastyear == "Yes") if !missing(pregnantlastyear)
}
else {
    decode pregnantlastyear, gen(_tmp_ply)
    gen pregnant_last_year = (upper(strtrim(_tmp_ply)) == "YES") if !missing(pregnantlastyear)
    drop _tmp_ply
}

/* FPrimary is string in Wave 2 */
cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

rename hhmid mother_hhmid
cap drop wave
gen wave = 2
keep FPrimary mother_hhmid wave pregnant_now pregnant_last_year
duplicates drop FPrimary mother_hhmid, force

di "Wave 2 pregnancy:"
tab pregnant_now, m
tab pregnant_last_year, m

save "$temp/w2_pregnancy.dta", replace


/*--- Wave 3: 07a_fertility.dta ---*/
use "$data/Wave 3/07a_fertility.dta", clear

/* Filter to females only (Wave 3 includes males) */
cap confirm string variable sex
if _rc == 0 {
    keep if sex == "Female"
}
else {
    cap decode sex, gen(_tmp_sex)
    if _rc == 0 {
        keep if upper(strtrim(_tmp_sex)) == "FEMALE"
        drop _tmp_sex
    }
    else {
        /* Try numeric: typically 2=Female */
        cap keep if sex == 2
    }
}

cap confirm string variable pregnantnow
if _rc == 0 {
    gen pregnant_now = (pregnantnow == "Yes") if !missing(pregnantnow)
}
else {
    decode pregnantnow, gen(_tmp_pn)
    gen pregnant_now = (upper(strtrim(_tmp_pn)) == "YES") if !missing(pregnantnow)
    drop _tmp_pn
}

cap confirm string variable pregnantlastyear
if _rc == 0 {
    gen pregnant_last_year = (pregnantlastyear == "Yes") if !missing(pregnantlastyear)
}
else {
    decode pregnantlastyear, gen(_tmp_ply)
    gen pregnant_last_year = (upper(strtrim(_tmp_ply)) == "YES") if !missing(pregnantlastyear)
    drop _tmp_ply
}

cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

rename hhmid mother_hhmid
cap drop wave
gen wave = 3
keep FPrimary mother_hhmid wave pregnant_now pregnant_last_year
duplicates drop FPrimary mother_hhmid, force

di "Wave 3 pregnancy:"
tab pregnant_now, m
tab pregnant_last_year, m

save "$temp/w3_pregnancy.dta", replace


/*--- Append all waves ---*/
use "$temp/w1_pregnancy.dta", clear
append using "$temp/w2_pregnancy.dta"
append using "$temp/w3_pregnancy.dta"

save "$temp/pregnancy_panel.dta", replace

di _n "Pregnancy status panel:"
tab wave pregnant_now, m
tab wave pregnant_last_year, m


/*--- Merge pregnancy onto analysis data ---*/
use "$programs_main/analysis_data.dta", clear

/* Ensure FPrimary is string */
cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

merge m:1 FPrimary mother_hhmid wave using "$temp/pregnancy_panel.dta", ///
    keep(master match) nogen

/* Label */
label variable pregnant_now "Mother currently pregnant at interview"
label variable pregnant_last_year "Mother pregnant in last year"

di _n "Pregnancy status merged onto analysis data:"
tab wave pregnant_now if analysis_sample == 1, m
tab wave pregnant_last_year if analysis_sample == 1, m

/* Strategy A: Prenatal depression = mother's K10 when she was pregnant */
gen prenatal_k10_A = m_k10_score if pregnant_now == 1
gen prenatal_depressed_A = (m_k10_score >= 30) if pregnant_now == 1 & !missing(m_k10_score)
label variable prenatal_k10_A "Prenatal K10 (Strategy A: pregnant at interview)"
label variable prenatal_depressed_A "Prenatal depressed (Strategy A: pregnant at interview)"

di _n "Strategy A: Mothers with K10 measured while pregnant:"
count if !missing(prenatal_k10_A)
tab wave if !missing(prenatal_k10_A)

save "$temp/analysis_prenatal_step1.dta", replace


/*==============================================================================
    PART 2: CONSTRUCT PRENATAL DEPRESSION VIA BIRTH TIMING (STRATEGY B)
==============================================================================*/

di _n(3) "=============================================="
di "PART 2: Birth-timing strategy for prenatal depression"
di "=============================================="

/*--- Step 2a: Get interview dates per household-wave ---*/

/* Wave 1 interview dates: sec0.dta */
use "$data/Wave 1/sec0.dta", clear

/* day, month, year are integer columns */
gen interview_date_w1 = mdy(month, day, year)
format interview_date_w1 %td

cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

keep FPrimary interview_date_w1
duplicates drop FPrimary, force

di "Wave 1 interview dates:"
sum interview_date_w1
di "Range: " %td r(min) " to " %td r(max)

save "$temp/w1_interview_date.dta", replace


/* Wave 2 interview dates: 01b2_roster.dta — use checkdate */
use "$data/Wave 2/01b2_roster.dta", clear

/* checkdate is stored as int with %td format (already a Stata date) */
cap confirm numeric variable checkdate
if _rc == 0 {
    gen interview_date_w2 = checkdate
    format interview_date_w2 %td
}
else {
    gen interview_date_w2 = date(checkdate, "DMY")
    format interview_date_w2 %td
}

cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

/* Collapse to household level (one date per FPrimary) */
keep FPrimary interview_date_w2
drop if missing(interview_date_w2)
bysort FPrimary: keep if _n == 1

di "Wave 2 interview dates:"
sum interview_date_w2
di "Range: " %td r(min) " to " %td r(max)

save "$temp/w2_interview_date.dta", replace


/*--- Step 2b: Get child birth dates ---*/

/* Wave 2 birth dates from roster */
use "$data/Wave 2/01b2_roster.dta", clear

cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

/* dateofbirth is stored as float with %td format (already a Stata date) */
cap confirm numeric variable dateofbirth
if _rc == 0 {
    gen child_birth_date = dateofbirth
    format child_birth_date %td
}
else {
    gen child_birth_date = date(dateofbirth, "DMY")
    format child_birth_date %td
}

/* Filter out clearly erroneous dates (before 1900 or after 2020) */
replace child_birth_date = . if child_birth_date < mdy(1,1,1900)
replace child_birth_date = . if child_birth_date > mdy(12,31,2020) & !missing(child_birth_date)

/* Also extract year from yearofbirth as fallback */
cap gen birth_year = yearofbirth
cap gen birth_month = month(child_birth_date)

rename hhmid child_hhmid
keep FPrimary child_hhmid child_birth_date birth_year birth_month
drop if missing(child_birth_date) & missing(birth_year)
duplicates drop FPrimary child_hhmid, force

di "Wave 2 child birth dates (from Wave 2 roster):"
sum child_birth_date birth_year

save "$temp/w2_child_birthdates.dta", replace


/* Wave 3 birth dates from roster */
use "$data/Wave 3/01b2_roster.dta", clear

cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

/* dateofbirth is stored as float with %td format (already a Stata date) */
cap confirm numeric variable dateofbirth
if _rc == 0 {
    gen child_birth_date = dateofbirth
    format child_birth_date %td
}
else {
    gen child_birth_date = date(dateofbirth, "DMY")
    format child_birth_date %td
}

/* Filter out clearly erroneous dates */
replace child_birth_date = . if child_birth_date < mdy(1,1,1900)
replace child_birth_date = . if child_birth_date > mdy(12,31,2020) & !missing(child_birth_date)

cap gen birth_year = yearofbirth
cap gen birth_month = month(child_birth_date)

rename hhmid child_hhmid
keep FPrimary child_hhmid child_birth_date birth_year birth_month
drop if missing(child_birth_date) & missing(birth_year)
duplicates drop FPrimary child_hhmid, force

di "Wave 3 child birth dates (from Wave 3 roster):"
sum child_birth_date birth_year

save "$temp/w3_child_birthdates.dta", replace


/* Wave 1 birth dates from s1d.dta */
use "$data/Wave 1/s1d.dta", clear

cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

/* s1d_3ii = birth month, s1d_3iii = birth year
   These are stored as numeric values (1-12 for months, literal years).
   Value labels map to themselves, so use numeric values directly. */
gen birth_month = s1d_3ii if s1d_3ii >= 1 & s1d_3ii <= 12
gen birth_year = s1d_3iii if s1d_3iii >= 1900 & s1d_3iii <= 2020

/* Construct birth date (use 15th of month as midpoint) */
gen child_birth_date = mdy(birth_month, 15, birth_year) if ///
    !missing(birth_month) & !missing(birth_year)
format child_birth_date %td

rename hhmid child_hhmid
keep FPrimary child_hhmid child_birth_date birth_year birth_month
drop if missing(child_birth_date) & missing(birth_year)

if _N > 0 {
    duplicates drop FPrimary child_hhmid, force
}

di "Wave 1 child birth dates (from s1d.dta):"
di "N = " _N
sum child_birth_date birth_year

save "$temp/w1_child_birthdates.dta", replace


/*--- Step 2c: Identify children in utero during a previous wave ---*/

/* Load analysis data with pregnancy info from Step 1 */
use "$temp/analysis_prenatal_step1.dta", clear

/* Merge interview dates */
merge m:1 FPrimary using "$temp/w1_interview_date.dta", ///
    keep(master match) nogen
merge m:1 FPrimary using "$temp/w2_interview_date.dta", ///
    keep(master match) nogen

/* Merge child birth dates — use m:1 since analysis data has multiple waves per child */
/* Try Wave 2, then Wave 3, then Wave 1 */
merge m:1 FPrimary child_hhmid using "$temp/w2_child_birthdates.dta", ///
    keep(master match) nogen
rename child_birth_date child_birth_date_w2
rename birth_year birth_year_w2
rename birth_month birth_month_w2

merge m:1 FPrimary child_hhmid using "$temp/w3_child_birthdates.dta", ///
    keep(master match) nogen
rename child_birth_date child_birth_date_w3
rename birth_year birth_year_w3
rename birth_month birth_month_w3

merge m:1 FPrimary child_hhmid using "$temp/w1_child_birthdates.dta", ///
    keep(master match) nogen
rename child_birth_date child_birth_date_w1
rename birth_year birth_year_w1
rename birth_month birth_month_w1

/* Use best available birth date (prefer later wave for more recent info) */
gen child_birth_date = child_birth_date_w3
replace child_birth_date = child_birth_date_w2 if missing(child_birth_date)
replace child_birth_date = child_birth_date_w1 if missing(child_birth_date)
format child_birth_date %td

gen birth_year_best = birth_year_w3
replace birth_year_best = birth_year_w2 if missing(birth_year_best)
replace birth_year_best = birth_year_w1 if missing(birth_year_best)

di _n "Children with birth dates:"
count if !missing(child_birth_date)
count if missing(child_birth_date) & !missing(birth_year_best)

/* Compute months between wave interview and child birth */
/* Strategy B: Child born 0-9 months after Wave t interview → in utero at Wave t */

/* For Wave 2 children: were they in utero during Wave 1? */
gen months_since_w1 = (child_birth_date - interview_date_w1) / 30.44 ///
    if !missing(child_birth_date) & !missing(interview_date_w1)

/* For Wave 3 children: were they in utero during Wave 2? */
gen months_since_w2 = (child_birth_date - interview_date_w2) / 30.44 ///
    if !missing(child_birth_date) & !missing(interview_date_w2)

di _n "Months between Wave 1 interview and child birth:"
sum months_since_w1, detail
di _n "Months between Wave 2 interview and child birth:"
sum months_since_w2, detail

/* Flag children who were in utero during previous wave (0-9 month window) */
gen in_utero_w1 = (months_since_w1 >= 0 & months_since_w1 <= 9) ///
    if !missing(months_since_w1)
gen in_utero_w2 = (months_since_w2 >= 0 & months_since_w2 <= 9) ///
    if !missing(months_since_w2)

di _n "Children in utero during Wave 1 interview:"
tab in_utero_w1, m
di _n "Children in utero during Wave 2 interview:"
tab in_utero_w2, m


/*--- Step 2d: Link prenatal K10 from previous wave ---*/

/* We need mother's K10 from the wave when the child was in utero.
   The current data has m_k10_score for each observation's own wave.
   We need to bring in the mother's K10 from the PREVIOUS wave. */

/* Get mother's K10 scores by wave — save as separate temp files */

/* Wave 1 K10 */
preserve
    keep FPrimary mother_hhmid wave m_k10_score m_k10_std
    keep if !missing(m_k10_score) & wave == 1
    duplicates drop FPrimary mother_hhmid, force
    rename m_k10_score m_k10_w1
    rename m_k10_std m_k10_std_w1
    gen m_depressed_w1 = (m_k10_w1 >= 30) if !missing(m_k10_w1)
    keep FPrimary mother_hhmid m_k10_w1 m_k10_std_w1 m_depressed_w1
    save "$temp/mother_k10_w1.dta", replace
restore

/* Wave 2 K10 */
preserve
    keep FPrimary mother_hhmid wave m_k10_score m_k10_std
    keep if !missing(m_k10_score) & wave == 2
    duplicates drop FPrimary mother_hhmid, force
    rename m_k10_score m_k10_w2
    rename m_k10_std m_k10_std_w2
    gen m_depressed_w2 = (m_k10_w2 >= 30) if !missing(m_k10_w2)
    keep FPrimary mother_hhmid m_k10_w2 m_k10_std_w2 m_depressed_w2
    save "$temp/mother_k10_w2.dta", replace
restore

/* Merge mother's wave-specific K10 */
merge m:1 FPrimary mother_hhmid using "$temp/mother_k10_w1.dta", ///
    keep(master match) nogen
merge m:1 FPrimary mother_hhmid using "$temp/mother_k10_w2.dta", ///
    keep(master match) nogen

/* Assign prenatal K10 from the wave when child was in utero */
gen prenatal_k10_B = .
gen prenatal_depressed_B = .

/* Child in utero at Wave 1 → assign Wave 1 K10 */
replace prenatal_k10_B = m_k10_w1 if in_utero_w1 == 1 & !missing(m_k10_w1)
replace prenatal_depressed_B = m_depressed_w1 if in_utero_w1 == 1 & !missing(m_depressed_w1)

/* Child in utero at Wave 2 → assign Wave 2 K10 */
replace prenatal_k10_B = m_k10_w2 if in_utero_w2 == 1 & !missing(m_k10_w2)
replace prenatal_depressed_B = m_depressed_w2 if in_utero_w2 == 1 & !missing(m_depressed_w2)

label variable prenatal_k10_B "Prenatal K10 (Strategy B: birth timing)"
label variable prenatal_depressed_B "Prenatal depressed (Strategy B: birth timing)"

di _n "Strategy B: Children with prenatal depression from birth timing:"
count if !missing(prenatal_k10_B)
tab wave if !missing(prenatal_k10_B)

/* Also create variant windows for sensitivity */
gen in_utero_w1_6mo = (months_since_w1 >= 0 & months_since_w1 <= 6) ///
    if !missing(months_since_w1)
gen in_utero_w2_6mo = (months_since_w2 >= 0 & months_since_w2 <= 6) ///
    if !missing(months_since_w2)
gen in_utero_w1_12mo = (months_since_w1 >= 0 & months_since_w1 <= 12) ///
    if !missing(months_since_w1)
gen in_utero_w2_12mo = (months_since_w2 >= 0 & months_since_w2 <= 12) ///
    if !missing(months_since_w2)

/* 6-month window */
gen prenatal_k10_B6 = .
replace prenatal_k10_B6 = m_k10_w1 if in_utero_w1_6mo == 1 & !missing(m_k10_w1)
replace prenatal_k10_B6 = m_k10_w2 if in_utero_w2_6mo == 1 & !missing(m_k10_w2)

/* 12-month window */
gen prenatal_k10_B12 = .
replace prenatal_k10_B12 = m_k10_w1 if in_utero_w1_12mo == 1 & !missing(m_k10_w1)
replace prenatal_k10_B12 = m_k10_w2 if in_utero_w2_12mo == 1 & !missing(m_k10_w2)

/* Combined prenatal measure: use Strategy A if available, else Strategy B */
gen prenatal_k10 = prenatal_k10_A
replace prenatal_k10 = prenatal_k10_B if missing(prenatal_k10)
gen prenatal_depressed = prenatal_depressed_A
replace prenatal_depressed = prenatal_depressed_B if missing(prenatal_depressed)
label variable prenatal_k10 "Prenatal K10 (combined A+B)"
label variable prenatal_depressed "Prenatal depressed (combined A+B)"

/* Standardize prenatal K10 */
egen prenatal_k10_std = std(prenatal_k10)
label variable prenatal_k10_std "Prenatal K10 (standardized)"

/* Create indicator for prenatal exposure available */
gen has_prenatal = !missing(prenatal_k10)
gen has_prenatal_A = !missing(prenatal_k10_A)
gen has_prenatal_B = !missing(prenatal_k10_B)
label variable has_prenatal "Has prenatal depression measure"

di _n "=============================================="
di "PRENATAL DEPRESSION MEASURES CONSTRUCTED"
di "=============================================="
di _n "Strategy A (pregnant at interview):"
count if has_prenatal_A == 1
di "Strategy B (birth timing):"
count if has_prenatal_B == 1
di "Combined (A or B):"
count if has_prenatal == 1
di "With cognitive outcomes:"
count if has_prenatal == 1 & analysis_sample == 1

save "$temp/analysis_prenatal.dta", replace


/*==============================================================================
    PART 3: SUMMARY STATISTICS
==============================================================================*/

di _n(3) "=============================================="
di "PART 3: Summary statistics"
di "=============================================="

/* Mothers pregnant at each wave */
di _n "--- Mothers currently pregnant by wave ---"
tab wave pregnant_now if !missing(m_k10_score), row

di _n "--- Mothers pregnant in last year by wave ---"
tab wave pregnant_last_year if !missing(m_k10_score), row

/* Prenatal depression prevalence */
di _n "--- Prenatal K10 scores ---"
sum prenatal_k10 if has_prenatal == 1, detail

di _n "--- Prenatal depression rate (K10 >= 30) ---"
tab prenatal_depressed if has_prenatal == 1

/* Compare prenatal-exposed vs unexposed children */
di _n "--- Comparison: children with prenatal exposure ---"
di _n "Cognitive index:"
ttest cog_index if analysis_sample == 1, by(has_prenatal)

di _n "Child age:"
ttest c_age if analysis_sample == 1, by(has_prenatal)

di _n "Household size:"
ttest hh_size if analysis_sample == 1, by(has_prenatal)

/* Among those with prenatal measures: depressed vs not */
di _n "--- Among prenatally measured: depressed vs not ---"
di _n "Cognitive index:"
cap ttest cog_index if has_prenatal == 1 & analysis_sample == 1, by(prenatal_depressed)

di _n "Ravens:"
cap ttest ravens_std if has_prenatal == 1 & analysis_sample == 1, by(prenatal_depressed)

/* Tabulate sample sizes */
di _n "--- Sample sizes for estimation ---"
di "Prenatal + cognitive outcome + analysis sample:"
count if has_prenatal == 1 & analysis_sample == 1 & !missing(cog_index)

di "Strategy A only:"
count if has_prenatal_A == 1 & analysis_sample == 1 & !missing(cog_index)

di "Strategy B only:"
count if has_prenatal_B == 1 & analysis_sample == 1 & !missing(cog_index)


/*==============================================================================
    PART 4: ESTIMATION
==============================================================================*/

di _n(3) "=============================================="
di "PART 4: Estimation — Prenatal Depression"
di "=============================================="

/* Control variable sets (same as main estimation) */
global child_controls "c_age i.c_female"
global maternal_controls "m_age_harmonized"
global hh_controls "hh_size ln_pc_consumption"
global full_controls "$child_controls $maternal_controls $hh_controls"


/*==============================================================================
    TABLE P1: EFFECT OF PRENATAL DEPRESSION ON CHILD COGNITION
==============================================================================*/

di _n "--- Table P1: Prenatal depression and child cognition ---"

eststo clear

/* Column 1: OLS — Prenatal K10 (standardized) on cognitive index */
cap noi eststo p1: reg cog_index prenatal_k10_std ///
    if has_prenatal == 1 & analysis_sample == 1, ///
    cluster(ea_id)
if _rc == 0 {
    estadd local controls "No"
    estadd local ea_fe "No"
    estadd local wave_fe "No"
}

/* Column 2: OLS + Full controls */
cap noi eststo p2: reg cog_index prenatal_k10_std $full_controls ///
    if has_prenatal == 1 & analysis_sample == 1, ///
    cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local ea_fe "No"
    estadd local wave_fe "No"
}

/* Column 3: EA + Wave FE */
cap noi eststo p3: reghdfe cog_index prenatal_k10_std ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if has_prenatal == 1 & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local ea_fe "Yes"
    estadd local wave_fe "Yes"
}

/* Column 4: Binary prenatal depression */
cap noi eststo p4: reghdfe cog_index prenatal_depressed ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if has_prenatal == 1 & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local ea_fe "Yes"
    estadd local wave_fe "Yes"
}

/* Column 5: Prenatal vs concurrent depression in same model */
cap noi eststo p5: reghdfe cog_index prenatal_k10_std m_k10_std ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if has_prenatal == 1 & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local controls "Yes"
    estadd local ea_fe "Yes"
    estadd local wave_fe "Yes"
}

/* Build model list (only include successful estimations) */
local p1_models ""
foreach m in p1 p2 p3 p4 p5 {
    cap estimates describe `m'
    if _rc == 0 local p1_models "`p1_models' `m'"
}

/* LaTeX output */
if "`p1_models'" != "" {
    cap noi esttab `p1_models' using "$results/TableP1_PrenatalDepression.tex", replace ///
        b(3) se(3) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        title("Effect of Prenatal Depression on Child Cognitive Development") ///
        mtitles("OLS" "OLS" "EA FE" "EA FE" "EA FE") ///
        keep(prenatal_k10_std prenatal_depressed m_k10_std) ///
        order(prenatal_k10_std prenatal_depressed m_k10_std) ///
        coeflabels( ///
            prenatal_k10_std "Prenatal depression (std. K10)" ///
            prenatal_depressed "Prenatally depressed (K10 $\geq$ 30)" ///
            m_k10_std "Concurrent depression (std. K10)" ///
        ) ///
        stats(controls ea_fe wave_fe N r2, ///
            labels("Controls" "EA FE" "Wave FE" "Observations" "\$R^2$") ///
            fmt(%s %s %s %9.0fc %9.3f)) ///
        nonotes ///
        addnotes("Standard errors clustered at the EA level in parentheses." ///
                 "Prenatal depression identified via (A) pregnancy at interview and" ///
                 "(B) birth timing (child born 0--9 months after previous wave interview)." ///
                 "Controls: child age, child gender, mother's age," ///
                 "household size, and log per capita consumption." ///
                 "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
        booktabs

    /* Text output */
    cap noi esttab `p1_models' using "$results/TableP1_PrenatalDepression.txt", replace ///
        b(3) se(3) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        title("Effect of Prenatal Depression on Child Cognitive Development") ///
        mtitles("OLS" "OLS" "EA FE" "EA FE (Binary)" "EA FE (Both)") ///
        keep(prenatal_k10_std prenatal_depressed m_k10_std) ///
        order(prenatal_k10_std prenatal_depressed m_k10_std) ///
        stats(controls ea_fe wave_fe N r2, ///
            labels("Controls" "EA FE" "Wave FE" "Observations" "R-squared") ///
            fmt(%s %s %s %9.0fc %9.3f))

    di _n "Table P1 saved."
}
else {
    di as error "WARNING: No models estimated for Table P1 — sample may be too small."
}


/*==============================================================================
    TABLE P2: SENSITIVITY ANALYSES
==============================================================================*/

di _n "--- Table P2: Sensitivity analyses ---"

eststo clear

/* Standardize the alternative-window prenatal K10 scores */
cap egen prenatal_k10_B6_std = std(prenatal_k10_B6)
cap egen prenatal_k10_B12_std = std(prenatal_k10_B12)

/* Column 1: Baseline (0-9 month window) — for reference */
cap noi eststo s1: reghdfe cog_index prenatal_k10_std ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if has_prenatal == 1 & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local window "0--9 months"
    estadd local outcome "Cog Index"
}

/* Column 2: Tighter window (0-6 months) */
cap noi eststo s2: reghdfe cog_index prenatal_k10_B6_std ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if !missing(prenatal_k10_B6) & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local window "0--6 months"
    estadd local outcome "Cog Index"
}

/* Column 3: Wider window (0-12 months) */
cap noi eststo s3: reghdfe cog_index prenatal_k10_B12_std ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if !missing(prenatal_k10_B12) & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local window "0--12 months"
    estadd local outcome "Cog Index"
}

/* Column 4: Raven's score only as outcome */
cap noi eststo s4: reghdfe ravens_std prenatal_k10_std ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if has_prenatal == 1 & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local window "0--9 months"
    estadd local outcome "Raven's"
}

/* Column 5: Adding current depression as control */
cap noi eststo s5: reghdfe cog_index prenatal_k10_std m_k10_std ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if has_prenatal == 1 & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local window "0--9 months"
    estadd local outcome "Cog Index"
}

/* Column 6: Strategy A only (pregnant at interview) */
cap noi eststo s6: reghdfe cog_index prenatal_k10_std ///
    $child_controls $maternal_controls hh_size ln_pc_consumption ///
    if has_prenatal_A == 1 & analysis_sample == 1, ///
    absorb(ea_id wave) cluster(ea_id)
if _rc == 0 {
    estadd local window "Strategy A only"
    estadd local outcome "Cog Index"
}

/* Build model list */
local p2_models ""
foreach m in s1 s2 s3 s4 s5 s6 {
    cap estimates describe `m'
    if _rc == 0 local p2_models "`p2_models' `m'"
}

/* LaTeX output */
if "`p2_models'" != "" {
    cap noi esttab `p2_models' using "$results/TableP2_PrenatalSensitivity.tex", replace ///
        b(3) se(3) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        title("Prenatal Depression: Sensitivity Analyses") ///
        mtitles("Baseline" "6-month" "12-month" "Raven's" "+Current" "Strat A") ///
        keep(prenatal_k10_std prenatal_k10_B6_std prenatal_k10_B12_std m_k10_std) ///
        order(prenatal_k10_std prenatal_k10_B6_std prenatal_k10_B12_std m_k10_std) ///
        coeflabels( ///
            prenatal_k10_std "Prenatal depression (std. K10)" ///
            prenatal_k10_B6_std "Prenatal depression (6-mo window)" ///
            prenatal_k10_B12_std "Prenatal depression (12-mo window)" ///
            m_k10_std "Concurrent depression (std. K10)" ///
        ) ///
        stats(window outcome N r2, ///
            labels("Timing window" "Outcome" "Observations" "\$R^2$") ///
            fmt(%s %s %9.0fc %9.3f)) ///
        nonotes ///
        addnotes("Standard errors clustered at the EA level in parentheses." ///
                 "All models include EA and wave fixed effects plus full controls." ///
                 "*** p$<$0.01, ** p$<$0.05, * p$<$0.1") ///
        booktabs

    /* Text output */
    cap noi esttab `p2_models' using "$results/TableP2_PrenatalSensitivity.txt", replace ///
        b(3) se(3) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        title("Prenatal Depression: Sensitivity Analyses") ///
        mtitles("Baseline" "6-month" "12-month" "Raven's" "+Current" "Strat A") ///
        keep(prenatal_k10_std prenatal_k10_B6_std prenatal_k10_B12_std m_k10_std) ///
        stats(window outcome N r2, ///
            labels("Timing window" "Outcome" "Observations" "R-squared") ///
            fmt(%s %s %9.0fc %9.3f))

    di _n "Table P2 saved."
}
else {
    di as error "WARNING: No models estimated for Table P2 — sample may be too small."
}


/*==============================================================================
    PART 5: CLEAN UP AND REPORT
==============================================================================*/

di _n(3) "=============================================="
di "PRENATAL DEPRESSION ANALYSIS COMPLETE"
di "=============================================="
di _n "Output saved to: $results/"
di "  TableP1_PrenatalDepression.tex/.txt"
di "  TableP2_PrenatalSensitivity.tex/.txt"

di _n "--- Final sample summary ---"
di "Total observations in analysis data: " _N
di "Analysis sample: "
count if analysis_sample == 1
di "With prenatal measure (combined): "
count if has_prenatal == 1
di "With prenatal measure + cognitive outcome: "
count if has_prenatal == 1 & analysis_sample == 1
di "  Strategy A (pregnant at interview): "
count if has_prenatal_A == 1 & analysis_sample == 1
di "  Strategy B (birth timing): "
count if has_prenatal_B == 1 & analysis_sample == 1

di _n "Prenatal depression prevalence (among measured):"
tab prenatal_depressed if has_prenatal == 1 & analysis_sample == 1

/* Clean up temp files */
cap erase "$temp/w1_pregnancy.dta"
cap erase "$temp/w2_pregnancy.dta"
cap erase "$temp/w3_pregnancy.dta"
cap erase "$temp/pregnancy_panel.dta"
cap erase "$temp/w1_interview_date.dta"
cap erase "$temp/w2_interview_date.dta"
cap erase "$temp/w1_child_birthdates.dta"
cap erase "$temp/w2_child_birthdates.dta"
cap erase "$temp/w3_child_birthdates.dta"
cap erase "$temp/mother_k10_w1.dta"
cap erase "$temp/mother_k10_w2.dta"
cap erase "$temp/analysis_prenatal_step1.dta"

log close

/*==============================================================================
    END OF PRENATAL DEPRESSION ANALYSIS
==============================================================================*/
