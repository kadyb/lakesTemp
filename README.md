# Lakes temperature
This repository contains the data, code, and results for “*The potential of monitoring the surface water temperature of lakes in Poland using Landsat 8 satellite images*” article.

## Dataset
The `data` folder contains the following files:
- `SR_processed.csv` - surface reflectance after cleaning
- `TOA_processed.csv` - top-of-atmosphere reflectance after cleaning
- `hydro_stations.csv` - list of hydrological stations (38) with name and ID
- `lakes_temp.csv` - lake water temperature in degrees Celsius
- `pointsFeatures.txt` - location of measurement points as a JavaScript object (this is required by Google Earth Engine)
- `coordinates` subfolder - location of measurement points as a shapefile
- `reflectance` subfolder - raw (not cleaned) SR and TOA reflectance
- `vector/lakes.gpkg` - extent of 4 sample lakes (Drawsko, Ełckie, Gopło, Łebsko)

## Reproduction

## Results
The results of this research are saved in `results` folder:
- `lakes_stats.csv`- performance statistics of LM and RF models considering training and test lakes
- `month_stats.csv` - performance statistics of LM and RF models by month
- `predictions_testset.csv` - testset with actual measurements and estimated by 4 models (LM, RF, LST, LST-L2)
- `rf_model.rds` - trained RF model in *.rds* format (`{ranger}` package is required)

Additionally, in the `images/predict` folder there are 4 exemplary results of the spatial prediction by the RF model for different terms.

## Acknowledgement
The source of the hydrological data is the Institute of Meteorology and Water Management - National Research Institute (https://www.imgw.pl/).
Landsat-8 images courtesy of the U.S. Geological Survey (https://earthexplorer.usgs.gov/) and Google Earth Engine (https://earthengine.google.com/).
