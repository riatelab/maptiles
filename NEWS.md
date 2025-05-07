# maptiles 0.10.0

## fix
- manage "inverted" jpg/jpeg images with terra::is.flipped (#36)


# maptiles 0.9.0

## fix
- manage "inverted" jpg images (see #34 and https://github.com/rspatial/terra/issues/1627)
- fix OpenStreetMap.HOT server address

## feat
- add 'retina' argument in get_tiles() to download high resolution tiles when 
available (#33 and #35)
- add some Stadia variants (AlidadeSmooth, AlidadeSmoothDark, OSMBright and Outdoors)



# maptiles 0.8.0

## fix
- use the same provider names as leaflet (#31 @mtennekes)
- correct a typo in attribution for OSM FR provider

## feat
- add get_providers() to export the provider list with URLS, subdomains, name and attribution (#31)



# maptiles 0.7.0

This release is a refactoring of the package, functions has been exploded to be 
better tested and inspected.

## fix
- update tests with valid provider
- remove (not functioning) Esri Delorme provider
- better management of cache, tiles and composed raster are cached 
(huge speed gain)
- remove the gdal-based merging mechanism, not efficient anymore. 

## feat
- improve doc in create_provider() for wms inspection (#22 @paul-carteron)
- add *.webp tile extension support (#28 @tadhg-moore)
- change the output of verbose
- cache composed raster for future use
- API keys management for Stadia and Thunderforest with env variable



# maptiles 0.6.1

## fix
- deactivate get_tiles() example due to unpredictable download time leading to 
CRAN note/rejection...



# maptiles 0.6.0

## fix

- remove various unreliable provider (OpenStreetMap.MapnikBW, HikeBike, 
Wikimedia, OpenStreetMap.NoLabels...) 
- update openstreetmap provider url (#23)
- update stamen provider to stadia (#24)
- fix forceDownload mechanism (force replace *.tif files) 

## feat

- new function create_provider() to create provider
- use a better mechanism for apikey


# maptiles 0.5.0

## fix
* do not discard the crs of SpatRaster and SpatVector (@rhijmans #19)
* no buffer is applied on input sf* object extent when crop = TRUE anymore

## feat
* add a project argument to get_tiles() to output SpatRaster in its original projection (part of @rhijmans #20)

## test
* better test suite



# maptiles 0.4.0

## Bug fixes
* Fix issue that stopped downloading tile sets that span different orders of magnitude
* Fix error message from GDAL for raster with nodata values 
* Allow 'jpeg' tile extension 
* Fail gracefully if the tile server is not responding


# maptiles 0.3.0

## Minor changes
* Change projection management, faster with 3857 now
* Add adjust argument to plot_tiles() to plot the raster without zoom-in or zoom-out in the graphic device
* Modify attribution of Stamen maps


# maptiles 0.2.0

## Minor changes
* Suppress warnings for png files
* Use sf::gdal_utils to merge tiles, the operation is really faster. 



# maptiles 0.1.3

## Minor changes
Lower gdal dependancy


# maptiles 0.1.2

## Minor changes
* Added a `NEWS.md` file to track changes to the package.
* Added URL and BugReports links
* Better tiles display
* Allow to use terra::plot() with tiles
* Added SpatRaster and SpatVector support in get_tiles()


## Bug fixes
* Added alpha channel to display transparents tiles
