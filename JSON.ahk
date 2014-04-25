class JSON
{
	parse(src) {
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
		null := ""
		i := 0, strings := []
		while (i:=InStr(src, '"',, i+1)) {
			j := i
			while (j:=InStr(src, '"',, j+1)) {
				str := SubStr(src, i+1, j-i-1)
				str := StrReplace(str, "\\", "\u005C")
				if (SubStr(str, 0) != "\")
					break
			}
			src := SubStr(src, 1, i-1) . SubStr(src, j)
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
		pos := 1, ch := " "
		key := dummy := []
		stack := [result:=new JSON.array], assert := '{["tfn0123456789-'
		while (ch != "") {
			ch := SubStr(src, pos, 1), pos += 1
			while (ch != "" && InStr(" `t`n`r", ch))
				ch := SubStr(src, pos, 1), pos += 1
			if (assert != "") {
				if !InStr(assert, ch), throw Exception("Unexpected '%ch%'", -1)
				assert := ""
			}

			if InStr(":,", ch) {
				assert := '{["tfn0123456789-'
				continue
			}

			if InStr("{[", ch) { ; object|array - opening
				cont := stack[1], base := (ch == '{' ? 'object' : 'array')
				len := (ObjMaxIndex(cont) || 0)
				stack.Insert(1, cont[key == dummy ? len+1 : key] := new JSON[base])
				key := dummy
				assert := (ch == '{' ? '"}' : ']{["tfn0123456789-')
				continue
			
			} else if InStr("}]", ch) { ; object|array - closing
				stack.Remove(1), assert := ']},'
				continue
			
			} else if (ch == '"') { ; string
				str := strings.Remove(1), cont := stack[1]
				if (key == dummy) {
					if cont is JSON.array {
						key := (ObjMaxIndex(cont) || 0)+1
					} else {
						key := str, assert := ":"
						continue
					}
				}
				cont[key] := str, key := dummy
				assert := ",%(cont is JSON.object ? '}' : ']')%"
				continue
			
			} else if (ch >= 0 && ch <= 9) || (ch == "-") { ; number
				if !RegExMatch(src, "-?\d+(\.\d+)?((?i)E[-+]?\d+)?", num, pos-1)
					throw Exception("Bad number", -1)
				pos += StrLen(num.Value)-1
				cont := stack[1], len := (ObjMaxIndex(cont) || 0)
				cont[key == dummy ? len+1 : key] := num.Value+0 ; convert to pure number
				key := dummy
				assert := ",%(cont is JSON.object ? '}' : ']')%"
				continue
			
			} else if InStr("tfn", ch, true) { ; true|false|null
				val := {t:"true", f:"false", n:"null"}[ch]
				; advance to next char, first char has already been validated
				while (c:=SubStr(val, A_Index+1, 1)) {
					ch := SubStr(src, pos, 1), pos += 1
					if !(ch == c) ; case-sensitive comparison
						throw Exception("Expected '%c%' instead of %ch%")
				}

				cont := stack[1], len := (ObjMaxIndex(cont) || 0)
				cont[key == dummy ? len+1 : key] := Abs(%val%)
				key := dummy
				assert := ",%(cont is JSON.object ? '}' : ']')%"
				continue
			
			} else {
				if (ch != ""), throw Exception("Unexpected '%ch%'", -1)
				else break
			}
		}
		return result[1]
	}

	stringify(obj:="", i:="", lvl:=1) {
		type := Type(obj)
		if (type == "Object") {
			if (obj is JSON.object || obj is JSON.array)
				arr := obj is JSON.array
			else for k in obj
				if !(arr := (k == A_Index)), break
			
			n := i ? "`n" : (i:="", t:="")
			Loop, % i ? lvl : 0
				t .= i
			
			lvl += 1
			for k, v in obj {
				if IsObject(k) || (k == ""), throw Exception("Invalid key.", -1)
				if !arr, key := k is 'number' ? '"%k%"' : JSON.stringify(k)
				val := JSON.stringify(v, i, lvl)
				s := ",%(n ? n : ' ') . t%"
				str .= arr
				? val . s
				: "%key%:%((IsObject(v) && InStr(val, '{') == 1) ? n . t : ' ')%%val%%s%"
			}
			str := n . t . Trim(str, ",`n`t ") . n . SubStr(t, StrLen(i)+1)
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
