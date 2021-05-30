function(input, output, session) {
  
  # Use session$userData to store user data that will be needed throughout
  # the Shiny application

  # Call the server function portion of the `records_table_module.R` module file
  callModule(
    records_table_module,
    "records_table"
  )

}
