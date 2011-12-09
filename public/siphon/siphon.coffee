# Siphon: CoffeeScript promgramming environment for iPad
# author: ICHIKAWA, Yuji
# Copyright (C) 2011 safari-park

#
# parameters
#

# editor object
editor = null
jsviewer = null

#
# utility functions
#

# returns a string with the first character capitalized.
capitalize = (word) -> word.substring(0, 1).toUpperCase() + word.substring(1)

#
# code snippets
#

# changes page to 'runpage' if the program uses 'canvas' and evals it.
run = ->
    document.location = '#runpage' if /canvas/.test jsviewer.getValue()
    try
        eval jsviewer.getValue()
    catch error
        alert error.message


# utility for resetSelect
fileOptions = ->
    result = []
    for i in [0...localStorage.length]
        e = document.createElement('option')
        e.appendChild(document.createTextNode(localStorage.key(i)))
        result.push e
    result

# utility for resetSelects
resetSelect = (id) ->
    selector = '#' + id
    $(selector).empty()
    option = document.createElement('option')
    option.appendChild(document.createTextNode(capitalize id + '...'))
    option.value = ''
    option.disabled = true
    $(selector).append option
    fileOptions().forEach (e) -> $(selector).append e

# makes "Open..." and "Delete..." select menu.
resetSelects = ->
    resetSelect 'open'
    resetSelect 'delete'

# dispatch for saveas
clickSaveas = ->
        currentFile = prompt 'filename:'
        return if not currentFile?
        localStorage.setItem(currentFile, editor.getValue())
        resetSelects()

iOSKeyboardHeight = 307

layoutEditor = ->
    restHeight = window.innerHeight -
        $('.ui-header').outerHeight(true) -
        $('#error').outerHeight(true) -
        ($(editor.element).outerHeight(true) - $(editor.element).height())
    if $('#keyboard-on')[0].checked
        $('#keyback').css('display', 'block')
        keybackHeight = iOSKeyboardHeight + $('#keys').outerHeight(true)
        restHeight -= keybackHeight
        $('#keyback').height(keybackHeight + 'px')
    else
        $('#keyback').css('display', 'none')
    restHeight = Math.max(restHeight, 12)
    editor.setHeight restHeight + 'px'
    jsElement = jsviewer.getWrapperElement()
    jsviewer.setHeight (window.innerHeight -
        $('.ui-header').outerHeight(true) -
        ($(jsElement).outerHeight(true) - $(jsElement).height())) + 'px'

keyCodes =
    'Control' : 17
    'Alt' : 18
    'Meta' : 91
    'Left' : 37
    'Right' : 39
    'Up' : 38
    'Home' : 36
    'PageUp' : 33
    'U+0009' : 9 # tab
    'Down' : 40
    'End' : 35
    'PageDown' : 34
    'Shift' : 16

KeyboardEvent.DOM_KEY_LOCATION_STANDARD = 0

# emulates keyboard event.
# Since many properties of KeyboardEvent are read only and can not be set,
# mobile property is added instead.
fireKeyEvent = (type, keyIdentifier, keyCode, charCode) ->
    e = document.createEvent 'KeyboardEvent'
    e.initKeyboardEvent type, true, true, window, keyIdentifier,
        KeyboardEvent.DOM_KEY_LOCATION_STANDARD, ''
    # There is no getModifiersState method in webkit, so you have no way to know the content of modifiersList. So I use '' in the last argument.
    e.mobile =
        keyCode : keyCode
        charCode : charCode
    ta = editor.getInputField()

    # Since cursor key doesn't have any effect above, it is treated below.
    if type is 'keydown'
        switch keyIdentifier
            when 'Left'
                pos = Math.max ta.selectionEnd - 1, 0
                ta.setSelectionRange pos, pos
            when 'Right'
                pos = Math.min ta.selectionEnd + 1, ta.value.length
                ta.setSelectionRange pos, pos
            when 'Up'
                xy = pos2xy ta.value, ta.selectionEnd
                xy.y = xy.y - 1 if xy.y > 0
                pos = xy2pos ta.value, xy
                ta.setSelectionRange pos, pos
            when 'Down'
                xy = pos2xy ta.value, ta.selectionEnd
                xy.y = xy.y + 1
                pos = xy2pos ta.value, xy
                ta.setSelectionRange pos, pos
    ta.dispatchEvent(e)


pos2xy = (str, pos) ->
    lines = str.split('\n')
    head = 0
    for y in [0...lines.length]
        if head <= pos <= head + lines[y].length
            return {x: pos - head, y: y}
        head += lines[y].length + 1 # +1 is for '\n'.
    error = new Error()
    error.name = 'overposition'
    error.message = 'pos is larger than str.'
    throw error

xy2pos = (str, xy) ->
    lines = str.split('\n')
    return str.length unless 0 <= xy.y < lines.length
    pos = 0
    pos += lines[y].length + 1 for y in [0...xy.y]
    return pos + Math.min(xy.x, lines[y].length)

TextEvent.DOM_INPUT_METHOD_KEYBOARD = 1

fireTextEvent = (str) ->
    e = document.createEvent 'TextEvent'
    e.initTextEvent 'textInput', true, true, window, str,
        TextEvent.DOM_INPUT_METHOD_KEYBOARD
    editor.getInputField().dispatchEvent(e)

#
# global variables
#

# keyname associated with current code in "edit" textarea
currentFile = null

# key sound
# tunes perfomance by keep pausing during no sound.
keySound =
    source : new Audio '../sounds/click.aiff'
    enable : true
    play : ->
        return if not @enable
        @source.play()
        keySound.timer = setTimeout ->
                keySound.source.pause()
                try
                    keySound.source.currentTime = 0
                catch e
            , 30

keySound.source.load()

#
# software key with upper flick
#
# usage:
#  1. prepare keys in an HTML file like the below
#    <div title="+">+
#        <div title="-">-</div>
#    </div>
#    "title" property is used for output at key release.
#    The child element is a second key, so basically invisible.
#    you need to setup such things with layout in CSS.
#  2. create instances of KeyFSM.
#     Lazy assignment may be good.
#  3. call touchStart, touchMove, and touchEnd in corresponding
#     EventListeners respectively.
#
# parameters:
#  KeyFSM.holdTime: hold time to activate subkey
#
# implementation:
#  Using MVC pattern, KeyFSM is Model, DOM is V, and KeyState is C.
#  KeyState uses "Choosing Method."
#  KeyFSM uses Observer pattern.
#  There is a single controller using four instances of KeyState.
#  So updating method for each key is one kind. that is kind of restriction.

# model class
class KeyFSM
    constructor : (@state, @observer, @holdTime) ->

    setState : (state) ->
        @state = state
        @changed()

    subkey : -> @observer.childNodes[1] ? null

    changed : -> @state.update(@observer, @subkey())

    clearTimer : ->
        clearTimeout @timer if @timer?
        @timer = null

    touchStart : (@startX, @startY) ->
        setTimeout (-> keySound.play()), 0
        @setState keyActive
        if @subkey()?
            @timer = setTimeout (=> @setState keySubActive), @holdTime
        fireKeyEvent 'keydown', @observer.id, @keyCode(), 0

    touchMove : (event) ->
        touchPoint = event.targetTouches[0]
        moveX = touchPoint.pageX - @startX
        moveY = touchPoint.pageY - @startY
        @state.touchMove this, moveX, moveY

    touchEnd : ->
        @state.touchEnd this
        fireKeyEvent 'keyup', @observer.id, @keyCode(), 0

    keyCode: ->
        if @observer.id? then keyCodes[@observer.id]
        else if @observer.title? then @observer.title.charCodeAt(0)
        else 0

# controller class to instantiate each state of a key.
class KeyState
    constructor : ->

    update : (main, sub) ->

    touchMove : (fsm, moveX, moveY) ->

    touchEnd : (fsm) ->

    inRange : (moveX, moveY) ->
        keySize = $('.key').width()
        -keySize < moveX < keySize and -2 * keySize < moveY < keySize

# inactive state
keyInactive = new KeyState()

keyInactive.update = (main, sub) -> sub.style.display = 'none' if sub?

# active state
keyActive = new KeyState()

keyActive.update = (main, sub) -> main.style.backgroundColor = '#a0a0a0'

keyActive.touchMove = (fsm, moveX, moveY) ->
    flickLength = 30
    if fsm.subkey()? and moveY < -flickLength and -flickLength < moveX < flickLength
        fsm.clearTimer()
        fsm.setState keySubActive
    else if not @inRange(moveX, moveY)
        fsm.clearTimer()
        fsm.setState keyInactive

keyActive.touchEnd = (fsm) ->
    fsm.clearTimer()
    if fsm.observer.title?
      code = fsm.observer.title.charCodeAt(0)
      fireTextEvent fsm.observer.title
      fireKeyEvent 'keypress', code, code
    fsm.setState keyInactive

# subkey active state
keySubActive = new KeyState()

keySubActive.update = (main, sub) ->
    $(sub).css 'color', '#fff'
    $(sub).css 'background-image',
        '-webkit-gradient(linear, left top, left bottom, from(rgb(65,134,245)), to(rgb(25,79,220)))'
    sub.style.display = 'block'

keySubActive.touchMove = (fsm, moveX, moveY) ->
    fsm.setState keySubInactive unless @inRange(moveX, moveY)


keySubActive.touchEnd = (fsm) ->
    if fsm.subkey().title? and fsm.subkey().title isnt ''
      c = fsm.subkey().title.charCodeAt(0)
      fireTextEvent fsm.subkey().title
      fireKeyEvent 'keypress', c, c
    fsm.setState keyInactive

# subkey inactive state
keySubInactive = new KeyState()

keySubInactive.update = (main, sub) ->
    $(sub).css 'color', '#000'
    $(sub).css 'background-image',
        '-webkit-gradient(linear, left top, left bottom, from(#EEEEF0), to(#D2D2D8))'

keySubInactive.touchMove = (fsm, moveX, moveY) ->
    fsm.setState keySubActive if @inRange(moveX, moveY)

keySubInactive.touchEnd = (fsm) -> fsm.setState keyInactive

#
# Application cache dispatches
#
appCache = window.applicationCache
#appCache.addEventListener 'checking', ->
appCache.addEventListener 'noupdate', ->
    console.log 'Manifest has no change.'
#appCache.addEventListener 'downloading', ->
#appCache.addEventListener 'progress', ->
appCache.addEventListener 'cached', ->
    alert 'Conguatulation! You can use Siphon offline.'
appCache.addEventListener 'updateready', ->
    if confirm 'New version was downloaded. Do you want to update?'
        appCache.swapCache()
        location.reload()
appCache.addEventListener 'obsolete', ->
    alert 'Manifest was not found, so the application cache is being deleted.'
appCache.addEventListener 'error', ->
    console.log 'Application cache error.'
    # error occurs when calling update() offline.

$(document).ready ->
    try
        appCache.update() if navigator.onLine
    catch e
        console.log e

    # jQuery Mobile setting
    $('#editorpage').addBackBtn = false # no back button on top page.

    editor = CodeMirror $('#editor')[0],
        value :  '''
                ###
                # This script is from https://github.com/davidguttman/crazy_delicious_coffee_processing/blob/tutorial/public/js/coffee_draw.coffee by D. Guttman.
                # BEFORE RUNNING THIS SCRIPT, PLEASE IMPORT Processing.js API!
                ###

                coffee_draw = (p5) ->
                  p5.setup = () ->
                    p5.size($(window).width(), $(window).height())
                    p5.background(0)
                    @beans = []

                  p5.draw = () ->
                    x_off = p5.frameCount * 0.0003
                    y_off = x_off + 20

                    x = p5.noise(x_off) * p5.width
                    y = p5.noise(y_off) * p5.height

                    if p5.frameCount % 8 == 0
                      bean = new Bean(p5, {
                        x: x
                        y: y
                        x_off: x_off
                        y_off: y_off
                      })
                      @beans.push(bean)

                    bean.draw() for bean in @beans

                class Bean
                  constructor: (@p5, opts) ->
                    @x = opts.x
                    @y = opts.y

                    @x_off = opts.x_off
                    @y_off = opts.y_off

                    @vel = opts.vel || 3
                    @accel = opts.accel || -0.003

                  draw: () ->
                    return unless @vel > 0

                    @x_off += 0.0007
                    @y_off += 0.0007

                    @vel += @accel

                    @x += @p5.noise(@x_off) * @vel - @vel/2
                    @y += @p5.noise(@y_off) * @vel - @vel/2

                    @set_color()
                    @p5.point(@x, @y)


                  set_color: () ->
                    @p5.colorMode(@p5.HSB, 360, 100, 100)

                    h = @p5.noise((@x_off+@y_off)/2)*360
                    s = 100
                    b = 100
                    a = 4

                    @p5.stroke(h, s, b, a)

                canvas = document.getElementById "canvas"
                processing = new Processing(canvas, coffee_draw)
                '''
        mode : 'coffeescript'
        onChange : -> editor.compile()
        onKeyPrefetch : (e) ->
            e.mobile ?= {}
            e.mobile.metaKey = $('#Meta')[0].model? and
                    $('#Meta')[0].model.state is keyActive
            e.mobile.ctrlKey = $('#Control')[0].model? and
                    $('#Control')[0].model.state is keyActive
            e.mobile.altKey = $('#Alt')[0].model? and
                    $('#Alt')[0].model.state is keyActive
            e.mobile.shiftKey = $('#Shift')[0].model? and
                    $('#Shift')[0].model.state is keyActive

    editor.element = editor.getWrapperElement()
    editor.setHeight = (str) ->
        this.getScrollerElement().style.height = str
        this.refresh()
    editor.compile = ->
        try
            jsviewer.setValue CoffeeScript.compile @getValue(), bare : on
            $('#error').text('')
        catch error
            $('#error').text(error.message)

    parent = $('#compiled').parent()[0]
    $('#compiled').remove()
    jsviewer = CodeMirror parent, {mode : 'javascript', readOnly : true}
    jsviewer.setHeight = (str) ->
        this.getScrollerElement().style.height = str
        this.refresh()
    $('textarea', jsviewer.getWrapperElement()).attr 'disabled', 'true'

    if /iPad/.test(navigator.userAgent)
        $('#keyboard-on')[0].checked = true
    else
        # for desktop safari or chrome
        $('#editorpage').live 'pageshow', (event, ui) -> editor.refresh()
        $('#compiledpage').live 'pageshow', (event, ui) -> jsviewer.refresh()

    layoutEditor()
    # problem
    #  When debug console is enabled on iPad, just after loading,
    #  1. the debug console is not showed
    #  2. the innnerHeight is as if it misses debug console.
    #  3. so the edit area is larger than intention.
    #  4. the position of soft key buttons is higher than intention.

    document.body.onresize = layoutEditor

    # prevents native soft keyboard to slip down when button was released.
    $('.key.main').mousedown (event) -> event.preventDefault()

    #
    # HTML soft keyboard
    #
    $('.key.main').bind 'touchstart', (event) ->
        touchPoint = event.originalEvent.targetTouches[0]

        # lazy initialization
        this.model ?= new KeyFSM keyInactive, this, 400 #milli seconds
        this.model.touchStart touchPoint.pageX, touchPoint.pageY

    $('.key.main').bind 'touchmove', (event) ->
        this.model.touchMove event.originalEvent
        event.preventDefault()
        # Because page scroll are enabled at debug mode, page scroll are disabled on buttons

    $('.key.main').bind 'touchend', (event) -> this.model.touchEnd()

    $('.run').click -> run()

    #
    # menu bar
    #
    $('#new').click ->
        editor.setValue('')
        currentFile = null

    $('#save').click ->
        if not currentFile? or currentFile is ''
            clickSaveas()
        else
            localStorage.setItem(currentFile, editor.getValue())
            alert '"' + currentFile + '" was saved.'

    $('#saveas').click clickSaveas

    $('#about').click ->
        alert 'Siphon\nCoffeeScript Programming Environment\nVersion 0.3.6\nCopyright (C) 2011 ICHIKAWA, Yuji All Rights Reserved.'

    resetSelects() # "Open...", and "Delete..." menus

    $('#open').change ->
        currentFile = $('#open')[0].value
        if currentFile? and currentFile isnt ''
            editor.setValue localStorage[$('#open')[0].value]
        $('#open')[0].selectedIndex = 0 # index = 0 means "Open..."
        $('#open').selectmenu('refresh')

    $('#delete').change ->
        if confirm 'Do you want to delete "' + $('#delete')[0].value +
                '"? (Current file is "' + currentFile + '".)'
            localStorage.removeItem $('#delete')[0].value
            resetSelects()
        $('#delete')[0].selectedIndex = 0 # index = 0 means "Delete..."
        $('#delete').selectmenu('refresh')

    $('#import').change ->
        if confirm 'Do you want to import "' + $('#import')[0].value + '"?'
            ###
            # appendTo of script element doesn't work.
            html = '<script type="text/javascript" src="' + $('#import')[0].value + '"></script>'
            $(html).appendTo('head')
            ###
            script = document.createElement('script')
            script.type = 'text/javascript'
            script.src = $('#import')[0].value
            document.head.appendChild(script)
        $('#import')[0].selectedIndex = 0 # index = 0 means "Import..."
        $('#import').selectmenu('refresh')

    $('#keyboard-on').change layoutEditor

    $('#key-sound').change ->
        keySound.enable = if $('#key-sound')[0].checked then true else false

    $('#codemirror').change ->

    editor.compile()
