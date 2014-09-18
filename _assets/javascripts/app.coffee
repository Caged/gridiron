index = 0
stadiums = []

render = ->
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
    console.log stadium
    map.flyTo [stadium.lat, stadium.lon], 17.5


  d3.csv 'data/schools.csv', format, (err, data) ->
    data.sort (a, b) -> d3.descending(a.conference, b.conference)
    stadiums = data
    document.addEventListener 'keyup', navigateToStadium

document.addEventListener 'DOMContentLoaded', render
