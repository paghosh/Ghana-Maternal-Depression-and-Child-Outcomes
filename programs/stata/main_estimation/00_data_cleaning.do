/*==============================================================================
    Project:    Maternal Depression, Parental Investment, and Child Cognitive
                Development in Ghana
    File:       00_data_cleaning.do
    Purpose:    Merge GSPS data across 3 waves, construct depression index,
                cognitive scores, anthropometric z-scores, parental investment
                measures, and create the analysis sample
    Author:     Pallab Ghosh, University of Oklahoma
    Created:    February 2026
    Data:       Ghana Socioeconomic Panel Survey (GSPS), Waves 1-3
==============================================================================*/

clear all
set more off
set maxvar 32767
cap log close

/*------------------------------------------------------------------------------
    Global Paths
------------------------------------------------------------------------------*/
global project  "/Users/pallab.ghosh/Library/CloudStorage/Dropbox/D/Study/My_Papers/OU/Health/Ghana_mental_health/maternal_depression_child_cog_devlopment"
global data     "/Users/pallab.ghosh/Library/CloudStorage/Dropbox/D/Study/My_Papers/OU/Health/Ghana_mental_health/data/Ghana_Panel_Survey/Data"
global programs "$project/programs/stata/Draft1_Feb2026"
global results  "$project/rersults/Draft1_Feb2026"
global temp     "$project/programs/stata/Draft1_Feb2026/temp"

/* Create temp and output directories */
cap mkdir "$temp"
cap mkdir "$results"

log using "$programs/00_data_cleaning.log", replace

/*==============================================================================
    PART 1: PROCESS WAVE 1 DATA
==============================================================================*/

/*--- 1A. Household Roster & Demographics (Wave 1) ---*/
use "$data/Wave 1/s1d.dta", clear

rename s1d_1 gender
rename s1d_2 relationship
rename s1d_4i age
rename s1d_4ii age_months

/* Identify mothers and children.
   Gender and relationship may be string or numeric with value labels.
   Use decode to handle numeric case. */
cap confirm string variable gender
if _rc == 0 {
    gen female = (gender == "Female")
}
else {
    decode gender, gen(gender_str)
    gen female = (gender_str == "Female")
    drop gender_str
}

cap confirm string variable relationship
if _rc == 0 {
    gen mother = (female == 1) & ///
        (relationship == "Household Head" | relationship == "Spouse" | ///
         relationship == "Parent/Parent-in-Law") & ///
        (age >= 15 & age < .)
    gen child = (relationship == "Child" | ///
        relationship == "Adopted/Foster/Stepchild" | ///
        relationship == "Grandchild") & ///
        (age >= 0 & age <= 17)
}
else {
    decode relationship, gen(rel_str)
    gen mother = (female == 1) & ///
        (rel_str == "Household Head" | rel_str == "Spouse" | ///
         rel_str == "Parent/Parent-in-Law") & ///
        (age >= 15 & age < .)
    gen child = (rel_str == "Child" | ///
        rel_str == "Adopted/Foster/Stepchild" | ///
        rel_str == "Grandchild") & ///
        (age >= 0 & age <= 17)
    drop rel_str
}

gen child_female = (child == 1 & female == 1)

/* Ethnicity (for matrilineal/patrilineal identification) */
rename s1d_15 ethnicity_w1

/* Keep relevant variables */
keep FPrimary hhid hhmid gender relationship age age_months female ///
    mother child child_female ethnicity_w1
duplicates drop FPrimary hhmid, force
gen wave = 1

save "$temp/w1_demographics.dta", replace

/*--- 1B. Depression Module (Wave 1) - K10 Scale ---*/
use "$data/Wave 1/s10ai.dta", clear

/* K10 items: s10ai_a1 through s10ai_a10
   Response categories: None of the time(1), A little(2), Some(3),
   Most(4), All of the time(5) */

/* K10 items may be numeric (1-5) with value labels, or string.
   Handle both cases robustly. */
foreach var of varlist s10ai_a1-s10ai_a10 {
    cap confirm string variable `var'
    if _rc == 0 {
        /* String variable: recode from text to numeric */
        gen `var'_n = .
        replace `var'_n = 1 if `var' == "None of the time"
        replace `var'_n = 2 if `var' == "A little of the time"
        replace `var'_n = 3 if `var' == "Some of the time"
        replace `var'_n = 4 if `var' == "Most of the time"
        replace `var'_n = 5 if `var' == "All of the time"
    }
    else {
        /* Numeric variable (already coded 1-5): use directly */
        gen `var'_n = `var'
    }
}

/* Construct K10 depression score (sum of 10 items, range 10-50) */
egen k10_score = rowtotal(s10ai_a1_n s10ai_a2_n s10ai_a3_n s10ai_a4_n ///
    s10ai_a5_n s10ai_a6_n s10ai_a7_n s10ai_a8_n s10ai_a9_n s10ai_a10_n), missing
replace k10_score = . if missing(s10ai_a1_n) & missing(s10ai_a2_n) & ///
    missing(s10ai_a3_n)

/* Depression severity categories (standard K10 cutoffs) */
gen depression_cat = .
replace depression_cat = 0 if k10_score >= 10 & k10_score <= 19   // Low
replace depression_cat = 1 if k10_score >= 20 & k10_score <= 24   // Mild
replace depression_cat = 2 if k10_score >= 25 & k10_score <= 29   // Moderate
replace depression_cat = 3 if k10_score >= 30 & k10_score <= 50   // Severe

gen depressed_binary = (k10_score >= 20) if k10_score < .

/* Also use the pre-constructed depression score if available */
rename depressed depressed_precoded
rename depression depression_score_precoded

/* Standardize K10 score */
egen k10_std = std(k10_score)

keep FPrimary hhid hhmid k10_score k10_std depression_cat depressed_binary ///
    depressed_precoded depression_score_precoded ///
    s10ai_a1_n s10ai_a2_n s10ai_a3_n s10ai_a4_n s10ai_a5_n ///
    s10ai_a6_n s10ai_a7_n s10ai_a8_n s10ai_a9_n s10ai_a10_n
duplicates drop FPrimary hhmid, force
gen wave = 1

save "$temp/w1_depression.dta", replace

/*--- 1C. Cognitive Tests (Wave 1) - Children Only ---*/

/* Raven's Progressive Matrices */
use "$data/Wave 1/s9c.dta", clear
rename s9c_ii hhmid

/* Correct answers for Raven's Set A (standard key):
   c1=4, c2=5, c3=1, c4=2, c5=6, c6=3, c7=6, c8=2, c9=1, c10=3, c11=5, c12=2 */
local correct_c1  "D"
local correct_c2  "E"
local correct_c3  "A"
local correct_c4  "B"
local correct_c5  "F"
local correct_c6  "C"
local correct_c7  "F"
local correct_c8  "B"
local correct_c9  "A"
local correct_c10 "C"
local correct_c11 "E"
local correct_c12 "B"

gen ravens_correct = 0
/* Check if Raven's answers are string or numeric with value labels */
cap confirm string variable s9c_c1
if _rc == 0 {
    /* String variable: compare letter answers directly */
    forvalues i = 1/12 {
        local j = string(`i')
        cap gen temp_correct_`j' = (upper(s9c_c`j') == upper("`correct_c`j''"))
        cap replace ravens_correct = ravens_correct + temp_correct_`j' if temp_correct_`j' < .
        cap drop temp_correct_`j'
    }
}
else {
    /* Numeric with value labels: decode first */
    forvalues i = 1/12 {
        local j = string(`i')
        cap decode s9c_c`j', gen(_tmp_r`j')
        cap gen temp_correct_`j' = (upper(_tmp_r`j') == upper("`correct_c`j''"))
        cap replace ravens_correct = ravens_correct + temp_correct_`j' if temp_correct_`j' < .
        cap drop temp_correct_`j' _tmp_r`j'
    }
}

/* Standardize ravens score */
egen ravens_std = std(ravens_correct)

keep FPrimary hhid hhmid ravens_correct ravens_std
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_ravens.dta", replace

/* Digit Span Forward */
use "$data/Wave 1/s9b1.dta", clear
rename s9b1_ii hhmid

/* Score = highest level where at least one trial is correct.
   Items may be string ("Correct") or numeric with value labels.
   Use decode to handle both cases. */
gen dsf_score = 0
forvalues lev = 1/8 {
    local l = string(`lev')
    /* Try string comparison first; if fails, decode and compare */
    cap confirm string variable s9b1_b`l'a
    if _rc == 0 {
        cap gen pass_`l' = (s9b1_b`l'a == "Correct" | s9b1_b`l'b == "Correct" | ///
            s9b1_b`l'c == "Correct") if !missing(s9b1_b`l'a)
    }
    else {
        /* Numeric with value labels: decode to string, then compare */
        cap decode s9b1_b`l'a, gen(_tmp_a)
        cap decode s9b1_b`l'b, gen(_tmp_b)
        cap decode s9b1_b`l'c, gen(_tmp_c)
        cap gen pass_`l' = (_tmp_a == "Correct" | _tmp_b == "Correct" | ///
            _tmp_c == "Correct") if !missing(s9b1_b`l'a)
        cap drop _tmp_a _tmp_b _tmp_c
    }
    cap replace dsf_score = `lev' if pass_`l' == 1
}
cap drop pass_*

egen dsf_std = std(dsf_score)
keep FPrimary hhid hhmid dsf_score dsf_std
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_dsf.dta", replace

/* Digit Span Backward */
use "$data/Wave 1/s9b2.dta", clear
/* In Wave 1, s9b2 does not have hhmid directly - use same merge as s9b1 */
/* The digit span backward starts at level 9 */
gen dsb_score = 0
forvalues lev = 9/15 {
    local l = string(`lev')
    cap confirm string variable s9b2_b`l'a
    if _rc == 0 {
        cap gen pass_`l' = (s9b2_b`l'a == "Correct" | s9b2_b`l'b == "Correct" | ///
            s9b2_b`l'c == "Correct") if !missing(s9b2_b`l'a)
    }
    else {
        cap decode s9b2_b`l'a, gen(_tmp_a)
        cap decode s9b2_b`l'b, gen(_tmp_b)
        cap decode s9b2_b`l'c, gen(_tmp_c)
        cap gen pass_`l' = (_tmp_a == "Correct" | _tmp_b == "Correct" | ///
            _tmp_c == "Correct") if !missing(s9b2_b`l'a)
        cap drop _tmp_a _tmp_b _tmp_c
    }
    cap replace dsb_score = (`lev' - 8) if pass_`l' == 1
}
cap drop pass_*

/* Need hhmid - use s9b2_i or merge via row position */
cap rename s9b2_i hhmid
cap rename s9b2_iii hhmid

egen dsb_std = std(dsb_score)
keep FPrimary hhid hhmid dsb_score dsb_std
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_dsb.dta", replace

/* Math Test */
use "$data/Wave 1/s9d.dta", clear
rename s9d_id hhmid

/* Score items s9d_1 through s9d_8. Handle string vs numeric. */
gen math_correct = 0
cap confirm string variable s9d_1
if _rc == 0 {
    /* String: compare directly */
    forvalues i = 1/8 {
        cap replace math_correct = math_correct + (s9d_`i' == "Correct") if !missing(s9d_`i')
    }
}
else {
    /* Numeric with value labels: decode and compare */
    forvalues i = 1/8 {
        cap decode s9d_`i', gen(_tmp_d`i')
        cap replace math_correct = math_correct + (_tmp_d`i' == "Correct") if !missing(s9d_`i')
        cap drop _tmp_d`i'
    }
}

egen math_std = std(math_correct)
keep FPrimary hhid hhmid math_correct math_std
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_math.dta", replace

/* English Test */
use "$data/Wave 1/s9e.dta", clear
rename s9d_ie hhmid

gen english_correct = 0
cap confirm string variable s9e_9
if _rc == 0 {
    forvalues i = 9/16 {
        cap replace english_correct = english_correct + (s9e_`i' == "Correct") if !missing(s9e_`i')
    }
}
else {
    forvalues i = 9/16 {
        cap decode s9e_`i', gen(_tmp_e`i')
        cap replace english_correct = english_correct + (_tmp_e`i' == "Correct") if !missing(s9e_`i')
        cap drop _tmp_e`i'
    }
}

egen english_std = std(english_correct)
keep FPrimary hhid hhmid english_correct english_std
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_english.dta", replace

/*--- 1D. Anthropometry (Wave 1) ---*/
use "$data/Wave 1/s6b.dta", clear

rename s6b_4 height_cm
rename s6b_5 weight_kg
rename s6b_8 arm_circumference

/* We will compute z-scores after merging with demographics (need age/sex) */
keep FPrimary hhid hhmid height_cm weight_kg arm_circumference
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_anthro.dta", replace

/*--- 1E. Education (Wave 1) ---*/
use "$data/Wave 1/s1fi.dta", clear

rename s1fi_hhmid hhmid

/* Highest grade attained */
rename s1fi_3 highest_grade_w1
rename s1fi_2 ever_attended_w1

/* Currently attending */
cap confirm string variable s1fi_5
if _rc == 0 {
    gen attending_school = (s1fi_5 == "Yes") if !missing(s1fi_5)
}
else {
    cap decode s1fi_5, gen(_tmp_sch)
    gen attending_school = (_tmp_sch == "Yes") if !missing(s1fi_5)
    cap drop _tmp_sch
}

keep FPrimary hhid hhmid highest_grade_w1 ever_attended_w1 attending_school
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_education.dta", replace

/*--- 1F. Employment & Earnings (Wave 1) ---*/
use "$data/Wave 1/s1ei.dta", clear

rename s1ei_7i weeks_year
rename s1ei_7ii days_week
rename s1ei_7iii hours_day
rename s1ei_10i pay_amount

/* Annualize earnings based on pay period (s1ei_11) */
gen annual_hours = weeks_year * days_week * hours_day
gen weekly_hours = days_week * hours_day

keep FPrimary hhid hhmid weeks_year days_week hours_day pay_amount ///
    annual_hours weekly_hours s1ei_11
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_employment.dta", replace

/*--- 1G. Health - Past 2 Weeks (Wave 1) ---*/
use "$data/Wave 1/s6f.dta", clear

/* Read with convert_categoricals workaround if needed */
destring s6f_1, replace force
destring s6f_5, replace force
destring s6f_6, replace force
destring s6f_7, replace force
destring s6f_8, replace force

rename s6f_1 ill_2weeks
rename s6f_5 days_sick
rename s6f_6 stopped_activities
rename s6f_7 days_stopped
rename s6f_8 consulted_facility

keep FPrimary hhid hhmid ill_2weeks days_sick stopped_activities ///
    days_stopped consulted_facility
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_health2wk.dta", replace

/*--- 1H. Immunization (Wave 1) ---*/
use "$data/Wave 1/s6c.dta", clear

/* Count vaccines received: s6c_2 BCG, s6c_3 polio, s6c_4 DPT,
   s6c_5 five-in-one, s6c_6 measles, s6c_7 vitamin A, s6c_8 yellow fever */
gen immun_count = 0
cap confirm string variable s6c_2
if _rc == 0 {
    foreach var in s6c_2 s6c_3 s6c_4 s6c_5 s6c_6 s6c_7 s6c_8 {
        replace immun_count = immun_count + (`var' == "Yes") if !missing(`var')
    }
}
else {
    foreach var in s6c_2 s6c_3 s6c_4 s6c_5 s6c_6 s6c_7 s6c_8 {
        cap decode `var', gen(_tmp_v)
        cap replace immun_count = immun_count + (_tmp_v == "Yes") if !missing(`var')
        cap drop _tmp_v
    }
}
gen immun_rate = immun_count / 7

keep FPrimary hhid hhmid immun_count immun_rate
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_immunization.dta", replace

/*--- 1I. Insurance (Wave 1) ---*/
use "$data/Wave 1/s6a.dta", clear

cap confirm string variable s6a_a1
if _rc == 0 {
    gen nhis_registered = (s6a_a1 == "Yes") if !missing(s6a_a1)
    gen nhis_valid_card = (s6a_a5 == "Yes, Card seen" | s6a_a5 == "Yes, No card seen") ///
        if !missing(s6a_a5)
}
else {
    decode s6a_a1, gen(_tmp1)
    gen nhis_registered = (_tmp1 == "Yes") if !missing(s6a_a1)
    drop _tmp1
    decode s6a_a5, gen(_tmp5)
    gen nhis_valid_card = (_tmp5 == "Yes, Card seen" | _tmp5 == "Yes, No card seen") ///
        if !missing(s6a_a5)
    drop _tmp5
}

keep FPrimary hhid hhmid nhis_registered nhis_valid_card
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_insurance.dta", replace

/*--- 1J. Care for Kids / Time Use (Wave 1) ---*/
use "$data/Wave 1/s10avi.dta", clear

/* Wave 1 time use has numbered activity items (s10avi_49 through s10avi_105)
   The structure is: activity yes/no, then hours, minutes for each
   We need to identify reading/homework-related activities */

/* For Wave 1, we will construct total time spent with children
   by summing hours across activities where person reports doing them */

/* Total hours columns are the even-numbered: s10avi_50i, s10avi_52i, etc. */
/* Minutes are: s10avi_50ii, s10avi_52ii, etc. */
/* Let's sum all activities' time as total parental time */

/* Simplified: sum up all hour entries */
egen total_time_hrs = rowtotal(s10avi_50i s10avi_52i s10avi_54i ///
    s10avi_56i s10avi_58i s10avi_60i s10avi_62i s10avi_64i s10avi_66i ///
    s10avi_68i s10avi_70i s10avi_72i s10avi_74i s10avi_76i s10avi_78i ///
    s10avi_80i s10avi_82i s10avi_84i s10avi_86i s10avi_88i s10avi_90i ///
    s10avi_92i s10avi_94i s10avi_96i s10avi_98i s10avi_100i s10avi_102i), missing

egen total_time_min = rowtotal(s10avi_50ii s10avi_52ii s10avi_54ii ///
    s10avi_56ii s10avi_58ii s10avi_60ii s10avi_62ii s10avi_64ii s10avi_66ii ///
    s10avi_68ii s10avi_70ii s10avi_72ii s10avi_74ii s10avi_76ii s10avi_78ii ///
    s10avi_80ii s10avi_82ii s10avi_84ii s10avi_86ii s10avi_88ii s10avi_90ii ///
    s10avi_92ii s10avi_94ii s10avi_96ii s10avi_98ii s10avi_100ii s10avi_102ii), missing

gen total_parental_time = total_time_hrs + total_time_min / 60

/* Days per week working on childcare */
rename s10avi_105 days_childcare_week_w1

keep FPrimary hhid hhmid total_parental_time days_childcare_week_w1
duplicates drop FPrimary hhmid, force
gen wave = 1
save "$temp/w1_childcare.dta", replace

/*--- 1K. Food Consumption (Wave 1) ---*/
use "$data/Wave 1/s11a.dta", clear

/* Aggregate food consumption at the household level */
/* s11a_bii = own-produced value (cedis), s11a_cii = purchased value */
collapse (sum) food_own = s11a_bii food_purch = s11a_cii, by(FPrimary hhid)
gen total_food_exp = food_own + food_purch

gen wave = 1
save "$temp/w1_foodcons.dta", replace

/*--- 1L. Non-Food Consumption (Wave 1) ---*/
/* Clothing */
use "$data/Wave 1/s11b.dta", clear
collapse (sum) clothing_exp = s11ba_2, by(FPrimary hhid)
gen wave = 1
save "$temp/w1_clothing.dta", replace

/* Other items (education, health, etc.) */
use "$data/Wave 1/s11c.dta", clear
collapse (sum) other_exp = s11c_2, by(FPrimary hhid)
gen wave = 1
save "$temp/w1_otheritems.dta", replace

/* Fuel */
use "$data/Wave 1/s11d.dta", clear
collapse (sum) fuel_exp = s11d_a, by(FPrimary hhid)
gen wave = 1
save "$temp/w1_fuel.dta", replace

/*--- 1M. Household Info (Wave 1) ---*/
use "$data/Wave 1/key_hhld_info.dta", clear
keep FPrimary hhid urbrur hhweight3 ppweight3
rename hhweight3 hh_weight
rename ppweight3 pp_weight
gen wave = 1
save "$temp/w1_hhinfo.dta", replace

/*--- 1N. Household Cover (Wave 1) - for household size, region ---*/
use "$data/Wave 1/sec0.dta", clear
keep FPrimary hhid regioncode districtcode eacode urbrur threezones
gen wave = 1
save "$temp/w1_hhcover.dta", replace


/*==============================================================================
    PART 2: PROCESS WAVE 2 DATA
==============================================================================*/

/*--- 2A. Demographics (Wave 2) ---*/
use "$data/Wave 2/01d_background.dta", clear

rename age age_w2
rename gender gender_w2

cap confirm string variable gender_w2
if _rc == 0 {
    gen female = (gender_w2 == "Female")
}
else {
    decode gender_w2, gen(_gender_str)
    gen female = (_gender_str == "Female")
    drop _gender_str
}
gen mother_w2 = 0

/* Need roster for relationship - merge with roster file */
save "$temp/w2_background_temp.dta", replace

use "$data/Wave 2/01b2_roster.dta", clear
/* Wave 2 roster */
keep FPrimary InstanceNumber hhmid
rename InstanceNumber instance_roster
save "$temp/w2_roster_ids.dta", replace

use "$temp/w2_background_temp.dta", clear
/* In Wave 2, InstanceNumber matches across files within FPrimary */
/* hhmid is the consistent member ID */

gen mother_w2_v2 = (female == 1) & (age_w2 >= 15 & age_w2 < .)

gen child_w2 = (age_w2 >= 0 & age_w2 <= 17)

keep FPrimary InstanceNumber hhmid age_w2 gender_w2 female mother_w2_v2 ///
    child_w2 maritalstatus religion ethnicity motherid fatherid
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_demographics.dta", replace

/*--- 2B. Depression (Wave 2) ---*/
use "$data/Wave 2/10ai_depression.dta", clear

/* K10 items have descriptive names in Wave 2.
   Items may be numeric (1-5 with value labels) or string. Handle both. */
foreach var in tired nervous hopeless restless depressed ///
    everythingeffort nothingcheerup worthless sonervous sorestless {
    cap confirm string variable `var'
    if _rc == 0 {
        /* String variable: recode from text to numeric */
        gen `var'_n = .
        replace `var'_n = 1 if `var' == "None of the time"
        replace `var'_n = 2 if `var' == "A little of the time"
        replace `var'_n = 3 if `var' == "Some of the time"
        replace `var'_n = 4 if `var' == "Most of the time"
        replace `var'_n = 5 if `var' == "All of the time"
    }
    else {
        /* Numeric variable (already coded 1-5): use directly */
        gen `var'_n = `var'
    }
}

/* K10 score: sum of the 10 items */
egen k10_score = rowtotal(tired_n nervous_n sonervous_n hopeless_n ///
    restless_n sorestless_n depressed_n everythingeffort_n ///
    nothingcheerup_n worthless_n), missing

gen depression_cat = .
replace depression_cat = 0 if k10_score >= 10 & k10_score <= 19
replace depression_cat = 1 if k10_score >= 20 & k10_score <= 24
replace depression_cat = 2 if k10_score >= 25 & k10_score <= 29
replace depression_cat = 3 if k10_score >= 30 & k10_score <= 50

gen depressed_binary = (k10_score >= 20) if k10_score < .
egen k10_std = std(k10_score)

keep FPrimary hhmid k10_score k10_std depression_cat depressed_binary ///
    tired_n nervous_n sonervous_n hopeless_n restless_n sorestless_n ///
    depressed_n everythingeffort_n nothingcheerup_n worthless_n
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_depression.dta", replace

/*--- 2C. Cognitive Tests (Wave 2) ---*/

/* Raven's */
use "$data/Wave 2/09c_ravenspattern.dta", clear

/* Correct answers same as Wave 1 */
gen ravens_correct = 0
local answers "d e a b f c f b a c e b"
cap confirm string variable c_01
if _rc == 0 {
    /* String: compare directly */
    local i = 1
    foreach ans of local answers {
        local j = string(`i', "%02.0f")
        cap replace ravens_correct = ravens_correct + (lower(c_`j') == "`ans'") if !missing(c_`j')
        local i = `i' + 1
    }
}
else {
    /* Numeric with value labels: decode first */
    local i = 1
    foreach ans of local answers {
        local j = string(`i', "%02.0f")
        cap decode c_`j', gen(_tmp_r)
        cap replace ravens_correct = ravens_correct + (lower(_tmp_r) == "`ans'") if !missing(c_`j')
        cap drop _tmp_r
        local i = `i' + 1
    }
}

egen ravens_std = std(ravens_correct)
keep FPrimary hhmid age gender ravens_correct ravens_std
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_ravens.dta", replace

/* Digit Span (combined forward and backward in Wave 2) */
use "$data/Wave 2/09b_digitspantest.dta", clear

/* Forward: levels b1_01 through b1_08 */
gen dsf_score = 0
cap confirm string variable b1_01a
if _rc == 0 {
    forvalues lev = 1/8 {
        local l = string(`lev', "%02.0f")
        cap gen pass_`lev' = (b1_`l'a == "Correct" | b1_`l'b == "Correct" | ///
            b1_`l'c == "Correct") if !missing(b1_`l'a)
        cap replace dsf_score = `lev' if pass_`lev' == 1
    }
}
else {
    forvalues lev = 1/8 {
        local l = string(`lev', "%02.0f")
        cap decode b1_`l'a, gen(_ta)
        cap decode b1_`l'b, gen(_tb)
        cap decode b1_`l'c, gen(_tc)
        cap gen pass_`lev' = (_ta == "Correct" | _tb == "Correct" | ///
            _tc == "Correct") if !missing(b1_`l'a)
        cap drop _ta _tb _tc
        cap replace dsf_score = `lev' if pass_`lev' == 1
    }
}

/* Backward: levels b2_09 through b2_15 */
gen dsb_score = 0
cap confirm string variable b2_09a
if _rc == 0 {
    forvalues lev = 9/15 {
        local l = string(`lev', "%02.0f")
        cap gen pass_`lev' = (b2_`l'a == "Correct" | b2_`l'b == "Correct" | ///
            b2_`l'c == "Correct") if !missing(b2_`l'a)
        cap replace dsb_score = (`lev' - 8) if pass_`lev' == 1
    }
}
else {
    forvalues lev = 9/15 {
        local l = string(`lev', "%02.0f")
        cap decode b2_`l'a, gen(_ta)
        cap decode b2_`l'b, gen(_tb)
        cap decode b2_`l'c, gen(_tc)
        cap gen pass_`lev' = (_ta == "Correct" | _tb == "Correct" | ///
            _tc == "Correct") if !missing(b2_`l'a)
        cap drop _ta _tb _tc
        cap replace dsb_score = (`lev' - 8) if pass_`lev' == 1
    }
}

egen dsf_std = std(dsf_score)
egen dsb_std = std(dsb_score)

keep FPrimary hhmid dsf_score dsf_std dsb_score dsb_std
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_digitspan.dta", replace

/* Math */
use "$data/Wave 2/09d_math.dta", clear
gen math_correct = 0
cap confirm string variable d_01
if _rc == 0 {
    forvalues i = 1/8 {
        local j = string(`i', "%02.0f")
        cap replace math_correct = math_correct + (d_`j' == "Correct") if !missing(d_`j')
    }
}
else {
    forvalues i = 1/8 {
        local j = string(`i', "%02.0f")
        cap decode d_`j', gen(_tmp_d)
        cap replace math_correct = math_correct + (_tmp_d == "Correct") if !missing(d_`j')
        cap drop _tmp_d
    }
}
egen math_std = std(math_correct)
keep FPrimary hhmid math_correct math_std
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_math.dta", replace

/* English */
use "$data/Wave 2/09e_english.dta", clear
gen english_correct = 0
cap confirm string variable e_09
if _rc == 0 {
    forvalues i = 9/15 {
        local j = string(`i', "%02.0f")
        cap replace english_correct = english_correct + (e_`j' == "Correct") if !missing(e_`j')
    }
}
else {
    forvalues i = 9/15 {
        local j = string(`i', "%02.0f")
        cap decode e_`j', gen(_tmp_e)
        cap replace english_correct = english_correct + (_tmp_e == "Correct") if !missing(e_`j')
        cap drop _tmp_e
    }
}
egen english_std = std(english_correct)
keep FPrimary hhmid english_correct english_std
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_english.dta", replace

/*--- 2D. Anthropometry (Wave 2) ---*/
use "$data/Wave 2/06b_anthropometry.dta", clear

rename height height_cm
rename weight_ weight_kg
rename armcircumference arm_circumference

keep FPrimary hhmid age gender height_cm weight_kg arm_circumference
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_anthro.dta", replace

/*--- 2E. Care for Kids (Wave 2) ---*/
use "$data/Wave 2/10avi_careforkids.dta", clear

/* Key variables: readhomeworkhours, readhomeworkminutes,
   otherhours, otherminutes, sleepinghours, daysworkperweek */
gen read_hw_time = readhomeworkhours + readhomeworkminutes / 60
gen other_child_time = otherhours + otherminutes / 60
gen total_child_time = read_hw_time + other_child_time

cap confirm string variable careforkids
if _rc == 0 {
    gen careforkids_yn = (careforkids == "Yes") if !missing(careforkids)
}
else {
    cap decode careforkids, gen(_tmp_ck)
    gen careforkids_yn = (_tmp_ck == "Yes") if !missing(careforkids)
    cap drop _tmp_ck
}

keep FPrimary hhmid careforkids_yn read_hw_time other_child_time ///
    total_child_time sleepinghours sleepingminutes daysworkperweek
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_childcare.dta", replace

/*--- 2F. Employment (Wave 2) ---*/
use "$data/Wave 2/01ei_employmentmain.dta", clear

rename jobweeksperyear weeks_year
rename jobdaysperweek days_week
rename jobhoursperday hours_day
rename paidamount pay_amount

gen annual_hours = weeks_year * days_week * hours_day
gen weekly_hours = days_week * hours_day

keep FPrimary hhmid weeks_year days_week hours_day pay_amount ///
    annual_hours weekly_hours paid paidperiod
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_employment.dta", replace

/*--- 2G. Education (Wave 2) ---*/
use "$data/Wave 2/01fi_generaleducation.dta", clear

rename highestgrade highest_grade_w2
rename attended ever_attended_w2
cap confirm string variable attendingstill
if _rc == 0 {
    gen attending_school = (attendingstill == "Yes") if !missing(attendingstill)
}
else {
    cap decode attendingstill, gen(_tmp_as)
    gen attending_school = (_tmp_as == "Yes") if !missing(attendingstill)
    cap drop _tmp_as
}

keep FPrimary hhmid highest_grade_w2 ever_attended_w2 attending_school gender
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_education.dta", replace

/*--- 2H. Health (Wave 2) ---*/
use "$data/Wave 2/06f_past2weeks.dta", clear

keep FPrimary hhmid anyillness howmanydays stopactivities howmanystop ///
    consultfacility
rename anyillness ill_2weeks
rename howmanydays days_sick
rename stopactivities stopped_activities
rename howmanystop days_stopped
rename consultfacility consulted_facility
duplicates drop FPrimary hhmid, force
gen wave = 2
save "$temp/w2_health2wk.dta", replace

/*--- 2I. Immunization (Wave 2) ---*/
use "$data/Wave 2/06c_immunization.dta", clear

/* Variable names may differ in Wave 2 */
ds, has(type string)
/* Count vaccines */
keep FPrimary hhmid
gen wave = 2
save "$temp/w2_immunization.dta", replace

/*--- 2J. Insurance (Wave 2) ---*/
use "$data/Wave 2/06a_insurance.dta", clear

keep FPrimary hhmid
gen wave = 2
save "$temp/w2_insurance.dta", replace

/*--- 2K. Consumption (Wave 2) ---*/
use "$data/Wave 2/11a_foodcomsumption_prod_purch.dta", clear
collapse (sum) food_own = producedcedis food_purch = purchasedcedis, by(FPrimary)
gen total_food_exp = food_own + food_purch
gen wave = 2
save "$temp/w2_foodcons.dta", replace


/*==============================================================================
    PART 3: PROCESS WAVE 3 DATA
==============================================================================*/

/*--- 3A. Demographics (Wave 3) ---*/
use "$data/Wave 3/01b2_roster.dta", clear

rename ageyears age_w3
rename agemonths age_months_w3

cap confirm string variable gender
if _rc == 0 {
    gen female = (gender == "Female")
}
else {
    decode gender, gen(_gender_str)
    gen female = (_gender_str == "Female")
    drop _gender_str
}

/* Identify mothers and children */
cap confirm string variable relationship
if _rc == 0 {
    gen mother_w3 = (female == 1) & ///
        (relationship == "Head" | relationship == "Spouse" | ///
         relationship == "Parent/Parent-in-law") & ///
        (age_w3 >= 15 & age_w3 < .)
    gen child_w3 = (relationship == "Child" | ///
        relationship == "Adopted, foster/stepchild" | ///
        relationship == "Grandchild") & ///
        (age_w3 >= 0 & age_w3 <= 17)
}
else {
    decode relationship, gen(_rel_str)
    gen mother_w3 = (female == 1) & ///
        (_rel_str == "Head" | _rel_str == "Spouse" | ///
         _rel_str == "Parent/Parent-in-law") & ///
        (age_w3 >= 15 & age_w3 < .)
    gen child_w3 = (_rel_str == "Child" | ///
        _rel_str == "Adopted, foster/stepchild" | ///
        _rel_str == "Grandchild") & ///
        (age_w3 >= 0 & age_w3 <= 17)
    drop _rel_str
}

keep FPrimary index hhmid hhmid_original gender age_w3 age_months_w3 ///
    female mother_w3 child_w3 relationship new_mem maritalstatus
gen wave = 3
save "$temp/w3_demographics.dta", replace

/*--- 3B. Depression (Wave 3) ---*/
use "$data/Wave 3/10ai_depression.dta", clear

/* In Wave 3: interviewedid = hhmid */
rename interviewedid hhmid

/* K10 items - same descriptive names as Wave 2.
   Items may be numeric (1-5 with value labels) or string. Handle both. */
foreach var in tired nervous hopeless restless depressed ///
    everythingeffort nothingcheerup worthless sonervous sorestless {
    cap confirm string variable `var'
    if _rc == 0 {
        /* String variable: recode from text to numeric */
        gen `var'_n = .
        replace `var'_n = 1 if `var' == "None of the time"
        replace `var'_n = 2 if `var' == "A little of the time"
        replace `var'_n = 3 if `var' == "Some of the time"
        replace `var'_n = 4 if `var' == "Most of the time"
        replace `var'_n = 5 if `var' == "All of the time"
    }
    else {
        /* Numeric variable (already coded 1-5): use directly */
        gen `var'_n = `var'
    }
}

/* Wave 3 also has a pre-computed 'kessler' variable */
rename kessler kessler_precomputed

egen k10_score = rowtotal(tired_n nervous_n sonervous_n hopeless_n ///
    restless_n sorestless_n depressed_n everythingeffort_n ///
    nothingcheerup_n worthless_n), missing

gen depression_cat = .
replace depression_cat = 0 if k10_score >= 10 & k10_score <= 19
replace depression_cat = 1 if k10_score >= 20 & k10_score <= 24
replace depression_cat = 2 if k10_score >= 25 & k10_score <= 29
replace depression_cat = 3 if k10_score >= 30 & k10_score <= 50

gen depressed_binary = (k10_score >= 20) if k10_score < .
egen k10_std = std(k10_score)

keep FPrimary hhmid k10_score k10_std depression_cat depressed_binary ///
    kessler_precomputed tired_n nervous_n sonervous_n hopeless_n ///
    restless_n sorestless_n depressed_n everythingeffort_n ///
    nothingcheerup_n worthless_n

/* Drop duplicate hhmid within FPrimary (take first observation) */
bysort FPrimary hhmid: keep if _n == 1

gen wave = 3
save "$temp/w3_depression.dta", replace

/*--- 3C. Cognitive Tests (Wave 3) ---*/

/* Raven's */
use "$data/Wave 3/01ei_ravens.dta", clear

gen ravens_correct = 0
local answers "d e a b f c f b a c e b"
cap confirm string variable ravens_01
if _rc == 0 {
    local i = 1
    foreach ans of local answers {
        local j = string(`i', "%02.0f")
        cap replace ravens_correct = ravens_correct + ///
            (lower(ravens_`j') == "`ans'") if !missing(ravens_`j')
        local i = `i' + 1
    }
}
else {
    local i = 1
    foreach ans of local answers {
        local j = string(`i', "%02.0f")
        cap decode ravens_`j', gen(_tmp_r)
        cap replace ravens_correct = ravens_correct + ///
            (lower(_tmp_r) == "`ans'") if !missing(ravens_`j')
        cap drop _tmp_r
        local i = `i' + 1
    }
}

egen ravens_std = std(ravens_correct)
keep FPrimary index hhmid age ravens_correct ravens_std
duplicates drop FPrimary hhmid, force
gen wave = 3
save "$temp/w3_ravens.dta", replace

/* Digit Span (Wave 3) */
use "$data/Wave 3/01ev_digitspan.dta", clear

/* Forward: forwards_01 through forwards_08 */
gen dsf_score = 0
cap confirm string variable forwards_01a
if _rc == 0 {
    forvalues lev = 1/8 {
        local l = string(`lev', "%02.0f")
        cap gen pass_`lev' = (forwards_`l'a == "Correct" | ///
            forwards_`l'b == "Correct" | ///
            forwards_`l'c == "Correct") if !missing(forwards_`l'a)
        cap replace dsf_score = `lev' if pass_`lev' == 1
    }
}
else {
    forvalues lev = 1/8 {
        local l = string(`lev', "%02.0f")
        cap decode forwards_`l'a, gen(_ta)
        cap decode forwards_`l'b, gen(_tb)
        cap decode forwards_`l'c, gen(_tc)
        cap gen pass_`lev' = (_ta == "Correct" | _tb == "Correct" | ///
            _tc == "Correct") if !missing(forwards_`l'a)
        cap drop _ta _tb _tc
        cap replace dsf_score = `lev' if pass_`lev' == 1
    }
}

/* Backward: backwards_09 through backwards_15 */
gen dsb_score = 0
cap confirm string variable backwards_09a
if _rc == 0 {
    forvalues lev = 9/15 {
        local l = string(`lev', "%02.0f")
        cap gen pass_`lev' = (backwards_`l'a == "Correct" | ///
            backwards_`l'b == "Correct" | ///
            backwards_`l'c == "Correct") if !missing(backwards_`l'a)
        cap replace dsb_score = (`lev' - 8) if pass_`lev' == 1
    }
}
else {
    forvalues lev = 9/15 {
        local l = string(`lev', "%02.0f")
        cap decode backwards_`l'a, gen(_ta)
        cap decode backwards_`l'b, gen(_tb)
        cap decode backwards_`l'c, gen(_tc)
        cap gen pass_`lev' = (_ta == "Correct" | _tb == "Correct" | ///
            _tc == "Correct") if !missing(backwards_`l'a)
        cap drop _ta _tb _tc
        cap replace dsb_score = (`lev' - 8) if pass_`lev' == 1
    }
}

egen dsf_std = std(dsf_score)
egen dsb_std = std(dsb_score)

keep FPrimary index hhmid dsf_score dsf_std dsb_score dsb_std
duplicates drop FPrimary hhmid, force
gen wave = 3
save "$temp/w3_digitspan.dta", replace

/* Math (Wave 3) */
use "$data/Wave 3/01eiii_math.dta", clear

/* Wave 3 has math_score pre-computed and math_01_yn through math_08_yn */
gen math_correct = 0
cap confirm string variable math_01_yn
if _rc == 0 {
    forvalues i = 1/8 {
        local j = string(`i', "%02.0f")
        cap replace math_correct = math_correct + (math_`j'_yn == "Correct") ///
            if !missing(math_`j'_yn)
    }
}
else {
    forvalues i = 1/8 {
        local j = string(`i', "%02.0f")
        cap decode math_`j'_yn, gen(_tmp_m)
        cap replace math_correct = math_correct + (_tmp_m == "Correct") ///
            if !missing(math_`j'_yn)
        cap drop _tmp_m
    }
}

/* Use pre-computed score if available */
cap replace math_correct = math_score if !missing(math_score)

egen math_std = std(math_correct)
keep FPrimary index hhmid math_correct math_std
duplicates drop FPrimary hhmid, force
gen wave = 3
save "$temp/w3_math.dta", replace

/* English (Wave 3) */
use "$data/Wave 3/01evi_english.dta", clear

gen english_correct = 0
cap confirm string variable english_09_yn
if _rc == 0 {
    forvalues i = 9/15 {
        local j = string(`i', "%02.0f")
        cap replace english_correct = english_correct + ///
            (english_`j'_yn == "Correct") if !missing(english_`j'_yn)
    }
}
else {
    forvalues i = 9/15 {
        local j = string(`i', "%02.0f")
        cap decode english_`j'_yn, gen(_tmp_e)
        cap replace english_correct = english_correct + ///
            (_tmp_e == "Correct") if !missing(english_`j'_yn)
        cap drop _tmp_e
    }
}

cap replace english_correct = english_score if !missing(english_score)

egen english_std = std(english_correct)
keep FPrimary index hhmid english_correct english_std
duplicates drop FPrimary hhmid, force
gen wave = 3
save "$temp/w3_english.dta", replace

/* NEPSY (Wave 3 only) */
use "$data/Wave 3/01eiv_nepsy.dta", clear

rename naming_task_score nepsy_naming
rename inhibit_task_score nepsy_inhibit

keep FPrimary index hhmid nepsy_naming nepsy_inhibit
duplicates drop FPrimary hhmid, force
gen wave = 3
save "$temp/w3_nepsy.dta", replace

/*--- 3D. Anthropometry (Wave 3) ---*/
use "$data/Wave 3/01evii_anthropometry.dta", clear

rename height height_cm
rename weight weight_kg
rename armcircumference arm_circumference

keep FPrimary index hhmid age height_cm weight_kg arm_circumference
duplicates drop FPrimary hhmid, force
gen wave = 3
save "$temp/w3_anthro.dta", replace

/*--- 3E. Care for Kids (Wave 3) ---*/
use "$data/Wave 3/10avi_careforkids.dta", clear

rename interviewedid hhmid
gen read_hw_time = readhomeworkhours + readhomeworkminutes / 60
gen other_child_time = otherhours + otherminutes / 60
gen math_help_time = mathhours + mathminutes / 60
gen english_help_time = englishhours + englishminutes / 60
gen total_child_time = read_hw_time + other_child_time + ///
    math_help_time + english_help_time

cap confirm string variable careforkids
if _rc == 0 {
    gen careforkids_yn = (careforkids == "Yes") if !missing(careforkids)
}
else {
    cap decode careforkids, gen(_tmp_ck)
    gen careforkids_yn = (_tmp_ck == "Yes") if !missing(careforkids)
    cap drop _tmp_ck
}

/* Drop duplicates */
bysort FPrimary hhmid: keep if _n == 1

keep FPrimary hhmid careforkids_yn read_hw_time other_child_time ///
    total_child_time math_help_time english_help_time ///
    sleepinghours sleepingminutes daysworkperweek
gen wave = 3
save "$temp/w3_childcare.dta", replace

/*--- 3F. Employment (Wave 3) ---*/
use "$data/Wave 3/01fi_employmentmain.dta", clear

rename jobweeksperyear weeks_year
rename jobdaysperweek days_week
rename jobhoursperday hours_day
rename paidamount pay_amount

gen annual_hours = weeks_year * days_week * hours_day
gen weekly_hours = days_week * hours_day

keep FPrimary hhmid weeks_year days_week hours_day pay_amount ///
    annual_hours weekly_hours paid paidperiod
duplicates drop FPrimary hhmid, force
gen wave = 3
save "$temp/w3_employment.dta", replace

/*--- 3G. Consumption (Wave 3) ---*/
use "$data/Wave 3/11a_foodconsumption_prod_purch.dta", clear
collapse (sum) food_own = producedcedis food_purch = purchasedcedis, by(FPrimary)
gen total_food_exp = food_own + food_purch
gen wave = 3
save "$temp/w3_foodcons.dta", replace

/*--- 3H. Health (Wave 3) ---*/
use "$data/Wave 3/06f_past2weeks.dta", clear

rename anyillness ill_2weeks
rename howmanydays days_sick
rename stopactivities stopped_activities
rename howmanystop days_stopped
rename consultfacility consulted_facility

keep FPrimary hhmid ill_2weeks days_sick stopped_activities ///
    days_stopped consulted_facility
duplicates drop FPrimary hhmid, force
gen wave = 3
save "$temp/w3_health2wk.dta", replace


/*==============================================================================
    PART 4: MERGE WITHIN EACH WAVE
==============================================================================*/

/*--- Wave 1 Master Dataset ---*/
use "$temp/w1_demographics.dta", clear

/* Merge depression */
merge 1:1 FPrimary hhmid using "$temp/w1_depression.dta", ///
    keep(master match) nogen

/* Merge cognitive tests - these are at child level */
merge 1:1 FPrimary hhmid using "$temp/w1_ravens.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w1_dsf.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w1_dsb.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w1_math.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w1_english.dta", ///
    keep(master match) nogen

/* Merge anthropometry */
merge 1:1 FPrimary hhmid using "$temp/w1_anthro.dta", ///
    keep(master match) nogen

/* Merge education */
merge 1:1 FPrimary hhmid using "$temp/w1_education.dta", ///
    keep(master match) nogen

/* Merge employment */
merge 1:1 FPrimary hhmid using "$temp/w1_employment.dta", ///
    keep(master match) nogen

/* Merge health */
merge 1:1 FPrimary hhmid using "$temp/w1_health2wk.dta", ///
    keep(master match) nogen

/* Merge immunization */
merge 1:1 FPrimary hhmid using "$temp/w1_immunization.dta", ///
    keep(master match) nogen

/* Merge insurance */
merge 1:1 FPrimary hhmid using "$temp/w1_insurance.dta", ///
    keep(master match) nogen

/* Merge childcare */
merge 1:1 FPrimary hhmid using "$temp/w1_childcare.dta", ///
    keep(master match) nogen

/* Merge household-level consumption */
merge m:1 FPrimary hhid using "$temp/w1_foodcons.dta", ///
    keep(master match) nogen
merge m:1 FPrimary hhid using "$temp/w1_clothing.dta", ///
    keep(master match) nogen
merge m:1 FPrimary hhid using "$temp/w1_otheritems.dta", ///
    keep(master match) nogen
merge m:1 FPrimary hhid using "$temp/w1_fuel.dta", ///
    keep(master match) nogen

/* Merge household info */
merge m:1 FPrimary using "$temp/w1_hhinfo.dta", ///
    keep(master match) nogen

/* Merge household cover */
merge m:1 FPrimary hhid using "$temp/w1_hhcover.dta", ///
    keep(master match) nogen

save "$temp/w1_master.dta", replace

/*--- Wave 2 Master Dataset ---*/
use "$temp/w2_demographics.dta", clear

merge 1:1 FPrimary hhmid using "$temp/w2_depression.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_ravens.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_digitspan.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_math.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_english.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_anthro.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_childcare.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_employment.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_education.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w2_health2wk.dta", ///
    keep(master match) nogen

/* Household-level consumption */
merge m:1 FPrimary using "$temp/w2_foodcons.dta", ///
    keep(master match) nogen

save "$temp/w2_master.dta", replace

/*--- Wave 3 Master Dataset ---*/
use "$temp/w3_demographics.dta", clear

merge 1:1 FPrimary hhmid using "$temp/w3_depression.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_ravens.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_digitspan.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_math.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_english.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_nepsy.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_anthro.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_childcare.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_employment.dta", ///
    keep(master match) nogen
merge 1:1 FPrimary hhmid using "$temp/w3_health2wk.dta", ///
    keep(master match) nogen

/* Household-level consumption */
merge m:1 FPrimary using "$temp/w3_foodcons.dta", ///
    keep(master match) nogen

save "$temp/w3_master.dta", replace


/*==============================================================================
    PART 5: APPEND WAVES INTO PANEL
==============================================================================*/

/* First, harmonize variable names across waves */
/* Wave 1 uses 'age', Wave 2 uses 'age_w2', Wave 3 uses 'age_w3' */

use "$temp/w1_master.dta", clear

/* Harmonize FPrimary type: Wave 1 has numeric, Waves 2-3 have string */
cap confirm string variable FPrimary
if _rc != 0 {
    tostring FPrimary, replace force
}

gen age_harmonized = age
append using "$temp/w2_master.dta"
replace age_harmonized = age_w2 if wave == 2
append using "$temp/w3_master.dta"
replace age_harmonized = age_w3 if wave == 3

/* Create unique person ID */
egen person_id = group(FPrimary hhmid)

/* Create household ID */
egen hh_id = group(FPrimary)

/* Sort panel */
sort person_id wave

save "$temp/panel_all_individuals.dta", replace


/*==============================================================================
    PART 6: CONSTRUCT ANALYSIS VARIABLES
==============================================================================*/

use "$temp/panel_all_individuals.dta", clear

/*--- 6A. Total Household Consumption ---*/
gen total_consumption = total_food_exp + clothing_exp + other_exp + fuel_exp
replace total_consumption = total_food_exp if missing(total_consumption) & ///
    !missing(total_food_exp)

/* Per capita consumption */
bysort FPrimary wave: gen hh_size = _N
gen pc_consumption = total_consumption / hh_size
gen ln_pc_consumption = ln(pc_consumption)

/*--- 6B. Construct Composite Cognitive Score ---*/
/* Principal component of available test scores */
/* We standardize within each wave to account for test difficulty changes */

forvalues w = 1/3 {
    foreach var in ravens_correct dsf_score dsb_score math_correct english_correct {
        cap egen `var'_std_w`w' = std(`var') if wave == `w'
    }
}

/* Simple average of available standardized scores as cognitive index */
egen cog_index = rowmean(ravens_std dsf_std dsb_std math_std english_std)

/* Also keep individual test z-scores for robustness */

/*--- 6C. Height-for-Age Z-Score (HAZ) ---*/
/* Approximate HAZ using WHO standards */
/* HAZ = (height - median_height) / SD_height for age and sex */
/* For simplicity, compute age-sex standardized height */

bysort wave female: egen mean_height = mean(height_cm) if age_harmonized <= 17
bysort wave female: egen sd_height = sd(height_cm) if age_harmonized <= 17
gen haz_approx = (height_cm - mean_height) / sd_height if age_harmonized <= 17

/* Weight-for-age z-score */
bysort wave female: egen mean_weight = mean(weight_kg) if age_harmonized <= 17
bysort wave female: egen sd_weight = sd(weight_kg) if age_harmonized <= 17
gen waz_approx = (weight_kg - mean_weight) / sd_weight if age_harmonized <= 17

/* BMI for adults */
gen bmi = weight_kg / (height_cm/100)^2 if height_cm > 0 & weight_kg > 0

/*--- 6D. Education Variables ---*/
/* Harmonize education across waves */
gen mother_educ_years = .
/* Wave 1: highest_grade_w1 may be string or numeric with value labels */
/* Create a string version for safe comparison */
cap confirm string variable highest_grade_w1
if _rc != 0 {
    decode highest_grade_w1, gen(_hg_str)
}
else {
    gen _hg_str = highest_grade_w1
}
replace mother_educ_years = 0 if _hg_str == "None" & wave == 1
replace mother_educ_years = 1 if _hg_str == "P1" & wave == 1
replace mother_educ_years = 2 if _hg_str == "P2" & wave == 1
replace mother_educ_years = 3 if _hg_str == "P3" & wave == 1
replace mother_educ_years = 4 if _hg_str == "P4" & wave == 1
replace mother_educ_years = 5 if _hg_str == "P5" & wave == 1
replace mother_educ_years = 6 if _hg_str == "P6" & wave == 1
replace mother_educ_years = 7 if inlist(_hg_str, "JSS1", "Middle 1") & wave == 1
replace mother_educ_years = 8 if inlist(_hg_str, "JSS2", "Middle 2") & wave == 1
replace mother_educ_years = 9 if inlist(_hg_str, "JSS3", "Middle 3", "Middle/JSS") & wave == 1
replace mother_educ_years = 10 if _hg_str == "SSS1" & wave == 1
replace mother_educ_years = 11 if _hg_str == "SSS2" & wave == 1
replace mother_educ_years = 12 if _hg_str == "SSS3" & wave == 1
drop _hg_str

/* Generate education category */
gen educ_cat = .
replace educ_cat = 0 if mother_educ_years == 0  // No education
replace educ_cat = 1 if mother_educ_years >= 1 & mother_educ_years <= 6  // Primary
replace educ_cat = 2 if mother_educ_years >= 7 & mother_educ_years <= 9  // JHS
replace educ_cat = 3 if mother_educ_years >= 10 & mother_educ_years <= 12  // SHS
replace educ_cat = 4 if mother_educ_years > 12 & mother_educ_years < .  // Tertiary


/*==============================================================================
    PART 7: CREATE MOTHER-CHILD LINKED DATASET
==============================================================================*/

/* This is the key step: link each child to their mother within the household */

/* Step 1: Identify mothers in each household-wave */
preserve
    keep if mother == 1 | mother_w2_v2 == 1 | mother_w3 == 1
    keep FPrimary hhmid wave k10_score k10_std depression_cat depressed_binary ///
        age_harmonized mother_educ_years educ_cat weekly_hours pay_amount ///
        total_parental_time read_hw_time other_child_time total_child_time ///
        careforkids_yn nhis_registered nhis_valid_card bmi ///
        height_cm weight_kg days_childcare_week_w1 daysworkperweek ///
        depressed_precoded depression_score_precoded kessler_precomputed

    /* Rename to indicate these are mother's variables */
    foreach var in k10_score k10_std depression_cat depressed_binary ///
        age_harmonized mother_educ_years educ_cat weekly_hours pay_amount ///
        total_parental_time read_hw_time other_child_time total_child_time ///
        careforkids_yn nhis_registered nhis_valid_card bmi ///
        height_cm weight_kg days_childcare_week_w1 daysworkperweek {
        rename `var' m_`var'
    }
    rename hhmid mother_hhmid

    /* Keep one mother per household-wave (primary female) */
    bysort FPrimary wave: keep if _n == 1

    save "$temp/mothers_panel.dta", replace
restore

/* Step 2: Keep children */
preserve
    keep if child == 1 | child_w2 == 1 | child_w3 == 1
    keep FPrimary hhmid wave age_harmonized female child_female ///
        ravens_correct ravens_std dsf_score dsf_std dsb_score dsb_std ///
        math_correct math_std english_correct english_std ///
        cog_index haz_approx waz_approx height_cm weight_kg ///
        arm_circumference attending_school ///
        ill_2weeks days_sick stopped_activities days_stopped ///
        consulted_facility immun_count immun_rate ///
        nepsy_naming nepsy_inhibit ///
        person_id hh_id hh_size ///
        total_food_exp total_consumption pc_consumption ln_pc_consumption ///
        clothing_exp other_exp fuel_exp ///
        urbrur

    /* Rename child variables */
    rename age_harmonized c_age
    rename female c_female
    rename height_cm c_height
    rename weight_kg c_weight
    rename arm_circumference c_arm_circ
    rename hhmid child_hhmid

    save "$temp/children_panel.dta", replace
restore

/* Step 3: Merge mothers and children */
use "$temp/children_panel.dta", clear

merge m:1 FPrimary wave using "$temp/mothers_panel.dta", ///
    keep(master match) nogen

/* Add household-level controls (geographic identifiers are time-invariant) */
/* Drop wave from hhcover before merging so it matches all waves */
preserve
    use "$temp/w1_hhcover.dta", clear
    drop wave
    /* Convert FPrimary to string to match panel */
    cap confirm string variable FPrimary
    if _rc != 0 {
        tostring FPrimary, replace force
    }
    save "$temp/w1_hhcover_nowave.dta", replace
restore
merge m:1 FPrimary using "$temp/w1_hhcover_nowave.dta", ///
    keep(master match) nogen

/* Create EA-level fixed effect.
   Since hhcover comes from Wave 1, all matched HHs have regioncode/districtcode/eacode */
egen ea_id = group(regioncode districtcode eacode) if !missing(eacode)

/* Household-level consumption */
gen ln_total_food = ln(total_food_exp) if total_food_exp > 0

/* Create wave dummies */
gen wave2 = (wave == 2)
gen wave3 = (wave == 3)

/*--- Child age groups ---*/
gen c_age_group = .
replace c_age_group = 1 if c_age >= 0 & c_age <= 4   // Early childhood
replace c_age_group = 2 if c_age >= 5 & c_age <= 9   // Middle childhood
replace c_age_group = 3 if c_age >= 10 & c_age <= 14  // Early adolescence
replace c_age_group = 4 if c_age >= 15 & c_age <= 17  // Late adolescence

label define age_grp 1 "0-4" 2 "5-9" 3 "10-14" 4 "15-17"
label values c_age_group age_grp


/*==============================================================================
    PART 8: SAMPLE RESTRICTIONS AND FINAL CLEANING
==============================================================================*/

/* Keep only observations with non-missing maternal depression */
gen has_maternal_dep = !missing(m_k10_score)

/* Keep only observations where child has at least one cognitive test */
gen has_cog_test = !missing(ravens_correct) | !missing(dsf_score) | ///
    !missing(dsb_score) | !missing(math_correct) | !missing(english_correct)

/* Analysis sample: mother-child pairs with depression data and cognitive tests */
gen analysis_sample = (has_maternal_dep == 1 & has_cog_test == 1)

/* Label key variables */
label variable m_k10_score "Maternal K10 Depression Score"
label variable m_k10_std "Maternal K10 Score (Standardized)"
label variable m_depressed_binary "Maternal Depression (K10 >= 20)"
label variable cog_index "Child Cognitive Index (Avg of Std Scores)"
label variable ravens_std "Raven's Score (Standardized)"
label variable dsf_std "Digit Span Forward (Standardized)"
label variable dsb_std "Digit Span Backward (Standardized)"
label variable math_std "Math Score (Standardized)"
label variable english_std "English Score (Standardized)"
label variable haz_approx "Height-for-Age Z-Score (Approx)"
label variable waz_approx "Weight-for-Age Z-Score (Approx)"
label variable c_age "Child Age (Years)"
label variable c_female "Child is Female"
label variable m_age_harmonized "Mother's Age"
label variable m_educ_cat "Mother's Education Level"
label variable m_read_hw_time "Mother's Reading/Homework Time with Child (Hrs)"
label variable m_total_child_time "Mother's Total Time with Child (Hrs)"
label variable m_weekly_hours "Mother's Weekly Work Hours"
label variable m_pay_amount "Mother's Pay Amount"
label variable wave "Survey Wave (1=2009, 2=2012, 3=2018)"
label variable hh_size "Household Size"
label variable ln_pc_consumption "Log Per Capita Consumption"
label variable analysis_sample "In Analysis Sample"

/* Save final analysis dataset */
compress
save "$project/programs/stata/Draft1_Feb2026/analysis_data.dta", replace

/* Report sample sizes */
di _n "=============================================="
di "SAMPLE CONSTRUCTION SUMMARY"
di "=============================================="
di "Total individual-wave observations: " _N
tab wave if analysis_sample == 1, m
tab c_age_group wave if analysis_sample == 1, m
di _n "Mother-child pairs with depression + cognitive data:"
count if analysis_sample == 1

log close

/*==============================================================================
    END OF DATA CLEANING
==============================================================================*/
