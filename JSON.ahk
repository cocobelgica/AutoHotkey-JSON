class JSON
{
	parse(src, jsonize:=false) {
		;// Pre-validate JSON source before parsing
		if ((src:=Trim(src, " `t`n`r")) == "") ;// trim whitespace(s)
			throw Exception('Empty JSON source.')
		first := SubStr(src, 1, 1), last := SubStr(src, -1)
		if !InStr('{["tfn0123456789-', first) ;// valid beginning chars
		|| !InStr('}]el0123456789"', last) ;// valid ending chars
		|| (first == '{' && last != '}') ;// if starts w/ '{' must end w/ '}'
		|| (first == '[' && last != ']') ;// if starts w/ '[' must end w/ ']'
		|| (first == '"' && last != '"') ;// if starts w/ '"' must end w/ '"'
		|| (first == 'n' && last != 'l') ;// assume 'null'
		|| (InStr('tf', first) && last != 'e') ;// assume 'true' OR 'false'
		|| (InStr('-0123456789', first) && !(last is 'number')) ;// number
			throw Exception('Invalid JSON format.', -1)
		
		esc_char := {
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
		while (i:=InStr(src, '"',, i+1)) {
			j := i
			while (j:=InStr(src, '"',, j+1)) {
				str := SubStr(src, i+1, j-i-1)
				str := StrReplace(str, "\\", "\u005C")
				if (SubStr(str, -1) != "\")
					break
			}
			if !j, throw Exception("Missing close quote(s).", -1)
			src := SubStr(src, 1, i) . SubStr(src, j+1)
			z := 0
			while (z:=InStr(str, "\",, z+1)) {
				ch := SubStr(str, z+1, 1)
				if InStr('"btnfr/', ch)
					str := SubStr(str, 1, z-1) . esc_char[ch] . SubStr(str, z+2)
				else if (ch = "u") {
					hex := "0x" . SubStr(str, z+2, 4)
					if !(A_IsUnicode || (Abs(hex) < 0x100))
						continue
					str := SubStr(str, 1, z-1) . Chr(hex) . SubStr(str, z+6)
				} else throw Exception("Bad string")
			}
			strings.Insert(str)
		}
		;// Check for missing opening/closing brace(s)
		if InStr(src, '{') || InStr(src, '}') {
			StrReplace(src, '{', '{', c1), StrReplace(src, '}', '}', c2)
			if (c1 != c2), throw Exception("
			(LTrim Q
			Missing %Abs(c1-c2)% %(c1 > c2 ? 'clos' : 'open')%ing brace(s)
			)", -1)
		}
		;// Check for missing opening/closing bracket(s)
		if InStr(src, '[') || InStr(src, ']') {
			StrReplace(src, '[', '[', c1), StrReplace(src, ']', ']', c2)
			if (c1 != c2), throw Exception("
			(LTrim Q
			Missing %Abs(c1-c2)% %(c1 > c2 ? 'clos' : 'open')%ing bracket(s)
			)", -1)
		}
		if jsonize, (_object := this.object, _array := this.array)
		else (_object := Object(), _array := Array())
		pos := 0
		, key := dummy := []
		, stack := [result := []]
		, assert := "" ;// assert := '{["tfn0123456789-'
		, null := ""
		;// Begin recursive descent
		while ((ch := SubStr(src, ++pos, 1)) != "") {
			;// skip whitespace
			while (ch != "" && InStr(" `t`n`r", ch))
				ch := SubStr(src, ++pos, 1)
			;// check if current char is expected or not
			if (assert != "") {
				if !InStr(assert, ch), throw Exception("Unexpected '%ch%'", -1)
				assert := ""
			}

			if InStr(":,", ch) { ;// colon(s) and comma(s)
				;// no container object
				if (cont == result), throw Exception("
				(LTrim
				Unexpected '%ch%' -> there is no container object/array.
				)")
				assert := (cont is _object && ch == ',') ? '"' : '{["tfn0123456789-'
			
			} else if InStr("{[", ch) { ;// object|array - opening
				cont := stack[1]
				, sub := new (ch == '{' ? _object : _array)
				, stack.Insert(1, cont[key == dummy ? (ObjMaxIndex(cont) || 0)+1 : key] := sub)
				, assert := (ch == '{' ? '"}' : ']{["tfn0123456789-')
				if (key != dummy), key := dummy
			
			} else if InStr("}]", ch) { ;// object|array - closing
				cont := stack.Remove(1)
				;// remove base if set to output normal AHK object(s)
				if !jsonize, cont.base := ""
				cont := stack[1]
				, assert := cont is _object ? '},' : '],'
			
			} else if (ch == '"') { ;// string
				str := strings.Remove(1), cont := stack[1]
				if (key == dummy) {
					if (cont is _object) {
						key := str, assert := ':'
						continue
					}
					;// _array or result | using 'else' seems faster, sometimes
					else key := (ObjMaxIndex(cont) || 0)+1
				}
				cont[key] := str
				, assert := cont is _object ? '},' : '],'
				, key := dummy
			
			} else if (ch >= 0 && ch <= 9) || (ch == "-") { ;// number
				if !RegExMatch(src, "-?\d+(\.\d+)?((?i)E[-+]?\d+)?", num, pos)
					throw Exception("Bad number", -1)
				pos += num.Len()-1
				, cont := stack[1]
				, cont[key == dummy ? (ObjMaxIndex(cont) || 0)+1 : key] := num.Value+0
				, assert := cont is _object ? '},' : '],'
				if (key != dummy), key := dummy
			
			} else if InStr("tfn", ch, true) { ;// true|false|null
				/* Ternary seems faster compared to object ->
				 * val := {t:"true", f:"false", n:"null"}[ch]
				 */
				val := (ch == 't') ? 'true' : (ch == 'f') ? 'false' : 'null'
				;// case-sensitve comparison
				if !((tfn:=SubStr(src, pos, len:=StrLen(val))) == val)
					throw Exception("Expected '%val%' instead of '%tfn%'")
				pos += len-1
				, cont := stack[1]
				, cont[key == dummy ? (ObjMaxIndex(cont) || 0)+1 : key] := %val%+0
				, assert := cont is _object ? '},' : '],'
				if (key != dummy), key := dummy
			}
		}
		return result[1]
	}

	stringify(obj:="", indent:="", lvl:=1) {
		type := Type(obj)
		if (type == "Object") {
			for k in obj
				if !(arr := (k == A_Index)), break
			
			n := indent ? "`n" : (i := indent := "")
			Loop, % indent ? lvl : 0
				i .= indent
			
			lvl += 1, str := "" ;// make #Warn happy
			for k, v in obj {
				if IsObject(k) || (k == ""), throw Exception("Invalid key.", -1)
				if !arr, key := k is 'number' ? '"%k%"' : JSON.stringify(k)
				val := JSON.stringify(v, indent, lvl)
				;// format output
				str .= (arr ? "" : "
				(LTrim Join Q C
				%key%:%(indent
				? (IsObject(v) && InStr(val, '{') == 1 && val != '{}')
				  ? n . i
				  : ' '
				: '')%
				)") . "%val%,%(indent ? n . i : '')%"
			}
			;// trim and pad
			if (str != "") {
				str := Trim(str, ",`n`t ")
				if indent, str := n . i . str . n . SubStr(i, StrLen(indent)+1)
			}
			return arr ? "[%str%]" : "{%str%}"
		
		} else if (type == "Integer" || type == "Float") {
			return InStr('01', obj) ? (obj ? 'true' : 'false') : obj
		
		} else if (type == "String") {
			if (obj == ""), return 'null'
			esc_char := {
			(Q
				'"': '\"',
				'/': '\/',
				'`b': '\b',
				'`f': '\f',
				'`n': '\n',
				'`r': '\r',
				'`t': '\t'
			)}
			obj := StrReplace(obj, "\", "\\")
			for k, v in esc_char
				obj := StrReplace(obj, k, v)
			while RegExMatch(obj, "[^\x20-\x7e]", ch) {
				ustr := Ord(ch.Value), esc_ch := "\u", n := 12
				while (n >= 0)
					esc_ch .= Chr((x:=(ustr>>n) & 15) + (x<10 ? 48 : 55)), n -= 4
				obj := StrReplace(obj, ch.Value, esc_ch)
			}
			return '"%obj%"'
		}
		throw Exception("Unsupported type: '%type%'")
	}

	class object
	{
		__New(p*) {
			ObjInsert(this, "_", [])
			if Mod(p.MaxIndex(), 2), p.Insert("")
			Loop p.MaxIndex()//2
				this[p[A_Index*2-1]] := p[A_Index*2]
		}

		__Set(k, v, p*) {
			this._.Insert(k)
		}

		_NewEnum() {
			return new JSON.object.Enum(this)
		}

		Insert(k, v) {
			return this[k] := v
		}

		Remove(k*) {
			ascs := A_StringCaseSense
			A_StringCaseSense := 'Off'
			if (k.MaxIndex() > 1) {
				k1 := k[1], k2 := k[2], is_int := false
				if k1 is 'integer' && k2 is 'integer'
					k1 := Round(k1), k2 := Round(k2), is_int := true
				while true {
					for each, key in this._
						i := each
					until found:=(key >= k1 && key <= k2)
					if !found, break
					key := this._.Remove(i)
					ObjRemove(this, (is_int ? [key, ''] : [key])*)
					res := A_Index
				}
			
			} else for each, key in this._ {
				if (key = (k.MaxIndex() ? k[1] : ObjMaxIndex(this))) {
					key := this._.Remove(each)
					res := ObjRemove(this, (key is 'integer' ? [key, ''] : [key])*)
					break
				}
			}
			A_StringCaseSense := ascs
			return res
		}

		GetCapacity(k*) {
			return ObjGetCapacity((k.MinIndex() ? [this, k[1]] : [this._])*)
		}

		len() {
			return (this._.MaxIndex() || 0)
		}

		stringify(i:="") {
			return JSON.stringify(this, i)
		}

		class Enum
		{
			__New(obj) {
				this.obj := obj
				this.enum := obj._._NewEnum()
			}
			; Lexikos' ordered array workaround
			Next(ByRef k, ByRef v:="") {
				if (r:=this.enum.Next(i, k)), v := this.obj[k]
				return r
			}
		}
	}

	class array
	{
		__New(p*) {
			for k, v in p
				this.Insert(v)
		}

		stringify(i:="") {
			return JSON.stringify(this, i)
		}
	}
}