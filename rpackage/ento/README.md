
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ento

<!-- README.md is generated from README.Rmd. Please edit that file -->

# ento: The R package of the Bohemia entomology protocol

This package contains utilities used by the Bohemia entomology research
team. It is publicly available for the purposes of reproducibility and
transparency.

## Installation

One can install directly from
github:

``` r
devtools::install_github('databrew/bohemia', subdir = 'rpackage/ento', dependencies = TRUE, force = TRUE)
```

To remove the package (for example, so as to re-install for an update),
simply run: \`remove.packages(‘ento’)

## Setting up credentials

`cd` into `rpackage/ento/dev` and create a directory called
`credentials`. Populate that with your (secret) credentials files,
including `bohemiacensuss3credentials.csv`

## Data flow

  - Data for this app is read from an AWS S3 bucket. That bucket gets
    updated by running `scripts/ento/get_ento_forms.R`.
