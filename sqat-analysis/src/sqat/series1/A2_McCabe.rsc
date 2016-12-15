module sqat::series1::A2_McCabe

import lang::java::jdt::m3::AST;
import IO;
import Relation;
import Set;
import List;

import sqat::series1::A1_SLOC;
//import analysis::statistics::Correlation;

/*

Construct a distribution of method cylcomatic complexity. 
(that is: a map[int, int] where the key is the McCabe complexity, and the value the frequency it occurs)


Questions:
- which method has the highest complexity (use the @src annotation to get a method's location)

	getHighestComplexityMethod(cc(jpacmanASTs())) returns the method with the highest CC value.

- how does pacman fare w.r.t. the SIG maintainability McCabe thresholds?
	The paper indicates that a CC between 1 and 10 is simple code without much risk. All methods
	within the JPacman project falls in this range.
	ccDist(cc(jpacmanASTs())) shows the distribution of CCs for the methods in JPacman.

- is code size correlated with McCabe in this case (use functions in analysis::statistics::Correlation to find out)? 
  (Background: Davy Landman, Alexander Serebrenik, Eric Bouwers and Jurgen J. Vinju. Empirical analysis 
  of the relationship between CC and SLOC in a large corpus of Java methods 
  and C functions Journal of Software: Evolution and Process. 2016. 
  http://homepages.cwi.nl/~jurgenv/papers/JSEP-2015.pdf)
  
- what if you separate out the test sources?

Tips: 
- the AST data type can be found in module lang::java::m3::AST
- use visit to quickly find methods in Declaration ASTs
- compute McCabe by matching on AST nodes

Sanity checks
- write tests to check your implementation of McCabe

Bonus
- write visualization using vis::Figure and vis::Render to render a histogram.

*/

set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework/src|, true);

alias CC = rel[loc method, int cc];

int visitStatements(Statement impl) {
	int cc = 1;

	visit(impl) {
		case \if(cond, ifBranch):		cc += 1;
		case \if(cond, _, elseBranch):	cc += 1;
		case \while(cond, body):		cc += 1;
		case \for(_, cond, _, body):	cc += 1;
		case \for(_, _, body):			cc += 1;
		case \foreach(_, _, body):		cc += 1;
		case \catch(_, body):			cc += 1;
		case \case(_):					cc += 1;
		case \defaultCase():			cc += 1;
		case \infix(lhs, "&&", rhs):	cc += 1;
		case \infix(lhs, "||", rhs):	cc += 1;
	}

	return cc;
}

CC cc(set[Declaration] decls) {
	CC result = {};

	visit(decls) {
		case m: \method(returnType, name, params, exceptions, implementation):
			result += <m@src, visitStatements(implementation)>;
	}

	return result;
}

alias CCDist = map[int cc, int freq];

CCDist ccDist(CC ccPerMethod) {
	CCDist d = ();

	for (cc <- [x[1] | x <- ccPerMethod]) {
		if (cc in d)
			d[cc] += 1;
		else
			d[cc] = 1;
	}

	return d;
}

tuple[loc, int] getHighestComplexityMethod(CC ccPerMethod) {
	bool sortOnCC(tuple[loc,int] a, tuple[loc,int] b) { return a[1] > b[1]; };
	return head(sort(ccPerMethod, sortOnCC));
}


lrel[int, int] findRelation(set[Declaration] decls) {
	lrel[int,int] res = [];

	for (<x,y> <- cc(decls)) {
		res += <getSLOC(readFileLines(x)), y>;
	}
	//PearsonsCorrelationPValues(res);
	return res;
}



rel[str methodName, int cc] testResults() {
	rel[str methodName, int cc] result = {};

	visit({ createAstFromFile(|project://sqat-analysis/src/sqat/series1/A2Test.java|, true) }) {
		case m: \method(_, name, _, _, impl):
			result += <name, visitStatements(impl)>;
	}

	return result;
}

test bool nestedTest() = testResults()["nested"] == {4};
test bool ifElseTest() = testResults()["if_else"] == {2};
test bool switchTest() = testResults()["switch_case"] == {5};
test bool infixSimpleTest() = testResults()["infix_simple"] == {3};
test bool infixComplexTest() = testResults()["infix_complex"] == {5};
test bool tryCatchTest() = testResults()["try_catch"] == {2};
