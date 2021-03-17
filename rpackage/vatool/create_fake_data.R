is_local <- TRUE
library(dplyr)
library(RPostgres)

# Define credentials
creds <- list(dbname = 'va')

users <- 
  tibble(user_id = 1:5,
         username = c('joe', 'ben', 'xing', 'cece', 'ramona'),
         password = 'password',
         first_name = c('Joe', 'Ben', 'Xing', 'Cece', 'Ramona'),
         last_name = 'Brew',
         country = c('Tanzania', 'Mozambique', 'Tanzania', 'Mozambique', 'Tanzania'),
         role = c('Adjudicator', 'Adjudicator', 'Viewer', 'Physician', 'Physician'))

# create cods data 
cods <- 
  tibble(user_id = c(1,2,1,2,3,4,5,3),
         death_id= c('MTM-013-701', 'MTM-013-701', 'NAU-040-701','MBI-076-701', 'KUK-129-701', 'KUK-129-701','KAI-013-701', 'KAI-013-701' ),
         cod_code = c('G03', 'P23', 'G03', 'A06', 'A09', 'A15', 'A20', 'A20'),
         cod = c('Meningitis', 'Pneumonia', 'Meningitis','Dysentery Acute/Chronic', 'Diarrhoea','TB Confirmed', 'Plague','Plague'),
         time_stamp = c("2021-02-16 09:46:39 EDT", "2021-01-11 08:46:39 EDT", "2021-01-16 11:36:39 EDT", "2021-03-15 09:46:39 EDT", "2021-03-08 09:50:39 EDT", "2021-02-16 09:46:39 EDT", "2021-03-16 09:45:39 EDT", "2021-03-16 09:46:39 EDT"))

# Define connection
drv <- RPostgres::Postgres()
if(is_local){
  con <- dbConnect(drv = drv,
                   dbname = creds$dbname)
} else {
  stop('REMOTE NOT READY YET')
}

# Write table
dbWriteTable(conn = con, name = 'users', value = users, overwrite = TRUE)
dbWriteTable(conn = con, name = 'cods', value = cods, overwrite = TRUE)
dbDisconnect(con)
