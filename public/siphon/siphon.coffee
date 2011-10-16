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
    catch error
        $('#error').text(error.message).show()


# Eval the compiled js.
evalJS = ->
    try
        eval window.compiledJS
    catch error then alert error


makeSelect = ->
    select = $('#files')[0]

    for i in [select.childNodes.length - 1..2] by -1
        console.log i
        select.removeChild select.childNodes[i]

    for i in [0...localStorage.length]
        e = document.createElement('option')
        e.appendChild(document.createTextNode(localStorage.key(i)))
        select.appendChild(e)


window.applicationCache.addEventListener 'updateready', ->
    if confirm 'アプリケーションの新しいバージョンが利用可能です。更新しますか？'
        cache.swapCache()
        location.reload()

# なぜか.readyの記述はcompileSource()よりも下に置かないといけない
$(document).ready ->
    # スワイプによるスクロール禁止
    document.ontouchmove = -> event.preventDefault()

    # iPadのソフトウェアキーボードが閉じようとするのを防止
    $('.button').mousedown (event) -> event.preventDefault()

    $('.char').click (event) ->
        if this.innerHTML[0] is '&'
            stringInput this.title
        else
            stringInput this.innerHTML
        compileSource()

    $('#tab').click (event) ->
        stringInput '  '
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
        makeSelect()

    $('#saveas').click ->
        currentFile = null
        $('#save').click()

    $('#open').click ->
        if $('#files')[0].value is ''
            alert 'select file'
        else
            $('#edit').val localStorage[$('#files')[0].value]

     $('#delete').click ->
        if $('#files')[0].value is ''
            alert 'select file'
        else
            localStorage.removeItem $('#files')[0].value
            makeSelect()

     $('#update').click -> window.applicationCache.update() if navigator.onLine

    makeSelect()
    compileSource()
