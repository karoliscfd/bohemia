# ICF tool

This application is meant to be run locally or served on a site server.

To install the application, run the below:

### Server

```
sudo su - -c "R -e \"remove.packages('icf')\""; sudo su - -c "R -e \"devtools::install_github('databrew/bohemia', subdir = 'rpackage/icf')\""; sudo chmod -R 777 /usr/local/lib/R/site-library; sudo chmod -R 777 /usr/lib/R/site-library/; sudo chmod -R 777 /usr/lib/R/library; sudo systemctl restart shiny-server;
```



### Local machine (R session)

```
remove.packages('icf')
devtools::install_github('databrew/bohemia', subdir = 'rpackage/icf')
library(icf); icf::run_app()
```


