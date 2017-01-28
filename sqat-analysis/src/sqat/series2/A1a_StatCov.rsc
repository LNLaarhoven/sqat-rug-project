module sqat::series2::A1a_StatCov

import lang::java::jdt::m3::Core;

import analysis::m3::Core;
import IO;
import Set;
import util::Math;
import String;

/*

Implement static code coverage metrics by Alves & Visser 
(https://www.sig.eu/en/about-sig/publications/static-estimation-test-coverage)


The relevant base data types provided by M3 can be found here:

- module analysis::m3::Core:

rel[loc name, loc src]        M3@declarations;            // maps declarations to where they are declared. contains any kind of data or type or code declaration (classes, fields, methods, variables, etc. etc.)
rel[loc name, TypeSymbol typ] M3@types;                   // assigns types to declared source code artifacts
rel[loc src, loc name]        M3@uses;                    // maps source locations of usages to the respective declarations
rel[loc from, loc to]         M3@containment;             // what is logically contained in what else (not necessarily physically, but usually also)
list[Message]                 M3@messages;                // error messages and warnings produced while constructing a single m3 model
rel[str simpleName, loc qualifiedName]  M3@names;         // convenience mapping from logical names to end-user readable (GUI) names, and vice versa
rel[loc definition, loc comments]       M3@documentation; // comments and javadoc attached to declared things
rel[loc definition, Modifier modifier] M3@modifiers;     // modifiers associated with declared things

- module  lang::java::m3::Core:

rel[loc from, loc to] M3@extends;            // classes extending classes and interfaces extending interfaces
rel[loc from, loc to] M3@implements;         // classes implementing interfaces
rel[loc from, loc to] M3@methodInvocation;   // methods calling each other (including constructors)
rel[loc from, loc to] M3@fieldAccess;        // code using data (like fields)
rel[loc from, loc to] M3@typeDependency;     // using a type literal in some code (types of variables, annotations)
rel[loc from, loc to] M3@methodOverrides;    // which method override which other methods
rel[loc declaration, loc annotation] M3@annotations;

Tips
- encode (labeled) graphs as ternary relations: rel[Node,Label,Node]
- define a data type for node types and edge types (labels) 
- use the solve statement to implement your own (custom) transitive closure for reachability.

Questions:
- what methods are not covered at all?
- how do your results compare to the jpacman results in the paper? Has jpacman improved?
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)


*/

M3 jpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework/src|);

alias Graph = rel[loc, str, loc];

bool isFunction(loc artifact) 				= artifact.scheme == "java+method" || artifact.scheme == "java+constructor";
bool isClass(loc artifact) 					= artifact.scheme == "java+class";
bool isTestAnnotation(set[loc] annotation) 	= |java+interface:///org/junit| in { a.parent | a <- annotation };

bool JCLCall(loc call) = startsWith(call.path, "/java/");

set[loc] getClassMethods(M3 model, loc class) {
	return { member | member <- model@containment[class], isFunction(member) };
}

set[loc] get(M3 model, bool (loc artifact) what) = { artifact.name | artifact <- model@declarations, what(artifact.name) };
set[loc] getAllClasses(M3 model) = get(model, isClass);
set[loc] getAllMethods(M3 model) = get(model, isFunction);

set[loc] filterMethods(M3 model, bool testMethods) = { method | method <- get(model, isFunction),
	testMethods == isTestAnnotation(model@annotations[method]) };

set[loc] getAllTestMethods(M3 model) = filterMethods(model, true);
set[loc] getNonTestMethods(M3 model) = filterMethods(model, false);

bool hasOnlyTestMethods(M3 model, loc class) = size({ m | m <- getClassMethods(model, class),
	!isTestAnnotation(model@annotations[m]) }) == 0;

set[loc] getTestedMethods(M3 model) {
	set[loc] tested = getAllTestMethods(model);

	Graph callGraph = { <from, "calls", to> | <from, to> <- model@methodInvocation, !JCLCall(to) };

	solve (tested) {
		tested += { * callGraph[method]["calls"] | method <- tested };
	}

	return tested - getAllTestMethods(model);
}

real calculateClassCoverage(M3 model, loc class, set[loc] allTestedMethods) {
	classMethods = getClassMethods(model, class);
	return 100 * toReal(size(allTestedMethods & classMethods)) / size(classMethods);
}

real calculateTotalCoverage(M3 model) {
	return 100 * toReal(size(getTestedMethods(model))) / size(getNonTestMethods(model));
}

rel[loc, real] calculateTotalCoveragePerClass(M3 model) {
	set[loc] tested = getTestedMethods(model);
	return { <class, calculateClassCoverage(model, class, tested)> | class <- getAllClasses(model),
		!hasOnlyTestMethods(model, class) };
}

