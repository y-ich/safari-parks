# Siphon: CoffeeScript promgramming environment for iPad
# author: ICHIKAWA, Yuji
# Copyright (C) 2011 safari-park

#
# parameters
#

# editor object
editor = null
jsviewer = null

# constants
holdTime = 400 # milli seconds

#
# utility functions
#

# returns a string with the first character Capitalized.
capitalize = (word) -> word.substring(0, 1).toUpperCase() + word.substring(1)

#
# code snippets
#

# compiles the code in editor into window.compiledJS.
compileSource = ->
    source = editor.getValue()
    window.compiledJS = ''
    try
        window.compiledJS = CoffeeScript.compile source, bare: on
        jsviewer.setValue window.compiledJS
        $('#error').text('')
    catch error
        $('#error').text(error.message)

run = ->
    document.location = '#runpage' if /canvas/.test(window.compiledJS)
    try
        eval window.compiledJS
    catch error
        alert error


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




#
# global variables
#

# keyname associated with current code in "edit" textarea
currentFile = null

# key sound
keySound = new Audio '../sounds/bin090208110829001.mp3'
keySound.enable = true

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
    constructor: (@state, @observer) ->
        @startX = 0
        @startY = 0
        @timer = null

    holdTime: 400 # ms

    setState: (state) ->
        @state = state
        @changed()

    subkey: -> if @observer.childNodes.length >= 2
            @observer.childNodes[1]
        else
            null

    changed: ->
        @state.update(@observer, @subkey())

    clearTimer: ->
        clearTimeout @timer if @timer?
        @timer = null

    touchStart: (startX, startY) ->
        keySound.play() if keySound.enable
        @startX = startX
        @startY = startY
        @setState keyActive
        context = this
        @timer = setTimeout(=>
                @setState keySubActive
            , @holdTime) if @subkey()?

    touchMove: (event) ->
        touchPoint = event.targetTouches[0]
        moveX = touchPoint.pageX - @startX
        moveY = touchPoint.pageY - @startY
        @state.touchMove(this, moveX, moveY)

    touchEnd: -> @state.touchEnd this

# controller class to instantiate each state of a key.
class KeyState
    constructor: ->

    update: (main, sub) ->

    touchMove: (fsm, moveX, moveY) ->

    touchEnd: (fsm) ->

    inRange: (moveX, moveY) -> -58 < moveX < 58 and -58*2 < moveY < 58

# inactive state
keyInactive = new KeyState()

keyInactive.update = (main, sub) ->
    sub.style.display = 'none' if sub?

# active state
keyActive = new KeyState()

keyActive.update = (main, sub) ->
    main.style.backgroundColor = '#a0a0a0'

keyActive.touchMove = (fsm, moveX, moveY) ->
    if fsm.subkey()? and moveY < -30 and -30 < moveX < 30
        fsm.clearTimer()
        fsm.setState keySubActive
    else if not @inRange(moveX, moveY)
        fsm.clearTimer()
        fsm.setState keyInactive

keyActive.touchEnd = (fsm) ->
    fsm.clearTimer()
    editor.insert fsm.observer.title
    fsm.setState keyInactive

# subkey active state
keySubActive = new KeyState()

keySubActive.update = (main, sub) ->
    $(sub).css('color', '#fff')
    $(sub).css('background-image', '-webkit-gradient(linear, left top, left bottom, from(rgb(65,134,245)), to(rgb(25,79,220)))')
    sub.style.display = 'block'

keySubActive.touchMove = (fsm, moveX, moveY) ->
    if not @inRange(moveX, moveY)
        fsm.setState keySubInactive

keySubActive.touchEnd = (fsm) ->
    editor.insert fsm.subkey().title
    fsm.setState keyInactive

# subkey inactive state
keySubInactive = new KeyState()

keySubInactive.update = (main, sub) ->
    $(sub).css('color', '#000')
    $(sub).css('background-image', '-webkit-gradient(linear, left top, left bottom, from(#EEEEF0), to(#D2D2D8))')

keySubInactive.touchMove = (fsm, moveX, moveY) ->
    fsm.setState keySubActive if @inRange(moveX, moveY)

keySubInactive.touchEnd = (fsm) ->
    fsm.setState keyInactive

#
# Application cache dispatches
#
#window.applicationCache.addEventListener 'checking', ->
window.applicationCache.addEventListener 'noupdate', ->
    console.log 'Manifest has no change.'
#window.applicationCache.addEventListener 'downloading', ->
#window.applicationCache.addEventListener 'progress', ->
window.applicationCache.addEventListener 'cached', ->
    alert 'Conguatulation! You can use Siphon offline.'
window.applicationCache.addEventListener 'updateready', ->
    if confirm 'New version was downloaded. Do you want to update?'
        window.applicationCache.swapCache()
        location.reload()
window.applicationCache.addEventListener 'obsolete', ->
    alert 'Manifest was not found, so the application cache is being deleted.'
window.applicationCache.addEventListener 'error', ->
    console.log 'Application cache error.'
    # error occurs when calling update() offline.

$(document).ready ->
    try
        window.applicationCache.update() if navigator.onLine
    catch e
        console.log e
    window.addEventListener 'error', (error, file, line) ->
        console.log error.message + ' file: ' + file + ', line: ' + line

    # jQuery Mobile setting
    $('#editorpage').addBackBtn = false # no back button on top page.

    editor = CodeMirror.fromTextArea $('#edit')[0],
        onChange: -> compileSource()
    editor.element = editor.getWrapperElement()
    editor.insert = (str) -> this.replaceRange(str, this.getCursor())
    editor.setHeight = (str) ->
        this.getScrollerElement().style.height = str
        this.refresh()

    parent = $('#compiled').parent()[0]
    $('#compiled').remove()
    jsviewer = CodeMirror parent, {mode: 'javascript', readOnly: true}
    jsviewer.setHeight = (str) ->
        this.getScrollerElement().style.height = str
        this.refresh()
    $('textarea', jsviewer.getWrapperElement()).attr('disabled', 'true')

    if /iPad/.test(navigator.userAgent)
        $('#keyboard-on')[0].checked = true
    else
        # for desktop safari or chrome
        $('#compiledpage').live 'pageshow', (event, ui) ->
            jsviewer.refresh()

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
        this.model ?= new KeyFSM keyInactive, this
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
        alert 'Siphon\nCoffeeScript Programming Environment\nVersion 0.3.5\nCopyright (C) 2011 ICHIKAWA, Yuji All Rights Reserved.'

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

    compileSource()
