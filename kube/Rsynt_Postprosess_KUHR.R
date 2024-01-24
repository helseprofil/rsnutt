# RSYNT_POSTPROSESS for kube KUHR
# Skrevet av: VL 11.jan 2024

# Sletter tall på bydelsnivå for 2023
# Fordi: For høy andel uoppgitt bydel

KUBE[nchar(GEO) > 4 & 
       grepl("^1103", GEO) & 
       !GEO %in% c("110308", "110309") & 
       TELLER.f > 0, 
     `:=` 
     (TELLER.f = 9,
       RATE.f = 9)]

KUBE[AAR == "2020_2022" & 
       nchar(GEO) > 4, 
     `:=` 
     (RATE = NA_real_,
       SMR = NA_real_,
       MEIS = NA_real_,
       TELLER.f = 1,
       RATE.f = 1)]