// D import file generated from 'source/rbf/fieldtype.d'
module rbf.fieldtype;
pragma (msg, "========> Compiling module ", "rbf.fieldtype");
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;
static string overpunch(string s)
{
	static string posTable = makeTrans("{ABCDEFGHI}", "01234567890");
	static string negTable = makeTrans("JKLMNOPQR", "123456789");
	string trans = s;
	if (s.indexOfAny("{ABCDEFGHI}") != -1)
	{
		trans = translate(s, posTable);
	}
	else
		if (s.indexOfAny("JKLMNOPQR") != -1)
		{
			trans = "-" ~ translate(s, negTable);
		}
	return trans;
}
alias CmpFunc = bool delegate(string, string, string);
alias Conv = string function(string);
enum AtomicType 
{
	decimal,
	integer,
	date,
	string,
}
struct FieldTypeMeta
{
	string name;
	AtomicType type;
	string stringType;
	string pattern;
	string format;
	bool checkPattern;
	string fmtPattern;
	Conv preConv;
	CmpFunc filterTestCallback;
}
class FieldType
{
	public 
	{
		FieldTypeMeta meta;
		this(string nickName, string declaredType)
		{
			with (meta)
			{
				stringType = declaredType;
				type = to!AtomicType(stringType);
				name = nickName;
				final switch (type)
				{
					case AtomicType.decimal:
					{
						filterTestCallback = &matchFilter!float;
						fmtPattern = "%f";
						break;
					}
					case AtomicType.integer:
					{
						filterTestCallback = &matchFilter!long;
						fmtPattern = "%d";
						break;
					}
					case AtomicType.date:
					{
						filterTestCallback = &matchFilter!string;
						fmtPattern = "%s";
						break;
					}
					case AtomicType.string:
					{
						filterTestCallback = &matchFilter!string;
						fmtPattern = "%s";
						break;
					}
				}
			}
		}
		@property bool isNumeric()
		{
			return meta.type == AtomicType.decimal || meta.type == AtomicType.integer;
		}
		bool isFieldFilterMatched(string lvalue, string op, string rvalue)
		{
			return meta.filterTestCallback(lvalue, op, rvalue);
		}
		static string testFilter(T)(string op)
		{
			return "condition = (to!T(lvalue)" ~ op ~ "to!T(rvalue));";
		}
		bool matchFilter(T)(string lvalue, string operator, string rvalue)
		{
			bool condition;
			try
			{
				switch (operator)
				{
					case "=":
					{
					}
					case "==":
					{
						mixin(testFilter!T("=="));
						break;
					}
					case "!=":
					{
						mixin(testFilter!T("!="));
						break;
					}
					case "<":
					{
						mixin(testFilter!T("<"));
						break;
					}
					case ">":
					{
						mixin(testFilter!T(">"));
						break;
						static if (is(T == string))
						{
							case "~":
							{
								condition = !matchAll(lvalue, regex(rvalue)).empty;
								break;
							}
							case "!~":
							{
								condition = matchAll(lvalue, regex(rvalue)).empty;
								break;
							}
						}

					}
					default:
					{
						throw new Exception("error: operator %s not supported".format(operator));
					}
				}
			}
			catch(ConvException e)
			{
				stderr.writeln("error: converting value %s %s %s to type %s".format(lvalue, operator, rvalue, T.stringof));
			}
			return condition;
		}
	}
}
