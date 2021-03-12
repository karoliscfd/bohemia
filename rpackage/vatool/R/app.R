
##################################################
# UI
##################################################
#' @import shiny
#' @import shinydashboard
#' @import leaflet
#' @import shiny
#' @import ggplot2
#' @import gsheet
#' @import DT
#' @import shinyMobile
#' @import DBI
#' @import RPostgres
app_ui <- function(request) {
  options(scipen = '999')

  tagList(
    mobile_golem_add_external_resources(),

    dashboardPage(
      dashboardHeader (title = "Bohemia VA tool"),
      dashboardSidebar(
        sidebarMenu(
          menuItem(
            text="Main",
            tabName="main"),
          menuItem(
            text = 'About',
            tabName = 'about')
        )),
      dashboardBody(
        tags$head(
          tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
        ),
        tabItems(
          tabItem(
            tabName="main",
            fluidPage(
              uiOutput('top_button'),
              uiOutput('ui_main'),
              fluidRow(
                column(8,
                       uiOutput('ui_select_va')),
                column(4,
                       uiOutput('ui_assign_cod'))
              ),
              fluidRow(
                column(12,
                       DT::dataTableOutput('va_table'))
              )
            )
          ),
          tabItem(
            tabName = 'about',
            make_about()
          )
        )
      )
    )
  )
}



##################################################
# SERVER
##################################################
#' @import shiny
#' @import leaflet
app_server <- function(input, output, session) {
  is_local <- TRUE
  logged_in <- reactiveVal(value = FALSE)
  
  data <- reactiveValues(va = data.frame())
  
  # Upon log in, read in data
  observeEvent(input$log_in,{
    logged_in(TRUE)
    removeModal()
    # Connect to database
    message('Connecting to database : ', ifelse(is_local, ' local', 'remote'))
    con <- get_db_connection(local = is_local)
    data$va <- load_va_data()
  })

  # Define the button
  output$top_button <- renderUI({
    li <- logged_in()
    if(li){
      actionButton("log_out", "Log out")
    } else {
      actionButton("show", "Log in")
    }
  })
  
  # Define the placeholder main ui
  output$ui_main <- renderUI({
    li <- logged_in()
    if(li){
      fluidPage(h1('Logged in'))
    } else {
      fluidPage(h1('Not logged in'))
    }
  })
  
  # Selection input for VA ID
  output$ui_select_va <- renderUI({
    li <- logged_in()
    if(li){
      pd <- data$va
      choices <- pd$death_id
      selectInput('death_id', 'VA ID', choices = choices, selected = choices[1])
    } else {
      NULL
    }
  })
  
  output$ui_assign_cod <- renderUI({
    li <- logged_in()
    if(li){
      icd_codes <- c('A00', 'A01', 'A01', 'A06', 'A09', 'A15', 'A16', 'A20', 'A33', 'A41', 'A75', 'B05', 'B24', 'B45', 'B53', 'B54', 'C80', 'G03', 'G04', 'G83', 'I50', 'J06', 'J18', 'J45', 'J81', 'J98', 'K75', 'L08', 'R09', 'R50', 'S09', 'S36', 'T14', 'T14.9', 'T30', 'C22', 'C46', 'C50', 'C55', 'C61', 'C80', 'D48', 'E14', 'I10', 'I42', 'I64', 'A80', 'K25', 'K29', 'K37', 'K46', 'K56', 'K65', 'K74', 'K75', 'K92', 'M86', 'M89', 'N04', 'N05', 'N15', 'N39', 'N94', 'B24', 'P05', 'P15', 'P21', 'P22', 'P23', 'P36', 'P37', 'P54', 'P74', 'P78', 'P95', 'P95', 'P95', 'Q05', 'Q24', 'Q89', 'R95', 'X49', 'Y09', 'O06', 'O16/O15', 'O46', 'O66', 'O71', 'O72', 'O75', 'O75', 'O85', 'O98', 'O99', 'O99', 'O99', 'O99', 'O99.4', 'Z21', 'T29', 'T30', 'T31', 'T32', 'T50', 'T51', 'T54', 'T56', 'T58', 'T59', 'T60', 'T65', 'T67', 'T70', 'T71', 'T80', 'T81', 'T83', 'Y08', 'Y09', 'V98', 'V99', 'V99')
      icd_names <- c("Cholera", "Typhoid fever (salmonellosis)", "Typhoid", "Dysentery Acute/Chronic", "Diarrhoea", "TB Confirmed", "TB Not confirmed", "Plague", "Tetanus, Neonatal", "Septicaemia", "Relapsing Fever (Louse borne Typhus)", "Measles", "HIV and AIDS", "Meningitis Cryptococal", "Malaria confirmed", "Malaria presumptive", "Neoplasm", "Meningitis", "Encephalitis", "Acute Flaccid Paralysis", "Heart failure", "Respiratory Infection Acute (ARI)", "Pneumonia", "Asthma", "Pulmonary oedema", "Pneumopathies", "Hepatitis", "Skin infections", "Pleurisy (non-Tuberculosis)", "Fever Chronic (> 1 month)", "Head injury", "Ruptured spleen", "Fractures", "Trauma Other", "Burns", "Cancer Liver", "Kaposi's sarcoma", "Cancer Breast", "Cancer Uterine", "Cancer Prostate", "Tumours Other malignant", "Tumours Other non-malignant", "Diabetes", "Hypertension", "Cardiomyopathy", "Cerebrovascular accident", "Acute Flacid Paralysis (polio)", "Ulcer, gastro-duodenal", "Gastritis", "Appendicitis", "Hernia", "Intestinal occlusion", "Peritonitis (non-Tuberculosis)", "Cirrhosis of the liver", "Hepatitis", "Digestive tract Haemorrhages", "Bone infections (including osteomyelitis)", "Bone and joint disease other", "Nephrotic syndrome", "Glomerulonephritis", "Kidney infections", "Urinary tract infections", "Gynecological problems", "Paediatric AIDS", "Low birth weight or Prematurity Complication", "Birth trauma", "Neonatal Asphyxia", "Respiratory distress", "Pneumonia", "Neonatal Septicaemia", "Malaria", "Haemorrhage", "Dehydration", "Diarrhoea", "Stillbirth (fresh)", "Stillbirth (macerated)", "Stillbirth", "Congenital hydrocephalus and spinal bifida", "Congenital malformation of the heart", "Other congenital malformation", "Sudden infant death syndrome", "Accidental poisoning by and exposure to noxious substances", "Assault", "Abortion", "Severe Hypertension in pregnancy/ eclampsia", "Antepartum Haemorrhage", "Obstructed Labour", "Rupture uterus", "Post-partum haemorrhage", "Unknown fever", "Local herbs", "Puerperal Sepsis /Septicaemia", "Malaria in pregnancy", "Pneumonia", "Anaemia in Pregnancy", "Pulmonary oedema", "Meningitis", "Cardiomyopathy", "Asymptomatic HIV", "Burns and corrosions of multiple body regions", "Burn and corrosion, body region unspecified", "Burns classified according to extent of body surface involved", "Corrosions classified according to extent of body surface involved", "Poisoning by diuretics and other unspecified drugs, medicaments and biological substances", "Toxic effect of alcohol", "Toxic effect of corrosive substances", "Toxic effect of metals", "Toxic effect of carbon monoxide", "Toxic effect of other gases, fumes and vapours", "Toxic effect of pesticides", "Toxic effect of other and unspecified substances", "Effects of heat and light", "Effects of air pressure and water pressure", "Asphyxiation", "Complications following infusion, transfusion and therapeutic injection", "Complications of procedures, not elsewhere classified", "Complications of genitourinary devices, implants and grafts", "Assault by other specified means", "Assault by other unspecified means", "Other Specified transport accidents", "Unspecified transport accidents", "Test ICD 10 Value")
      choices <- icd_codes
      names(choices) <- icd_names
      fluidPage(
        fluidRow(
          selectInput('cod', 'Cause of death', choices = choices, selected = choices[1])
        ),
        fluidRow(
          actionButton('submit_cod', 'Submit')
        )
      )
    } else {
      NULL
    }
  })
  
  output$va_table <- DT::renderDataTable({
    li <- logged_in()
    out <- NULL
    if(li){
      idi <- input$death_id
      if(!is.null(idi)){
        pd <- data$va
        person <- pd %>% filter(death_id == idi)
        out <- 
          tibble(Variable = names(person),
                 Response = as.character(person[1,]))
      }
    } 
    out
  })

  observeEvent(input$show, {
    # logged_in(TRUE)
    showModal(modalDialog(
      title = "Log in",
      fluidPage(
        fluidRow(
          column(6,
                 textInput('email', 'Email')),
          column(6,
                 passwordInput('password', 'Password'))
        ),
        fluidRow(
          actionButton('log_in', 'Log in')
        )
      )
    ))
  })
  observeEvent(input$log_out, {
    logged_in(FALSE)
  })
  
  # Observe submission of cause of death and save
  observeEvent(input$submit_cod, {
    message('COD submitted, need to do some stuff here...')
  })

  session$onSessionEnded(function(){
    cat(paste0('Session ended.'))
    if(exists('con')){
      dbDisconnect(con)
      cat(paste0('Disconnected from database.'))
    }
  })


}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
mobile_golem_add_external_resources <- function(){
  addResourcePath(
    'www', system.file('app/www', package = 'vatool')
  )


  share <- list(
    title = "Bohemia VA Tool",
    url = "https://bohemia.team/va/",
    image = "https://www.databrew.cc/images/logo_clear.png",
    description = "Bohemia app",
    twitter_user = "data_brew"
  )

  tags$head(
    tags$link(rel="stylesheet", type="text/css", href="www/custom.css")
  )
}

app <- function(){
  # Detect the system. If on AWS, don't launch browswer
  is_aws <- grepl('aws', tolower(Sys.info()['release']))
  shinyApp(ui = app_ui,
           server = app_server,
           options = list('launch.browswer' = !is_aws))
}
