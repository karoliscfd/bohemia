dat <- read.csv('contact_info.csv')
dat$X <- NULL
usethis::use_data(dat, overwrite = TRUE)

# get va form (For readable variable names)
va_form <- read.csv('va_clean_names.csv', na.strings = c('NA'=''))
va_form <- va_form %>% select(name, label_english = label..English, label_portuguese = label..Portuguese, label_swahili = label..Swahili)
va_names <- va_form[complete.cases(va_form),]
usethis::use_data(va_names, overwrite = TRUE)
