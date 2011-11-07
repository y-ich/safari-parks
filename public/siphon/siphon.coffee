#
# utilies
#
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


$('#files_to_open').change (event) ->
    if confirm 'Open ' + event.target.value + '?'
        $('#edit').val localStorage[event.target.value]


$('#files_to_delete').change (event) ->
    if confirm 'Delete ' + event.target.value + '?'
        localStorage.removeItem event.target.innerHTML


keyOptions = ->
    result = []
    for i in [0...localStorage.length]
        e = document.createElement('option')
        e.appendChild(document.createTextNode(localStorage.key(i)))
        result.push e
    result


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


keySound = new Audio '../sounds/Tink.aif'

keyStart =
    target: null
    timer: null
    pageX: 0
    pageY: 0

displaySecondKey = ->
    secondKey = keyStart.target.childNodes[1]
    secondKey.style.backgroundColor = '#0088ff'
    secondKey.style.visibility = 'visible'
    keyStart.timer = null


# なぜか.readyの記述はcompileSource()よりも下に置かないといけない
$(document).ready ->
    # メインページにバックボタンは表示しない。
    $('#editorpage').addBackBtn = false

    ###
    # スワイプによるスクロール禁止
    document.ontouchmove = -> event.preventDefault()
    for e in $('.scroll')
        e.ontouchmove = ->
            event.stopPropagation() if event.touches.length == 2
    # touches制限をしないと、textarea内でスクロールする余地がない時に全体スクロールする。
    # touches制限しても、なにかの拍子に全体スクロールする。

    # iPadのソフトウェアキーボードが閉じようとするのを防止
    $('.button').mousedown (event) -> event.preventDefault()
    ###

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
            event.preventDefault()

    $('.button').bind 'touchend',
        (event) ->
            clearTimeout keyStart.timer if keyStart.timer?
            this.style.backgroundColor = '#dbdbdb'
            if keyStart.target? and keyStart.target.childNodes[1].style.visibility == 'visible'
                key = keyStart.target.childNodes[1].title
                keyStart.target.childNodes[1].style.visibility = 'hidden'
                keyStart.target = null
            else
                key = this.title
            stringInput key
            compileSource()

    $('#edit').focus()
	# onloadで開始時にテキストエリアをアクティブにしたいがiPadでは機能していない

    # Listen for keypresses and recompile.
    $('#edit').keyup -> compileSource()
    $('#run').click -> evalJS()

    $('#new').click ->
        $('#edit').val('')
        currentFile = null

    $('#save').click ->
        while not currentFile? or currentFile is ''
            currentFile = prompt 'filename:'
            return if currentFile is null
        localStorage.setItem currentFile, $('#edit').val()

    $('#saveas').click ->
        currentFile = null
        $('#save').click()

    $('#open').click ->
        select = $('#files_to_open')
        select.empty()
        _(keyOptions()).each (e) -> select.append e
        select.css 'display', 'block'
        select.focus()

    $('#delete').click ->
        select = $('#files_to_delete')
        select.empty()
        _(keyOptions()).each (e) -> select.append e
        select.focus()

    $('#update').click ->
        if navigator.onLine
            window.applicationCache.update()
        else
            alert 'seems you are offline...'

    $('#about').click ->
        alert 'Siphon version 0.1.1\nCopyright (C) safari-park 2011'

    compileSource()
