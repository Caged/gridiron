index = 0
stadiums = []

commafy = d3.format(',')

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

  inspect = (stadium, index) ->
    info.html('').datum(stadium)

    info.append('h3')
      .attr('class', 'title')
      .html((d) -> "
      <a href='http://maps.google.com/maps?t=k&q=#{d.stadium}'>
        <span>#{d.stadium}</span><span class='idx'>#{index}</span>
      </a>")

    info.append('span')
      .attr('class', 'row')
      .html((d) -> "<em>Team:</em><span>#{d.team}</span>")

    info.append('span')
      .attr('class', 'row')
      .html((d) -> "<em>Conference:</em><span>#{d.conference}</span>")

    info.append('span')
      .attr('class', 'row')
      .html((d) -> "<em>Capacity:</em><span>(##{d.capacityRank}) #{commafy(d.capacity)}</span>")

    info.append('span')
      .attr('class', 'row')
      .html((d) -> "<em>Record:</em><span>#{commafy(d.record)}</span>")

    info.append('span')
      .attr('class', 'row')
      .html((d) -> "<em>Built:</em><span>#{d.built}</span>")

    info.append('span')
      .attr('class', 'row')
      .html((d) -> "<em>Expanded:</em><span>#{d.expanded}</span>")

    # info.html "
    #   <a href='http://maps.google.com/maps?t=k&q=#{stadium.stadium}'>
    #     #{stadium.stadium}<span class='team'>#{stadium.team}</span>
    #   </a>"

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
    inspect stadium, idx
    map.flyTo [stadium.lat, stadium.lon], 17.0


  d3.csv 'data/schools.csv', format, (err, data) ->

    data.sort (a, b) -> d3.descending(a.capacity, b.capacity)
    stadium.capacityRank = index + 1 for stadium, index in data
    capacity = d3.extent data, (d) -> d.capacity

    data.sort (a, b) -> d3.descending(a.record, b.record)
    stadium.recordRank = index + 1 for stadium, index in data
    record = d3.extent data, (d) -> d.record

    data.sort (a, b) -> d3.descending(a.conference, b.conference)

    stadiums = data
    debugindex = document.location.search.match(/index=([0-9]+)/i)

    if debugindex and debugindex = parseInt(debugindex[1])
      stadium = stadiums[debugindex]
      inspect stadium, debugindex
      index = debugindex
      map.setCenter [stadium.lat, stadium.lon]
      map.setZoom 16.5
      #return

    document.addEventListener 'keyup', navigateToStadium

document.addEventListener 'DOMContentLoaded', render
