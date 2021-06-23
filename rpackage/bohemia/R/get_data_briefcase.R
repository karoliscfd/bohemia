#' Get data briefcase
#' 
#' Get the unique 3 letter location given a location
#' @param url Country
#' @param id Region
#' @param user District
#' @param password Ward
#' @param briefcase_dir Village
#' @param jar_file_briefcase Hamlet
#' @param briefcase_storage_dir Allow the all option
#' @param dry_run Whether to just print the java cli code (rather than actually run it)
#' @return Writes objects
#' @import dplyr
#' @export
get_data_briefcase <- function(url,
                               id,
                               user,
                               password,
                               briefcase_dir,
                               jar_file_briefcase,
                               briefcase_storage_dir,
                               dry_run = FALSE){
  owd <- getwd()
  setwd(briefcase_dir)
  cli_text <- paste0(
    'java -jar ',
    jar_file_briefcase, ' --pull_aggregate',
    ' -U ', url,
    ' -u ', user,
    ' -p ', password,
    ' -id ', id,
    ' -sd ', briefcase_storage_dir,
    ' -e ',
    ' -ed ', briefcase_storage_dir,
    ' -ef ', paste0(id, '.csv')
  )
  message(cli_text)
  if(!dry_run){
    system(cli_text)
  }
  setwd(owd)
}