# title: "Rsynt_Postprosess_MOBBING_1aar_0"
# author: "Vegard"
# updated: "2024-01-24"
# 
# Retrieve data from UDIR via API
# Identifies all strata which is censored by UDIR to make sure we do not show these data. 

library(httr2)
library(data.table)

cat("\n\nSTARTER RSYNT_POSTPROSESS, R-SNUTT\n")
cat("\nHenter prikkeinformasjon fra UDIR, f.o.m. 2021-2022")
mobbingapi <- "https://api.statistikkbanken.udir.no/api/rest/v2/Eksport/150"

# Get all available years
filterverdier <- httr2::request(mobbingapi) |>
  httr2::req_url_path_append("filterVerdier") |> 
  httr2::req_retry(max_tries = 5) |>
  httr2::req_perform() |> 
  httr2::resp_body_json(simplifyDataFrame = TRUE)

aar <- paste(filterverdier$TidID$id, collapse = "_")

# Define query
qry <- list(filter = I(paste0("TidID(", aar, ")_EierformID(-10)_KjoennID(-10)_SpoersmaalID(334)_TrinnID(6_9)")),
            format = 0)

# Find number of pages
pages <- httr2::request(mobbingapi) |>
  httr2::req_url_path_append("sideData") |>
  httr2::req_url_query(!!!qry) |>
  httr2::req_perform() |>
  httr2::resp_body_json(simplifyDataFrame = TRUE)
pages <- pages$JSONSider

# Get data
udirprikk <- data.table()
for(i in 1:pages){
  newpage <- httr2::request(mobbingapi) |>
    httr2::req_url_path_append("data") |> 
    httr2::req_retry(max_tries = 5) |>
    httr2::req_url_query(!!!qry) |> 
    httr2::req_url_query(sideNummer=i) |> 
    httr2::req_perform() |> 
    httr2::resp_body_json(simplifyDataFrame = TRUE)
  
  udirprikk <- rbindlist(list(udirprikk,
                              newpage))
}

# Data wrangling
udirprikk <- udirprikk[EnhetNivaa == 3 & AndelMobbet == "*"]
udirprikk[, `:=` (GEO = Kommunekode,
                  KJONN = 0,
                  TRINN = TrinnKode,
                  UDIRPRIKK = 1,
                  AAR = paste0(substr(Skoleaarnavn, 1,4), "_", 
                               as.integer(substr(Skoleaarnavn, 1,4))+1))]
udirprikk <- udirprikk[, .(GEO, AAR, KJONN, TRINN, UDIRPRIKK)]

# Merge udirdata
KUBE <- merge.data.table(KUBE, udirprikk, by = c("GEO", "AAR", "KJONN", "TRINN"), all.x = T)

# Save object UDIRPRIKKpre
UDIRPRIKKpre <<- KUBE[UDIRPRIKK == 1]
cat("\n Object UDIRPRIKKpre saved to environment, showing relevant rows before observations are deleted")
cat(paste0("\nN prikk pre: ", KUBE[is.na(RATE), .N]))
cat(paste0("\nAdditional rows to be censored: ", KUBE[!is.na(RATE) & UDIRPRIKK == 1, .N]))

# Delete data for rows where UDIRPRIKK == 1
KUBE[UDIRPRIKK == 1,
     `:=` (
       RATE = NA_real_,
       SMR = NA_real_,
       MEIS = NA_real_,
       TELLER.f = 3,
       RATE.f = 3
     )]

# Save object UDIRPRIKKpost
UDIRPRIKKpost <<- KUBE[UDIRPRIKK == 1]
cat("\n Object UDIRPRIKKpost saved to environment, showing relevant rows after observations are deleted")
cat(paste0("\nN prikk pre: ", KUBE[is.na(RATE), .N]))
cat("\nRSYNT_POSTPROSESS ferdig")
