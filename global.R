library(googlesheets)

#shiny_token <- gs_auth() # authenticate w/ your desired Google identity here
#saveRDS(shiny_token, "token.rds")

googlesheets::gs_auth(token = "token.rds")
source_key <- gs_key(x="1aeL31DIetHqVMvqMZTRWcFSq17JsbOdnpUTMC-_M6RI")

slist_key <- gs_key("1cbumxhU4vhWxp96LI5plcN_t5jQusVeVPhNZ7qU4wDM")


