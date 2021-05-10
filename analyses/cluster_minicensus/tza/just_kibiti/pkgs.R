pkgs <- c("ggplot2", 
          "lubridate", 
          "dplyr", 
          "ggplot2", 
          "sp", 
          "raster", 
          "ggthemes", 
          "sf", 
          "RColorBrewer", 
          "readr", 
          "tidyr", 
          "leaflet", 
          "rgeos")
for(i in 1:length(pkgs)){
  this_pkg <- pkgs[i]
  remove.packages(this_pkg)
  install.packages(this_pkg)
}
