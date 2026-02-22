/* Install required packages */
cap ssc install require, replace
cap ssc install ftools, replace
cap ssc install reghdfe, replace
cap ftools, compile
cap ssc install estout, replace
cap ssc install outreg2, replace
cap ssc install ivreg2, replace
cap ssc install ranktest, replace
cap ssc install ivreghdfe, replace

/* Quick test that reghdfe works */
sysuse auto, clear
reghdfe price mpg, absorb(foreign)
di "reghdfe test passed"
