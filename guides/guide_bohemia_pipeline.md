# Bohemia Data Pipeline

## Overview

The data pipeline contains 4 components:
 1. A PostgreSQL database
 2. A Shiny Application as the web interface
 3. A collection of R scripts for data snapshotting, cleaning, and anomaly detection
 4. An ODK-X application to resolve anomalies

### Outline of the Procedure

1. Data synced from Android tablets to a local Sync Endpoint server
2. Data pipeline takes a snapshot of the Sync Endpoint data and saves to project server
   1. The pipeline should snapshot periodically but also provide an option to snapshot manually.
3. Data pipeline performs automated data cleaning on the snapshot
4. Data pipeline displays a report of the latest snapshot. The report should include:
   1. New rows
   2. Modified rows
   3. Automated cleaning actions performed
   4. Anomalies detected
5. Data pipeline pushes a list of rows that require attention to the Sync Endpoint server
   1. The list of rows will be stored as a table on Sync Endpoint. Each record in the list contains an unique ID and links to the row requiring attention.
6. Android tablets sync to receive the list of rows requiring attention
7. Authorized users correct the data with ODK-X Survey then push the changes back to Sync Endpoint
   1. Authorized users will see a list of rows flagged in ODK-X Tables. The list will include the row ID, a natural ID (e.g. HHID for a household, ExtID for a member), and the reason why the row was flagged.
   2. Authorized users will be able implement corrections using the same form field workers used to collect the data. Authorized users could also choose to remove the data or mark the data as correct
   3. Data corrections or removal will be stored in a separate table to maintain record. e.g. Corrections for the census table will be stored in the census_correction tabl
   4. There should also be an option to implement correction to rows not flagged by anomaly detection.
8. Data pipeline pulls in fixes from Sync Endpoint and re-runs anomaly detection
9. Authorized users confirm or discard the changes via web interface
10. Data pipeline pushes the fixed data back to Sync Endpoint

### PostgreSQL Database
The database is used to store:
 - Snapshots of data taken from an ODK-X Sync Endpoint server
 - Changes between snapshots
 - Actions taken to resolve anomalies

### Shiny Web Interface
A Shiny Application serves as the web interface for the data pipeline. Its main functions are:
 - Display changes between snapshots
 - Display automated cleaning actions performed
 - Display anomalies detected along with the reason
 - Manually obtain snapshots of Sync Endpoint data
 - Accept or deny anomaly resolutions

The interface contains 2 pages:
 - Report
 - Anomaly resolution

#### Report
The report page contains UI elements to display a summary of the latest snapshot, controls to select another snaphsot, and controls to obtain a new snapshot.
The summary displays the changes (if any) between the latest snapshot and the previous snapshot. The information includes data added, modified, and removed for each table tracked by the pipeline. If automated cleaning was performed on the snapshot, the report also displays the actions performed and data affected. In the case that anomalies were detected in the snapshot, this page also displays the anomalies and guide the user to resolve the anomalies using ODK-X.

#### Anomaly Resolution
This page displays a list of corrections that are pending to be applied. After anomaly corrections are entered through ODK-X, the modifications will be shown here for confirmation. The atomic unit for accepting and denying changes is 1 row of data. This page only provides controls for accepting and denying changes. If the changes are partially incorrect, they should be rectified through ODK-X. Once all pending corrections have been reviewed, the corrections will be applied and a new snapshot taken.

### R Scripts
A collection of scripts to
 - Pull data from a Sync Endoint server, in order to obtain a snapshot and save the snapshot to a PostgreSQL database
 - Calculate changes between snapshots
 - Clean data
 - Detect anomalies
 - Push anomalies to a Sync Endpoint server, to prepare for anomaly resolution

These functions are structured as standalone scripts, as opposed to integrated parts of the Shiny application so these scripts can be ran independent of the Shiny application. For example, to run these scripts from a cron job.

### ODK-X Application
The ODK-X component of the pipeline serves to facilitate anomaly resolution. Authorized users will use ODK-X Tables to see a list of records that have been flagged as anomalous. From here 3 actions are possible:
 - Discard the record
 - No changes required
 - Fix the anomaly

If a fix is required, authorized users will use the form originally used to collect the data to perform the changes. For example, if an anomaly is detected in a record of the individual questionnaire, the individual questionnaire form will be used to correct the data.
