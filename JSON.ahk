; JSON Lib
class JSON
{
	
	parse(src) {
		res := new JSON.__parser__(src)
		return res.out
	}

	stringify(obj) {

	}

	class __parser__
	{

		__New(src) {
			this.src := src
			this.pos := 1
			this.ch := " "
			this.out := this.value()
		}

		next(c:="") {
			if (c != "" && c != this.ch)
				throw Exception("Expected '" . c . "' instead of '" . this.ch . "'")
			this.ch := SubStr(this.src, this.pos, 1) ; char at pos
			this.pos+=1
			return this.ch
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
		/*
		Optimize this...?
		*/
		string() {
			str := ""
			if (this.ch != """")
				throw Exception("Bad string")
			while this.next() {
				if (this.ch == """") {
					this.next()
					return str
				}
				str .= this.ch
			}
		}

		number() {
			while (this.ch >= 0 && this.ch <= 9) {
				num .= this.ch
				this.next()
			}
			return num
		}

		/*
		true, false or null
		*/
		const() {
			ch := this.ch
			c := {t:{w:"true", r:true}
			    , f:{w:"false", r:false}
			    , n:{w:"null", r:""}}
			if !c.HasKey(ch)
				throw Exception("Unexpected '" . ch . "'")
			const := c[ch].w
			Loop, Parse, const
				this.next(A_LoopField)
			return c[ch].r
		}
		/*
		Parse a JSON value [array, object, string, number, word(true, false, null)]
		*/
		value() {
			this.skip_ws()
			if ((ch:=this.ch) == "[")
				return this.array()
			else if (ch == "{")
				return this.object()
			else if (ch == """")
				return this.string()
			else return (ch >= 0 && ch <= 9) ? this.number() : this.const()
		}
		/*
		Skip whitespace
		*/
		skip_ws() {
			while (this.ch != "" && this.ch == " ") ; Handle 'tabs' as well?
				this.next()
		}
		
		__array() {
			arr := []
			while ((ch:=this.next()) <> "]") {
				if InStr(" ,", ch)
					continue
				if (ch == """")
					arr.Insert(this.string())
				else if (ch ~= "[0-9]")
					this.pos -= 1
					, arr.Insert(this.number())
				else if (ch == "[")
					arr.Insert(this.array())
				else if (ch == "{")
					arr.Insert(this.object())
			}
			return arr
		}

		__object() {
			kv := [], obj := {}
			while ((ch:=this.next()) <> "}") {
				if InStr(" :,", ch)
					continue
				if (ch == """")
					kv.Insert(this.string())
				else if (ch ~= "[0-9]")
					this.pos -= 1
					, kv.Insert(this.number())
				else if (ch == "[")
					kv.Insert(this.array())
				else if (ch == "{")
					kv.Insert(this.object())
				if (kv.MaxIndex() == 2) {
					obj[kv[1]] := kv[2]
					kv := []
				}
			}
			return obj
		}

		__string() {
			q := """"
			src := SubStr(this.src, this.pos)
			i := 1, j := InStr(src, q,, i)
			while (SubStr(src, j-1, 1) == "\")
				j := InStr(src, q,, j+1)
			this.pos += j
			return SubStr(src, i, j-i)
			/*
			while ((ch:=this.next()) <> """")
				str .= ch
			return str
			*/
		}

		__number() {
			while ((ch:=this.next()) ~= "[0-9]")
				num .= ch
			this.pos -= 1
			return num
		}
	}

	__parse(src) {
		q := """"
		str := [], i := 1
		while (i:=InStr(src, q,, i)) {
			j := InStr(src, q,, i+1)
			while (SubStr(src, j-1, 1) == "\")
				j := InStr(src, q,, j+1)
			t := SubStr(src, i+1, j-(i+1))
			str.Insert(t)
			StringReplace, src, src, % q . t . q, % q
			i += 1
		}
		return str
	}
}