# RSYNT_POSTPROSESS for kube MOBBING_1aar_0
# Skrevet av: VL Februar 2023

# Delete observations censored by UDIR for 2021 and 2022

cat("\n\nSTARTER RSYNT_POSTPROSESS, R-SNUTT\n")
cat("\nSletter tall som er prikket av UDIR f.o.m. 2021\n")

# Load lists of which GEO-codes are censored for all combinations of AAR, KJONN, and TRINN
.udirprikk <- fread("F:/Forskningsprosjekter/PDB 2455 - Helseprofiler og til_/PRODUKSJON/BIN/Z_Statasnutter/UDIR_prikkelister/mobbing_udir_prikket_21_22.csv")

# Matching KUBE col classes
# Convert GEO to character, add leading 0 if 3 characters, convert TRINN to character
.udirprikk[, GEO := as.character(GEO)]
.udirprikk[nchar(GEO) == 3, GEO := paste0("0", GEO)]
.udirprikk[, TRINN := as.character(TRINN)]

# merge KUBE and .udirprikk. Adds column UDIRPRIKK = 1 for strata censored by Udir
KUBE <- merge.data.table(KUBE, .udirprikk, by = c("GEO", "AAR", "KJONN", "TRINN"), all.x = T)

# Save object UDIRPRIKKpre
UDIRPRIKKpre <<- KUBE[UDIRPRIKK == 1]
cat("\n Object UDIRPRIKKpre saved to environment, showing relevant rows before observations are deleted")
cat(paste0("\nN prikk pre: ", KUBE[is.na(TELLER), .N]))
cat(paste0("\nAdditional rows to be censored: ", KUBE[!is.na(TELLER) & UDIRPRIKK == 1, .N]))

# Delete data for rows where UDIRPRIKK == 1
KUBE[UDIRPRIKK == 1,
     `:=` (
       TELLER = NA_real_,
       RATE = NA_real_,
       SMR = NA_real_,
       MEIS = NA_real_,
       RATE.n = NA_real_,
       sumTELLER = NA_real_,
       sumNEVNER = NA_real_,
       TELLER.f = 3,
       RATE.f = 3
     )]

# Save object UDIRPRIKKpost
UDIRPRIKKpost <<- KUBE[UDIRPRIKK == 1]
cat("\n Object UDIRPRIKKpost saved to environment, showing relevant rows after observations are deleted")
cat(paste0("\nN prikk pre: ", KUBE[is.na(TELLER), .N]))
cat("\nRSYNT_POSTPROSESS ferdig")