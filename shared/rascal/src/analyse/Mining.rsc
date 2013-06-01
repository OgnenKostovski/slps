@contributor{Vadim Zaytsev - vadim@grammarware.net - SWAT, CWI}
module analyse::Mining

import analyse::Metrics;
import language::BGF;
import io::ReadBGF;
import String;
import List;
import Map;
import IO;
import lib::Rascalware;
import export::BNF;

// TODO: just import mutate::type2::RetireSs ?
// import normal::BGF;
// 
// SGrammar RetireSs(SGrammar g)
// {
// 	ps = visit(g.prods) {case selectable(_,BGFExpression e) => e};
// 	return <g.roots, normalise(g.prods)>;
// }
BGFProduction RetireSs(BGFProduction p) = visit(p) {case selectable(_,BGFExpression e) => e};

alias dict = map[BGFExpression,int];
alias NPC = tuple[int ns, int clasns, int ps, int cx, dict patterns, map[str,int] counts, set[str] weird, map[str,set[str]] scores];
NPC Zero = <0,0,0,0,(),(),{},()>;
alias SGrammar = tuple[set[str] roots, map[str,BGFProdSet] prods];

NPC getZoo(loc zoo, NPC npc)
{
	dict patterns = npc.patterns;
	int n = npc.ns, pcx = npc.ps, cx = npc.cx, cns = npc.clasns;
	set[str] weird = npc.weird, newweird = {}, nonclas = {};
	map[str,int] counts = npc.counts;
	map[str,set[str]] scores = npc.scores;
	BGFGrammar g;
	SGrammar s;
	set[str] allNTs = {};
	for (str lang <- listEntries(zoo), !endsWith(lang,".html"), str s <- listEntries(zoo+"/<lang>"), endsWith(s,".bgf"))
	{
		println("<lang>::<s>");
		cx += 1;
		g = readBGF(zoo+"/<lang>/<s>");
		allNTs = allNs(g);
		newweird = allNTs;
		nonclas = allNTs;
		int VAR = len(allNTs);
		n += VAR;
		pcx += len(g.prods);

		sg = splitGrammar(g);
		if (domain(sg.prods) != allNTs)
			println("Nonterminal sets are not equal!\n<domain(sg.prods)>\n<allNTs>\n<domain(sg.prods)-allNTs>\n<allNTs-domain(sg.prods)>");
		
		for (metric <- AllMetrics)
		{
			// println("  Calculating <metric>...");
			res = AllMetrics[metric](sg);
			if ("<metric>" notin counts) counts["<metric>"] = 0;
			if ("<metric>" notin scores) scores["<metric>"] = {};
			counts["<metric>"] += len(res);
			if (len(res)==VAR)
				scores["<metric>"] += {"<lang>::<s>"};
			if ("<AllMetrics[metric]>" in Exclude)
				newweird -= res;
			else
			{
				allNTs -= res;
				nonclas -= res;
			}
		}
		cns += len(allNTs);
		weird += {"<lang>::<s>::<nt>" | nt <- newweird};
		
		if (false && !isEmpty(nonclas))
		{
			// int sz;
			println("  Not classified:");
			for(str ncnt <- nonclas)
				println("    <pp(prodsOfN(ncnt,g))>");
		}
		
		g = abstractPattern(g);
		for (BGFProduction p <- abstractPattern(g).prods)
			if (p.rhs in domain(patterns))
				patterns[p.rhs] += 1;
			else
				patterns[p.rhs] = 1;
	}
	return <n,cns,pcx,cx,patterns,counts,weird,scores>;
}

BGFGrammar abstractPattern(BGFGrammar g)
	= visit(g)
	{
		case nonterminal(_) => nonterminal("N")
		case terminal(_) => nonterminal("T")
		case selectable(_, BGFExpression expr) => expr
	};

SGrammar splitGrammar(BGFGrammar g)
{
	map[str,BGFProdSet] ps = ();
	for (BGFProduction p <- g.prods)
		if (p.lhs in domain(ps))
			ps[p.lhs] += {p};
		else
			ps[p.lhs] = {p};
	for (str n <- bottomNs(g))
		ps[n] = {};
	for (str n <- g.roots, n notin ps)
		ps[n] = {};
	return <toSet(g.roots), ps>;
}

////////////////////////////
// GROUP: GlobalPosition  //
////////////////////////////
set[str] tops(SGrammar g)    = definedNs(g) - usedNs(g); // = {t | str t <- domain(g.prods), /nonterminal(t) !:= range(g.prods)};
set[str] bottoms(SGrammar g) = usedNs(g) - definedNs(g);
set[str] ifroots(SGrammar g) = g.roots & domain(g.prods);
// TODO: not _, but in fact [*nonterminal(_)]
// TODO: also account for vertical roots
set[str] multiroots(SGrammar g) = {n | str n<-g.roots, {production(_,n,choice(L))} := g.prods[n], allnonterminals(L)};
// TODO: actually, much more complicated: may not refer to _defined_ nonterminals
set[str] leafs(SGrammar g) = {n | str n <- domain(g.prods), !isEmpty(g.prods[n]), /nonterminal(_) !:= g.prods[n] };

//////////////////////
// GROUP: ProdForm  //
//////////////////////
set[str] horizontals(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice(L))} := g.prods[n] };
set[str] verticals(SGrammar g) = {n | str n <- domain(g.prods), len(g.prods[n])>1 };
// TODO: covers too much?
set[str] singletons(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,BGFExpression e)} := g.prods[n], choice(_) !:= e};
// NB: the next is the same one as bottoms
// set[str] undefineds(SGrammar g) = {n | str n <- domain(g.prods), isEmpty(g.prods[n])};

////////////////
// UNGROUPED  //
////////////////
set[str] preterminals(SGrammar g) = {n | str n <- domain(g.prods), allofterminals(g.prods[n])};

set[str] constructors(SGrammar g) = {n | str n <- domain(g.prods), allconstructors(g.prods[n])};
bool allconstructors(BGFProdSet ps) = ( true | it && selectable(_,epsilon()) := p | p <- ps );

set[str] pureseqs(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,rhs)} := g.prods[n], pureseq(rhs)};
bool pureseq(epsilon()) = true;
bool pureseq(empty()) = true;
bool pureseq(anything()) = true; // arguable
bool pureseq(val(_)) = true; // arguable
bool pureseq(terminal(_)) = true;
bool pureseq(nonterminal(_)) = true;
bool pureseq(sequence(L)) = ( true | it && pureseq(e) | e <- L );
default bool pureseq(BGFExpression rhs) = false;

set[str] cnfs(SGrammar g) = {n | str n <- domain(g.prods), allCNFs(g.prods[n]) };
bool allCNFs(BGFProdSet ps) = ( true | it && isCNF(p.rhs) | p <- ps );
bool isCNF(epsilon()) = true;
bool isCNF(terminal(_)) = true;
bool isCNF(sequence([nonterminal(_),nonterminal(_)])) = true;
default bool isCNF(BGFExpression e) = false;

// TODO: include other patterns?
set[str] fakeseplists(SGrammar g) = {n | str n <- domain(g.prods), {p} := g.prods[n], isfakeseplist(RetireSs(p))};
bool isfakeseplist(production(_,_,sequence([BGFExpression a,star(sequence([BGFExpression b, a]))]) )) = true;
bool isfakeseplist(production(_,str n,choice([BGFExpression a,sequence([nonterminal(n),BGFExpression b,a])]) )) = true;
default bool isfakeseplist(BGFProduction p) = false;

set[str] fakeopts(SGrammar g) = {n | str n <- domain(g.prods), 
	(
	{production(_,n,choice([nonterminal(_),epsilon()]))} := g.prods[n]
	||
	(len(g.prods[n])>1 && production("",n,epsilon()) in g.prods[n])
	)
	};

set[str] ntorts(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([nonterminal(_),terminal(_)]))} := g.prods[n]};
set[str] ntsorts(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([*L,terminal(_)]))} := g.prods[n], allnonterminals(L)};
set[str] ntortss(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([nonterminal(_),*L]))} := g.prods[n], allterminals(L)};
set[str] tsornts(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([*L,nonterminal(_)]))} := g.prods[n], allterminals(L)};

set[str] abstracts(SGrammar g) = {n | str n <- domain(g.prods), /terminal(_) !:= g.prods[n]};

set[str] empties(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,epsilon())} := g.prods[n]};
set[str] failures(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,empty())} := g.prods[n]};

set[str] justplusses(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,plus(nonterminal(_)))} := g.prods[n]};
set[str] juststars(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,star(nonterminal(_)))} := g.prods[n]};
set[str] justopts(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,optional(nonterminal(_)))} := g.prods[n]};

// TODO: include other patterns?
set[str] justseplistps(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,seplistplus(nonterminal(_),terminal(_)))} := g.prods[n]};
set[str] justseplistss(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sepliststar(nonterminal(_),terminal(_)))} := g.prods[n]};

set[str] bracketedseplistps(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sequence([terminal(_),seplistplus(nonterminal(_),terminal(_)),terminal(_)]))} := g.prods[n]};
set[str] bracketedseplistss(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sequence([terminal(_),sepliststar(nonterminal(_),terminal(_)),terminal(_)]))} := g.prods[n]};

set[str] bracketedfakeseplist(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sequence([terminal(_),nonterminal(_),star(sequence([terminal(_),nonterminal(_)])),terminal(_)]))} := g.prods[n]};

set[str] bracketedopts(SGrammar g)
	= {n | str n <- domain(g.prods), {production(_,n,sequence([terminal("("),optional(_),terminal(")")]))} := g.prods[n]}
	+ {n | str n <- domain(g.prods), {production(_,n,sequence([terminal("["),optional(_),terminal("]")]))} := g.prods[n]}
	+ {n | str n <- domain(g.prods), {production(_,n,sequence([terminal("{"),optional(_),terminal("}")]))} := g.prods[n]}
	;

//     relational-expression ::= (shift-expression | (relational-expression "<" shift-expression) | (relational-expression ">" shift-expression) | (relational-expression "<=" shift-expression) | (relational-expression ">=" shift-expression) | (relational-expression "is" type) | (relational-expression "as" type)) ;
set[str] layers(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([nonterminal(_),*L]))} := g.prods[n], allNTNof(n,L)};
bool allNTNof(str x,BGFExprList xs) = ( true | it && sequence([nonterminal(x),terminal(_),nonterminal(_)]) := e | e <- xs );

// does not tolerate folding
set[str] names1(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,plus(choice(L)))} := g.prods[n], allterminals(L)};
set[str] names2(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sequence([choice(L1),star(choice(L2))]))} := g.prods[n], allterminals(L1), allterminals(L2)};

// TODO: simple chain as an all chain where $m$ is used only once in the whole grammar
set[str] allchains(SGrammar g) = {n | str n <- domain(g.prods), areallchains(g.prods[n])};
bool areallchains(BGFProdSet ps) = ( true | it && production(_,_,nonterminal(_)) := p  | p <- ps );
// set[str] somechains(SGrammar g) = {n | str n <- domain(g.prods), {*P1,production(_,n,nonterminal(_)),*P2} := g.prods[n]};
set[str] somechains(SGrammar g) = {n | str n <- domain(g.prods), /production(_,n,nonterminal(_)) := g.prods[n]};
set[str] onechains(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,nonterminal(_))} := g.prods[n]};
set[str] reflchains(SGrammar g) = {n | str n <- domain(g.prods), {*P1,production(_,n,nonterminal(n)),*P2} := g.prods[n]};
set[str] brackets(SGrammar g) = {n | str n <- domain(g.prods), {*P1,production(_,n,sequence([terminal(_),nonterminal(n),terminal(_)])),*P2} := g.prods[n]};

// lower level functions
set[str] definedNs(SGrammar g) = {n | n <- domain(g.prods), {production(_,n,empty())} !:= g.prods[n], !isEmpty(g.prods[n]) };
set[str] usedNs(SGrammar g) = {n | /nonterminal(n) := range(g.prods)};

bool allnonterminals(BGFExprList xs) = ( true | it && nonterminal(_) := e | e <- xs );
bool allterminals(BGFExprList xs) = ( true | it && terminal(_) := e | e <- xs );

bool allofterminals(BGFProdSet ps)  = ( true | it && allofterminals(p.rhs) | p <- ps );
bool allofterminals(BGFExprList xs) = ( true | it && allofterminals(e) | e <- xs );

bool allofterminals(terminal(_)) = true;
bool allofterminals(sequence(L)) = allofterminals(L);
bool allofterminals(choice(L)) = allofterminals(L);
bool allofterminals(allof(L)) = allofterminals(L); // hardly necessary
bool allofterminals(optional(e)) = allofterminals(e);
bool allofterminals(plus(e)) = allofterminals(e);
bool allofterminals(star(e)) = allofterminals(e);
bool allofterminals(seplistplus(e,s)) = allofterminals(e) && allofterminals(s);
bool allofterminals(sepliststar(e,s)) = allofterminals(e) && allofterminals(s);
default bool allofterminals(BGFExpression e) = false;

set[str] distinguished(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice(L))} := g.prods[n], allTNpairs(L)};
bool allTNpairs(BGFExprList xs) = ( true | it && sequence([terminal(_),nonterminal(_)]) := e | e <- xs );

set[str] notimplemented(SGrammar _) = {};

// 
//                ADD CLASSIFIERS HERE!
// 
map[str name,set[str](SGrammar) fun] AllMetrics =
	(
		// GlobalPosition
		"Top":					tops,					// defined but not used
		"Bottom":				bottoms,				// used but not defined
		"Leaf":					leafs,					// not referring to any other nonterminal
		"Root":					ifroots,				// if it is a root
		"MultiRoot":			multiroots,				// a “fake” multiple root
		// ProdForm
		"Singleton":			singletons,				// nonterminal is defined with one non-horizontal production rule
		"Horizontal":			horizontals,			// top level choice
		"Vertical":				verticals,				// multiple production rules per nonterminal
		// Pattern
		"JustSepListPlus":		justseplistps,			// x defined as {y ","}+
		"JustSepListStar":		justseplistss,			// x defined as {y ","}*
		"JustPlus":				justplusses,			// x defined as y+
		"JustStar":				juststars,				// x defined as y*
		"JustOptional":			justopts,				// x defined as y?
		"JustPseudoChoice":		allchains,				// nonterminal defined only with chain production rules (right hand sides are nonterminals)
		"JustChain":			onechains,				// nonterminal defined with a single chain production rule (right hand side == nonterminal)
		"BracketedSepListPlus":	bracketedseplistps,		// x defined as ( "(" {y ","}+ ")" )
		"BracketedSepListStar":	bracketedseplistss,		// x defined as ( "(" {y ","}* ")" )
		"BracketedFakeSepList":	bracketedfakeseplist,	// x defined as ( "(" y ("," z)* ")" )
		"BracketedOptional":	bracketedopts,			// x defined as ( "[" y? "]" )
		"Bracket":				brackets,				// nonterminals that have a bracketing production, e.g. E ::= "(" E ")"
		"Constructor":			constructors,			// defined with labelled epsilons
		"AbstractSyntax":		abstracts,				// abstract syntax (no terminal symbols)
		"Empty":				empties,				// nonterminal defines an empty language (epsilon)
		"Failure":				failures,				// nonterminal explicitly or implicitly undefined
		"AChain":				somechains,				// one production rule is a chain production rule (right hand side == nonterminal)
		"ReflexiveChain":		reflchains,				// one production rule is a reflexive chain (left hand side == right hand side)
		"FakeSepList":			fakeseplists,			// “fake” separator list
		"FakeOptional":			fakeopts,				// “fake” optional nonterminal
		"NTorT":				ntorts,					// nonterminal or terminal
		"NTSorT":				ntsorts,				// nonterminals or terminal
		"NTorTS":				ntortss,				// nonterminal or terminals
		"TSorNT":				tsornts,				// terminals or nonterminal
		"ExprLayer":			layers,					// expression layers
		// the rest
		"Name1":				names1,					// identifier names [a-z]+
		"Name2":				names2,					// identifier names [a-z][a-zA-Z_]*
		"Preterminal":			preterminals,			// defined with terminals
		"PureSequence":			pureseqs,				// pure sequential composition
		"DistinguishByTerm":	distinguished,			// T N | T N | …
		"CNF":					cnfs,					// production rules in Chomsky normal form
		// Not implemented
		"No":					notimplemented
	);
// too popular or exhaustive
set[str] Exclude = {"<singletons>","<horizontals>","<verticals>","<bottoms>"};

// MAIN
public void main(list[str] as)
{
	loc zoo = |home:///projects/webslps/zoo|;
	NPC npc = getZoo(|home:///projects/webslps/zoo|,Zero);
	npc = getZoo(|home:///projects/webslps/tank|,npc);
	println("Total: <npc.cx> grammars, <npc.ps> production rules, <npc.ns> nonterminals (<npc.ns-npc.clasns> thereof classified), <len(npc.patterns)> patterns.");
	for (metric <- AllMetrics)
	{
		println("<100*npc.counts["<metric>"]/npc.ns>% classified as <metric>: <npc.counts["<metric>"]> (<len(npc.scores["<metric>"])> scores).");
		if (len(npc.scores["<metric>"])>0 && len(npc.scores["<metric>"])<30)
			println("  Scores: <joinStrings(npc.scores["<metric>"])>");
	}
	for (w <- npc.weird)
		println("Weird: <w>");
	// Just the Zoo:
	//              Total: 42 grammars, 8927 production rules, 8277 nonterminals.
	// Zoo + Tank:
	//              Total: 99 grammars, 11570 production rules, 10943 nonterminals.
	// After including the Atlantic, the Relax, etc:
	// Zoo + Tank:
	//              Total: 533 grammars, 55342 production rules, 41038 nonterminals (35021 thereof classified), 3403 patterns.
	// TODO: only report unclassified ones
	// for (BGFExpression e <- domain(npc.patterns))
	// 	println("<pp(e)>: <npc.patterns[e]>");
}

