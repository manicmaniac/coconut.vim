" Vim syntax file
" Language:	Coconut
" Maintainer:	Ryosuke Ito <rito.0305@gmail.com>
" Last Change:	2016 Jun 27
" Credits:	Zvezdan Petkovic <zpetkovic@acm.org>
"		Neil Schemenauer <nas@python.ca>
"		Dmitry Vasiliev
"		Ryosuke Ito
"
"		This version is a major rewrite by Zvezdan Petkovic.
"
"		- introduced highlighting of doctests
"		- updated keywords, built-ins, and exceptions
"		- corrected regular expressions for
"
"		  * functions
"		  * decorators
"		  * strings
"		  * escapes
"		  * numbers
"		  * space error
"
"		- corrected synchronization
"		- more highlighting is ON by default, except
"		- space error highlighting is OFF by default
"
" Optional highlighting can be controlled using these variables.
"
"   let coconut_no_builtin_highlight = 1
"   let coconut_no_doctest_code_highlight = 1
"   let coconut_no_doctest_highlight = 1
"   let coconut_no_exception_highlight = 1
"   let coconut_no_number_highlight = 1
"   let coconut_space_error_highlight = 1
"
" All the options above can be switched on together.
"
"   let coconut_highlight_all = 1
"

" For version 5.x: Clear all syntax items.
" For version 6.x: Quit when a syntax file was already loaded.
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" We need nocompatible mode in order to continue lines with backslashes.
" Original setting will be restored.
let s:cpo_save = &cpo
set cpo&vim

" Keep Python keywords in alphabetical order inside groups for easy
" comparison with the table in the 'Python Language Reference'
" http://docs.python.org/reference/lexical_analysis.html#keywords.
" Groups are in the order presented in NAMING CONVENTIONS in syntax.txt.
" Exceptions come last at the end of each group (class and def below).
"
" Keywords 'with' and 'as' are new in Python 2.6
" (use 'from __future__ import with_statement' in Python 2.5).
"
" Some compromises had to be made to support both Python 3.0 and 2.6.
" We include Python 3.0 features, but when a definition is duplicated,
" the last definition takes precedence.
"
" - 'False', 'None', and 'True' are keywords in Python 3.0 but they are
"   built-ins in 2.6 and will be highlighted as built-ins below.
" - 'exec' is a built-in in Python 3.0 and will be highlighted as
"   built-in below.
" - 'nonlocal' is a keyword in Python 3.0 and will be highlighted.
" - 'print' is a built-in in Python 3.0 and will be highlighted as
"   built-in below (use 'from __future__ import print_function' in 2.6)
"
syn keyword coconutStatement	False, None, True
syn keyword coconutStatement	as assert break continue del exec global
syn keyword coconutStatement	lambda nonlocal pass print return with yield
syn keyword coconutStatement	class def nextgroup=coconutFunction skipwhite
syn keyword coconutConditional	elif else if
syn keyword coconutRepeat	for while
syn keyword coconutOperator	and in is not or
syn keyword coconutException	except finally raise try
syn keyword coconutInclude	from import

" Decorators (new in Python 2.4)
syn match   coconutDecorator	"@" display nextgroup=coconutFunction skipwhite

" Pipe operators
syn match   coconutPipe	/\%(|>\||\*>\|<|\|<\*|\)/ display

" Compose
syn match   coconutCompose	"\.\." display

" Chain
syn match   coconutChain	"::" display

" Arrow functions
syn match   coconutArrow	"->" display

" Partial applications
syn match   coconutPartial	"\$" display

" Placeholder
syn match   coconutPlaceholder	/\<_\>/ display

" Code Paththrough
syn match   coconutCodePaththrough	/\\\\\w\+/ display

" The zero-length non-grouping match before the function name is
" extremely important in coconutFunction.  Without it, everything is
" interpreted as a function inside the contained environment of
" doctests.
" A dot must be allowed because of @MyClass.myfunc decorators.
syn match   coconutFunction
      \ "\%(\%(def\s\|class\s\|@\)\s*\)\@<=\h\%(\w\|\.\)*" contained

syn match   coconutEscapableStatement	/\\\@<!\(data\|async\|await\)\>/
syn match   coconutEscapableConditional	/\\\@<!\(match\|case\)\>/

syn match   coconutComment	"#.*$" contains=coconutTodo,@Spell
syn keyword coconutTodo		BUG DEBUG ERROR FIXME NOTE NOTES OPTIMIZE REVIEW REVISIT TODO XXX contained

" Triple-quoted strings can contain doctests.
syn region  coconutString
      \ start=+[uU]\=\z(['"]\)+ end="\z1" skip="\\\\\|\\\z1"
      \ contains=coconutEscape,@Spell
syn region  coconutString
      \ start=+[uU]\=\z('''\|"""\)+ end="\z1" keepend
      \ contains=coconutEscape,coconutSpaceError,coconutDoctest,@Spell
syn region  coconutRawString
      \ start=+[uU]\=[rR]\z(['"]\)+ end="\z1" skip="\\\\\|\\\z1"
      \ contains=@Spell
syn region  coconutRawString
      \ start=+[uU]\=[rR]\z('''\|"""\)+ end="\z1" keepend
      \ contains=coconutSpaceError,coconutDoctest,@Spell

syn match   coconutEscape	+\\[abfnrtv'"\\]+ contained
syn match   coconutEscape	"\\\o\{1,3}" contained
syn match   coconutEscape	"\\x\x\{2}" contained
syn match   coconutEscape	"\%(\\u\x\{4}\|\\U\x\{8}\)" contained
" Coconut allows case-insensitive Unicode IDs: http://www.unicode.org/charts/
syn match   coconutEscape	"\\N{\a\+\%(\s\a\+\)*}" contained
syn match   coconutEscape	"\\$"

if exists("coconut_highlight_all")
  if exists("coconut_no_builtin_highlight")
    unlet coconut_no_builtin_highlight
  endif
  if exists("coconut_no_doctest_code_highlight")
    unlet coconut_no_doctest_code_highlight
  endif
  if exists("coconut_no_doctest_highlight")
    unlet coconut_no_doctest_highlight
  endif
  if exists("coconut_no_exception_highlight")
    unlet coconut_no_exception_highlight
  endif
  if exists("coconut_no_number_highlight")
    unlet coconut_no_number_highlight
  endif
  let coconut_space_error_highlight = 1
  let coconut_reserved_error_highlight = 1
endif

" It is very important to understand all details before changing the
" regular expressions below or their order.
" The word boundaries are *not* the floating-point number boundaries
" because of a possible leading or trailing decimal point.
" The expressions below ensure that all valid number literals are
" highlighted, and invalid number literals are not.  For example,
"
" - a decimal point in '4.' at the end of a line is highlighted,
" - a second dot in 1.0.0 is not highlighted,
" - 08 is not highlighted,
" - 08e0 or 08j are highlighted,
"
" and so on, as specified in the 'Python Language Reference'.
" http://docs.python.org/reference/lexical_analysis.html#numeric-literals
if !exists("coconut_no_number_highlight")
  " numbers (including longs and complex)
  syn match   coconutNumber	"\<0[oO]\=\o\(\o\|_\)*[Ll]\=\>"
  syn match   coconutNumber	"\<0[xX]\x\(\x\|_\)*[Ll]\=\>"
  syn match   coconutNumber	"\<0[bB][01_]\+[Ll]\=\>"
  syn match   coconutNumber	"\<\%([1-9]\(\d\|_\)*\|0\)[Ll]\=\>"
  syn match   coconutNumber	"\<\d\(\d\|_\)*[jJ]\>"
  syn match   coconutNumber	"\<\d\(\d\|_\)*[eE][+-]\=\d\(\d\|_\)*[jJ]\=\>"
  syn match   coconutNumber
	\ "\<\d\(\d\|_\)*\.\%([eE][+-]\=\d\(\d\|_\)*\)\=[jJ]\=\%(\W\|$\)\@="
  syn match   coconutNumber
	\ "\%(^\|\W\)\@<=\(\d\|_\)*\.\(\d\|_\)\+\%([eE][+-]\=\(\d\|_\)\+\)\=[jJ]\=\>"
endif

" Group the built-ins in the order in the 'Python Library Reference' for
" easier comparison.
" http://docs.python.org/library/constants.html
" http://docs.python.org/library/functions.html
" http://docs.python.org/library/functions.html#non-essential-built-in-functions
" Python built-in functions are in alphabetical order.
if !exists("coconut_no_builtin_highlight")
  " built-in constants
  " 'False', 'True', and 'None' are also reserved words in Python 3.0
  syn keyword coconutBuiltin	False True None
  syn keyword coconutBuiltin	NotImplemented Ellipsis __debug__
  " built-in functions
  syn keyword coconutBuiltin	abs addpattern all any bin bool chr classmethod
  syn keyword coconutBuiltin	compile complex concurrent_map consume count
  syn keyword coconutBuiltin	datamaker delattr dict dir divmod dropwhile
  syn keyword coconutBuiltin	enumerate eval filter float fmap format frozenset
  syn keyword coconutBuiltin	getattr globals groupsof hasattr hash help hex
  syn keyword coconutBuiltin	id input int isinstance issubclass iter len list
  syn keyword coconutBuiltin	locals makedata map max min next object oct open
  syn keyword coconutBuiltin	ord parallel_map pow prepattern print property
  syn keyword coconutBuiltin	range recursive recursive_iterator reiterable
  syn keyword coconutBuiltin	repr reversed round scan set setattr slice sorted
  syn keyword coconutBuiltin	starmap staticmethod str sum super takewhile tee
  syn keyword coconutBuiltin	tuple type vars zip __import__
  " Python 2.6 only
  syn keyword coconutBuiltin	basestring callable cmp execfile file
  syn keyword coconutBuiltin	long raw_input reduce reload unichr
  syn keyword coconutBuiltin	unicode xrange
  " Python 3.0 only
  syn keyword coconutBuiltin	ascii bytearray bytes exec memoryview
  " non-essential built-in functions; Python 2.6 only
  syn keyword coconutBuiltin	apply buffer coerce intern
endif

" From the 'Python Library Reference' class hierarchy at the bottom.
" http://docs.python.org/library/exceptions.html
if !exists("coconut_no_exception_highlight")
  " builtin base exceptions (only used as base classes for other exceptions)
  syn keyword coconutExceptions	BaseException Exception
  syn keyword coconutExceptions	ArithmeticError EnvironmentError
  syn keyword coconutExceptions	LookupError
  " builtin base exception removed in Python 3.0
  syn keyword coconutExceptions	StandardError
  " builtin exceptions (actually raised)
  syn keyword coconutExceptions	AssertionError AttributeError BufferError
  syn keyword coconutExceptions	EOFError FloatingPointError GeneratorExit
  syn keyword coconutExceptions	IOError ImportError IndentationError
  syn keyword coconutExceptions	IndexError KeyError KeyboardInterrupt MatchError
  syn keyword coconutExceptions	MemoryError NameError NotImplementedError
  syn keyword coconutExceptions	OSError OverflowError ReferenceError
  syn keyword coconutExceptions	RuntimeError StopIteration SyntaxError
  syn keyword coconutExceptions	SystemError SystemExit TabError TypeError
  syn keyword coconutExceptions	UnboundLocalError UnicodeError
  syn keyword coconutExceptions	UnicodeDecodeError UnicodeEncodeError
  syn keyword coconutExceptions	UnicodeTranslateError ValueError VMSError
  syn keyword coconutExceptions	WindowsError ZeroDivisionError
  " builtin warnings
  syn keyword coconutExceptions	BytesWarning DeprecationWarning FutureWarning
  syn keyword coconutExceptions	ImportWarning PendingDeprecationWarning
  syn keyword coconutExceptions	RuntimeWarning SyntaxWarning UnicodeWarning
  syn keyword coconutExceptions	UserWarning Warning
endif

if exists("coconut_space_error_highlight")
  " trailing whitespace
  syn match   coconutSpaceError	display excludenl "\s\+$"
  " mixed tabs and spaces
  syn match   coconutSpaceError	display " \+\t"
  syn match   coconutSpaceError	display "\t\+ "
endif

if exists("coconut_reserved_error_highlight")
  syn match   coconutReservedError	/\<_coconut\w*\>/ display
endif

" Do not spell doctests inside strings.
" Notice that the end of a string, either ''', or """, will end the contained
" doctest too.  Thus, we do *not* need to have it as an end pattern.
if !exists("coconut_no_doctest_highlight")
  if !exists("coconut_no_doctest_code_highlight")
    syn region coconutDoctest
	  \ start="^\s*>>>\s" end="^\s*$"
	  \ contained contains=ALLBUT,coconutDoctest,@Spell
    syn region coconutDoctestValue
	  \ start=+^\s*\%(>>>\s\|\.\.\.\s\|"""\|'''\)\@!\S\++ end="$"
	  \ contained
  else
    syn region coconutDoctest
	  \ start="^\s*>>>" end="^\s*$"
	  \ contained contains=@NoSpell
  endif
endif

" Sync at the beginning of class, function, or method definition.
syn sync match coconutSync grouphere NONE "^\s*\%(def\|class\)\s\+\h\w*\s*("

if version >= 508 || !exists("did_coconut_syn_inits")
  if version <= 508
    let did_coconut_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  " The default highlight links.  Can be overridden later.
  HiLink coconutStatement	Statement
  HiLink coconutConditional	Conditional
  HiLink coconutRepeat		Repeat
  HiLink coconutOperator		Operator
  HiLink coconutException	Exception
  HiLink coconutInclude		Include
  HiLink coconutDecorator	Define
  HiLink coconutPipe		Operator
  HiLink coconutCompose		Operator
  HiLink coconutChain		Operator
  HiLink coconutArrow		Operator
  HiLink coconutPartial		Operator
  HiLink coconutPlaceholder		SpecialChar
  HiLink coconutCodePaththrough	Macro
  HiLink coconutFunction		Function
  HiLink coconutEscapableStatement		Statement
  HiLink coconutEscapableConditional		Conditional
  HiLink coconutComment		Comment
  HiLink coconutTodo		Todo
  HiLink coconutString		String
  HiLink coconutRawString	String
  HiLink coconutEscape		Special
  if !exists("coconut_no_number_highlight")
    HiLink coconutNumber		Number
  endif
  if !exists("coconut_no_builtin_highlight")
    HiLink coconutBuiltin	Function
  endif
  if !exists("coconut_no_exception_highlight")
    HiLink coconutExceptions	Structure
  endif
  if exists("coconut_space_error_highlight")
    HiLink coconutSpaceError	Error
  endif
  if exists("coconut_reserved_error_highlight")
    HiLink coconutReservedError		Error
endif
  if !exists("coconut_no_doctest_highlight")
    HiLink coconutDoctest	Special
    HiLink coconutDoctestValue	Define
  endif

  delcommand HiLink
endif

let b:current_syntax = "coconut"

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:set sw=2 sts=2 ts=8 noet:
