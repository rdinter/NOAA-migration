# Notes on IRS Data


## Notes for 0-IRS_Pop_ZIP

### [SOI Tax Stats - Individual Income Tax Statistics - ZIP Code Data (SOI)](https://www.irs.gov/uac/soi-tax-stats-individual-income-tax-statistics-zip-code-data-soi)

The IRS has released ZIP code level data on tax returns, which is great. The years cover [1998](#1998), [2001](#2001), [2002](#2002), and [2004](#2004) to [2013](#2013). All of these will include returns, exemptions, AGI, salaries and wages, taxable interest, earned income credit, total tax, "Schedule C" (non-farm sole proprietorship), "Schedule F" (farm sole proprietorship), and Schedule A Deductions." The files up until 2005 are in .xls format, then from 2005 and beyond they are .csv. In addition, all years are stratified by AGI classes but the IRS has slowly added new AGI classes and so comparability is limited. Here is a quick rundown of the contents of the .zip files for each year:

### 1998
All states are in .xls files plus an additional "98zp53us.xls" which contains state totals and US totals.

AGI: < $10,000; $10,000 to $25,000; $25,000 to $50,000; > $50,000

Data start on row 9, then it is "Total" followed by AGI classes and a skipped row.

There are 19 columns: 

1.  name
2.  returns
3.  exemptions (total)
4.  dependent exemptions
5.  AGI
6.  number of returns for salaries/wages
7.  amount of salaries/wages
8.  number of returns with taxable interest
9.  taxable interest amount
10. number of returns with earned income credit
11. amount of earned income credit
12. number of returns with tax
13. total tax amount
14. number of returns for schedule C
15. number of schedule Cs claimed
16. number of returns for schedule F
17. number of schedule Fs claimed
18. number of returns with schedule A
19. amount of schedule A deductions

Special notes

> \* Upper cell and/or lower cell value(s) have been added into this cell.  
> \** Value removed from this cell is added into upper or lower cell.  
> \- Cell values are zero.  
> State totals do not include deleted Zipcode totals.

### 2001
All states are in .xls files plus an additional "01zp53us.xls" which contains state totals and US totals.

AGI: < $10,000; $10,000 to $25,000; $25,000 to $50,000; > $50,000

Data start on row 9, then it is "Total" followed by AGI classes and a skipped row.

There are 19 columns: 

1.  name
2.  returns
3.  exemptions (total)
4.  dependent exemptions
5.  AGI
6.  number of returns for salaries/wages
7.  amount of salaries/wages
8.  number of returns with taxable interest
9.  taxable interest amount
10. number of returns with tax
11. total tax amount
12. number of returns for schedule C
13. number of returns for schedule F
14. number of returns with schedule A

> \* Upper cell and/or lower cell value(s) have been added into this cell.
> \** Value removed from this cell is added into upper or lower cell.
> 0 or - Cell values are zero.
> State totals do not include deleted Zipcode totals.
> Adjusted Gross Income size of "Under $10,000" includes adjusted gross deficits.
> Source: IRS Master File Data, Statistics of Income, October 2003.

### 2002
Same as 2001.

### 2004
All states are in .xls files, there is no total file for states/US.

AGI: < $10,000; $10,000 to $25,000; $25,000 to $50,000; $50,000 to $75,000; $75,000 to $100,000; > $100,000

Data start on row 13, then it is "Total" followed by AGI classes and a skipped row.

There are 39 columns:

1.  name
2.  returns
3.  exemptions (total)
4.  dependent exemptions
5.  AGI
6.  number of returns for salaries/wages
7.  amount of salaries/wages
8.  number of returns with taxable interest
9.  taxable interest amount
10. number of returns with taxable dividends
11. amount of earned taxable dividends
12. number of returns with net capital gain/loss
13. amount of net capital gain/loss
14. number of returns for schedule C
15. amount of schedule Cs net profit/loss
16. number of returns for schedule F
17. number of schedule Fs net profit/loss
18. number of returns with IRA payment deduction
19. amount of IRA payment deduction
20. number of Self-employment Pension Deduction
21. amount of Self-employment Pension Deduction
22. number of total itemized deductions
23. AGI of total itemized deductions
24. amount of total itemized deductions
25. number of contributions deductions
26. AGI of contributions deductions
27. amount of contributions deductions
28. number of taxes paid deductions
29. AGI of taxes paid deductions
30. amount of taxes paid deductions
31. number of alternative minimum tax
32. amount of alternative minimum tax
33. number of income tax before credits
34. amount of income tax before credits
35. number of total tax returns
36. amount of total tax
37. number of earned income credit
38. amount of earned income credit
39. number of paid preparer returns

It appears that only \* is a special character on this set of data.

### 2005
Finally, we have .csv files! There is also a file of .xls files but only need the `zipcode05.csv` to read in. 

AGI classes: 1 = Under $10,000; 2 = $10,000 under $25,000; 3 = $25,000 under $50,000; 4 = $50,000 under $75,000; 5 = $75,000 under $100,000; 6 = $100,000 or more.

Here are the variables:

1.  state, 2 letter state abbreviation	
2.  agi_class
3.  zipcode, 5-digit zipcode	
4.  n1, Number of returns
5.  n2, Number of exemptions Total
6.  n6, Dependent Exemptions
7.  a00100, Adjusted Gross Income
8.  n00200, Salaries and Wages, Number of returns
9.  a00200, Amount
10. n00300, Taxable Interest, Number of returns
11. a00300, Amount
12. n00600, Taxable Dividends, Number of returns
13. a00600, Amount
14. n01000, Net Capital Gain/Loss, Number of returns
15. a01000, Amount
16. n00900, Schedule C Net Profit/Loss, Number of returns
17. a00900, Amount
18. n02100, Schedule F Net Profit/Loss, Number of returns
19. a02100, Amount
20. n03150, IRA Payment Deduction, Number of returns
21. a03150, Amount
22. n03300, Self-employed Pension Deduction, Number of returns
23. a03300, Amount
24. n21060, Total Itemized Deductions, Number of returns
25. agi_04470, Adjusted gross income
26. a21060, Amount
27. n19700, Contributions Deductions, Number of returns
28. agi_19700, Adjusted gross income
29. a19700, Amount
30. n18300, Taxes Paid Deductions, Number of returns
31. agi_18300, Adjusted gross income
32. a18300, Amount
33. n09600, Alternative Minimum Tax, Number of returns
34. a09600, Amount
35. n05800, Income Tax Before Credits, Number of returns
36. a05800, Amount
37. n09200, Total Tax, Number of returns
38. a09200, Amount
39. n11000, Earned Income Credit, Number of returns
40. a11000, Amount
41. PREP, Number of returns using a Paid Preparer

### 2006
Same as 2005, except new AGI classes are added: $100,000 to $200,000; and > $200,000

### 2007
Things change again. Still as a .csv

Variables are now: 

state ZIPCODE agi_class n1 mars2 prep n2 numdep a00100 n00200 a00200 n00300 a00300 n00600 a00600 n00900 a00900 schf n23900 a23900 n01400 a01400 n01700 a01700 n02300 a02300 n02500 a02500 n03300 a03300 n04470 a04470 n18425 a18425 n18450 a18450 n18500 a18500 n18300 a18300 n19300 a19300 n19700 a19700 n04800 a04800 n07100 a07100 nf5695 af5695 n07220 a07220 n07180 a07180 n59660 a59660 n59720 a59720 n09600 a09600 n06500 a06500 n10300 a10300 n11900gt0 a11900gt0 n11900lt0 a11900lt0

mars2 - filing status is married filing jointly; prep - paid preparer outside IRS; numdep - n6, dependent exemptions

### 2008
Need to go into the folder `2008ZIPCode/` to then find the .csv file. Variables all appear in 2007, although some are missing:

state ZIPCODE agi_class n1 mars2 prep n2 numdep a00100 a00200 a00300 a00600 a00900 a23900 a01400 a01700 a02300 a02500 a03300 a04470 a18425 a18450 a18500 a18300 a19300 a19700 a04800 a07100 af5695 a07220 a07180 a59660 a59720 a09600 a06500 a10300 a11900gt0 a11900lt0

### 2009
Now there are two .csv files, one with AGI sub-classes and another without them (totals). The disclosure problem increased from 10 returns to 20.

The variables all appear to be the same though:

STATEFIPS STATE ZIPCODE AGI_STUB N1 MARS2 PREP N2 NUMDEP A00100 N00200 A00200 N00300 A00300 N00600 A00600 N00650 A00650 N00900 A00900 SCHF N01000 A01000 N01400 A01400 N01700 A01700 N02300 A02300 N02500 A02500 N03300 A03300 N04470 A04470 N18425 A18425 N18450 A18450 N18500 A18500 N18300 A18300 N19300 A19300 N19700 A19700 N04800 A04800 N07100 A07100 N07220 A07220 N07180 A07180 N07260 A07260 N59660 A59660 N59720 A59720 N11070 A11070 N09600 A09600 N06500 A06500 N10300 A10300 N11901 A11901 N11902 A11902

### 2010
Appears to be the same as 2009:

STATEFIPS STATE ZIPCODE AGI_STUB N1 MARS2 PREP N2 NUMDEP A00100 N00200 A00200 N00300 A00300 N00600 A00600 N00650 A00650 N00900 A00900 SCHF N01000 A01000 N01400 A01400 N01700 A01700 N02300 A02300 N02500 A02500 N03300 A03300 N04470 A04470 N18425 A18425 N18450 A18450 N18500 A18500 N18300 A18300 N19300 A19300 N19700 A19700 N04800 A04800 N07100 A07100 N07220 A07220 N07180 A07180 N07260 A07260 N59660 A59660 N59720 A59720 N11070 A11070 N09600 A09600 N06500 A06500 N10300 A10300 N11901 A11901 N11902 A11902

### 2011
These are .csv files that have been loaded in already.

### 2012
Same as 2011.

### 2013
Same as 2011 and 2012.
