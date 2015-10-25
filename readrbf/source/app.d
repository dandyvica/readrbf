import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.algorithm;
import std.datetime;
import std.range;
import std.conv;
import std.path;

import rbf.field;
import rbf.record;
import rbf.recordfilter;
import rbf.layout;
import rbf.reader;
import rbf.writers.writer;
import rbf.config;

import args;

int main(string[] argv)
{
	// number of records read
	auto nbReadRecords = 0;
	auto nbWrittenRecords = 0;


	string[] conditions;

	// need to known how much time spent
	auto starttime = Clock.currTime();

	try {

		// read XML properties from rbf.xml file
		auto settings = new Setting();

		// manage arguments passed from the command line
		//writeln(argv);
		auto opts = new CommandLineOption(argv);

		// check output formats
		if (opts.outputFormat !in settings.outputDir) {
			throw new Exception(
				"error: output format should be in the following list: %s".
						format(settings.outputDir.names));
		}

		// define new layout corresponding to the requested layout
		auto layout = new Layout(settings.layoutDir[opts.inputLayout].file);

		// syntax validation requested
		if (opts.bCheckLayout) {
			layout.validate;
		}

		// need to get rid of some records?
		if (opts.isFieldFilterFileSet) {
			// only keep specified fields
			layout.keepOnly(opts.filteredFields, "\n");
		}
		if (opts.isFieldFilterSet) {
			// only keep specified fields
			layout.keepOnly(opts.filteredFields, ";");
		}

		// create new reader according to what is passed in the command
		// line and the configuration found in JSON properties file
		auto reader = new Reader(opts.inputFileName, layout);

		// grep lines?
		if (opts.lineFilter != "") {
			reader.lineRegexPattern = opts.lineFilter;
		}

		// do we want to always get rid of some fields for all records?
		if (layout.meta.skipField != []) {
			stderr.writefln("info: skipping fields %s", layout.meta.skipField);
		}
		if (layout.meta.ignoreLinePattern != "") {
			stderr.writefln("info: skipping line pattern = %s", layout.meta.ignoreLinePattern);
		}

		// create new writer to generate outputFileName matching the outputFormat
		Writer writer;
		auto outputFileName = buildNormalizedPath(
				settings.outputDir[opts.outputFormat].outputDir,
				opts.outputFileName
		);

		auto output = (opts.stdOutput) ? "" :outputFileName;
		writer = writerFactory(output, opts.outputFormat, layout);

		// set writer features read in config
		writer.outputFeature = settings.outputDir[opts.outputFormat];

		// if verbose option is requested, print out what's possible
		if (opts.bVerbose) {
			opts.printOptions;
		}

		// now loop for each record in the file
		foreach (rec; reader)
		{
			// if samples is set, break if record count is reached
			if (opts.samples != 0 && nbReadRecords >= opts.samples) break;

			// record read is increasing
			nbReadRecords++;

			// do we filter out records?
			if (opts.isRecordFilterFileSet || opts.isRecordFilterSet) {
				if (!rec.matchRecordFilter(opts.filteredRecords))
					continue;
			}

			// don't want to write? Just loop
			if (opts.bJustRead) continue;

			// use our writer to generate the file
			writer.write(rec);
			nbWrittenRecords++;
		}

		// explicitly call close to finish creating file (specially for Excel files)
		writer.close();

		// print out some stats
		auto elapsedtime = Clock.currTime() - starttime;
		stderr.writefln("\nLines: %d read, records: %d read, %d written\nElapsed time = %s",
			reader.nbLinesRead, nbReadRecords, nbWrittenRecords, elapsedtime);
		if (!opts.bJustRead)
				stderr.writefln("Created file %s, size = %d bytes",
								opts.outputFileName, getSize(opts.outputFileName));
	}
	catch (Exception e) {
		stderr.writeln(e.msg);
		return 1;
	}

	// return code to OS
	return 0;

}
