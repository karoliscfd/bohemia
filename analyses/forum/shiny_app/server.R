function(input, output, session) {
  
  
  create_records_query = "CREATE TABLE records (
  uid                             TEXT PRIMARY KEY,
  country                          TEXT,
  first_name                       TEXT,
  last_name                        TEXT,
  institution                      TEXT,
  position                         TEXT,
  email                            TEXT,
  phone
)"
  
  # Drop the table if it already exists
  dbExecute(conn, "DROP TABLE IF EXISTS records")
  # Execute the query created above
  dbExecute(conn, create_records_query)
  
  if(!'df_forum.RData' %in% dir('/tmp')){
    df <- gsheet::gsheet2tbl('https://docs.google.com/spreadsheets/d/1qDxynnod4YZYzGP1G9562auOXzAq1nVn89EjeJYgL8k/edit#gid=0') 
    # removing details for now
    df$details <- NULL
    df <- df[, c("country", "first_name", "last_name", "institution", "position", "email", "phone")]
    save(df, file = '/tmp/df_forum.RData')
  } else {
    load('/tmp/df_forum.RData')
  }
  
  df$uid <- uuid::UUIDgenerate(n = nrow(df))
  
  df <- df %>%
    select(uid, everything())
  
  DBI::dbWriteTable(
    conn,
    name = "records",
    value = df,
    overwrite = FALSE,
    append = TRUE
  )
  
  

  # Use session$userData to store user data that will be needed throughout
  # the Shiny application

  # Call the server function portion of the `records_table_module.R` module file
  callModule(
    records_table_module,
    "records_table"
  )
  
  # session$allowReconnect("force")
}
