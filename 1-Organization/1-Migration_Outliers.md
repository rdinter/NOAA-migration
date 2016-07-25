Detecting Outliers for Net Migration
====================================

The IRS data currently spans across 1992 to 2013 for a total of 68984 observations. There were substantial changes in data formatting and collecting across this time. As such, there are likely some data problems like clerical errors in reporting values or misclassifications in FIPS codes, etc. This is meant to be a quick and dirty way of detecting outliers in the data.

The process for detecting an outlier used here is to group the in-migration data for each county across the years (on average 22 years for each) and calculate the following:

\[ | X_i - median(X_{-i}) | > 7*sd(X_{-i}) \]

Values for which the above is true are flagged as potential outliers as this indicates the observation is approximately a seven sigma event (p-value of approximately 2.6e-12) and in expectation we should see one in 5663374 migration datasets if each county follows an independent normal distribution. This is only meant as a quick and dirty way of detecting outliers, but there are a total of 36 flagged FIPS-year combinations:

|  year|   fips|  return\_in|  mean\_in|  sd\_in|  flag\_factor|
|-----:|------:|-----------:|---------:|-------:|-------------:|
|  1992|  51840|        3926|      1354|     628|             3|
|  1994|  13125|         476|        90|      90|             5|
|  1994|  42031|        1176|       677|     122|             2|
|  1994|  42121|        2519|       892|     367|             3|
|  1995|  13087|        3743|       705|     696|             5|
|  1996|  13261|        1000|       615|     100|             2|
|  1998|  16015|         589|       265|      82|             2|
|  2003|  17017|      245211|     11446|   52212|            21|
|  2005|  22051|       16202|     10840|    1444|             1|
|  2005|  22095|        2002|      1058|     254|             2|
|  2005|  22103|        9086|      5602|     865|             2|
|  2005|  28109|        2143|      1111|     259|             2|
|  2005|  48099|        6137|      3869|     562|             2|
|  2006|  17161|        3904|      2889|     262|             1|
|  2007|  21051|         367|       220|      37|             2|
|  2010|  13287|         541|       216|      87|             3|
|  2011|   1011|         347|       180|      43|             2|
|  2011|  12073|       11279|      8043|     835|             1|
|  2011|  18123|         551|       328|      55|             2|
|  2011|  20029|        3061|       357|     604|             9|
|  2011|  20089|        1326|       129|     268|            10|
|  2011|  20137|         200|       124|      19|             2|
|  2011|  20157|        2104|       196|     426|            11|
|  2011|  20183|        1532|       141|     311|            11|
|  2011|  21077|         530|       240|      74|             2|
|  2011|  28065|         429|       247|      47|             2|
|  2011|  28103|         290|       163|      33|             2|
|  2011|  29157|         512|       353|      41|             1|
|  2011|  31149|         128|        37|      21|             3|
|  2011|  36025|        1478|       967|     132|             2|
|  2011|  36049|        1291|       471|     189|             3|
|  2011|  42015|        1405|       974|     114|             1|
|  2011|  42115|        1363|       819|     128|             2|
|  2011|  47061|         581|       227|      82|             3|
|  2011|  47067|         225|        95|      31|             2|
|  2013|  48453|      109131|     37774|   18433|             3|

The column `flag_factor` is the flagged in-migration value for the county-year divided by the mean of in-migration for that county. The higher the value, the more unlikely the event.
