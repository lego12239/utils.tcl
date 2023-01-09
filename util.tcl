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
