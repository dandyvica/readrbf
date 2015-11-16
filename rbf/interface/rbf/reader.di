// D import file generated from 'source/rbf/reader.d'
module rbf.reader;
pragma (msg, "========> Compiling module ", "rbf.reader");
import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.exception;
import std.regex;
import std.range;
import std.algorithm;
import rbf.errormsg;
import rbf.field;
import rbf.record;
import rbf.layout;
alias STRING_MAPPER = void function(Record);
class Reader
{
	private 
	{
		immutable string _rbFile;
		Layout _layout;
		MapperFunc _recordIdentifier;
		Regex!char _ignoreRegex;
		Regex!char _lineRegex;
		STRING_MAPPER _mapper;
		ulong _nbLinesRead;
		ulong _currentLineNumber;
		ulong _inputFileSize;
		ulong _guessedRecordNumber;
		bool _checkPattern;
		public 
		{
			this(string rbFile, Layout layout, MapperFunc recIndentifier = null);
			@property void ignoreRegexPattern(string pattern);
			@property void lineRegexPattern(string pattern);
			@property ulong nbRecords();
			@property void recordTransformer(STRING_MAPPER func);
			@property Layout layout();
			@property ulong nbLinesRead();
			@property ulong inputFileSize();
			@property void checkPattern(bool check);
			Record _getRecordFromLine(char[] lineReadFromFile);
			struct Range
			{
				private 
				{
					File _fh;
					ulong _nbChars = (ulong).max;
					char[] _buffer;
					Reader _outerThis;
					Record rec;
					public 
					{
						this(string fileName, Reader outer);
						@property bool empty();
						@property ref Record front();
						void popFront();
					}
				}
			}
			Range opSlice();
		}
	}
}
