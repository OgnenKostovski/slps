term(var(X)) :- variable(X).
term(app(T1,T2)) :- term(T1), term(T2).
term(lam(X,T)) :- variable(X), term(T).

% Variables are Prolog atoms and numbers
variable(X) :- atom(X).
variable(X) :- number(X).

