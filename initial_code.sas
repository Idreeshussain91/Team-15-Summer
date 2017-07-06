/* TO DO

Merge on Cust_ID

Adjuster_technician: Correct Adj_ZIP

Customer_family_medical


Potential questions:

What percentage of customers had claims?
What is distribution of claims?
What percentage had 5% of costs? 10%? etc.
Missing data?

Predictor of death from health-related causes
*/

* set libname;
libname summer 'C:\Users\Charlie\Google Drive\MSA\Summer project';

* format variables for customer_medical;



* examine datasets;
proc contents data = summer._all_ nods;
run;

proc print data =  summer.CUSTOMER_MEDICAL (obs = 5);
run;

 Re-formatting value tiers for reward definitions

*reward amounts;
proc freq data = summer.customer_transactions nlevels;
	tables Reward_A / nocum nopercent;
run;


*reward types
proc freq data = summer.customer_transactions nlevels;
	tables Reward_r / nocum nopercent;
run;

proc print data = summer.customer_transactions (obs = 5);
run;

proc format;
	value RA		100-199 = 'Accidental'
					200-299 = 'Criminal	Acts'
					300-499	= 'Health Related Causes'
					500-549	= 'Dangerous Activity'
					550-559 = 'War'
					560-569 = 'Aviation'
					570-579 = 'Suicide';
run;

proc format;
	value RE		100-199 = 'Accidental'
					200-299 = 'Criminal	Acts'
					300-499	= 'Health Related Causes'
					500-579	= 'RE - Reward Excluded'
					;
run;

proc freq data = summer.customer_transactions;
	format reward_r RA.;
	table reward_r;
run;

proc freq data = summer.customer_transactions;
	format reward_r RE.;
	table reward_r;
run;



* examine variables for individual patient medical history;
proc contents data =  summer.CUSTOMER_MEDICAL;
run;

proc freq data = summer.customer_medical;
	table state / noprint;
run;

*set up dataset for individual patient history with missing values indicated;
title;
data cust_missing;
	set summer.customer_medical;
	if Alcohol in ('Y',"N") then Missing = "Not missing";
	else missing = "Missing";
run;

* (wildly inappropriate) t test for date based on missing variables;
proc ttest data = cust_missing;
	var date;
	class missing;
run;

/* this takes FOREVER to run and ends up looking terrible.  Need a better way to display progression of missing values over time
proc gchart data=cust_missing noprint;
	vbar date / discrete 
	subgroup = missing;
run;
*/

* the next steps sort all medical and payment data;
proc sort data = summer.customer_medical out = customer_medical;
	by Cust_ID;
run;

proc sort data = summer.customer_family_medical out = customer_family_medical;
	by Cust_ID;
run;

proc sort data = summer.customer_transactions out = customer_transactions;
	by cust_ID;
run;

* creates temp dataset with all medical data;
data all_medical;
	merge customer_medical CUSTOMER_FAMILY_MEDICAL;
	by Cust_ID;
run;

* creates temp dataset with medical and payment data;	
data all_medical_and_rewards;
	merge customer_medical CUSTOMER_FAMILY_MEDICAL customer_transactions;
	by Cust_ID;
run;

data all_client_records;
	merge all_medical_and_rewards summer.customer_info;
	by Cust_ID;
run;

/* trying to create a BMI variable - the substring and math works, but it 
throws a massive error when I try to run it as part of creating a new column
data all_client_records;
	set all_client_records;
	a = substr (feetinches, 1,1);
	b = substr (feetinches, 3, 4);
	c = substr (feetinches, 1, length(b)-1);
	BMI = Pounds / (a * 12 + c)**2 * 703;
run;
*/

proc format;
	value BMI_class		low - 20 = 'Underweight'
						20 - 25 = 'Healthy'
						25 - 30 = 'Overweight'
						30 - high = 'Obese';
run;


proc freq data = all_medical_and_rewards nlevels;
	table _all_ / noprint;
run;	

* assesses mean payments for three classes of award; 
proc means data = all_medical_and_rewards;
	format reward_r RE.;
	var reward_a;
	class reward_r;
	where reward_r < 500;
run;

* anova and boxplots for three classes of award - no significant difference between groups;
proc anova data = all_medical_and_rewards PLOTS(MAXPOINTS=NONE);
	format reward_r RE.;
	class reward_r;
	model reward_a = reward_r;
	means reward_r / hovtest = levene;
	where reward_r < 500;
run;

proc glm data = all_medical_and_rewards PLOTS(MAXPOINTS=NONE) plots = all;
	format reward_r RE.;
	class reward_r;
	model reward_a = reward_r;
	means reward_r / hovtest = levene;
	where reward_r < 500;
run;


proc univariate data =  cust_missing;
	var date;
run;

proc format;
	value era	-5450 - -2950 = 'Time 1'
				-2949 - 451  = 'Time 2'
				452 - 2408 = 'Time 3'
				2409 - 4547 = 'Time 4'
				4548 - 7046 = 'Time 5'
				7047 - 9545 = 'Time 6'
				9546 - 12044 = 'Time 7'
				12045 - 14543 = 'Time 8'
				14544 - 17042 = 'Time 9'
				17043 - 19540 = 'Time 10'
				;
run;
		
/* missing data from personal health records - what's driving this increase in missing data over time?

why don't we see the same thing for the family health records?  */
title 'Missing data over time';
proc sgplot data = cust_missing;
	format date era.;
	vbar date /  group=missing stat=sum;
  	xaxis display=(nolabel);
  	yaxis grid  label='Collected data';
 run;
 title;

 * table for data above - column percentage for missing goes up every single year;
 proc freq data = cust_missing;
 	format date era.;
	tables missing * date;
run;

* a first small sampling of looking at relationship between risk factors and cause of death;
proc freq data = all_medical_and_rewards;
 	format reward_r RE.;
	tables 	reward_r * alcohol 
			reward_r * caffeine
			reward_r * alcohol_num;
	where reward_r < 500;
run;

*geocoding using cities = first step toward plotting location of all customers - can't figure out how to get it onto a map;
proc geocode
 method=city /* Geocoding method */
 data=summer.customer_info /* Input address data */
 out=summer.geocoded
 lookup =  SASHELP.ZIPCODE; /* Output data set */
run;

proc contents data = summer.CUSTOMER_INFO;
run;


