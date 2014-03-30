# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# define Tweet popup
getPopupDiv = (tweet) ->
  div = $("<div class='popup'>")
  content = $("<div class='popup-content'>")
  content.append($("<p><b>" + tweet.attributes.screen_name + ":</b><br />" + tweet.attributes.text + "</p>"))
  content.append($("<p>" + tweet.attributes.latitude + "," + tweet.attributes.longitude + "</p>"))
  content.append($("<p>Cluster: " + tweet.attributes.cluster + "</p>"))
  content.append($("<p><a href='http://twitter.com/"+tweet.attributes.screen_name+"/statuses/" + tweet.attributes.id + "' target='_blank'>Link to Tweet</b></p>"))
  div.append(content)
  return div.html()

# define colors for different clusters
COLORS = ["#99CCFF",  "#99CCCC", "#99CC99", "#99CC66", "#99CC33", "#99CC00",
        "#9999FF", "#9999CC", "#999999", "#999966", "#999933", "#999900"]
        
getClusterColor = (cluster) ->
  if cluster == -1
    return 'black'
  else if cluster < COLORS.length
    return COLORS[cluster]
  else  # if not enough colors for cluster make it red
    return 'red'

# transformations for coordinates
WGS84 = new OpenLayers.Projection('EPSG:4326')
MERCATOR = new OpenLayers.Projection('EPSG:900913')

  
(exports ? this).renderTweetMap = ->
  $('#map').empty()
  console.log "render tweet map"
  # add marker to map when current location is determined
  addCurrentPositionToMap = ->
    #console.log location.coords
    console.log "addLocationToMap"
    $.ajax(url: "/get_current_location").done (location) ->
      if location != null
        console.log(location)
        size = new OpenLayers.Size(21,25)
        offset = new OpenLayers.Pixel(-(size.w/2), -size.h)
        icon = new OpenLayers.Icon('http://www.openlayers.org/dev/img/marker.png', size, offset)
        position = new OpenLayers.LonLat(location.lon, location.lat).transform(WGS84, MERCATOR)
        locationMarker = new OpenLayers.Layer.Markers( "LocationMarker" )
        locationMarker.addMarker(new OpenLayers.Marker(position,icon.clone()))
        current_boundary = map.getExtent()
        current_boundary.extend(locationMarker.getDataExtent)
        map.zoomToExtent(current_boundary)
        map.addLayer(locationMarker)
    
  # create map and add map layer
  map = new OpenLayers.Map('map') # Argument is the name of the containing div.
  map.addLayer(new OpenLayers.Layer.OSM())        # add map layer
  
  # create features Layer
  featureLayer = new OpenLayers.Layer.Vector("Tweets", 
                  styleMap: new OpenLayers.StyleMap({
                    pointRadius: 8,
                    fillColor: '${color}',
                    strokeColor: 'black',
                    fillOpacity: 0.2,
                    strokeWidth: 2,
                    strokeOpacity: 1
                  })
  )

  # retrieve tweets
  tweets = []
  $.ajax(url: "/get_tweets").done (received_tweets) ->
    #console.log received_tweets
    for tweet in received_tweets
      #console.log tweet
      
      if tweet.geo_enabled == true 
        latitude = parseFloat(tweet.geo_latitude)
        longitude = parseFloat(tweet.geo_longitude)
        
        attributes = {
          latitude: latitude,
          longitude: longitude,
          text: tweet.text,
          id: tweet.id,
          cluster: tweet.cluster,
          screen_name: tweet.screen_name
          color: getClusterColor(tweet.cluster)
        }
        
        point = new OpenLayers.Geometry.Point(longitude, latitude).transform(WGS84, MERCATOR)
        tweets.push(new OpenLayers.Feature.Vector(point,attributes))
      
    
    featureLayer.addFeatures(tweets)
    
    # determine boundary
    map.zoomToExtent(featureLayer.getDataExtent());
    
    # tweet popups
    controlSelection = new OpenLayers.Control.SelectFeature(featureLayer);
    map.addControl(controlSelection);
    controlSelection.activate()
    
    map.addLayer(featureLayer)                          # add features
    
    featureLayer.events.on({
      "featureselected": (e) ->
            tweet = e.feature;
            html = getPopupDiv(tweet)
            popup = new OpenLayers.Popup.FramedCloud("Tweet", tweet.geometry.getBounds().getCenterLonLat(), null, html, null, true, -> controlSelection.unselect(tweet))
            popup.minSize = new OpenLayers.Size(300, 100)
            tweet.popup = popup
            map.addPopup(popup)
      ,
      "featureunselected": (e) ->
            tweet = e.feature;
            map.removePopup(tweet.popup);
            tweet.popup.destroy();
            tweet.popup = null;
    })
    
    addCurrentPositionToMap()  

