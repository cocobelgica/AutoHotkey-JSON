# JSON and JSON2
### [JSON](http://json.org/) module for [AutoHotkey](http://ahkscript.org/)
_ Tested on AutoHotkey **v1.1.15.04** and **v2.0-a049** _

License: [WTFPL](www.wtfpl.net)
- - -
# JSON (class)
### There are multiple version(s) available (as branches) in this repo to provide support for different AutoHotkey builds. The _master_ branch is meant to be compatible with both AHK _v1.1_ and _v2.0-a_ (haven't updated yet), while branches _v1.1_ and _v2_ support the specific AutoHotkey version as indicated by their branch name.
- - -
### **.parse()** - deserialize _src_ (a JSON formatted string) to an AutoHotkey object
### Synax:    `` obj := JSON.parse( src [, jsonize := false ] ) ``
### Return Value:
An AutoHotkey object

### Parameter(s):
 * **src** [in] - JSON formatted string
 * **jsonize** [in, opt] - if _true_, **_objects_( ``{}`` )** and **_arrays_( ``[]`` )** are wrapped as **JSON.object** and **JSON.array** instances respectively. This is to compensate for AutoHotkey's non-distinction between these types and other AHK object type quirks. _e.g.: In AutoHotkey, object keys are enumerated in alphabetical order not in the sequence in which they are created_
- - -
### **.stringify()** - serialize _obj_ to a JSON formatted string 
### Syntax:    `` str := JSON.stringify( obj, [, indent := "" ] ) ``
### Return Value:
A JSON formatted string

### Parameter(s):
 * **obj** [in] - AutoHotkey object. Non-standard AHK objects like _COM_, _Func_, _FileObject_, _RegExMatchObject_ are not supported.
 * **indent** [in, opt] -if indent is a non-negative integer or string, then JSON array elements and object members will be pretty-printed with that indent level. Blank( ``""`` ) (the default) or ``0`` selects the most compact representation. Using a positive integer indent indents that many spaces per level. If indent is a string (such as ``"`t"``), that string is used to indent each level. _(I'm lazy, wording taken from Python docs)_
- - -
 
# JSON2 (function)
### Similar to the JSON class above just implemented as a function. Unlike JSON (class) above, this implementation provides _reading from_ and _writing to_ file. Works on both AutoHotkey _v1.1_ and _v2.0_
 - - -
### **Deserialize** - deserialize _src_ (a JSON formatted string) to an AutoHotkey object
### Syntax:    `` obj := Json2( src [, object_base := "", array_base := "" ]) ``
### Parameter(s):
 * **src** [in] - JSON formatted string or path to the file containing JSON formatted string.
 * **object_base** [in, opt] - an object to use as prototype for objects( ``{}`` ) created during parsing.
 * **array_base** [in, opt] - an object to use as prototype for arrays( ``[]`` ) created during parsing.
- - -
### **Serialize** -  Serialize _obj_ to a JSON formatted string OR dumps _obj_ to the file specified in _out_
### Syntax:    `` str := Json2( obj [, out := "", indent := "" ]) ``
### Return Value:
A JSON formatted string. If _out_ is specified, the number of bytes written is returned.

### Parameter(s):
 * **obj** [in] - this argument has the same meaning as in _JSON.stringify()_
 * **out** [in, opt] - path to the file to write to. If specified, the function returns the number of bytes written.
 * **indent** [in, opt] - this argument has the same meaning as in _JSON.stringify()_