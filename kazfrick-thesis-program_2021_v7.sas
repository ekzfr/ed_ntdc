*Kaz Frick Thesis Program 2021 v6.sas
authors: Kaz Frick & Simon
date created: 2025-01-03
modified: 2025-03-03 
purpose: Evaluate NEDS 2021 for NTDCs seen in US EDs.
license: To be used only within AHRQ HCUP DUA terms and conditions;

*DATA SOURCE: AHRQ HCUP owns the right to the dataset used in this program. 
	Data is provided by HCUP for research purposes under a DUA.
	Documentation for this database can be found here:
		https://hcup-us.ahrq.gov/db/nation/neds/nedsdbdocumentation.jsp
	NEDS File Speciications can be found here:
		https://hcup-us.ahrq.gov/db/nation/neds/nedsfilespecs.jsp;

*The libname allows us to create a short "nickname" for the file pathway where the 
	data files are stored. This nickname is a stand-in for the pathway: 
	nedslib.FILENAME ;

libname nedslib
	"F:\NEDS\Datasets\SAS"
	access=readonly;
libname mylib
	"D:\perm\2021";

*the % sign indicates a macro that will open and run a separate SAS program at the 
	start of this program. I have saved my variable format labels in this file.;
*Proc format allows us to replace number codes with descriptive labels in plain 
	English. The decriptions of all data elements can be viewed here: 
	https://hcup-us.ahrq.gov/db/nation/neds/nedsdde.jsp ;
%include 
	"D:\perm\frequent\format_neds.sas";

*SAS Output Delivery System (ODS) provides formatting functionality to the SAS program 
	outside of individual procedures. Below, ODS PDF and ODS GRAPHICS are used. 
	'ODS graphics' tells the program to create graphical output for procedures where 
	appropriate. 'ODS pdf file' will save a pdf copy of the output each time the 
	program is run.;
ods graphics on;
ods pdf file=
	"D:\results/2021/kazfrick_2021 output_2025-03-03.pdf";

*2021 NEDS Data File Information;
*The Core File contains the primary visit-level observations for ED encounters in 2021.
	Data Set File Name: NEDS_2021_CORE;
*The Hospital Weights File is the file that contains hospital weights & hospital/sample 
	characteristics.
	Data Set File Name: NEDS_2021_HOSPITAL;
*The Diagnosis and Procedure Groups File contains groups for combining many ICD-10-CM 
	diagnosis codes into one meaningful group, starting with NEDS 2018. From 2018-2020, 
	all dental conditions (including traumatic) were combined under group variable 
	"DIG002 - Disorders of teeth and gingiva". In 2021, dental subgroups distinguishing 
	traumatic, nontramatic, and caries/perio/other preventable dental diseases were added 
	as DEN001, DEN002, and DEN003 respectively. This study is interested in DEN002 and DEN003 
	which is found in NEDS 2021 only. 
	Data Set File Name: NEDS_2021_DX_PR_GRPS

* ------------------- RAW DATA COUNTS ------------------------------------;

proc means
	n nmiss
	data=
		nedslib.neds_2021_core;
	var
		AGE
		AMONTH
		AWEEKEND
		DIED_VISIT
		DISCWT
		DISP_ED
		DQTR
		EDevent	
		FEMALE
		HOSP_ED
		KEY_ED			
		NEDS_STRATUM
		PAY1
		PL_NCHS
		RACE			
		TOTCHG_ED
		ZIPINC_QRTL;
	title1 
		"Data steps reference counts - 2021 Missing counts (Pre-Data Preparation)";
	title2 
		"Data steps reference counts - 2021 NEDS Core table"; 
run;

proc means
	n nmiss
	data=
		nedslib.neds_2021_dx_pr_grps;
	var 
		KEY_ED 
		DXCCSR_DIG002
		DXCCSR_DEN001
		DXCCSR_DEN002
		DXCCSR_DEN003
		DXCCSR_MUS038 
		DXCCSR_NVS010;
	title2 
		"Data steps reference counts - 2021 NEDS Diagnosis & Procedure Groups table"; 
run;

proc means
	n nmiss
	data=
		nedslib.neds_2021_hospital;
	var
		HOSP_ED 
		HOSP_REGION
		HOSP_CONTROL;
	title2 
		"Data steps reference counts - 2021 NEDS Hospital table"; 
run;


*------- DATA PREPARATION SECTION --------------------------------------------;

*DATA CLEANING AND CREATION OF A SINGLE MERGED TABLE:
	The large NEDS data tables 'Core', 'DX PR Groups' and 'Hospital' were trimmed to only 
	those columns of interest to my project using a DATA step. This is done to reduce CPU 
	processing time and simplify a subsequent SQL step to combine all variables into a single 
	data table for analysis. For example, the 'DX PR Groups' file contains over 500 columns, 
	so trimming the unneeded columns first greatly simplifies the coding process. 
	Then, a one-to-many DATA step was used to add the trimmed tables to the merged 'Core' and 
	'DX PR Groups' table. The resulting table includes all variables of interest from the 
	'Core', 'DX PR Groups', and 'Hospital' data tables. Within this file, a third data step
	is performed to create binary variables to use within the domain statement in the logistic
	regression models. Two binary variables were created: combining the test diagnosis group
	DIG002 (dental concerns) and MUS038 (low back pain, unspecified) control, and also one
	combining DIG002 encounters and NVS010 (headache, unspecified) second control. The 
	resulting 'thesis_nineteen' table sorted by KEY_ED, is the table that will be used to 
	perform data visualization and data analysis.  

	Documentation of these steps, performed in a separate program, is as follows:;


	*-- DATA STEP 1: Trimming large tables ------------;
data
	dxgrp_2021_trim;
set
	nedslib.neds_2021_dx_pr_grps
	(keep= 
		KEY_ED 
		DXCCSR_DIG002
		DXCCSR_DEN001
		DXCCSR_DEN002
		DXCCSR_DEN003
		DXCCSR_MUS038 
		DXCCSR_NVS010);
run;

data
	hospital_2021_trim;
set
	nedslib.neds_2021_hospital
	(keep= 
		HOSP_ED 
		HOSP_REGION
		HOSP_CONTROL);
run;


data
	core_2021_trim;
set
	nedslib.neds_2021_core
		(keep= 
			AGE
			AMONTH
			AWEEKEND
			DIED_VISIT
			DISCWT
			DISP_ED
			DQTR
			EDevent	
			FEMALE
			HOSP_ED
			KEY_ED			
			NEDS_STRATUM
			PAY1
			PL_NCHS
			RACE			
			TOTCHG_ED
			ZIPINC_QRTL);
run;

	
	*-- PROC SQL STEP: Combining core and dx groups in a full join on KEY_ED -----;
proc sql;
	create table sqlstep as
	select *
	from core_2021_trim as c
	full join dxgrp_2021_trim as g
	on c.KEY_ED = g.KEY_ED;
quit;

	*------- DATA STEP 2: One-to-many merge, on foreign key HOSP_ED ----------;
proc sort 
	data=sqlstep
	out=sqlstep_sort;
	by HOSP_ED;
run;

proc sort
	data=hospital_2021_trim
	out=hospital_sort;
	by HOSP_ED;
run;

data
	merge_2021_tables;
	merge sqlstep_sort hospital_sort;
	by HOSP_ED;

proc sort;
	by KEY_ED;
run;

	*--- DATA STEP 3: Creating test/control group variables for domain & class statements in lorgreg models;
	*Data Step 3 NOTE: A small sum of observations (Less than 1% of records) contained both a test code 
		(dental) and a control code (low back pain or headache) recorded within an encounter. So as to 
		maintain independence of observations, those encounter records containing both a test and control 
		group diagnosis code were treated as if the encounter had neither recorded, appearing as 0 for 
		'non-outcome' within the new domain variables. This was done so that no single observations were 
		analyzed within both test and control.; 

data
	thesis_2021_newvars;
set
	merge_2021_tables;
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
	
data
	thesis_2021_cases;
set
	thesis_2021_newvars;
		if DXCCSR_DEN002 > 0 then
			if DXCCSR_MUS038 = 0 AND DXCCSR_NVS010 = 0 then DOMAIN_CASES = 1;
		if DXCCSR_DEN002 > 0 then
			if DXCCSR_MUS038 > 0 AND DXCCSR_NVS010 > 0 then DOMAIN_CASES = 0;
		if DXCCSR_DEN002 > 0 then
			if DXCCSR_MUS038 > 0 AND DXCCSR_NVS010 = 0 then DOMAIN_CASES = 0;
		if DXCCSR_DEN002 > 0 then
			if DXCCSR_MUS038 = 0 AND DXCCSR_NVS010 > 0 then DOMAIN_CASES = 0;

		if DXCCSR_DEN002 = 0 then
			if DXCCSR_MUS038 > 0 AND DXCCSR_NVS010 = 0 then DOMAIN_CASES = 2;
		if DXCCSR_DEN002 = 0 then
			if DXCCSR_MUS038 = 0 AND DXCCSR_NVS010 > 0 then DOMAIN_CASES = 3;
		if DXCCSR_DEN002 = 0 then
			if DXCCSR_MUS038 > 0 AND DXCCSR_NVS010 > 0 then DOMAIN_CASES = 0;
		if DXCCSR_DEN002 = 0 then
			if DXCCSR_MUS038 = 0 AND DXCCSR_NVS010 = 0 then DOMAIN_CASES = 0;
	run;

data
	thesis_2021_data;
set
	thesis_2021_cases;
		if AGE >=0 AND AGE <= 17 then AGE_cat = 1;
			else if AGE >= 18 AND AGE <=44 then AGE_cat = 2;
			else if AGE >=45 AND AGE <= 64 then AGE_cat = 3;
			else if AGE >= 65 then AGE_cat = 0;
run;

*--- Adding column labels to the new variables-----;

proc datasets;
	modify mylib.thesis_2021_data;
	label 
		DOMAIN_MUS = 'Domain of DEN002 and MUS038 Visits'
		DOMAIN_NVS = 'Domain of DEN002 and NVS010 Visits'
		AGE_cat = 'Patient Age in Years'
		SEX_cat = 'Patient Sex'
		RACE_cat = 'Patient Race and Ethnicity'
		PAY_cat = 'Visit Primary Expected Payer'
		PL_NCHS_cat = 'Patient Location'
		HOSP_REGION_cat = 'Hospital Region in US'
		ZIPINC_cat = 'Income Quartile for Patient Zip Code'
		DEN002_cat = 'Nontraumatic Dental Visit'
		DOMAIN_CASES = 'Nontraum Dental, Low Back, or Headache Visit';
run;


*The 'thesis_2021_data' SAS file was created using DATA steps and PROC SQL to combine three 
	NEDS tables into one table with only the columns of interest to this project, 
	including creating new variables to use as class and domain variables for the
	logistic regression, odds ratio, and confidence interval calculations, and to 
	provide appropriate recoding for predictors and outcome variables with "0" as
	the reference category.;

*After the final table was finished, I cut and paste the file out of the temp SAS folder into
	a permanent file folder within my AWS study drive ('mylib' location).;

* --- Checking Data & SQL Steps with counts/missingness -------; 

*Here, PROC MEANS is used instead of PROC SURVEYMEANS because we do not need to apply 
	weights to a simple count of missing fields in the data table. Our interest is at 
	the level of the data table rather than calculations arising from the data as 
	representative of the sample population.; 

proc means
	n nmiss
	data=
		mylib.thesis_2021_data;
	title 
		"Data steps quality check - 2021 Missing counts (Post Data Preparation)";
run;

*--quality check of domain variable using surveyfreq ---;

proc surveyfreq
	data=
		mylib.thesis_2021_data;
	tables 
		DOMAIN_CASES *
		(DXCCSR_DEN002
		DXCCSR_MUS038
		DXCCSR_NVS010)/ row col plots=none;
	format 
		DXCCSR_DEN002 f_DEN.
		DXCCSR_MUS038 f_MUS.
		DXCCSR_NVS010 f_NVS.;
	strata NEDS_STRATUM;
	weight DISCWT;
	title "Data steps quality check - DOMAIN_CASES x DXCCSR cross check";
run;

proc surveyfreq
	data=
		mylib.thesis_2021_data;
	tables 
		DXCCSR_DEN002 *
		(DXCCSR_MUS038
		DXCCSR_NVS010)/ row col plots=none;
	format 
		DXCCSR_DEN002 f_DEN.
		DXCCSR_MUS038 f_MUS.
		DXCCSR_NVS010 f_NVS.;
	strata NEDS_STRATUM;
	weight DISCWT;
	title "Data steps quality check - DXCCSR x DXCCSR frequency cross-reference";
run;
proc surveyfreq
	data=
		mylib.thesis_2021_data;
	tables
		DOMAIN_CASES
		DOMAIN_MUS
		DOMAIN_NVS;
	format
		DOMAIN_MUS f_DOMAIN_M.
		DOMAIN_NVS f_DOMAIN_N.;
	title "Data steps quality check - DOMAIN_CASES frequency cross-reference";
run;


*------- DESCRIPTIVE STATISTICS SECTION -------------------------------------------;

*The following tables show proportions via counts/multi-way tabless for each of the 
	categorical exposure variables using PROC SURVEYMEANS and PROC SURVEYFREQ  within 
	each domain: a) the susbgroup of dental and low back pain visits, and b) the subgroup
	of dental and unspecified headache visits. Since we want to consider the data as 
	a meaningful representation of the population, we now apply weight and strata.;
* Note: In keeping with epidemiology standards, the crosstabulation tables are presented with
	the outcome variable (encounter type) as the Columns, and the exposure variable (patient 
	or hospital level indicators like age, income quartile, primary payer, and hospital region)
	as the rows. This is important to remember when interpreting odds ratios.;

*In SAS, the TABLES statement views the last variable as the columns, and the second to last 
	variable as the rows. Additional variables above these integrate the domains. Here, we do 
	not use a BY statement, because the numerator and denominator counts of our population are 
	not finite. To obtain a valid subgroup analysis, we must use domains instead. 
See SAS Help Guide: 
	"For two-way tables to multiway tables, the values of the last variable form the 
	crosstabulation table columns, while the values of the next-to-last variable form the rows. 
	Each level (or combination of levels) of the other variables forms one layer. 
	PROC SURVEYFREQ produces a separate crosstabulation table for each layer. 
	For example, a specification of A*B*C*D in a TABLES statement produces k tables, where k 
	is the number of different combinations of levels for A and B. Each table lists the 
	levels for D (columns) within each level of C (rows)." 
	"Note that using a BY statement provides completely separate analyses of the BY groups. 
	It does not provide a statistically valid subpopulation or domain analysis, where the 
	total number of units in the subpopulation is not known with certainty. You should 
	include the domain variable(s) in your TABLES request to obtain domain analysis.";

*In a 2x2 table in SAS, the first listed variable in TABLES statement is the row, and
	the second listed variable is the column. A * B = A_row * B_col. Put exposure in 
	the rows, and case/control or event/non-event in the columns. ;

proc surveyfreq
	data=
		mylib.thesis_2021_data;
	tables 
		AGE_cat
		AWEEKEND
		EDevent
		SEX_cat
		PAY_cat
		PL_NCHS_cat
		RACE_cat
		ZIPINC_cat
		HOSP_REGION_cat 
		DOMAIN_CASES
		DXCCSR_MUS038
		DXCCSR_NVS010
		DEN002_cat / row col OR plots=none;
	format
		AGE_cat f_AGE_cat.
		AWEEKEND f_AWEEKEND.
		EDevent f_EDevent_binary.
		SEX_cat f_SEX_cat.
		PAY_cat f_PAY_cat.
		PL_NCHS_cat f_PL_NCHS_cat.
		RACE_cat f_RACE_cat.
		ZIPINC_cat f_ZIPINC_cat.
		HOSP_REGION_cat f_HOSP_REGION_cat.
		DOMAIN_CASES f_DOMAIN_CASES.
		DXCCSR_MUS038 f_MUS.
		DXCCSR_NVS010 f_NVS.
		DEN002_cat f_DEN002_cat.;
	strata 
		NEDS_STRATUM;
	weight 
		DISCWT;
	title "Descriptive Statistics - 2021 Variable level counts";
run; 

proc surveyfreq
	data=
		mylib.thesis_2021_data;
	tables 
		(AGE_cat
		AWEEKEND
		EDevent
		SEX_cat
		PAY_cat
		PL_NCHS_cat
		RACE_cat
		ZIPINC_cat
		HOSP_REGION_cat) * 
			DOMAIN_CASES / row col plots=none;
	format
		DOMAIN_CASES f_DOMAIN_CASES.
		DEN002_cat f_DEN002_cat.
		AGE_cat f_AGE_cat.
		AWEEKEND f_AWEEKEND.
		EDevent f_EDevent_binary. 
		SEX_cat f_SEX_cat. 
		PAY_cat f_PAY_cat.
		PL_NCHS_cat f_PL_NCHS_cat.
		RACE_cat f_RACE_cat.
		ZIPINC_cat f_ZIPINC_cat.
		HOSP_REGION_cat f_HOSP_REGION_cat.;
	strata 
		NEDS_STRATUM;
	weight 
		DISCWT;
	title "Descriptive Statistics - 2021 Domain Case Proportions for Descriptive Table";
run; 


* ---- INFERENTIAL STATISTICS SECTION -------------------------------------;

*After descriptive statistics have been assessed, the next section 
	provides inferential statistics. Logistic regression was selected
	as the appropriate test due to multiple levels for each variable.
	With a Chi Square approach, each level of the variable is compared
	to each level of the comparison variable. Some variables have 4 or 
	more levels in which differences would be separately assessed, 
	which would greatly reduce the power of the test. However, the 
	odds ratio calculation provided by crosstabulation tables is a
	useful reference to compare to the OR of the logistic regression
	models. It can help confirm that you have the groups ordered 
	correctly (reading A:B versus B:A) when describing results!; 


*--------- LOGISTIC REGRESSION MODELS ---------------------------;

* ---- Log Reg Model 1: Among Dental & Low Back Pain Domain --------;
proc surveylogistic 
	varmethod=TAYLOR
	data=
		mylib.thesis_2021_data;
	class 		
		AGE_cat (REF='Age 65+ years (ref)')
		SEX_cat (REF='Female (ref)')
		PAY_cat (REF='Private Insurance (ref)')
		PL_NCHS_cat (REF='Urban (ref)')
		RACE_cat (REF='White, non-hispanic (ref)')
		ZIPINC_cat (REF='Fourth Income Quartile (2021 $88,000+) (ref)');
	domain 
		DOMAIN_MUS;
	model 
		DEN002_cat 
			(EVENT='Visits for Nontraumatic Dental') = 
				AGE_cat
				Sex_cat
				PAY_cat
				PL_NCHS_cat
				RACE_cat
				ZIPINC_cat;
	format
		DOMAIN_MUS f_DOMAIN_M.
		DEN002_cat f_DEN002_cat.
		AGE_cat f_AGE_cat.
		SEX_cat f_SEX_cat. 
		PAY_cat f_PAY_cat.
		PL_NCHS_cat f_PL_NCHS_cat.
		RACE_cat f_RACE_cat.
		ZIPINC_cat f_ZIPINC_cat.;
	strata 
		NEDS_STRATUM;
	weight 
		DISCWT;
	title "Inferential - Model 1: Dental & Low back pain population";
run;

* ---- Log Reg Model 2: Among Dental & Headache Domain --------;

proc surveylogistic 
	varmethod=TAYLOR
	data=
		mylib.thesis_2021_data;
	class 		
		AGE_cat (REF='Age 65+ years (ref)')
		SEX_cat (REF='Female (ref)')
		PAY_cat (REF='Private Insurance (ref)')
		PL_NCHS_cat (REF='Urban (ref)')
		RACE_cat (REF='White, non-hispanic (ref)')
		ZIPINC_cat (REF='Fourth Income Quartile (2021 $88,000+) (ref)');
	domain 
		DOMAIN_NVS;
	model 
		DEN002_cat 
			(EVENT='Visits for Nontraumatic Dental') = 
				AGE_cat
				SEX_cat
				PAY_cat
				PL_NCHS_cat
				RACE_cat
				ZIPINC_cat;
	format
		DOMAIN_NVS f_DOMAIN_N.
		DEN002_cat f_DEN002_cat.
		AGE_cat f_AGE_cat.
		SEX_cat f_SEX_cat. 
		PAY_cat f_PAY_cat.
		PL_NCHS_cat f_PL_NCHS_cat.
		RACE_cat f_RACE_cat.
		ZIPINC_cat f_ZIPINC_cat.;
	strata 
		NEDS_STRATUM;
	weight 
		DISCWT;
	title "Inferential - Model 2: Dental & Headache population";
run;


*This line of ODS code bookends the output that is saved to pdf, and also turns off 
	grapic output. This can be placed at the end of your program code, or ODS can be 
	placed around certain sections to show only select output as desired.;
ods pdf close;
ods graphics off;

