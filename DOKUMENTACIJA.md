# Algoritamska glazbena kompozicija s genetskim algoritmima i zadovoljenjem ograničenja

**Autori:** Matej Abramović (0303090408), Loris Lukić (0303090567), Daniel Vorić (0303096417)

---

## Sadržaj

1. [Uvod](#uvod)
2. [Cilj i glavni naputci](#cilj-i-glavni-naputci)
3. [Biblioteke](#biblioteke)
4. [Arhitektura projekta](#arhitektura-projekta)
5. [Kako koristiti](#kako-koristiti)
6. [Metodologija](#metodologija)
7. [Rezultati](#rezultati)
8. [Zaključak](#zaključak)

---

## Uvod

Algoritamska glazbena kompozicija je polje koje kombinira teoriju glazbe, računalnu znanost i matematiku. Ovim projektom istražujemo primjenu genetskih algoritama i SMT solvera (zadovoljenja ograničenja) za automatsku generaciju glazbenih skladbi u Haskellu.

Genetski algoritmi simuliraju prirodnu evoluciju populacije glazbenih fraza kako bi pronašli optimalne skladbe. S druge strane, zadovoljenje ograničenja osigurava da generirane melodije poštuju glazbena pravila kao što su tonalitet, ritam i harmonija.

Kombiniranjem ova dva pristupa, sustav generira glazbene skladbe koje su istovremeno estetski zadovoljavajuće i teorijski ispravne. Konačni rezultati se izvoze kao MIDI datoteke za reprodukciju u bilo kojem glazbenom programu.

---

## Cilj i glavni naputci

### Cilj

Istraživati primjenu genetskih algoritama za evoluciju glazbenih skladbi kroz procese slične prirodnoj selekciji. Implementirati SMT solver za osiguravanje skladanja u skladu s glazbenim ograničenjima (npr. tonalitet). Zatim kombinirati oba pristupa za poboljšanu kvalitetu generirane glazbe. Na kraju, evaluirati performanse i kvalitetu rezultata u odnosu na pojedinačne pristupe

### Glavni naputci

Tradicionalne metode skladanja zahtijevaju muzikalnu obuku i kreativnost. Ovaj projekt istražuje kako računalo može automatski generirati glazbu koja: poštuje glazbena pravila i ograničenja, ima koherentnu strukturu i melodiju, može služiti kao inspiracija kompozitorima ili kao samostalni kompozitacijski alat i prilagođava se različitim glazbenim stilovima i tonalitetima

---

## Biblioteke

### Haskell ekosistem

GHC - Glasgow Haskell Compiler za compileanje programskog koda

Stack - upravljač projektima i dependencija

Cabal - sistem za izgradnju Haskell projekata

### Glazbene biblioteke

Euterpea - Haskell biblioteka za glazbeni opis, analizu i generaciju, omogućuje rad s notama, akordima i glazbenim sekvencama i pruža funkcionalnosti za MIDI export

Haskore - funkcionalni moduli za glazbu (korišteno u primjerima), služi za kreiranje, analiziranje i manupuliranje glazbom

### SMT solver

SBV (Symbolic Boolean Vectors) - Haskell biblioteka za SMT rješavanje, integrira se sa Z3 SMT solverom i omogućuje definiranje ograničenja i njihovo rješavanje

Z3 - SMT solver razvijen od Microsoft Research-a, služi za rješavanje teorija prvoga reda i za osiguravanje glazbenih ograničenja

---

## Arhitektura projekta

### Struktura datoteka

Glavne datoteke su:

```
funkprog-project/
├── Genetic.hs                   # Genetski algoritam za evoluciju melodija
├── Constraint.hs                # SMT solver za glazbena ograničenja
├── mainmidi.hs                  # Glavna aplikacija i UI
├── funkprog-project.cabal       # Deklaracija projekta
├── package.yaml                 # Konfiguracija dependencija
└── stack.yaml                   # Stack konfiguracija
```

### Ključne komponente

#### **Genetic.hs** - genetski algoritam

Implementira genetski algoritam za evoluciju melodija. Koristi tipove `Pitch` (tonska klasa + oktava), `Melody` (lista nota) i `Population` (skup melodija).

**Ključne funkcije:**

`randomPitch()` - generira nasumičnu notu iz chromatic skale (sve 12 note) u oktavama 4-5

`randomMelody()` - kreira nasumičnu melodiju od 8 nota

`fitness()` - poboljšana fitness funkcija koja nagrađuje:
- male intervale (≤2 polutona) → +2 boda
- srednje intervale (3-7 polutona) → +1 bod
- velike intervale (>7 polutona) → -1 bod
- identične uzastopne note → -2 boda
- raznolikost nota → bonus ovisno o broju jedinstvenih nota

`evolve()` - glavna funkcija koja pokreće evoluciju kroz zadani broj generacija

**Proces:**

1. kreiramo inicijalnu populaciju od n nasumičnih melodija
2. za svaku melodiju računamo fitness vrijednost
3. odabiramo najbolje melodije (top 50% kao elite)
4. kombiniramo dijelove melodija (crossover) nasumičnom točkom
5. nasumično mijenjamo jednu notu (mutacija)
6. ponavljamo kroz zadani broj generacija
7. vraćamo najbolju melodiju pretvorenu u Euterpea glazbu

**Druge funkcije:**

`randomPopulation n = replicateM n randomMelody` -  stvara populaciju od "n" nasumičnih melodija.

`selectBest pop n = take n $ reverse $ sortOn fitness pop` - sortira populaciju po "fitness" vrijednosti (descending) i uzima najbolje "n" melodija.

`crossover a b = do` - spaja dva roditelja uz nasumično odabranu točku (single-point crossover).

`mutate m = do` - mijenja jednu notu u melodiji na nasumičnoj poziciji.

`nextGeneration pop = do` - generira novu populaciju: zadržava elite, ostalo su kombinacije crossover + mutacija.

`melodyToMusic = line . map (note qn)` - konvertira listu pitcheva u Euterpea glazbu s kvartnim notama.

`writeMusic = writeMidi` - sprema glazbu kao MIDI datoteku.


#### **Constraint.hs** - SMT solver i ograničenja

Koristi Z3 SMT solver preko SBV biblioteke za osiguranje glazbenih pravila. Modul izvozi ključne funkcije: `solveMelody`, `solveMelodyWithSeed`, `extractPCs` i tip `MusicConstraint`.

**MusicConstraint tipovi:**

`InKey PitchClass` - melodija mora biti u zadanoj tonalnosti (C, G, D, F, A, E)

`Diverse` - zabrana uzastopnih identičnih nota

`MaxStep Int` - maksimalni interval između uzastopnih nota (u polutonima)

`MinStep Int` - minimalni interval između uzastopnih nota (za raznolikost)

`MotifLength Int` - osigurava da svaka N nota bude različita (varijacija u frazama)

**Ključne funkcije:**

`pcToInt()` - mapira PitchClass na brojeve 0-11 (C=0, Cs=1, ..., B=11)

`intToPc()` - inverzna konverzija iz broja u PitchClass

`majorScale root` - vraća listu integers (0-11) za major skalu od zadanog root-a

`solveMelody n constraints` - generira nasumičnu melodiju od n nota i provjerava je li zadovoljava zadana ograničenja (pokušava do 1000 puta)

`solveMelodyWithSeed seed constraints` - koristi genetsku melodiju kao početnu točku (seed) i pokušava pronaći rješenje koje zadovoljava ograničenja

`extractPCs music` - ekstrahira pitch class vrijednosti iz Euterpea glazbe u listu integers

`checkMelody vals constraints` - provjerava zadovoljava li melodija zadana ograničenja

`rngMelody n root` - generira nasumičnu melodiju od n nota u zadanoj ljestvici (koristi System.Random)

`buildMusic pcs` - konvertira listu integers u Euterpea glazbu s kvartnim notama u oktavi 4

**Proces (solveMelody):**

1. generiraj nasumičnu melodiju od n nota u zadanoj tonalnosti (rngMelody)
2. ekstrahiraj pitch class vrijednosti (extractPCs)
3. provjeri zadovoljava li melodija sva ograničenja (checkMelody)
4. ako da → vrati melodiju, ako ne → ponovi (do 1000 pokušaja)

**Proces (solveMelodyWithSeed):**

1. kreiraj SMT varijable za svaku notu iz seed-a
2. forsiraj te vrijednosti kao početne (constrain $ p .== literal v)
3. primjeni sva ograničenja (InKey, Diverse, MaxStep, MinStep, MotifLength)
4. pokreni Z3 solver (checkSat)
5. ako Sat → vrati seed melodiju, ako Unsat → vrati grešku

**Druge funkcije:**

`applyConstraint notes (InKey root)` - osigurava da sve note budu u major skali zadanog root-a

`applyConstraint notes Diverse` - zabrana susjednih identičnih nota (sNot (n1 .== n2))

`applyConstraint notes (MaxStep maxVal)` - ograničava maksimalni apsolutni interval (sAbs (n2 - n1) .<= maxV)

`applyConstraint notes (MinStep minVal)` - ograničava minimalni apsolutni interval (sAbs (n2 - n1) .>= minV)

`applyConstraint notes (MotifLength m)` - osigurava da svaka grupa od m uzastopnih nota ima sve različite note

`getRoot constraints` - ekstrahira root iz InKey constrainta ili vraća C kao default


#### **mainmidi.hs** - glavna aplikacija i korisničko sučelje

Glavna aplikacija koja pruža interaktivno korisničko sučelje i koordinira sva tri pristupa generiranju glazbe. Postavlja Z3 putanju i omogućuje korisniku odabir načina generiranja.

**Ključne funkcije:**

`main()` - glavna funkcija koja postavlja okruženje i prikazuje izbornik

`readMidi path` - čita MIDI datoteku i vraća `Maybe Music1`

`writeMidiFile fp m` - sprema glazbu kao MIDI i reproducira je

**Tri načina generiranja:**

1. **Genetski algoritam + SMT solver (preporučeno)**

`generateWithSMT()` - kombinirani pristup:
- korisnik bira tonalitet (C, G, D, F, A, E)
- korisnik bira MaxStep (3/5/7/12 polutona)
- korisnik bira MinStep (1/2/3/0 polutona)
- korisnik bira MotifLength (2/3/4 note)
- generira melodiju genetskim algoritmom (100 populacija, 20 generacija)
- ekstrahira pitch class vrijednosti (extractPCs)
- poziva `solveMelodyWithSeed` za provjeru ograničenja
- ako ne zadovoljava → iterira iznova (do 1,000 pokušaja)
- sprema rezultat kao `v3_final_output_no_X.mid`

2. **Samo SMT solver (Z3)**

`generateSMTOnly()` - direktni SMT pristup:
- Korisnik bira tonalitet, MaxStep, MinStep, MotifLength
- Poziva `solveMelody 8 [constraints]`
- Sprema kao `smt_output.mid`

3. **Samo Genetski algoritam**

`generateGeneticOnly()` - čisti evolucijski pristup:
- Poziva `Genetic.evolve 100 20`
- Sprema kao `gen_output.mid`

**Pomoćne funkcije:**

`generateUntilValid attempt key maxStep minStep motif` - rekurzivna funkcija koja iterira dok ne pronađe validnu melodiju

`generateSMT key maxStep minStep motif` - direktno poziva SMT solver

`writeMidiFile filename music` - zapisuje MIDI i reproducira glazbu

**Interaktivni izbornik:**

```
Odaberite nacin generiranja glazbe:
1 - Genetski algoritam + SMT solver (preporuceno)
2 - Samo SMT solver (Z3)
3 - Samo genetski algoritam
Vas izbor (1/2/3):
```

Za svaki način postoji podizbornik za odabir tonaliteta i parametara:

---

## Kako koristiti

### Pokretanje projekta

**Izgradnja:**
```bash
stack build
```

**Pokretanje:**
```bash
stack exec -- funkprog-project
```

### Opis načina generiranja

1. **Genetski algoritam + SMT solver (preporučeno)**: Kombinira evolucijski pristup s matematičkim ograničenjima za najbolju kvalitetu
2. **Samo SMT solver (Z3)**: Koristi matematička ograničenja za generiranje melodija u skladu s glazbenim pravilima
3. **Samo genetski algoritam**: Evoluirajuća populacija melodija bez strogih matematičkih ograničenja

### Reprodukcija MIDI datoteka

Koristiti bilo koji MIDI player: Windows Media Player, Winamp, GarageBand, iTunes, Timidity, fluidsynth, online

---

## Metodologija

### Genetski Algoritam - detaljni proces

**1. Inicijalizacija**

Kreira se populacija od n nasumičnih melodija (default: 100), a svaka melodija sadrži 8 nota iz chromatic skale (sve 12 note) u oktavama 4-5.

**2. Evaluacija (Fitness)**

```
fitness(melodija) = Σ(ocjena intervala) - kazna za monotoniju + bonus za raznolikost
```

- male intervali (≤2 polutona) → +2 boda
- srednji intervali (3-7 polutona) → +1 bod
- veliki intervali (>7 polutona) → -1 bod
- identične uzastopne note → -2 boda
- raznolikost nota → bonus ovisno o broju jedinstvenih nota

**3. Selekcija**

Odabiru se najbolje melodije (top 50%) kao elite.

**4. Crossover**

Kombiniraju se dijelovi dviju odabranih melodija nasumičnom točkom (single-point crossover).

**5. Mutacija**

Nasumično se mijenja jedna nota u melodiji na nasumičnoj poziciji.

**6. Iteracija**

Proces se ponavlja kroz zadani broj generacija (default: 20).

### SMT Solver - detaljni proces (RNG pristup)

**1. RNG generacija**

Generira se nasumična melodija od n nota u zadanoj major ljestvici koristeći `randomRIO`.

**2. Provjera ograničenja**

Kreiraju se SMT varijable za svaku notu i forsiraju se vrijednosti iz RNG melodije, zatim se primjenjuju sva ograničenja:
- InKey: note moraju biti u major skali
- Diverse: zabrana uzastopnih identičnih nota
- MaxStep: maksimalni interval između uzastopnih nota
- MinStep: minimalni interval između uzastopnih nota
- MotifLength: svaka grupa od N nota mora imati različite note

**3. Rješavanje**

Z3 solver provjerava zadovoljenost ograničenja (checkSat).

**4. Povratna vrijednost**

Ako je zadovoljivo vraća pronađenu melodiju, ako nije kreće novi pokušaj (do 1000 pokušaja).

### SMT Solver - detaljni proces (seed pristup)

**1. Seed iz genetskog algoritma**

Ekstrahiraju se pitch class vrijednosti iz genetske melodije (`extractPCs`).

**2. Forsiranje vrijednosti**

Kreiraju se SMT varijable i forsiraju se vrijednosti iz seed-a.

**3. Primjena ograničenja**

Primjenjuju se sva ograničenja na simboličke note.

**4. Rješavanje**

Z3 solver provjerava zadovoljenost ograničenja.

**5. Povratna vrijednost**

Ako Sat → vraća se seed melodija, ako Unsat → vraća se greška.

### Kombiniran pristup

1. Korisnik bira tonalitet (C, G, D, F, A, E) i parametre (MaxStep, MinStep, MotifLength)
2. Genetski algoritam generira melodiju (100 populacija, 20 generacija)
3. Ekstrahiraju se pitch class vrijednosti iz genetske melodije
4. `solveMelodyWithSeed` provjerava zadovoljava li melodija sva ograničenja
5. Ako zadovoljava → sprema se kao MIDI datoteka
6. Ako ne zadovoljava → iterira se s novom genetskom melodijom (do 1,000 pokušaja)

---


## Rezultati

**Primjeri generirane glazbe:**

- `v2_final_output_no_1.mid` - Genetski + SMT pristup
- `smt_output.mid` - SMT solver pristup
- `gen_output.mid` - Genetski algoritam pristup
- `melodija_1.mid` do `melodija_5.mid` - Više eksperimenata (SMT solver), uzastopno iteriranje melodija


---

## Zaključak

Ovaj projekt demonstrira kombiniranje genetskih algoritama i SMT solvera za automatsku glazbenu kompoziciju. Dok genetski algoritam osigurava raznolikost i koherentnost, SMT solver garantira teoretsku ispravnost glazbe.

Iako su rezultati obećavajući, naravno, kao i uvijek postoji prostor za poboljšanja, primjerice: podrška za harmoniju i akorde, fleksibilnija kontrola nad tonalitetima, učenje iz primjera kroz strojno učenje, bolje varijacije glazbe i uočavanje istih

---

## Literatura i Izvori

- Genetic Algorithm članak: https://sciendo.com/article/10.2478/amns.2023.2.00070
- Algorithmic Composition as CSP članak: https://www.hinojosachapel.com/data/texts/algorithmic_composition_as_a_csp.pdf
- Euterpea dokumentacija: http://www.euterpea.com/
- Z3 SMT Solver: https://github.com/Z3Prover/z3
- SBV Biblioteka: http://leventerkok.github.io/sbv/
