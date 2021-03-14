#!/usr/bin/env Rscript

library(dplyr)
library(tidyr)
library(stringr)

SAVEPOINT_TYPE_COMPLETE <- 'COMPLETE'
SUITCASE_UPDATE_OP <- 'FORCE_UPDATE'

CONTACT_NUM_LENGTH <- 9
HH_ID_LENGTH <- 4 * 2 - 1
EXT_ID_LENGTH <- 4 * 3 - 1

HH_CSV_PATH <- 'odk_x_hh.csv'
MEMBER_CSV_PATH <- 'odk_x_member.csv'
GEO_LOCATION_CSV_PATH <- 'odk_x_geolocation.csv'

minicensus_data_path <- 'minicensus_data.RData'

add_metadata_col <- function(df, form_id) {
  if (!('_id') %in% colnames(df)) {
    # Add an empty _id column if there isn't one.
    # When the _id column is empty,
    # it will be populated with a generated UUID by ODK-X Suitcase on upload
    df <- df %>% tibble::add_column(`_id` = NA, .before = 1)
  }

  df %>%
    tibble::add_column(
      `_locale` = NA,
      `_savepoint_type` = SAVEPOINT_TYPE_COMPLETE,
      `_savepoint_timestamp` = NA,
      `_savepoint_creator` = NA,
      `_default_access` = NA,
      `_group_modify` = NA,
      `_group_privileged` = NA,
      `_group_read_only` = NA,
      `_row_etag` = NA,
      `_row_owner` = NA,
      .before = 1
    ) %>%
    tibble::add_column(`_form_id` = form_id, .before = 1) %>%
    tibble::add_column(operation = SUITCASE_UPDATE_OP, .before = 1)
}

# select_multiple fields are encoded as JSON array
format_select_multiple <- function(...) {
  str_c('["', str_c(..., collapse = '","'), '"]')
}

message('Loading minicensus data')
load(minicensus_data_path)

message('Processing clean_minicensus_main')
odk_x_hh <- out_list$clean_minicensus_main %>%
  distinct(hh_id, .keep_all = TRUE) %>%
  select(instance_id, hh_member_num, hh_head_id, hh_contact_info_number, hh_contact_info_number_alternate, hh_id, hh_geo_location) %>%
  filter(nchar(hh_id) == HH_ID_LENGTH) %>%
  mutate(across(
    c(
      hh_contact_info_number,
      hh_contact_info_number_alternate
    ),
    ~ case_when(nchar(.) == CONTACT_NUM_LENGTH ~ .)
  )) %>%
  mutate(hh_contact_no = case_when(is.na(hh_contact_info_number) ~ format_select_multiple('no_contact_num'))) %>%
  mutate(hh_contact_alt_no = case_when(is.na(hh_contact_info_number_alternate) ~ format_select_multiple('no_alt_contact_num'))) %>%
  mutate(hh_head_id = paste(hh_id, str_pad(hh_head_id, 3, pad = '0'), sep = '-')) %>%
  tibble::add_column(hh_minicenced = 'yes')

message('Processing geolocation')
odk_x_hh_geo_location <- odk_x_hh %>%
  select(hh_id, hh_geo_location) %>%
  separate(
    col = 'hh_geo_location',
    sep = ' ',
    into = c(
      'hh_geo_location_latitude',
      'hh_geo_location_longitude',
      'hh_geo_location_altitude',
      'hh_geo_location_accuracy'
    )
  )

# TODO: merge substitute
odk_x_hh_sub <- out_list$clean_minicensus_repeat_hh_sub %>%
  filter(hh_sub_count == 1) %>%
  select(instance_id, hh_sub_id, hh_sub_relationship)

message('Processing clean_minicensus_people')
odk_x_member <- out_list$clean_minicensus_people %>%
  distinct(instance_id, pid, .keep_all = TRUE) %>%
  select(
    instance_id,
    first_name,
    last_name,
    pid,
    dob,
    gender,
    member_resident
  ) %>%
  inner_join(
    select(odk_x_hh, instance_id, hh_id),
    by = 'instance_id'
  ) %>%
  filter(nchar(pid) == EXT_ID_LENGTH) %>%
  mutate(member_resident = recode(
    member_resident,
    `Resident Member` = 'resident',
    `Non-resident Member` = 'non_resident'
  )) %>%
  mutate(
    dob_day = as.numeric(format(dob, '%d')),
    dob_month = as.numeric(format(dob, '%m')),
    dob_year = as.numeric(format(dob, '%Y'))
  ) %>%
  select(-instance_id, -dob)

# Add UUID for individuals
# The UUID needs to be generated here to populate the HH head column in the HH table
message('Generating UUIDs')
odk_x_member <- tibble::add_column(
  odk_x_member,
  `_id` = paste0('uuid:', uuid::UUIDgenerate(n = nrow(odk_x_member))),
  .before = 1
)

# Note that some hh_head_id cannot be found in the member table
message('Writing CSVs')
odk_x_hh <- odk_x_hh %>%
  left_join(
    select(rename(odk_x_member, hh_head_uuid = `_id`), pid, hh_head_uuid),
    by = c('hh_head_id' = 'pid')
  ) %>%
  select(-hh_head_id) %>%
  rename(hh_head_id = hh_head_uuid)

# Rename columns and write to CSV
odk_x_hh %>%
  rename(
    `_id` = instance_id,
    minicensed_hh_n_residents = hh_member_num,
    hh_head_new_select = hh_head_id,
    hh_contact = hh_contact_info_number,
    hh_contact_alt = hh_contact_info_number_alternate
  ) %>%
  select(-hh_geo_location) %>%
  add_metadata_col('census') %>%
  write.csv(HH_CSV_PATH, na = '', row.names = FALSE, fileEncoding = 'UTF-8')

odk_x_member %>%
  rename(
    name = first_name,
    surname = last_name,
    id = pid,
    resident_status = member_resident
  ) %>%
  add_metadata_col('hh_member') %>%
  write.csv(MEMBER_CSV_PATH, na = '', row.names = FALSE, fileEncoding = 'UTF-8')

odk_x_hh_geo_location %>%
  add_metadata_col('hh_geo_location') %>%
  write.csv(GEO_LOCATION_CSV_PATH, na = '', row.names = FALSE, fileEncoding = 'UTF-8')
