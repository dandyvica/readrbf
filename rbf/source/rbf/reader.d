/**
 * Authors: Alain Viguier
 * Date: 03/04/2015
 * Version: 0.1
 */
module rbf.reader;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.exception;
import std.regex;


import rbf.field;
import rbf.record;
import rbf.layout;

// definition of useful aliases
alias GET_RECORD_FUNCTION = string delegate(string);   /// alias for a function pointer which identifies a record
alias STRING_MAPPER = void function(Record);           /// alias to a delegate used to change field values


/***********************************
 * record-base file reader used to loop on each record
 */
class Reader {

private:

	/// filename to read
	immutable string _rbFile;

	/// file handle when opened
	//File _fh;

	/// list of all records read from XML definition file
	Layout _layout;

	/// this function will identify a record name from the line read
	GET_RECORD_FUNCTION _recordIdentifier;

	/// regex ignore pattern: don't read those lines matching this regex
	Regex!char _ignoreRegex;

	/// mapper function
	STRING_MAPPER _mapper;

	/// size read
	ulong _currentReadSize;

	/// input file size
	ulong _inputFileSize;


public:
	/**
	 * creates a new Reader object for rb files
	 *
	 * Params:
	 *  rbFile = path/name of the file to read
	 *  layout = layout object
	 *  recIndentifier = function used to map each record
	 */
	this(string rbFile, Layout layout, GET_RECORD_FUNCTION recIndentifier)
	{
		// check arguments
		enforce(exists(rbFile), "error: file %s not found".format(rbFile));

		// save file name and opens file for reading
		_rbFile = rbFile;

		// open file for reading
		//_fh = File(rbFile, "r");

		// build all records but defining a new format
		_layout = layout;

		// save record identifier lambda
		_recordIdentifier = recIndentifier;

		// get file size
		_inputFileSize = getSize(rbFile);
	}

	/**
	 * register a regex pattern to ignore line matching this pattern
	 *
	 * Examples:
	 * -----------------------------
	 * reader.ignoreRegexPattern("^#")		// ignore lines starting with #
	 * -----------------------------
	 */
	@property void ignoreRegexPattern(Regex!char pattern) { _ignoreRegex = pattern; }

	/**
	 * register a callback function which will be called for each fetched record
	 */
	@property void recordTransformer(STRING_MAPPER func) { _mapper = func; }

	@property Layout layout() { return _layout; }

	@property ulong currentReadSize() { return _currentReadSize; }

	@property ulong inputFileSize() { return _inputFileSize; }

	/**
	 * used to loop on foreach on all records of the file
	 *
	 * Examples:
	 * -----------------------------
	 * foreach (Record rec; rbfile)
	 * 	{ writeln(rec); }
	 * -----------------------------
	 */
	int opApply(int delegate(ref Record) dg)
	{
		int result = 0;
		string recordName;

		// read each line of the ascii file
		//foreach (string line_read; lines(File(_rbFile, "r")))
		foreach (string line_read; lines(File(_rbFile)))
		{
			// one more line read
			_currentReadSize += line_read.length;

			// get rid of \n
			auto line = chomp(line_read);

			// if line is matching the ignore pattern, just loop
			if (!_ignoreRegex.empty && matchFirst(line, _ignoreRegex)) {
				continue;
			}

			// try to fetch corresponding record name for line we've read
			recordName = _recordIdentifier(line);

			// record not found ? So loop
			if (recordName !in _layout) {
				writefln("error: record name <%s> not found!!", recordName);
				continue;
			}

			// do we keep this record?
			if (!_layout[recordName].keep) continue;

			// now we can safely save our values
			// set record value (and fields)
			_layout[recordName].value = line;

			// is a mapper registered? so we need to call it
			if (_mapper)
				_mapper(_layout[recordName]);

			// this is conventional way of opApply()
			result = dg(_layout[recordName]);
			if (result)
				break;
		}
		return result;
	}

}

unittest {

	auto layout = new Layout("./test/world_data.xml");
	auto rbf = new Reader("./test/world.data", layout, (line => line[0..4]));
	rbf.ignoreRegexPattern = regex("^#");

	foreach (rec; rbf) {
		assert("NAME" in rec);
	}


}