{-# LANGUAGE LambdaCase #-}


-- | stack exec -- funkprog-project
-- | stack build

import Euterpea
import Codec.Midi (importFile)
import qualified Genetic
import qualified Constraint

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
    putStrLn "Generiranje glazbe s genetskim algoritmom..."
    generateUntilValid 1


generateUntilValid :: Int -> IO ()
generateUntilValid attempt
    | attempt > 10000 = putStrLn "Neuspjelo nakon 10000 pokusaja."
    | otherwise = do
        putStrLn $ "Pokusaj broj" ++ show attempt

        gaMusic <- Genetic.evolve 50 20

        let spec = Constraint.CompositionSpec
                { Constraint.basePattern = gaMusic
                , Constraint.constraints = [Constraint.InKey C]
                }

        case Constraint.solveComposition spec of
            Left _ -> generateUntilValid (attempt + 1)

            Right music -> do
                let filename = "v1_final_output_no_" ++ show attempt ++ ".mid"
                writeMidiFile filename music
                putStrLn $ "Uspjeh na pokusaju #" ++ show attempt