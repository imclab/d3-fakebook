'use strict'

class D3Fakebook.BarChart extends D3Fakebook.Core
  buildChart: ->
    data = @buildData()

    hasData = false
    _(data).each (d) ->
      hasData = true if d.values.length

    # Don't do any of the data rendering if there's nothing to show
    unless hasData
      @displayNotice 'This dataset cannot be rendered.',
        'There is insufficient data for this chart.'
      return

    maxVal = @findMax data
    minVal = @findMin data

    if maxVal < 0 and minVal < 0
      _maxVal = maxVal
      _minVal = minVal
      maxVal = _minVal
      minVal = _maxVal

    colors = @opts.colors or @countryColors
    @_setColorScale colors, data

    @x0 = d3.scale.ordinal()
      .rangeRoundBands([0, @innerWidth], .1)

    @x1 = d3.scale.ordinal()

    @y = d3.scale.linear()
      .range([@innerHeight, 0])

    # Set the X and Y axes
    @xAxis = @createAxis 'x', @x0, 'bottom'
    @yAxis = @createAxis 'y', @y, 'left',
      size :
        major : 0 - @innerWidth
        minor : 0 - @innerWidth
        end   : 0 - @innerWidth

    countries = @setCountries @color, data

    categories = d3.keys(data[0]).filter (key) ->
      key isnt 'date' and key isnt 'values'

    @x0.domain data.map((d) -> d.date)
    @x1.domain(categories).rangeRoundBands([0, @x0.rangeBand()])
    @y.domain([minVal, maxVal])

    @drawChart data

  findMin : (data) ->
    min = d3.min data, (d) ->
      d3.min d.values, (d) ->
        d.value

    # Set a floor for the chart; either 0 or "min", whichever value is
    # smaller. This should help in preventing "invisible" bars for most
    # data sets.
    Math.min 0, min

  findMax : (data) ->
    max = d3.max data, (d) ->
      d3.max d.values, (d) ->
        d.value

    max

  createAxis : (plane, scale, position, ticks) ->
    _ticks =
      count     : 10
      subdivide : false
      padding   : 10
      size      :
        major : 0
        minor : 0
        end   : 0

    ticks = _.extend _ticks, ticks or {}

    axis = d3.svg.axis()
            .scale(scale)
            .orient(position)

    if plane.match /^y/
      axis.ticks(ticks.count)
          .tickSize(ticks.size.major, ticks.size.minor, ticks.size.end)
          .tickPadding(ticks.padding)

      @setTickFormat(axis)

    axis

  setCountries : (scale, data) ->
    scale.domain().map (name) ->
      name   : name
      values : data[name]

  buildData : ->
    data   = @data
    dates  = _.keys data
    values = _.values data
    _(dates).each (date) ->
      data[date].values = []
      _(data[date]).each (v, k) ->
        unless k is 'date' or k is 'values' or _(v).isNaN()
          obj =
            name  : k
            value : +v
            date  : +data[date].date

          if k is 'World'
            data[date].values.unshift obj
          else
            data[date].values.push obj

    data

  drawChart : (data) ->
    @drawAxes()
    @drawBars(data)
    @drawLegend()
    @drawTitle()

  drawBars : (data) ->
    format = (val) ->
      formatter = d3.format('n')
      value = formatter(val)
      if value is '-0'
        value = '0'
      value

    date = @svg.selectAll('.date')
              .data(data)
              .enter().append('g')
              .attr('class', 'g')
              .attr('transform', (d) => 'translate(' + @x0(d.date) + ',0)')

    date.selectAll('rect')
        .data((d) -> d.values)
        .enter().append('rect')
        .attr('class', 'chart-bar')
        .attr('width', @x1.rangeBand())
        .attr('x', (d) => @x1 d.name)
        .attr('y', (d) => @y d.value)
        .attr('title', (d) -> d.name)
        .attr('height', (d) => @innerHeight - @y(d.value))
        .style('fill', (d) => @color d.name)
        .attr('data-legend', (d) -> d.name)
        .attr('data-legend-color', (d) => @color d.name)
        .attr('data-toggle', 'popover')
        .attr('data-content', (d) =>
          "<strong style=\"color: #{@color d.name};\">
          #{format @utils.round2(d.value)}
          #</strong> #{d.date}"
        )

  drawAxes : () ->
    @drawXAxis()
    @drawYAxis()

  drawXAxis : ->
    @svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', 'translate(0,' + @innerHeight + ')')
        .call(@xAxis)

  drawYAxis : ->
    yPosition = 0 - @opts.yLabelOffset or @margin.left / 6

    labelContent = @svg.append('g')
        .attr('class', 'y axis')
        .call(@yAxis)
        .append('text')
        .attr('transform', "rotate(-90)translate(#{0}, #{yPosition})")
        .style('text-anchor', 'middle')
        .attr('class', 'chart-label chart-label-y-axis')

    labelContent.append('tspan')
        .attr('x', '-160')
        .attr('y', '-4.2em')
        #.text("#{_.str.words(@opts.yLabel, ", ")[0]}")
        .text("#{@opts.yLabel}")

    #labelContent.append('tspan')
        #.attr('x', '-160')
        #.attr('y', '-3.0em')
        #.text(_.str.words(@opts.yLabel, ", ")[1])
