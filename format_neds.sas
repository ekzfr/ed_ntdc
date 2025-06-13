* -----  NEDS Formats for Vars that I created ----; 

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
		1 = "Age 0-17 years"
		2 = "Age 18-44 years"
		3 = "Age 45-64 years"
		0 = "Age 65+ years (ref)";

	value f_SEX_cat
		0 = "Female (ref)"
		1 = "Male";

	value f_PAY_cat
		0 = "Private Insurance (ref)"
		1 = "Medicare"
		2 = "Medicaid"
		3 = "No Ins/Self Pay";

	value f_PL_NCHS_cat
		0 = "Urban (ref)"
		1 = "Rural";

	value f_RACE_cat
		0 = "White, non-hispanic (ref)"
		1 = "Black, non-hispanic"
		2 = "Hispanic"
		3 = "Other";

	value f_ZIPINC_cat
		1 = "First Income Quartile (2021 $1-51,999)"
		2 = "Second Income Quartile (2021 $52,000-65,999)"
		3 = "Third Income Quartile (2021 $66,000-87,999)"
		0 = "Fourth Income Quartile (2021 $88,000+) (ref)";

	value f_HOSP_REGION_cat
		0 = "West (ref)"
		1 = "Northeast"
		2 = "Midwest"
		3 = "South";

	value f_DEN
		0 = "All others"
		1,2,3 = "Visit for Nontraumatic Dental";

	value f_MUS
		0 = "All others"
		1,2,3 = "Visit for Low Back Pain";

	value f_NVS
		0 = "All others"
		1,2,3 = "Visit for Headache";

	value f_DOMAIN_M
		0 = "Not in domain"
		1 = "Domain of 'dental' or 'low back pain' concern";

	value f_DOMAIN_N
		0 = "Not in domain"
		1 = "Domain of 'dental' or 'headache' concern";

run;

*----- Misc NEDS Formats ------;

proc format;
	value f_AGE
		low -< 18 = "Age 0-17"
		18 -< 45 = "Age 18-44"
		45 -< 65 = "Age 45-64"
		65 - high = "Age 65+";

	value f_AGE_ahrq
		low - 17 = "0-17"
		18 - 44 = "18-44"
		45 - 64 = "45-64"
		65 - 84 = "65-85"
		85 - high = "85 years and older";

	value f_AWEEKEND
		0 = "Weekday Admission (Mon-Fri) (ref)"
		1 = "Weekend Admission (Sat-Sun)"; 

	value f_DIED_VISIT
		0 = "Did not die"
		1,2 = "Died in ED or hospital";

	value f_DQTR
		1 = "1st Quarter (Jan-Mar)"
		2 = "2nd Quarter (Apr-Jun)"
		3 = "3rd Quarter (Jul-Sep)"
		4 = "4th Quarter (Oct-Dec)";	

	value f_TOTCHG_ED
		low -< 200 = "$0-199"
		200 -< 400 = "$200-399"
		400 -< 600 = "$400-599"
		600 - high = "$600+";

	value f_RACE
		1 = "White"
		2 = "Black"
		3 = "Hispanic"
		4 = "Asian or Pacific Islander"
		5 = "Native American"
		6 = "Other";

	value f_RACE_ahrq
		1 = "White, non-hispanic"
		2 = "Black, non-hispanic"
		3 = "Hispanic"
		4,5,6 = "Other, non-hispanic";

	value f_RACE_binary
		1 = "White"
		2,3,4,5,6 = "Other";

	value f_FEMALE
		0 = "Male"
		1 = "Female";

	value f_DISP_ED 
		1 = "Routine"
		2 = "Transfer, short term hospital"
		5 = "Transfer, other"
		6 = "Home health care"
		7 = "Against medical advice"
		9 = "Admitted as inpatient"
		20 = "Died in ED"
		98 = "Not admitted, desination unknown"
		99 = "Not admitted, alive, destination unknown";

	value f_EDevent
		1 = "treated and released"
		2 = "admitted to hospital"
		3 = "transferred, short term hospital"
		9 = "died in ED"
		98 = "not admitted, destination unknown"
		99 = "not admitted, discharged alive, destination unknown";

	value f_EDevent_binary
		1 = "treated and released"
		2,3,9,98,99 = "other (admitted/transfered/died)";
		
	value f_PAY 
		1 = "Medicare"
		2 = "Medicaid"
		3 = "Private insurance"
		4,5,6 = "No insurance";

	value f_PAY_ahrq
		1 = "Medicare"
		2 = "Medicaid"
		3 = "Private insurance"
		4 = "No insurance"
		5,6 = "Other";

	value f_HOSP_REGION
		1 = "Northeast"
		2 = "Midwest"
		3 = "South"
		4 = "West";

	value f_HOSP_URCAT
		1 = "lrg metropolitan areass w/ at least 1mil residents"
		2 = "sml metropolitan areas w/ <1mil residents"
		3 = "micropolitan areas"
		4 = "non-urban residential"
		6 = "urban-rural collapsed category"
		7 = "sml metro and micropolitan collapsed category"
		8 = "metropolitan (lrg and sml metro collapsed category)"
		9 = "non-metro (micro and non-urban collapsed category)";

	value f_ZIQ_nine
		1 = "1stQ 1-47,999"
		2 = "2ndQ 48,000-60,999"
		3 = "3rdQ 61,000-81,999"
		4 = "4thQ 82,000+";

	value f_ZIQ_zero
		1 = "1stQ 1-49,999"
		2 = "2ndQ 50,000-64,999"
		3 = "3rdQ 65,000-85,999"
		4 = "4thQ 86,000+";
		
	value f_ZIQ
		1 = "1stQ 1-51,999"
		2 = "2ndQ 52,000-65,999"
		3 = "3rdQ 66,000-87,999"
		4 = "4thQ 88,000+";

	value f_ZIQ_binary
		1 = "Low Income Quartile ($1-51,999)"
		2,3,4 = "Other ($52,000+)";

	value f_DXCCSR
		0 = "Group not contained in input record"
		1 = "Group listed in principle Dx only"
		2 = "Group listed in prinicple & secondary Dx"
		3 = "Group listed in secondary Dx only";

	value f_PL_NCHS
		1 = "Central counties of metro areas >=1mil pop"
		2 = "Fringe counties of metro areas >=1mil pop"
		3 = "Counties in metro areas of 250,000-999,999 pop"
		4 = "Counties in metro areas of 50,000-249,999 pop"
		5 = "Micropolitan counties"
		6 = "Not metropolitan or micropolitan counties";

	value f_PL_NCHS_ahrq
		1,2 = "Large metropolitan"
		3,4 = "Medium/small metropolitan"
		5 = "Micropolitan"
		6 = "Non-metropolitan/Rural";

	value f_PL_NCHS_binary
		1,2,3,4 = "Urban"
		5,6 = "Rural";

	value f_HOSP_CONTROL
		0 = "Government or private (collapsed category)"
		1 = "Government, non-federal (public)"
		2 = "Private, not-for-profit (voluntary)"
		3 = "Private, investor-owned (proprietary)"
		4 = "Private (collapsed category)";

	value f_HOSP_CONTROL_grps
		1 = "Public"
		0,2 = "Non-profit"
		3,4 = "Private, Investor-owned";
run;
