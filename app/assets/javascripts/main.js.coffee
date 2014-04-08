# make global namespace available everywhere
global = exports ? this

global.whenAvailable = (name, callback) ->
  interval = 50
  setTimeout ->
    if (window[name])
      callback(window[name])
    else
      setTimeout(arguments.callee, interval)
  ,interval

#global variable current_position
global.current_position = {lat: 1, lon: 1} # TODO: find better initial value?

# reloads the users tweets when already logged in to update new ones for example
reloadTweets = ->
  console.log('reload tweets needs to be implemented')
  # TODO: implement this method!!

# retrieve user tweets from Twitter
retrieveUserTweets = ->
  $("#loading-tweets-div").show()
  $('#retrieve-user-spin').spin('show')
  $('#retrieve-user-arrow').show()
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
          runGeoclustering()
    , 500

# run geoclustering on current tweet data
# triggered by retrieveUserTweets()
runGeoclustering = ->
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
          #storeCurrentClusterInSession(job.current_cluster) # TODO: REMOVE
          $('#cluster-spin').spin('hide')
          $('#cluster-arrow').hide()
          $('#cluster-ok').show();
          # reload location to show user page 
          location.reload() # TODO: do not reload but only load new stuff ajax based
    , 500

# global method to update the current location and prepare the model
global.updateLocation = ->
  $.ajax(url: '/set_current_location', type: 'POST', data: global.current_position).done (answer) ->
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
  
# retrieve nearby tweets
# triggered by global.updateLocation() 
retrieveNearbyTweets = ->
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
          runLanguageModeling()
    , 500

# run language modeling worker
# triggered by retrieveNearbyTweets()
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

# tries to get the current position from the browser
# triggerd at page load when logged in and on button click
getCurrentPositionFromBrowser = (params) ->
  
  # sets the retrieved location as current and updates everything
  setLocation = (location) ->
    coordinates = location.coords
    global.current_position = {lat: coordinates.latitude, lon: coordinates.longitude}
    value = global.current_position.lat + "," + global.current_position.lon  
    $('#location-field').val value
    whenAvailable("updateCurrentLocationOnMap", -> updateCurrentLocationOnMap)
    global.updateLocation()

  # hides error popover
  hideErrorPopover = ->
    $("#location-field").popover('hide')
  
  # shows error popover
  showErrorPopover = ->
    $("#location-field").popover({trigger: 'manual'})
    $("#location-field").popover('show')
    $("#location-field").focus(hideErrorPopover)
  
  # handles error while retrieving location from browser
  handleError = (err) ->
    # if error occured on page load, check for location details in session
    if 'oninit' of params
      $.ajax(url: '/get_current_location').done (answer) ->
        if answer != null
          global.current_position = answer
          value = global.current_position.lat + "," + global.current_position.lon  
          $('#location-field').val value
          whenAvailable("updateCurrentLocationOnMap", -> updateCurrentLocationOnMap)
          global.updateLocation()
        else
          showErrorPopover()
    else
      showErrorPopover()
  
  # finally initialise location retrieval
  navigator.geolocation.getCurrentPosition(setLocation, handleError,
    {enableHighAccuracy: true, timeout: 5000, maximumAge: 0})

# gets a location from the input term
getLocationFromInput = ->
  location = $('#location-field').val()
  $.ajax(url: '/search_location', type: 'POST', data: {'location': location}).done (coordinates) ->
    global.current_position = coordinates
    updateCurrentLocationOnMap()
    global.updateLocation()
    global.whenAvailable

# generate new tweet and show it to the user
getNextGeneratedTweet = ->
  $.ajax(url: '/generate_next_tweet').done (next_tweet) ->
    console.log next_tweet
    $("#generated-tweet").html next_tweet
    $("#generated-tweet-div").show()

# resets the session and reloads the page
resetSession = ->
  $.ajax(url: '/reset_session').done (answer) ->
    location.reload()

# returns true if on public page, else false
onPublicPage = ->
  if $("#map").length == 0
    return true
  else
    return false

# retrieves and renders the new generation explanation
renderGenerationExplanation = ->
  $.ajax(url: "/generation_explanation").done (html) ->
    $("#generation-explanation").html html


# Initialisation when page loaded
$ -> 
  
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
      reloadTweets()
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
    
