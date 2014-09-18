index = 0
stadiums = []

render = ->
  info = d3.select '.js-stadium'

  mapboxgl.accessToken = 'pk.eyJ1IjoiY2FnZWQiLCJhIjoiQjd2aXNGYyJ9.gr1QeGYwG1QYUW47I-DqaQ'
  map = new mapboxgl.Map
    container: 'js-map'
    center: [41.676056, -86.249631],
    zoom: 15.5
    style: 'https://www.mapbox.com/mapbox-gl-styles/styles/satellite-v4.json'

  map.on 'click', (e) ->
    location = map.unproject e.point
    console.log "#{location.lng},#{location.lat}"

  format = (data) ->
    data.lat = parseFloat data.lat
    data.lon = parseFloat data.lon
    data.built = +data.built
    data.expanded = +data.expanded
    data.capacity = +data.capacity
    data.record = +data.record
    data.permalink = data.stadium.toLowerCase().replace(/\s+/g, '-')
    data

  inspect = (stadium) ->
    info.html "
      <a href='http://maps.google.com/maps?t=k&q=#{stadium.stadium}'>
        #{stadium.stadium}<span class='team'>#{stadium.team}</span>
      </a>"

    console.log stadium

  navigateToStadium = (event) ->
    idx = index
    if event.keyCode is 37
      idx -= 1
      idx = (stadiums.length - 1) if idx < 0

    if event.keyCode is 39
      idx += 1
      idx = 0 if idx > (stadiums.length - 1)

    index = idx
    stadium = stadiums[idx]
    inpsect stadium
    map.flyTo [stadium.lat, stadium.lon], 17.0


  d3.csv 'data/schools.csv', format, (err, data) ->
    data.sort (a, b) -> d3.descending(a.conference, b.conference)
    stadiums = data
    debugindex = document.location.search.match(/index=([0-9]+)/i)[1]

    if debugindex
      stadium = stadiums[debugindex]
      inspect stadium
      map.setCenter [stadium.lat, stadium.lon]
      map.setZoom 16.5
      return

    document.addEventListener 'keyup', navigateToStadium

document.addEventListener 'DOMContentLoaded', render
