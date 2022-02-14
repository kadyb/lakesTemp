var table = [ ]; // input pointsFeatures.txt here
var table = ee.FeatureCollection(table);

// Function to mask clouds based on the QA_PIXEL band of Landsat 8 TOA data
function maskL8sr(image) {
  // Bits 4 and 3 are cloud shadow and cloud, respectively
  var cloudShadowBitMask = (1 << 4);
  var cloudsBitMask = (1 << 3);
  // Get the pixel QA band
  var qa = image.select('QA_PIXEL');
  // Both flags should be set to zero, indicating clear conditions
  var mask = qa.bitwiseAnd(cloudShadowBitMask).eq(0)
                 .and(qa.bitwiseAnd(cloudsBitMask).eq(0));
  return image.updateMask(mask);
}

// Load the image data
var data = ee.ImageCollection('LANDSAT/LC08/C02/T1_TOA')
              //.filterDate('2013-04-01', '2019-12-31')
              .filter(ee.Filter.calendarRange(4, 10, 'month'))
              .filterBounds(table)
              .filterMetadata('CLOUD_COVER', 'less_than', 60)
              .map(maskL8sr)
              .select(['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 
                      'B7', 'B10', 'B11']);

// Map over the images and use reduceRegions() to extract data
var featureCollection = data.map(function(image) {
  var dataOutput = image.reduceRegions(table, ee.Reducer.mean(), 30);
  return dataOutput;
}).flatten();
var featureCollection = featureCollection.filterMetadata('B1', 'not_equals', null);

// Export data as CSV
Export.table.toDrive({
  collection: featureCollection,
  description: 'Landsat8_TOA',
  selectors: ['system:index', 'oid', 'B1', 'B2', 'B3',
              'B4', 'B5', 'B6','B7', 'B10', 'B11']
});
