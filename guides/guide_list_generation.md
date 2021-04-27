# List generation

## Context 

For reasons of operational guidance, internal accountability, and data capture efficiency, Bohemia field sites require the ability to automatically generate "lists". These lists are generated locally by data managers so as to include names data. This document contains instructions for generating those lists.


## Prerequisites

In order to generate lists, you need a private and public key on your system, as per the [schema for handling names data](https://github.com/databrew/bohemia/blob/master/misc/handling_names.md). These files should be named as follows:

- `bohemia_pub.pem`
- `bohemia_priv.pem`

It is important that you never share these files with anyone, nor put them in any location where they might be accessed by someone other than you. If you do not have these files on your system, please contact bohemia@databrew.cc.

## Visit control sheet

To generate the visit control sheet, run the following code:

```
priv_key <- 'bohemia_priv.pem' # change to path to your local file
pub_key <- 'bohemia_pub.pem' # change to path to your local file

list_generation_visit_control(keyfile = priv_key,
                              keyfile_public = pub_key,
                              location = 'CUD',
                              output_file = NULL)
```

Note that the `location` argument can be set to the 3 letter hamlet code for one location. Alternatively, you can set to `NULL` (in which case ALL locations will be rendered) or to multiple locations by passing a character vector of length >1 (for example, `c('KLD, 'DIM', 'KRE', 'NWE')`).

If the `output_file` argument is left as `NULL` (the default), the function will return an in-memory dataframe for further manipulation. Alternatively, pass a path to any not yet existent file with a `.csv` extension, and the function will instead write a csv locally.

# VA consent verification list

To generate a VA consent verification list, run the following code:

```
priv_key <- 'bohemia_priv.pem' # change to path to your local file
pub_key <- 'bohemia_pub.pem' # change to path to your local file

list_generation_va_consent_verification(keyfile = priv_key,
                              keyfile_public = pub_key,
                              location = 'CUD',
                              output_file = NULL)
```

Note that the `location` argument can be set to the 3 letter hamlet code for one location. Alternatively, you can set to `NULL` (in which case ALL locations will be rendered) or to multiple locations by passing a character vector of length >1 (for example, `c('KLD, 'DIM', 'KRE', 'NWE')`).

If the `output_file` argument is left as `NULL` (the default), the function will return an in-memory dataframe for further manipulation. Alternatively, pass a path to any not yet existent file with a `.csv` extension, and the function will instead write a csv locally.


