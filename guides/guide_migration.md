# Migration

## Overview

The Bohemia census uses "pre-populated" data elements from the prior Bohemia minicensus. Pre-population of data means that the server which hosts the Bohemia census form must undergo a process in which previously collected data is imported into it. We call this process "migration". This guide details how to carry out a full migration.

## Preparing client devices

First and foremost, make sure that any client devices you have which are configured for your server have been cleared. This means doing the following on each device:
- Go to OI File Manager
- Find "opendatakit" and click on it
- Press and hold the `default` folder; once the "Do you really want to delete default?" prompt pops up, click "OK"

Doing the above is important so as to ensure that your client devices are fresh and ready to be synced. Now, you'll need to configure the server / authenticate again on each device.

## Preparing the server

**When you carry out a migration, you'll be deleting all the current forms and data currently hosted on that server. So, do NOT go forward unless you are fine with throwing out all existant code, forms, and data currently on your server.**

A reproducible example of a migration is available at https://github.com/databrew/bohemia/blob/master/scripts/odk_x_migration/migrate_minicensus.R. Clone this repo, modify the code (for your server), modify the parameters at the top of your script, and then run the code.

Note: running java commands in RStudio ocasionnally causes the GUI to freeze. Consider using `Rscript` from the command line instead.




