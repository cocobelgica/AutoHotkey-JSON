/*
JSON module for AutoHotkey [requires v.1.1+, tested on v.1.1.13.01]

The parser is inspired by Douglas Crockford's(json.org) json_parse.js and
and Mike Samuel's json_sans_eval.js (https://code.google.com/p/json-sans-eval/).
I've combined the two implementation to create a fast(somehow:P) and validating
JSON parser. Some section(s) are based on VxE's JSON function(s) - 
[http://www.ahkscript.org/boards/viewtopic.php?f=6&t=30] - Thank you VxE
*/
class JSON
{
	/*
	Parses a string containing JSON string and returns it as an AHK object.
	Objects {} and arrays [] are wrapped as JSON.object and JSON.array instances.
	Objects {} key-value pairs are enumerated in the order they are created
	instead of the default behavior -- alpahabetically. An exception is thrown
	if the JSON string is badly formatted, e.g. illegal chars, invalid escaping
	Usage:
	--start-of-code--
	j := JSON.parse("[{""foo"": ""Hello World"", ""bar"":""AutoHotkey""}]")
	MsgBox, % j[1].foo ; displays 'Hello World'
	MsgBox, % j[1].bar ; displays 'AutoHotkey'
	--end-of-code--
	*/
	parse(src) {
		esc_char := {"""":"""", "/":"/", "b":Chr(08), "f":Chr(12), "n":"`n", "r":"`r", "t":"`t"}
		null := "" ; needed??

		/*
		This loop is based on VxE's JSON_ToObj.ahk - thank you VxE
		Quoted strings are extracted and temporarily stored in an object and
		later on re-inserted while the result object is being created.
		*/
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
						continue ; throw Exception() ???
					str := SubStr(str, 1, z-1) . Chr(hex) . SubStr(str, z+6)
				
				} else throw Exception("Bad string")
			}
			strings.Insert(str)
		}
		
		pos := 1, ch := " "
		key := dummy := []
		stack := [result:=new JSON.array], assert := "{[""tfn0123456789-"
		while (ch != "", ch:=SubStr(src, pos, 1), pos+=1) {
			
			while (ch != "" && InStr(" `t`r`n", ch)) ; skip whitespace
				ch := SubStr(src, pos, 1), pos += 1
				;pos := RegExMatch(src, "\S", ch, pos)+1
			/*
			Check if the current character is expected or not
			Acts as a simple validator for badly formatted JSON string
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

			if InStr("{[", ch) { ; object|array - opening
				cont := stack[1], base := (ch == "{" ? "object" : "array")
				len := (i:=ObjMaxIndex(cont)) ? i : 0
				stack.Insert(1, cont[key == dummy ? len+1 : key] := new JSON[base])
				key := dummy
				assert := (ch == "{" ? """}" : "]{[""tfn0123456789-")
				continue
			
			} else if InStr("}]", ch) { ; object|array - closing
				stack.Remove(1), assert := "]},"
				continue
			
			} else if (ch == """") { ; string
				str := strings.Remove(1), cont := stack[1]
				if (key == dummy) {
					if (cont.__Class == "JSON.array") {
						key := ((i:=ObjMaxIndex(cont)) ? i : 0)+1
					} else {
						key := str, assert := ":"
						continue
					}
				}
				cont[key] := str, key := dummy
				assert := "," . (cont.__Class == "JSON.object" ? "}" : "]")
				continue
			
			} else if (ch >= 0 && ch <= 9) || (ch == "-") { ; number
				if !RegExMatch(src, "-?\d+(\.\d+)?((?i)E[-+]?\d+)?", num, pos-1)
					throw Exception("Bad number", -1)
				pos += StrLen(num)-1
				cont := stack[1], len := (i:=ObjMaxIndex(cont)) ? i : 0
				cont[key == dummy ? len+1 : key] := num
				key := dummy
				assert := "," . (cont.__Class == "JSON.object" ? "}" : "]")
				continue
			
			} else if InStr("tfn", ch, true) { ; true|false|null
				val := {t:"true", f:"false", n:"null"}[ch]
				; advance to next char, first char has already been validated
				while (c:=SubStr(val, A_Index+1, 1)) {
					ch := SubStr(src, pos, 1), pos += 1
					if !(ch == c) ; case-sensitive comparison
						throw Exception("Expected '" c "' instead of " ch)
				}

				cont := stack[1], len := (i:=ObjMaxIndex(cont)) ? i : 0
				cont[key == dummy ? len+1 : key] := %val%
			    key := dummy
			    assert := "," . (cont.__Class == "JSON.object" ? "}" : "]")
			    continue
			
			} else {
				if (ch != "")
					throw Exception("Unexpected '" . ch . "'", -1)
				else break
			}
		}
		return result[1]
	}
	/*
	Returns a string representation of an AHK object.
	The 'i' (indent) parameter allows 'pretty printing'. Specify any char(s)
	to use as indentation.
	Usage: JSON.stringify(object, "`t") ; use tab as indentation
	       JSON.stringify(object, "    ") ; 4-spaces indentation
	       JSON.stringify(object) ; no indentation
	Remarks:
	JSON.object and JSON.array instance(s) may call this method, automatically
	passing itself as the first parameter. If indententation is specified,
	nested arrays [] are in OTB-style.
	As per JSON spec, hex numbers are treated as strings - doing something
	like: 'JSON.stringify([0xfff])' will output '0xffff' as decimal. To
	output as string, wrap it in quotes: 'JSON.stringify(["0xffff"])'
	0, 1 and ""(blank) are output as false, true and null respectively.
 	*/
	stringify(obj:="", i:="", lvl:=1) {
		if IsObject(obj) {
			if (obj.base == JSON.object || obj.base == JSON.array)
				arr := (obj.base == JSON.array ? true : false)
			else for k in obj
				arr := (k == A_Index)
			until !arr

			n := i ? "`n" : (i:="", t:="")
			Loop, % i ? lvl : 0
				t .= i

			lvl += 1
			for k, v in obj {
				if IsObject(k) || (k == "")
					throw Exception("Invalid key.", -1)
				if !arr
					; integer key(s) are automatically wrapped in quotes
					key := k+0 == k ? """" . k . """" : JSON.stringify(k)
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
			if obj is xdigit
				if obj is not digit
					obj := """" . obj . """"
			
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
	/*
	Base object for objects {} created during parsing. The user may also manually
	create an insatnce of this class. The sole purpose of wrapping objects {} as
	JSON.object instance is to allow enumeration of key-value pairs in the order
	they were created. The len() method may be used to get the total count of
	key-value pairs.
	Usage: Instances are automatically created during parsing. The user may
	       use the 'new' operator to create a JSON.object object manually.
	--start-of-code--
	obj := new JSON.object("key1", "value1", "key2", "value2")
	obj["key3"] := "Add a new key-value pair"
	MsgBox, % obj.stringify() ; display as string
	; '{"key1": "value1", "key2": "value2", "key3": "Add a new key-value pair"}'
	--end-of-code--
	*/
	class object
	{
		
		__New(p*) {
			ObjInsert(this, "_", [])
			if Mod(p.MaxIndex(), 2)
				p.Insert("")
			Loop, % p.MaxIndex()//2
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

		Remove(k) { ; restrict to single key
			if !ObjHasKey(this, k)
				return
			for i, v in this._
				continue
			until (v = k)
			this._.Remove(i)
			if k is integer
				return ObjRemove(this, k, "")
			return ObjRemove(this, k)
		}

		len() {
			return this._.MaxIndex()
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
				if (r:=this.enum.Next(i, k))
					v := this.obj[k]
				return r
			}
		}
	}
	/*
	Base object for arrays [] created during parsing. Same as JSON.object above.
	*/	
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