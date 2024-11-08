* Importing the data set csv file into SAS;
proc import out=marks
datafile="/home/u63607157/Student_Marks.csv"
dbms=csv
replace;
getnames=YES;
run;

* Splitting the data set 70/30 for building and validation purposes;
proc surveyselect data=marks rate=0.7 outall out=marks2 seed=1234;
run;

data marks_build marks_val; 
set marks2; 
if selected =1 then output marks_build; 
else output marks_val; 
drop selected;
run;

proc contents data=marks_build;

* Generating the scatter plot matrix;
proc sgscatter data=marks_build;
matrix Marks number_courses time_study;
run;

* Generating the correlation matrix for the x variables;
proc corr data=marks_build;
var Marks number_courses time_study;
run;

* Best subset by adjusted R2;
proc reg data=marks_build;
model Marks=number_courses time_study / selection=adjrsp;
run;

* Forward stepwise regression;
proc reg data=marks_build;
model Marks=number_courses time_study / selection=stepwise slentry=0.05 slstay=0.10;
run;

* Fitting the full model;
proc reg data=marks_build plots(unpack)=diagnostics;
model Marks=number_courses time_study / partial;
run;

* Applying a transformation to the data to account for nonlinearity;
data transformed_build;
SET marks_build;
x2=time_study**2;
x3=number_courses*x2;
run;

data transformed_val;
SET marks_val;
x2=time_study**2;
x3=number_courses*x2;
y_hat=0.39470 + 1.73480*number_courses + 0.66993*x2;
error=Marks-y_hat;
error2=error**2;
run;

* Generating the scatter plot matrix;
proc sgscatter data=transformed_build;
matrix Marks number_courses x2;
run;

* Generating the correlation matrix for the x variables;
proc corr data=transformed_build;
var Marks number_courses x2;
run;

* Best subset by adjusted R2;
proc reg data=transformed_build;
model Marks=number_courses x2 / selection=adjrsp;
run;

* Forward stepwise regression;
proc reg data=transformed_build;
model Marks=number_courses x2 / selection=stepwise slentry=0.05 slstay=0.10;
run;

* Checking for interaction term;
proc reg data=transformed_build;
model Marks=number_courses x2 x3 / partial;
test x3=0;
run;

* Checking the partial regression plots;
proc reg data=transformed_build plots(unpack)=diagnostics;
model Marks=number_courses x2 / partial;
run;

* Checking VIF for multicollinearity;
proc reg data=transformed_build;
model Marks=number_courses x2 / vif;
run;

* Influence statistics: DFFITS and DFBETAS;
proc reg data=transformed_build;
model Marks=number_courses x2 / influence;
run;

* Influence statistics: Cook's distance;
proc reg data=transformed_build plot=diagnostics(unpack label);
model Marks=number_courses x2;
output out=ck cookd=cooks_distance;
run;
proc print data=ck;
run;

* Testing on validation set;
proc reg data=transformed_val;
model Marks=number_courses x2;
run;

* Finding the MSPR;
proc means data=transformed_val;
var error2;
run;