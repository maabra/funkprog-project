{-# LANGUAGE LambdaCase #-}


-- | stack exec -- funkprog-project
-- | stack build

import Euterpea
import Codec.Midi (importFile)
import qualified Genetic

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
    -- genetski algoritam
    putStrLn "Generating music with genetic algorithm..."
    gaMusic <- Genetic.evolve 50 20    -- 50 generacija, populacija 20
    writeMidiFile "ga_output.mid" gaMusic

    -- read test
    readMidi "FurElise.mid" >>= \m ->
        maybe (putStrLn "Error reading FurElise.mid.") play m