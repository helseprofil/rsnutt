# title: "Rsynt_Pre_FGlagring_KUHR
# author: "Vegard"
# updated: "2024-01-25"
# 
# Handle kommune -> bydel (Stavanger)
# Set old GEO codes corresponding to Aalesund/Haram to 1507 for years 2020-2023
# Rectangularize FG
# Set all missing to explicit 0 except for old GEO codes corresponding to AAlesund/Haram for years 2020-2023

# Handle kommune which became bydel
Filgruppe[GEO %in% c("503000", "166200"), GEO := "500104"]
Filgruppe[GEO %in% c("114100" ), GEO := "110308"]
Filgruppe[GEO %in% c("114200"), GEO := "110309"]

# old GEO codes corresponding to AAlesund/Haram
oldcodes <- c("150400", "152300", "152900", "153400", "154600")

# For years 2020-2023, set 1504, 1523, 1534, 1529, 1546 to 1507
Filgruppe[AARl %in% c(2020, 2021, 2022, 2023) & GEO %in% oldcodes,
          GEO := "150700"]

# Rectanguralize FG
Filgruppe[, `:=` (tempAAR = paste(AARl, AARh, sep = "_"),
                  tempALDER = paste(ALDERl, ALDERh, sep = "_"))]

# Generate all strata
.dims <- c("GEOniv", "tempAAR", "tempALDER", "KJONN", "UTDANN", "LANDBAK", "INNVKAT", "TAB1", "GEO")
rect <- do.call(CJ, lapply(.dims, function(x) unique(Filgruppe[[x]])))
rect <- setNames(rect, .dims)

# Add AARl, AARh, ALDERl, ALDERh, FYLKE, KOBLID, ROW
rect <- collapse::join(rect, Filgruppe[, .(tempALDER, tempAAR, AARl, AARh, ALDERl, ALDERh)], 
                       on  = c("tempALDER", "tempAAR"), how = "left")
rect <- collapse::join(rect, Filgruppe[, .(GEO, FYLKE)], 
                       on = "GEO", how = "left")
rect[, `:=` (KOBLID = NA_integer_,
             ROW = 1L:nrow(rect))]

# Merge value columns ANTOBS, ANTOBS.f, and ANTOBS.a
joincols2 <- c("ANTOBS", "ANTOBS.f", "ANTOBS.a")
rect <- collapse::join(rect, Filgruppe[, mget(c(.dims, joincols2))], 
                       on = .dims, how = "left", multiple = T)

# Set explicit 0
rect[!complete.cases(ANTOBS, ANTOBS.a, ANTOBS.f), `:=` (ANTOBS = 0,
                                                        ANTOBS.f = 0,
                                                        ANTOBS.a = 1)]

# Delete rows for year 2020-2023 and old GEO corresponding to AAlesund/Haram
rect <- rect[!(AARl %in% c(2020, 2021, 2022, 2023) & GEO %in% oldcodes)]

# Cleanup and replace Filgruppe with rectangularized file
setcolorder(rect, names(Filgruppe))
rect[, grep("temp", names(rect)) := NULL]

Filgruppe <- copy(rect)
rm(rect)
gc()
