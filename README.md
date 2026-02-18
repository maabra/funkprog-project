NASLOV:
Algoritamska glazbena kompozicija s genetskim algoritmima i zadovoljenjem ograničenja u Haskellu

POPIS ČLANOVA:
Matej Abramović, 0303090408; Loris Lukić, 0303090567; Daniel Vorić, 0303096417

SAŽETAK:
Kreirati će se dva različita algoritma, genetski algoritam za skladanje glazbe i algoritam zadovoljenja ograničenja za samu glazbenu kompoziciju, tj. genetski algoritam i algoritam zadovoljenja ograničenja. 

Prilikom stvaranja algoritamske glazbe korištenjem genetskih algoritama u Haskellu koristit ćemo biblioteke kao što su Haskore, Euterpea i neku vrstu genetskiog algoritma. Genetski algoritmi rade tako što razvijaju populaciju glazbenih fraza kroz procese slične prirodnoj selekciji. Počevši od mape osnovnih uzoraka kao početne populacije, funckija "fitness"-a procjenjuje glazbenu kvalitetu svake tzv. skladbe. "Crossover" kombinira dijelove dviju kompozicija, dok mutacija uvodi male nasumične promjene kako bi se osigurala raznolikost. Kroz uzastopne generacije, ovaj pristup pokušava dobiti zadovoljavajuć glazbeni rezultat, tj. glazbu koja bi se stvarno mogla slušati. Rezulti se spremaju kao MIDI datoteke.

Zadovoljenje ograničenja u skladanju glazbe koristi biblioteke kao što su Haskore, Euterpea i proizvoljni ili postojeći rješavač/solver ograničenja. Ova metoda uključuje definiranje skupa glazbenih ograničenja, npr. tonalitet, napredovanje akorda i ritmičkih uzoraka. Alat za rješavanje ograničenja, tj. solver osigurava da se generirana glazba pridržava ovih unaprijed definiranih pravila. Korištenjem mape osnovnih uzoraka, algoritam generira skladbe koje zadovoljavaju navedene kriterije. Konačni rezultat je također u MIDI formatu.

IZVOR:
https://sciendo.com/article/10.2478/amns.2023.2.00070 - Genetski algoritam

https://www.hinojosachapel.com/data/texts/algorithmic_composition_as_a_csp.pdf - Algoritam pomoću zadovoljenja ograničenja