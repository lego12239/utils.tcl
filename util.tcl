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
