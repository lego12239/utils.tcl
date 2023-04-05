# Split string treating sequence of whitespaces as one whitespace.
# E.g.(from tclsh):
# % set a " 1   2     3"
# % split $a
# {} 1 {} {} 2 {} {} {} {} 3
# % _split $a
# 1 2 3
proc _split {str} {
	apply {args { return $args; }} {*}$str;
}

# Get a tcl object type.
# ret:
#  dict - for dict
#  list - for list
#  string - for string
#  pure - for pure string
#  int - for integer
#  double - for double
#proc _get_otype {obj} {
#	return [lindex [split [tcl::unsupported::representation $obj]] 3]
#}
proc _get_otype {obj} {
	set s [tcl::unsupported::representation $obj]
	return [string range $s 11 [string first " " $s 11]-1]
}

# Insert specified text at pos pos in str.
# If pos <= 0, then prepend text to str.
# If pos >= LEN(str), then append text to str.
# M+N as pos isn't supported(only single integer).
proc _str_insert {str pos text} {
	if {$pos <= 0} {
		return "${text}$str"
	} elseif {$pos >= [string length $str]} {
		return "${str}$text"
	}
	return [string replace $str $pos $pos "$text[string index $str $pos]"]
}

# Get a list item with a maximum value.
# To do a number comparing instead of string comparing(by default) set cmd to:
# {apply {{a b} {if {$a == $b} { return 0; }; return [expr {$a>$b ? 1 : -1}]; }}}
# Or to some number_cmp, which can be defined as:
# proc number_cmp {a b} {
# 	if {$a == $b} {
# 	  return 0
# 	}
# 	return [expr {$a>$b ? 1 : -1}]
# }
proc lmax {l {cmd "string compare"}} {
	set ret [lindex $l 0]
	foreach i $l {
		if {[{*}$cmd $i $ret] == 1} {
			set ret $i
		}
	}

	return $ret
}

# Get a list item with a minimum value.
# To do a number comparing instead of string comparing(by default) set cmd to:
# {apply {{a b} {if {$a == $b} { return 0; }; return [expr {$a>$b ? 1 : -1}]; }}}
# Or to some number_cmp, which can be defined as:
# proc number_cmp {a b} {
# 	if {$a == $b} {
# 	  return 0
# 	}
# 	return [expr {$a>$b ? 1 : -1}]
# }
proc lmin {l {cmd "string compare"}} {
	set ret [lindex $l 0]
	foreach i $l {
		if {[{*}$cmd $i $ret] == -1} {
			set ret $i
		}
	}

	return $ret
}

# Parse options from argslist.
# Stop on first non-option argument or after --.
# prms:
#  argslist - arguments to parse
#  spec     - opts spec. A dict where:
#             key - opt name (started with "-")
#             value - 0 for opt without argument
#                     1 for opt with argument
# ret:
#  list - 1 item is opts dict with opts from argslist, 2 item is index for first
#         non-option argument
#
# E.g.:
#  _opts_parse "-dval -t 7 -- fname q" {-dval 0 -D 1 -t 1}
#
proc _opts_parse {argslist spec} {
	set opts [dict create]

	for {set i 0} {$i < [llength $argslist]} {incr i} {
		set lex [lindex $argslist $i]
		if {![string equal -length 1 $lex "-"]} {
			break
		}
		if {$lex eq "--"} {
			incr i
			break
		}
		if {![dict exists $spec $lex]} {
			error "wrong option: $lex"
		}
		set val [dict get $spec $lex]
		if {[lindex $val 0]} {
			incr i
			dict set opts $lex [lindex $argslist $i]
		} else {
			dict incr opts $lex
		}
	}

	return [list $opts $i]
}

# Parse a network address in plan9 format.
# prms:
#  naddr  - a network address in plan9 format
# ret:
#  {net NET addr ADDR srv SRV} - parsed network address.
#
# Address syntax:
#  NET!ADDR!SRV  or
#  NET!ADDR!0    or
#  NET!ADDR      or
#  ADDR
# Where NET is a network protocol(like 'tcp' or 'udp') or 'net' for any net,
# ADDR is a host name or a host address(can be '*' for any address),
# SRV is a protocol specific service.
# Example: tcp!127.0.0.1!8888
proc _naddr_parse {naddr} {
	set addr [dict create net "" addr "" srv ""]
	set naddr_ [split $naddr "!"]
	switch [llength $naddr_] {
	3 {
		dict set addr net [string tolower [lindex $naddr_ 0]]
		dict set addr addr [string tolower [lindex $naddr_ 1]]
		dict set addr srv [string tolower [lindex $naddr_ 2]]
	}
	2 {
		dict set addr net [string tolower [lindex $naddr_ 0]]
		dict set addr addr [string tolower [lindex $naddr_ 1]]
	}
	1 {
		dict set addr addr [string tolower [lindex $naddr_ 0]]
	}
	default {
		error "Wrong network address syntax: '$naddr'"
	}
	}


	return $addr
}

# Example naddr_parse for using a parsed addr with socket command.
# prms:
#  naddr   - a network address in plan9 format
#  defaddr - a default addr if '*' is specified (0.0.0.0 by default)
# ret:
#  {net NET addr ADDR srv SRV} - parsed network address.
proc naddr_parse {naddr {defaddr 0.0.0.0}} {
	set addr [_naddr_parse $naddr]
	if {[dict get $addr net] ne "tcp"} {
		error "Unsupported net in network address: [dict get $addr net]"
	}
	if {[dict get $addr net] eq "net"} {
		dict set addr net tcp
	}
	if {[dict get $addr addr] eq "*"} {
		dict set addr addr $defaddr
	}
	if {[dict get $addr srv] eq ""} {
		dict set addr srv 0
	}

	return $addr
}

# Escape special characters according to HTML escape rules.
# prms:
#  str - a string to process
# ret:
#  STR - a string with special characters escaped
# &, <, > - for any places
# ", ' - for element attributes
proc html_escape {str} {
	set str [string map {& &amp; < &lt; > &gt; \" &quot; \' &#39;} $str]

	return $str
}

# Unescape HTML escape sequences.
# prms:
#  str - a string to process
# ret:
#  STR - a string with unescaped escape sequences
# "&#xX;", "&#N;" and "&W;" is converted to a character with hex code X or
# decimal code N or name W.
proc html_unescape {str} {
	set i0 0
	set res ""
	set _html_unescape_escseq [dict create\
	  quot {"} amp & lt > gt < Tab "\t" NewLine "\n" nbsp "\uA0"\
	  iexcl "\uA1" cent "\uA2" pound "\uA3" curren "\uA4" yen "\uA5"\
	  brvbar "\uA6" sect "\uA7" uml "\uA8" copy "\uA9" ordf "\uAA"\
	  laquo "\uAB" not "\uAC" shy "\uAD" reg "\uAE" macr "\uAF"\
	  deg "\uB0" plusmn "\uB1" sup2 "\uB2" sup3 "\uB3" acute "\uB4"\
	  micro "\uB5" para "\uB6" dot "\uB7" cedil "\uB8" sup1 "\uB9"\
	  ordm "\uBA" raquo "\uBB" frac14 "\uBC" frac12 "\uBD" frac34 "\uBE"\
	  iquest "\uBF" Agrave "\uC0" Aacute "\uC1" Acirc "\uC2"\
	  Atilde "\uC3" Auml "\uC4" Aring "\uC5" AElig "\uC6" Ccedil "\uC7"\
	  Egrave "\uC8" Eacute "\uC9" Ecirc "\uCA" Euml "\uCB" Igrave "\uCC"\
	  Iacute "\uCD" Icirc "\uCE" Iuml "\uCF" ETH "\uD0" Ntilde "\uD1"\
	  Ograve "\uD2" Oacute "\uD3" Ocirc "\uD4" Otilde "\uD5" Ouml "\uD6"\
	  times "\uD7" Oslash "\uD8" Ugrave "\uD9" Uacute "\uDA"\
	  Ucirc "\uDB" Uuml "\uDC" Yacute "\uDD" THORN "\uDE" szlig "\uDF"\
	  agrave "\uE0" aacute "\uE1" acirc "\uE2" atilde "\uE3" auml "\uE4"\
	  aring "\uE5" aelig "\uE6" ccedil "\uE7" egrave "\uE8"\
	  eacute "\uE9" ecirc "\uEA" euml "\uEB" igrave "\uEC" iacute "\uED"\
	  icirc "\uEE" iuml "\uEF" eth "\uF0" ntilde "\uF1" ograve "\uF2"\
	  oacute "\uF3" ocirc "\uF4" otilde "\uF5" ouml "\uF6" divide "\uF7"\
	  oslash "\uF8" ugrave "\uF9" uacute "\uFA" ucirc "\uFB" uuml "\uFC"\
	  yacute "\uFD" thorn "\uFE" yuml "\uFF" Amacr "\u0100"\
	  amacr "\u0101" Abreve "\u0102" abreve "\u0103" Aogon "\u0104"\
	  aogon "\u0105" Cacute "\u0106" cacute "\u0107" Ccirc "\u0108"\
	  ccirc "\u0109" Cdot "\u010A" cdot "\u010B" Ccaron "\u010C"\
	  ccaron "\u010D" Dcaron "\u010E" dcaron "\u010F" Dstrok "\u0110"\
	  dstrok "\u0111" Emacr "\u0112" emacr "\u0113" Ebreve "\u0114"\
	  ebreve "\u0115" Edot "\u0116" edot "\u0117" Eogon "\u0118"\
	  eogon "\u0119" Ecaron "\u011A" ecaron "\u011B" Gcirc "\u011C"\
	  gcirc "\u011D" Gbreve "\u011E" gbreve "\u011F" Gdot "\u0120"\
	  gdot "\u0121" Gcedil "\u0122" gcedil "\u0123" Hcirc "\u0124"\
	  hcirc "\u0125" Hstrok "\u0126" hstrok "\u0127" Itilde "\u0128"\
	  itilde "\u0129" Imacr "\u012A" imacr "\u012B" Ibreve "\u012C"\
	  ibreve "\u012D" Iogon "\u012E" iogon "\u012F" Idot "\u0130"\
	  imath "\u0131" inodot "\u0131" IJlig "\u0132" ijlig "\u0133"\
	  Jcirc "\u0134" jcirc "\u0135" Kcedil "\u0136" kcedil "\u0137"\
	  kgreen "\u0138" Lacute "\u0139" lacute "\u013A" Lcedil "\u013B"\
	  lcedil "\u013C" Lcaron "\u013D" lcaron "\u013E" Lmidot "\u013F"\
	  lmidot "\u0140" Lstrok "\u0141" lstrok "\u0142" Nacute "\u0143"\
	  nacute "\u0144" Ncedil "\u0145" ncedil "\u0146" Ncaron "\u0147"\
	  ncaron "\u0148" napos "\u0149" ENG "\u014A" eng "\u014B"\
	  Omacr "\u014C" omacr "\u014D" Obreve "\u014E" obreve "\u014F"\
	  Odblac "\u0150" odblac "\u0151" OElig "\u0152" oelig "\u0153"\
	  Racute "\u0154" racute "\u0155" Rcedil "\u0156" rcedil "\u0157"\
	  Rcaron "\u0158" rcaron "\u0159" Sacute "\u015A" sacute "\u015B"\
	  Scirc "\u015C" scirc "\u015D" Scedil "\u015E" scedil "\u015F"\
	  Scaron "\u0160" scaron "\u0161" Tcedil "\u0162" tcedil "\u0163"\
	  Tcaron "\u0164" tcaron "\u0165" Tstrok "\u0166" tstrok "\u0167"\
	  Utilde "\u0168" utilde "\u0169" Umacr "\u016A" umacr "\u016B"\
	  Ubreve "\u016C" ubreve "\u016D" Uring "\u016E" uring "\u016F"\
	  Udblac "\u0170" udblac "\u0171" Uogon "\u0172" uogon "\u0173"\
	  Wcirc "\u0174" wcirc "\u0175" Ycirc "\u0176" ycirc "\u0177"\
	  Yuml "\u0178" fnof "\u0192" circ "\u02C6" tilde "\u02DC"\
	  Alpha "\u0391" Beta "\u0392" Gamma "\u0393" Delta "\u0394"\
	  Epsilon "\u0395" Zeta "\u0396" Eta "\u0397" Theta "\u0398"\
	  Iota "\u0399" Kappa "\u039A" Lambda "\u039B" Mu "\u039C"\
	  Nu "\u039D" Xi "\u039E" Omicron "\u039F" Pi "\u03A0" Rho "\u03A1"\
	  Sigma "\u03A3" Tau "\u03A4" Upsilon "\u03A5" Phi "\u03A6"\
	  Chi "\u03A7" Psi "\u03A8" Omega "\u03A9" alpha "\u03B1"\
	  beta "\u03B2" gamma "\u03B3" delta "\u03B4" epsilon "\u03B5"\
	  zeta "\u03B6" eta "\u03B7" theta "\u03B8" iota "\u03B9"\
	  kappa "\u03BA" lambda "\u03BB" mu "\u03BC" nu "\u03BD" xi "\u03BE"\
	  omicron "\u03BF" pi "\u03C0" rho "\u03C1" sigmaf "\u03C2"\
	  sigma "\u03C3" tau "\u03C4" upsilon "\u03C5" phi "\u03C6"\
	  chi "\u03C7" psi "\u03C8" omega "\u03C9" thetasym "\u03D1"\
	  upsih "\u03D2" piv "\u03D6" ensp "\u2002" emsp "\u2003"\
	  thinsp "\u2009" zwnj "\u200C" zwj "\u200D" lrm "\u200E"\
	  rlm "\u200F" ndash "\u2013" mdash "\u2014" lsquo "\u2018"\
	  rsquo "\u2019" sbquo "\u201A" ldquo "\u201C" rdquo "\u201D"\
	  bdquo "\u201E" dagger "\u2020" Dagger "\u2021" bull "\u2022"\
	  hellip "\u2026" permil "\u2030" prime "\u2032" Prime "\u2033"\
	  lsaquo "\u2039" rsaquo "\u203A" oline "\u203E" euro "\u20AC"\
	  trade "\u2122" larr "\u2190" uarr "\u2191" rarr "\u2192"\
	  darr "\u2193" harr "\u2194" crarr "\u21B5" forall "\u2200"\
	  part "\u2202" exist "\u2203" empty "\u2205" nabla "\u2207"\
	  isin "\u2208" notin "\u2209" ni "\u220B" prod "\u220F"\
	  sum "\u2211" minus "\u2212" lowast "\u2217" radic "\u221A"\
	  prop "\u221D" infin "\u221E" ang "\u2220" and "\u2227"\
	  or "\u2228" cap "\u2229" cup "\u222A" int "\u222B" there4 "\u2234"\
	  sim "\u223C" cong "\u2245" asymp "\u2248" ne "\u2260"\
	  equiv "\u2261" le "\u2264" ge "\u2265" sub "\u2282" sup "\u2283"\
	  nsub "\u2284" sube "\u2286" supe "\u2287" oplus "\u2295"\
	  otimes "\u2297" perp "\u22A5" sdot "\u22C5" lceil "\u2308"\
	  rceil "\u2309" lfloor "\u230A" rfloor "\u230B" loz "\u25CA"\
	  spades "\u2660" clubs "\u2663" hearts "\u2665" diams "\u2666"]

	while {[set i1 [string first "&" $str $i0]] != -1} {
		append res [string range $str $i0 $i1-1]
		set esc [string range $str $i1 [string first ";" $str $i1]]
		if {[string equal -length 3 $esc "&#x"]} {
			append res [format %c [scan [string range $esc 3 end-1] %x]]
		} elseif {[string equal -length 2 $esc "&#"]} {
			append res [format %c [scan [string range $esc 2 end-1] %u]]
		} else {
			append res [dict get $_html_unescape_escseq\
			  [string range $esc 1 end-1]]
		}
		set i0 [expr {$i1 + [string length $esc]}]
	}
	if {$i0 < [string length $str]} {
		append res "[string range $str $i0 end]"
	}

	return $res
}

# Create an anyPointer from a specified args.
# anyPointer is inspired by JSON Pointer(rfc6901).
# But it escapes also \n and \r chars to allow anyPointer
# to remain on a single line.
# prms:
#  parts  - a list with elements
# ret:
#  STRING - formatted pointer
proc anyptr_fmt {parts} {
	set res ""

	foreach s $parts {
		regsub {%} $s "%0" s
		regsub {/} $s "%1" s
		regsub {\n} $s "%2" s
		regsub {\r} $s "%3" s
		append res "$s/"
	}

	return [string range $res 0 end-1]
}

# Parse an anyPointer into a list.
# prms:
#  str  - formatted pointer
# ret:
#  LIST - a list with elements
proc anyptr_parse {str} {
	set res [list]

	foreach s [split $str "/"] {
		regsub {%3} $s "\r" s
		regsub {%2} $s "\n" s
		regsub {%1} $s "/" s
		regsub {%0} $s "%" s
		lappend res $s
	}

	return $res
}

