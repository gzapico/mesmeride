# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

modified = false
waypointUniqueId = -1

$ ->

  #
  # Toolboxes and resizing
  #

  $( ".toolbox,.debug_dump" ).draggable();

  $( "#zoom-slider" ).slider
    orientation: 'vertical', 
    change: (event,ui) -> 
      $('#surface').css('width', ui.value*10 + '%').css('height', ui.value*10 + '%')

  $( "#controls" ).offset({top: $('#tools').offset().top + $('#tools').outerHeight() + 4, left: $('#controls').offset().left});
  $( "#surface-container" ).height($('#bottom-anchor').offset().top - $('.navbar-fixed-top').outerHeight() - $('#waypoints').outerHeight());

  #
  # Waypoint manipulation
  #
  
  routeDistance = window.streams.distance[window.streams.distance.length-1]
  
  waypointChange = (e) ->  
    for w in waypoints 
      w.name = $(e).val() if w.id == waypointId(e)
        
    stravaOnSteroids.postRedraw();
    
  waypointId = (elem) ->
    $(elem).parents('#waypoints tr').data('id')
    
  getWaypoint = (elem) ->
    id = waypointId(elem)
    for w in waypoints 
      return w if w.id is id
    null
  
  getElevationByDistance = (distance) ->
    for d,i in streams.distance
      return streams.altitude[i] if d >= distance
    return -1
  
  attachWaypointEvents = ->
    $( "#waypoints input[type='text']" ).keyup -> waypointChange this
    $( "#waypoints input[type='text']" ).change -> 
      waypointChange this
      modified = true
    $( "#waypoints button.close" ).click ->
      for w,i in waypoints
        if w.id == waypointId(this)
          waypoints.splice i,1
          break
      $(this).parent().parent().find('input,div,button').attr('disabled','disabled')
      # $(this).parent().parent().find('.waypoint-distance').slider('disable')
      $(this).parent().parent().find('.input-destroy').val(1) # '#waypoints tr[id=#{waypointId(this)}] ').disable() 
      # this).parent().parent().detach()
      stravaOnSteroids.postRedraw()
      
    $( "#waypoints .waypoint-distance" ).each ->
      refreshWaypoint = (e) ->
        waypoint = getWaypoint(e)
        waypoint.distance = $(e).slider('value')
        waypoint.elevation = getElevationByDistance(waypoint.distance)
        stravaOnSteroids.postRedraw()
        $('.ui-slider-handle',e).tooltip('show')

      $(this).slider(
        min: 0
        max: routeDistance
        step: 1
        value: getWaypoint(this).distance
        slide: ->
          refreshWaypoint(this)
          
      #
      # override default keyboard events because pgup/dn are too large an increment
      #
      
      ).keydown (event) ->
        switch event.keyCode
          when $.ui.keyCode.PAGE_UP then $(this).slider('value', Math.max($(this).slider('value') - 100, 0))
          when $.ui.keyCode.PAGE_DOWN then $(this).slider('value', Math.min($(this).slider('value') + 100, routeDistance))
          when $.ui.keyCode.LEFT then $(this).slider('value', Math.max($(this).slider('value') - 1, 0))
          when $.ui.keyCode.RIGHT then $(this).slider('value', Math.min($(this).slider('value') + 1, routeDistance))
          when $.ui.keyCode.HOME then $(this).slider('value', 0)
          when $.ui.keyCode.END then $(this).slider('value', routeDistance)
          else return true
        refreshWaypoint(this)
        event.preventDefault()

      $('.ui-slider-handle',this).tooltip(
        title: ->
          "#{getWaypoint(this).distance/1000}km"
        trigger: 'hover focus manual'
        animation: false
        container: 'body'
      ).unbind('keydown')
      
  attachWaypointEvents()
  
  $( '#add-waypoint-button').click ->
    # todo: refactor this into a partial
    $( '#waypoints table tbody' ).append(
      "<tr data-id='#{waypointUniqueId}'>"+
      "<td><input type='text'></td>"+
      "<td><div class='waypoint-distance'></div></td>"+
      "<td><button class='close' type='submit'>×</button></td>"+
      "</tr>")
    waypoint =
      id: waypointUniqueId
      distance: 0
      elevation: window.streams.altitude[0]
      name: ''
    window.waypoints.push(waypoint)
    attachWaypointEvents()
    waypointUniqueId--
    
  #
  # Save and Export
  #

  $('#export-button').click ->
    stravaOnSteroids.export()
    
  $('#save-button').click ->
    # $('#waypoints_field').val(JSON.stringify(waypoints))
    # .parents('form').submit()
    $('.edit_route').submit()
#
# Window resizing
#

$(window).resize ->
  $( "#surface-container" ).height($('#bottom-anchor').offset().top - $('.navbar-fixed-top').outerHeight() - $('#waypoints').outerHeight());
  stravaOnSteroids.postRedraw();
