% dziecko(Dziecko, Matka, Ojciec).

dziecko(jas, ewa, jan).
dziecko(ewa, hela, stefan).
dziecko(jan, gloria, pankracy).
dziecko(felicja, hela, stefan).
dziecko(malgosia, ewa, jan).
dziecko(hela, rudolfina, robert).
dziecko(basia, ewa, wojtek).
dziecko(ola, heike, joseph).
dziecko(ala, ola, joseph).
dziecko(pankracy, zocha, stach).

% rodzenstwo rodzone:
rodzenstwo(X, Y) :- dziecko(X, M, O), dziecko(Y, M, O).

% matka(Dziecko, Matka).
matka(D, M) :- dziecko(D, M, _).

% rodzic(Dziecko, Ojciec).
ojciec(D, O) :- dziecko(D, _, O).

% rodzic(Dziecko, Rodzic).
rodzic(Dziecko, Rodzic) :- matka(Dziecko, Rodzic).
rodzic(Dziecko, Rodzic) :- ojciec(Dziecko, Rodzic).

% dziadek(Wnuk, Dziadek).
dziadek(W, Dz) :- rodzic(W, R), ojciec(R, Dz).

% przodek(Potomek, Przodek).
przodek(Desc, Anc) :- rodzic(Desc, Anc).
przodek(Desc, Anc) :- przodek(Par, Anc), rodzic(Desc, Par).

przodek2(Desc, Anc) :- rodzic(Desc, Anc).
przodek2(Desc, Anc) :- przodek(Desc, X), przodek(X, Anc).
