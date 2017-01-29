module sqat::series2::A2_CheckArch

import sqat::series2::Dicto;
import lang::java::jdt::m3::Core;
import Message;
import ParseTree;
import IO;

import String;
import ToString;
import Set;

/*

This assignment has two parts:
- write a dicto file (see example.dicto for an example)
  containing 3 or more architectural rules for Pacman
  
- write an evaluator for the Dicto language that checks for
  violations of these rules. 

Part 1  

An example is: ensure that the game logic component does not 
depend on the GUI subsystem. Another example could relate to
the proper use of factories.   

Make sure that at least one of them is violated (perhaps by
first introducing the violation).

Explain why your rule encodes "good" design.
  
Part 2:  
 
Complete the body of this function to check a Dicto rule
against the information on the M3 model (which will come
from the pacman project). 

A simple way to get started is to pattern match on variants
of the rules, like so:

switch (rule) {
  case (Rule)`<Entity e1> cannot depend <Entity e2>`: ...
  case (Rule)`<Entity e1> must invoke <Entity e2>`: ...
  ....
}

Implement each specific check for each case in a separate function.
If there's a violation, produce an error in the `msgs` set.  
Later on you can factor out commonality between rules if needed.

The messages you produce will be automatically marked in the Java
file editors of Eclipse (see Plugin.rsc for how it works).

Tip:
- for info on M3 see series2/A1a_StatCov.rsc.

Questions
- how would you test your evaluator of Dicto rules? (sketch a design)
- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 

	1.	A package Entity type. Currently, only class and method is supported.
		If we want to make sure the game logic does not depend on the GUI
		components, then it would be nice that we can simply denote:
			`jpacman.game.Game cannot depend on jpacman.ui`
		.. instead of enumerating all subtypes of the jpacman.ui package.

	2.	Method parentheses. Our code does a lookup in the names annotation
		of the M3 model to attempt to find out the correct method, in
		case there are multiple overloaded methods. Introducing parentheses
		in the Dicto syntax would remove the need for this, since obviously
		the function arguments can then point out which function is meant.
*/

set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);

set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) 
  = ( {} | it + eval(r, m3) | r <- rules );


bool validate(loc artifact, Modality m, set[loc] artifacts) {

	switch (toString(m)) {
		case "must": 		return artifact in artifacts;
		case "cannot": 		return artifact notin artifacts;
		case "may": 		return true;
		case "can only":	return validate(artifact, (Modality)`must`, artifacts)
									&& size(artifacts) == 1;
	}
}

set[loc] getImports(loc javaFile) = { |java+class:///| + replaceAll(name, ".", "/")
	| l <- readFileLines(javaFile), /\s*import \s*<name:[\w|\.]*>;/ := l };

loc getFileFromDecl(loc artifact, M3 m3) = [ |file:///| + a.path | a <- m3@declarations[artifact] ][0];

bool evalImport(loc e1, loc e2, Modality m, M3 m3) 	= validate(e2, m, getImports(getFileFromDecl(e1, m3)));
bool evalDepend(loc e1, loc e2, Modality m, M3 m3) 	= validate(e2, m, m3@typeDependency[e1]);
bool evalInherit(loc e1, loc e2, Modality m, M3 m3)	= validate(e2, m, m3@extends[e1]);

bool evalInvoke(Entity e1, loc e2, Modality m, M3 m3) {

	e1loc = getLoc(e1, m3);

	if (e1 is method) {
		return validate(e2, m, m3@methodInvocation[e1loc]);
	}

	if (e1 is class) {
		return validate(e2, m, { *m3@methodInvocation[e1s] | e1s <- m3@containment[e1loc], isFunction(e1s) });
	}
}

bool evalInstantiate(Entity e1, Entity e2, Modality m, M3 m3) {
	set[loc] e2ctors = m3@names[ split(".", toString(e2))[-1] ];

	allCtorCalls = { evalInvoke(e1, e, m, m3) | e <- e2ctors};

	switch (toString(m)) {
		case "must": 		return (false 	| it || i | bool i <- allCtorCalls); // Any of the ctors should be invoked
		case "cannot": 		return (true 	| it && i | bool i <- allCtorCalls); // None of the ctors should be invoked
		case "may":			return true;
		case "can only": 	return (false 	| it || i | bool i <- allCtorCalls)
									&& size(allCtorCalls) == 1;
	}

}

set[Message] eval(Rule rule, M3 m3) {
	set[Message] msgs = {};

	// to be done
	if ((Rule)`<Entity e1> <Modality m> <Relation r> <Entity e2>` := rule) {

		loc e1loc = getLoc(e1, m3);
		loc e2loc = getLoc(e2, m3);
		bool pass = true;

		switch (toString(r)) {

			case "import": 		pass = evalImport(e1loc, e2loc, m, m3);
			case "depend": 		pass = evalDepend(e1loc, e2loc, m, m3);
			case "invoke": 		pass = evalInvoke(e1, e2loc, m, m3);
			case "instantiate":	pass = evalInstantiate(e1, e2, m, m3);
			case "inherit": 	pass = evalInherit(e1loc, e2loc, m, m3);

		}

		if (!pass) msgs += warning(toString(rule), e1loc);

	} else {
		println("invalid rule: " + toString(rule));
	}

	return msgs;
}

loc getLoc(Entity e, M3 m3) {

	str slashedName = replaceAll(toString(e), ".", "/");

	if (e is class)
		return |java+class:///| + slashedName;

	if (e is method) {
		set[loc] fullNames = m3@names[ split("::", toString(e))[-1] ];

		// Constructors too, perhaps?
		slashedLoc = |java+method:///| + replaceAll(slashedName, "::", "/");

		for (name <- fullNames, name.parent == slashedLoc.parent)
			return name;

		println("warning: problem resolving method name \"" + toString(e) + "\"");
		return |java+method:///| + "unresolvable";

	}
}

bool isFunction(loc artifact) = artifact.scheme == "java+method" || artifact.scheme == "java+constructor";

M3 testModel() = createM3FromEclipseProject(|project://TestCheckArch/src|);
test bool mustInheritRule() = size(eval((Rule)`inherit.Sub must inherit inherit.Super`, testModel())) == 0;
test bool cannotInheritRule() = size(eval((Rule)`inherit.Sub cannot inherit inherit.Super`, testModel())) == 1;
test bool canOnlyInheritRule() = size(eval((Rule)`inherit.Sub can only inherit inherit.Super`, testModel())) == 0;

test bool mustImportRule() = size(eval((Rule)`testImport.Import must import testImport.ToBeImported`, testModel())) == 0;
test bool canOnlyImportRule() = size(eval((Rule)`testImport.Import can only import testImport.ToBeImported`, testModel())) == 0;
test bool cannotImportRule() = size(eval((Rule)`testImport.Import cannot import testImport.ToBeImported`, testModel())) == 1;

test bool mustInvokeRule() = size(eval((Rule)`testImport.Import must invoke testImport.ToBeImported::invokeTest`, testModel())) == 0;
test bool canOnlyInvokeRule() = size(eval((Rule)`testImport.Import can only invoke testImport.ToBeImported::invokeTest`, testModel())) == 1;
test bool cannotInvokeRule() = size(eval((Rule)`testImport.Import cannot invoke testImport.ToBeImported::invokeTest`, testModel())) == 1;
