library("sf")

pts = read_sf("data/coordinates/coords.shp")
pts$text = NA
coords = st_coordinates(pts)
coords = round(coords, 5)

### sample features:
# var features = [
#    ee.Feature(ee.Geometry.Point(-73.96, 40.781), {name: 'Thiessen'}),
#    ee.Feature(ee.Geometry.Point(6.4806, 50.8012), {name: 'Dirichlet'})
#   ];
for (i in seq_len(nrow(pts))) {
        pts$text[i] = paste0("ee.Feature(ee.Geometry.Point(", coords[i, 1], ", ", coords[i, 2], "), {oid: ", pts$Kod.stacji[i], "}),")
}

# remove unnecessary comma
last_row = pts$text[nrow(pts)]
last_row = substr(last_row, 1, nchar(last_row) - 1)
pts$text[nrow(pts)] = last_row

write.table(pts$text, "data/pointsFeatures.txt", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
