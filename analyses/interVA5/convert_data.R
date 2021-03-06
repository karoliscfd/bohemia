library(CrossVA)
library(openVA)
library(nbc4va)
library(InterVA5)
library(bohemia)

# mozambique
moz_forms <- load_odk_data(the_country = 'Mozambique',
                           credentials_path = '../../credentials/credentials.yaml',
                           users_path = '../../credentials/users.yaml',
                           local = FALSE, 
                           efficient=FALSE,
                           use_cached = FALSE)
va <- moz_forms$va

# save.image('temp.RData')
# CrossVA package example data (VA version 1.5.1)
datafile_2016_151 <- system.file("sample", "who151_odk_export.csv", package = "CrossVA")
records_2016_151 <- read.csv(datafile_2016_151)
whoData2016_151 <- odk2openVA(records_2016_151)

out2 <- InterVA5(whoData2016_151, HIV = "l", Malaria = "l", directory = getwd())
summary(out2)

# our data (VA version 1.5.3)
dat <- read.csv('2016_WHO_Verbal_Autopsy_Form_1_5_3_results.csv')
# right now only one row, so create a fake 2nd row
dat <- rbind(dat, dat)
temp <- odk2openVA_v151(dat)
temp2 <- InterVA5(temp,  HIV = "l", Malaria = "l", directory = getwd())
summary(temp2)


