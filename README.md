# NOAA-migration
Working repository to look at the effects of natural disasters on internal migration rates across the United States from the early 1990s to mid 2010s.

As a short note, it is helpful to have a consistent style for the code. Object names should be nouns while functions should be verbs. The names should adhere to [snake_case](https://en.wikipedia.org/wiki/Snake_case). In general, we should follow Hadley Wickham's [Style guide](http://adv-r.had.co.nz/Style.html) from his [Advanced R](http://adv-r.had.co.nz/) text. Hadley also has a great new book titled [R for Data Science](http://r4ds.had.co.nz/) plus if we end up developing any packages related to this repository then [R packages](http://r-pkgs.had.co.nz/) is another great resource from Hadley.

## To Do:

1. Revamp the IRS code for downloading and parsing through the county to county migration data.
2. Create scripts for finding the [random](https://github.com/rdinter/NOAA-migration/tree/master/0-data/random) folder data.
3. Create variables to control for hurricane propensity across the US. This also involves different distance functions.
4. Estimation of a censored or truncated regression.

## Organization:

* 0-data/
    * `0-data_source.R` - script to download data and create `.csv` and `.rds` files in an easy to read and uniform format.
    * `0-functions.R` - relevant functions for this sub-directory.
    * `.gitignore` - any large files will not be loaded to GitHub.
    * Data_Source/ 
        * `various_names.csv` - usable files
        * `various_names.rds` - usable files
        * raw/ - most of this will be ignored via `.gitignore`.
            * All downloaded files from the `0-data_source.R` script.
            * Some data cannot be downloaded and must be hosted elsewhere. They will also be in this folder for local use.
* 1-tidy/
    * `1-project_tidy.R` - script to gather particular data
    * `1-project_functions.R` - any relevant functions for tidying of a project's data.
    * Project/
        * Properly formatted and gathered data for further analysis. If files are over 100 mb, [GitHub will reject the push](http://stackoverflow.com/questions/17382375/github-file-size-limit-changed-6-18-13-cant-push-now). __So Do Not Push Files Above 100MB__
* 2-eda/
    * `2-project_eda.R` - summary statistics, histograms, plots, maps, etc.
    * Project/
        * Various plots, figures, tables, and maps saved. Not all are valuable or finished.
* 3-basic/
    * `3-project_basic.R` - basically OLS type of analysis to see what the data are doing.
    * Project/
        * Saved results, although some of these may never be of use for the final product.
* 4-advanced/
    * `4-project_advanced.R` - a more complex, and hopefully complete, way of modeling the data for the particular project.
    * Project/
        * Various ideas for solving the problem of interest.
* 5-writing/
    * `5-paper.Rmd` - an RMarkdown file which is used to compile the writing and results. It will also reference the associated R file which processes the analysis, the bibliography, and any other templates.
    * `5-paper.R` - the output to be used for said project.
    * `paper.bib` - a bibtex document for proper references
    * Project/
        * Finished results.
* 6-presentations/
    * Venue/
        * `6-presentation.Rmd` - RMarkdown file which produces the beamer or ioslides for the presentation.
        * `6-presentation.R` - R code which helps produce figures and tables used in the presetnation.
