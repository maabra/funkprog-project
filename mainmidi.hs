{-# LANGUAGE LambdaCase #-}


-- | stack exec -- funkprog-project
-- | stack build

import Euterpea
import Codec.Midi (importFile)
import qualified Genetic
import qualified Constraint
import Control.Monad (when)
import System.Environment (setEnv)

readMidi :: FilePath -> IO (Maybe Music1)
readMidi path =
    importFile path >>= \case
        Right midi -> pure $ Just (fromMidi midi)
        Left _     -> pure Nothing

-- | kreiranje genetsko generirane glazbe i spremanje u .mid
writeMidiFile :: FilePath -> Music Pitch -> IO ()
writeMidiFile fp m = do
    putStrLn $ "Writing MIDI to " ++ fp
    Genetic.writeMusic fp m
    play m

main :: IO ()
main = do
    setEnv "SBV_Z3" "./z3-4.16.0-x64-win/bin/z3.exe"
    -- putStrLn "Generiranje glazbe s genetskim algoritmom..."
    -- generateUntilValid 1

    putStrLn "Odaberite nacin generiranja glazbe:"
    putStrLn "1 - Genetski algoritam + SMT solver (preporuceno)"
    putStrLn "2 - Samo SMT solver (Z3)"
    putStrLn "3 - Samo genetski algoritam"
    putStr "Vas izbor (1/2/3): "
    choice <- getLine
    
    case choice of
        "1" -> generateWithSMT
        "2" -> generateSMTOnly
        "3" -> generateGeneticOnly
        _   -> putStrLn "Neispravan izbor"


-- generateUntilValid :: Int -> IO ()
-- generateUntilValid attempt
--     | attempt > 10000 = putStrLn "Neuspjelo nakon 10000 pokusaja."
--     | otherwise = do
--         putStrLn $ "Pokusaj broj" ++ show attempt

--         gaMusic <- Genetic.evolve 50 20

--         let spec = Constraint.CompositionSpec
--                 { Constraint.basePattern = gaMusic
--                 , Constraint.constraints = [Constraint.InKey C]
--                 }

--         case Constraint.solveComposition spec of
--             Left _ -> generateUntilValid (attempt + 1)

--             Right music -> do
--                 let filename = "v1_final_output_no_" ++ show attempt ++ ".mid"
--                 writeMidiFile filename music
--                 putStrLn $ "Uspjeh na pokusaju #" ++ show attempt


-- Opcija 1: Genetski algoritam + SMT provjera
generateWithSMT :: IO ()
generateWithSMT = do
    putStrLn "\n Genetski algoritam + SMT provjera "
    
    -- Odabir tona
    putStrLn "Odaberite ton (pitch) za melodiju:"
    putStrLn "1 - C (C-dur)"
    putStrLn "2 - G (G-dur)"
    putStrLn "3 - D (D-dur)"
    putStrLn "4 - F (F-dur)"
    putStrLn "5 - A (A-mol)"
    putStrLn "6 - E (E-mol)"
    putStr "Vas izbor (1-6): "
    key <- getLine
    let pitch = case key of
            "1" -> Constraint.InKey C
            "2" -> Constraint.InKey G
            "3" -> Constraint.InKey D
            "4" -> Constraint.InKey F
            "5" -> Constraint.InKey A
            "6" -> Constraint.InKey E
            _   -> Constraint.InKey C
    
    -- Odabir MaxStep (maksimalni interval između nota)
    putStrLn "\nOdaberite maksimalni interval izmedu nota:"
    putStrLn "1 - Mali (3 polutona)"
    putStrLn "2 - Srednji (5 polutona)"
    putStrLn "3 - Veliki (7 polutona)"
    putStrLn "4 - Bez ogranicenja"
    putStr "Vas izbor (1-4): "
    msKey <- getLine
    let maxStep = case msKey of
            "1" -> Constraint.MaxStep 3
            "2" -> Constraint.MaxStep 5
            "3" -> Constraint.MaxStep 7
            "4" -> Constraint.MaxStep 12
            _   -> Constraint.MaxStep 5
    
    -- Odabir MinStep (minimalni interval između nota)
    putStrLn "\nOdaberite minimalni interval izmedu nota:"
    putStrLn "1 - Mali (1 poluton)"
    putStrLn "2 - Srednji (2 polutona)"
    putStrLn "3 - Veliki (3 polutona)"
    putStrLn "4 - Bez ogranicenja"
    putStr "Vas izbor (1-4): "
    minKey <- getLine
    let minStep = case minKey of
            "1" -> Constraint.MinStep 1
            "2" -> Constraint.MinStep 2
            "3" -> Constraint.MinStep 3
            "4" -> Constraint.MinStep 0
            _   -> Constraint.MinStep 0
    
    -- Odabir MotifLength (varijacija u frazama)
    putStrLn "\nOdaberite duljinu motiva (varijacija u frazama):"
    putStrLn "1 - Kratko (4 note)"
    putStrLn "2 - Srednje (6 nota)"
    putStrLn "3 - Dugo (8 nota)"
    putStr "Vas izbor (1-3): "
    motifKey <- getLine
    let motifLen = case motifKey of
            "1" -> Constraint.MotifLength 4
            "2" -> Constraint.MotifLength 6
            "3" -> Constraint.MotifLength 8
            _   -> Constraint.MotifLength 4
    
    putStrLn $ "Generiram u tonu: " ++ show pitch
    generateUntilValid 1 pitch maxStep minStep motifLen

generateUntilValid :: Int -> Constraint.MusicConstraint -> Constraint.MusicConstraint -> Constraint.MusicConstraint -> Constraint.MusicConstraint -> IO ()
generateUntilValid attempt keyConstraint maxStepConstraint minStepConstraint motifConstraint
    | attempt > 1000 = putStrLn "Neuspjelo nakon 1000 pokusaja."
    | otherwise = do
        putStrLn $ "Pokusaj #" ++ show attempt
        
        gaMusic <- Genetic.evolve 100 20
        
        -- rjesenje sa SMT solverom koristeci genetsku melodiju kao pocetnu tocku
        putStrLn "  Pokrecem SMT solver za pronalazenje rjesenja..."
        result <- Constraint.solveMelody 20 [keyConstraint, Constraint.Diverse, maxStepConstraint, minStepConstraint, motifConstraint]
        
        case result of
            Left err -> do
                putStrLn $ "SMT solver nije pronasao rjesenje: " ++ err
            Right music -> do
                let filename = "v3_final_output_no_" ++ show attempt ++ ".mid"
                writeMidiFile filename music
                putStrLn $ "uspjeh na pokusaju #" ++ show attempt

-- opcija 2, Samo SMT solver
generateSMTOnly :: IO ()
generateSMTOnly = do
    putStrLn "\n Samo SMT solver (Z3) "
    
    -- Odabir tona
    putStrLn "Odaberite ton (pitch) za melodiju:"
    putStrLn "1 - C (C-dur)"
    putStrLn "2 - G (G-dur)"
    putStrLn "3 - D (D-dur)"
    putStrLn "4 - F (F-dur)"
    putStrLn "5 - A (A-mol)"
    putStrLn "6 - E (E-mol)"
    putStr "Vas izbor (1-6): "
    key <- getLine
    let pitch = case key of
            "1" -> Constraint.InKey C
            "2" -> Constraint.InKey G
            "3" -> Constraint.InKey D
            "4" -> Constraint.InKey F
            "5" -> Constraint.InKey A
            "6" -> Constraint.InKey E
            _   -> Constraint.InKey C
    
    -- Odabir MaxStep
    putStrLn "\nOdaberite maksimalni interval izmedu nota:"
    putStrLn "1 - Mali (3 polutona)"
    putStrLn "2 - Srednji (5 polutona)"
    putStrLn "3 - Veliki (7 polutona)"
    putStrLn "4 - Bez ogranicenja"
    putStr "Vas izbor (1-4): "
    msKey <- getLine
    let maxStep = case msKey of
            "1" -> Constraint.MaxStep 3
            "2" -> Constraint.MaxStep 5
            "3" -> Constraint.MaxStep 7
            "4" -> Constraint.MaxStep 12
            _   -> Constraint.MaxStep 5
    
    -- Odabir MinStep
    putStrLn "\nOdaberite minimalni interval izmedu nota:"
    putStrLn "1 - Mali (1 poluton)"
    putStrLn "2 - Srednji (2 polutona)"
    putStrLn "3 - Veliki (3 polutona)"
    putStrLn "4 - Bez ogranicenja"
    putStr "Vas izbor (1-4): "
    minKey <- getLine
    let minStep = case minKey of
            "1" -> Constraint.MinStep 1
            "2" -> Constraint.MinStep 2
            "3" -> Constraint.MinStep 3
            "4" -> Constraint.MinStep 0
            _   -> Constraint.MinStep 0
    
    -- Odabir MotifLength
    putStrLn "\nOdaberite duljinu motiva (varijacija u frazama):"
    putStrLn "1 - Kratko (4 note)"
    putStrLn "2 - Srednje (6 nota)"
    putStrLn "3 - Dugo (8 nota)"
    putStr "Vas izbor (1-3): "
    motifKey <- getLine
    let motifLen = case motifKey of
            "1" -> Constraint.MotifLength 4
            "2" -> Constraint.MotifLength 6
            "3" -> Constraint.MotifLength 8
            _   -> Constraint.MotifLength 4
    
    putStrLn $ "Generiram u tonu: " ++ show pitch
    generateSMT pitch maxStep minStep motifLen

generateSMT :: Constraint.MusicConstraint -> Constraint.MusicConstraint -> Constraint.MusicConstraint -> Constraint.MusicConstraint -> IO ()
generateSMT keyConstraint maxStepConstraint minStepConstraint motifConstraint = do
    putStrLn "Pokrecem SMT solver za melodiju od 20 nota..."
    result <- Constraint.solveMelody 20 [keyConstraint, Constraint.Diverse, maxStepConstraint, minStepConstraint, motifConstraint]
    
    case result of
        Left err -> do
            putStrLn $ "Greska: " ++ err
        Right music -> do
            let filename = "smt_output.mid"
            writeMidiFile filename music
            putStrLn "Melodija spremljena!"

-- opcija 3, Samo genetski algoritam
generateGeneticOnly :: IO ()
generateGeneticOnly = do
    putStrLn "\n Samo genetski algoritam "
    putStrLn "Generiranje melodije genetskim algoritmom..."
    
    gaMusic <- Genetic.evolve 100 20 -- populacija 100, 20 generacija
    
    let filename = "gen_output.mid"
    writeMidiFile filename gaMusic
    putStrLn "Melodija spremljena!"

{-
-- pomocna funkcija za vise eksperimenata {--}
generateMultiple :: Int -> IO ()
generateMultiple n = do
    putStrLn $ "Generiranje " ++ show n ++ " melodija..."
    results <- mapM generateOne [1..n]
    let successCount = length $ filter id results
    putStrLn $ "Uspjesno generirano: " ++ show successCount ++ "/" ++ show n
    where
    generateOne i = do
        putStrLn $ "Generiranje melodije #" ++ show i
        result <- Constraint.solveMelody 8 [Constraint.InKey C, Constraint.Diverse, Constraint.MaxStep 5, Constraint.NoRepeats 2, Constraint.MotifLength 4]
        case result of
            Left err -> do
                putStrLn $ "  Neuspjeh: " ++ err
                return False
            Right music -> do
                let filename = "melodija_" ++ show i ++ ".mid"
                writeMidiFile filename music
                return True
-}