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

1. istraživati primjenu genetskih algoritama za evoluciju glazbenih skladbi kroz procese slične prirodnoj selekciji
2. implementirati SMT solver za osiguravanje skladanja u skladu s glazbenim ograničenjima (npr. tonalitet)
3. kombinirati oba pristupa za poboljšanu kvalitetu generirane glazbe
4. evaluirati performanse i kvalitetu rezultata u odnosu na pojedinačne pristupe

### Glavni naputci

Tradicionalne metode skladanja zahtijevaju muzikalnu obuku i kreativnost. Ovaj projekt istražuje kako računalo može automatski generirati glazbu koja:
- poštuje glazbena pravila i ograničenja
- ima koherentnu strukturu i melodiju
- može služiti kao inspiracija kompozitorima ili kao samostalni kompozitacijski alat
- prilagođava se različitim glazbenim stilovima i tonalitetima

---

## Biblioteke

### Haskell ekosistem

- **GHC**: Glasgow Haskell Compiler za compileanje programskog koda
- **Stack**: upravljač projektima i dependencija
- **Cabal**: sistem za izgradnju Haskell projekata

### Glazbene biblioteke

- **Euterpea**: Haskell biblioteka za glazbeni opis, analizu i generaciju

Omogućuje rad s notama, akordima i glazbenim sekvencama i pruža funkcionalnosti za MIDI export.

- **Haskore**: funkcionalni moduli za glazbu (korišteno u primjerima)

Služi za kreiranje, analiziranje i manupuliranje glazbom

### SMT solver

- **SBV (Symbolic Boolean Vectors)**: Haskell biblioteka za SMT rješavanje

Integrira se sa Z3 SMT solverom, a i omogućuje definiranje ograničenja i njihovo rješavanje.

- **Z3**: SMT solver razvijen od Microsoft Research-a

Služi za rješavanje teorija prvoga reda i za osiguravanje glazbenih ograničenja.

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

Implementira genetski algoritam za evoluciju melodija:

- **Pitch**: predstavlja glazbenu notu (tonska klasa + oktava)
- **Melody**: lista nota koje čine melodiju
- **Population**: skup melodija koje se evoluiraju

**Ključne funkcije:**
- `randomPitch()`: generira nasumičnu notu iz major skale
- `randomMelody()`: kreira nasumičnu melodiju od 8 nota
- `fitness()`: evaluira kvalitetu melodije
  - nagrađena za male intervale između susjednih nota (tj. koherentnost)
  - kažnjena za velike skokove
- `evolve()`: izvršava evoluciju kroz generacije

**Proces:**
1. kreiramo inicijalnu populaciju od 50 nasumičnih melodija
2. za svaku melodiju računamo fitness vrijednost
3. odabiramo najbolje melodije (selekcija)
4. kombiniramo dijelove melodija (crossover)
5. nasumično mijenjamo dio nota (mutacija)
6. ponavljamo kroz 20 generacija

**Druge funkcije:**
- `identicalNotes = length $ filter id $ zipWith (==) m (tail m)`
  - broji uzastopne identične note i omogućuje da se monotonija kazni u fitness funkciji.
- `mutationCount <- randomRIO (1, 2)` i `mutateSeveral m mutationCount`
  - nasumično bira koliko će nota biti mutirano u jednoj melodiji.
- `take idx m ++ [newp] ++ drop (idx + 1) m`
  - zamjenjuje notu na poziciji `idx` novom notom `newp` bez mijenjanja ostatka melodije.
- `randomPopulation n = replicateM n randomMelody`
  - stvara populaciju od `n` nasumičnih melodija pozivajući `randomMelody` više puta.
- `selectBest pop n = take n $ reverse $ sortOn fitness pop`
  - sortira populaciju po `fitness` vrijednosti i uzima najbolje `n` melodija kao elitnu skupinu.
- `crossover a b = do
    point <- randomRIO (1, melodyLen - 1)
    return $ take point a ++ drop point b`
  - spaja dva roditelja uz nasumično odabranu točku, uzimajući početak prve i kraj druge melodije.
- `children <- replicateM (popSize - eliteCount) ...`
  - generira ostale melodije u populaciji ponavljanjem postupka crossover + mutacija.
- `finalPop <- foldM (\pop _ -> nextGeneration pop) pop0 [1..gens]`
  - petlja koja ponavlja evolucijski korak `nextGeneration` kroz zadani broj generacija, gradeći novu populaciju iz prethodne.

#### **Constraint.hs** - SMT solver i ograničenja

Koristi Z3 SMT solver preko SBV biblioteke za osiguranje glazbenih pravila:

- **MusicConstraint**: enumeracija mogućih ograničenja
  - `InKey PitchClass`: glazba mora biti u određenoj tonalnosti
  - `MelodyLength Int`: duljina melodije
  - `Diverse`: dodatno ograničenje da se spriječe uzastopne identične note i potakne raznolikost

**Ključne funkcije:**
- `majorScale()`: vraća sve note u određenoj "major" skali
- `solveMelody()`: koristi Z3 solver da generira melodiju od N nota koja zadovoljava ograničenja
- `applyConstraint()`: primjenjuje `MusicConstraint` pravila, uključujući raznolikost
- `pcToInt()`: mapira glazbene tonske klase na brojeve (0-11)
- `intToPc()`: inverzna konverzija

**Proces:**
1. kreiramo SMT varijable za svaku notu u melodiji
2. definiramo ograničenja:
   - svaka nota mora biti dio tonalnosti (npr. C major)
   - note se nalaze unutar razumnog raspon octava
   - `Diverse` ograničenje sprječava uzastopne identične note i potiče raznolikost
3. Z3 solver provjerava zadovoljenost i pronalazi rješenje
4. vraćamo pronađenu melodiju ili grešku

**Druge funkcije:**
- `notes <- forM [1..n] $ \i -> sInteger ("note" ++ show i)`
  - stvara `n` simboličkih varijabli koje predstavljaju note u melodiji.
- `mapM_ (\p -> constrain $ p .>= 0 .&& p .<= 11) notes`
  - ograničava sve note na vrijednosti između 0 i 11, što odgovara pitch class rasponu.
- `mapM_ (applyConstraint notes) constraints`
  - primjenjuje svaki od zadanih ograničenja na istu grupu simboličkih nota.
- `query $ do ... cs <- checkSat ...`
  - pokreće SMT solver i provjerava je li zadatak zadovoljiv; rezultat može biti `Sat` ili `Unsat`.
- `vals <- mapM getValue notes`
  - čita konkretne vrijednosti koje je solver pronašao za svaku simboličku notu.
- `buildMusic pcs = E.line $ map (\pc -> E.note E.qn (intToPc pc, 4)) pcs`
  - pretvara rješenje solvera u Euterpea melodiju s kvartnim notama u oktavi 4.
- `applyConstraint notes Diverse`
  - primjenjuje dodatno pravilo da susjedne note ne mogu biti identične, čime se potiče raznolikost u rezultirajućoj melodiji.


#### **mainmidi.hs** - glavna aplikacija

Pruža korisničko sučelje i koordinira oba pristupa u tri načina generiranja:

**Tri načina generiranja:**

1. **Genetski algoritam + SMT solver (preporučeno)**

Generira melodiju genetskim algoritmom, zatim provjerava je sa Z3 solverom. Ako ne zadovoljava ograničenja, iterira iznova i na kraju sprema rezultat kao MIDI datoteku.

2. **Samo SMT solver (Z3)**

Koristi samo Z3 solver s definiranim ograničenjima, uključujući `Diverse` ograničenje za raznolikost melodije; brži je za male melodije i garantira zadovoljenje ograničenja.

> U kodu `mainmidi.hs` sada se pozivaju `solveMelody` funkcije s kombinacijom `[Constraint.InKey C, Constraint.Diverse]` kako bi se spriječile uzastopne identične note.

**Druge funkcije:**
- `choice <- getLine`
  - čita korisnički unos iz konzole za odabir načina generiranja.
- `case choice of ...`
  - odlučuje koji način generiranja pokrenuti na temelju korisničkog unosa.
- `result <- Constraint.solveMelody 8 [Constraint.InKey C, Constraint.Diverse]`
  - traži melodiju od 8 nota koja zadovoljava tonalitet C i raznolikost.
- `case result of Left err -> ... Right music -> ...`
  - obrađuje ishod solvera: ispisuje poruku u slučaju greške ili sprema i reproducira pronađenu glazbu.

3. **Samo Genetski algoritam**

Koristi samo genetsku evoluciju bez provjere ograničenja, ima brži proces ali bez garantiranja glazbenih pravila. Također je koristan za eksperimentiranje.

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

**Interaktivno sučelje:**

Program će pitati koji način generiranja odabrati:

```
Odaberite nacin generiranja glazbe:
1 - Genetski algoritam + SMT solver (preporuceno)
2 - Samo SMT solver (Z3)
3 - Samo genetski algoritam
Vas izbor (1/2/3): 
```

### Reprodukcija MIDI datoteka

Koristiti bilo koji MIDI player:
- Windows: Windows Media Player, Winamp
- macOS: GarageBand, iTunes
- Linux: Timidity, fluidsynth
- Online: https://html5-player.libsyn.com/

---

## Metodologija

### Genetski Algoritam - Detaljni proces

**1. Inicijalizacija**

Kreira se populacija od 50 nasumičnih melodija, a svaka melodija sadrži 8 nota iz C major skale.

**2. Evaluacija (Fitness)**

```
fitness(melodija) = broj intervalnih skokova ≤ 2 polutona
```

Nagrađuje koherentne melodije s malim skokom između nota, i s druge strane kažnjavaju se preskakanja koja čine melodiju "neuobičajenom".

**3. Selekcija**

Odabiru se najbolje melodije (top 50%).

**4. Crossover**

Kombiniraju se dijelovi dviju odabranih melodija.

**5. Mutacija**

Nasumično se mijenja 10% nota melodije.

**6. Iteracija**

Proces se ponavlja kroz 20 generacija.

### SMT Solver - Detaljni proces

**1. Definiranje varijabli**

Varijable za svaku notu (tj. cijeli brojevi 0-11).

**2. Definiranje ograničenja**

```
ForAll i: nota[i] ∈ majorScale (tonalitet)
```

**3. Rješavanje**

Uz Z3 se traži vrijednosti koje zadovoljavaju sva ograničenja.

**4. Povratna vrijednost**

- ako je zadovoljivo: vraća pronađenu melodiju
- ako je nezadovoljivo: vraća grešku

### Kombiniran pristup

1. Genetski algoritam generira kandidata
2. SMT solver provjerava je zadovoljava li ograničenja
3. Ako jest: sprema se kao rezultat
4. Ako nije: iterira se iznova s novim kandidatom

---


## Rezultati

**Primjeri generirane glazbe:**
- `v2_final_output_no_1.mid` - Genetski + SMT pristup
- `smt_output.mid` - SMT solver pristup
- `gen_output.mid` - Genetski algoritam pristup

---

## Zaključak

Ovaj projekt demonstrira kombiniranje **genetskih algoritama** i **SMT solvera** za automatsku glazbenu kompoziciju. Dok genetski algoritam osigurava raznolikost i koherentnost, SMT solver garantira teoretsku ispravnost glazbe.

Iako su rezultati obećavajući, naravno, kao i uvijek postoji prostor za poboljšanja, primjerice:

- podrška za harmoniju i akorde
- fleksibilnija kontrola nad tonalitetima
- duže melodije
- učenje iz primjera kroz strojno učenje
- bolje varijacije glazbe i uočavanje istih

---

## Literatura i Izvori

- Genetic Algorithm ćlanak: https://sciendo.com/article/10.2478/amns.2023.2.00070
- Algorithmic Composition as CSP članak: https://www.hinojosachapel.com/data/texts/algorithmic_composition_as_a_csp.pdf
- Euterpea dokumentacija: http://www.euterpea.com/
- Z3 SMT Solver: https://github.com/Z3Prover/z3
- SBV Biblioteka: http://leventerkok.github.io/sbv/
