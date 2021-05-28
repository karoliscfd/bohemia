
#' Record Add & Edit Module
#'
#' Module to add & edit records in the records database file
#'
#' @importFrom shiny observeEvent showModal modalDialog removeModal fluidRow column textInput numericInput selectInput modalButton actionButton reactive eventReactive
#' @importFrom shinyFeedback showFeedbackDanger hideFeedback showToast
#' @importFrom shinyjs enable disable
#' @importFrom lubridate with_tz
#' @importFrom uuid UUIDgenerate
#' @importFrom DBI dbExecute
#'
#' @param modal_title string - the title for the modal
#' @param record_to_edit reactive returning a 1 row data frame of the record to edit
#' from the "records" table
#' @param modal_trigger reactive trigger to open the modal (Add or Edit buttons)
#'
#' @return None
#'
record_edit_module <- function(input, output, session, modal_title, record_to_edit, modal_trigger) {
  ns <- session$ns

  observeEvent(modal_trigger(), {
    hold <- record_to_edit()

    showModal(
      modalDialog(
        fluidRow(
          column(
            width = 12,
            textInput(
              ns("country"),
              'Country',
              value = ifelse(is.null(hold), "", hold$country)
            ),
            textInput(
              ns("first_name"),
              'First Name',
              value = ifelse(is.null(hold), "", hold$first_name)
            ),
            textInput(
              ns("last_name"),
              'Last Name',
              value = ifelse(is.null(hold), "", hold$last_name)
            ),
            textAreaInput(
              ns("institution"),
              'Institution',
              value = ifelse((is.na(hold$institution) || is.null(hold)), "", hold$institution)
            ),
            textInput(
              ns("position"),
              'Position',
              value = ifelse(is.null(hold), "", hold$position)
            ),
            textInput(
              ns("email"),
              'Email',
              value = ifelse(is.null(hold), "", hold$email)
            ),
            textInput(
              ns("phone"),
              'Phone',
              value = ifelse(is.null(hold), "", hold$phone)
            ),
            textAreaInput(
              ns("notes"),
              'Notes',
              value = ifelse((is.na(hold$notes) || is.null(hold)), "", hold$notes)
            )
            
          )
        ),
        title = modal_title,
        size = 'm',
        footer = list(
          modalButton('Cancel'),
          actionButton(
            ns('submit'),
            'Submit',
            class = "btn btn-primary",
            style = "color: white"
          )
        )
      )
    )

  })



  edit_record_dat <- reactive({
    hold <- record_to_edit()

    out <- list(
      uid = if (is.null(hold)) NA else hold$uid,
      data = list(
        "country" = input$country,
        "first_name" = input$first_name,
        "last_name" = input$last_name,
        "institution" = input$institution,
        "position" = input$position,
        "email" = input$email,
        "phone" = input$phone,
        "notes" = input$notes
      )
    )

    out
  })

  validate_edit <- eventReactive(input$submit, {
    dat <- edit_record_dat()

    # Logic to validate inputs...

    dat
  })

  observeEvent(validate_edit(), {
    removeModal()
    dat <- validate_edit()

    tryCatch({

      if (is.na(dat$uid)) {
        # creating a new record
        uid <- uuid::UUIDgenerate()

        dbExecute(
          conn,
          "INSERT INTO mtcars (uid, model, mpg, cyl, disp, hp, drat, wt, qsec, vs, am,
          gear, carb, created_at, created_by, modified_at, modified_by) VALUES
          ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)",
          params = c(
            list(uid),
            unname(dat$data)
          )
        )
      } else {
        # editing an existing record
        dbExecute(
          conn,
          "UPDATE records SET country=$1, first_name=$2, last_name=$3, institution=$4, position=$5, email=$6,
          phone=$7, notes=$8 WHERE uid=$9",
          params = c(
            unname(dat$data),
            list(dat$uid)
          )
        )
      }

      session$userData$records_trigger(session$userData$records_trigger() + 1)
      showToast("success", paste0(modal_title, " Successfully"))
    }, error = function(error) {

      msg <- paste0(modal_title, " Error")


      # print `msg` so that we can find it in the logs
      print(msg)
      # print the actual error to log it
      print(error)
      # show error `msg` to user.  User can then tell us about error and we can
      # quickly identify where it cam from based on the value in `msg`
      showToast("error", msg)
    })
  })

}
