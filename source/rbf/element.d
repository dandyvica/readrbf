module rbf.element;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.string;
import std.exception;
import std.algorithm;


/***********************************
 * This is the core data for representing atomic data in record-based files
 * Mainly, those data are not dependant on the context. They are always valid
 */
class Element(T,U,Context...) 
{
private:

	immutable T _name;					    /// name of the element
	T _description;	  	            		/// description of the element
	immutable U _length;		      		/// length (in bytes) of the element
	U _cellLength1; 						/// max(name,length)
	U _cellLength2; 						/// max(name,length,description)

public:

	// any additional contextual information if necessary
	static if (Context.length > 0) 
    {
		Context[0] context;
	}

	/**
 	 * create a new field object
	 *
	 * Params:
	 * 	name = name of the field
	 *  description = a generally long description of the field
	 *  length = length in bytes of the field. Should be >0
	 *
	 */
	this(in T name, in T description, in U length)
	// verify pre-conditions
	{
		// check arguments
		enforce(name != "", "field name should not be empty!");
		enforce(length > 0, "field length should be > 0");

		// just copy what is passed to constructor
		_name        = name;
		_description = description;
		_length      = length;

		// used to print out text data. Useful to compute this at build time and not
        // at run time
		_cellLength1 = max(_length, _name.length);
		_cellLength2 = max(_length, _description.length, _name.length);
	}

	// copy an element with all its data
	Element dup() pure immutable
    {
		auto copied = new Element!(T,U,Context)(_name, _description, _length);
		return copied;
	}

	/// read property for name attribute
	@property T name() { return _name; }

	/// read property for description attribute
	@property T description() { return _description; }

	/// write property for description attribute
	@property void description(in string newDesc) { _description = newDesc; }

	/// read property for field length
	@property U length() { return _length; }

	/// read property for cell length when creating ascii tables
	@property U cellLength1() { return _cellLength1; }
	@property void cellLength1(in U l1) { _cellLength1 = l1; }
	@property U cellLength2() { return _cellLength2; }
	@property void cellLength2(in U l2) { _cellLength2 = l2; }

	/**
	 * return a string of element attributes
	 */
	override string toString()
    {
		return("name=<%s>, description=<%s>, length=<%u>".format(name, description, length));
	}

}
///
unittest {
    writefln("\n========> testing %s", __FILE__);

    assertThrown(new Element!(string, ulong)("","First field", 5));
    assertThrown(new Element!(string, ulong)("FIELD1","First field", 0));

    auto element1 = new Element!(string, ulong)("FIELD1", "Field description", 15);
    assert(element1.name == "FIELD1");
    assert(element1.description == "Field description");
    assert(element1.length == 15);
    assert(element1.cellLength1 == 15);
    assert(element1.cellLength2 == 17);

    writefln("********> end test %s\n", __FILE__);
}
