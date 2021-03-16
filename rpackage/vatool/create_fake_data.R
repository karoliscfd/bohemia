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
         role = c('Physician', 'Adjudicator', 'Viewer', 'Physician', 'Physician'))

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


dbDisconnect(con)
