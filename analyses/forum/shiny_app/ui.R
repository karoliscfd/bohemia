fluidPage(
  shinyFeedback::useShinyFeedback(),
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  # Application Title
  titlePanel(
    h1("Contact list", align = 'center', style = "text-transform: uppercase; color: #337ab7;"),
    windowTitle = "Forum"
  ),
  records_table_module_ui("records_table")
)

