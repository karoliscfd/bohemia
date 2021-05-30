#' Records Table Module UI
#'
#' The UI portion of the module for displaying the records datatable
#'
#' @importFrom shiny NS tagList fluidRow column actionButton tags
#' @importFrom DT DTOutput
#' @importFrom shinycssloaders withSpinner
#'
#' @param id The id for this module
#'
#' @return a \code{shiny::\link[shiny]{tagList}} containing UI elements
#'
records_table_module_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(
        width = 12,
        title = "Table records",
        div(class = "materialBox",
          DTOutput(ns('record_table')) %>%
            withSpinner()
        ),
        tags$br(),
        tags$br()
      )
    ),
    tags$script(src = "records_table_module.js"),
    tags$script(paste0("records_table_module_js('", ns(''), "')"))
  )
}

#' Records Table Module Server
#'
#' The Server portion of the module for displaying the records datatable
#'
#' @importFrom shiny reactive reactiveVal observeEvent req callModule eventReactive
#' @importFrom DT renderDT datatable replaceData dataTableProxy
#' @importFrom dplyr tbl collect mutate arrange select filter pull
#' @importFrom purrr map_chr
#' @importFrom tibble tibble
#'
#' @param None
#'
#' @return None

records_table_module <- function(input, output, session) {

  # trigegr to reload data from the "records" table
  session$userData$records_trigger <- reactiveVal(0)

  # Read in "records" table from the database
  records <- reactive({
    session$userData$records_trigger()

    out <- NULL
    tryCatch({
      out <- conn %>%
        tbl('records') %>%
        collect() 
    }, error = function(err) {


      msg <- "Database Connection Error"
      # print `msg` so that we can find it in the logs
      print(msg)
      # print the actual error to log it
      print(error)
      # show error `msg` to user.  User can then tell us about error and we can
      # quickly identify where it cam from based on the value in `msg`
      showToast("error", msg)
    })

    out
  })


  record_table_prep <- reactiveVal(NULL)

  observeEvent(records(), {
    out <- records()

    ids <- out$uid

    actions <- purrr::map_chr(ids, function(id_) {
      paste0(
        '<div class="btn-group" style="width: 50px;" role="group" aria-label="Basic example">
          <button class="btn btn-primary btn-sm edit_btn" data-toggle="tooltip" data-placement="top" title="Edit" id = ', id_, ' style="margin: 0"><i class="fa fa-pencil-square-o"></i></button>
        </div>'
      )
    })

    # Remove the `uid` column. We don't want to show this column to the user
    out <- out %>%
      select(-uid)

    # Set the Action Buttons row to the first column of the `records` table
    out <- cbind(
      tibble(" " = actions),
      out
    )

    if (is.null(record_table_prep())) {
      # loading data into the table for the first time, so we render the entire table
      # rather than using a DT proxy
      record_table_prep(out)

    } else {

      # table has already rendered, so use DT proxy to update the data in the
      # table without rerendering the entire table
      replaceData(record_table_proxy, out, resetPaging = FALSE, rownames = FALSE)

    }
  })

  output$record_table <- renderDT({
    req(record_table_prep())
    out <- record_table_prep()

    # datatable(out,
    #           # editable = 'cell',
    #           # callback = JS('trianglegirl_function();'),
    #           # Escape the HTML in all except 1st column (which has the buttons)
    #           escape = -1,
    #           extensions = 'Buttons',
    #           selection = "none",
    #           filter = 'top',
    #           options = list(pageLength = 15, info = FALSE, dom='Bfrtip', buttons = list('csv'))
    # )
    
    datatable(
      out,
      rownames = FALSE,
      colnames = c('Country', 'First name', 'Last name', 'Institution', 'Position', 'Email', 'Phone', 'Notes'),
      selection = "none",
      # class = "compact stripe row-border nowrap",
      # Escape the HTML in all except 1st column (which has the buttons)
      escape = -1,
      extensions = c("Buttons"),
      filter = 'top',
      options = list(
        # scrollX = TRUE,
        filter = 'top',
        dom = 'Blfrtip',
        filter = "top",
        pageLength = 10,
        lengthChange = TRUE,
        lengthMenu = list(c(10, 50, -1), c("10", "50", "All")),
        info = TRUE,
        buttons = list(
          list(
            extend = "csv",
            text = "Download",
            title = paste0("records-", Sys.Date()),
            exportOptions = list(
              columns = 1:(length(out) - 1)
            )
          )
        ),
        autoWidth = TRUE,
        columnDefs = list(
          # list(targets = 0, orderable = FALSE,),
          list(width = '200px', targets = "_all", searchable = TRUE)
        ),
        drawCallback = JS("function(settings) {
          // removes any lingering tooltips
          $('.tooltip').remove()
        } ")
      )
    )

  })

  record_table_proxy <- DT::dataTableProxy('record_table')


  record_to_edit <- eventReactive(input$record_id_to_edit, {

    records() %>%
      filter(uid == input$record_id_to_edit)
  })

  callModule(
    record_edit_module,
    "edit_record",
    modal_title = "Record Edit",
    record_to_edit = record_to_edit,
    modal_trigger = reactive({input$record_id_to_edit})
  )


}
