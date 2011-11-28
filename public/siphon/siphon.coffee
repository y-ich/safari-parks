# Siphon: CoffeeScript promgramming environment for iPad
# author: ICHIKAWA, Yuji
# Copyright (C) 2011 safari-park

#
# parameters
#

# operation mode
debugMode = false

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

# inserts str at current caret position in #edit textarea.
stringInput = (str) ->
    edit = $('#edit')[0]
    edit.focus()
    pos = edit.selectionStart

    edit.value = edit.value.slice(0, pos) + str + edit.value.slice(pos);
    pos = pos + str.length;
    edit.setSelectionRange(pos, pos); # resetting caret position.


# compiles the code in #edit textarea into window.compiledJS.
compileSource = ->
    source = $('#edit').val()
    window.compiledJS = ''
    try
        window.compiledJS = CoffeeScript.compile source, bare: on
        el = $('#compiled')[0]
        if el.innerText
            el.innerText = window.compiledJS
        else
            $(el).text window.compiledJS
        $('#error').text('')
    catch error
        $('#error').text(error.message)

# evaluates the compiled js.
evalJS = ->
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
        localStorage.setItem(currentFile, $('#edit').val())
        resetSelects()

iOSKeyboardHeight = 307

layoutEditor = ->
    restHeight = window.innerHeight -
        $('.ui-header').outerHeight(true) - $('#error').outerHeight(true) -
        ($('#edit').outerHeight(true) - $('#edit').height()) -
        $('.ui-footer').outerHeight(true)
    if $('#keyboard-on')[0].checked
        keybackHeight = iOSKeyboardHeight + $('#keys').outerHeight(true) -
            $('.ui-footer').outerHeight(true)
        restHeight -= keybackHeight
        $('#keyback').height(keybackHeight + 'px')
        $('#keyback').css('display', 'block')
    else
        $('#keyback').css('display', 'none')
    restHeight = Math.max(restHeight, 12)
    $('#edit').css('height', restHeight + 'px')
    $('#edit').css('max-height', restHeight + 'px')

#
# global variables
#

# keyname associated with current code in "edit" textarea
currentFile = null

# key sound
keySound = new Audio '../sounds/bin090208110829001.mp3'

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
        keySound.play()
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
    stringInput fsm.observer.title
    fsm.setState keyInactive
    compileSource()

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
    stringInput fsm.subkey().title
    fsm.setState keyInactive
    compileSource()

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
    alert 'Manifest has no change.' if debugMode
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
    alert 'Sorry. Application cache error.' if debugMode
    # error occurs offline without calling update().


$(document).ready ->
    window.applicationCache.update() if navigator.onLine

    # jQuery Mobile setting
    $('#editorpage').addBackBtn = false # no back button on top page.

    layoutEditor()

    # problem
    #  When debug console is enabled on iPad, just after loading,
    #  1. the debug console is not showed
    #  2. the innnerHeight is as if it misses debug console.
    #  3. so the edit area is larger than intention.
    #  4. the position of soft key buttons is higher than intention.

    document.body.onresize = layoutEditor

    if not debugMode
        # prevents page scroll
        document.ontouchmove = -> event.preventDefault()

        # enables overflow scroll in scroll class
        $('.scroll').bind 'touchmove', (e) ->
            event = e.originalEvent
            event.stopPropagation() if event.targetTouches.length is 2
        # problem
        #  Page scroll occurs occasionally.
        # trial
        #  Page scroll occurs when there is no space in scroll object if number of fingers are not restricted.

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
        event.preventDefault() if debugMode
        # Because page scroll are enabled at debug mode, page scroll are disabled on buttons

    $('.key.main').bind 'touchend', (event) -> this.model.touchEnd()

    $('#edit').focus()
	# problem
    # My intention is to show native keyboard on load,
    # but just focus, no keyboard on iPad.

    # real-time compiling for native soft keyboard.
    $('#edit').keyup -> compileSource()

    $('.run').click -> evalJS()

    #
    # menu bar
    #
    $('#new').click ->
        $('#edit').val('')
        currentFile = null

    $('#save').click ->
        if not currentFile? or currentFile is ''
            clickSaveas()
        else
            localStorage.setItem(currentFile, $('#edit').val())
            alert '"' + currentFile + '" was saved.'

    $('#saveas').click clickSaveas

    $('#about').click ->
        alert 'Siphon\nCoffeeScript Programming Environment\nVersion 0.2.6\nCopyright (C) 2011 ICHIKAWA, Yuji All Rights Reserved.'

    resetSelects() # "Open...", and "Delete..." menus

    $('#open').change ->
        currentFile = $('#open')[0].value
        if currentFile? and currentFile isnt ''
            $('#edit').val localStorage[$('#open')[0].value]
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

    compileSource()
