module Series1

extend javascript::Syntax;
import ParseTree;

syntax Expression
  = "@" Id
  | @category="TwitterConstant" "@(" {Expression ","}* ")"
  | @category="TwitterConstant" "#(" {Expression ","}* ")"
  ;
  
syntax Statement
  = "dont" Statement
  | "todo" String ";"
  | "unless" "(" Expression ")" Statement
  | "repeat" Statement "until" "(" Expression ")" ";"
  | "assert" Expression ":" String ";"
  | "debug" Expression ";"
  ;
  
// Reserve the new keywords
keyword Keywords = "todo" | "dont" | "unless" | "repeat" | "assert" | "debug";
  
/* 
 * 0. Debug statement (Example)
 */ 
  

Statement desugar((Statement)`debug <Expression ex>;`) {
  return (Statement) `if (DEBUG_FLAG) 
                     '  console.log("DEBUG: " + (<Expression ex>));`;
}

test bool testDebug() 
  = desugar((Statement)`debug "Hello";`) 
  == (Statement)`if (DEBUG_FLAG) console.log("DEBUG: " + ("Hello"));`;

/*
 * 1. At fields
 */ 
Expression desugar((Expression)`@<Id x>`) = (Expression)`this.<Id x>`;

test bool testAtField() 
  = desugar((Expression)`@name`) 
  == (Expression)`this.name`;


/*
 * 2. Twitter search expressions
 */
Expression desugar((Expression)`@(<{Expression ","}* es>)`) 
  = /* you should replace this */ dummyExp();

Expression desugar((Expression)`#(<{Expression ","}* es>)`)
  = /* you should replace this */ dummyExp();  

test bool testTwitter()
  = desugar((Expression)`@("obama")`) 
  == (Expression)`searchAt("obama")`;

/*
 * 3. Don't statement
 */

Statement desugar((Statement)`dont <Statement _>`) = /* you should replace this */ dummyStat();

test bool testDont()
  = desugar((Statement)`dont if (x == 3) print(x);`) 
  == (Statement)`;`;

/*
 * 4. Todo statement
 */

Statement desugar((Statement)`todo <String s>;`) 
  = /* you should replace this */ dummyStat(); 
 
 
test bool testTodo()
  = desugar((Statement)`todo "FIXME";`) 
  == (Statement)`console.log("TODO: " + "FIXME");`;
 
/* 
 * 5. Unless statement
 */
 
Statement desugar((Statement)`unless (<Expression cond>) <Statement body>`)
  = /* you should replace this */ dummyStat();
 

test bool testUnless()
  = desugar((Statement)`unless (x == 0) print(x);`)
  == (Statement)`if (!(x == 0)) print(x);`;
 
/* 
 * 6. Repeat-until statement
 */

Statement desugar((Statement)`repeat <Statement stat> until (<Expression cond>);`)
  = /* you should replace this */ dummyStat();

test bool testRepeat()
  = desugar((Statement)`repeat {print(i); i--;} until (i == 0);`)
  ==  (Statement)`do {print(i); i--;} while (!(i == 0));`;

/* 
 * 7. Assert statement
 */


Statement desugar((Statement)`assert <Expression e>: <String msg>;`) {
  // don't forget to convert the expression to a string!
  return /* you should replace this */ dummyStat();
}


test bool testAssert()
  = desugar((Statement)`assert x != null: "x should not be null";`)
  == (Statement)`if (!(x != null))
                '  throw "Assertion " + "x != null" + " failed: " + "x should not be null";`;
  
String jsString(Expression e) = parse(#String, "\"<unparse(e)>\""); 


Expression dummyExp() = (Expression)`NOT_YET_IMPLEMENTED`;
Statement dummyStat() = (Statement)`NOT_YET_IMPLEMENTED;`;

