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
    -- constraint kompozicija uz genetski algoritam
    putStrLn "Generiranje glazbe s genetskim algoritmom..."

    gaMusic <- Genetic.evolve 50 20

    let spec = Constraint.CompositionSpec
            { Constraint.basePattern = gaMusic
            , Constraint.constraints = [Constraint.InKey C]
            }

    case Constraint.solveComposition spec of
            Left err -> putStrLn $ "Constraint error: " ++ err
            Right music -> writeMidiFile "final_output.mid" music
