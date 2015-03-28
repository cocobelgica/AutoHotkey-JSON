# JSON and Jxon

#### [JSON](http://json.org/) lib for [AutoHotkey](http://ahkscript.org/)

Requirements: AutoHotkey _v1.1.21.00+_ or _v2.0-a_

Version: v1.2.00.00 _(updated 03/28/2015)_

License: [WTFPL](http://wtfpl.net/)


- - -

## JSON.ahk (class)
Works on both AutoHotkey _v1.1_ and _v2.0a_

### Installation
Use `#Include JSON.ahk` or `#Include <JSON>`. Must be copied into a [function library folder](http://ahkscript.org/docs/Functions.htm#lib) for the latter.

- - -

#### .Load() _(previously `.parse()`)_
Deserialize _src_ (a JSON formatted string) to an AutoHotkey object

#### Syntax:

    obj := JSON.Load( ByRef src [, jsonize := false ] )


#### Return Value:
An AutoHotkey object

#### Parameter(s):
 * **src** [in, ByRef] - JSON formatted string
 * **jsonize** [in, opt] - if _true_, **_objects_( ``{}`` )** and **_arrays_( ``[]`` )** are wrapped as **JSON.Object** and **JSON.Array** instances respectively. This is to compensate for AutoHotkey's non-distinction between these types and other AHK object type quirks. _e.g.: In AutoHotkey, object keys are enumerated in alphabetical order not in the sequence in which they are created_

- - -

#### .Dump() _(previously `.stringify()`)_
Serialize _obj_ to a JSON formatted string

#### Syntax:

    str := JSON.Dump( obj, [, indent := "" ] )


#### Return Value:
A JSON formatted string

#### Parameter(s):
 * **obj** [in] - AutoHotkey object. Non-standard AHK objects like _COM_, _Func_, _FileObject_, _RegExMatchObject_ are not supported.
 * **indent** [in, opt] -if indent is a non-negative integer or string, then JSON array elements and object members will be pretty-printed with that indent level. Blank( ``""`` ) (the default) or ``0`` selects the most compact representation. Using a positive integer indent indents that many spaces per level. If indent is a string (such as ``"`t"``), that string is used to indent each level. _(I'm lazy, wording taken from Python docs)_

### Remarks:
For compatibilty with existing scripts using this lib. Calls to `.parse()` and `.stringify()` are cast to `.Load()` and `.Dump()` respectively.

- - -
 
## Jxon.ahk (function)
Similar to the JSON class above just implemented as a function. ~~Unlike JSON (class) above, this implementation provides _reading from_ and _writing to_ file~~(Removed `Jxon_Read` and `Jxon_Write`). Works on both AutoHotkey _v1.1_ and _v2.0a_

### Installation
Use `#Include Jxon.ahk` or `#Include <Jxon>`. Must be copied into a [function library folder](http://ahkscript.org/docs/Functions.htm#lib) for the latter.

- - -

### Jxon_Load()
Deserialize _src_ (a JSON formatted string) to an AutoHotkey object

#### Syntax:

    obj := Jxon_Load( ByRef src [ , object_base := "", array_base := "" ] )


#### Parameter(s):
 * **src** [in, ByRef] - JSON formatted string or path to the file containing JSON formatted string.
 * **object_base** [in, opt] - an object to use as prototype for objects( ``{}`` ) created during parsing.
 * **array_base** [in, opt] - an object to use as prototype for arrays( ``[]`` ) created during parsing.

- - -

### Jxon_Dump()
Serialize _obj_ to a JSON formatted string

#### Syntax:

    str := Jxon_Dump( obj [ , indent := "" ] )


#### Return Value:
A JSON formatted string.

#### Parameter(s):
 * **obj** [in] - this argument has the same meaning as in _JSON.Dump()_
 * **indent** [in, opt] - this argument has the same meaning as in _JSON.Dump()_