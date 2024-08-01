# STEP 1: install and load packages

setwd("C:/Users/RexDe/Desktop/R Projects/Shipping")
current_directory <- getwd()
print(current_directory)

pacman::p_load(
  tidyverse, terra,
  sf, giscoR, ggnewscale
)


# STEP 2: download, unzip and load traffic data

url <- "https://datacatalogfiles.worldbank.org/ddh-published/0037580/DR0045406/shipdensity_global.zip"
destfile <- basename(url)

options(timeout = 999)

download.file(
  url = url,
  destfile = destfile,
  mode = "wb"
)

source("https://raw.githubusercontent.com/milos-agathon/shipping-traffic-maps/main/R/decompress_file.r")

////// 
  
  library(terra)

# Specify the full path to the zip file
zip_file <- "C:/Users/RexDe/Desktop/R Projects/Shipping/shipdensity_global.zip"

# Specify the directory where you want to extract the files
output_directory <- "C:/Users/RexDe/Desktop/R Projects/Shipping/"

# Decompress the zip file
decompress_file(zip_file, output_directory)

# Generate the file name for the decompressed raster file
raster_file <- gsub(".zip", ".tif", basename(zip_file))

# Load the raster file directly
global_traffic <- rast("C:/Users/RexDe/Desktop/R Projects/Shipping/shipdensity_global/shipdensity_global.tif")

/////////

# STEP 3: Select the area of interest and crop

  # Japan beijing
xmin <- 116.790636
ymin <- 21.567545
xmax <- 143.809902
ymax <- 41.863015
  
  
# Van isle 
# -129.035467,46.938262,-121.918197,51.415654



bounding_box <- sf::st_sfc(
  sf::st_polygon(
    list(
      cbind(
        c(xmin, xmax, xmax, xmin, xmin),
        c(ymin, ymin, ymax, ymax, ymin)
      )
    )
  ),
  crs = 4326
)

shipping_traffic <- terra::crop(
  x = global_traffic,
  y = bounding_box,
  snap = "in"
)

terra::plot(shipping_traffic)

shipping_traffic_clean <- terra::ifel(
  shipping_traffic == 0,
  NA,
  shipping_traffic
)

////////
  
# STEP 4: Get nightlight data

u <- "https://eogdata.mines.edu/nighttime_light/annual/v22/2022/VNL_v22_npp-j01_2022_global_vcmslcfg_c202303062300.average_masked.dat.tif.gz"
filename <- basename(u)

download.file(
  url = u,
  destfile = filename,
  mode = "wb"
)

path_to_nightlight <- list.files(
  path = getwd(),
  pattern = filename,
  full.names = TRUE
)

nightlight <- terra::rast(
  paste0(
    "/vsigzip/",
    path_to_nightlight
  )
)

nightlight_region <- terra::crop(
  x = nightlight,
  y = bounding_box,
  snap = "in"
)

nightlight_resampled <- terra::resample(
  x = nightlight_region,
  y = shipping_traffic_clean,
  method = "bilinear"
)

terra::plot(nightlight_resampled)