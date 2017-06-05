#Robert Dinterman


# ---- 0-IRS_Mig.R --------------------------------------------------------

#Problem for excel files with "us" from 1998.99 until 2001.2
read_excel1 <- function(file){
  require(readxl)
  dat   <- read_excel(file)
  dat   <- dat[, c(1:9)]
  #dat   <- dat[c(8:nrow(dat)), c(1:9)]
  return(dat)
}
read_excel2 <- function(file){
  require(gdata)
  dat   <- read.xls(file)
  dat   <- dat[c(4:nrow(dat)), c(1:9)]
  return(dat)
}
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

read_data1 <- function(j5i, namesi, inflow = T){
  require(readxl)
  require(gdata)
  indata <- sapply(j5i, function(x){
    dat <- tryCatch(read_excel1(x), error = function(e){
      read_excel2(x)
    })
    
    dat[,c(1:4,7:9)] <- lapply(dat[,c(1:4,7:9)],
                                function(xx){ # Sometimes characters in values
                                  as.numeric(
                                    gsub(",", "", 
                                         gsub("[A-z]", "", xx)))
                                })
    dat[,c(5:6)]     <- lapply(dat[,c(5:6)], function(xx) toupper(xx) )
    names(dat)       <- namesi
    
    if (inflow) {
      dat           <- filter(dat, !is.na(st_fips_d))
      dat$st_fips_d <- Mode(dat$st_fips_d)
    } else {
      dat           <- filter(dat, !is.na(st_fips_o))
      dat$st_fips_o <- Mode(dat$st_fips_o)
    }
    
    
    dat$ofips <- dat$st_fips_o*1000 + dat$cty_fips_o
    dat$dfips <- dat$st_fips_d*1000   + dat$cty_fips_d
    dat
  }, simplify = F, USE.NAMES = T)
  indata      <- bind_rows(indata)
  indata$year <- as.numeric(substr(basename(i), 1, 4))
  return(indata)
}


# ---- 0-IRS_Pop.R --------------------------------------------------------


# Download files using RCurl (because of https issues)
bdown <- function(url, folder){
  require(RCurl, quietly = T)
  file <- paste(folder, basename(url), sep = "/")
  
  if (!file.exists(file)){
    f <- CFILE(file, mode = "wb")
    a <- curlPerform(url = url, writedata = f@ref, noprogress = FALSE)
    close(f)
    return(a)
  } else print("File Already Exists!")
}

zipdata <- function(file, tempDir, year){
  unlink(tempDir, recursive = T)
  
  unzip(file, exdir = tempDir)
  file       <- list.files(tempDir, pattern = "\\.txt$", full.names = T)
  rdata      <- read_csv(file)
  
  names(rdata) <- tolower(names(rdata))
  rdata$year   <- year
  
  return(rdata)
}

#Problem for excel files with "us" from 1998.99 until 2001.2
read_pop1 <- function(file){
  require(readxl, quietly = T)
  coln   <- c("st_fips", "cty_fips", "county_name", "return", "exmpt",
              "agi", "wages", "dividends", "interest")
  
  # Alaska in 97 is missing a column and MA 2001 is F-d
  probs <- c("ALASKA97ci.xls", "Kentucky01ci.xls", "MASSACHUSETTS01ci.xls")
  if (!(basename(file) %in% probs)){
    dat    <- read_excel(file)
    
    check1 <- grep("code", dat[, 1], ignore.case = T)
    check2 <- grep("code", dat[, 2], ignore.case = T)
    
    if (is.na(check1[1])) dat <- dat[c((check2[1] + 1):nrow(dat)), c(2:10)]
    else                  dat <- dat[c((check1[1] + 1):nrow(dat)), c(1:9)]
    
    ind        <- apply(dat, 1, function(x) all(is.na(x)))
    dat        <- dat[ !ind, ]
    names(dat) <- coln
  } else if (basename(file) == probs[1]){ #for Alaska 97
    dat        <- read_excel(file)
    check1     <- grep("code", dat[, 1], ignore.case = T)
    dat        <- cbind(dat[c((check1[1] + 1):nrow(dat)), c(1:2)], NA,
                        dat[c((check1[1] + 1):nrow(dat)), c(3:8)])
    ind        <- apply(dat, 1, function(x) all(is.na(x)))
    dat        <- dat[!ind, ]
    names(dat) <- coln
    dat$county_name <- "AK Replace"
  } else if (basename(file) == probs[2]){ #for KY 01
    dat         <- read_excel(file)
    check1      <- grep("code", dat[, 1], ignore.case = T)
    dat1        <- dat[c((check1[1] + 1)), c(1:9)]
    dat2        <- dat[c((check1[1] + 2):nrow(dat)), c(1:9)]
    names(dat1) <- names(dat2) <- coln
    
    # Correct:
    dat1$interest  <- as.character(sum(as.numeric(dat2$interest)))
    
    dat         <- bind_rows(dat1, dat2)
    
    ind         <- apply(dat, 1, function(x) all(is.na(x)))
    dat         <- dat[ !ind, ]
  } else if (basename(file) == probs[3]){ #for MA 01
    dat         <- read_excel(file)
    check1      <- grep("code", dat[, 1], ignore.case = T)
    dat1        <- dat[c((check1[1] + 1)), c(1:9)]
    dat2        <- dat[c((check1[1] + 2):nrow(dat)), c(1:9)]
    names(dat1) <- names(dat2) <- coln
    
    # Correct:
    dat1$county_name <- "Total"
    dat1$return      <- as.character(sum(as.numeric(dat2$return)))
    
    dat <- bind_rows(dat1, dat2)
    
    ind <- apply(dat, 1, function(x) all(is.na(x)))
    dat <- dat[!ind, ] 
  }
  return(dat)
}

read_pop2 <- function(file){
  require(gdata)
  
  coln       <- c("st_fips", "cty_fips", "county_name", "return", "exmpt",
                  "agi", "wages", "dividends", "interest")
  dat        <- read.xls(file)
  dat        <- dat[c(5:nrow(dat)), c(1:9)]
  ind        <- apply(dat, 1, function(x) all(is.na(x)))
  dat        <- dat[ !ind, ]
  names(dat) <- coln
  return(dat)
}


# Function for fips issues ------------------------------------------------


fipssues <- function(dat, fip, fiplace){
  require(magrittr)
  
  correct <- dat %>%
    filter(fips %in% fiplace) %>%
    group_by(year) %>%
    summarise_each(funs(sum), -fips)
  correct$fips <- fip
  dat <- dat %>%
    filter(!(fips %in% fiplace)) %>%
    bind_rows(correct)
  
  return(dat)
}

fipssuesmean <- function(dat, fip, fiplace){
  require(magrittr)
  
  correct <- dat %>%
    filter(fips %in% fiplace) %>%
    group_by(year) %>%
    summarise_each(funs(sum), -fips)
  correct$fips <- fip
  dat <- dat %>%
    filter(!(fips %in% fiplace)) %>%
    bind_rows(correct)
  
  return(dat)
}

fipssuespov <- function(dat, fip, fiplace){
  require(magrittr)
  
  correct <- dat %>%
    filter(fips %in% fiplace) %>%
    group_by(year) %>%
    summarise(POV_ALL    = sum(POV_ALL, na.rm = T),
              POV_ALL_P  = mean(POV_ALL_P, na.rm = T),
              POV_0.17   = sum(POV_0.17, na.rm = T),
              POV_0.17_P = mean(POV_0.17_P, na.rm = T),
              POV_5.17   = sum(POV_5.17, na.rm = T),
              POV_5.17_P = mean(POV_5.17_P, na.rm = T),
              MEDHHINC   = mean(MEDHHINC, na.rm = T),
              POP_POV    = sum(POP_POV, na.rm = T))
  correct$fips <- fip
  dat <- dat %>%
    filter(!(fips %in% fiplace)) %>%
    bind_rows(correct)
  
  return(dat)
}

# Function for fips issues for CBP
fipssues1 <- function(dat, fip, fiplace){
  require(magrittr)
  
  correct <- dat %>%
    filter(fips %in% fiplace) %>%
    group_by(year, sic, naics) %>%
    summarise_each(funs(sum), -fips, -empflag)
  correct$fips <- fip
  dat <- dat %>%
    filter(!(fips %in% fiplace)) %>%
    bind_rows(correct)
  
  return(dat)
}

fipssues2 <- function(dat, fip, fiplace){
  require(magrittr)
  
  correct <- dat %>%
    filter(fips %in% fiplace) %>%
    group_by(year, naics) %>%
    summarise_each(funs(sum), -fips, -empflag, -(emp_nf:ap_nf))
  correct$fips <- fip
  dat <- dat %>%
    filter(!(fips %in% fiplace)) %>%
    bind_rows(correct)
  
  return(dat)
}