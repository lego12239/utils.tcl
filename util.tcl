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
proc lmax {l} {
	set ret [lindex $l 0]
	foreach i $l {
		if {[string compare $i $ret] == 1} {
			set ret $i
		}
	}

	return $ret
}

# Get a list item with a minimum value.
proc lmin {l} {
	set ret [lindex $l 0]
	foreach i $l {
		if {[string compare $i $ret] == -1} {
			set ret $i
		}
	}

	return $ret
}
