# Crig Ulliott 2012
# Mercator module for use with google map tiles
#
# this is my ruby implementation of:
# Author: Klokan Petr Pridal, klokan at klokan dot cz
# Web: http://www.klokan.cz/projects/gdal2tiles/
#
#
# Example:
#
# zoom = 10
# lat = -41.29 
# lon = 174.8
# 
# mx, my = Mercator::LatLonToMeters( lat, lon )
# tx, ty = Mercator::MetersToTile( mx, my, zoom )
# puts "TMS: #{tx} #{ty}"
# 
# gx, gy = Mercator::GoogleTile(tx, ty, zoom)
# puts "tGoogle: #{gx} #{gy}"
# 
# tx1, ty1 = Mercator::TMSTile(gx, gy, zoom)
# puts "TMS: #{tx1} #{ty1}"
# 
# wgsbounds = Mercator::TileLatLonBounds( tx, ty, zoom)
# puts "Coords: #{wgsbounds}"
module Mercator

  # Initialize the TMS Global Mercator pyramid
  @tileSize = 256
  @initialResolution = 2 * Math::PI * 6378137 / 256
  @originShift = 2 * Math::PI * 6378137 / 2.0
  
  # Converts given lat/lon in WGS84 Datum to XY in Spherical Mercator EPSG:900913
  def self.LatLonToMeters(lat, lon )
    mx = lon * @originShift / 180.0
    my = Math.log( Math.tan((90 + lat) * Math::PI / 360.0 )) / (Math::PI / 180.0)
    my = my * @originShift / 180.0
    return mx, my
  end
  
  # Converts XY point from Spherical Mercator EPSG:900913 to lat/lon in WGS84 Datum
  def self.MetersToLatLon(mx, my )
    lon = (mx / @originShift) * 180.0
    lat = (my / @originShift) * 180.0
    lat = 180 / Math::PI * (2 * Math.atan( Math.exp( lat * Math::PI / 180.0)) - Math::PI / 2.0)
    return lat, lon
  end
  
  # Converts pixel coordinates in given zoom level of pyramid to EPSG:900913
  def self.PixelsToMeters(px, py, zoom)
    res = self.Resolution( zoom )
    mx = px * res - @originShift
    my = py * res - @originShift
    return mx, my
  end
    
  # Converts EPSG:900913 to pyramid pixel coordinates in given zoom level
  def self.MetersToPixels(mx, my, zoom)
    res = self.Resolution( zoom )
    px = (mx + @originShift) / res
    py = (my + @originShift) / res
    return px, py
  end
  
  # Returns a tile covering region in given pixel coordinates
  def self.PixelsToTile(px, py)
    tx = ( px / @tileSize.to_f ).ceil - 1
    ty = ( py / @tileSize.to_f ).ceil - 1
    return tx, ty
  end
    
  # Returns tile for given mercator coordinates
  def self.MetersToTile(mx, my, zoom)
    px, py = self.MetersToPixels( mx, my, zoom)
    return self.PixelsToTile( px, py)
  end
  
  # Returns bounds of the given tile in EPSG:900913 coordinates
  def self.TileBounds(tx, ty, zoom)
    minx, miny = self.PixelsToMeters( tx*@tileSize, ty*@tileSize, zoom )
    maxx, maxy = self.PixelsToMeters( (tx+1)*@tileSize, (ty+1)*@tileSize, zoom )
    return [ minx, miny, maxx, maxy ]
  end

  # Returns bounds of the given tile in latutude/longitude using WGS84 datum
  def self.TileLatLonBounds(tx, ty, zoom )
    bounds = self.TileBounds( tx, ty, zoom)
    minLat, minLon = self.MetersToLatLon(bounds[0], bounds[1])
    maxLat, maxLon = self.MetersToLatLon(bounds[2], bounds[3])
    return [ minLat, minLon, maxLat, maxLon ]
  end
    
  # Resolution (meters/pixel) for given zoom level (measured at Equator)
  def self.Resolution(zoom )
    # return (2 * Math::PI * 6378137) / (@tileSize * 2**zoom)
    return @initialResolution / (2**zoom)
  end

  # Converts TMS tile coordinates to Google Tile coordinates
  def self.GoogleTile(tx, ty, zoom)
    # coordinate origin is moved from bottom-left to top-left corner of the extent
    return tx, (2**zoom - 1) - ty
  end

  # Converts Google tile coordinates to TMS Tile coordinates
  def self.TMSTile(tx, ty, zoom)
    # coordinate origin is moved from top-left to bottom-left corner of the extent
    return tx, - (ty - (2**zoom - 1))
  end

end