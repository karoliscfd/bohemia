is_local <- TRUE
library(dplyr)
library(RPostgres)
library(yaml)

# Define credentials
creds <- list(dbname = 'bohemia')

# password <- yaml::yaml.load_file('credentials/users.yaml')

# Read in users from the main bohemia app

users <- 
  tibble(user_id = 1:6,
         username = c('joe', 'ben', 'xing', 'cece', 'ramona', 'hansel'),
         # password = password$`joe@databrew.cc`,
         password = c('unique', 'unique', 'unique', 'unique', 'unique', 'unique'),
         first_name = c('Joe', 'Ben', 'Xing', 'Cece', 'Ramona', 'Hansel'),
         last_name = c(rep('Brew', 5), 'Manduca'),
         country = c('Tanzania', 'Mozambique', 'Tanzania', 'Mozambique', 'Tanzania', 'Spain'),
         role = c('Adjudicator', 'Adjudicator', 'Viewer', 'Physician', 'Physician', 'Physician'))

# create cods data 
cods <- 
  tibble(user_id = c(1,2,1,2,3,4,5,3),
         death_id= c('MTM-013-701', 'MTM-013-701', 'NAU-040-701','MBI-076-701', 'KUK-129-701', 'KUK-129-701','KAI-013-701', 'KAI-013-701' ),
         cod_code_1 = c('T67', 'G03', 'A06', 'A09', 'A15', 'A20', 'A20', 'P23'),
         cod_1 = c('Effects of heat and light', 'Meningitis','Dysentery Acute/Chronic', 'Diarrhoea','TB Confirmed', 'Plague','Plague', 'Pneumonia'),
         cod_code_2 = c('A06', 'D48', 'O71', 'P95', 'T71',  'A20','A15' ,'Y08'),
         cod_2 = c('Dysentery Acute/Chronic', 'Tumours Other non-malignant', 'Rupture uterus','Stillbirth (macerated)', 'Asphyxiation', 'Plague','TB Confirmed','Assault by other specified means'),
         cod_code_3 = c('G03', 'P23', 'G03', 'A06', 'A09', 'A15', 'A20', 'A20'),
         cod_3 = c('Meningitis', 'Pneumonia', 'Meningitis','Dysentery Acute/Chronic', 'Diarrhoea','TB Confirmed', 'Plague','Plague'),
         time_stamp = c("2021-02-16 09:46:39 EDT", "2021-01-11 08:46:39 EDT", "2021-01-16 11:36:39 EDT", "2021-03-15 09:46:39 EDT", "2021-03-08 09:50:39 EDT", "2021-02-16 09:46:39 EDT", "2021-03-16 09:45:39 EDT", "2021-03-16 09:46:39 EDT"))


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
