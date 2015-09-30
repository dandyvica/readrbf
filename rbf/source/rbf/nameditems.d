module rbf.nameditems;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.typecons;
import std.exception;

immutable uint PRE_ALLOC_SIZE = 30;

/***********************************
 * Generic container for field-like objects
 */
class NamedItemsContainer(T, bool allowDuplicates) {
protected:

	alias TNAME   = typeof(T.name);
	alias TVALUE  = typeof(T.value);
	alias TLENGTH = typeof(T.length);
	alias TLIST   = T[];
	alias TMAP	  = T[][TNAME];

	// useful type alias whether the container accepts duplcates or not
	static if (allowDuplicates) {
		alias TRETURN = TLIST;
		ref TRETURN _contextMap(T[][TNAME] map, TNAME name) { return map[name]; }
	}
	else {
		alias TRETURN = T;
		ref TRETURN _contextMap(T[][TNAME] map, TNAME name) { return map[name][0]; }
	}

	TLIST _list;				/// track all fields within a dynamic array
	TMAP _map;					/// and as several instance of the same field can exist,
											/// need to keep track of all instances

	TLENGTH _length;		/// current length of the container when adding elements

	string _name;				/// container name
	string _description;/// container descrption




public:

	struct Range {
		private TLIST items;

		ulong head = 0;
		ulong tail = 0;

		this(TLIST list) {
				items = list;
				head = 0;
				tail = list.length - 1;
		}

		@property bool empty() const { return items.length == head; }
		@property ref T front() { return items[head]; }
		@property ref T back() { return items[tail]; }
		@property Range save() { return this; }
		void popBack() {  tail--; }
		void popFront() {	head++;	}

		T opIndex(size_t i) { return items[i]; }
	}


	/**	Constructor taking an optional parameter

	Params:
	preAllocSize = preallocation of the inner array

	*/
	this(ushort preAllocSize=PRE_ALLOC_SIZE) { _list.reserve(preAllocSize); }

	/**	Constructor taking an input range

	Params:
	r = range

	*/
	this(Range)(Range r) {
		this();
		foreach (e; r) {
			this ~= e;
		}
	}




	//----------------------------------------------------------------------------
	// properties
	//----------------------------------------------------------------------------
	/// Get container number of elements
	@property ulong size() { return _list.length; }

	/// get length of all elements
	@property ulong length() { return _length; }

	// get/set name of the container
	@property string name() { return _name; }
	@property void name(string name ) { _name = name; }

	// get/set description of the container
	@property string description() { return _description; }
	@property void description(string description) { _description = description; }

	//----------------------------------------------------------------------------
	// useful mapper generation
	//----------------------------------------------------------------------------
	static string getMembersData(string memberName) {
		return "return array(_list.map!(e => e." ~ memberName ~ "));";
	}

	/// Return all elements names
	TNAME[] names() { mixin(getMembersData("name")); }

	//----------------------------------------------------------------------------
	// add methods
	//----------------------------------------------------------------------------
	/// append a new element
	void opOpAssign(string op)(T element) if (op == "~") {
		_list ~= element;

		// if no duplicates is allowed, need to test it
		static if (!allowDuplicates) {
			assert(element.name !in _map,
				"error: element name %s already in container".format(element.name));
		}

		// add element
		_map[element.name] ~= element;

		// added one element, so length is greater
		_length += element.length;
	}

	//----------------------------------------------------------------------------
	// index methods
	//----------------------------------------------------------------------------
	/**
	 * [] operator to retrieve i-th element
	 *
	 * Params:
	 *	i = index of the i-th element to retrieve

	 Returns:

	 An element of type T

	 */
	T opIndex(size_t i) {
		assert(0 <= i && i < _list.length, "index %d is out of bounds for _list[]".format(i));
		return _list[i];
	}

	/**
	* [] operator to retrieve field object whose name is passed as an argument
	*
	* Params:
	* name = name of the element to retrieve

	 Returns:
	 An array of elements of type T
	 */
	ref TRETURN opIndex(TNAME name) {
		assert(name in this, "element %s is not found in container".format(name));
		return _contextMap(_map, name);
	}

	/**

	Slicing operating

	Params:
	i = lower index
	j = upper index

	Returns:
	An array of elements of type T

	*/
	T[] opSlice(size_t i, size_t j) { return _list[i..j]; }

	/// Return a range on the container
	Range opSlice() {
		return Range(_list);
	}

	/**
		 * get the i-th field whose is passed as argument in case of duplicate
		 * field names (starting from 0)

		 Returns:
		 An array of elements of type T

	*/
	T get(TNAME name, ushort index = 0)
  {
		assert(name in this, "element %s is not found in record %s".format(name));
		assert(0 <= index && index < _map[name].length, "element %s, index %d is out of bounds".format(name,index));

		static if (!allowDuplicates) {
			assert(index == 0, "error: cannot call get method with index %d without allowing duplcated");
		}

		return _map[name][index];
	}

	/**
	 * Get the value of element

	 Params:
 	 name = name of the element to retrieve

 	 Returns:
 	 value of the first element found

	 */
	@property TVALUE opDispatch(TNAME name)()
	{
		return _map[name][0].value;
	}

	/**
	 * to match an element more easily
	 */
	TVALUE opDispatch(TNAME name)(ushort index) if (allowDuplicates)
	{
		//enforce(0 <= index && index < _fieldMap[fieldName].length, "field %s, index %d is out of bounds".format(fieldName,index));
		return _map[name][index].value;
	}

  //----------------------------------------------------------------------------
	// remove methods
	//----------------------------------------------------------------------------

	/** remove all elements matching name (as the same name may appear several times)

	Params:
	name = name of the elements to remove

	*/
	void remove(TNAME name) {
		_list = _list.remove!(f => f.name == name);
		// remove corresponding key
		_map.remove(name);
	}

	/// remove all elements in the _list
	void remove(TNAME[] name) { name.each!(e => this.remove(e)); }

	/// remove all elements not in the _list
	void keepOnly(TNAME[] name) {
		_list = array(_list.filter!(e => name.canFind(e.name)));
		auto keys = _map.keys.filter!(e => !name.canFind(e));
		keys.each!(e => _map.remove(e));
	}

	//----------------------------------------------------------------------------
	// reduce methods
	//----------------------------------------------------------------------------
	/// Returns the sum of elements converted to type U
	U sum(U)(TNAME name) {
		return _list.filter!(e => e.name == name).map!(e => to!U(e.value)).sum();
	}

	/// get the maximum of all elements converted to type U
	U max(U)(TNAME name) {
		auto values = _list.filter!(e => e.name == name).map!(e => to!U(e.value));
		return values.reduce!(std.algorithm.comparison.max);
	}

	/// get the minimum of all elements converted to type U
	U min(U)(TNAME name) {
		auto values = _list.filter!(e => e.name == name).map!(e => to!U(e.value));
		return values.reduce!(std.algorithm.comparison.min);
	}

	//----------------------------------------------------------------------------
	// "iterator" methods
	//----------------------------------------------------------------------------
	// foreach loop on sorted items by name
	int sorted(int delegate(ref TRETURN) dg)
	{
		int result = 0;

		foreach (TNAME name; sort(_map.keys)) {
				result = dg(_contextMap(_map, name));
				if (result)
					break;
		}
		return result;
	}

	//----------------------------------------------------------------------------
	// belonging methods
	//----------------------------------------------------------------------------
	TLIST* opBinaryRight(string op)(TNAME name)	if (op == "in")
	{
		return (name in _map);
	}

	//----------------------------------------------------------------------------
	// misc. methods
	//----------------------------------------------------------------------------
	/// count number of elements having the same name
	auto count(TNAME name) { return _list.count!("a.name == b")(name); }

	/// test if all elements match names
	bool opEquals(TNAME[] list)
	{
		return names == list;
	}

	//----------------------------------------------------------------------------
	// private methods
	//----------------------------------------------------------------------------


}
///
unittest {

	import rbf.field;

	auto c = new NamedItemsContainer!(Field,true)();
	c ~= new Field("FIELD1", "value1", "A/N", 10);
	c ~= new Field("FIELD2", "value2", "A/N", 30);
	c ~= new Field("FIELD2", "value2", "A/N", 30);
	c ~= new Field("FIELD3", "value3", "N", 20);
	c ~= new Field("FIELD3", "value3", "N", 20);
	c ~= new Field("FIELD3", "value3", "N", 20);
	c ~= new Field("FIELD4", "value4", "A/N", 20);

	auto i=1;
	foreach (f; c) {
		f.value = to!string(i++*10);
	}

	// properties
	assert(c.size == 7);
	assert(c.length == 150);
	assert(c.names == ["FIELD1","FIELD2","FIELD2","FIELD3","FIELD3","FIELD3","FIELD4"]);

	// opEquals
	assert(c == ["FIELD1","FIELD2","FIELD2","FIELD3","FIELD3","FIELD3","FIELD4"]);

	// opindex
	assert(c[0] == tuple("FIELD1","value1","A/N",10UL));
	assert(c["FIELD3"].length == 3);
	assert(c["FIELD3"][1].value!int == 50);
	assert(c[2..4][1] == tuple("FIELD3", "value3", "N", 20UL));

	// get
	assert(c.get("FIELD3") == tuple("FIELD3", "value3", "N", 20UL));

	// dispatch
	assert(c.FIELD3 == "40");
	assert(c.FIELD3(1) == "50");

	// arithmetic
	assert(c.sum!int("FIELD3") == 150);
	assert(c.min!int("FIELD3") == 40);
	assert(c.max!int("FIELD3") == 60);

	// in
	assert("FIELD4" in c);
	assert("FIELD10" !in c);

	// misc
	assert(c.count("FIELD3") == 3);

	// range test
	static assert(isBidirectionalRange!(typeof(c[])));
	c[].each!(e => assert(e.name.startsWith("FIELD")));
	auto r = array(c[].take(1));
	assert(r[0].name == "FIELD1");

	// build a new container based on range
	auto a = c[].filter!(e => e.name == "FIELD3");
	auto e = new NamedItemsContainer!(Field,true)(a);
	assert(e.size == 3);


	// do not accept duplicates
	auto d = new NamedItemsContainer!(Field,false)();
	d ~= new Field("FIELD2", "value2", "A/N", 10);
	d ~= new Field("FIELD1", "value1", "A/N", 30);
	//assertThrown(d ~= new Field("FIELD2", "value2", "A/N", 30));
	d ~= new Field("FIELD4", "value4", "N", 20);
	d ~= new Field("FIELD3", "value3", "A/N", 20);

	i=1;
	foreach (f; d) {
		f.value = to!string(i++*10);
	}

	// properties
	assert(d.size == 4);
	assert(d.length == 80);
	assert(d.names == ["FIELD2","FIELD1","FIELD4","FIELD3"]);

	// opEquals
	assert(d == ["FIELD2","FIELD1","FIELD4","FIELD3"]);

	// opindex
	assert(d[0] == tuple("FIELD2", "value2", "A/N", 10UL));
	assert(d["FIELD3"] == tuple("FIELD3", "value3", "A/N", 20UL));
	assert(d["FIELD3"].value!int == 40);
	assert(d[1..3][1] == tuple("FIELD4", "value4", "N", 20UL));

	// get
	assert(d.get("FIELD3") == tuple("FIELD3", "value3", "A/N", 20UL));

	// dispatch
	assert(d.FIELD3 == "40");
	assert(!__traits(compiles, d.FIELD3(1) == "50"));

	// belong to
	assert("FIELD3" in d);

	// test sorted foreach
	string[] names;
	foreach (f; &d.sorted) {
		names ~= f.name;
	}
	assert(names == ["FIELD1","FIELD2","FIELD3","FIELD4"]);

}