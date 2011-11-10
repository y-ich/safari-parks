# operation mode
debugMode = true

# constants
holdTime = 400 # milli seconds

#
# utilies
#

capitalize = (word) ->
    word.substring(0, 1).toUpperCase() + word.substring(1)

stringInput = (str) ->
    edit = $('#edit')[0]
    edit.focus()
    pos = edit.selectionStart

    edit.value = edit.value.slice(0, pos) + str + edit.value.slice(pos);
    pos = pos + str.length;
    edit.setSelectionRange(pos, pos); # resetting caret position.


# Set up the compilation function, to run when you stop typing.
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


# Eval the compiled js.
evalJS = ->
    try
        eval window.compiledJS
    catch error then alert error


fileOptions = ->
    result = []
    for i in [0...localStorage.length]
        e = document.createElement('option')
        e.appendChild(document.createTextNode(localStorage.key(i)))
        result.push e
    result

resetSelect = (id) ->
    selector = '#' + id
    $(selector).empty()
    option = document.createElement('option')
    option.appendChild(document.createTextNode(capitalize id + '...'))
    option.value = ''
    option.disabled = true
    $(selector).append option
    _(fileOptions()).each (e) -> $(selector).append e

resetSelects = ->
    resetSelect 'open'
    resetSelect 'delete'

# window.applicationCache.addEventListener 'checking', ->


window.applicationCache.addEventListener 'noupdate', ->
    alert 'Manifest has no change.'


# window.applicationCache.addEventListener 'downloading', ->


window.applicationCache.addEventListener 'progress', ->


window.applicationCache.addEventListener 'obsolete', ->
    alert 'No manifest, Offline feature disabled.'


window.applicationCache.addEventListener 'updateready', ->
    if confirm 'New version is downloaded. Do you want to update?'
        window.applicationCache.swapCache()
        location.reload()


window.applicationCache.addEventListener 'cached', ->
    alert 'Now cached.'


window.applicationCache.addEventListener 'error', ->
    alert 'Manifest check error.' if debugMode


#
# global variables
#

currentFile = null

keySound = new Audio '../sounds/bin090208110829001.mp3'

keyState =
    target: null
    second: null
    timer: null
    startX: 0
    startY: 0

#
# software key with upper flick
#

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


class KeyState
    constructor: ->

    update: (main, sub) ->

    touchMove: (fsm, moveX, moveY) ->

    touchEnd: (fsm) ->

    inRange: (moveX, moveY) -> -58 < moveX < 58 and -58*2 < moveY < 58

keyInactive = new KeyState()
keyInactive.update = (main, sub) ->
    main.style.backgroundColor = '#dbdbdb'
    sub.style.display = 'none' if sub?

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

keySubActive = new KeyState()
keySubActive.update = (main, sub) ->
    sub.style.backgroundColor = '#0088ff'
    sub.style.display = 'block'
keySubActive.touchMove = (fsm, moveX, moveY) ->
    if not @inRange(moveX, moveY)
        fsm.setState keySubInactive
keySubActive.touchEnd = (fsm) ->
    stringInput fsm.subkey().title
    fsm.setState keyInactive
    compileSource()

keySubInactive = new KeyState()
keySubInactive.update = (main, sub) ->
   sub.style.backgroundColor = '#dbdbdb'
keySubInactive.touchMove = (fsm, moveX, moveY) ->
    fsm.setState keySubActive if @inRange(moveX, moveY)
keySubInactive.touchEnd = (fsm) ->
    fsm.setState keyInactive


# dispatches

clickSaveas = ->
        currentFile = prompt 'filename:'
        return if not currentFile?
        localStorage.setItem(currentFile, $('#edit').val())
        resetSelects()

# なぜか.readyの記述はcompileSource()よりも下に置かないといけない
$(document).ready ->
    # メインページにバックボタンは表示しない。
    $('#editorpage').addBackBtn = false

    restHeight = window.innerHeight - (380 + 58 * 2 + 55)
    $('#edit').css('height': restHeight + 'px')
    $('#edit').css('max-height': restHeight + 'px')
    if not debugMode
        # スワイプによるスクロール禁止
        document.ontouchmove = -> event.preventDefault()
        for e in $('.scroll')
            e.ontouchmove = ->
                event.stopPropagation() if event.targetTouches.length is 2
        # touches制限をしないと、textarea内でスクロールする余地がない時に全体スクロールする。
        # touchesをtwo finger制限しても、なにかの拍子に全体スクロールする。

        # iPadのソフトウェアキーボードが閉じようとするのを防止
        $('.button').mousedown (event) -> event.preventDefault()

    #
    # soft key board
    #
    $('.button').bind 'touchstart', (event) ->
        touchPoint = event.originalEvent.targetTouches[0]
        if not this.model?
            this.model = new KeyFSM keyInactive, this

        this.model.touchStart touchPoint.pageX, touchPoint.pageY

    $('.button').bind 'touchmove', (event) ->
        this.model.touchMove event.originalEvent
        event.preventDefault() if debugMode

    $('.button').bind 'touchend', (event) ->
        this.model.touchEnd()

    $('#edit').focus()
	# onloadで開始時にテキストエリアをアクティブにしているが、ソフトキーボードは現れないという不具合あり。

    # Listen for keypresses and recompile.
    $('#edit').keyup -> compileSource()
    $('#run').click -> evalJS()

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

    $('#update').click ->
        if navigator.onLine
            window.applicationCache.update()
        else
            alert 'seems you are offline...'

    $('#about').click ->
        alert 'Siphon version 0.2.1\nCopyright (C) safari-park 2011'

    resetSelects()

    $('#open').change ->
        currentFile = $('#open')[0].value
        $('#edit').val localStorage[$('#open')[0].value] if currentFile? and currentFile isnt ''
        $('#open')[0].selectedIndex = 0
        $('#open').selectmenu('refresh')

    $('#delete').change ->
        if confirm 'Do you wan to delete "' + $('#delete')[0].value + '"? (Current file is "' + currentFile + '".)'
            localStorage.removeItem $('#delete')[0].value
            resetSelects()
        $('#delete')[0].selectedIndex = 0
        $('#delete').selectmenu('refresh')

    compileSource()
