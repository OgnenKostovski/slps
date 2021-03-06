%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Map XSD to Prolog-based representation of BGF %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wiki: XSD2BGF


%
% Declare a namespace for XML Schema
%

:- multifile sxmlns/2.

sxmlns(xsd,'http://www.w3.org/2001/XMLSchema').
sxmlns(xsi,'http://www.w3.org/2001/XMLSchema-instance').


%
% Load an XSD file
%

loadXsd(File,(S,G,SGs))
 :-
    % Load schema and check schema element
    format('Loading XSD file ~q.~n',[File]),
    load_structure(File, Content, [dialect(xmlns)]),
    member(S,Content),
    S =.. [element|_],
    self(name(xsd:schema),S),
    noXmlnssBelow(S),

    % Derive dir of schema file
    ( 
      name(File,FileS),
      append(DirS,[0'/|BaseS],FileS),
      \+ member(0'/,BaseS),
      name(Dir,DirS),
      !
    ;
      Dir = '.'
    ),

    % Import
    children(name(xsd:import),S,Is),
    maplist(xsdImport(Dir),Is,SGs),

    % Derive grammar
    gFromSchema(S,G),
    !.


%
% Realize an import
%

xsdImport(Dir,I,SG)
 :-
    attribute(schemaLocation,I,Base),
    name(Dir,DirS),
    name(Base,BaseS),
    append(DirS,[0'/|BaseS],FileS), % '
    name(File,FileS),
    loadXsd(File,SG),
    !.


%
% Derive a grammar from a schema
%

gFromSchema(S,G2) 
 :-    
   
    % Compute roots
    children(name(xsd:element),S,Es),
    maplist(rFromElement,Es,Rs1),

    % Derive productions from global components
    children(element,S,Zs),
    maplist(psFromGlobal(S),Zs,Pss),
    concat(Pss,Ps1),

    % Check that no clashes happen
    maplist(definedN,Ps1,Ns1),
    doubles(Ns1,Ns2),
    require(
      Ns2 == [],
      'Names ~w clash after merging symbol namespaces.',
      [Ns2]),

    % Put together and normalize grammar
    G1 = g(Rs1,Ps1),
    normalizeG(G1,G2),
    !.


%
% Derive a root from a root-element declaration
%

rFromElement(E,N)
 :-
    attribute(name,E,N),
    !.


%
% Derive productions from a global XSD component
%

psFromGlobal(S,Z1,Ps)
 :-
    ( 
      self(name(xsd:element),Z1),
      !,
      pFromElement(S,Z1,P),
      Ps = [P]
    ;
      self(name(xsd:complexType),Z1),
      !,
      pFromCType(S,Z1,P),
      Ps = [P]
    ;
      self(name(xsd:group),Z1),
      !,
      pFromGroup(S,Z1,P),
      Ps = [P]
    ;
      self(name(xsd:simpleType),Z1),
      !,
      pFromSType(S,Z1,P),
      Ps = [P]
    ;
      self(name(xsd:include),Z1),
      !,
      require(
        fail,
        'XSD includes unsupported.',
        [])
    ;
      self(name(xsd:attribute),Z1),
      !,
      require(
        fail,
        'Global attribute declarations unsupported.',
        [])
    ;
      self(name(xsd:attributeGroup),Z1),
      !,
      require(
        fail,
        'Attribute groups unsupported.',
        [])
    ;
      Ps = []
    ),
    !.


%
% Derive a production from a root-element declaration
%

pFromElement(S,E,p([],N,X))
 :-
    attribute(name,E,N),
    ( 
      attribute(type,E,T1),
      xFromTypeRef(S,T1,X)
    ;
      child(name(xsd:complexType),E,T),
      !,
      xFromCType(S,T,X)
    ;
      child(name(xsd:simpleType),E,T),
      !,
      xFromSType(S,T,X)
    ;
      X = true
    ),
    !.


%
% Derive a production from a complex-type definition
%

pFromCType(S,T1,p([],N,X2))
 :-
    attribute(name,T1,N),
    attribute(abstract,T1,false,A),
    xFromCType(S,T1,X1),
    (
      A == true,
      require(
        X1 == true,
        'Non-empty abstract complex type ~q unsupported.',
        [N]),
      children(call(typeWithBase(N)),S,Ts),
      maplist(nFromType,Ts,Ns),
      X2 = ';'(Ns)
    ;
      A == false,
      X2 = X1
    ),
    !.


%
% Derive a production from a group definition
%

pFromGroup(S,GR,p([],N,X))
 :-
    attribute(name,GR,N),
    xFromCType(S,GR,X),
    !.


%
% Derive an expression from a complex type-based content model
%

xFromCType(S,T1,X3)
 :-
    (
      child(name(xsd:complexContent),T1,T2) ->
          ( require(
              child(name(xsd:extension),T2,T3),
              'Complex-type restriction unsupported.',
              []),
            attribute(base,T3,B1),    
            normalizeQName(S,B1,B2),
            require(
              lookupGlobal(S,xsd:complexType,B2,B3),
              'Cannot locate base type ~q.',
              [B2]),
            require(
              attribute(abstract,B3,true),
              'Concrete base type ~q unsupported.',
              [B2])
          )
        ; T3 = T1
    ),
    ( child( (name(xsd:sequence);
              name(xsd:choice);
              name(xsd:all);
              name(xsd:group)), T3, T4),
      !,
      xFromModel(S,T4,X1)
    ; 
      X1 = true 
    ),
    attribute(mixed,T1,false,Mixed),
    (
      Mixed == false ->
          X2 = X1
        ; require(
            mixType(S,X1,X2),
            'Form of mixed content ~q unsupported.',
            [X1])
    ),
    addAttributes(S,T3,X2,X3),
    !.


%
% Add attributes if any to a content model
%

addAttributes(S,T3,X1,X2)
 :-
    children(name(xsd:attribute),T3,As),
    maplist(xFromAttribute(S),As,Xs),
    normalizeG_algebraically(','([X1,','(Xs)]),X2),
    !.

xFromAttribute(S,A,X3)
 :-
    attribute(name,A,N),
    attribute(type,A,T1),
    xFromTypeRef(S,T1,X1),
    X2 = s(N,X1),
    attribute(use,A,required,U),
    ( U == required ->
          X3 = X2
        ; X3 = '?'(X2)
    ),
    !.


%
% Enhance an expression to reflect mixed content
%

mixType(_,'*'(a),'*'(';'([a,v(string)]))).
mixType(S,'*'(n(N)),'*'(';'([n(N),v(string)])))
 :-
    lookupGlobal(S,xsd:group,N,G),
    !,
    child( (name(xsd:sequence);
            name(xsd:choice);
            name(xsd:all)),G,C),
    flatChoice(C),
    !.
mixType(_,'*'(n(N)),'*'(';'([n(N),v(string)])))
 :-
    !.
mixType(_,'*'(s(S,n(N))),'*'(';'([s(S,n(N)),v(string)])))
 :-
    !.
mixType(_,'*'(s(S,v(T))),'*'(';'([s(S,v(T)),v(string)])))
 :-
    !.

%
% Test a composite to be a flat choice
% That is:
%  - It is a choice.
%  - There are no non-default occurs constraints.
%  - All components are required element declarations.
%

flatChoice(C)
 :-
    self(name(xsd:choice),C),
    defaultOccurrence(C),  
    children(element,C,Kids),
    maplist(flatChoiceComponent,Kids),
    !.

flatChoiceComponent(C)
 :-
    self(name(xsd:element),C),
    defaultOccurrence(C),  
    !.

defaultOccurrence(X)
 :-
    attribute(minOccurs,X,'1',Min),
    attribute(maxOccurs,X,'1',Max),
    Min == '1',
    Max == '1',
    !.


%
% Test the complex type to be an extension of N
%

typeWithBase(N,T)
 :- 
    self(name(xsd:complexType),T),
    children(name(xsd:complexContent),T,[T1]),
    children(name(xsd:extension),T1,[T2]),
    attribute(base,T2,N),
    !.


%
% Construct a nonterminal reference from a type
%

nFromType(T,n(N)) 
 :-
    attribute(name,T,N),
    !.


%
% Map content model to grammar expression
%

xFromModel(S,M,X)
 :-
    xFromComposite(S,sequence,',',M,X),
    !.

xFromModel(S,M,X)
 :-
    xFromComposite(S,choice,';',M,X),
    !.

xFromModel(S,M,X)
 :-
    xFromComposite(S,all,',',M,X),
    !.

xFromModel(_,M,a)
 :-
    self(name(xsd:any),M),
    !.

xFromModel(S,M,X3)
 :-
    self(name(xsd:element),M),
    !,
    ( 
      %
      % Do not confuse s(e1,e2)* with s(e1,e2*)!
      %
      attribute(name,M,N),
      (
        attribute(type,M,T1),
        !,
        xFromTypeRef(S,T1,X1)
      ;
        child(name(xsd:complexType),M,T),
        !,
        xFromCType(S,T,X1)
      ;
        child(name(xsd:simpleType),M,T),
        !,
        xFromSType(S,T,X1)
      ;
        X1 = a
      ),
      X2 = s(N,X1)
    ;
      attribute(ref,M,N1),
      xFromTypeRef(S,N1,X2)
    ),
    xFromOccurs(M,X2,X3),
    !.

xFromModel(S,M,X)
 :-
    self(name(xsd:group),M),
    attribute(ref,M,N1),
    normalizeQName(S,N1,N2),
    xFromOccurs(M,n(N2),X),
    !.


%
% Factored commonalities of sequence, choice (and all)
%

xFromComposite(S,C,F,M,X)
 :-
    self(name(xsd:C),M),
    children(element,M,Ms),
    ( 
      Ms = [M1] -> 
        xFromModel(S,M1,X1)
      ; ( maplist(xFromModel(S),Ms,Xs), X1 =.. [F,Xs] )
    ),
    xFromOccurs(M,X1,X),
    !.


%
% Translate min/maxOccurs into regexp forms
%

xFromOccurs(M,X1,X2)
 :-
    attribute(minOccurs,M,'1',Min),
    attribute(maxOccurs,M,'1',Max1),
    once((
       Max1 == '1', Max2 = Max1
     ; Max1 == unbounded, Max2 = unbounded
     ; Max2 = unbounded
    )),
    (
       Min == '1', Max2 == '1', X2 = X1
     ; Min == '0', Max2 == '1', X2 = '?'(X1)
     ; Min == '0', Max2 == unbounded, X2 = '*'(X1)
     ; Min == '1', Max2 == unbounded, X2 = '+'(X1)
    ),
    !.


%
% Derive a production from a simple-type definition
%

pFromSType(S,T,p([],N,X))
 :-
    attribute(name,T,N),
    xFromSType(S,T,X).


%
% Derive an expression from a complex type-based content model
%

xFromSType(S,T,X)
 :-
    child(name(xsd:restriction),T,R),       
    children(name(xsd:enumeration),R,Es),
    ( \+ Es == [] ->
          (
            maplist(attribute(value),Es,Vs),
            maplist(xFromEnumeration,Vs,Xs),
            X = ';'(Xs)
          )
        ;
          (
            attribute(base,R,N),
            xFromTypeRef(S,N,X)
          )
    ),
    !.

xFromEnumeration(V,s(V,true)).


%
% Map type reference to expression
%

xFromTypeRef(S,QN,v(N2))
 :-
    qname(QN,Pfx,N1),
    dxmlns(S,Pfx,Ns),
    sxmlns(xsd,Ns),
    require(
      member(N1,[anyURI,'ID','IDREF',int,string,token]),
      'Cannot handle XSD type ~q.',
      [N1]
      ),
    mapXsdSimpleType(N1,N2),
    !.

xFromTypeRef(S,N1,n(N2))
 :-
    normalizeQName(S,N1,N2),
    !.

mapXsdSimpleType(X,X) :- member(X,[int]),!.
mapXsdSimpleType(_,string).


%
% Normalize a qualified name
%

normalizeQName(S,N1,N2) 
 :-
    ( qname(N1,Pfx,UQN) -> 
          (
            attribute(targetNamespace,S,Tns),
            dxmlns(S,Pfx,Ns),
            ( Tns == Ns ->
                  N2 = UQN
                ; N2 = N1
            )
          )
        ; N2 = N1
    ),
    !.


%
% Qualify a name to belong into the XSD namespace
%

xsdQName(S,N,QName)
 :-
    sxmlns(xsd,Ns),
    dxmlns(S,Pfx,Ns),
    concat_atom([Pfx,':',N],QName),
    !.


%
% Look up a global of a given kind by name
%

lookupGlobal(S,K,N,G)
 :-
    children(name(K),S,Gs),
    member(G,Gs),
    attribute(name,G,N),
    !.


%
% Compute transitive closure of schema
%

completeXsd((S1,G1,SGs),G2)
 :-
    usedNs(G1,Uses1),
    filter(qname,Uses1,Uses2),   
    maplist(qname2pfx,Uses2,Pfxs1),
    list_to_set(Pfxs1,Pfxs2),
    maplist(dxmlns(S1),Pfxs2,Nss1),
    zip(Pfxs2,Nss1,Imports),
    accum(uqImportXsd(SGs),Imports,G1,G2).

uqImportXsd(SGs1,(Pfx,Ns),G1,G4)
 :-
    member(SG1,SGs1),
    SG1 = (S1,_,_),
    attribute(targetNamespace,S1,Ns),
    transform(try(delpfx_rules(Pfx)),G1,G2),
    definedNs(G2,Defined1),
    completeXsd(SG1,G3),
    definedNs(G3,Defined2),
    intersection(Defined1,Defined2,Defined3),
    require(
      ( Defined3 == [] ),
      'XSD import with clashing unqualified names ~q.',
      [Defined3]),
    G2 = g(Rs1,Ps1),
    G3 = g(Rs2,Ps2),
    union(Rs1,Rs2,Rs3),
    append(Ps1,Ps2,Ps3),
    G4 = g(Rs3,Ps3),
    !.

delpfx_rules(Pfx,g(Rs1,Ps),g(Rs2,Ps))
 :-
    maplist(delpfx(Pfx),Rs1,Rs2).

delpfx_rules(Pfx,p(As,N1,X),p(As,N2,X))
 :-
    delpfx(Pfx,N1,N2).

delpfx_rules(Pfx,n(N1),n(N2))
 :-
    delpfx(Pfx,N1,N2).
