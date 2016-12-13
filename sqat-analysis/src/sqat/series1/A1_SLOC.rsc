module sqat::series1::A1_SLOC

import IO;
import util::FileSystem;

import String;
import List;
import ValueIO;
import Tuple;
import Map;

/* 

Count Source Lines of Code (SLOC) per file:
- ignore comments
- ignore empty lines

Tips
- use locations with the project scheme: e.g. |project:///jpacman/...|
- functions to crawl directories can be found in util::FileSystem
- use the functions in IO to read source files

Answer the following questions:
- what is the biggest file in JPacman?
	largestFile(|project://jpacman-framework/src|) returns the 'Level.java' file
	in the level subdirectory.

- what is the total size of JPacman?
	linesOfCode(|project://jpacman-framework/src|) returns 2458 SLOC

- is JPacman large according to SIG maintainability?
	In the SIG maintainability model, 2458 SLOC is classified as "very small" (++)

- what is the ratio between actual code and test code size?
	We excluded the tests from the main source code by adjusting the project paths:
		linesOfCode(|project://jpacman-framework/src/main|) = 1901
		linesOfCode(|project://jpacman-framework/src/test|) = 557
	1901/557 = 3.41, so for every line of test code, there are 3 lines of actual source code.
	

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.

- compare you results to external tools sloc and/or cloc.pl
	Our result for the number of source lines of code corresponds with the result
	given by the cloc.pl script.

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/
test bool multiLine() = linesOfCode(|project://sqat-analysis/src/sqat/series1/A1Test_multiline.java|) == 2;
test bool newLines() = linesOfCode(|project://sqat-analysis/src/sqat/series1/A1Test_consec_newlines.java|) == 2;

alias fileAndSize = tuple[loc,int];
loc largestFile(loc project) {
	fileSzPairs = [ <f, getFileLength(f)> | /file(f) := crawl(project), f.extension == "java" ];
	bool sortOnSize(fileAndSize a, fileAndSize b) { return a[1] > b[1]; };
	return head(sort(fileSzPairs, sortOnSize))[0];
}

int linesOfCode(loc project) {
	return sum([ s | <_,s> <- toList(sloc(project)) ]);
}

alias SLOC = map[loc file, int sloc];

int getSLOC(list[str] lines) {
	int result = 0;
	bool multiline = false;
  	
	for (line <- lines, !isEmpty(trim(line))) {
  	
  		if (/\/\*/ := line)
			multiline = true;

  		if (/\/\// !:= line && !multiline)
			result += 1;
  		
  		if (/\*\// := line)
  			multiline = false;
  	}
	return result;
}

// |project://jpacman-framework/src|
SLOC sloc(loc project) {
	SLOC result = ();

	for (/file(f) := crawl(project), f.extension == "java") {
		fileLines = readFileLines(f);
		result[f] = getSLOC(fileLines);
	}
	return result;
}