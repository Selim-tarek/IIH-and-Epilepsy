## K7_code_inventory.R --------------------------------------------------------
## Full inventory of every seizure-extract code, for the investigator to decide
## which to exclude.
##
## Counted over the analysis window only: after the 180-day washout and within
## the at-risk clock (index to last attended encounter, death or freeze, capped
## at 3 years). Rows outside that window cannot affect any estimate.
##
## COLUMNS
##   ctl_rows / iih_rows      how often the code appears
##   ctl_pts  / iih_pts       how many patients carry it at least once
##   ctl_only / iih_only      patients whose ONLY qualifying code is this one.
##                            This is the column that matters: excluding a code
##                            removes only these patients from the event count.
##   currently                whether the code is counted in the corrected
##                            primary analysis as it stands
##
## WHATEVER IS EXCLUDED MUST BE EXCLUDED FROM BOTH ARMS. 70 of the 102 IIH
## events rest on R56.9 / 780.39 alone, so dropping those codes removes them
## from the IIH arm as well; the iih_only column shows the cost.

source("R/00_setup.R")
log_msg("=== K7 code inventory ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds")); W <- 180; TAU <- 3
d0$open <- pmin(d0$fu_carpal_end_day, W + TAU*365.25)

dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character")
names(dx) <- c("mrn","s","code","desc","date")
cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character")
names(cn) <- c("mrn","s","code","desc","on","rec")
o <- as.Date(substr(cn$on,1,10)); r <- as.Date(substr(cn$rec,1,10))
e <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
           data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                      date=as.Date(ifelse(is.na(o), r, o), origin="1970-01-01")))
e <- e[e$mrn %in% d0$mrn & !is.na(e$date), ]
i <- match(e$mrn, d0$mrn)
e$day <- as.numeric(e$date - d0$index_date[i]); e$iih <- d0$iih[i]; e$open <- d0$open[i]
e <- e[e$day > W & e$day <= e$open + 1e-6, ]
e$key <- paste0(e$code, " | ", e$desc)

## what the corrected primary currently counts
cur <- (grepl("^G40|^345|^0345|^R56|^780\\.39|^07703", e$code)) &
       !(grepl("^F44|^300\\.11|^R56\\.1|^780\\.33|^780\\.32|^Z82|^G43|^E936|^966", e$code) |
         grepl("febrile|non.epileptic|psychogenic|conversion|family history|migraine|poisoning|adverse",
               e$desc, ignore.case=TRUE))
e$counted <- cur
qq <- e[e$counted, ]
solo <- tapply(qq$key, qq$mrn, function(k) if (length(unique(k))==1) unique(k) else NA_character_)
solo <- solo[!is.na(solo)]
solo_arm <- d0$iih[match(names(solo), d0$mrn)]

keys <- sort(unique(e$key))
inv <- do.call(rbind, lapply(keys, function(k){
  s <- e[e$key==k, ]
  data.frame(code=sub(" \\|.*","",k), description=sub(".*\\| ","",k),
    ctl_rows=sum(s$iih==0), iih_rows=sum(s$iih==1),
    ctl_pts=length(unique(s$mrn[s$iih==0])), iih_pts=length(unique(s$mrn[s$iih==1])),
    ctl_only=sum(solo==k & solo_arm==0), iih_only=sum(solo==k & solo_arm==1),
    currently=if (any(s$counted)) "COUNTED" else "excluded") }))
inv <- inv[order(-(inv$ctl_pts + inv$iih_pts)), ]
write_tab(inv, "K_T14_code_inventory")
print(inv[inv$ctl_pts + inv$iih_pts >= 3,
          c("code","description","ctl_pts","iih_pts","ctl_only","iih_only","currently")],
      row.names=FALSE)
log_msg("rows with fewer than 3 patients are in the CSV but not printed")
log_msg("K7 complete")
