index           = 0
zoom            = 16.5
stadiums        = []
commafy         = d3.format(',')
builtExtent     = null
expandedExtent  = null
capacityExtent  = null
recordExtent    = null

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

  rangeChart = (container, extent, data, formatter) ->
    m = t: 0, r: 30, b: 20, l: 30
    width = parseInt(container.style('width')) - m.l - m.r
    height = 30 - m.t - m.b
    [min, max] = extent

    x = d3.scale.linear()
      .domain([min, max])
      .range [0, width]

    xax = d3.svg.axis().scale(x)
      .ticks(4)
      .tickSize(height)
      .tickFormat(formatter)

    vis = container.append('svg')
      .attr('width', width + m.l + m.r)
      .attr('height', height + m.t + m.b)
    .append('g')
      .attr('transform', "translate(#{m.l}, #{m.t})")

    vis.append('rect')
      .attr('y', height / 2)
      .attr('class', 'backing')
      .attr('width', width)
      .attr('height', 1)

    vis.append('g')
      .call(xax)

    vis.append('text')
      .attr('dx', -m.l)
      .attr('dy', height)
      .text(min)

    vis.append('text')
      .attr('dx', width + 5)
      .attr('dy', height)
      .text(max)

    vis.append('circle')
      .attr('class', 'built')
      .attr('r', 3)
      .attr('cx', (d) -> x(d.built))
      .attr('cy', height / 2)

    vis.append('circle')
      .attr('class', 'expanded')
      .attr('r', 3)
      .attr('cx', (d) -> x(d.expanded))
      .attr('cy', height / 2)


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
    map.setCenter [stadium.lat, stadium.lon]
    map.setZoom zoom
    history.pushState({}, "", "?index=#{idx}")

  d3.csv 'data/combined.csv', format, (err, data) ->
    builtExtent     = d3.extent data, (d) -> d.built
    expandedExtent  = d3.extent data.filter((d) -> d.expanded > 0), (d) -> d.expanded
    capacityExtent  = d3.extent data, (d) -> d.capacity
    recordExtent    = d3.extent data.filter((d) -> d.record > 0), (d) -> d.record
    # data.sort (a, b) -> d3.descending(a.capacity, b.capacity)
    # stadium.capacityRank = index + 1 for stadium, index in data
    # capacity = d3.extent data, (d) -> d.capacity
    #
    # data.sort (a, b) -> d3.descending(a.record, b.record)
    # stadium.recordRank = index + 1 for stadium, index in data
    # record = d3.extent data, (d) -> d.record

    data.sort (a, b) -> d3.descending(a.conference, b.conference)

    stadiums = data
    debugindex = document.location.search.match(/index=([0-9]+)/i)

    if debugindex and debugindex = parseInt(debugindex[1])
      stadium = stadiums[debugindex]
      inspect stadium, debugindex
      index = debugindex
      map.setCenter [stadium.lat, stadium.lon]
      map.setZoom zoom
      #return

    document.addEventListener 'keyup', navigateToStadium

document.addEventListener 'DOMContentLoaded', render
