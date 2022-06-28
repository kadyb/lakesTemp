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
1. Open the `geomorph_clustering.Rproj` project file in [RStudio](https://rstudio.com/).
2. Create a JavaScript object with coordinates using `01_create_features.R` that will be used in [Google Earth Engine](https://earthengine.google.com/).
3. Download reflectance data from Google Earth Engine using `02_Landsat8_SR_download.js` (Surface Reflectance) and `02_Landsat8_TOA_download.js` (Top-of-Atmosphere Reflectance).
You must use the coordinates from the `pointsFeatures.txt` file.
4. Download data from hydrological stations (water temperature) using `04_hydro_process.R`.
5. The main part of the analysis was done in the `05_analysis.R` script.
It includes training of LM and RF models and validation of all LM, RF, LST and LST-L2 models.
6. `06_LST_calibration.R` was used to compare calibration methods for the LST-L2 (USGS) product using empirical data.
7. Entire satellite scenes for spatial prediction can be downloaded using script `07_download_scene.js`.
8. Prediction using LM or RF model can be done with script `08_predict.R` for individual lakes or the entire scene.
The `{terra}` package was used to process the raster data.

The algorithm to generate the LST product developed by [Ermida et al. (2020)](https://www.mdpi.com/2072-4292/12/9/1471/htm) is available in the Google Earth Engine repository: https://code.earthengine.google.com/?accept_repo=users/sofiaermida/landsat_smw_lst

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
