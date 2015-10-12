// D import file generated from 'source/rbf/record.d'
module rbf.record;
pragma (msg, "========> Compiling module ", "rbf.record");
import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.array;
import std.regex;
import std.range;
import std.container.array;
import rbf.field;
import rbf.nameditems;
import rbf.recordfilter;
class Record : NamedItemsContainer!(Field, true)
{
	private 
	{
		bool _keep = true;
		public 
		{
			this(in string name, in string description);
			@property bool keep();
			@property void keep(bool keep);
			@property void value(string s);
			@property string value();
			@property string[] fieldNames();
			@property string[] fieldValues();
			@property string[] fieldRawValues();
			@property string[] fieldDescriptions();
			void opOpAssign(string op)(Field field) if (op == "~")
			{
				field.index = this.size;
				field.offset = this.length;
				super.opOpAssign!"~"(field);
				field.lowerBound = field.offset;
				field.upperBound = field.offset + field.length;
			}
			override string toString();
			string toXML();
			bool matchRecordFilter(RecordFilter filter);
		}
	}
}
import std.exception;
