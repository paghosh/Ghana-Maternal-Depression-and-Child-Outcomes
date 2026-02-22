/*==============================================================================
    Project:    Maternal Depression, Parental Investment, and Child Cognitive
                Development in Ghana
    File:       master.do
    Purpose:    Master do file that runs all analysis files in sequence
    Author:     Pallab Ghosh, University of Oklahoma
    Created:    February 2026

    INSTRUCTIONS:
    1. Set the global path below to match your machine
    2. Run this file to execute the entire analysis pipeline
    3. Output tables will be saved in:
       $project/rersults/Draft1_Feb2026/
       in LaTeX (.tex), text (.txt), CSV (.csv), and Excel (.xlsx) formats

    DATA SOURCE:
    Ghana Socioeconomic Panel Survey (GSPS), Waves 1-3
    Yale Economic Growth Center

    DO FILES:
    00_data_cleaning.do    — Merge and construct analysis variables
    01_summary_stats.do    — Summary statistics tables
    02_main_estimation.do  — Main OLS, FE, and IV regressions
    03_mechanisms.do       — Channel/mechanism analysis
    04_robustness.do       — Robustness checks and sensitivity analysis
==============================================================================*/

clear all
set more off
set maxvar 32767

timer clear
timer on 1

/*------------------------------------------------------------------------------
    Set Paths (MODIFY THIS FOR YOUR MACHINE)
------------------------------------------------------------------------------*/
global project  "/Users/pallab.ghosh/Library/CloudStorage/Dropbox/D/Study/My_Papers/OU/Health/Ghana_mental_health/maternal_depression_child_cog_devlopment"
global programs "$project/programs/stata/Draft1_Feb2026"

/*------------------------------------------------------------------------------
    Run Analysis Pipeline
------------------------------------------------------------------------------*/

/* Step 1: Data Cleaning and Variable Construction */
di _n(3) "=============================================="
di "RUNNING: 00_data_cleaning.do"
di "=============================================="
do "$programs/00_data_cleaning.do"

/* Step 2: Summary Statistics */
di _n(3) "=============================================="
di "RUNNING: 01_summary_stats.do"
di "=============================================="
do "$programs/01_summary_stats.do"

/* Step 3: Main Estimation */
di _n(3) "=============================================="
di "RUNNING: 02_main_estimation.do"
di "=============================================="
do "$programs/02_main_estimation.do"

/* Step 4: Mechanisms / Channels */
di _n(3) "=============================================="
di "RUNNING: 03_mechanisms.do"
di "=============================================="
do "$programs/03_mechanisms.do"

/* Step 5: Robustness Checks */
di _n(3) "=============================================="
di "RUNNING: 04_robustness.do"
di "=============================================="
do "$programs/04_robustness.do"

/*------------------------------------------------------------------------------
    Report Timing
------------------------------------------------------------------------------*/
timer off 1
timer list

di _n(3) "=============================================="
di "ALL ANALYSIS COMPLETE"
di "=============================================="
di "Output saved to: $project/rersults/Draft1_Feb2026/"
di _n "Files generated:"
di "  Tables 1-5:  Summary statistics (LaTeX, text, Excel)"
di "  Tables 6-12: Main estimation results"
di "  Tables 13-18: Mechanism/channel analysis"
di "  Tables A1-A9: Robustness checks"
