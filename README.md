# JSON and Jxon

#### [JSON](http://json.org/) module for [AutoHotkey](http://ahkscript.org/)

_Requires AutoHotkey **v1.1.17.00+** OR **2.0-a057+**_

License: [WTFPL](http://wtfpl.net/)

- - -

## JSON.ahk (class)
There are multiple version(s) available (as branches) in this repo to provide support for different AutoHotkey builds. The _master_ branch is for `v1.1` _(except for Json2.ahk which is version independent)_ while the _v2_ branch is for `AHK v2.0-a`.

- - -

#### .parse()
Deserialize _src_ (a JSON formatted string) to an AutoHotkey object

#### Syntax:

    obj := JSON.parse( ByRef src [, jsonize := false ] )


#### Return Value:
An AutoHotkey object

#### Parameter(s):
 * **src** [in, ByRef] - JSON formatted string
 * **jsonize** [in, opt] - if _true_, **_objects_( ``{}`` )** and **_arrays_( ``[]`` )** are wrapped as **JSON.object** and **JSON.array** instances respectively. This is to compensate for AutoHotkey's non-distinction between these types and other AHK object type quirks. _e.g.: In AutoHotkey, object keys are enumerated in alphabetical order not in the sequence in which they are created_

- - -

#### .stringify()
serialize _obj_ to a JSON formatted string 

#### Syntax:

    str := JSON.stringify( obj, [, indent := "" ] )


#### Return Value:
A JSON formatted string

#### Parameter(s):
 * **obj** [in] - AutoHotkey object. Non-standard AHK objects like _COM_, _Func_, _FileObject_, _RegExMatchObject_ are not supported.
 * **indent** [in, opt] -if indent is a non-negative integer or string, then JSON array elements and object members will be pretty-printed with that indent level. Blank( ``""`` ) (the default) or ``0`` selects the most compact representation. Using a positive integer indent indents that many spaces per level. If indent is a string (such as ``"`t"``), that string is used to indent each level. _(I'm lazy, wording taken from Python docs)_

- - -
 
## Jxon.ahk (function)
Similar to the JSON class above just implemented as a function. ~~Unlike JSON (class) above, this implementation provides _reading from_ and _writing to_ file~~(Removed `Jxon_Read` and `Jxon_Write`). Works on both AutoHotkey _v1.1_ and _v2.0_

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
 * **obj** [in] - this argument has the same meaning as in _JSON.stringify()_
 * **indent** [in, opt] - this argument has the same meaning as in _JSON.stringify()_