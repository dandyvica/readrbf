

**NAME**

readrbf - read a record-based file and convert it to a known format

**SYNOPSIS**

readrbf -i file - l layout [-o format] [-f file] [-c] [-O] [--br] [--ff] [--fl] [--fr] [-r file] [-s n] [-v] [-p] [-h] [--dup] [--of file] [--conf configfile] [--postsql sqlfile] [--presql sqlfile] [--ua]

**DESCRIPTION**
       
       This program is aimed at reading a record-based file and converting it to a human-readable format.  It reads its settings from the rbf.xml configu‐
       ration file found in the following locations: 
       
       - from the RBF_CONF environment variable
       - from the current directory 
       - or lastly from the ~/.rbf directory (linux) or the %%APPDATA%%\local\rbf directory (Windows).

**OPTIONS**

       -b : Benchmark: don't write output file but just read input file.

       --buildxml file: build rbf XML file from input file.

       --br : Break records: try to break record into individual repeated sub-records for better text presentation.

       --check : check whether field patterns are matched.

       --conf file: use the file given as argument instead of rbf.xml file.

       --convert : convert input layout to the format given by --format (ref. to --format)

       --dup : just print records and fields which are repeated within each record.

       -f file : Full path and name of a file to filter fields.

       --ff records/fields list : filter fields: only write selected records/fields.

       --fl pattern : Filter lines: only select lines matching the regex pattern.  NB if "--ff" is also specified, this --fl comes first.

       --format [html, xml, include, csv, temp]: gives the output format of the conversion of the XML layout file

       --fr condition : Filter records: only include records matching condition.

       -i file : Full path and name of the file to be read and converted.

       -l layout : Name of the input file layout. This name is found is the configuration file rbf.xml.

       --layouts: list all possible layouts found in the configuration file.

       -o format : Name of the output file format. Possible values are: %s. 
	Defaulted to txt if not specified (ident means that the output file format is the same than the input one). Here is an explanation
    of the possible formats:

        box:      a text file, one description header and one record per line, separated by ascii box characters
        csv:      a text file, one record per line, fields separated by the ; character (this separator is configurable in the XML configuration file)
        html:     a HTML file, one HTML table per record, and either one field per line (default) or one field per column
        ident:    same file format than the input file, but matching input parameters
        sqlite3:  a sqlite3 database file, one table per record
        postgres: a postgres database instance, one table per record
        tag:      a text file, one record per line, all fields tagged with the following format: field_name = "field_value"
        excel1:   a Microsoft Excel (2007 and above) workbook file format, one record per line, one field per cell (one worksheet)
        excel2:   a Microsoft Excel (2007 and above) workbook file format, one record per worksheet, one field per column for the corresponding worksheet
        xml:      an XML file with its corresponding  XSD schema, fields XML-tagged like <field_name>field_value</field_name>

       --of filename : Convert file to given file name.

       --out : Write to standard output only.

       -p : Print out progress status.

       --presql sqlfile : execute SQL statements from the given file after creating of all tables and before inserting data.

       --postsql sqlfile : execute SQL statements from the given file after inserting data.

       -r file : Full path and name of a file to filter records.

       --raw : use raw values instead of blank stripped values

       -s n : Only convert the n-first records.

       --stats: print out detailed statistics on file at the end of conversion.

       --strict: if a record if not found is the layout, exit the program. By default, it just logs a warning in the log

       --template: name and path of the template file to use when using temp output format.

       --trigger recordName: when using the template option, trigger file output when matching record name is met.

       --ua : use alternate field names instead of regular field names. 

       -v : Verbose: print out options.

       --validate : Validate layout structure.

**ENVIRONMENT VARIABLES**
        
    The RBF_CONF environment variable, if set, gives the name and path of the configuration file to use. Otherwise,
    default values are used.
