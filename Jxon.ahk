Jxon_Load(ByRef src, args*)
{
	static q := Chr(34)

	key := "", is_key := false
	stack := [ tree := [] ]
	is_arr := { (tree): 1 }
	next := q . "{[01234567890-tfn"
	pos := 0
	while ( (ch := SubStr(src, ++pos, 1)) != "" )
	{
		static is_v2       := A_AhkVersion >= "2"
		static ObjPush     := Func(is_v2 ? "ObjPush"     : "ObjInsert")
		static ObjInsertAt := Func(is_v2 ? "ObjInsertAt" : "ObjInsert")
		static ObjRemoveAt := Func(is_v2 ? "ObjRemoveAt" : "ObjRemove")

		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch, true)
		{
			ln := StrSplit(SubStr(src, 1, pos), "`n")[is_v2 ? "Length" : "MaxIndex"]()
			col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

			msg := Format("{}: line {} col {} (char {})"
			,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
			  : (next == "'")     ? "Unterminated string starting at"
			  : (next == "\")     ? "Invalid \escape"
			  : (next == ":")     ? "Expecting ':' delimiter"
			  : (next == q)       ? "Expecting object key enclosed in double quotes"
			  : (next == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
			  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			  : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
			    , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
			, ln, col, pos)

			throw Exception(msg, -1, ch)
		}

		is_array := is_arr[obj := stack[1]]

		if i := InStr("{[", ch)
		{
			val := (proto := args[i]) ? new proto : {}
			is_array? %ObjPush%(obj, val) : obj[key] := val
			%ObjInsertAt%(stack, 1, val)
			
			is_arr[val] := !(is_key := ch == "{")
			next := q . (is_key ? "}" : "{[]0123456789-tfn")
		}

		else if InStr("}]", ch)
		{
			%ObjRemoveAt%(stack, 1)
			next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
		}

		else if InStr(",:", ch)
		{
			is_key := (!is_array && ch == ",")
			next := is_key ? q : q . "{[0123456789-tfn"
		}

		else ; string | number | true | false | null
		{
			if (ch == q) ; string
			{
				static Replace := Func(is_v2 ? "StrReplace" : "RegExReplace")
				static bash := is_v2 ? "\" : "\\"

				i := pos
				while i := InStr(src, q,, i+1)
				{
					val := %Replace%(SubStr(src, pos+1, i-pos-1), bash . bash, "\u005C")
					static end := is_v2 ? -1 : 0
					if (SubStr(val, end) != "\")
						break
				}
				if !i ? (pos--, next := "'") : 0
					continue

				pos := i ; update pos

				  val := %Replace%(val, bash . "/",  "/")
				, val := %Replace%(val, bash .   q,    q)
				, val := %Replace%(val, bash . "b", "`b")
				, val := %Replace%(val, bash . "f", "`f")
				, val := %Replace%(val, bash . "n", "`n")
				, val := %Replace%(val, bash . "r", "`r")
				, val := %Replace%(val, bash . "t", "`t")

				i := 0
				while i := InStr(val, "\",, i+1)
				{
					if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
						continue 2

					; \uXXXX - JSON unicode escape sequence
					xxxx := Abs("0x" . SubStr(val, i+2, 4))
					if (A_IsUnicode || xxxx < 0x100)
						val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
				}

				if is_key
				{
					key := val, next := ":"
					continue
				}
			}

			else ; number | true | false | null
			{
				val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
				
				static null := "", Ord := Func(is_v2 ? "Ord" : "Asc")
				if InStr(",true,false,null,", "," . val . ",", true) ; if var in
					val := %val%
				else if (Abs(val) == "") ? (pos--, next := Chr(%Ord%(ch)+1)) : 0
					continue
				
				val := val + 0, pos += i-1
			}
			
			is_array? %ObjPush%(obj, val) : obj[key] := val
			next := obj==tree ? "" : is_array ? ",]" : ",}"
		}
	}

	return tree[1]
}

Jxon_Dump(obj, indent:="", lvl:=1)
{
	static q := Chr(34)

	if IsObject(obj)
	{
		if (ObjGetCapacity(obj) == "")
			throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))

		is_array := 0
		for k in obj
			is_array := k == A_Index
		until !is_array

		static integer := "integer"
		if indent is %integer%
		{
			if (indent < 0)
				throw Exception("Indent parameter must be a postive integer.", -1, indent)
			spaces := indent, indent := ""
			Loop % spaces
				indent .= " "
		}
		indt := ""
		Loop, % indent ? lvl : 0
			indt .= indent

		lvl += 1, out := "" ; Make #Warn happy
		for k, v in obj
		{
			if IsObject(k) || (k == "")
				throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
			
			if !is_array
				out .= ( ObjGetCapacity([k], 1) ? Jxon_Dump(k) : q . k . q ) ;// key
				    .  ( indent ? ": " : ":" ) ; token + padding
			out .= Jxon_Dump(v, indent, lvl) ; value
			    .  ( indent ? ",`n" . indt : "," ) ; token + indent
		}

		if (out != "")
		{
			out := Trim(out, ",`n" . indent)
			if (indent != "")
				out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
		}
		
		return is_array ? "[" . out . "]" : "{" . out . "}"
	}

	; Number
	else if (ObjGetCapacity([obj], 1) == "")
		return obj

	; String (null -> not supported by AHK)
	if (obj != "")
	{
		static Replace := Func(A_AhkVersion<"2" ? "RegExReplace" : "StrReplace")
		static bash := A_AhkVersion<"2" ? "\\" : "\"
		  obj := %Replace%(obj,  bash,    "\\")
		, obj := %Replace%(obj,   "/",    "\/")
		, obj := %Replace%(obj,     q, "\" . q)
		, obj := %Replace%(obj,  "`b",    "\b")
		, obj := %Replace%(obj,  "`f",    "\f")
		, obj := %Replace%(obj,  "`n",    "\n")
		, obj := %Replace%(obj,  "`r",    "\r")
		, obj := %Replace%(obj,  "`t",    "\t")

		static Ord := Func(A_AhkVersion<"2" ? "Asc" : "Ord")
		while RegExMatch(obj, "[^\x20-\x7e]", m)
			obj := %Replace%(obj, ch := IsObject(m) ? m[0] : m, Format("\u{:04X}", %Ord%(ch)))
	}
	
	return q . obj . q
}