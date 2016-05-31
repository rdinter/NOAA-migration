#Robert Dinterman


# ---- 0-IRS_Mig.R --------------------------------------------------------

#Problem for excel files with "us" from 1998.99 until 2001.2
read_excel1 <- function(file){
  require(readxl)
  data   <- read_excel(file)
  data   <- data[, c(1:9)]
  #data   <- data[c(8:nrow(data)), c(1:9)]
  return(data)
}
read_excel2 <- function(file){
  require(gdata)
  data   <- read.xls(file)
  data   <- data[c(4:nrow(data)), c(1:9)]
  return(data)
}
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

read_data1 <- function(j5i, namesi, inflow = T){
  require(readxl)
  require(gdata)
  indata <- sapply(j5i, function(x){
    data <- tryCatch(read_excel1(x), error = function(e){
      read_excel2(x)
    })
    
    data[,c(1:4,7:9)] <- lapply(data[,c(1:4,7:9)],
                                function(xx){ # Sometimes characters in values
                                  as.numeric(
                                    gsub(",", "", 
                                         gsub("[A-z]", "", xx)))
                                })
    data[,c(5:6)]     <- lapply(data[,c(5:6)], function(xx) toupper(xx) )
    names(data)       <- namesi
    
    if (inflow) {
      data              <- filter(data, !is.na(st_fips_d))
      data$st_fips_d <- Mode(data$st_fips_d)
    } else {
      data              <- filter(data, !is.na(st_fips_o))
      data$st_fips_o <- Mode(data$st_fips_o)
    }
    
    
    data$ofips <- data$st_fips_o*1000 + data$cty_fips_o
    data$dfips <- data$st_fips_d*1000   + data$cty_fips_d
    data
  }, simplify = F, USE.NAMES = T)
  indata <- bind_rows(indata)
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
    a <- curlPerform(url = url, writedata = f@ref,
                     noprogress = FALSE)
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
  rdata$year <- year
  
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
    data   <- read_excel(file)
    
    check1 <- grep("code", data[, 1], ignore.case = T)
    check2 <- grep("code", data[, 2], ignore.case = T)
    
    if (is.na(check1[1])) data <- data[c((check2[1] + 1):nrow(data)), c(2:10)]
    else                  data <- data[c((check1[1] + 1):nrow(data)), c(1:9)]
    
    ind    <- apply(data, 1, function(x) all(is.na(x)))
    data   <- data[ !ind, ]
    names(data) <- coln
  } else if (basename(file) == probs[1]){ #for Alaska 97
    data   <- read_excel(file)
    check1 <- grep("code", data[, 1], ignore.case = T)
    data   <- cbind(data[c((check1[1] + 1):nrow(data)), c(1:2)], NA,
                    data[c((check1[1] + 1):nrow(data)), c(3:8)])
    ind    <- apply(data, 1, function(x) all(is.na(x)))
    data   <- data[!ind, ]
    names(data) <- coln
    data$county_name <- "AK Replace"
  } else if (basename(file) == probs[2]){ #for KY 01
    data   <- read_excel(file)
    check1 <- grep("code", data[, 1], ignore.case = T)
    data1  <- data[c((check1[1] + 1)), c(1:9)]
    data2  <- data[c((check1[1] + 2):nrow(data)), c(1:9)]
    names(data1) <- names(data2) <- coln
    
    # Correct:
    data1$interest  = as.character(sum(as.numeric(data2$interest)))
    
    data   <- bind_rows(data1, data2)
    
    ind    <- apply(data, 1, function(x) all(is.na(x)))
    data   <- data[ !ind, ]
  } else if (basename(file) == probs[3]){ #for MA 01
    data   <- read_excel(file)
    check1 <- grep("code", data[, 1], ignore.case = T)
    data1  <- data[c((check1[1] + 1)), c(1:9)]
    data2  <- data[c((check1[1] + 2):nrow(data)), c(1:9)]
    names(data1) <- names(data2) <- coln
    
    # Correct:
    data1$county_name = "Total"
    data1$return  = as.character(sum(as.numeric(data2$return)))
    
    data   <- bind_rows(data1, data2)
    
    ind    <- apply(data, 1, function(x) all(is.na(x)))
    data   <- data[!ind, ] 
  }
  return(data)
}

read_pop2 <- function(file){
  coln   <- c("st_fips", "cty_fips", "county_name", "return", "exmpt",
              "agi", "wages", "dividends", "interest")
  data   <- read.xls(file)
  data   <- data[c(5:nrow(data)), c(1:9)]
  ind    <- apply(data, 1, function(x) all(is.na(x)))
  data   <- data[ !ind, ]
  names(data) <- coln
  return(data)
}


# Function for fips issues ------------------------------------------------


fipssues <- function(data, fip, fiplace){
  data %>% filter(fips %in% fiplace) %>% group_by(year) %>%
    summarise_each(funs(sum), -fips) -> correct
  correct$fips <- fip
  data %>% filter(!(fips %in% fiplace)) %>%
    bind_rows(correct) -> data
  
  return(data)
}
fipssuesmean <- function(data, fip, fiplace){
  correct <- data %>% filter(fips %in% fiplace) %>% group_by(year) %>%
    summarise_each(funs(sum), -fips)
  correct$fips <- fip
  data %>% filter(!(fips %in% fiplace)) %>%
    bind_rows(correct) -> data
  
  return(data)
}
fipssuespov <- function(data, fip, fiplace){
  correct <- data %>% filter(fips %in% fiplace) %>% group_by(year) %>%
    summarise(POV_ALL = sum(POV_ALL, na.rm = T),
              POV_ALL_P = mean(POV_ALL_P, na.rm = T),
              POV_0.17 = sum(POV_0.17, na.rm = T),
              POV_0.17_P = mean(POV_0.17_P, na.rm = T),
              POV_5.17 = sum(POV_5.17, na.rm = T),
              POV_5.17_P = mean(POV_5.17_P, na.rm = T),
              MEDHHINC = mean(MEDHHINC, na.rm = T),
              POP_POV = sum(POP_POV, na.rm = T))
  correct$fips <- fip
  data %>% filter(!(fips %in% fiplace)) %>%
    bind_rows(correct) -> data
  
  return(data)
}

# Function for fips issues for CBP
fipssues1 <- function(data, fip, fiplace){
  data %>% filter(fips %in% fiplace) %>% group_by(year, sic, naics) %>%
    summarise_each(funs(sum), -fips, -empflag) -> correct
  correct$fips <- fip
  data %>% filter(!(fips %in% fiplace)) %>%
    bind_rows(correct) -> data
  
  return(data)
}
fipssues2 <- function(data, fip, fiplace){
  data %>% filter(fips %in% fiplace) %>% group_by(year, naics) %>%
    summarise_each(funs(sum), -fips, -empflag, -(emp_nf:ap_nf)) -> correct
  correct$fips <- fip
  data %>% filter(!(fips %in% fiplace)) %>%
    bind_rows(correct) -> data
  
  return(data)
}