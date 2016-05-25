module rbf.errormsg;

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.algorithm;
import std.range;
import std.datetime;
import std.process;

// list of all error messages found in code
// some are sent to log file, some to stdout or stderr
immutable MSG001 = "error: element name <%s> is not in record/container <%s>";
immutable MSG002 = "line# <%d>, record <%s>, field <%s>, value <%s> is not matching expected pattern <%s>";
immutable MSG003 = "name=<%s>, description=<%s>, length=<%u>, type=<%s>, lower/upperBound=<%u:%u>, rawValue=<%s>, value=<%s>, offset=<%s>, index=<%s>";
immutable MSG004 = "error: settings file <%s> not found";
immutable MSG005 = "error: element %s, index %d is out of bounds";
immutable MSG006 = "error: cannot call get method with index %d without allowing duplicated";
immutable MSG007 = "error: lower index %d is out of bounds, upper bound = %d";
immutable MSG008 = "error: upper index %d is out of bounds, upper bound = %d";
immutable MSG009 = "error: lower index %d is higher than upper index %d";
immutable MSG010 = "error: unable to create field, wrong number of csv data (%d, expected %d)";
immutable MSG011 = "info: creating Excel/ZIP file <%s>";
immutable MSG012 = "info: creating Excel internal directory structure";
immutable MSG013 = "info: created file %s, size = %d bytes";
immutable MSG014 = "info: lines: %d read, records: %d read, %d written";
immutable MSG015 = "elapsed time = %s";
immutable MSG016 = "opening input file <%s>, size = %d bytes";
immutable MSG017 = "read rate = %.0f records per second";
immutable MSG018 = "line# <%d>, record name <%s> not found, %d first bytes of the line=<%s>";
immutable MSG019 = "creating output file <%s>";
immutable MSG020 = "conversion error, line# <%d>, record <%s>, field <%s> value <%s> to type <%s>, resetting to NULL";
immutable MSG021 = "creating tables, SQL pool size = %d";
immutable MSG022 = "%d table(s) created";
immutable MSG023 = "layout <%s> read, %d record(s) created";
immutable MSG024 = "record filter error: field <%s> is not found in layout";
immutable MSG025 = "creating table (for record) <%s>";
immutable MSG026 = "field filter requested, layout has now <%d> records";
immutable MSG027 = "====> configuration file is <%s>";
immutable MSG028 = "built SQL statement: <%s>";
immutable MSG029 = "error: sqlite3_prepare_v2() API error, SQL error %d, statement=<%s>, error msg <%s>";
immutable MSG030 = "error: operator <%s> not supported. Admissible operator list is %s";
immutable MSG031 = "error: converting value %s to type %s";
immutable MSG032 = "error: element name %s already in container";
immutable MSG033 = "error: index %d is out of bounds for _list[]";
immutable MSG034 = "record %s is not matching declared length (%d instead of %d)";
immutable MSG035 = "layout %s validates!!";
immutable MSG036 = "error: unknown mapper lambda <%d> in layout <%s>";
immutable MSG037 = "error: XML definition file <%s> not found";
immutable MSG038 = "error: mapper function is not defined in layout";
immutable MSG039 = "option break records requested";
immutable MSG040 = "record <%s>, repeated pattern <%s>";
immutable MSG041 = "error: field filter file %s not found";
immutable MSG042 = "error: record filter file %s not found";
immutable MSG043 = "error: unknown output mode. Should be in the following list: %s";
immutable MSG044 = "error: break record options is only compatible with txt/box output formats";
immutable MSG045 = "zip command failed, rc = <%d>";
immutable MSG046 = "error: INSERT statement, error code = <%d>, error msg <%s>";
immutable MSG047 = "error: database create error: %s";
immutable MSG048 = "error: SQL error %d when opening file %d, SQL msg %s";
immutable MSG049 = "worksheet name = <%s>";
immutable MSG050 = "starting conversion, nbCpus = %d";
immutable MSG051 = "error: input file <%s> not found";
immutable MSG052 = "sqlite3 lib version <%s>";
immutable MSG053 = "info: number of bad formatted fields: <%d>";
immutable MSG054 = "error: field %s is not in layout %s";
immutable MSG055 = "field filter error: record <%s> is not found in layout";
immutable MSG056 = "new field type: name=<%s>, type=<%s>, pattern=<%s>, format=<%s>";
immutable MSG057 = "processing record-based file creation";
immutable MSG058 = "fatal: output format should be in the following list: %s";
immutable MSG059 = "add zip archive <%s>";
immutable MSG060 = "deleting unnecessary files";
immutable MSG061 = "started with the following arguments: %s";
immutable MSG062 = "fatal error: type <%s> is not defined for field <%s> !!";
immutable MSG063 = "error: statement <%s>, error code = <%d>, error msg <%s>";
immutable MSG064 = "error: sqlite_bind() API error, error code = <%d>, error msg <%s>";
immutable MSG065 = "%d lines processed so far";
immutable MSG066 = "info: %d/%d records processed so far (%.0f %%), %d matching record filter condition";
immutable MSG067 = "info: reading configuration file <%s> from environment variable <%s>";
immutable MSG068 = "info: creating/using default log file <%s>";
immutable MSG069 = "info: reading configuration file <%s> from the current directory";
immutable MSG070 = "info: reading configuration file <%s> from the default location";
immutable MSG071 = "info: reading configuration file <%s> from the command line";
immutable MSG072 = "info: %s table is populated";
immutable MSG073 = "error: SQL statement file <%s> not found";
immutable MSG074 = "info: reading external SQL statement file <%s>";
immutable MSG075 = "info: triggering pre-sql file <%s>";
immutable MSG076 = "info: triggering post-sql file <%s>";
immutable MSG077 = "info: field filter requested, keeping only <%s>";
immutable MSG078 = "error: template file <%s> not found";
immutable MSG079 = "error: element name <%s> is not in unique list of record/container <%s>";
immutable MSG080 = "info: using template file <%s>";
immutable MSG081 = "error: record name is empty";
immutable MSG082 = "error: no name attribute when creating record";
immutable MSG083 = "error: no description attribute when creating record";
immutable MSG084 = "error: no name attribute when creating field";
immutable MSG085 = "error: no description attribute when creating field";
immutable MSG086 = "error: no length attribute when creating field";
immutable MSG087 = "error: no type attribute when creating field";
immutable MSG088 = "error: XMl configuration file <%s> not found";
immutable MSG089 = "error: input file <%s> for XML file creation not found";
immutable MSG090 = "error: unknown sanitizing option for tag <%s> and attribute <%s>";
immutable MSG091 = "error: no template file provided";
immutable MSG092 = "PostgreSQL lib version <%d>";
immutable MSG093 = "error: PostgreSQL error %d when opening db %s, SQL msg %s";
