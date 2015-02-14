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
		if !InStr(next, ch)
			throw Exception("Unexpected char.", -1, ch)

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
			next := is_arr[stack[1]] ? "]," : "},"
		}

		else if InStr(",:", ch)
		{
			if (obj == tree)
				throw Exception("Unexpected char -> there is no container object.", -1, ch)
			
			is_key := (!is_array && ch == ",")
			next := q . "{[0123456789-tfn"
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
				if !i
					throw Exception("Missing close quote(s).", -1)

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
					if (SubStr(val, i+1, 1) != "u")
						throw Exception("Invalid escape sequence.", -1, SubStr(val, i, 2))

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

			else ; number | true,false,null
			{
				val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
				
				static null := ""
				if InStr(",true,false,null,", "," . val . ",", true) ; if var in
					val := %val%
				else if (Abs(val) == "")
					throw Exception("Invalid JSON value.", -1, val)
				
				val := val + 0, pos += i-1
			}
			
			is_array? %ObjPush%(obj, val) : obj[key] := val
			next := is_array ? "]," : "},"
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
				throw Exception("Invalid JSON key", -1)
			
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

Jxon_Read(src, prototype*)
{
	if f := FileOpen(src, "r", "UTF-8")
	{
		jstr := f.Read(), f.Close()
		return Jxon_Load(jstr, prototype*)
	}
}

Jxon_Write(obj, dest, indent:="")
{
	if f := FileOpen(dest, "w", "UTF-8")
	{
		bytes := f.Write(Jxon_Dump(obj, indent)), f.Close()
		return bytes
	}
}