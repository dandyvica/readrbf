// D import file generated from 'source/field.d'
module rbf.field;
import std.stdio;
import std.conv;
import std.string;
import std.regex;
enum FieldType 
{
	FLOAT,
	INTEGER,
	DATE,
	ALPHABETICAL,
	ALPHANUMERICAL,
}
class Field
{
	private 
	{
		FieldType _field_type;
		string _name;
		immutable string _description;
		immutable ulong _length;
		immutable string _type;
		string _raw_value;
		string _str_value;
		ulong _index;
		ulong _offset;
		float _float_value;
		uint _int_value;
		short _value_sign = 1;
		public 
		{
			this(in string name, in string description, in string type, in ulong length);
			Field dup();
			@property string name();
			@property void name(string name);
			@property string description();
			@property FieldType type();
			@property ulong length();
			@property string value();
			@property void value(string s);
			@property string rawvalue();
			@property ulong index();
			@property void index(ulong new_index);
			@property ulong offset();
			@property void offset(ulong new_offset);
			@property short sign();
			@property void sign(short new_sign);
			void convert();
			override string toString();
			bool isFilterMatched(in string operator, in string scalar);
			static string testFilter(in string operator);
		}
	}
}
import std.exception;
