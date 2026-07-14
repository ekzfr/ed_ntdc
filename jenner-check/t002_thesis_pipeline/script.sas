/* -----------------------------------------------------------------------
 * Adapted from kazfrick-thesis-program_2021_v7.sas (this repository).
 *
 * The original reads the AHRQ HCUP NEDS 2021 Core / DX-PR-Groups /
 * Hospital tables via libname (available only under the HCUP DUA), writes
 * an ODS PDF and a permanent library on the author's machine, and %includes
 * format_neds.sas. To make the analytic pipeline self-contained here, three
 * small NEDS-shaped WORK tables stand in for the licensed source tables,
 * the formats are inlined, and the machine-specific ODS/libname paths are
 * dropped. The author's own logic -- the trim DATA steps, the PROC SQL
 * full join on KEY_ED, the one-to-many hospital merge, the domain/recode
 * DATA steps, and the survey-weighted PROC SURVEYFREQ tables -- is kept
 * intact and runs unmodified against the stand-in data.
 * ----------------------------------------------------------------------- */

/* --- format library from format_neds.sas (subset used below) --- */
proc format;
  value f_DOMAIN_CASES
    0 = "All Others (excl. cases & control cases)"
    1 = "NTDC cases (cases for DEN002 only)"
    2 = "Low back pain control cases (cases for MUS038 only)"
    3 = "Headache control cases (cases for NVS010 only)";
  value f_DEN002_cat
    0 = "All Others"
    1 = "Visits for Nontraumatic Dental";
  value f_AGE_cat
    1 = "Age 0-17 years"  2 = "Age 18-44 years"
    3 = "Age 45-64 years" 0 = "Age 65+ years (ref)";
  value f_SEX_cat        0 = "Female (ref)" 1 = "Male";
  value f_PAY_cat        0 = "Private Insurance (ref)" 1 = "Medicare" 2 = "Medicaid" 3 = "No Ins/Self Pay";
  value f_PL_NCHS_cat    0 = "Urban (ref)" 1 = "Rural";
  value f_RACE_cat       0 = "White, non-hispanic (ref)" 1 = "Black, non-hispanic" 2 = "Hispanic" 3 = "Other";
  value f_ZIPINC_cat     1 = "First Income Quartile (2021 $1-51,999)" 2 = "Second Income Quartile (2021 $52,000-65,999)" 3 = "Third Income Quartile (2021 $66,000-87,999)" 0 = "Fourth Income Quartile (2021 $88,000+) (ref)";
  value f_HOSP_REGION_cat 0 = "West (ref)" 1 = "Northeast" 2 = "Midwest" 3 = "South";
  value f_DEN 0 = "All others" 1,2,3 = "Visit for Nontraumatic Dental";
  value f_MUS 0 = "All others" 1,2,3 = "Visit for Low Back Pain";
  value f_NVS 0 = "All others" 1,2,3 = "Visit for Headache";
  value f_DOMAIN_M 0 = "Not in domain" 1 = "Domain of 'dental' or 'low back pain' concern";
  value f_DOMAIN_N 0 = "Not in domain" 1 = "Domain of 'dental' or 'headache' concern";
run;

/* --- MOCK NEDS-shaped source tables (stand-ins for nedslib.* under DUA) --- */
data neds_2021_core;
  input AGE AMONTH AWEEKEND DIED_VISIT DISCWT DISP_ED DQTR EDevent FEMALE HOSP_ED KEY_ED NEDS_STRATUM PAY1 PL_NCHS RACE TOTCHG_ED ZIPINC_QRTL;
  datalines;
25 3 0 0 2.51 1 1 1 1 101 1001 11 3 1 1 250 2
67 6 1 0 3.02 9 2 2 0 101 1002 11 1 5 2 810 4
44 9 0 0 1.55 1 3 1 1 102 1003 12 2 3 6 175 1
15 1 1 0 2.20 1 1 1 0 102 1004 12 4 2 3 620 3
52 11 0 0 1.80 5 4 2 1 103 1005 13 3 6 4 430 3
73 4 1 1 2.90 20 2 9 0 103 1006 13 2 5 5 990 4
31 7 0 0 1.40 1 3 1 1 104 1007 14 1 4 2 300 2
19 2 0 0 2.05 6 1 1 0 104 1008 14 3 1 1 120 1
;
run;

data neds_2021_dx_pr_grps;
  input KEY_ED DXCCSR_DIG002 DXCCSR_DEN001 DXCCSR_DEN002 DXCCSR_DEN003 DXCCSR_MUS038 DXCCSR_NVS010;
  datalines;
1001 1 0 1 0 0 0
1002 0 0 0 0 1 0
1003 1 0 1 0 0 0
1004 0 0 0 0 0 1
1005 0 0 0 0 0 0
1006 0 0 0 0 1 1
1007 1 0 1 0 0 0
1008 0 0 0 0 0 0
;
run;

data neds_2021_hospital;
  input HOSP_ED HOSP_REGION HOSP_CONTROL;
  datalines;
101 1 2
102 2 3
103 3 1
104 4 2
;
run;

/* -- DATA STEP 1: Trimming large tables ------------ (from their program) */
data dxgrp_2021_trim;
set neds_2021_dx_pr_grps
  (keep= KEY_ED DXCCSR_DIG002 DXCCSR_DEN001 DXCCSR_DEN002 DXCCSR_DEN003 DXCCSR_MUS038 DXCCSR_NVS010);
run;

data hospital_2021_trim;
set neds_2021_hospital
  (keep= HOSP_ED HOSP_REGION HOSP_CONTROL);
run;

data core_2021_trim;
set neds_2021_core
  (keep= AGE AMONTH AWEEKEND DIED_VISIT DISCWT DISP_ED DQTR EDevent FEMALE HOSP_ED KEY_ED NEDS_STRATUM PAY1 PL_NCHS RACE TOTCHG_ED ZIPINC_QRTL);
run;

/* -- PROC SQL STEP: full join core x dx groups on KEY_ED -- */
proc sql;
  create table sqlstep as
  select *
  from core_2021_trim as c
  full join dxgrp_2021_trim as g
  on c.KEY_ED = g.KEY_ED;
quit;

/* -- DATA STEP 2: one-to-many merge on HOSP_ED -- */
proc sort data=sqlstep out=sqlstep_sort;    by HOSP_ED; run;
proc sort data=hospital_2021_trim out=hospital_sort; by HOSP_ED; run;

data merge_2021_tables;
  merge sqlstep_sort hospital_sort;
  by HOSP_ED;
proc sort;
  by KEY_ED;
run;

/* -- DATA STEP 3: test/control domain + recoded class variables -- */
data thesis_2021_newvars;
set merge_2021_tables;
  if DXCCSR_DEN002 > 0 AND DXCCSR_MUS038 = 0 then DOMAIN_MUS = 1;
  if DXCCSR_DEN002 = 0 AND DXCCSR_MUS038 > 0 then DOMAIN_MUS = 1;
  if DXCCSR_DEN002 = 0 AND DXCCSR_MUS038 = 0 then DOMAIN_MUS = 0;
  if DXCCSR_DEN002 > 0 AND DXCCSR_MUS038 > 0 then DOMAIN_MUS = 0;

  if DXCCSR_DEN002 > 0 AND DXCCSR_NVS010 = 0 then DOMAIN_NVS = 1;
  if DXCCSR_DEN002 = 0 AND DXCCSR_NVS010 > 0 then DOMAIN_NVS = 1;
  if DXCCSR_DEN002 = 0 AND DXCCSR_NVS010 = 0 then DOMAIN_NVS = 0;
  if DXCCSR_DEN002 > 0 AND DXCCSR_NVS010 > 0 then DOMAIN_NVS = 0;

  if FEMALE = 1 then SEX_cat = 0;
  if FEMALE = 0 then SEX_cat = 1;

  if RACE = 1 then RACE_cat = 0;
  if RACE = 2 then RACE_cat = 1;
  if RACE = 3 then RACE_cat = 2;
  if RACE = 4 then RACE_cat = 3;
  if RACE = 5 then RACE_cat = 3;
  if RACE = 6 then RACE_cat = 3;

  if PAY1 = 3 then PAY_cat = 0;
  if PAY1 = 1 then PAY_cat = 1;
  if PAY1 = 2 then PAY_cat = 2;
  if PAY1 = 4 then PAY_cat = 3;
  if PAY1 = 5 then PAY_cat = 3;
  if PAY1 = 6 then PAY_cat = 3;

  if PL_NCHS = 1 then PL_NCHS_cat = 0;
  if PL_NCHS = 2 then PL_NCHS_cat = 0;
  if PL_NCHS = 3 then PL_NCHS_cat = 0;
  if PL_NCHS = 4 then PL_NCHS_cat = 0;
  if PL_NCHS = 5 then PL_NCHS_cat = 1;
  if PL_NCHS = 6 then PL_NCHS_cat = 1;

  if HOSP_REGION = 4 then HOSP_REGION_cat = 0;
  if HOSP_REGION = 1 then HOSP_REGION_cat = 1;
  if HOSP_REGION = 2 then HOSP_REGION_cat = 2;
  if HOSP_REGION = 3 then HOSP_REGION_cat = 3;

  if ZIPINC_QRTL = 4 then ZIPINC_cat = 0;
  if ZIPINC_QRTL = 1 then ZIPINC_cat = 1;
  if ZIPINC_QRTL = 2 then ZIPINC_cat = 2;
  if ZIPINC_QRTL = 3 then ZIPINC_cat = 3;

  if DXCCSR_DEN002 = 0 then DEN002_cat = 0;
  if DXCCSR_DEN002 > 0 then DEN002_cat = 1;
run;

data thesis_2021_cases;
set thesis_2021_newvars;
  if DXCCSR_DEN002 > 0 then do;
    if DXCCSR_MUS038 = 0 AND DXCCSR_NVS010 = 0 then DOMAIN_CASES = 1;
    if DXCCSR_MUS038 > 0 AND DXCCSR_NVS010 > 0 then DOMAIN_CASES = 0;
    if DXCCSR_MUS038 > 0 AND DXCCSR_NVS010 = 0 then DOMAIN_CASES = 0;
    if DXCCSR_MUS038 = 0 AND DXCCSR_NVS010 > 0 then DOMAIN_CASES = 0;
  end;
  if DXCCSR_DEN002 = 0 then do;
    if DXCCSR_MUS038 > 0 AND DXCCSR_NVS010 = 0 then DOMAIN_CASES = 2;
    if DXCCSR_MUS038 = 0 AND DXCCSR_NVS010 > 0 then DOMAIN_CASES = 3;
    if DXCCSR_MUS038 > 0 AND DXCCSR_NVS010 > 0 then DOMAIN_CASES = 0;
    if DXCCSR_MUS038 = 0 AND DXCCSR_NVS010 = 0 then DOMAIN_CASES = 0;
  end;
run;

data thesis_2021_data;
set thesis_2021_cases;
  if AGE >=0 AND AGE <= 17 then AGE_cat = 1;
    else if AGE >= 18 AND AGE <=44 then AGE_cat = 2;
    else if AGE >=45 AND AGE <= 64 then AGE_cat = 3;
    else if AGE >= 65 then AGE_cat = 0;
run;

/* --- quality check + descriptive statistics (survey-weighted) --- */
proc surveyfreq data=thesis_2021_data;
  tables DOMAIN_CASES *
    (DXCCSR_DEN002 DXCCSR_MUS038 DXCCSR_NVS010)/ row col plots=none;
  format
    DXCCSR_DEN002 f_DEN.
    DXCCSR_MUS038 f_MUS.
    DXCCSR_NVS010 f_NVS.;
  strata NEDS_STRATUM;
  weight DISCWT;
  title "Data steps quality check - DOMAIN_CASES x DXCCSR cross check";
run;

proc surveyfreq data=thesis_2021_data;
  tables
    AGE_cat SEX_cat PAY_cat PL_NCHS_cat RACE_cat
    ZIPINC_cat HOSP_REGION_cat DOMAIN_CASES DEN002_cat / row col plots=none;
  format
    AGE_cat f_AGE_cat.
    SEX_cat f_SEX_cat.
    PAY_cat f_PAY_cat.
    PL_NCHS_cat f_PL_NCHS_cat.
    RACE_cat f_RACE_cat.
    ZIPINC_cat f_ZIPINC_cat.
    HOSP_REGION_cat f_HOSP_REGION_cat.
    DOMAIN_CASES f_DOMAIN_CASES.
    DEN002_cat f_DEN002_cat.;
  strata NEDS_STRATUM;
  weight DISCWT;
  title "Descriptive Statistics - 2021 Variable level counts";
run;
