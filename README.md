# NOAA-migration
Working repository to look at the effects of natural disasters on internal migration rates across the United States from the early 1990s to mid 2010s.

TO BE UPDATED.

One bit of note, it would be helpful to have a consistent style for the code. Object names should be nouns while functions should be verbs. The names should adhere to [snake_case](https://en.wikipedia.org/wiki/Snake_case). In general, we should follow Hadley Wickham's [Style guide](http://adv-r.had.co.nz/Style.html) from his [Advanced R](http://adv-r.had.co.nz/) text. Hadley also has a great new book titled [R for Data Science](http://r4ds.had.co.nz/) plus if we end up developing any packages related to this repository then [R packages](http://r-pkgs.had.co.nz/) is another great resource from Hadley.

## Organization:

The main theme behind this repository is to have an easy to access data-source that can be easily accessed for multiple projects. The `Project` is the identifier for various ideas, research interests, modeling exercises, etc. As this becomes more populated with Projects, I will give a short description for each.

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
* 1-Organization/
    * `1-Project_Tidy.R` - script to gather particular data
    * Project/
        * Properly formatted and gathered data for further analysis. If files are over 100 mb, [GitHub will reject the push](http://stackoverflow.com/questions/17382375/github-file-size-limit-changed-6-18-13-cant-push-now). __So Do Not Push Files Above 100MB__
    * `1-Project_functions.R` - any relevant functions for tidying of a project's data.
* 2-Exploratory/
    * `2-Project_Explore.R` - summary statistics, histograms, plots, maps, etc.
    * Project/
        * Various plots, figures, tables, and maps saved. Not all are valuable or finished.
* 3-Basic_Modeling/
    * `3-Project_Basic_XXX.R` - basically OLS type of analysis to see what the data are doing.
    * Project/
        * Saved results, although some of these may never be of use for the final product.
* 4-Advanced_Modeling/
    * `4-Project_Advanced_XXX.R` - a more complex, and hopefully complete, way of modeling the data for the particular project.
    * Project/
        * Various ideas for solving the problem of interest.
* 5-Results/
    * `5-Project_Results.R` - the output to be used for said project.
    * Project/
        * Finished results.

## Packages Needed
The packages used in this repository so far include: `cleangeo`, `dplyr`, `gdata`, `lubridate`, `maptools`, `RCurl`, `readr`, `readxl`, `rgdal`, `rvest`, `stringr`, and `tidyr`. All of these are available on [CRAN](https://cran.r-project.org/) and can be installed using `install.packages()`.

# Various To-Do Items:

This is still currently a work in progress. At the moment, here are a few things I know that I will eventually need to tackle:

1. Hosting various datasets (FCC data, various shapefiles, etc.) on a site so that R scripts are automated.
2. Delve into the BEA API and sort through their various data. Document this as well.
3. Convert Matlab code (for origin-destination models) to R scripts.
