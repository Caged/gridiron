index           = 0
zoom            = 16.6
stadiums        = []
commafy         = d3.format(',')
builtExtent     = null
expandedExtent  = null
capacityExtent  = null
recordExtent    = null

formatSymbol = (number, abs = false) ->
  number = Math.abs(number) if abs
  return number if number < 1e+3
  pf = d3.formatPrefix(number)
  "#{pf.scale(number)}#{pf.symbol}"

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
      .text(if min.toString().length > 4 then formatter(min) else min)

    vis.append('text')
      .attr('dx', width + 5)
      .attr('dy', height)
      .text(if max.toString().length > 4 then formatter(max) else max)

    vis.selectAll('.point')
      .data(data)
    .enter().append('circle')
      .attr('r', 3)
      .attr('class', (d) -> d.key.toLowerCase())
      .attr('cx', (d) -> x(d.val))
      .attr('cy', height / 2)

  inspect = (stadium, index) ->
    info.html('').datum(stadium)

    info.append('h3')
      .attr('class', 'title')
      .html((d) -> "
      <a href='http://maps.google.com/maps?t=k&q=#{d.stadium}'>
        <span>#{d.stadium}</span>
      </a>")

    info.append('span')
      .attr('class', 'row')
      .html((d) -> "<em>Team:</em><span class='val'>#{d.team} #{d.nickname}</span>")

    info.append('span')
      .attr('class', 'row')
      .html((d) -> "<em>Location:</em><span class='val'>#{d.city}, #{d.state}</span>")

    if stadium.joined_fbs
      info.append('span')
        .attr('class', 'row')
        .html((d) -> "<em>Joined FBS:</em><span class='val'>#{d.joined_fbs}</span>")

    built = info.append('span')
      .attr('class', 'row')

    min = Math.min builtExtent[0], expandedExtent[0]
    max = Math.max builtExtent[1], expandedExtent[1]
    data = [
      { key: 'Built', val: stadium.built }
      { key: 'Expanded', val: stadium.expanded }
    ]

    rangeChart built, [min, max], data, ((d) ->  d.toString().substring(2))

    built.append('span')
      .attr('class', 'legend')
      .html((d) -> "
        <span class='built'><em>Built:</em> <span>#{d.built}</span></span>
        <span class='expanded'><em>Expanded:</em> <span>#{if d.expanded is 0 then 'n/a' else d.expanded}</span></span>
      ")

    capacity = info.append('span')
      .attr('class', 'row')

    min = Math.min capacityExtent[0], recordExtent[0]
    max = Math.max capacityExtent[1], recordExtent[1]
    data = [
      { key: 'Capacity', val: stadium.capacity }
      { key: 'Record', val: stadium.record }
    ]

    rangeChart capacity, [min, Math.ceil((max+1)/1000)*1000], data, formatSymbol
    capacity.append('span')
      .attr('class', 'legend')
      .html((d) -> "
        <span class='capacity'><em>Capacity:</em> <span>#{commafy d.capacity}</span></span>
        <span class='record'><em>Record:</em> <span>#{if d.record is 0 then 'n/a' else commafy d.record}</span></span>
      ")

    logo = info.append('div')
      .attr('class', 'logo')

    if stadium.conference isnt 'Independent'
      logo.append('img')
        .attr('class', 'logo-image')
        .style('max-width', "#{parseFloat(info.style('width'))}px")
        .attr('src', (d) -> "images/#{d.conference.toLowerCase().replace(' ', '-')}.png")

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
