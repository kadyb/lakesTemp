// Points coordinates
var p = ee.Geometry.Point([16.677, 53.0]);

// Load the image data
var data = ee.ImageCollection('LANDSAT/LC08/C02/T1_TOA')
              //.filterDate('2013-04-01', '2019-12-31')
              .filter(ee.Filter.calendarRange(4, 10, 'month'))
              .filterBounds(p)
              .filterMetadata('CLOUD_COVER', 'less_than', 10);

print(data);

// Select one scene by ID
var data = ee.Image('LANDSAT/LC08/C02/T1_TOA/LC08_191023_20210428')
              .select(['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 
                       'B7', 'B10', 'B11']);

var projection = data.select('B2').projection().getInfo();

Export.image.toDrive({
  image: data,
  folder: 'images',
  description: 'West',
  crs: projection.crs,
  crsTransform: projection.transform
});



// Geometry bounding boxes
// goplo = (18.31, 52.47, 18.40, 52.70)
// lebsko = (17.28, 54.66, 17.54, 54.76)
// drawsko = (16.11, 53.54, 16.24, 53.66)
// elckie = (22.31, 53.78, 22.37, 53.84)
var lake = ee.Geometry.BBox(22.31, 53.78, 22.37, 53.84);

var data = ee.ImageCollection('LANDSAT/LC08/C02/T1_TOA')
              //.filterDate('2013-04-01', '2019-12-31')
              .filter(ee.Filter.calendarRange(4, 10, 'month'))
              .filterBounds(lake)
              .filterMetadata('CLOUD_COVER', 'less_than', 10);

print(data);

// Select scene by ID for each lake
// LANDSAT/LC08/C02/T1_TOA/LC08_190023_20210608
// LANDSAT/LC08/C02/T1_TOA/LC08_191022_20150818
// LANDSAT/LC08/C02/T1_TOA/LC08_192023_20180529
// LANDSAT/LC08/C02/T1_TOA/LC08_187022_20211025
var data = ee.Image('LANDSAT/LC08/C02/T1_TOA/LC08_187022_20211025')
              .select(['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 
                       'B7', 'B10', 'B11']);

var projection = data.select('B2').projection().getInfo();

var vizParams = {
  bands: ['B4', 'B3', 'B2'],
  min: 0,
  max: 0.5,
  gamma: [0.95, 1.1, 1]
};

Map.addLayer(data, vizParams);
Map.centerObject(lake, 11);

Export.image.toDrive({
  image: data,
  description: 'Elckie',
  folder: 'images',
  region: lake,
  crs: projection.crs,
  crsTransform: projection.transform
});