; JSON Lib
class JSON
{
	
	parse(src) {
		res := new JSON.deserializer(src)
		return res.out
	}

	stringify(obj) {

	}

	class deserializer
	{

		__New(src) {
			this.src := src
			this.pos := 1
			this.ch := " "
			this.out := this.value()
		}

		char_at(pos) {
			return SubStr(this.src, pos, 1)
		}

		next(c:="") {
			if (c != "" && c != this.ch)
				throw Exception("Expected '" . c . "' instead of '" . this.ch . "'")
			this.ch := SubStr(this.src, this.pos, 1) ; char at pos
			this.pos += 1
			return this.ch
		}

		object() {
			obj := {}
			if (this.ch != "{")
				throw Exception("Bad object")
			this.next("{"), this.skip_ws()
			if (this.ch == "}") {
				this.next("}")
				return obj
			}
			
			while this.ch {
				key := this.string()
				this.skip_ws(), this.next(":")
				obj[key] := this.value()
				this.skip_ws()
				if (this.ch == "}") {
					this.next("}")
					return obj
				}
				this.next(","), this.skip_ws()
			}
		}

		array() {
			arr := []
			if (this.ch != "[")
				throw Exception("Bad array")
			this.next("["), this.skip_ws()
			if (this.ch == "]") {
				this.next("]")
				return arr
			}
			while this.ch {
				arr.Insert(this.value())
				this.skip_ws()
				if (this.ch == "]") {
					this.next("]")
					return arr
				}
				this.next(","), this.skip_ws()
			}
		}
		
		string() {
			static esc_char

			if !esc_char ; Not #Warn friendly
				esc_char := {"""": """"   ; double quote
				           , "/": "/"     ; forward slash
				           , "b": Chr(08) ; backspace
				           , "f": Chr(12) ; form feed
				           , "n": "`n"    ; newline
				           , "r": "`r"    ; carriage return
				           , "t": "`t"}   ; horiontal tab
			
			if (this.ch != """")
				throw Exception("Bad string")
			src := SubStr(this.src, this.pos-1)
			
			j := i := InStr(src, """")
			while (j:=InStr(src, """",, j+1)) {
				str := SubStr(src, i+1, j-i-1)
				StringReplace, str, str, \\, \u005C, A
				if (SubStr(str, 0) != "\")
					break
			}
			
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
			
			this.pos += j-1, this.next()
			return str
		}

		number() {
			src := SubStr(this.src, this.pos-1)
			xpr := "^[-+]?\d+(\.\d+)?((?i)E[-+]?\d+)?"
			if !RegExMatch(src, xpr, num)
				throw Exception("Bad number")
			this.pos += StrLen(num)-1, this.next()
			return num
			/*
			; json_parse.js implementation
			if (this.ch == "-")
				num := "-", this.next("-")
			while (this.ch >= 0 && this.ch <= 9)
				num .= this.ch, this.next()
			if (this.ch == ".") {
				num .= "."
				while (this.next() && this.ch >= 0 && this.ch <= 9)
					num .= this.ch
			}
			if (this.ch = "e") {
				num .= this.ch, this.next()
				if InStr("-+", this.ch)
					num .= this.ch, this.next()
				while (this.ch >= 0 && this.ch <= 9)
					num .= this.ch, this.next()
			}
			return num
			*/
		}
		/*
		true, false or null
		*/
		const() {
			ch := this.ch
			c := {t:{str:"true", val:true}
			    , f:{str:"false", val:false}
			    , n:{str:"null", val:""}}
			if !c.HasKey(ch)
				throw Exception("Unexpected '" . ch . "'")
			str := c[ch].str
			Loop, Parse, str
				try this.next(A_LoopField)
				catch e
					throw e
			return c[ch].val
		}
		/*
		Parse a JSON value [array, object, string, number, word(true, false, null)]
		*/
		value() {
			this.skip_ws()
			if ((ch:=this.ch) == "{")
				return this.object()
			else if (ch == "[")
				return this.array()
			else if (ch == """")
				return this.string()
			else if (ch == "-")
				return this.number()
			else return (ch >= 0 && ch <= 9)
			            ? this.number()
			            : this.const()
		}
		/*
		Skip whitespace
		*/
		skip_ws() {
			while (this.ch != "" && this.ch == " ") ; Handle 'tabs' as well?
				this.next()
		}
	}
}