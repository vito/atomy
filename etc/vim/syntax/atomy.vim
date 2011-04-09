" Remove any old syntax stuff hanging around
if version < 600
  syn clear
elseif exists("b:current_syntax")
  finish
endif

" Delimiters
syn match   atomyDelimiter          "(\|,\|\[\|\]"
syn match   atomyBlock              ":\|;\|{\|}"

" Identifiers & Operators
syn match   atomyIdentifier         "[a-z_][a-zA-Z0-9~!@#$%^&*\-=+./\\|<>\?]*"
syn match   atomyOperator           ":\?[<>~!@#\$%\^&\*\-=\+./\?\\|]\+"

" Special Constants
syn match   atomyNil                "\<\(nil\)\>"
syn match   atomyBoolean            "\<\(true\|false\)\>"
syn match   atomyConditional        "\<\(if\|then\|else\)\>"
syn match   atomySpecial            "\<\(self\|macro\|for-macro\|operator\)\>"

" Method Definition
syn match   atomyMethod             "[a-z_][a-zA-Z0-9~!@#$%^&*\-=+./\\|<>\?]*" contained
syn match   atomyOpMethod           ":\?[<>~!@#\$%\^&\*\-=\+./\?\\|]\+" contained
syn match   atomyDefinition         "[a-z_][a-zA-Z0-9~!@#$%^&*\-=+./\\|<>\?]*[[:space:]]*:="me=e-2 contains=atomyMethod,atomyGrouped,atomyOperator
syn match   atomyDefinition         "[a-z_][a-zA-Z0-9~!@#$%^&*\-=+./\\|<>\?]*(.*:="me=e-2 contains=atomyMethod,atomyGrouped,atomyOperator
syn match   atomyDefinition         "[[:space:]]\+:\?[<>~!@#\$%\^&\*\-=\+./\?\\|]\+[[:space:]]\+.*:="me=e-2 contains=atomyOpMethod,atomyGrouped,atomyOperator

" Grouped
syn region  atomyGrouped            start="(" end=")" contains=TOP,atomyDefinition

" Strings
syn match   atomySpecialChar        contained "\\\([0-9]\+\|o[0-7]\+\|x[0-9a-fA-F]\+\|[\"\\'&\\abfnrtv]\|^[A-Z^_\[\\\]]\)"
syn match   atomySpecialChar        contained "\\\(NUL\|SOH\|STX\|ETX\|EOT\|ENQ\|ACK\|BEL\|BS\|HT\|LF\|VT\|FF\|CR\|SO\|SI\|DLE\|DC1\|DC2\|DC3\|DC4\|NAK\|SYN\|ETB\|CAN\|EM\|SUB\|ESC\|FS\|GS\|RS\|US\|SP\|DEL\)"
syn match   atomySpecialCharError   contained "\\&\|'''\+"
syn region  atomyString             start=+"+  skip=+\\\\\|\\"+  end=+"+  contains=atomySpecialChar

" Numbers
syn match   atomyNumber             "\<[-+]\?[0-9]\+\>\|\<[-+]\?0[xX][0-9a-fA-F]\+\>\|\<[-+]\?0[oO][0-7]\+\>"
syn match   atomyFloat              "\<[-+]\?[0-9]\+\.[0-9]\+\([eE][-+]\=[0-9]\+\)\=\>"

" Symbols &c.
syn match   atomyUnquote            "\~\([a-z_][a-zA-Z:~!@#$%^&*\-_=+./\\|<>\?]*\)\?"
syn region  atomyUnquote            matchgroup=Special start="\~(" end=")" contains=TOP
syn match   atomySplice             "\~\*\([a-z_][a-zA-Z:~!@#$%^&*\-_=+./\\|<>\?]*\)\?"
syn region  atomySplice             matchgroup=Special start="\~\*(" end=")" contains=TOP
syn match   atomyQuasiQuote         "`"
syn region  atomyQuasiQuote         matchgroup=Special start="`(" end=")" contains=TOP
syn match   atomyQuote              "'"
syn region  atomyQuote              matchgroup=Special start="'(" end=")" contains=TOP
syn match   atomyParticle           "#\([a-z_][a-zA-Z:~!@#$%^&*\-_=+./\\|<>\?]*\)\?"

" Identifiers, Constants & Variables
syn match   atomyConstant           "[A-Z][a-zA-Z0-9_]*"
syn match   atomyClassVariable      "@@[a-z_][a-zA-Z0-9~!@#$%^&*\-=+./\\|<>\?]\+"
syn match   atomyInstanceVariable   "@[a-z_][a-zA-Z0-9~!@#$%^&*\-=+./\\|<>\?]*"
syn match   atomyGlobalVariable     "$[a-z_][a-zA-Z0-9~!@#$%^&*\-=+./\\|<>\?]*"

" Comments
syn match   atomyLineComment        "--.*$"
syn region  atomyBlockComment       start="{-"  end="-}" contains=atomyBlockComment

" Regexp fun, ported from the Ruby syntax
syn region  atomyRegexpComment       matchgroup=atomyRegexpSpecial  start="(?#"  skip="\\)"  end=")"  contained
syn region  atomyRegexpParens        matchgroup=atomyRegexpSpecial  start="(\(?:\|?<\=[=!]\|?>\|?<[a-z_]\w*>\|?[imx]*-[imx]*:\=\|\%(?#\)\@!\)" skip="\\)"  end=")"  contained transparent contains=@atomyRegexpSpecial
syn region  atomyRegexpBrackets      matchgroup=atomyRegexpCharClass start="\[\^\="  skip="\\\]" end="\]" contained transparent contains=atomyStringEscape,atomyRegexpEscape,atomyRegexpCharClass oneline
syn match   atomyRegexpCharClass     "\[:\^\=\%(alnum\|alpha\|ascii\|blank\|cntrl\|digit\|graph\|lower\|print\|punct\|space\|upper\|xdigit\):\]" contained
syn match   atomyRegexpCharClass     "\\[DdHhSsWw]"                                contained display
syn match   atomyRegexpEscape        "\\[].*?+^$|\\/(){}[]"                        contained
syn match   atomyRegexpQuantifier    "[*?+][?+]\="                                 contained display
syn match   atomyRegexpQuantifier    "{\d\+\%(,\d*\)\=}?\="                        contained display
syn match   atomyRegexpAnchor        "[$^]\|\\[ABbGZz]"                            contained display
syn match   atomyRegexpDot           "\."                                          contained display
syn match   atomyRegexpSpecial       "|"                                           contained display
syn match   atomyRegexpSpecial       "\\[1-9]\d\=\d\@!"                            contained display
syn match   atomyRegexpSpecial       "\\k<\%([a-z_]\w*\|-\=\d\+\)\%([+-]\d\+\)\=>" contained display
syn match   atomyRegexpSpecial       "\\k'\%([a-z_]\w*\|-\=\d\+\)\%([+-]\d\+\)\='" contained display
syn match   atomyRegexpSpecial       "\\g<\%([a-z_]\w*\|-\=\d\+\)>"                contained display
syn match   atomyRegexpSpecial       "\\g'\%([a-z_]\w*\|-\=\d\+\)'"                contained display

syn cluster atomyRegexpSpecial      contains=atomyInterpolation,atomyNoInterpolation,atomyStringEscape,atomyRegexpSpecial,atomyRegexpEscape,atomyRegexpBrackets,atomyRegexpCharClass,atomyRegexpDot,atomyRegexpQuantifier,atomyRegexpAnchor,atomyRegexpParens,atomyRegexpComment

syn region  atomyRegexp             start=+r{+  skip=+\\\\\|\\}+  end=+}+  contains=@atomyRegexpSpecial keepend
syn region  atomyRegexp             start=+r"+  skip=+\\\\\|\\"+  end=+"+  contains=@atomyRegexpSpecial keepend


" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_atomy_syntax_inits")
  if version < 508
    let did_atomy_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink atomyBlockComment        atomyComment
  HiLink atomyLineComment         atomyComment
  HiLink atomyComment             Comment
  HiLink atomySpecial             PreProc
  HiLink atomyConditional         Conditional
  HiLink atomySpecialChar         SpecialChar
  HiLink atomyOperator            Operator
  HiLink atomySpecialCharError    Error
  HiLink atomyString              String
  HiLink atomyNumber              Number
  HiLink atomyFloat               Float
  HiLink atomyConditional         Conditional
  HiLink atomyNil                 Constant
  HiLink atomyBoolean             Boolean

  HiLink atomyRegexpEscape        atomyRegexpSpecial
  HiLink atomyRegexpQuantifier    atomyRegexpSpecial
  HiLink atomyRegexpAnchor        atomyRegexpSpecial
  HiLink atomyRegexpDot           atomyRegexpCharClass
  HiLink atomyRegexpCharClass     atomyRegexpSpecial
  HiLink atomyRegexpSpecial       Special
  HiLink atomyRegexpComment       Comment
  HiLink atomyRegexp              atomyString

  HiLink atomyConstant            Type
  HiLink atomyGlobalVariable      Identifier
  HiLink atomyClassVariable       Identifier
  HiLink atomyInstanceVariable    Identifier

  HiLink atomyQuasiQuote          PreProc
  HiLink atomyQuote               Special
  HiLink atomyUnquote             Special
  HiLink atomySplice              Special

  HiLink atomyMethod              Function
  HiLink atomyOpMethod            Function

  delcommand HiLink
endif

let b:current_syntax = "atomy"
