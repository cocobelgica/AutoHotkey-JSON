/*
JSON module for AutoHotkey
More comments to come!
*/
class JSON
{
	
	parse(src) {
		static object := {__type__:"object"} ; Fix this, create class
		static array := {__type__:"array"} ; Fix this, create class
		esc_char := {"""":"""", "/":"/", "b":Chr(08), "f":Chr(12), "n":"`n", "r":"`r", "t":"`t"}
		null := "" ; needed??

		i := 0, strings := []
		while (i:=InStr(src, """",, i+1)) {
			j := i
			while (j:=InStr(src, """",, j+1)) {
				str := SubStr(src, i+1, j-i-1)
				StringReplace, str, str, \\, \u005C, A
				if (SubStr(str, 0) != "\")
					break
			}

			src := SubStr(src, 1, i-1) . SubStr(src, j)

			z := 0
			while (z:=InStr(str, "\",, z+1)) {
				ch := SubStr(str, z+1, 1)
				if InStr("""btnfr/", ch) ; esc_char.HasKey(ch)
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
		stack := [result:=new array], assert := "{[""tfn0123456789-"
		while (ch != "", ch:=SubStr(src, pos, 1), pos+=1) {
			
			while (ch != "" && InStr(" `t`r`n", ch)) ; skip whitespace
				ch := SubStr(src, pos, 1), pos += 1
				;pos := RegExMatch(src, "\S", ch, pos)+1
			/*
			Check if the current character is expected or not
			Speed is somehow sacrificed..
			*/
			if (assert != "") {
				if !InStr(assert, ch)
					throw Exception("Unexpected '" . ch . "'", -1)
				assert := ""
			}
			
			if InStr(":,", ch) {
				assert := "{[""tfn0123456789-"
				continue
			}

			if InStr("{[", ch) {
				cont := stack[1], __base__ := (ch == "{" ? "object" : "array")
				len := (i:=cont.MaxIndex()) ? i : 0
				stack.Insert(1, cont[key == dummy ? len+1 : key] := new %__base__%)
				key := dummy
				assert := (ch == "{" ? """}" : "]{[""tfn0123456789-")
				continue
			
			} else if InStr("}]", ch) {
				stack.Remove(1), assert := "]},"
				continue
			
			} else if (ch == """") {
				str := strings.Remove(1), cont := stack[1]
				if (key == dummy) {
					if (cont.__type__ == "array") {
						key := ((i:=cont.MaxIndex()) ? i : 0)+1
					} else {
						key := str, assert := ":"
						continue
					}
				}
				cont[key] := str, key := dummy
				assert := "," . {"object":"}", "array":"]"}[cont.__type__]
				continue
			
			} else if (ch >= 0 && ch <= 9) || (ch == "-") { ; number
				if !RegExMatch(src, "-?\d+(\.\d+)?((?i)E[-+]?\d+)?", num, pos-1)
					throw Exception("Bad number", -1)
				pos += StrLen(num)-1
				cont := stack[1], len := (i:=cont.MaxIndex()) ? i : 0
				cont[key == dummy ? len+1 : key] := num
				key := dummy
				assert := "," . {"object":"}", "array":"]"}[cont.__type__]
				continue
			
			} else if InStr("tfn", ch, true) { ; true|false|null
				val := {t:"true", f:"false", n:"null"}[ch]
				; advance to next char, first char has already been validated
				while (c:=SubStr(val, A_Index+1, 1)) {
					ch := SubStr(src, pos, 1), pos += 1
					if !(ch == c) ; case-sensitive comparison
						throw Exception("Expected '" c "' instead of " ch)
				}

				cont := stack[1], len := (i:=cont.MaxIndex()) ? i : 0
				cont[key == dummy ? len+1 : key] := %val%
			    key := dummy
			    assert := "," . {"object":"}", "array":"]"}[cont.__type__]
			    continue
			
			} else {
				if (ch != "")
					throw Exception("Unexpected '" . ch . "'", -1)
				else break
			}
		}
		return result[1]
	}

	stringify(obj:="", i:="", lvl:=1) {
		if IsObject(obj) {
			for k in obj
				arr := (k == A_Index)
			until !arr

			n := i ? "`n" : (i:="", t:="")
			Loop, % i ? lvl : 0
				t .= i

			lvl += 1
			for k, v in obj {
				if !arr
					key := InStr(r:=JSON.stringify(k, i, lvl), """") == 1
					       ? r : """" . r . """"
				val := JSON.stringify(v, i, lvl)
				s := "," . (n ? n : " ") . t
				str .= arr ? (val . s)
				           : key . ":" . ((IsObject(v) && InStr(val, "{") == 1) ? n . t : " ") . val . s
			}
			str := n . t . Trim(str, ",`n`t ") . n . SubStr(t, StrLen(i)+1)
			return arr ? "[" str "]" : "{" str "}"
		}

		else if InStr(01, obj) || (obj == "")
			return {"": "null", 0:"false", 1:"true"}[obj]

		else if obj is number
		{
			; Fix this
			if (SubStr(obj, 1, 2) == "0x") || (obj ~= "i)[a-f]+")
			{
				afi := A_FormatInteger
				SetFormat, Integer, h
				obj += 0
				SetFormat, Integer, % afi
				return """" . obj . """"
			}
			
			return obj
		}

		else {
			esc_char := {"""":"\"""
			           , "/":"\/"
			           , Chr(08):"\b"
			           , Chr(12):"\f"
			           , "`n":"\n"
			           , "`r":"\r"
			           , "`t":"\t"}
			
			StringReplace, obj, obj, \, \\, A
			for k, v in esc_char
				StringReplace, obj, obj, % k, % v, A

			while RegExMatch(obj, "[^\x20-\x7e]", ch) {
				ustr := Asc(ch), esc_ch := "\u", n := 12
				while (n >= 0)
					esc_ch .= Chr((x:=(ustr>>n) & 15) + (x<10 ? 48 : 55))
					, n -= 4
				StringReplace, obj, obj, % ch, % esc_ch, A
			}
			return """" . obj . """"
		}
	}

	class __object__
	{

		__New(p*) {
			ObjInsert(this, "_", [])
			if Mod(p.MaxIndex(), 2)
				p.Insert("")
			for k, v in p {
				if !Mod(A_Index, 2)
					this[key] := v
				else key := v
			}
		}

		__Set(k, v, p*) {
			this._.Insert(k)
		}

		_NewEnum() {
			return new JSON.__object__.Enum(this)
		}

		Insert(k, v) {
			return this[k] := v
		}

		Remove(k) {
			if !ObjHasKey(this, k)
				return
			for i, v in this._
				continue
			until (v = k)
			this._.Remove(i)
			return ObjRemove(this, k)
		}

		len() {
			return this._.MaxIndex()
		}

		class Enum
		{

			__New(obj) {
				this.obj := obj
				this.enum := obj._._NewEnum()
			}

			Next(ByRef k, ByRef v:="") {
				if (r:=this.enum.Next(i, k))
					v := this.obj[k]
				return r
			}
		}
	}
}