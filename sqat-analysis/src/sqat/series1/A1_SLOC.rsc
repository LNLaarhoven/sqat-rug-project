module sqat::series1::A1_SLOC

import IO;
import util::FileSystem;

import String;
import List;
import ValueIO;
import Tuple;

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
- what is the total size of JPacman?
- is JPacman large according to SIG maintainability?
- what is the ratio between actual code and test code size?

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/
alias fileAndSize = tuple[loc,int];
loc largestFile(loc project) {
	fileSzPairs = [ <f, getFileLength(f)> | /file(f) := crawl(project), f.extension == "java" ];
	bool sortOnSize(fileAndSize a, fileAndSize b) { return a[1] > b[1]; };
	return head(sort(fileSzPairs, sortOnSize))[0];
}

alias SLOC = map[loc file, int sloc];

// |project://jpacman-framework/src|
SLOC sloc(loc project) {
  SLOC result = ();
  
  for (/file(f) := crawl(project), f.extension == "java") {
  	
	fileLines = readFileLines(f);
	result[f] = 0;
	
  	bool multiline = false;
  	
  	for (line <- fileLines, !isEmpty(trim(line))) {
  	
  		if (/\/\*/ := line)
  			multiline = true;
  		
  		if (/\/\// !:= line && !multiline)
  			result[f] += 1;
  		
  		if (/\*\// := line)
  			multiline = false;
  	}
  
  }
  return result;
}