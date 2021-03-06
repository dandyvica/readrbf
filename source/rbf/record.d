/**
 * Authors: dandyvica
 * Date: 03/04/2015
 * Version: 0.3
 */
module rbf.record;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.array;
import std.regex;
import std.range;
import std.container.array;
import std.ascii;

import rbf.errormsg;
import rbf.field;
import rbf.nameditems;
import rbf.recordfilter;
import rbf.log;
import rbf.builders.xmlcore;

struct RecordMeta 
{
	string name;				 /// record name
	string description;			 /// record description
	bool   skipRecord;	         /// do we skip this record?
	string[][] repeatingPattern; /// list of all fields which might be repeated within a record
	Record[] subRecord;          /// list of all records matching those repeated fields
    string ruler;                /// when using the text writer, length of the ruler for header vs. data
    ulong sourceLineNumber;      /// line number where this record is found
    bool  section;               /// we want to save this record name
    typeof(Field.length) declaredLength; /// if record tag has a length attribute
    string tableName;            /// table name supercedes record name when creating SQL tables based on record name
    
}

/***********************************
 * This record class represents a record as found in record-based files
 */
class Record : NamedItemsContainer!(Field, true, RecordMeta) 
{

public:
	/**
	 * creates a new record object
	 *
	 * Params:
	 *	name = name of the record
	 *  description = a generally long description of the record
	 *
	 * Examples:
	 * --------------
	 * auto record = new Record("FIELD1", "Field1 description");
	 * --------------
	 */
    this(in string name, in string description)
    {
        // name shouldn't be empty but description could be
        enforce(name != "", Log.build_msg(Message.MSG081));

        // pre-allocate array of fields by calling the container's ctor
        super(name);

        // fill container name/desc
        this.meta.name = name;
        this.meta.description = description;
    }

	/**
	 * creates a new record object
	 *
	 * Params:
	 *	attr = associative array having keys "name", "description" with corresponding values
	 *
	 * Examples:
	 * --------------
	 * auto record = new Record(["name":"FIELD1", "description":"Field1 description"]);
	 * --------------
	 */
    this(string[string] attr)
    {
        // name & description keys should exists
        enforce("name" in attr, Log.build_msg(Message.MSG082));
        enforce("description" in attr, Log.build_msg(Message.MSG083));

        this(attr["name"], attr["description"]);
    }

	/**
	 * sets record value from one string
	 *
	 * Params:
	 *	s = string to split according to all fields
	 *
	 * Examples:
	 * --------------
	 * record.value = "AAAAA0001000020DDDDDEEEEEFFFFFGGGGGHHHHHIIIIIJJJJJKKKKKLLLLLMMMMMNNNNN00010"
	 * --------------
	 */
	@property void value(TVALUE s) 
	{
		// add chars from string if s has not the same length as record length
		if (s.length < _length) 
        {
			s = s.leftJustify(_length);
		}
        /*
		else if (s.length > _length) 
        {
			s = s[0.._length];
		}*/

		// assign each field to it's corresponding slice of s
		this.each!(f => f.value = s[f.context.lowerBound..f.context.upperBound]);
	}

	/**
	 * value of a record is the concatenation of all field raw values
	 */
	@property string rawValue()
	{
		return fieldRawValues.join("");
	}
	@property string value()
	{
		return fieldValues.join("");
	}

	/**
	 * return the list of all field names contained in the record
	 */
	@property string[] fieldNames()
	{
		mixin(NamedItemsContainer!(Field,true).getMembersData("name"));
	}

	/**
	 * return the list of all field names contained in the record
	 */
	@property string[] fieldAlternateNames()
	{
		mixin(NamedItemsContainer!(Field,true).getMembersData("context.alternateName"));
	}

	/**
	 * return the list of all field values contained in the record
	 */
	@property auto fieldValues()
	{
		mixin(NamedItemsContainer!(Field,true).getMembersData("value"));
	}

	/**
	 * return the list of all field raw values contained in the record
	 */
	@property auto fieldRawValues()
	{
		mixin(NamedItemsContainer!(Field,true).getMembersData("rawValue"));
	}

	/**
	 * return the list of all field description contained in the record
	 */
	@property string[] fieldDescriptions()
	{
		mixin(NamedItemsContainer!(Field,true).getMembersData("description"));
	}

	/**
	 * concatenate field values for the fields having the same name
	 */
	@property TVALUE concat(in string name)
	{
        auto values = array(this[name].map!(f => f.value));
        return values.reduce!((a,b) => a ~ b);
	}

    /* table name property */
    /*
    @property auto tableName() { return meta.tableName; }
    @property void tableName(string tblName) { meta.tableName = tblName; }
    */

	/**
	 * find the field name having index i
	 */
	string findNameByIndex(in ulong i)
    {
		foreach (f; this) 
        {
			if (f.context.index == i) return f.name;
		}
		return "";
	}

	/**
	 * when deleting fields, we need to recalculate indexes
	 */
    void recalculateIndex()
    {
        auto i=0;
        this.each!(f => f.context.index = i++);
    }

	/**
	 * when a field is repeated inside a record, we cannot call it by name.
     * So we need to call it using its name and index (a.k.a alternateName)
	 */
    void buildAlternateNames()
    {
        foreach(f; this)
        {
            // for each field being repeated at least twice, build its "alternate" name 
            // which, by the way it's build, unique
            auto list = this[f.name];

            // only build alternate name for fields which are at least repeated twice
            if (list.length > 1)
            {
                auto i=1;
                foreach(f1; list)
                {
                    // build alternate name if not already specified in the layout file
                    if (f1.context.alternateName == f1.name)
                    {
                        f1.context.alternateName = "%s%d".format(f1.name, i++);
                    }
                }
            }
        }
    }


	/**
	 * when fields are repeated, we use a simple regex to identify that repetition
	 */
    void identifyRepeatedFields()
    {
        // build our string to search for: each field is replaced by
        // pattern <i> where i is the first field index
        // it allows to easily search using regex: ((<\d+>)+?)\1+
        // which means: find at least to successive tokens matching <i>
        // where i is a decimal digit
        string s;
        foreach(f; this) 
        {
            auto i = _map[f.name][0].context.index;
            s ~= "<%d>".format(i);
        }

        // real pattern matching here
        auto pattern = ctRegex!(r"((<\d+>)+?)\1+");
        auto match = matchAll(s, pattern);

        // we've matched here duplicated pattern
        foreach (m; match) 
        {
            // our result is a list of indexes liek "<2><5><7>...".
            // each number traces back to the field name
            auto result = matchAll(m[1], r"<(\d+)>");
            auto a = array(result.map!(r => findNameByIndex(to!ulong(r[1]))));
            meta.repeatingPattern ~= a;
        }

    }


    /**
     * try to match fields whose names are repeated
     */
    void findRepeatedFields(string[] fieldList)
    {
        auto indexOfFirstField = array(this[fieldList[0]].map!(f => f.context.index));
        immutable l = fieldList.length;

        foreach (i; indexOfFirstField)
        {
            if (i+l > size) break;

            // create new record
            // record name is based on field names
            auto recName = join(fieldList, ";");
            meta.subRecord ~= new Record(recName, "subRecord");

            auto a = this[i..i+l];
            if (array(this[i..i+l].map!(f => f.name)) == fieldList)
            {
                meta.subRecord[$-1] ~= a;
            }
        }

    }


	/**
	 * add a new Field object.
	 *
	 * Params:
	 *	field = field object to be added
	 * Examples:
	 * --------------
	 * auto record = new Record("FIELD1", "Field1 description");
	 * record ~ new Field("FIELD1", "Field1 description", "I", 10);
	 * --------------
	 *
	 */
	void opOpAssign(string op)(Field field) if (op == "~")
	{
		// set index & offset
		field.context.index      = this.size;
		field.context.offset     = this.length;

		// add element
		super.opOpAssign!"~"(field);

		// at this point, occurence is the length of map containing fields by name
		field.context.occurence  = this.size(field.name)-1;

		// lower/upper bounds calculation inside the record
		field.context.lowerBound = field.context.offset;
		field.context.upperBound = field.context.offset + field.length;
	}

	void opOpAssign(string op)(Field[] fieldList) if (op == "~")
	{
		fieldList.each!(f => super.opOpAssign!"~"(f));
	}

	/**
	 * print out Record properties with all fields and record data
	 */
	override string toString()
	{
		auto s = "\nname=<%s>, description=<%s>, length=<%u>, skip=<%s>\n".format(name, meta.description, length, meta.skipRecord);
		foreach (field; this)
		{
			s ~= field.toString();
			s ~= "\n";
		}
		return(s);
	}

	/**
	 * match a record against a set of boolean conditions to filter data
	 * returns True is all conditions are met
	 */
	bool matchRecordFilter(RecordFilter filter)
	{
		// now for each filter, just check it out
		foreach (RecordClause c; filter)
		{
			// field name not found: just return false
			if (c.fieldName !in this) 
            {
				return false;
			}

			// loop on all fields for this requested field
			bool condition = false;

			//writefln("number of fields %s is %d",c.fieldName, this[c.fieldName].length);
			foreach (Field field; this[c.fieldName]) 
            {
				// if one condition is false, then get out
				condition |= field.type.isFieldFilterMatched(field.value, c.operator, c.value);
			}

			if (!condition) return false;
		}

		// if we didn't return, condition is true
		return true;
	}

    /// build XML tag definition
    string asXML()
    {
        XmlAttribute[] attributes;

        // build attribute elements for mandatory attributes of <field> tag
        attributes ~= XmlAttribute("name", name);
        attributes ~= XmlAttribute("description", meta.description);

        // build XML main <record> tag
        auto tag = buildXmlTag("record", attributes, false);

        // add fields
        foreach (f; this)
        {
            tag ~= newline ~ "\t" ~ f.asXML;
        }

        // end tag gracefully
        tag ~= newline ~ buildXmlTag("record", [], true);

        return tag;
    }
}


import std.exception;
///
unittest {

	import rbf.fieldtype;

    writefln("\n========> testing %s", __FILE__);

	// check wrong arguments
	assertThrown(new Record("", "Rec description"));

	// main test
	auto rec = new Record("RECORD_A", "This is my main and top record");
	auto rec1 = new Record(["name":"RECORD_A", "description":"This is my main and top record"]);
	auto ft = new FieldType("A/N", "string");

	rec ~= new Field("FIELD1", "Desc1", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);
	rec ~= new Field("FIELD3", "Desc3", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);

	// test properties
	assert(rec.name == "RECORD_A");
	assert(rec.meta.description == "This is my main and top record");

	assert(rec1.name == "RECORD_A");
	assert(rec1.meta.description == "This is my main and top record");

    // test asXML
    assert(rec.asXML == `<record name="RECORD_A" description="This is my main and top record">
	<field name="FIELD1" description="Desc1" length="10" type="A/N"/>
	<field name="FIELD2" description="Desc2" length="10" type="A/N"/>
	<field name="FIELD3" description="Desc3" length="10" type="A/N"/>
	<field name="FIELD2" description="Desc2" length="10" type="A/N"/>
	<field name="FIELD2" description="Desc2" length="10" type="A/N"/>
</record>`);

	// set value
	auto s = "AAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEE";
	rec.value = s;
	assert(rec.value == s);

	// test fields
	assert(rec[0].name == "FIELD1");
	assert(rec[0].description == "Desc1");
	assert(rec[0].length == 10);
	assert(rec.fieldNames == ["FIELD1", "FIELD2", "FIELD3", "FIELD2", "FIELD2"]);
	assert(rec.fieldValues == ["AAAAAAAAAA", "BBBBBBBBBB", "CCCCCCCCCC", "DDDDDDDDDD", "EEEEEEEEEE"]);

	// succ
	/*assert(rec.succ(rec[2]).name == "FIELD2");
	assert(rec.succ(rec[4]) is null);
	assert(rec.pred(rec[2]).name == "FIELD2");
	assert(rec.pred(rec[0]) is null);*/

	// test for subrecords
	rec = new Record("RECORD_A", "This is my main and top record");
	rec ~= new Field("FIELD1", "Desc1", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);
	rec ~= new Field("FIELD3", "Desc3", ft, 10);
	rec ~= new Field("FIELD4", "Desc4", ft, 10);
	rec ~= new Field("FIELD5", "Desc5", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);
	rec ~= new Field("FIELD3", "Desc3", ft, 10);
	rec ~= new Field("FIELD4", "Desc4", ft, 10);
	rec ~= new Field("FIELD5", "Desc5", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);
	rec ~= new Field("FIELD3", "Desc3", ft, 10);
	rec ~= new Field("FIELD4", "Desc4", ft, 10);
	rec ~= new Field("FIELD5", "Desc5", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);
	rec ~= new Field("FIELD3", "Desc3", ft, 10);
	rec ~= new Field("FIELD4", "Desc4", ft, 10);
	rec ~= new Field("FIELD5", "Desc5", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);
	rec ~= new Field("FIELD3", "Desc3", ft, 10);
	rec ~= new Field("FIELD4", "Desc4", ft, 10);
	rec ~= new Field("FIELD5", "Desc5", ft, 10);
	rec ~= new Field("FIELD6", "Desc2", ft, 10);
	rec ~= new Field("FIELD6", "Desc2", ft, 10);
	rec ~= new Field("FIELD6", "Desc2", ft, 10);
	rec ~= new Field("FIELD2", "Desc2", ft, 10);
	rec ~= new Field("FIELD3", "Desc3", ft, 10);
	rec ~= new Field("FIELD4", "Desc4", ft, 10);
	rec.identifyRepeatedFields;

	assert(rec.meta.repeatingPattern == [["FIELD2", "FIELD3", "FIELD4", "FIELD5"],["FIELD6"]]);

	// f1 is Field[][]
	rec.findRepeatedFields(rec.meta.repeatingPattern[0]);
	assert(rec.meta.subRecord[0].names == ["FIELD2", "FIELD3", "FIELD4", "FIELD5"]);
	rec.findRepeatedFields(rec.meta.repeatingPattern[1]);
	assert(rec.meta.subRecord[5].names == ["FIELD6"]);

    writefln("********> end test %s\n", __FILE__);
}
