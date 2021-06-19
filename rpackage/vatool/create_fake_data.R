is_local <- TRUE
library(dplyr)
library(RPostgres)
library(yaml)

# Define credentials
creds <- list(dbname = 'bohemia')

# password <- yaml::yaml.load_file('credentials/users.yaml')

# Read in users from the main bohemia app

users <- 
  tibble(user_id = 1:14,
         username = c('kizito', 'narciso', 'gilda', 'celso', 'sheila', 'elisio', 'antonio', ' brito', 'tacilta', 'francisco', 'salesio', 'hansel', 'joyce', 'patrick'),
         password = rep('pword', 14),
         first_name = c('kizito', 'narciso', 'gilda', 'celso', 'sheila', 'elisio', 'antonio', ' brito', 'tacilta', 'francisco', 'salesio', 'hansel', 'joyce', 'patrick'),
         last_name = c('Gondo', 'Valoi', 'Mapute', 'Monjane', 'Mercedes', 'Xerinda', 'Americo', 'Rato', 'Nhampossa', 'Saute', 'Macuacua', 'Mundaca', 'Mugasa', 'Kabangutse'))

# create cods data 
cods <- 
  tibble(user_id = c('test_entry'),
         death_id= c('MTM-013-701'),
         cod_code_1 = c('T67'),
         cod_1 = c('Effects of heat and light'),
         cod_code_2 = c('A06'),
         cod_2 = c('Dysentery Acute/Chronic'),
         cod_code_3 = c('G03'),
         cod_3 = c('Meningitis'),
         time_stamp = c("2021-02-16 09:46:39 EDT"))


# Define connection
drv <- RPostgres::Postgres()
if(is_local){
  con <- dbConnect(drv = drv,
                   dbname = creds$dbname)
} else {
  creds <- yaml::yaml.load_file('credentials/credentials.yaml')
  psql_end_point = creds$endpoint
  psql_user = creds$psql_master_username
  psql_pass = creds$psql_master_password
  con <- dbConnect(drv, dbname='bohemia', host=psql_end_point, 
                   port=5432,
                   user=psql_user, password=psql_pass)
}

# Write table
dbWriteTable(conn = con, name = 'vatool_users', value = users, overwrite = TRUE)
dbWriteTable(conn = con, name = 'vatool_cods', value = cods, overwrite = TRUE)
dbDisconnect(con)
