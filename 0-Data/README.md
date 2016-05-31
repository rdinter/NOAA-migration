# 0-Data

* 0-Data/
    * `0-Data_Source.R` - script to download data and create `.csv` and `.Rda` files in an easy to read and uniform format.
    * Data_Source/ - most of this will be ignored via `.gitignore`.
        * raw/
            * All downloaded files from the `0-Data_Source.R` script.
            * Some data cannot be downloaded and must be hosted elsewhere. They will also be in this folder for local use.
        * `Various_Names.csv`
        * `Various_Names.Rda`
    * `0-functions.R` - relevant functions for this sub-directory.
    * `.gitignore` - any large files will not be loaded to GitHub.

## Data Collected:

So far, the data sources that have been collected here range only involve the IRS, NOAA, and Shapefiles. These are not yet comprehensive though:

* `IRS` - [Internal Revenue Service](http://www.irs.gov/uac/SOI-Tax-Stats-County-Data)- county data. From 1989 to 2013 data on population, households, AGI, Wages, Dividends, and Interest at the county level through IRS return data. Further, there are migration county-to-county data available from 1992 to 2013 which includes flows of population, households, and AGI.
* `NOAA` - [National Oceanic and Atmospheric Administration](https://www.ncdc.noaa.gov/stormevents/ftp.jsp) - Storm Events Database which documents property damage and deaths due to storms at the county level going back to 1950.
* `Shapefiles` - ArcGIS from NC State library: ZCTA shapefile from 2004. Also a county shapefile from the national atlas.


## To Do list:

There is another [GitHub repository](https://github.com/rdinter/test-counties/tree/master/0-Data) that I have which houses various other data sources which involve various Census Bureau and other government data sources: ACS, CBP, CPI, ERS, FCC, Census Bureau, LAU, Poverty. Eventually, we should update the R scripts and integrate them to the repository.

Here is a very general list of county level data sources which I have yet to find or need to upload/host somewhere:

1. IRS data for Population at County and ZIP level can include information on AGI stub, which is a stratified sample based on income level. This should be updated. These are from 2010 and onward.
    * `noagi.csv` versus `agi.csv` are the relevant files.
    * Also applies to the migration data.
2. Wage rate
3. Education
4. NORSIS, locally stored.
5. Home Prices? Zillow or Trulia are possible but not complete for US.
6. BEA - GDP - this utilizes an API and is a work in progress.
7. Housing Permits, locally stored.
8. Govt / Tax Rates ? http://www.census.gov/govs/ ? extend the Census of Governments for 2007 and 2012.
9. Regional Price Index, unsure of existence.
10. [Commuting Zone Data](http://www.ers.usda.gov/data-products/commuting-zones-and-labor-market-areas.aspx)
    * Also the [PIZA Measures](http://www.ers.usda.gov/data-products/population-interaction-zones-for-agriculture-(piza).aspx) - population interaction zones for agriculture.
11. Extend [FCC data](http://www2.ntia.doc.gov/broadband-data) beyond 2013. Should be an API somewhere.
12. [0-Crime-JSON.R](https://github.com/maliabadi/ucr-json) I am unsure how to classify this at the moment...
13. [IRS ZIP Code data](https://www.irs.gov/uac/SOI-Tax-Stats-Individual-Income-Tax-Statistics-ZIP-Code-Data-(SOI)) from 1998 to 2013 but the data structures are all different. Files are in .xls class and by State. Lots of suppression issues, this may take some time to sort out.
14. `MSA` - [Metropolitan Statistical Area](http://www.nber.org/data/cbsa-msa-fips-ssa-county-crosswalk.html) - needs work.
15. `QCEW` - [Quarterly Census of Employment and Wages](http://www.bls.gov/cew/datatoc.htm) - needs an update to dplyr!
16. [ACS data](https://www.census.gov/hhes/migration/data/acs/county_to_county_mig_2007_to_2011.html) has a [Public Use Microdata Survey](https://www.census.gov/programs-surveys/acs/technical-documentation/pums.html) is an area I need to look into for the migration data. The [2012 5 year stats](http://www2.census.gov/acs2012_5yr/pums/) are available and appear to be in a SQL-like format?