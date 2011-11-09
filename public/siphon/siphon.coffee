# operation mode
debugMode = false

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
# dispatches
#

displaySecondKey = ->
    keyState.second.style.backgroundColor = '#0088ff'
    keyState.second.style.display = 'block'
    keyState.timer = null

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

    $('.button').bind 'touchstart',
        (event) ->
            keySound.play()
            this.style.backgroundColor = '#a0a0a0'
            if this.childNodes.length >= 2
                keyState.target = this
                keyState.second = this.childNodes[1]
                keyState.timer = setTimeout(displaySecondKey, holdTime)
                keyState.startX = event.originalEvent.targetTouches[0].pageX
                keyState.startY = event.originalEvent.targetTouches[0].pageY

    $('.button').bind 'touchmove',
        (event) ->
            moveX = event.originalEvent.targetTouches[0].pageX - keyState.startX
            moveY = event.originalEvent.targetTouches[0].pageY - keyState.startY
            if moveX < -58 or moveX > 58 or moveY < -58*2 or moveY > 58
                if keyState.timer?
                    clearTimeout keyState.timer
                    keyState.timer = null
                if keyState.second? and keyState.second.style.display isnt 'none'and keyState.second.style.display isnt ''
                   keyState.second.style.backgroundColor = '#dbdbdb'
                else
                    this.style.backgroundColor = '#dbdbdb'
            else if keyState.second? and keyState.second.style.display isnt 'none' and keyState.second.style.display isnt ''
                keyState.second.style.backgroundColor = '#0088ff'

            if keyState.timer? and moveY < -30
                clearTimeout keyState.timer
                displaySecondKey()

            event.preventDefault() if debugMode

    $('.button').bind 'touchend',
        (event) ->
            if keyState.timer?
                clearTimeout keyState.timer
                keyState.timer = null
            if this.style.backgroundColor isnt 'rgb(219, 219, 219)' # '#dbdbdb'
                if keyState.second? and keyState.second.style.display isnt 'none' and keyState.second.style.display isnt ''
                    key = if keyState.second.style.backgroundColor isnt 'rgb(219, 219, 219)' # '#dbdbdb'
                            keyState.target.childNodes[1].title
                        else
                            null
                    keyState.second.style.display = 'none'
                    keyState.target = null
                    keyState.second = null
                else
                    key = this.title
                if key? and key isnt ''
                    stringInput key
                    compileSource()
                this.style.backgroundColor = '#dbdbdb'

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
        console.log this
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
