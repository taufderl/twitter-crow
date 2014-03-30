# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

retrieveTweets = ->
  console.log 'retrieve tweets'
  if !onPublicPage()
    $("#generation-explanation").empty()
    $("#generated-tweet").empty()
    $("#generated-tweet-div").hide()
  
  $("#progress-label").html 'Crawl Tweets'
  $("#progress-div").show()
  username = $("#username-field").val()
  $.ajax(url: "/crawl_tweets", data: {'username': username}).done (job_id) ->
    updateInterval = setInterval -> 
      $.getJSON('/worker_status', {job_id: job_id}).done (job) ->
        $("#progress-bar-tweets").attr style: "width: #{job.num/3}%"
        $("#progress-bar-tweets-text").html job.message
        if (job.status == 'failed')
          clearInterval(updateInterval)
          $("#progress-label").html 'Some error occured'
          setTimeout ->
            resetSession()
          ,3000  
        else if (job.status == 'complete')
          clearInterval(updateInterval)
          setTimeout ->
            runGeoclustering()
          ,1000  
    , 500

runGeoclustering = ->
  console.log('run geoclustering')
  $("#progress-label").html 'Geoclustering'
  $.ajax(url: "/run_geoclustering").done (job_id) ->
    updateInterval = setInterval -> 
      $.getJSON('/worker_status', {job_id: job_id}).done (job) ->
        $("#progress-bar-geo").attr style: "width: #{job.num/3}%"
        $("#progress-bar-geo-text").html job.message
        if (job.status == 'failed')
          clearInterval(updateInterval)
          $("#progress-label").html 'Some error occured'
          setTimeout ->
            resetSession()
          ,3000
        else if (job.status == 'complete')
          clearInterval(updateInterval)
          storeCurrentClusterInSession(job.current_cluster)
          setTimeout ->
            runLanguageModeling()
          ,1000  
    , 500
    
runLanguageModeling = ->
  console.log('run geoclustering')
  $("#progress-label").html 'Creating Language Models'
  $.ajax(url: "/run_language_modeling").done (job_id) ->
    updateInterval = setInterval -> 
      $.getJSON('/worker_status', {job_id: job_id}).done (job) ->
        $("#progress-bar-lang").attr style: "width: #{job.num/3}%"
        $("#progress-bar-lang-text").html job.message
        if (job.status == 'failed')
          clearInterval(updateInterval)
          $("#progress-label").html 'Some error occured'
          setTimeout ->
            resetSession()
          ,3000
        else if (job.status == 'complete')
          clearInterval(updateInterval)
          setTimeout ->
            if onPublicPage() == true
              console.log 'reload page'
              location.reload()
            else
              console.log 'render map'
              $("#progress-div").hide()
              $("#tweet-map").show()
              renderGenerationExplanation()
              renderTweetMap()
          ,1000  
    , 500

getCurrentPositionAndStoreInSession = ->
  navigator.geolocation.getCurrentPosition (location) ->
    console.log "setLocationInSession"
    $.ajax(url: '/set_current_location', type: 'POST', data: location.coords).done (answer) ->
      console.log answer
      
getNextGeneratedTweet = ->
  $.ajax(url: '/generate_next_tweet').done (next_tweet) ->
    console.log next_tweet
    $("#generated-tweet").html next_tweet
    $("#generated-tweet-div").show()
      

storeCurrentClusterInSession = (current_cluster) ->
  $.ajax(url: '/set_current_cluster', type: 'POST', data: {'current_cluster': current_cluster}).done (answer) ->
    console.log answer

resetSession = ->
  $.ajax(url: '/reset_session', type: 'DELETE').done (answer) ->
    location.reload() //TODO: remove bars instead of reloading and show error message
    console.log answer

onPublicPage = ->
  if $("#map").length == 0
    return true
  else
    return false

renderGenerationExplanation = ->
  $.ajax(url: "/generation_explanation").done (html) ->
    $("#generation-explanation").html html



$ -> # INIT DOCUMENT READY

  $("#retrieve-tweets-button").click -> 
    retrieveTweets()
    
  getCurrentPositionAndStoreInSession()
  
  if !onPublicPage()
    $("#tweet-map").show()
    renderTweetMap()
    renderGenerationExplanation()
    $("#generate-tweet-button").click -> 
      getNextGeneratedTweet()
  
  else  
    $('#username-field').keydown (event) ->
      if (event.keyCode == 13)
        retrieveTweets()

      
