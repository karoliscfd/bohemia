library(CrossVA)
library(openVA)
library(nbc4va)
library(InterVA5)
library(bohemia)
library(RPostgres)

# See useful presentation at https://zehangli.com/openVA/openVA-ghana_2017.html#data-preparation
# See useful vignette at http://openva.net/vignettes/using-crossva-and-openva.html

# See useful slide on conversion on first presentation. Example:
# toyDataNew <- ConvertData(toyData, yesLabel = "Yes", noLabel = "No", 
#                           missLabel = c("Don't know", "Refused to answer"))
# toyDataNew

# See interva fields 
## data(causetextV5)
data(causetextV5)
data(RandomVA5) # format should be this
data(probbaseV5)
data(probbaseV5_14)
data(probbaseV5_17)

is_local <- FALSE
drv <- RPostgres::Postgres()
# read in credenstials 
creds <- yaml::yaml.load_file('../../credentials/credentials.yaml')


if(is_local){
  con <- dbConnect(drv, dbname='bohemia')
} else {
  psql_end_point = creds$endpoint
  psql_user = creds$psql_master_username
  psql_pass = creds$psql_master_password
  con <- dbConnect(drv, dbname='bohemia', host=psql_end_point, 
                   port=5432,
                   user=psql_user, password=psql_pass)
}

va <- dbGetQuery(conn = con,
                 'SELECT * FROM va LIMIT 100')

dbDisconnect(con)

# CrossVA package example data (VA version 1.5.1)
datafile_2016_151 <- system.file("sample", "who151_odk_export.csv", package = "CrossVA")
records_2016_151 <- read.csv(datafile_2016_151)
whoData2016_151 <- odk2openVA(records_2016_151)

out2 <- InterVA5(whoData2016_151, HIV = "l", Malaria = "l", directory = getwd())
summary(out2)

# our data (VA version 1.5.3)
dat <- va
dat <- read.csv('2016_WHO_Verbal_Autopsy_Form_1_5_3_results.csv') # https://trello.com/c/ZiqTjBeD/2328-bohemia-get-our-data-into-interva-5-format
# right now only one row, so create a fake 2nd row
dat <- rbind(dat, dat)
temp <- odk2openVA_v151(dat)
temp2 <- InterVA5(temp,  HIV = "l", Malaria = "l", directory = getwd())
summary(temp2)


