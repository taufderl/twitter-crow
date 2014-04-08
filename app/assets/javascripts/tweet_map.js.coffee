# make global namespace available everywhere
global = exports ? this

# define the tweet popup on the map
getPopupDiv = (tweet) ->
  div = $("<div class='popup'>")
  content = $("<div class='popup-content'>")
  content.append($("<p><b>@" + tweet.attributes.screen_name + "</b> ("+tweet.attributes.created_at + "):<br />"+ tweet.attributes.text + "</p>"))
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
    return 'white'
  else if cluster < COLORS.length
    return COLORS[cluster]
  else  # if not enough colors for cluster make it red
    return 'red'

# projections for coordinates
WGS84 = new OpenLayers.Projection('EPSG:4326')
MERCATOR = new OpenLayers.Projection('EPSG:900913')

# the initialisation method for the map 
global.renderTweetMap = ->
  $('#map').empty()
  console.log "render tweet map"
  
  
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
          color: getClusterColor(tweet.cluster),
          created_at: tweet.created_at
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
            popup.minSize = new OpenLayers.Size(250, 100)
            tweet.popup = popup
            map.addPopup(popup)
      ,
      "featureunselected": (e) ->
            tweet = e.feature;
            map.removePopup(tweet.popup);
            tweet.popup.destroy();
            tweet.popup = null;
    })
    
    # create location Layer vector based -------->
    locationStyle = OpenLayers.Util.extend({
        externalGraphic : "/assets/marker.png",
        pointRadius     : 12
        })
    locationLayer = new OpenLayers.Layer.Vector("LocationLayer", { style: locationStyle })
    map.addLayer(locationLayer)
    
    handleLocationDragged = (feature, pixel) ->
                    global.current_position = map.getLonLatFromViewPortPx(pixel).transform(MERCATOR, WGS84)
                    value = global.current_position.lat + "," + global.current_position.lon  
                    $('#location-field').val value
                    #global.updateLocation()
                    
    # drag control for location
    dragLocation = new OpenLayers.Control.DragFeature(locationLayer,{
          # store new location in session when dragged the tile
          'onComplete': handleLocationDragged 
          })
    map.addControl(dragLocation)
    dragLocation.activate()
    # <----------- Vector based location layer
    
    point = new OpenLayers.Geometry.Point(global.current_position.lon, global.current_position.lat, ).transform(WGS84, MERCATOR)
    locationFeature = new OpenLayers.Feature.Vector(point, { icon: "icon.png" })
    locationLayer.addFeatures([locationFeature]);
  
    global.updateCurrentLocationOnMap = ->
      newLonLat = new OpenLayers.LonLat(global.current_position.lon,global.current_position.lat).transform(WGS84, MERCATOR);
      locationFeature.move(newLonLat)
  
    # add select control to switch layers
    map.addControl(new OpenLayers.Control.LayerSwitcher());
    selectControl = new OpenLayers.Control.SelectFeature([featureLayer, locationLayer]);
    map.addControl(selectControl);
    selectControl.activate();

