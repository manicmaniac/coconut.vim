" Language:	coconut
" Maintainer:	Ryosuke Ito <rito.0305@gmail.com>
" Last Change:	2016 Jun 28

autocmd BufNewFile,BufRead *.coco set filetype=coconut

function! s:DetectCoconut()
    if getline(1) =~ '^#!.*\<coconut\>'
        set filetype=coconut
    endif
endfunction

autocmd BufNewFile,BufRead * call s:DetectCoconut()
