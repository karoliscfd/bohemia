
<!-- README.md is generated from README.Rmd. Please edit that file -->

# VA Tool

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

## Installation

To install from github,
    run:

    devtools::install_github('databrew/bohemia', subdir = 'rpackage/bohemia')

## Setting up back-end

You’ll need to set up a back-end. In order to this, create a postgres
database named `va`:

    psql
    create database va;
    exit

Then go into the psql cli in va:

    psql va

and copy-paste the code from `set_up_database.sql`

Then, in order to create fake data, run:

    Rscript create_fake_data.R

## Credentials

Save a `credentials/credentials.yaml` in `dev`.

## Development

To run locally, run:

    cd dev
    Rscript run_dev.R
