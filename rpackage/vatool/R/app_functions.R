library(shiny)
library(dplyr)

# # load VA data (for now, this is fake)
load_va_data <- function(is_local = FALSE, use_cached = TRUE){

  if(use_cached){
    if(file.exists('/tmp/va.RData')){
      load('/tmp/va.RData')
      get_new <- FALSE
    } else {
      get_new <- TRUE
    }
  }
  # if(file.exists('../data-raw/va.csv')){
  #   out <- read.csv('../data-raw/va.csv')
  # } else {
  #   stop('YOU NEED TO DOWNLOAD va.csv INTO data-raw. Get from https://trello.com/c/75qsyxWu/2368-bohemia-va-tool-create-functioning-tool')
  # }
  if(get_new){
    con <- get_db_connection(local = is_local)
    out <- dbReadTable(conn = con, name = 'va')
    dbDisconnect(con)
    save(out, file = '/tmp/va.RData')
  }
  return(out)
}

# function for getting readable names 
get_va_names <- function(va_data){
  col_names <- names(va_data)
  for(i in 1:length(col_names)){
    this_col <- col_names[i]
    if(any(this_col==tolower(va_names$name))){
      name_index <- which(this_col ==tolower(va_names$name))
      names(va_data)[i] <- as.character(va_names$label_english[name_index])
    }
  }
  return(va_data)
}


# Random date function
random_date <- function(n = 10000){
  sample(Sys.Date() - n: 
             Sys.Date(),
         1)
}

# Function for cause of death choices
cod_choices <- function(){
  icd_codes <- c('A00', 'A01', 'A01', 'A06', 'A09', 'A15', 'A16', 'A20', 'A33', 'A41', 'A75', 'B05', 'B24', 'B45', 'B53', 'B54', 'C80', 'G03', 'G04', 'G83', 'I50', 'J06', 'J18', 'J45', 'J81', 'J98', 'K75', 'L08', 'R09', 'R50', 'S09', 'S36', 'T14', 'T14.9', 'T30', 'C22', 'C46', 'C50', 'C55', 'C61', 'C80', 'D48', 'E14', 'I10', 'I42', 'I64', 'A80', 'K25', 'K29', 'K37', 'K46', 'K56', 'K65', 'K74', 'K75', 'K92', 'M86', 'M89', 'N04', 'N05', 'N15', 'N39', 'N94', 'B24', 'P05', 'P15', 'P21', 'P22', 'P23', 'P36', 'P37', 'P54', 'P74', 'P78', 'P95', 'P95', 'P95', 'Q05', 'Q24', 'Q89', 'R95', 'X49', 'Y09', 'O06', 'O16/O15', 'O46', 'O66', 'O71', 'O72', 'O75', 'O75', 'O85', 'O98', 'O99', 'O99', 'O99', 'O99', 'O99.4', 'Z21', 'T29', 'T30', 'T31', 'T32', 'T50', 'T51', 'T54', 'T56', 'T58', 'T59', 'T60', 'T65', 'T67', 'T70', 'T71', 'T80', 'T81', 'T83', 'Y08', 'Y09', 'V98', 'V99', 'V99')
  icd_names <- c("Cholera", "Typhoid fever (salmonellosis)", "Typhoid", "Dysentery Acute/Chronic", "Diarrhoea", "TB Confirmed", "TB Not confirmed", "Plague", "Tetanus, Neonatal", "Septicaemia", "Relapsing Fever (Louse borne Typhus)", "Measles", "HIV and AIDS", "Meningitis Cryptococal", "Malaria confirmed", "Malaria presumptive", "Neoplasm", "Meningitis", "Encephalitis", "Acute Flaccid Paralysis", "Heart failure", "Respiratory Infection Acute (ARI)", "Pneumonia", "Asthma", "Pulmonary oedema", "Pneumopathies", "Hepatitis", "Skin infections", "Pleurisy (non-Tuberculosis)", "Fever Chronic (> 1 month)", "Head injury", "Ruptured spleen", "Fractures", "Trauma Other", "Burns", "Cancer Liver", "Kaposi's sarcoma", "Cancer Breast", "Cancer Uterine", "Cancer Prostate", "Tumours Other malignant", "Tumours Other non-malignant", "Diabetes", "Hypertension", "Cardiomyopathy", "Cerebrovascular accident", "Acute Flacid Paralysis (polio)", "Ulcer, gastro-duodenal", "Gastritis", "Appendicitis", "Hernia", "Intestinal occlusion", "Peritonitis (non-Tuberculosis)", "Cirrhosis of the liver", "Hepatitis", "Digestive tract Haemorrhages", "Bone infections (including osteomyelitis)", "Bone and joint disease other", "Nephrotic syndrome", "Glomerulonephritis", "Kidney infections", "Urinary tract infections", "Gynecological problems", "Paediatric AIDS", "Low birth weight or Prematurity Complication", "Birth trauma", "Neonatal Asphyxia", "Respiratory distress", "Pneumonia", "Neonatal Septicaemia", "Malaria", "Haemorrhage", "Dehydration", "Diarrhoea", "Stillbirth (fresh)", "Stillbirth (macerated)", "Stillbirth", "Congenital hydrocephalus and spinal bifida", "Congenital malformation of the heart", "Other congenital malformation", "Sudden infant death syndrome", "Accidental poisoning by and exposure to noxious substances", "Assault", "Abortion", "Severe Hypertension in pregnancy/ eclampsia", "Antepartum Haemorrhage", "Obstructed Labour", "Rupture uterus", "Post-partum haemorrhage", "Unknown fever", "Local herbs", "Puerperal Sepsis /Septicaemia", "Malaria in pregnancy", "Pneumonia", "Anaemia in Pregnancy", "Pulmonary oedema", "Meningitis", "Cardiomyopathy", "Asymptomatic HIV", "Burns and corrosions of multiple body regions", "Burn and corrosion, body region unspecified", "Burns classified according to extent of body surface involved", "Corrosions classified according to extent of body surface involved", "Poisoning by diuretics and other unspecified drugs, medicaments and biological substances", "Toxic effect of alcohol", "Toxic effect of corrosive substances", "Toxic effect of metals", "Toxic effect of carbon monoxide", "Toxic effect of other gases, fumes and vapours", "Toxic effect of pesticides", "Toxic effect of other and unspecified substances", "Effects of heat and light", "Effects of air pressure and water pressure", "Asphyxiation", "Complications following infusion, transfusion and therapeutic injection", "Complications of procedures, not elsewhere classified", "Complications of genitourinary devices, implants and grafts", "Assault by other specified means", "Assault by other unspecified means", "Other Specified transport accidents", "Unspecified transport accidents", "Test ICD 10 Value")
  choices <- icd_codes
  names(choices) <- icd_names
  return(choices)
}

# create data to match codes and names
cod_data <- function(){
  icd_codes <- c('A00', 'A01', 'A01', 'A06', 'A09', 'A15', 'A16', 'A20', 'A33', 'A41', 'A75', 'B05', 'B24', 'B45', 'B53', 'B54', 'C80', 'G03', 'G04', 'G83', 'I50', 'J06', 'J18', 'J45', 'J81', 'J98', 'K75', 'L08', 'R09', 'R50', 'S09', 'S36', 'T14', 'T14.9', 'T30', 'C22', 'C46', 'C50', 'C55', 'C61', 'C80', 'D48', 'E14', 'I10', 'I42', 'I64', 'A80', 'K25', 'K29', 'K37', 'K46', 'K56', 'K65', 'K74', 'K75', 'K92', 'M86', 'M89', 'N04', 'N05', 'N15', 'N39', 'N94', 'B24', 'P05', 'P15', 'P21', 'P22', 'P23', 'P36', 'P37', 'P54', 'P74', 'P78', 'P95', 'P95', 'P95', 'Q05', 'Q24', 'Q89', 'R95', 'X49', 'Y09', 'O06', 'O16/O15', 'O46', 'O66', 'O71', 'O72', 'O75', 'O75', 'O85', 'O98', 'O99', 'O99', 'O99', 'O99', 'O99.4', 'Z21', 'T29', 'T30', 'T31', 'T32', 'T50', 'T51', 'T54', 'T56', 'T58', 'T59', 'T60', 'T65', 'T67', 'T70', 'T71', 'T80', 'T81', 'T83', 'Y08', 'Y09', 'V98', 'V99', 'V99')
  icd_names <- c("Cholera", "Typhoid fever (salmonellosis)", "Typhoid", "Dysentery Acute/Chronic", "Diarrhoea", "TB Confirmed", "TB Not confirmed", "Plague", "Tetanus, Neonatal", "Septicaemia", "Relapsing Fever (Louse borne Typhus)", "Measles", "HIV and AIDS", "Meningitis Cryptococal", "Malaria confirmed", "Malaria presumptive", "Neoplasm", "Meningitis", "Encephalitis", "Acute Flaccid Paralysis", "Heart failure", "Respiratory Infection Acute (ARI)", "Pneumonia", "Asthma", "Pulmonary oedema", "Pneumopathies", "Hepatitis", "Skin infections", "Pleurisy (non-Tuberculosis)", "Fever Chronic (> 1 month)", "Head injury", "Ruptured spleen", "Fractures", "Trauma Other", "Burns", "Cancer Liver", "Kaposi's sarcoma", "Cancer Breast", "Cancer Uterine", "Cancer Prostate", "Tumours Other malignant", "Tumours Other non-malignant", "Diabetes", "Hypertension", "Cardiomyopathy", "Cerebrovascular accident", "Acute Flacid Paralysis (polio)", "Ulcer, gastro-duodenal", "Gastritis", "Appendicitis", "Hernia", "Intestinal occlusion", "Peritonitis (non-Tuberculosis)", "Cirrhosis of the liver", "Hepatitis", "Digestive tract Haemorrhages", "Bone infections (including osteomyelitis)", "Bone and joint disease other", "Nephrotic syndrome", "Glomerulonephritis", "Kidney infections", "Urinary tract infections", "Gynecological problems", "Paediatric AIDS", "Low birth weight or Prematurity Complication", "Birth trauma", "Neonatal Asphyxia", "Respiratory distress", "Pneumonia", "Neonatal Septicaemia", "Malaria", "Haemorrhage", "Dehydration", "Diarrhoea", "Stillbirth (fresh)", "Stillbirth (macerated)", "Stillbirth", "Congenital hydrocephalus and spinal bifida", "Congenital malformation of the heart", "Other congenital malformation", "Sudden infant death syndrome", "Accidental poisoning by and exposure to noxious substances", "Assault", "Abortion", "Severe Hypertension in pregnancy/ eclampsia", "Antepartum Haemorrhage", "Obstructed Labour", "Rupture uterus", "Post-partum haemorrhage", "Unknown fever", "Local herbs", "Puerperal Sepsis /Septicaemia", "Malaria in pregnancy", "Pneumonia", "Anaemia in Pregnancy", "Pulmonary oedema", "Meningitis", "Cardiomyopathy", "Asymptomatic HIV", "Burns and corrosions of multiple body regions", "Burn and corrosion, body region unspecified", "Burns classified according to extent of body surface involved", "Corrosions classified according to extent of body surface involved", "Poisoning by diuretics and other unspecified drugs, medicaments and biological substances", "Toxic effect of alcohol", "Toxic effect of corrosive substances", "Toxic effect of metals", "Toxic effect of carbon monoxide", "Toxic effect of other gases, fumes and vapours", "Toxic effect of pesticides", "Toxic effect of other and unspecified substances", "Effects of heat and light", "Effects of air pressure and water pressure", "Asphyxiation", "Complications following infusion, transfusion and therapeutic injection", "Complications of procedures, not elsewhere classified", "Complications of genitourinary devices, implants and grafts", "Assault by other specified means", "Assault by other unspecified means", "Other Specified transport accidents", "Unspecified transport accidents", "Test ICD 10 Value")
  dat <- tibble(cod_code = icd_codes, cod_names = icd_names)
  return(dat)
}

# Function for generating the about page
make_about <- function(){
  fluidPage(
    fluidRow(
      div(img(src='www/logo.png', align = "center"), style="text-align: center;"),
      h4('Built in partnership with ',
         a(href = 'http://databrew.cc',
           target='_blank', 'Databrew'),
         align = 'center'),
      p('Empowering research and analysis through collaborative data science.', align = 'center'),
      div(a(actionButton(inputId = "email", label = "info@databrew.cc", 
                         icon = icon("envelope", lib = "font-awesome")),
            href="mailto:info@databrew.cc",
            align = 'center')), 
      style = 'text-align:center;'
    )
  )
}

# Plot theme
theme_va <- ggplot2::theme_bw

# Get database connection
get_db_connection <- function(local = FALSE){
  creds <- yaml::yaml.load_file('credentials/credentials.yaml')
  users <- yaml::yaml.load_file('credentials/users.yaml')
  drv <- RPostgres::Postgres()
  
  if(local){
    con <- dbConnect(drv, dbname = 'bohemia')
  } else {
    psql_end_point = creds$endpoint
    psql_user = creds$psql_master_username
    psql_pass = creds$psql_master_password
    con <- dbConnect(drv, dbname='bohemia', host=psql_end_point, 
                     port=5432,
                     user=psql_user, password=psql_pass)
  }

  return(con)
}
