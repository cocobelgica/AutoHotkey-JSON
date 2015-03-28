/* Class: JSON
 *     JSON lib for AutoHotkey
 * Version:
 *     v1.2.00.00 [updated 03/28/2015 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     AutoHotkey v1.1.21.00+ OR v2.0-a+
 * Installation:
 *     Use #Include JSON.ahk or #Include <JSON>. Must be copied into a function
 *     library folder for the latter.
 * Others:
 *     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
 *     Forum Topic - http://goo.gl/r0zI8t
 *     Email:      - cocobelgica@gmail.com
 */
class JSON
{
	/* Method: Load
	 *     Deserialize a string containing a JSON document to an AHK object.
	 * Syntax:
	 *     json_obj := JSON.Load( ByRef src [ , jsonize := false ] )
	 * Parameter(s):
	 *     src  [in, ByRef] - String containing a JSON document
	 *     jsonize     [in] - If true, objects {} and arrays [] are wrapped as
	 *                        JSON.Object and JSON.Array instances respectively.
	 */
	Load(ByRef src, jsonize:=false)
	{
		static q := Chr(34)

		args := jsonize ? [ JSON.Object, JSON.Array ] : []
		key := "", is_key := false
		stack := [ tree := [] ]
		is_arr := { (tree): 1 }
		next := q . "{[01234567890-tfn"
		pos := 0
		while ( (ch := SubStr(src, ++pos, 1)) != "" )
		{
			if InStr(" `t`n`r", ch)
				continue
			if !InStr(next, ch)
			{
				ln  := ObjLength(StrSplit(SubStr(src, 1, pos), "`n"))
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
				is_array? ObjPush(obj, val) : obj[key] := val
				ObjInsertAt(stack, 1, val)
				
				is_arr[val] := !(is_key := ch == "{")
				next := q . (is_key ? "}" : "{[]0123456789-tfn")
			}

			else if InStr("}]", ch)
			{
				ObjRemoveAt(stack, 1)
				next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
			}

			else if InStr(",:", ch)
			{
				is_key := (!is_array && ch == ",")
				next := is_key ? q : q . "{[0123456789-tfn"
			}

			else
			{
				if (ch == q)
				{
					i := pos
					while i := InStr(src, q,, i+1)
					{
						val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
						static end := A_AhkVersion<"2" ? 0 : -1
						if (SubStr(val, end) != "\")
							break
					}
					if !i ? (pos--, next := "'") : 0
						continue
					
					pos := i ; update pos

					  val := StrReplace(val,    "\/",  "/")
					, val := StrReplace(val, "\" . q,    q)
					, val := StrReplace(val,    "\b", "`b")
					, val := StrReplace(val,    "\f", "`f")
					, val := StrReplace(val,    "\n", "`n")
					, val := StrReplace(val,    "\r", "`r")
					, val := StrReplace(val,    "\t", "`t")

					i := 0
					while (i := InStr(val, "\",, i+1))
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
				
				else
				{
					val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
					
					static null := "" ; for #Warn
					if InStr(",true,false,null,", "," . val . ",", true) ; if var in
						val := %val%
					else if (Abs(val) == "") ? (pos--, next := "#") : 0
						continue
					
					val := val + 0, pos += i-1
				}
				
				is_array? ObjPush(obj, val) : obj[key] := val
				next := obj==tree ? "" : is_array ? ",]" : ",}"
			}
		}
		
		return tree[1]
	}
	/* Method: Dump
	 *     Serialize an object to a JSON formatted string.
	 * Syntax:
	 *     json_str := JSON.Dump( obj [ , indent := "" ] )
	 * Parameter(s):
	 *     obj      [in] - The object to stringify.
	 *     indent   [in] - Specify string(s) to use as indentation per level.
 	 */
	Dump(obj:="", indent:="", lvl:=1)
	{
		static q := Chr(34)

		if IsObject(obj)
		{
			static Type := Func("Type")
			if Type ? (Type.Call(obj) != "Object") : (ObjGetCapacity(obj) == "") ; COM,Func,RegExMatch,File,Property object
				throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))
			
			is_array := 0
			for k in obj
				is_array := (k == A_Index)
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

			lvl += 1, out := "" ; make #Warn happy
			for k, v in obj
			{
				if IsObject(k) || (k == "")
					throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
				
				if !is_array
					out .= ( ObjGetCapacity([k], 1) ? JSON.Dump(k) : q . k . q ) ; key
					    .  ( indent ? ": " : ":" ) ; token + padding
				out .= JSON.Dump(v, indent, lvl) ; value
				    .  ( indent ? ",`n" . indt : "," ) ; token + indent
			}
			
			if (out != "")
			{
				out := Trim(out, ",`n" indent)
				if (indent != "")
					out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
			}
			
			return is_array ? "[" . out . "]" : "{" . out . "}"
		}
		
		; Number
		if (ObjGetCapacity([obj], 1) == "") ; returns an integer if 'obj' is string
			return obj
		
		; String (null -> not supported by AHK)
		if (obj != "")
		{
			  obj := StrReplace(obj,  "\",    "\\")
			, obj := StrReplace(obj,  "/",    "\/")
			, obj := StrReplace(obj,    q, "\" . q)
			, obj := StrReplace(obj, "`b",    "\b")
			, obj := StrReplace(obj, "`f",    "\f")
			, obj := StrReplace(obj, "`n",    "\n")
			, obj := StrReplace(obj, "`r",    "\r")
			, obj := StrReplace(obj, "`t",    "\t")

			static needle := (A_AhkVersion<"2" ? "O)" : "") . "[^\x20-\x7e]"
			while RegExMatch(obj, needle, m)
				obj := StrReplace(obj, m[0], Format("\u{:04X}", Ord(m[0])))
		}
		
		return q . obj . q
	}
	
	class Object
	{
		
		__New(args*)
		{
			if ((len := ObjLength(args)) & 1)
				throw Exception("Too few parameters passed to function.", -1, len)

			ObjRawSet(this, "_", []) ; bypass __Set
			Loop % len//2
				this[args[A_Index*2-1]] := args[A_Index*2] ; invoke __Set
		}

		__Set(key, args*)
		{
			ObjPush(this._, key) ; add key to key list and allow __Set to continue normally
		}

		Delete(FirstKey, LastKey*)
		{
			IsRange := ObjLength(LastKey)
			i := 0
			for index, key in ObjClone(this._)
				if IsRange ? (key >= FirstKey && key <= LastKey[1]) : (key = FirstKey)
				{
					ObjRemoveAt(this._, index - (i++))
					if !IsRange ; single key only
						break
				}
			
			return ObjDelete(this, FirstKey, LastKey*)
		}

		Dump(indent:="")
		{
			return JSON.Dump(this, indent)
		}
		static Stringify := JSON.Object.Dump

		_NewEnum()
		{
			static enum := { "Next": JSON.Object._EnumNext }
			return { base: enum, enum: ObjNewEnum(this._), obj: this }
		}

		_EnumNext(ByRef key, ByRef val:="")
		{
			if r := this.enum.Next(, key)
				val := this.obj[key]
			return r
		}
		; Do not implement array methods??
		static InsertAt := "", RemoveAt := "", Push := "", Pop := ""
	}
		
	class Array
	{
			
		__New(args*)
		{
			args.base := this.base
			return args
		}

		Dump(indent:="")
		{
			return JSON.Dump(this, indent)
		}
		static Stringify := JSON.Array.Dump
	}
	; Deprecated but maintained for existing scripts using the lib
	static Parse := JSON.Load ; cast to .Load
	static Stringify := JSON.Dump ; cast to .Dump
}