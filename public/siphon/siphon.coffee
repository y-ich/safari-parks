# operation mode
debugMode = false

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


keyOptions = ->
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
    _(keyOptions()).each (e) -> $(selector).append e

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
    if confirm 'New version is available. Do you update?'
        window.applicationCache.swapCache()
        location.reload()


window.applicationCache.addEventListener 'cached', ->
    alert 'Now cached.'


window.applicationCache.addEventListener 'error', ->
    alert 'Sorry, seems error.'

#
# global variables
#

currentFile = null

# keySound = new Audio '../sounds/Tink.aif'
keySound = new Audio '../sounds/key_click1.mp3'

keyStart =
    target: null
    timer: null
    pageX: 0
    pageY: 0

#
# dispatches
#

displaySecondKey = ->
    secondKey = keyStart.target.childNodes[1]
    secondKey.style.backgroundColor = '#0088ff'
    secondKey.style.display = 'block'
    keyStart.timer = null

clickSaveas = ->
        currentFile = prompt 'filename:'
        return if not currentFile?
        localStorage.setItem(currentFile, $('#edit').val())
        resetSelects()

# なぜか.readyの記述はcompileSource()よりも下に置かないといけない
$(document).ready ->
    # メインページにバックボタンは表示しない。
    $('#editorpage').addBackBtn = false

    if not debugMode
        # スワイプによるスクロール禁止
        document.ontouchmove = -> event.preventDefault()
        for e in $('.scroll')
            e.ontouchmove = ->
                event.stopPropagation()
        # touches制限をしないと、textarea内でスクロールする余地がない時に全体スクロールする。
        # touchesをtwo finger制限しても、なにかの拍子に全体スクロールする。

        # iPadのソフトウェアキーボードが閉じようとするのを防止
        $('.button').mousedown (event) -> event.preventDefault()

    $('.button').bind 'touchstart',
        (event) ->
            keySound.play()
            this.style.backgroundColor = '#a0a0a0'
            if this.childNodes.length >= 2
                keyStart.target = this
                keyStart.timer = setTimeout(displaySecondKey, 400)
                keyStart.pageX = event.originalEvent.targetTouches[0].pageX
                keyStart.pageY = event.originalEvent.targetTouches[0].pageY

    $('.button').bind 'touchmove',
        (event) ->
            if keyStart.timer? and event.originalEvent.targetTouches[0].pageY - keyStart.pageY < -30
                clearTimeout keyStart.timer
                displaySecondKey()
            event.preventDefault() if debugMode

    $('.button').bind 'touchend',
        (event) ->
            clearTimeout keyStart.timer if keyStart.timer?
            this.style.backgroundColor = '#dbdbdb'
            if keyStart.target? and keyStart.target.childNodes[1].style.display isnt 'none'
                key = keyStart.target.childNodes[1].title
                keyStart.target.childNodes[1].style.display = 'none'
                keyStart.target = null
            else
                key = this.title
            stringInput key
            compileSource()

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
            console.log 'pass'
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
        alert 'Siphon version 0.2.0\nCopyright (C) safari-park 2011'

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
