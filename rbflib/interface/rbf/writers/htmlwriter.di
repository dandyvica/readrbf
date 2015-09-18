// D import file generated from 'source/writers/htmlwriter.d'
module rbf.writers.htmlwriter;
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import std.array;
import std.functional;
import rbf.field;
import rbf.record;
import rbf.writers.writer;
immutable formatter = "format(\"<%s>%s</%s>\",a,b,a)";
alias htmlRowBuilder = binaryFun!formatter;
class HTMLWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
	override void close();
	private string _buildHTMLDataRow(Record rec);
}