:- module(xbgf1,[transformG/3]).
% wiki: XBGF, bypass, addV, addH, chain, define, redefine, designate, unlabel, deyaccify, distribute, dump, eliminate, extract, factor, fold, horizontal, inject, appear, inline, introduce, importG, iterate, LAssoc, RAssoc, massage, permute, anonymize, deanonymize, abstractize, concretize, disappear, project, removeV, removeH, renameL, renameN, renameS, renameT, replace, reroot, narrow, abridge, detour, splitN, RetireTs, RetireLs, RetireSs, unchain, undefine, unfold, unite, equate, vertical, widen, yaccify, downgrade, upgrade

%
% Convenience wrapper for transformations.
% Make sure that transformations apply to normalized grammars.
% Make sure that vacuous transformations except bypass are rejected.
%

transformG(sequence(Ts1),G1,G2)
 :-
    !,
    normalizeG(Ts1,Ts2),
    accum(xbgf1:transformG,Ts2,G1,G2).

transformG(bypass,G1,G2)
 :- 
    !,
    format('[XBGF] bypass~n',[]),
    normalizeG(G1,G2).

transformG(Xbgf1,G1,G4)
 :-
    normalizeG(Xbgf1,Xbgf2),    
    format('[XBGF] ~q~n',[Xbgf2]),
    normalizeG(G1,G2),
    apply(Xbgf2,[G2,G3]),
    normalizeG(G3,G4),
    require(
      ( \+ G2 == G4 ),
      'Vacuous transformation detected: ~q.',
      [Xbgf2]),
    !.

%
% p([l(addV)], f, n(p))
% p([l(addH)], f, n(p))
%
% Add a production to an existing definition.
% Add a branch to a choice in a production.
%

addV(P1,g(Rs,Ps1),g(Rs,Ps3))
 :-
    P1 = p(_,N,_),
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    concat([Ps2a,Ps2,[P1],Ps2b],Ps3).

addH(P1,g(Rs,Ps1),g(Rs,Ps2))
 :-
    unmark(P1,P1u),
    removeH(P1,P1r),
    findP(Ps1,P1r,Ps1a,Ps1b),
    append(Ps1a,[P1u|Ps1b],Ps2).
    

%
% p([l(chain)], f, n(p))
%
% Establish a chain production; a restricted kind of extract
%

chain(P1,g(Rs,Ps1),g(Rs,Ps4))
 :-
    P1 = p(As,N1,X1),
    require(
      X1 = n(N2),
      'Production ~q must be a chain production.',
      [P1]),
    splitN(Ps1,N1,Ps2,Ps2a,Ps2b),
    allNs(Ps1,Ns),
    require(
      (\+ member(N2,Ns)),
      'Nonterminal ~q must be fresh.',
      [N2]),
    findP(Ps2,As,N1,P2,Ps3a,Ps3b),
    P2 = p(_,_,X2),
    concat([Ps2a,Ps3a,[P1],Ps3b,[p([],N2,X2)],Ps2b],Ps4),
    !.


%
% p([l(define)], f, +n(p))
%
% Define a nonterminal
%

define(Ps1,G1,G2)
 :-
    usedNs(G1,Uses),
    ps2n(Ps1,N),
    require(
      member(N,Uses),
      'Nonterminal ~q must not be fresh.',
      [N]),
    new(Ps1,N,G1,G2),
    !.

ps2n(Ps1,N)
 :-
    maplist(arg(2),Ps1,Ns1),
    list_to_set(Ns1,Ns2), 
    require(
      Ns2 = [N],
      'Multiple defined nonterminals found.',
      []),
    !.

%
% p([l(redefine)], f, +n(p))
%
% Undefine a nonterminal and define a new one with the same name
%

redefine(Ps1,G1,G2)
 :-
    ps2n(Ps1,N),
    undefine1(N,G1,G3),
    define(Ps1,G3,G2).


%
% p([l(designate)], f, n(p))
%
% Label a production
%

designate(P1,g(Rs,Ps1),g(Rs,Ps2))
 :-
    P1 = p(As,N,X),
    require(
       ( \+ As == [] ),
       'Production ~q must be labeled.',
       [P1]),
    P2 = p([],N,X),
    require(
      append(Ps1a,[P2|Ps1b],Ps1),
      'Production ~q not found.',
      [P2]),
    append(Ps1a,[P1|Ps1b],Ps2).

%
% p([l(unlabel)], f, n(p))
%
% Strips the label from a production
%

unlabel(L,G1,G2)
 :-
    stripL(L,G1,G2).


%
% p([l(deyaccify)], f, n(n))
%
% Use EBNF-based regular expression operator instead of BNF encoding
%

deyaccify(N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    require(
       ( length(Ps2, Len), Len > 1 ),
       'Nonterminal ~q must be defined vertically for deyaccification to work.',
       [N]),
    require(
      once(xbgf1:deyaccify_rules(N,Ps2,P3)),
      'Nonterminal ~q is not deyaccifiable: ~q',
      [N,Ps2]),
    append(Ps2a,[P3|Ps2b],Ps3).

% (N: N x; N: y) -------> N: y x*
% (N: N x; N: x) -------> N: x+
deyaccify_rules(N,P12,P3)
 :-
    length(P12,2),
    member(P1,P12),
    member(P2,P12),
    \+ P1 == P2,
    P1 = p(_,N,','([n(N)|Xs])),
    P2 = p(_,N,Y),
    normalizeG(','(Xs),X),
   (
        eqX(X,Y),!,
        normalizeG(p([],N,+(X)),P3)
    ;
        normalizeG(p([],N,','([Y,*(X)])),P3)
    ).

% (N: x N; N: y) -------> N: x* y
% (N: x N; N: x) -------> N: x+
deyaccify_rules(N,P12,P3)
 :-
    length(P12,2),
    member(P1,P12),
    member(P2,P12),
    \+ P1 == P2,
    P1 = p(_,N,','(Zs)),
    P2 = p(_,N,Y),
    append(Xs,[n(N)],Zs),
    normalizeG(','(Xs),X),
    (
        eqX(X,Y),!,
        P3 = p([],N,+(X))
    ;
        P3 = p([],N,','([*(X),Y]))
    ).


%
% p([l(distributeL)], f, n(l))
% p([l(distributeN)], f, n(n))
%
% Distribute sequential composition over choices
%

distributeL(L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P,Ps2a,Ps2b),
    distribute([P],Ps2a,Ps2b,Ps3).

distributeN(N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    distribute(Ps2,Ps2a,Ps2b,Ps3).

distribute(Ps1,Ps1a,Ps1b,Ps3)
 :-
    maplist(xbgf1:distribute_p,Ps1,Ps2),
    concat([Ps1a,Ps2,Ps1b],Ps3).

distribute_p(p(As,N,X),p(As,N,';'(Xs)))
 :-
    distribute_x(X,Xs).

distribute_x(X,[X])
 :-
    \+ X = ';'(_),
    \+ X = ','(_).

distribute_x(';'(Xs1),Xs2)
 :-
    maplist(xbgf1:distribute_x,Xs1,Xss2),
    concat(Xss2,Xs2).

distribute_x(','(Xs1),Xs3)
 :-
    maplist(xbgf1:distribute_x,Xs1,Xss2),
    findall(Xs2,distribute_sequence(Xss2,Xs2),Xs3).

distribute_sequence([Xs],','([X]))
 :- 
    member(X,Xs).

distribute_sequence([Xs1|Xss],','([X|Xs2]))
 :-
    member(X,Xs1),
    distribute_sequence(Xss,','(Xs2)).


%
% p([l(dump)], f, true)
%
% Stop transformation and store current grammar in xbgf.log.
%

dump(G,_)
 :-
    gToXml(G,BgfOutXml),
    saveXml('xbgf.log',BgfOutXml),
    cease('Dump transformation encountered.',[]).


%
% p([l(eliminate)], f, n(n))
%
% Eliminate a defined, otherwise unused nonterminal
%

eliminate(N,g(Rs1,Ps1),g(Rs2,Ps2))
 :-
    definedNs(Ps1,Defined),
    require(
       member(N,Defined),
       'Nonterminal ~q must be defined.',
       [N]),
    filter(nonunifiable(N),Rs1,Rs2),
    filter(nonunifiable(p(_,N,_)),Ps1,Ps2),
    usedNs(Ps2,Used),
    require(
       ( \+ member(N,Used) ),
       'Nonterminal ~q must not be used.',
       [N]).


%
% p([l(extract)], f, n(p))
% p([l(extractN)], f, (n(p),n(n)))
% p([l(extractL)], f, (n(p),n(l)))
%
% Extract a nonterminal definition
%

extract(P1,g(Rs,Ps1),g(Rs,Ps3))
 :-
    extract(P1,Ps1,Ps1,[],[],Ps3).

extractN(P1,N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    extract(P1,Ps1,Ps2,Ps2a,Ps2b,Ps3).

extractL(P1,L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P2,Ps2a,Ps2b),
    extract(P1,Ps1,[P2],Ps2a,Ps2b,Ps3).

extract(P1,Ps1,Ps2,Ps2a,Ps2b,Ps4)
 :-
    P1 = p(_,N,X),
    definedNs(Ps1,Defined),
    require(
       ( \+ member(N,Defined) ),
       'Nonterminal ~q must be fresh.',
       [N]),
    stoptd(xbgf1:replace_rules(X,n(N)),Ps2,Ps3),
    require(
      ( \+ Ps2 == Ps3 ),
      'No ocurrences of ~q found for extraction.',
      [X]),
    concat([Ps2a,Ps3,[P1],Ps2b],Ps4).


%
% p([l(factor)], f, (n(x),n(x)))
% p([l(factorL)], f, (n(x),n(x),n(l)))
% p([l(factorN)], f, (n(x),n(x),n(n)))
%
% Massage modulo factorization over choices.
%

factor(X1,X2,g(Rs,Ps1),g(Rs,Ps2))
 :-
    factor(X1,X2,Ps1,[],[],Ps2).

factorL(X1,X2,L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P,Ps2a,Ps2b),
    factor(X1,X2,[P],Ps2a,Ps2b,Ps3).

factorN(X1,X2,N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    factor(X1,X2,Ps2,Ps2a,Ps2b,Ps3).

factor(X1,X2,Ps1,Ps1a,Ps1b,Ps2)
 :-
    require(
      (
        xbgf1:distribute_x(X1,Xs1),
        xbgf1:distribute_x(X2,Xs2),
        normalizeG(Xs1,Xs3),
        normalizeG(Xs2,Xs4),
        eqX(';'(Xs3),';'(Xs4))
      ),
      'Expressions ~q and ~q must be related by distribution.',
      [X1,X2]
    ),
    replace(X1,X2,Ps1,Ps1a,Ps1b,Ps2).


%
% p([l(fold)], f, n(n))
% p([l(foldN)], f, (n(n),n(n)))
% p([l(foldL)], f, (n(n),n(l)))
%
% Fold an expression to its defining nonterminal
%

fold(N1,g(Rs,Ps1),g(Rs,Ps3))
 :-
    fold(N1,Ps1,Ps1,[],[],Ps3).

foldN(N1,N2,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N2,Ps2,Ps2a,Ps2b),
    fold(N1,Ps1,Ps2,Ps2a,Ps2b,Ps3).

foldL(N1,L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P2,Ps2a,Ps2b),
    fold(N1,Ps1,[P2],Ps2a,Ps2b,Ps3).

fold(N1,Ps1,Ps2,Ps2a,Ps2b,Ps4)
 :-
    splitN1(Ps1,N1,P1,_,_),
    P1 = p(_,_,X),
    ( append(Ps2c,[P1|Ps2d],Ps2) ->
        ( 
          stoptd(xbgf1:replace_rules(X,n(N1)),Ps2c,Ps2e),
          stoptd(xbgf1:replace_rules(X,n(N1)),Ps2d,Ps2f),
          append(Ps2e,[P1|Ps2f],Ps3)
        )
      ; stoptd(xbgf1:replace_rules(X,n(N1)),Ps2,Ps3)
    ),
    concat([Ps2a,Ps3,Ps2b],Ps4).


%
% p([l(horizontal)], f, n(n))
%
% Turn multiple productions into choices
%

horizontal(N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    require(
       ( length(Ps2, Len), Len > 1 ),
       'Nonterminal ~q must be defined vertically.',
       [N]),

    maplist(xbgf1:horizontal_rule,Ps2,Xs),
    concat([Ps2a,[p([],N,';'(Xs))],Ps2b],Ps3).

horizontal_rule(p([],_,X),X).
horizontal_rule(p([l(L)],_,X),s(L,X)).


%
% p([l(id)], f, true)
%
% Identity
%

id(G,G).

%
% p([l(inject)], f, n(p))
%
% Inverse of apply projection to the body of a production
%

inject(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    project(P1,P2),
    findP(Ps1,P2,Ps1a,Ps1b),
    unmark(P1,P3),
    append(Ps1a,[P3|Ps1b],Ps2).
    
%
% p([l(appear)], f, n(p))
%
% Insert an optional symbol
%

appear(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    require(
      (collect(xbgf1:collectMarked_rule,P1,[?(_)]);
       collect(xbgf1:collectMarked_rule,P1,[*(_)])),
      '~q does not have an optional part marked.',
      [P1]),
    project(P1,P2),
    findP(Ps1,P2,Ps1a,Ps1b),
    unmark(P1,P3),
    append(Ps1a,[P3|Ps1b],Ps2).


%
% p([l(inline)], f, n(n))
%
% Inline a nonterminal definition (and eliminate it)
%

inline(N,g(Rs,Ps1),g(Rs,Ps4))
 :- 
    require(
       (\+ member(N,Rs) ),
       'Nonterminal ~q must not be root.',
       [N]),
    usedNs(Ps1,Uses1),
    require(
      member(N,Uses1),
      'Nonterminal ~q must be used.',
      [N]),
    splitN1(Ps1,N,P2,Ps2a,Ps2b),
    P2 = p(_,_,X),
    usedNs([P2],Uses2),
    require(
      ( \+ member(N,Uses2) ),
      'Nonterminal ~q must not be used in its definition.',
      [N]),
    append(Ps2a,Ps2b,Ps3),
    transform(try(xbgf1:inline_rule(N,X)),Ps3,Ps4).
    
inline_rule(N,X,n(N),X).


%
% p([l(introduce)], f, +n(p))
%
% Add a definition for a fresh nonterminal
%

introduce(Ps1,G1,G2)
 :-
    usedNs(G1,Uses),
    ps2n(Ps1,N),
    require(
      ( \+ member(N,Uses) ),
      'Nonterminal ~q must be fresh.',
      [N]),
    new(Ps1,N,G1,G2).

new(Ps1,N,G1,G2)
 :-
    definedNs(G1,Defs),
    require(
      ( \+ member(N,Defs) ),
      'Definition for ~q clashes with existing definition.',
      [N]),
    G1 = g(Rs,Ps2),
    append(Ps2,Ps1,Ps3),
    G2 = g(Rs,Ps3).

%
% p([l(import)], f, +n(p))
%
% Add multiple possibly connected definitions for fresh nonterminals
%

import(Ps0,g(Rs,Ps1),g(Rs,Ps2))
 :-
    definedNs(Ps0,Defs0),
    definedNs(Ps1,Defs1),
    usedNs(Ps1,Uses1),
    intersection(Defs0,Defs1,Defs01),
    intersection(Defs0,Uses1,DU01),
    require(
      Defs01 = [],
      'Import clashes with existing definitions ~q.',
      [Defs01]),
    require(
      DU01 = [],
      'Import clashes with existing uses ~q.',
      [DU01]),
    append(Ps1,Ps0,Ps2).

%
% p([l(iterate)], f, n(p))
%
% Interpret separator list iteratively
%
iterate(P1,G1,G2)
 :-
    iter(P1,G1,G2).

iter(P1,g(Rs,Ps1),g(Rs,Ps2))
 :-
    P1 = p(As,N,X1),
    findP(Ps1,As,N,P2,Ps2a,Ps2b),
    P2 = p(As,N,X2),
    require(
      xbgf1:assoc_rules(N,X2,X1),
      '~q must admit associativity transformation.',
      [P1]),
    append(Ps2a,[P1|Ps2b],Ps2).

%
% p([l(lassoc)], f, n(p))
%
% Interpret separator list left-associatively
%

lassoc(P1,G1,G2)
 :-
    assoc(P1,G1,G2).

assoc(P1,g(Rs,Ps1),g(Rs,Ps2))
 :-
    P1 = p(As,N,X1),
    findP(Ps1,As,N,P2,Ps2a,Ps2b),
    P2 = p(As,N,X2),
    require(
      xbgf1:assoc_rules(N,X1,X2),
      '~q must admit associativity transformation.',
      [P1]),
    append(Ps2a,[P1|Ps2b],Ps2).

assoc_rules(N,X1,X2) :- assoc_rule1(N,X1,X2).
assoc_rules(N,X1,X2) :- assoc_rule2(N,X1,X2).
assoc_rules(N,X1,X2) :- assoc_rule3(N,X1,X2).

assoc_rule1(
  N,
  ','([n(N),X,n(N)]), 
  ','([n(N),'*'(','([X,n(N)]))])).

assoc_rule2(
  N,
  ','([n(N),X,n(N)]), 
  ','(['*'(','([n(N),X])),n(N)])).

assoc_rule3(
  N,
  ','([n(N),n(N)]), 
  +(n(N))).


%
% p([l(massage)], f, (n(x),n(x)))
% p([l(massageL)], f, (n(x),n(x),n(l)))
% p([l(massageN)], f, (n(x),n(x),n(n)))
%
% Semantics-preserving expression replacement
%

massage(X1,X2,g(Rs,Ps1),g(Rs,Ps3))
 :-
    massage(X1,X2,Ps1,[],[],Ps3).

massageL(X1,X2,L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P,Ps2a,Ps2b),
    massage(X1,X2,[P],Ps2a,Ps2b,Ps3).

massageN(X1,X2,N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    massage(X1,X2,Ps2,Ps2a,Ps2b,Ps3).

massage(X1,X2,Ps2,Ps2a,Ps2b,Ps3)
 :-
     require(
       xbgf1:massage_bothways(X1,X2),
       '~q and ~q are not in massage relation.',
       [X1,X2]),
     stoptd(xbgf1:replace_rules(X1,X2),Ps2,Ps4),
     concat([Ps2a,Ps4,Ps2b],Ps3).

massage_bothways(X1,X2) :- massage_rules(X1,X2), !.
massage_bothways(X1,X2) :- massage_rules(X2,X1), !.

% Deprecated - please use anonymize/deanonymize instead!
massage_rules(s(_,X),X).

massage_rules(?(s(S,X)),s(S,?(X))).
massage_rules(*(s(S,X)),s(S,*(X))).
massage_rules(+(s(S,X)),s(S,+(X))).

%% All possible composition combinations
% ?(...)
massage_rules(?(?(X)),?(X)).
massage_rules(?(+(X)),*(X)).
massage_rules(?(*(X)),*(X)).
% +(...)
massage_rules(+(?(X)),*(X)).
massage_rules(+(+(X)),+(X)).
massage_rules(+(*(X)),*(X)).
% *(...)
massage_rules(*(?(X)),*(X)).
massage_rules(*(+(X)),*(X)).
massage_rules(*(*(X)),*(X)).

%% All possible choice combinations
% true|...
%massage_rules(?(';'([X|L1])),';'([L2])) :- append(L3,L1,L2), length(L3,2),member(X, L3),member(true,L3).

%
% Not general enough but a good explanation of what follows
%
% massage_rules(?(X),';'(L)) :- length(L,2),member(  X, L),member(true,L).
% x? -> x | ε
% massage_rules(?(X),';'(L)) :- length(L,2),member(?(X),L),member(true,L).
% x? -> x? | ε
massage_rules(?(X),';'(L))
 :-
    append(L1,[true|L2],L),
    append(L1,L2,L3),
    normalizeG(';'(L3),Y),
    (
    eqX(X,Y)
    ;
    eqX(?(X),Y)
    ).

% massage_rules(*(X),';'(L)) :- length(L,2),member(+(X),L),member(true,L).
% x* -> x+ | ε
% massage_rules(*(X),';'(L)) :- length(L,2),member(*(X),L),member(true,L).
% x* -> x* | ε
massage_rules(*(X),';'(L))
 :-
    append(L1,[true|L2],L),
    append(L1,L2,L3),
    normalizeG(';'(L3),Y),
    (
    eqX(+(X),Y)
    ;
    eqX(*(X),Y)
    ).

% x|...

%massage_rules(X,';'([s(_,X),s(_,X)])).
% x -> s::x | ...
massage_rules(X,Y)
 :-
    normalizeG(Y,';'(L)),
    listofselectors(X,L).

% massage_rules(*(X),';'(L)) :- length(L,2),member(*(X),L),member(X,L).
% massage_rules(*(X),';'(L)) :- length(L,2),member(*(X),L),member(?(X),L).
massage_rules(*(X),';'(L))
 :-
    append(L1,[*(X)|L2],L),
    append(L1,L2,L3),
    normalizeG(';'(L3),Y),
    (
    eqX(X,Y)
    ;
    eqX(?(X),Y)
    ;
    eqX(+(X),Y)
    ).

% massage_rules(*(X),';'(L)) :- length(L,2),member(?(X),L),member(+(X),L).
massage_rules(*(X),';'(L))
 :-
    append(L1,[+(X)|L2],L),
    append(L1,L2,L3),
    normalizeG(';'(L3),Y),
    eqX(?(X),Y).

% massage_rules(?(X),';'(L)) :- length(L,2),member(?(X),L),member(X,L).
massage_rules(?(X),';'(L))
 :-
    append(L1,[X|L2],L),
    append(L1,L2,L3),
    normalizeG(';'(L3),Y),
    eqX(?(X),Y).

% massage_rules(+(X),';'(L)) :- length(L,2),member(+(X),L),member(X,L).
massage_rules(+(X),';'(L))
 :-
    append(L1,[X|L2],L),
    append(L1,L2,L3),
    normalizeG(';'(L3),Y),
    eqX(+(X),Y).


%% All possible sequential combinations
% massage_rules(*(X),','([*(X),*(X)])).
massage_rules(*(X),Y)
 :-
    normalizeG(Y,','(L)),
    listofthesame(*(X),L).

% massage_rules(+(X),','(L)) :- length(L,2),member(+(X),L),member(?(X),L).
% massage_rules(+(X),','(L)) :- length(L,2),member(+(X),L),member(*(X),L).
massage_rules(+(X),','(L))
 :-
    append(L1,[+(X)|L2],L),
    append(L1,L2,L3),
    normalizeG(','(L3),Y),
    (eqX(?(X),Y);eqX(*(X),Y)).

% massage_rules(+(X),','(L)) :- length(L,2),member(  X, L),member(*(X),L).
massage_rules(+(X),','(L))
 :-
    append(L1,[X|L2],L),
    append(L1,L2,L3),
    normalizeG(','(L3),Y),
    eqX(*(X),Y).

% massage_rules(*(X),','(L)) :- length(L,2),member(*(X),L),member(?(X),L).
massage_rules(*(X),','(L))
 :-
    append(L1,[?(X)|L2],L),
    append(L1,L2,L3),
    normalizeG(','(L3),Y),
    eqX(*(X),Y).

%% Miscellaneous
massage_rules(','([X,?(','([Y,X]))]),','([?(','([X,Y])),X])).
massage_rules(','([X,+(','([Y,X]))]),','([+(','([X,Y])),X])).
massage_rules(','([X,*(','([Y,X]))]),','([*(','([X,Y])),X])).
%% Binary distributivity of optionality
%massage_rules(?(','([?(X),?(Y)])),','([?(X),?(Y)])).
%%massage_rules(?(','([*(X),?(Y)])),','([*(X),?(Y)])).
%massage_rules(?(','([?(X),*(Y)])),','([?(X),*(Y)])).
%massage_rules(?(','([*(X),*(Y)])),','([*(X),*(Y)])).
%massage_rules(?(';'([X,Y])),';'([?(X),?(Y)])).

%% Separator lists
massage_rules(slp(X,Y),','([X,*(','([Y,X]))])).
massage_rules(slp(X,Y),','([*(','([X,Y])),X])).
massage_rules(sls(X,Y),?(','([X,*(','([Y,X]))]))).
massage_rules(sls(X,Y),?(','([*(','([X,Y])),X]))).
massage_rules(sls(X,Y),?(slp(X,Y))).

% We can add a selectable epsilon anywhere
massage_rules(','(L1),','(L2))
 :-
    append(L3,[s(_,true)|L4],L2),
    append(L3,L4,L1).

listofselectors(_,[]).
listofselectors(X,[Y|L]) :- eqX(s(_,X),Y), listofselectors(X,L).

listofthesame(_,[]).
listofthesame(X,[Y|L]) :- eqX(X,Y), listofthesame(X,L).

%
% p([l(permute)], f, n(p))
%
% Permute the body of a production
%

permute(P1,g(Rs,Ps1),g(Rs,Ps5))
 :- 
    P1 = p(As1,N1,X1),
    require(
      X1 = ','(Xs1),
      'Permutation requires a sequence instead of ~q.',
      [X1]),
    findP(Ps1,As1,N1,P2,Ps3,Ps4),
    P2 = p(As1,N1,X2),
    require(
      X2 = ','(Xs2),
      'Permutation requires a sequence instead of ~q.',
      [X2]),
    require(
      xbgf1:permuteXs(Xs1,Xs2),
      'Phrases ~q and ~q must be permutations of each other.',
      [X1,X2]),
    append(Ps3,[P1|Ps4],Ps5).

permuteXs([],[]).
permuteXs([X|Xs1],Xs2)
 :-
    append(Xs2a,[X|Xs2b],Xs2),
    !,
    append(Xs2a,Xs2b,Xs3),
    permuteXs(Xs1,Xs3),
    !.

%
% p([l(anonymize)], f, n(p))
%
% Removes selectors from an existing production.
%  Reverse of deanonymize
%

anonymize(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    unmark(P1,P1u),
    anonymize(P1,P1a),
    findP(Ps1,P1u,Ps1a,Ps1b),
    append(Ps1a,[P1a|Ps1b],Ps2).

anonymize(X,Z) 
 :-
    transform(try(xbgf1:anonymize_rule),X,Y),
    normalizeG(Y,Z),
    require(
      \+ X == Z,
      '~q must contain markers.',
      [X]).

anonymize_rule({s(_,X)},X) :- !.
    
%
% p([l(deanonymize)], f, n(p))
%
% Add selectors to an existing production.
%  Reverse of anonymize
%

deanonymize(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    unmark(P1,P1u),
    anonymize(P1,P1a),
    findP(Ps1,P1a,Ps1a,Ps1b),
    append(Ps1a,[P1u|Ps1b],Ps2).


%
% p([l(abstractize)], f, n(p))
%
% Remove marked terminals from the right hand side of a production.
%  Reverse of concretize
%

abstractize(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    unmark(P1,P2),
    findP(Ps1,P2,Ps1a,Ps1b),
    project(P1,P3),
    transform(try(xbgf1:stripTs_rule),g(Rs,[P2]),g(Rs,[P2nt])),
    transform(try(xbgf1:stripTs_rule),g(Rs,[P3]),g(Rs,[P3nt])),
    normalizeG(P2nt,P4),
    normalizeG(P3nt,P5),
    require(
      P4 == P5,
      'Abstractize only works with marked terminals, use project instead.',
      []),
    append(Ps1a,[P3|Ps1b],Ps2).

%
% p([l(concretize)], f, n(p))
%
% Add marked terminals to the right hand side of a production.
%  Reverse of abstractize
%

concretize(P1,g(Rs,Ps1),g(Rs,Ps2))
 :-
    project(P1,P2),
    findP(Ps1,P2,Ps1a,Ps1b),
    unmark(P1,P3),
    transform(try(xbgf1:stripTs_rule),g(Rs,[P2]),g(Rs,[P2nt])),
    transform(try(xbgf1:stripTs_rule),g(Rs,[P3]),g(Rs,[P3nt])),
    normalizeG(P2nt,P4),
    normalizeG(P3nt,P5),
    require(
      P4 == P5,
      'Concretize only works with marked terminals, use inject instead.',
      []),
    append(Ps1a,[P3|Ps1b],Ps2).

%
% p([l(disappear)], f, n(p))
%
% Make an optional symbol disappear
%

disappear(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    require(
      (collect(xbgf1:collectMarked_rule,P1,[?(_)]);
       collect(xbgf1:collectMarked_rule,P1,[*(_)])),
      '~q does not have an optional part marked.',
      [P1]),
    unmark(P1,P2),
    findP(Ps1,P2,Ps1a,Ps1b),
    project(P1,P3),
    append(Ps1a,[P3|Ps1b],Ps2).

%
% p([l(project)], f, n(p))
%
% Apply projection to the body of a production
%

project(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    unmark(P1,P2),
    findP(Ps1,P2,Ps1a,Ps1b),
    project(P1,P3),
    append(Ps1a,[P3|Ps1b],Ps2).

project(X,Z) 
 :-
    transform(try(xbgf1:project_rule),X,Y),
    normalizeG(Y,Z),
    require(
      \+ X == Z,
      '~q must contain markers.',
      [X]).

project_rule({_},true).


unmark(X,Z)
 :-
    transform(try(xbgf1:unmark_rule),X,Y),
    normalizeG(Y,Z),
    require(
      \+ X == Z,
      '~q must contain markers.',
      [X]).

unmark_rule({X},X).


%
% p([l(rassoc)], f, n(p))
%
% Interpret separator list right-associatively
%

rassoc(P1,G1,G2)
 :-
    assoc(P1,G1,G2).


%
% p([l(removeV)], f, n(p))
% p([l(removeH)], f, n(p))
%
% Remove a production (vertical mode).
% Remove a branch of a choice (horizontal mode).
%

removeV(P1,g(Rs,Ps1),g(Rs,Ps2))
 :-
    findP(Ps1,P1,Ps1a,Ps1b),
    append(Ps1a,Ps1b,Ps2).

removeH(P1,g(Rs,Ps1),g(Rs,Ps2))
 :-
    unmark(P1,P1u),
    removeH(P1,P1r),
    findP(Ps1,P1u,Ps1a,Ps1b),
    append(Ps1a,[P1r|Ps1b],Ps2).

removeH(X,Z) 
 :-
    transform(try(xbgf1:removeH_rules),X,Y),
    normalizeG(Y,Z),
    require(
      \+ X == Z,
      '~q must contain markers.',
      [X]).

removeH_rules(';'(Xs1),';'(Xs2))
 :-
    append(Xs1a,[{_}|Xs1b],Xs1),
    append(Xs1a,Xs1b,Xs2).


%
% p([l(renameL)], f, ','([n(l), n(l)]))
% p([l(renameN)], f, ','([n(n), n(n)]))
% p([l(renameS)], f, ','([?(n(l)), n(s), n(s)]))
% p([l(renameT)], f, ','([n(t), n(t)]))
%
% Rename labels, nonterminals, selectors, and terminals
%

renameL((L1,L2),G1,G2)
 :-
    renameL(L1,L2,G1,G2).

renameL(L1,L2,G1,G2)
 :-
    allLs(G1,Ls),
    require(
       member(L1,Ls),
       'Source name ~q for renaming must not be fresh.',
       [L1]),
    require(
      countocc(L1,Ls,1),
      'Label ~q must be unique.',
      [L1]),
    require(
       (\+ member(L2,Ls)),
       'Target name ~q for renaming must be fresh.',
       [L2]),
    transform(try(xbgf1:renameL_rule(L1,L2)),G1,G2).

renameL_rule(L1,L2,p([l(L1)],N,X),p([l(L2)],N,X)).

renameN((N1,N2),G1,G2)
 :-
    renameN(N1,N2,G1,G2).

renameN(N1,N2,G1,G2)
 :-
    allNs(G1,Ns),
    require(
       member(N1,Ns),
       'Source name ~q for renaming must not be fresh.',
       [N1]),
    require(
       (\+ member(N2,Ns)),
       'Target name ~q for renaming must be fresh.',
       [N2]),
    transform(try(xbgf1:renameN_rules(N1,N2)),G1,G2).

renameN_rules(N1,N2,g(Rs1,Ps),g(Rs2,Ps))
 :-
    append(Rs1a,[N1|Rs1b],Rs1),
    append(Rs1a,[N2|Rs1b],Rs2).
renameN_rules(N1,N2,n(N1),n(N2)).
renameN_rules(N1,N2,p(As,N1,X),p(As,N2,X)).

renameS((S1,S2),G1,G2)
 :-
    renameS([],S1,S2,G1,G2).

renameS([],S1,S2,G1,G2)
 :-
    allSs(G1,Ss),
    require(
       member(S1,Ss),
       'Source name ~q for renaming must not be fresh.',
       [S1]),
    require(
       (\+ member(S2,Ss)),
       'Target name ~q for renaming must be fresh.',
       [S2]),
    transform(try(xbgf1:renameS_rule(S1,S2)),G1,G2).

renameS([L],S1,S2,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P1,Ps2a,Ps2b),
    allSs(Ps1,Ss),
    require(
       member(S1,Ss),
       'Source name ~q for renaming must not be fresh.',
       [S1]),
    require(
       (\+ member(S2,Ss)),
       'Target name ~q for renaming must be fresh.',
       [S2]),
    transform(try(xbgf1:renameS_rule(S1,S2)),P1,P2),
    append(Ps2a,[P2|Ps2b],Ps3).

renameS_rule(S1,S2,s(S1,X),s(S2,X)).

renameT(T1,T2,G1,G2)
 :-
    allTs(G1,Ts),
    require(
       member(T1,Ts),
       'Source name ~q for renaming must not be fresh.',
       [T1]),
    require(
       (\+ member(T2,Ts)),
       'Target name ~q for renaming must be fresh.',
       [T2]),
    transform(try(xbgf1:renameT_rule(T1,T2)),G1,G2).

renameT_rule(T1,T2,t(T1),t(T2)).


%
% p([l(replace)], f, (n(x),n(x)))
% p([l(replaceL)], f, (n(x),n(x),n(l)))
% p([l(replaceN)], f, (n(x),n(x),n(n)))
%
% Unconstrainted expression-level editing
%

replace(X1,X2,g(Rs,Ps1),g(Rs,Ps3))
 :-
    replace(X1,X2,Ps1,[],[],Ps3).

replaceL(X1,X2,L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P,Ps2a,Ps2b),
    replace(X1,X2,[P],Ps2a,Ps2b,Ps3).

replaceN(X1,X2,N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    replace(X1,X2,Ps2,Ps2a,Ps2b,Ps3).

replace(X1,X2,Ps2,Ps2a,Ps2b,Ps3)
 :-
     replace_traversal(X1,X2,Ps2,Ps4),
     concat([Ps2a,Ps4,Ps2b],Ps3).

replace_traversal(X1,X2,X3,X4)
 :-
    stoptd(xbgf1:replace_rules(X1,X2),X3,X4).

replace_rules(X1,X2,X3,X2)
 :-
    eqX(X1,X3),
    !.

% Find sequence of interest as subsequence

replace_rules(X1,Y1,','(Xs2),','(Xs3))
 :-
    X1 = ','(Xs1),
    append(Xs1a,Xs1b,Xs2),
    append(Xs1c,Xs1d,Xs1b),
    eqX(','(Xs1),','(Xs1c)),
    replace_traversal(X1,Y1,','(Xs1a),X1a),
    replace_traversal(X1,Y1,','(Xs1d),X1d),
    concat([[X1a],[Y1],[X1d]],Xs3),
    !.

% Incomplete but order-preserving replacement for choices

replace_rules(X1,Y1,';'(Xs2),';'(Xs3))
 :-
    X1 = ';'(Xs1),
    append(Xs1a,Xs1b,Xs2),
    append(Xs1c,Xs1d,Xs1b),
    eqX(';'(Xs1),';'(Xs1c)),
    replace_traversal(X1,Y1,';'(Xs1a),X1a),
    replace_traversal(X1,Y1,';'(Xs1d),X1d),
    concat([[X1a],[Y1],[X1d]],Xs3),
    !.

% Complete but non-order-preserving replacement for choices

replace_rules(';'(Xs1),Y1,';'(Xs2),';'([Y1|Xs3]))
 :-
    subsetXs(Xs1,Xs2,Xs3),
    !.


%
% p([l(reroot)], f, *(n(n)))
%
% Assign new roots to the grammar
%

reroot(Rs,g(_,Ps),g(Rs,Ps))
 :- 
    allNs(Ps,Ns1),
    subtract(Rs,Ns1,Ns2),
    require(
       subset(Rs,Ns1),
       'Nonterminal(s) ~q not found.', 
       [Ns2]).


%
% p([l(narrow)], f, (n(x),n(x)))
% p([l(narrowN)], f, (n(x),n(x),n(n)))
% p([l(narrowL)], f, (n(x),n(x),n(l)))
%
% Decrease generated language by expression replacement
%

narrow(X1,X2,g(Rs,Ps1),g(Rs,Ps3))
 :-
    narrow(X1,X2,Ps1,[],[],Ps3).

narrowN(X1,X2,N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    narrow(X1,X2,Ps2,Ps2a,Ps2b,Ps3).

narrowL(X1,X2,L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P,Ps2a,Ps2b),
    narrow(X1,X2,[P],Ps2a,Ps2b,Ps3).

narrow(X1,X2,Ps2,Ps2a,Ps2b,Ps3)
 :-
     require(
       xbgf1:narrow_rules(X1,X2),
       '~q and ~q are not in narrowing relation.',
       [X1,X2]),
     stoptd(xbgf1:replace_rules(X1,X2),Ps2,Ps4),
     concat([Ps2a,Ps4,Ps2b],Ps3).

narrow_rules(a,_).
narrow_rules(*(X),+(X)).
narrow_rules(*(X),?(X)).
narrow_rules(*(X),X).
%narrow_rules(+(X),?(X)).
narrow_rules(+(X),X).
narrow_rules(?(X),X).
%narrow_rules(';'(L),X) :- length(L,2),member(X,L),member(true,L).


%
% p([l(abridge)], f, n(p))
%
% Skip a reflexive chain production
%

abridge(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    require(
      P1 = p(_,N,n(N)),
      'Production ~q cannot be abridged.',
      [P1]),
    require(
      append(Ps1a,[P1|Ps1b],Ps1),
      'Production ~q not found.',
      [P1]),
    append(Ps1a,Ps1b,Ps2).

%
% p([l(detour)], f, n(p))
%
% Introduce a reflexive chain production
%

detour(P1,g(Rs,Ps1),g(Rs,Ps2))
 :- 
    require(
      P1 = p(_,N,n(N)),
      'Production ~q is not a reflexive chain production.',
      [P1]),
    usedNs(Ps1,Uses1),
    require(
      member(N,Uses1),
      'Nonterminal ~q must be used.',
      [N]),
	append(Ps1,[P1],Ps2).

%
% p([l(split)], f, ','([n(n), n(n)]))
%
% Nonterminal splitting, a form of "de-unification"
%
% TODO: works only on labels, should eventually be implemented for all kinds of scopes/contexts
%
split(N1,Ps0,Ls1,g(Rs,Ps1),g(Rs,Ps2))
 :-
    allNs(g(Rs,Ps1),Ns1),
    definedNs(g([],Ps0),[N0]),
	require(
       (member(N1,Ns1)),
       'Source name ~q for splitting must not be fresh.',
       [N1]),
	require(
       (\+ member(N0,Ns1)),
       'Target name ~q for splitting must be fresh.',
       [N0]),
    changelhs(N0,N1,Ps0,Ps0p),
    removeprods(Ps0p,g(Rs,Ps1),g(Rs,Ps3)),
    import(Ps0,g(Rs,Ps3),g(Rs,Ps4)),
    replaceLs(n(N1),n(N0),Ls1,g(Rs,Ps4),g(Rs,Ps2)).

changelhs(_,_,[],[]).
changelhs(N1,N2,[P1|Ps1],[P2|Ps2])
 :- 
    P1 = p(L,N3,X),
    (
      N1 == N3,
	  P2 = p(L,N2,X)
	;
	  P2 = p(L,N3,X)
	),
    changelhs(N1,N2,Ps1,Ps2).

removeprods([],G1,G1).
removeprods([P0|Ps0],g(Rs,Ps1),g(Rs,Ps3)) :- removeV(P0,g(Rs,Ps1),g(Rs,Ps2)), removeprods(Ps0,g(Rs,Ps2),g(Rs,Ps3)).

replaceLs(_,_,[],G1,G1).
replaceLs(X1,X2,[L1|Ls],g(Rs,Ps1),g(Rs,Ps3))
 :- 
    replaceL(X1,X2,L1,g(Rs,Ps1),g(Rs,Ps2)),
    replaceLs(X1,X2,Ls,g(Rs,Ps2),g(Rs,Ps3)).

%
% p([l(stripL)], f, n(l))
% p([l(stripLs)], f, true)
% p([l(stripS)], f, n(s))
% p([l(stripSs)], f, true)
% p([l(stripT)], f, n(t))
% p([l(stripTs)], f, true)
%
% Strip labels, selectors, and terminals
%

stripL(L,G1,g(Rs,Ps2))
 :-
    allLs(G1,Ls),
    require(
      member(L,Ls),
      'Label ~q must be in use.',
      [L]),
    require(
      countocc(L,Ls,1),
      'Label ~q must be unique.',
      [L]),
    G1 = g(Rs,Ps1),
    maplist(xbgf1:stripL_rules(L),Ps1,Ps2).

stripLs(g(Rs,Ps1),g(Rs,Ps2))
 :-
    maplist(xbgf1:stripLs_rule,Ps1,Ps2).

stripL_rules(L,p([l(L)],N,X),p([],N,X)) :- !.
stripL_rules(_,P,P).

stripLs_rule(p(_,N,X),p([],N,X)).


stripS(S,G1,g(Rs,Ps2))
 :-
    allSs(G1,Ss),
    require(
      member(S,Ss),
      'Selector ~q must be in use.',
      [S]),
    G1 = g(Rs,Ps1),
    transform(try(xbgf1:stripS_rule(S)),Ps1,Ps2).

stripSs(g(Rs,Ps1),g(Rs,Ps2))
 :-
    transform(try(xbgf1:stripSs_rule),Ps1,Ps2).

stripS_rule(S,s(S,X),X).

stripSs_rule(s(_,X),X).

stripTs(G1,G2)
 :-
    transform(try(xbgf1:stripTs_rule),G1,G2).

stripT(T,G1,G2) 
 :-
    allTs(G1,Ts),
    require(
      member(T,Ts),
      'The terminal ~q must occur.',
      [T]),
    transform(try(xbgf1:stripT_rule(T)),G1,G2).

stripT_rule(T,t(T),true).

stripTs_rule(t(_),true).


%
% p([l(unchain)], f, n(p))
%
% Unchain a production -- a restricted unfold
%

unchain(P1,g(Rs,Ps1),g(Rs,Ps4))
 :-
    findP(Ps1,P1,Ps1a,Ps1b),
    require(
      P1 = p(As1,N1,n(N2)),
      'Production ~q must be chain production.',
      [P1]),
    append(Ps1a,Ps1b,Ps2),
    def(Ps2,N2,N2Ps),
    [p(_,_,X)] = N2Ps,
    require(
       (\+ member(N2,Rs) ),
       'Nonterminal ~q must not be root.',
       [N2]),
    append(Ps1a,[p(As2,N1,X)|Ps1b],Ps3),
    (
      As1 = [l(_)] ->
          As2 = As1
        ; (
            allLs(Ps2,Ls),
            require(
              ( \+ member(N2,Ls) ),
              '~q must not be a label in use.',
              [N1]),
            As2 = [l(N2)] 
          )
    ),
    splitN1(Ps3,N2,_,Ps3a,Ps3b),
    append(Ps3a,Ps3b,Ps4),
    allNs(Ps4,Ns),
    require(
      (\+ member(N2,Ns) ),
      'Nonterminal ~q must occur exactly once.',
      [N2]).


%
% p([l(undefine)], f, n(n))
%
% Undefine a nonterminal, i.e., remove all productions
%
undefine([],g(Rs1,Ps1),g(Rs1,Ps1)).
undefine([N|Ns],g(Rs1,Ps1),g(Rs3,Ps3))
 :-
    undefine1(N,g(Rs1,Ps1),g(Rs2,Ps2)),
    undefine(Ns,g(Rs2,Ps2),g(Rs3,Ps3)).

undefine1(N,g(Rs1,Ps1),g(Rs2,Ps2))
 :-
    definedNs(Ps1,Defined),
    require(
       member(N,Defined),
       'Nonterminal ~q must be defined.',
       [N]),
    filter(nonunifiable(N),Rs1,Rs2),
    filter(nonunifiable(p(_,N,_)),Ps1,Ps2),
    usedNs(Ps2,Used),
    require(
       member(N,Used),
       'Nonterminal ~q must be used.',
       [N]).


%
% p([l(unfold)], f, n(n))
% p([l(unfoldN)], f, (n(n),n(n)))
% p([l(unfoldL)], f, (n(n),n(l)))
%
% Unfold occurrences of a nonterminal to its defining expression
%

unfold(N1,g(Rs,Ps1),g(Rs,Ps3))
 :-
    unfold(N1,Ps1,Ps1,[],[],Ps3).

unfoldN(N1,N2,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N2,Ps2,Ps2a,Ps2b),
    unfold(N1,Ps1,Ps2,Ps2a,Ps2b,Ps3).

unfoldL(N1,L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P2,Ps2a,Ps2b),
    unfold(N1,Ps1,[P2],Ps2a,Ps2b,Ps3).

unfold(N1,Ps1,Ps2,Ps2a,Ps2b,Ps4)
 :-
    splitN1(Ps1,N1,P1,_,_),
    P1 = p(_,_,X),
    ( append(Ps2c,[P1|Ps2d],Ps2) ->
        ( 
          stoptd(xbgf1:replace_rules(n(N1),X),Ps2c,Ps2e),
          stoptd(xbgf1:replace_rules(n(N1),X),Ps2d,Ps2f),
          append(Ps2e,[P1|Ps2f],Ps3)
        )
      ; stoptd(xbgf1:replace_rules(n(N1),X),Ps2,Ps3)
    ),
    concat([Ps2a,Ps3,Ps2b],Ps4).


%
% p([l(unite)], f, ','([n(n), n(n)]))
%
% Confusing renaming, also called "unification"
%

unite(N1,N2,G1,G2)
 :-
    allNs(G1,Ns),
    require(
       ( member(N1,Ns), member(N2,Ns) ),
       'Both ~q and ~q must not be fresh.',
       [N1,N2]),
    transform(try(xbgf1:renameN_rules(N1,N2)),G1,G2).

%
% p([l(equate)], f, ','([n(n), n(n)]))
%
% Merging two identically defined nonterminals
%
equate(N1,N2,g(Rs1,Ps1),g(Rs2,Ps2))
 :-
    splitN(Ps1,N1,N1Ps1,N1Ps1a,N1Ps1b),
    def(Ps1,N2,N2Ps),
    xbgf1:renameN(N1,N2,g(Rs1,N1Ps1),g(_,N1Ps2)),
    require(
		(xbgf1:checkforidentity(N1Ps2,N2Ps)),
		'Definitions of nonterminals ~q and ~q must be equal.',
		[N1,N2]),
    concat([N1Ps1a,N1Ps1b],N1Ps3),
    transform(try(xbgf1:renameN_rules(N1,N2)),g(Rs1,N1Ps3),g(Rs2,Ps2)).

checkforidentity([],[]).
checkforidentity([P1|Ps1],Ps2)
 :-
    removeproduction(P1,Ps2,Ps3),
	checkforidentity(Ps1,Ps3).

removeproduction(P1,[P2|Ps2],Ps2) :- eqP(P1,P2).
removeproduction(P1,[P2|Ps2],[P2|Ps3]) :- removeproduction(P1,Ps2,Ps3).

%
% p([l(verticalL)], f, n(l))
% p([l(verticalN)], f, n(n))
%
% Turn top-level choices into multiple productions
%

verticalL(L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P,Ps2a,Ps2b),
    vertical([P],Ps2a,Ps2b,Ps3).

verticalN(N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    vertical(Ps2,Ps2a,Ps2b,Ps3).

vertical(Ps1,Ps1a,Ps1b,Ps4)
 :-
    maplist(xbgf1:vertical_p,Ps1,Pss2),
    concat(Pss2,Ps2),
    allLs(Ps2,Ls1),
    doubles(Ls1,Ls2),
    require(
      Ls2 == [],
      'Outermost selectors ambigious ~q.',
      [Ls2]),
    concat([Ps1a,Ps1b],Ps3),
    allLs(Ps3,Ls3),
    intersection(Ls2,Ls3,Ls4),
    require(
      Ls4 == [],
      'Outermost selectors clash with labels ~q.',
      [Ls4]),
    concat([Ps1a,Ps2,Ps1b],Ps4).

vertical_p(p(_,N,';'(Xs)),Ps)
 :-
    maplist(xbgf1:vertical_x(N),Xs,Ps).

vertical_p(P,[P])
 :-
    \+ P = p(_,_,';'(_)).

vertical_x(N,s(S,X),p([l(S)],N,X)).

vertical_x(N,X,p([],N,X))
 :-
    \+ X = s(_,_).

%
% p([l(widen)], f, (n(x),n(x)))
% p([l(widenN)], f, (n(x),n(x),n(n)))
% p([l(widenL)], f, (n(x),n(x),n(l)))
%
% Increase generated language by expression replacement
%

widen(X1,X2,g(Rs,Ps1),g(Rs,Ps3))
 :-
    widen(X1,X2,Ps1,[],[],Ps3).

widenN(X1,X2,N,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitN(Ps1,N,Ps2,Ps2a,Ps2b),
    widen(X1,X2,Ps2,Ps2a,Ps2b,Ps3).

widenL(X1,X2,L,g(Rs,Ps1),g(Rs,Ps3))
 :-
    splitL(Ps1,L,P,Ps2a,Ps2b),
    widen(X1,X2,[P],Ps2a,Ps2b,Ps3).

widen(X1,X2,Ps2,Ps2a,Ps2b,Ps3)
 :-
     require(
       xbgf1:narrow_rules(X2,X1),
       '~q and ~q are not in widening relation.',
       [X1,X2]),
     stoptd(xbgf1:replace_rules(X1,X2),Ps2,Ps4),
     concat([Ps2a,Ps4,Ps2b],Ps3).


%
% p([l(yaccify)], f, *(n(p)))
%
% Expand EBNF-based regular expression operator via BNF encoding
%

yaccify(Ps0,g(Rs,Ps1),g(Rs,Ps3))
 :-
    Ps0 = [P1,P2],
    P1 = p(_,N,_),	
    P2 = p(_,N,_),
    splitN1(Ps1,N,P3,Ps2a,Ps2b),
    require(
      xbgf1:deyaccify_rules(N,[P1,P2],P3),
      '~q and ~q not suitable as yaccification of ~q.',
      [P1,P2,P3]),
    append(Ps2a,[P1,P2|Ps2b],Ps3).

downgrade(P1,P2,g(Rs,Ps1),g(Rs,Ps2))
 :-
    require(
      collect(xbgf1:collectMarked_rule,P1,[n(N)]),
      '~q does not have a single nonterminal marked.',
      [P1]),
    require(
      P2 = p(_,N,X),
      '~q and ~q do not agree on nonterminal.',
      [P1,P2]),
    unmark(P1,P3),
    findP(Ps1,P3,Ps1a,Ps1b),
    findP(Ps1,P2,_,_),
    replaceMarker(X,P1,P4),
    append(Ps1a,[P4|Ps1b],Ps2).
        
collectMarked_rule({X},[X]).

replaceMarker(Z,X,Y) 
 :-
    stoptd(xbgf1:replaceMarker_rule(Z),X,Y).

replaceMarker_rule(Z,{_},Z).

upgrade(P1,P2,g(Rs,Ps1),g(Rs,Ps2))
 :-
    require(
      collect(xbgf1:collectMarked_rule,P1,[n(N)]),
      '~q does not have a single nonterminal marked.',
      [P1]),
    require(
      P2 = p(_,N,X),
      '~q and ~q do not agree on nonterminal.',
      [P1,P2]),
    replaceMarker(X,P1,P3),
    normalizeG(P3,P4),
    findP(Ps1,P4,Ps1a,Ps1b),
    findP(Ps1,P2,_,_),
    unmark(P1,P5),
    append(Ps1a,[P5|Ps1b],Ps2).
