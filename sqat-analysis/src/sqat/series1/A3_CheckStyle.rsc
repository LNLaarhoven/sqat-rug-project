module sqat::series1::A3_CheckStyle

import lang::java::\syntax::Java15;
import Message;
import util::FileSystem;
import String;
import IO;

/*

Assignment: detect style violations in Java source code.
Select 3 checks out of this list:  http://checkstyle.sourceforge.net/checks.html
Compute a set[Message] (see module Message) containing 
check-style-warnings + location of  the offending source fragment. 

Plus: invent your own style violation or code smell and write a checker.

Note: since concrete matching in Rascal is "modulo Layout", you cannot
do checks of layout or comments (or, at least, this will be very hard).

JPacman has a list of enabled checks in checkstyle.xml.
If you're checking for those, introduce them first to see your implementation
finds them.

Questions
- for each violation: look at the code and describe what is going on? 
  Is it a "valid" violation, or a false positive?

Tips 

- use the grammar in lang::java::\syntax::Java15 to parse source files
  (using parse(#start[CompilationUnit], aLoc), in ParseTree)
  now you can use concrete syntax matching (as in Series 0)

- alternatively: some checks can be based on the M3 ASTs.

- use the functionality defined in util::ResourceMarkers to decorate Java 
  source editors with line decorations to indicate the smell/style violation
  (e.g., addMessageMarkers(set[Message]))

  
Bonus:
- write simple "refactorings" to fix one or more classes of violations 

*/
bool checkAvoidStarImport(str importString) {
	
	if (contains(importString, ".*"))
		return true;
	else
		return false;
}

bool checkLineLength(str line) {
	if (size(line) > 100)
		return true;
	else
		return false;
}

bool checkOneStatementPerLine(str line) {
	if(!startsWith(line, "for") && findFirst(line, ";") != findLast(line, ";"))
		return true;
	else
		return false;  
}

set[Message] checkStyle(loc project) {
  set[Message] result = {};
  
  // to be done
  // implement each check in a separate function called here. 
  for (/file(f) := crawl(project), f.extension == "java") {
  	
	fileLines = readFileLines(f);
	int lineNumber = 1;
	
	for (line <- fileLines) {
  		
  		if (startsWith(trim(line), "import ") && checkAvoidStarImport(line))
  			result += warning("Avoid star characters in import statement in line <lineNumber>", f);
  		
  		if (checkLineLength(line))
  			result += warning("Line <lineNumber> exceeds the 100 character limit, please shorten or cut the line", f);
  		
  		if (checkOneStatementPerLine(trim(line)))
  			result += warning("There is more than one statement on line <lineNumber>", f);		
  			
  		lineNumber += 1; 
  	}
	
  }  
  
  return result;
}
