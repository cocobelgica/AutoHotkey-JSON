class JSON
{
	parse(src, jsonize:=false)
	{
		;// Pre-validate JSON source before parsing
		if ((src:=Trim(src, " `t`n`r")) == "") ;// trim whitespace(s)
			throw Exception("Empty JSON source")
		first := SubStr(src, 1, 1), last := SubStr(src, -1)
		if !InStr('{["tfn0123456789-', first) ;// valid beginning chars
		|| !InStr('}]el0123456789"', last) ;// valid ending chars
		|| (first == '{' && last != '}') ;// if starts w/ '{' must end w/ '}'
		|| (first == '[' && last != ']') ;// if starts w/ '[' must end w/ ']'
		|| (first == '"' && last != '"') ;// if starts w/ '"' must end w/ '"'
		|| (first == 'n' && last != 'l') ;// assume 'null'
		|| (InStr('tf', first) && last != 'e') ;// assume 'true' OR 'false'
		|| (InStr('-0123456789', first) && !(last is 'number')) ;// number
			throw Exception("Invalid JSON format")
		
		static esc_seq := {
		(Q
			'"': '"',
			'/': '/',
			'b': '`b',
			'f': '`f',
			'n': '`n',
			'r': '`r',
			't': '`t'
		)}
		;// Extract string literals
		i := 0, strings := []
		while (i:=InStr(src, '"',, i+1))
		{
			j := i
			while (j:=InStr(src, '"',, j+1))
			{
				str := SubStr(src, i+1, j-i-1)
				str := StrReplace(str, "\\", "\u005C")
				if (SubStr(str, -1) != "\")
					break
			}
			
			if !j, throw Exception("Missing close quote(s)")
			src := SubStr(src, 1, i) . SubStr(src, j+1)
			
			k := 0
			while (k := InStr(str, "\",, k+1))
			{
				ch := SubStr(str, k+1, 1)
				if InStr('"btnfr/', ch)
					str := SubStr(str, 1, k-1) . esc_seq[ch] . SubStr(str, k+2)
				
				else if (ch = "u")
				{
					hex := "0x" . SubStr(str, k+2, 4)
					if !(A_IsUnicode || (Abs(hex) < 0x100))
						continue
					str := SubStr(str, 1, k-1) . Chr(hex) . SubStr(str, k+6)
				
				}
				else
					throw Exception("Invalid escape sequence: '\%ch%'")
			}
			ObjPush(strings, str)
		}
		
		;// Check for missing opening/closing brace(s)
		if InStr(src, '{') || InStr(src, '}')
		{
			StrReplace(src, '{', '{', c1), StrReplace(src, '}', '}', c2)
			if (c1 != c2)
				throw Exception("Missing %Abs(c1-c2)% %(c1 > c2 ? 'clos' : 'open')%ing brace(s)")
		}
		;// Check for missing opening/closing bracket(s)
		if InStr(src, '[') || InStr(src, ']')
		{
			StrReplace(src, '[', '[', c1), StrReplace(src, ']', ']', c2)
			if (c1 != c2)
				throw Exception("Missing %Abs(c1-c2)% %(c1 > c2 ? 'clos' : 'open')%ing bracket(s)")
		}
		
		static t := "true", f := "false", n := "null", null := ""
		jbase := jsonize ? { "{":JSON.object, "[":JSON.array } : { "{":0, "[":0 }
		, pos := 0
		, key := "", is_key := false
		, stack := [tree := []]
		, is_arr := {(tree): 1}
		, next := first ;// '"{[01234567890-tfn'
		while ((ch := SubStr(src, ++pos, 1)) != "")
		{
			if InStr(" `t`n`r", ch)
				continue
			if !InStr(next, ch)
				throw Exception("Unexpected char: '%ch%'")
			
			is_array := is_arr[obj := stack[1]]
			
			if InStr("{[", ch)
			{
				val := (proto := jbase[ch]) ? new proto : {}
				, obj[is_array? ObjLength(obj)+1 : key] := val
				, ObjInsertAt(stack, 1, val)
				, is_arr[val] := !(is_key := ch == "{")
				, next := is_key ? '"}' : '"{[]0123456789-tfn'
			}

			else if InStr("}]", ch)
			{
				ObjRemoveAt(stack, 1)
				, next := is_arr[stack[1]] ? "]," : "},"
			}

			else if InStr(",:", ch)
			{
				if (obj == tree)
					throw Exception("Unexpected char: '%ch%' -> there is no container object.")
				next := '"{[0123456789-tfn', is_key := (!is_array && ch == ",")
			}

			else
			{
				if (ch == '"')
				{
					val := ObjRemoveAt(strings, 1)
					if is_key
					{
						key := val, next := ":"
						continue
					}
				}
				else
				{
					val := SubStr(src, pos, (SubStr(src, pos) ~= "[\]\},\s]|$")-1)
					, pos += StrLen(val)-1
					if InStr("tfn", ch, 1)
					{
						if !(val == %ch%)
							throw Exception("Expected '%(%ch%)%' instead of '%val%'")
						val := %val%
					}
					else if (Abs(val) == "")
						throw Exception("Invalid number: %val%")
					val += 0
				}
				obj[is_array? ObjLength(obj)+1 : key] := val
				, next := is_array ? "]," : "},"
			}
		}
		return tree[1]
	}

	stringify(obj:="", indent:="", lvl:=1)
	{
		type := Type(obj)
		if (type == "Object")
		{
			is_array := 0
			for k in obj
				if !(is_array := (k == A_Index)), break

			if (Abs(indent) != "")
			{
				if (indent < 0)
					throw "Indent parameter must be a postive integer"
				spaces := indent, indent := ""
				Loop % spaces
					indent .= " "
			}
			indt := ""
			Loop, % indent ? lvl : 0
				indt .= indent
			
			lvl += 1, out := "" ;// make #Warn happy
			for k, v in obj
			{
				if IsObject(k) || (k == ""), throw Exception("Invalid JSON key")
				
				if !is_array
					out .= ( Type(k) == "String" ? JSON.stringify(k) : '"%k%"' ) ;// key
					    .  ( indent ? ": " : ":" ) ;// token
				out .= JSON.stringify(v, indent, lvl) ;// value
				    .  ( indent ? ",`n%indt%" : "," ) ;// token + indent
			}

			if (out != "")
			{
				out := Trim(out, ",`n%indent%")
				if (indent != "")
					out := "`n%indt%%out%`n" . SubStr(indt, StrLen(indent)+1)
			}
			
			return is_array ? "[%out%]" : "{%out%}"
		}

		else if (type == "Integer" || type == "Float")
			return obj

		else if (type == "String")
		{
			static esc_seq := {
			(Q
				'"': '\"',
				'/': '\/',
				'`b': '\b',
				'`f': '\f',
				'`n': '\n',
				'`r': '\r',
				'`t': '\t'
			)}
			if (obj != "")
			{
				obj := StrReplace(obj, "\", "\\")
				for k, v in esc_seq
					obj := StrReplace(obj, k, v)
				while RegExMatch(obj, "[^\x20-\x7e]", wstr)
				{
					ucp := Ord(wstr.Value), hex := "\u", n := 16
					while ((n -= 4) >= 0)
						hex .= Chr( (x := (ucp >> n) & 15) + (x < 10 ? 48 : 55) )
					obj := StrReplace(obj, wstr.Value, hex)
				}
			}
			return '"%obj%"'
		}
		throw Exception("Unsupported type: '%type%'")
	}

	class object
	{
		__New(args*)
		{
			ObjRawSet(this, "_", [])
			if ((len := ObjLength(args)) & 1)
				throw Exception("Invalid number of parameters")
			Loop len//2
				this[args[A_Index*2-1]] := args[A_Index*2]
		}

		__Set(key, val, args*)
		{
			ObjPush(this._, key)
		}

		Remove(args*)
		{
			is_range := ObjLength(args) > 1
			scs := A_StringCaseSense, A_StringCaseSense := "Off"
			i := -1
			for index, key in ObjClone(this._) {
				if is_range? (key >= args[1] && key <= args[2]) : (key = args[1])
				{
					ObjRemoveAt(this._, index-(i+=1))
					if !is_range, break ;// single key only
				}
			}
			/* Alternative way
			keys := []
			for index, key in this._ {
				if is_range? (key >= args[1] && key <= args[2]) : (key = args[1])
					continue
				ObjPush(keys, key)
			}
			ObjRawSet(this, "_", keys)
			*/
			A_StringCaseSense := scs
			return ObjRemove(this, args*)
		}

		Count()
		{
			return ObjLength(this._)
		}

		stringify(i:="")
		{
			return JSON.stringify(this, i)
		}

		_NewEnum()
		{
			static proto := { "Next": JSON.object.Next }
			return { base: proto, enum: this._._NewEnum(), obj: this }
		}

		Next(ByRef key, ByRef val:="")
		{
			if (ret := this.enum.Next(i, key))
				val := this.obj[key]
			return ret
		}
	}

	class array
	{
		__New(args*)
		{
			args.base := this.base
			return args
		}

		stringify(indent:="")
		{
			return JSON.stringify(this, indent)
		}
	}
}