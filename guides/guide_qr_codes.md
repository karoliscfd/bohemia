_2021-05-01_

# Household QR code

## Context

During the minicensus, there were cases in which a single household identification number (ID) was assigned to more than one household. This causes both (a) operational problems as well as (b) data integrity problems (such as the issue of multiple individuals sharing a person ID). In order to reduce duplication, quick response (QR) codes will be used during the census.

## Purpose

The purpose of distributing a QR code to each household is two-fold:

1. The QR code is machine-readable / scannable, meaning that follow-up visits to the house can read the QR code so as to reduce ambiguiety and provide confirmation that the fieldworker is actually at the house in question.

2. The QR code, if printed on paper, is finite and unique. That is, there should be only one piece of paper for QR code `ABC-123`. This finite/unique characteristic is essential to reducing redundancy/duplication in that a fieldworker who correctly leaves code `ABC-123` at the corresponding household cannot, by definition, leave that same code at the next household.


## How to

QR codes can be generated ad-hoc via the script in this repo at `scripts/qr/generate_qr_codes.R`  By default, this script will generate both:
- One QR code for every household from which was data was collected in the minicensus.  
- One QR code for an addition `n_extra` (by default, 50) households for each hamlet (for newly enumerated/identified households).  
- In the case of a hamlet requiring more than 50 `n_extra` QR codes, that parameter can be changed:
   - This should be infrequent in Mozambique, since most hamlets will not have more than 50 "new" households.  
   - This may be more frequent in Tanzania, since some hamlets have no previous data collected in the minicensus.


## Caveats and gotchas  

- QR codes may get lost; the lack of a QR code for a house does not "prove" that the household in question is new.  
- QR codes may (less frequently) be moved; the presence of a QR code in a household does not "prove" that the household corresponds to that QR code (though it is strong evidence).  
- QR codes should be finite. Data managers should ensure that a QR code is not printed more than once.  
- QR code generation and pdf compilation requires several third party libraries (latex, imagemagick, etc.). If sites have problems generating QR codes, they should reach out to bohemia@databrew.cc  
