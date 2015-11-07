/**
 * Lib: JSON.ahk
 *     JSON lib for AutoHotkey.
 * Version:
 *     v2.0.00.00 [updated 11/07/2015 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
 * Installation:
 *     Use #Include JSON.ahk or copy into a function library folder and then
 *     use #Include <JSON>
 * Links:
 *     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
 *     Forum Topic - http://goo.gl/r0zI8t
 *     Email:      - cocobelgica <at> gmail <dot> com
 */


/**
 * Class: JSON
 *     The JSON object contains methods for parsing JSON and converting values
 *     to JSON. Callable - NO; Instantiable - YES; Subclassable - YES;
 *     Nestable(via #Include) - NO.
 * Methods:
 *     Load() - see relevant documentation before method definition header
 *     Dump() - see relevant documentation before method definition header
 */
class JSON
{
	/**
	 * Method: Load
	 *     Parses a JSON string into an AHK value
	 * Syntax:
	 *     value := JSON.Load( text [, reviver ] )
	 * Parameter(s):
	 *     value      [retval] - parsed value
	 *     text      [in, opt] - JSON formatted string
	 *     reviver   [in, opt] - function object, similar to JavaScript's
	 *                           JSON.parse() 'reviver' parameter
	 */
	class Load extends JSON.Functor
	{
		Call(self, text, reviver:="")
		{
			this.rev := IsObject(reviver) ? reviver : false
			this.keys := this.rev ? {} : false

			static q := Chr(34)
			     , json_value := q . "{[01234567890-tfn"
			     , json_value_or_array_closing := q . "{[]01234567890-tfn"
			     , object_key_or_object_closing := q . "}"

			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0

			while ((ch := SubStr(text, ++pos, 1)) != "") {
				if InStr(" `t`r`n", ch)
					continue
				if !InStr(next, ch, 1)
					this.ParseError(next, text, pos)

				holder := stack[1]
				is_array := holder.IsArray

				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? q : json_value

				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

				} else {
					if InStr("{[", ch) {
					; Check if Array() is overridden and if its return value has
					; the 'IsArray' property. If so, Array() will be called normally,
					; otherwise, use a custom base object for arrays
						static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
					
					; sacrifice readability for minor(actually negligible) performance gain
						(ch == "{")
							? ( is_key := true
							  , value := {}
							  , next := object_key_or_object_closing )
						; ch == "["
							: ( value := json_array ? new json_array : []
							  , next := json_value_or_array_closing )
						
						ObjInsertAt(stack, 1, value)

						if (this.keys)
							this.keys[value] := []
					
					} else {
						if (ch == q) {
							i := pos
							while (i := InStr(text, q,, i+1)) {
								value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

								static ss_end := A_AhkVersion<"2" ? 0 : -1
								if (SubStr(value, ss_end) != "\")
									break
							}

							if (!i)
								this.ParseError("'", text, pos)

							  value := StrReplace(value,    "\/",  "/")
							, value := StrReplace(value, "\" . q,    q)
							, value := StrReplace(value,    "\b", "`b")
							, value := StrReplace(value,    "\f", "`f")
							, value := StrReplace(value,    "\n", "`n")
							, value := StrReplace(value,    "\r", "`r")
							, value := StrReplace(value,    "\t", "`t")

							pos := i ; update pos
							
							i := 0
							while (i := InStr(value, "\",, i+1)) {
								if !(SubStr(value, i+1, 1) == "u")
									this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

								uffff := Abs("0x" . SubStr(value, i+2, 4))
								if (A_IsUnicode || uffff < 0x100)
									value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
							}

							if (is_key) {
								key := value, next := ":"
								continue
							}
						
						} else {
							value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)

							static number := "number", _null := ""
							if value is %number%
								value += 0
							else if (value == "true" || value == "false" || value == "_null")
								value := %value% + 0
							else
							; we can do more here to pinpoint the actual culprit
							; but that's just too much extra work.
								this.ParseError(next, text, pos, i)

							pos += i-1
						}

						next := holder==root ? "" : is_array ? ",]" : ",}"
					} ; If InStr("{[", ch) { ... } else

					is_array? key := ObjPush(holder, value) : holder[key] := value

					if (this.keys && this.keys.HasKey(holder))
						this.keys[holder].Push(key)
				}
			
			} ; while ( ... )

			return this.rev ? this.Walk(root, "") : root[""]
		}

		ParseError(expect, text, pos, len:=1)
		{
			static q := Chr(34)
			
			line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
			col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
			msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
			,     (expect == "")      ? "Extra data"
			    : (expect == "'")     ? "Unterminated string starting at"
			    : (expect == "\")     ? "Invalid \escape"
			    : (expect == ":")     ? "Expecting ':' delimiter"
			    : (expect == q)       ? "Expecting object key enclosed in double quotes"
			    : (expect == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
			    : (expect == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			    : (expect == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			    : InStr(expect, "]")  ? "Expecting JSON value or array closing ']'"
			    :                       "Expecting JSON value(string, number, true, false, null, object or array)"
			, line, col, pos)

			static offset := A_AhkVersion<"2" ? -3 : -4
			throw Exception(msg, offset, SubStr(text, pos, len))
		}

		Walk(holder, key)
		{
			value := holder[key]
			if IsObject(value)
				for i, k in this.keys[value]
					value[k] := this.Walk.Call(this, value, k) ; bypass __Call
			
			return this.rev.Call(holder, key, value)
		}
	}

	/**
	 * Method: Dump
	 *     Converts an AHK value into a JSON string
	 * Syntax:
	 *     str := JSON.Dump( value [, replacer, space ] )
	 * Parameter(s):
	 *     str        [retval] - JSON representation of an AHK value
	 *     value          [in] - any value(object, string, number)
	 *     replacer  [in, opt] - function object, similar to JavaScript's
	 *                           JSON.stringify() 'replacer' parameter
	 *     space     [in, opt] - similar to JavaScript's JSON.stringify()
	 *                           'space' parameter
	 */
	class Dump extends JSON.Functor
	{
		Call(self, value, replacer:="", space:="")
		{
			this.rep := IsObject(replacer) ? replacer : ""

			this.gap := ""
			if (space) {
				static integer := "integer"
				if space is %integer%
					Loop, % ((n := Abs(space))>10 ? 10 : n)
						this.gap .= " "
				else
					this.gap := SubStr(space, 1, 10)

				this.indent := "`n"
			}

			return this.Str({"": value}, "")
		}

		Str(holder, key)
		{
			value := holder[key]

			if (this.rep)
				value := this.rep.Call(holder, key, value)

			if IsObject(value) {
				if (this.gap) {
					stepback := this.indent
					this.indent .= this.gap
				}

				is_array := value.IsArray
				; Array() is not overridden, rollback to old method of
				; identifying array-like objects
				if (!is_array) {
					for i in value
						is_array := i == A_Index
					until !is_array
				}

				str := ""
				if (is_array) {
					Loop, % value.Length() {
						if (this.gap)
							str .= this.indent
						
						str .= value.HasKey(A_Index) ? this.Str(value, A_Index) . "," : "null,"
					}
				} else {
					colon := this.gap ? ": " : ":"
					for k in value {
						if (this.gap)
							str .= this.indent

						str .= this.Quote(k) . colon . this.Str(value, k) . ","
					}
				}

				if (str != "") {
					str := RTrim(str, ",")
					if (this.gap)
						str .= stepback
				}

				if (this.gap)
					this.indent := stepback

				return is_array ? "[" . str . "]" : "{" . str . "}"
			}
			; is_number ? value : "value"
			return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
		}

		Quote(string)
		{
			static q := Chr(34)

			if (string != "") {
				  string := StrReplace(string,  "\",    "\\")
				; , string := StrReplace(string,  "/",    "\/") ; optional in ECMAScript
				, string := StrReplace(string,    q, "\" . q)
				, string := StrReplace(string, "`b",    "\b")
				, string := StrReplace(string, "`f",    "\f")
				, string := StrReplace(string, "`n",    "\n")
				, string := StrReplace(string, "`r",    "\r")
				, string := StrReplace(string, "`t",    "\t")

				static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
				while RegExMatch(string, rx_escapable, m)
					string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
			}

			return q . string . q
		}
	}

	class Functor
	{
		__Call(method, args*)
		{
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, args*)
			else if (method == "")
				return (new this).Call(args*)
		}
	}
}