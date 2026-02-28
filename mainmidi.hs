{-# LANGUAGE LambdaCase #-}


-- | stack exec -- funkprog-project
-- | stack build

import Euterpea
import Codec.Midi (importFile)
import qualified Genetic
import qualified Constraint
import Control.Monad (when)

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
    generateUntilValid 1

generateUntilValid :: Int -> IO ()
generateUntilValid attempt
    | attempt > 1000 = putStrLn "Neuspjelo nakon 1000 pokusaja."
    | otherwise = do
        putStrLn $ "Pokusaj #" ++ show attempt
        
        gaMusic <- Genetic.evolve 50 20
        
        -- rjesenje sa SMT solverom koristeci genetsku melodiju kao pocetnu tocku
        putStrLn "  Pokrecem SMT solver za pronalazenje rjesenja..."
        -- result <- solveMelody 8 [InKey C]
        result <- Constraint.solveMelody 8 [Constraint.InKey C]  -- <- koristi C iz Euterpea
        
        case result of
            Left err -> do
                putStrLn $ "SMT solver nije pronasao rjesenje: " ++ err
                putStrLn "Pokusavam s manje nota..."
                -- result2 <- solveMelody 4 [InKey C]
                result2 <- Constraint.solveMelody 4 [Constraint.InKey C]
                case result2 of
                    Left err2 -> do
                        putStrLn $ "Ni s manje nota neuspjesno: " ++ err2
                        generateUntilValid (attempt + 1)
                    Right music -> do
                        let filename = "v2_final_output_no_" ++ show attempt ++ ".mid"
                        writeMidiFile filename music
                        putStrLn $ "uspjeh na pokusaju #" ++ show attempt
            
            Right music -> do
                let filename = "v2_final_output_no_" ++ show attempt ++ ".mid"
                writeMidiFile filename music
                putStrLn $ "uspjeh na pokusaju #" ++ show attempt

-- opcija 2, Samo SMT solver
generateSMTOnly :: IO ()
generateSMTOnly = do
    putStrLn "\n Samo SMT solver (Z3) "
    putStrLn "Pokrecem SMT solver za melodiju od 8 nota u C-duru..."
    -- result <- solveMelody 8 [InKey C]
    result <- Constraint.solveMelody 8 [Constraint.InKey C]
    
    case result of
        Left err -> do
            putStrLn $ "Greska: " ++ err
            putStrLn "Pokusavam s jednostavnijim ogranicenjima (4 note)..."
            -- result2 <- solveMelody 4 [InKey C]
            result2 <- Constraint.solveMelody 4 [Constraint.InKey C]
            case result2 of
                Left err2 -> putStrLn $ "Ponovno neuspjesno: " ++ err2
                Right music -> do
                    let filename = "smt_output.mid"
                    writeMidiFile filename music
                    putStrLn "Melodija spremljena!"
        Right music -> do
            let filename = "smt_output.mid"
            writeMidiFile filename music
            putStrLn "Melodija spremljena!"

-- opcija 3, Samo genetski algoritam
generateGeneticOnly :: IO ()
generateGeneticOnly = do
    putStrLn "\n Samo genetski algoritam "
    putStrLn "Generiranje melodije genetskim algoritmom..."
    
    gaMusic <- Genetic.evolve 50 20
    
    let filename = "gen_output.mid"
    writeMidiFile filename gaMusic
    putStrLn "Melodija spremljena!"

-- pomocna funkcija za vise eksperimenata
generateMultiple :: Int -> IO ()
generateMultiple n = do
    putStrLn $ "Generiranje " ++ show n ++ " melodija..."
    results <- mapM generateOne [1..n]
    let successCount = length $ filter id results
    putStrLn $ "Uspjesno generirano: " ++ show successCount ++ "/" ++ show n
    where
    generateOne i = do
        putStrLn $ "Generiranje melodije #" ++ show i
        result <- Constraint.solveMelody 8 [Constraint.InKey C]
        case result of
            Left err -> do
                putStrLn $ "  Neuspjeh: " ++ err
                return False
            Right music -> do
                let filename = "melodija_" ++ show i ++ ".mid"
                writeMidiFile filename music
                return True