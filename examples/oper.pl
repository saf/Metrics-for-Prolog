% Definiowanie operatorow pozycyjnych

% op(Pierwszenstwo, Typ, ListaNazw).

%        lewe     zadne    prawe
% pref     -        fx       fy
% inf     yfx      xfx      xfy
% post    yf       xf        -

:- op(100, xfx, ['#', '.']).

lista(nil).
lista(_.A) :- lista(A).

