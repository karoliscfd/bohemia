#!/usr/bin/env Rscript

library(dplyr)
library(tidyr)
library(stringr)

SAVEPOINT_TYPE_COMPLETE <- 'COMPLETE'
SUITCASE_UPDATE_OP <- 'FORCE_UPDATE'

CONTACT_NUM_LENGTH <- 9
HH_ID_LENGTH <- 4 * 2 - 1
EXT_ID_LENGTH <- 4 * 3 - 1

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

migrate_to_odk_x <- function(
  out_list,
  full_migration = FALSE,
  hh_csv_path = 'odk_x_hh.csv',
  member_csv_path = 'odk_x_member.csv',
  geo_location_csv_path = 'odk_x_geolocation.csv',
  death_csv_path = 'odk_x_death.csv'
) {
  message('Processing clean_minicensus_main')
  hh_col <- c(
    'instance_id',
    'hh_member_num',
    'hh_head_id',
    'hh_contact_info_number',
    'hh_contact_info_number_alternate',
    'hh_id',
    'hh_geo_location'
  )

  if (full_migration) {
    hh_col <- c(
      hh_col,
      'hh_animals_distance_cattle_dry_season',
      'hh_animals_distance_cattle_rainy_season',
      'hh_animals_dry_season_distance_pigs',
      'hh_animals_rainy_season_distance_pigs',
      'hh_animals_where_cattle_rainy_season',
      'hh_animals_where_cattle_dry_season',
      'hh_animals_rainy_season_pigs',
      'hh_animals_dry_season_pigs',
      'hh_main_building_type',
      'hh_main_energy_source_for_lighting',
      'hh_main_wall_material',
      'hh_n_constructions',
      'hh_n_constructions_sleep'
    )
  }

  odk_x_hh <- out_list$clean_minicensus_main %>%
    distinct(hh_id, .keep_all = TRUE) %>%
    select(all_of(hh_col)) %>%
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

  if (full_migration) {
    odk_x_hh <- odk_x_hh %>%
      mutate(across(
        c(
          hh_animals_where_cattle_rainy_season,
          hh_animals_where_cattle_dry_season,
          hh_animals_rainy_season_pigs,
          hh_animals_dry_season_pigs
        ),
        ~ recode(
          .,
          `Inside the compound but not inside a structure, but more than 15 meters from the house` = 'Inside the compound but not inside a structure, but >15 meters from the house',
          `Inside the compound but not inside a structure, within 15 meters from the house` = 'Inside the compound but not inside a structure within 15 meters from the household',
          `There is no fixed space to house them` = 'Unspecified location for keeping them'
        )
      )) %>%
      separate(
        col = 'hh_main_wall_material',
        sep = 'other',
        fill = 'right',
        into = c('house_wall_material', 'house_wall_material_other')
      ) %>%
      mutate(house_wall_material = ifelse(
        is.na(house_wall_material_other),
        house_wall_material,
        paste0(house_wall_material, 'other')
      )) %>%
      mutate(across(
        c('house_wall_material', 'house_wall_material_other'),
        ~ str_trim(.)
      )) %>%
      mutate(house_wall_material = sapply(str_split(house_wall_material, pattern = ' '), format_select_multiple)) %>%
      left_join(
        select(rename(out_list$clean_minicensus_repeat_water, water_bodies_num = num), instance_id, water_bodies_num),
        by = 'instance_id'
      ) %>%
      left_join(
        select(rename(out_list$clean_minicensus_repeat_mosquito_net, hh_num_nets = num), instance_id, hh_num_nets),
        by = 'instance_id'
      )
  }

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

  message('Processing clean_minicensus_repeat_hh_sub')
  odk_x_hh_sub <- out_list$clean_minicensus_repeat_hh_sub %>%
    filter(!is.na(hh_sub_id)) %>%
    inner_join(
      select(odk_x_hh, instance_id, hh_id),
      by = 'instance_id'
    ) %>%
    mutate(hh_sub_id = paste(hh_id, str_pad(hh_sub_id, 3, pad = '0'), sep = '-'))

  if (full_migration) {
    odk_x_hh_sub <- odk_x_hh_sub %>%
      mutate(hh_sub_relationship = recode(
        hh_sub_relationship,
        husband_or_wife = 'husband_wife',
        son_or_daughter = 'son_daughter',
        brother_or_sister = 'brother_sister',
        father = 'father_mother',
        mother = 'father_mother',
        son_or_daughter_in_law = 'son_daughterinlaw',
        brother_or_sister_in_law = 'brother_sisterinlaw',
        uncle_or_aunt = 'uncle_aunt',
        grandson_or_granddaughter = 'grandson_granddaughter',
        adopted_son_or_daughter = 'adopted_son_daughter',
        newphew_or_niece = 'nephew_niece'
      ))
  }

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

  if (full_migration) {
    message('Processing clean_minicensus_repeat_death_info')
    odk_x_death <- out_list$clean_minicensus_repeat_death_info %>%
      filter(!is.na(death_id)) %>%
      select(
        instance_id,
        death_age,
        death_age_unit,
        death_dob_unknown,
        death_dod,
        death_gender,
        death_id,
        death_name,
        death_surname
      ) %>%
      mutate(death_age = ifelse(death_age_unit == 'Years' | is.na(death_age_unit), death_age, 0)) %>%
      mutate(death_age = coalesce(death_age, death_dob_unknown)) %>%
      mutate(death_dod = format(death_dod, '%Y-%m-%d')) %>%
      mutate(hh_death_date_dk = ifelse(is.na(death_dod), format_select_multiple('dk'), NA)) %>%
      inner_join(
        select(odk_x_hh, instance_id, hh_id),
        by = 'instance_id'
      ) %>%
      select(-death_age_unit, -death_dob_unknown, -instance_id)
  }

  # Add UUID for individuals
  # The UUID needs to be generated here to populate the HH head column in the HH table
  message('Generating UUIDs')
  odk_x_member <- tibble::add_column(
    odk_x_member,
    `_id` = paste0('uuid:', uuid::UUIDgenerate(n = nrow(odk_x_member))),
    .before = 1
  )

  # Note that some hh_head_id cannot be found in the member table
  message('Processing HH head and HH head sub')
  odk_x_hh <- odk_x_hh %>%
    left_join(
      select(odk_x_hh_sub, instance_id, hh_sub_id, hh_sub_relationship),
      by = 'instance_id'
    ) %>%
    left_join(
      select(rename(odk_x_member, hh_head_uuid = `_id`), pid, hh_head_uuid),
      by = c('hh_head_id' = 'pid')
    ) %>%
    left_join(
      select(rename(odk_x_member, hh_sub_uuid = `_id`), pid, hh_sub_uuid),
      by = c('hh_sub_id' = 'pid')
    ) %>%
    select(-hh_head_id, -hh_sub_id) %>%
    rename(
      hh_head_id = hh_head_uuid,
      hh_sub_id = hh_sub_uuid
    ) %>%
    mutate(no_hh_head_sub = ifelse(is.na(hh_sub_id), format_select_multiple('no_sub'), NA))

  if (!full_migration) {
    odk_x_hh <- odk_x_hh %>% select(-hh_sub_relationship)
  }

  message('Deleting CSVs')
  all_csv <- c(hh_csv_path, member_csv_path, geo_location_csv_path, death_csv_path)
  removedCsvs <- sum(file.remove(all_csv[sapply(all_csv, file.exists)]))
  message('Deleted ', removedCsvs, ' CSVs')

  # Rename columns and write to CSV
  message('Writing CSVs')

  odk_x_hh <- odk_x_hh %>% rename(
    `_id` = instance_id,
    minicensed_hh_n_residents = hh_member_num,
    hh_head_new_select = hh_head_id,
    hh_head_sub_new_select = hh_sub_id,
    hh_contact = hh_contact_info_number,
    hh_contact_alt = hh_contact_info_number_alternate
  )

  if (full_migration) {
    odk_x_hh <- odk_x_hh %>% rename(
      distance_cattle_rainy_season = hh_animals_distance_cattle_rainy_season,
      distance_cattle_dry_season = hh_animals_distance_cattle_dry_season,
      distance_pigs_rainy_season = hh_animals_rainy_season_distance_pigs,
      distance_pigs_dry_season = hh_animals_dry_season_distance_pigs,
      where_cattle_rainy_season = hh_animals_where_cattle_rainy_season,
      where_cattle_dry_season = hh_animals_where_cattle_dry_season,
      where_pigs_rainy_season = hh_animals_rainy_season_pigs,
      where_pigs_dry_season = hh_animals_dry_season_pigs,
      house_building_type = hh_main_building_type,
      main_energy_lighting = hh_main_energy_source_for_lighting,
      num_houses = hh_n_constructions,
      num_houses_sleep = hh_n_constructions_sleep
    )
  }

  odk_x_hh %>%
    mutate(`_id` = str_c('uuid:', `_id`)) %>%
    select(-hh_geo_location) %>%
    add_metadata_col('census') %>%
    write.csv(hh_csv_path, na = '', row.names = FALSE, fileEncoding = 'UTF-8')

  odk_x_member %>%
    rename(
      name = first_name,
      surname = last_name,
      id = pid,
      resident_status = member_resident
    ) %>%
    add_metadata_col('hh_member') %>%
    write.csv(member_csv_path, na = '', row.names = FALSE, fileEncoding = 'UTF-8')

  odk_x_hh_geo_location %>%
    add_metadata_col('hh_geo_location') %>%
    write.csv(geo_location_csv_path, na = '', row.names = FALSE, fileEncoding = 'UTF-8')

  if (full_migration) {
    odk_x_death %>%
      rename(
        hh_death_id = death_id,
        hh_death_name = death_name,
        hh_death_surname = death_surname,
        hh_death_gender = death_gender,
        hh_death_date = death_dod,
        hh_death_age = death_age
      ) %>%
      add_metadata_col('hh_death') %>%
      write.csv(death_csv_path, na = '', row.names = FALSE, fileEncoding = 'UTF-8')
  }
}

message('Loading minicensus data')
load('minicensus_data.RData')

migrate_to_odk_x(out_list = out_list, full_migration = FALSE)
