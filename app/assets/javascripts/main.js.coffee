# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
global = exports ? this

global.current_position = {lat: 1, lon: 1}

global.updateLocation = ->
  $.ajax(url: '/set_current_location', type: 'POST', data: global.current_position).done (answer) ->
    console.log("prepare model for coordinates "+answer)
    # start all working spins
    $('.spin').spin()
    # hide all status icons before starting
    $('.status-icon').hide()
    $('.status-label').html ''
    $("#generation-explanation").empty()
    $("#generated-tweet").empty()
    $("#generated-tweet-div").hide()
    $("#tweet-generator").hide()
    # show status div
    $("#refreshing-location-div").show()
    retrieveNearbyTweets()
  return global.current_position

retrieveUserTweets = ->
  console.log 'retrieve user tweets'
  $('#retrieve-user-spin').spin('show')
  $('#retrieve-user-arrow').show()
  
  $("#loading-tweets-div").show()
  username = $("#username-field").val()
  $.ajax(url: "/crawl_user_tweets", data: {'username': username}).done (job_id) ->
    updateInterval = setInterval -> 
      $.getJSON('/worker_status', {job_id: job_id}).done (job) ->
        $("#retrieve-user-label").html job.message
        if (job.status == 'failed')
          $('#retrieve-user-failed').show();
          $('#retrieve-user-label').html = 'Some error occured'
          clearInterval(updateInterval)
          setTimeout ->
            resetSession()
          ,3000  
        else if (job.status == 'complete')
          clearInterval(updateInterval)
          $('#retrieve-user-spin').spin('hide');
          $('#retrieve-user-arrow').hide()
          $('#retrieve-user-ok').show();
          location.reload()
    , 500

retrieveNearbyTweets = ->
  console.log 'retrieve nearby tweets'
  $('#retrieve-nearby-spin').spin('show')
  $('#retrieve-nearby-arrow').show()
  
  username = $("#username-field").val()
  $.ajax(url: "/crawl_nearby_tweets", data: {'username': username}).done (job_id) ->
    updateInterval = setInterval -> 
      $.getJSON('/worker_status', {job_id: job_id}).done (job) ->
        $("#retrieve-nearby-label").html job.message
        if (job.status == 'failed')
          $('#retrieve-nearby-failed').show();
          $('#retrieve-nearby-label').html = 'Some error occured'
          clearInterval(updateInterval)
          setTimeout ->
            resetSession()
          ,3000  
        else if (job.status == 'complete')
          clearInterval(updateInterval)
          $('#retrieve-nearby-spin').spin('hide');
          $('#retrieve-nearby-arrow').hide()
          $('#retrieve-nearby-ok').show();
          runGeoclustering()
    , 500

runGeoclustering = ->
  console.log('run geoclustering')
  $('#cluster-spin').spin('show')
  $('#cluster-arrow').show()
  $.ajax(url: "/run_geoclustering").done (job_id) ->
    updateInterval = setInterval -> 
      $.getJSON('/worker_status', {job_id: job_id}).done (job) ->
        $("#cluster-label").html job.message
        if (job.status == 'failed')
          clearInterval(updateInterval)
          $("#cluster-label").html 'Some error occured'
          setTimeout ->
            resetSession()
          ,3000
        else if (job.status == 'complete')
          clearInterval(updateInterval)
          storeCurrentClusterInSession(job.current_cluster)
          $('#cluster-spin').spin('hide')
          $('#cluster-arrow').hide()
          $('#cluster-ok').show();
          runLanguageModeling()  
    , 500
    
runLanguageModeling = ->
  console.log('run language modeling')
  $('#model-spin').spin('show')
  $('#model-arrow').show()
  $.ajax(url: "/run_language_modeling").done (job_id) ->
    updateInterval = setInterval -> 
      $.getJSON('/worker_status', {job_id: job_id}).done (job) ->
        $("#model-label").html job.message
        if (job.status == 'failed')
          clearInterval(updateInterval)
          $("#model-label").html 'Some error occured'
          setTimeout ->
            resetSession()
          ,3000
        else if (job.status == 'complete')
          $('#model-spin').spin('hide')
          $('#model-arrow').hide()
          $('#model-ok').show();
          clearInterval(updateInterval)
          setTimeout ->
            if onPublicPage() == true
              console.log 'reload page'
              location.reload()
            else
              console.log 'render map'
              $("#refreshing-location-div").hide()
              $("#tweet-generator").show()
              renderGenerationExplanation()
              renderTweetMap()
          ,1000  
    , 500

getCurrentPositionFromBrowser = (params) ->
  
  setLocationInSession = (location) ->
    coordinates = location.coords
    global.current_position = {lat: coordinates.latitude, lon: coordinates.longitude}
    value = global.current_position.lat + "," + global.current_position.lon  
    $('#location-field').val value
    updateCurrentLocationOnMap()
    global.updateLocation()

  hideErrorPopover = ->
    $("#location-field").popover('hide')
  
  showErrorPopover = ->
    $("#location-field").popover({
        trigger: 'manual'
    })
    $("#location-field").popover('show')
    $("#location-field").focus(hideErrorPopover)
  
  handleError = (err) ->
    if 'oninit' of params
      $.ajax(url: '/get_current_location').done (answer) ->
        if answer != null
          global.current_position = answer
          value = global.current_position.lat + "," + global.current_position.lon  
          $('#location-field').val value
          updateCurrentLocationOnMap()
          global.updateLocation()
        else
          showErrorPopover()
    else
      showErrorPopover()
      
  navigator.geolocation.getCurrentPosition(setLocationInSession, handleError,
    {enableHighAccuracy: true, timeout: 5000, maximumAge: 0})

getLocationFromInput = ->
  location = $('#location-field').val()
  $.ajax(url: '/search_location', type: 'POST', data: {'location': location}).done (coordinates) ->
    global.current_position = coordinates
    updateCurrentLocationOnMap()
    global.updateLocation()

getNextGeneratedTweet = ->
  $.ajax(url: '/generate_next_tweet').done (next_tweet) ->
    console.log next_tweet
    $("#generated-tweet").html next_tweet
    $("#generated-tweet-div").show()
      
storeCurrentClusterInSession = (current_cluster) ->
  $.ajax(url: '/set_current_cluster', type: 'POST', data: {'current_cluster': current_cluster}).done (answer) ->
    console.log answer

resetSession = ->
  $.ajax(url: '/reset_session').done (answer) ->
    location.reload() # TODO: remove bars instead of reloading and show error message
    console.log answer

onPublicPage = ->
  if $("#map").length == 0
    return true
  else
    return false

renderGenerationExplanation = ->
  $.ajax(url: "/generation_explanation").done (html) ->
    $("#generation-explanation").html html



$ -> # INIT ON DOCUMENT READY
  
  if onPublicPage()
    # set button handler and Enter key handler
    $("#retrieve-tweets-button").click -> 
        retrieveUserTweets()
    $('#username-field').keydown (event) ->
      if (event.keyCode == 13)
        retrieveUserTweets()
    
  else
    # set button handler
    $("#update-tweets-button").click -> 
      reloadTweets() # TODO: implement
      
    $('#current-position-button').click ->
      getCurrentPositionFromBrowser({})
    $("#generate-tweet-button").click -> 
      getNextGeneratedTweet()
    $("#set-location-button").click -> 
      getLocationFromInput()
    $('#location-field').keydown (event) ->
      if (event.keyCode == 13)
        getLocationFromInput()
    
    # try to retrieve current position and set in session
    getCurrentPositionFromBrowser({oninit: true})
    
    # render the Openlayers Map of the users tweets
    renderTweetMap()
    
