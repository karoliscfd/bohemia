# Library in packages used in this application
library(shiny)
library(DT)
library(DBI)
library(RSQLite)
library(shinyjs)
library(shinycssloaders)
library(lubridate)
library(shinyFeedback)
library(dplyr)
library(dbplyr)

db_config <- config::get()$db

# Create database connection
conn <- dbConnect(
  RSQLite::SQLite(),
  dbname = db_config$dbname
)


create_records_query = "CREATE TABLE records (
  uid                             TEXT PRIMARY KEY,
  country                          TEXT,
  first_name                       TEXT,
  last_name                        TEXT,
  institution                      TEXT,
  position                         TEXT,
  email                            TEXT,
  phone                            TEXT,
  notes                            TEXT
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
df$notes <- NA
df$notes <-  as.character(df$notes)
df$notes[9] <- ""

df <- df %>%
  select(uid, everything())


DBI::dbWriteTable(
  conn,
  name = "records",
  value = df,
  overwrite = FALSE,
  append = TRUE
)


# Stop database connection when application stops
shiny::onStop(function() {
  dbDisconnect(conn)
})


# Turn off scientific notation
options(scipen = 999)


# Set spinner type (for loading)
options(spinner.type = 8)
