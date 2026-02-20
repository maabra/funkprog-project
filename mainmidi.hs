{-# LANGUAGE LambdaCase #-}

import Euterpea
import Codec.Midi (importFile)
import qualified Genetic

readMidi :: FilePath -> IO (Maybe Music1)
readMidi path =
    importFile path >>= \case
        Right midi -> pure $ Just (fromMidi midi)
        Left _     -> pure Nothing

-- | Write a music value to a MIDI file and (optionally) play it.
writeMidiFile :: FilePath -> Music Pitch -> IO ()
writeMidiFile fp m = do
    putStrLn $ "Writing MIDI to " ++ fp
    Genetic.writeMusic fp m
    play m

main :: IO ()
main = do
    -- run the genetic algorithm and save the result
    putStrLn "Generating music with genetic algorithm..."
    gaMusic <- Genetic.evolve 50 20    -- 50 generations, population of 20
    writeMidiFile "ga_output.mid" gaMusic

    -- as before, read and play an existing file
    readMidi "FurElise.mid" >>= \m ->
        maybe (putStrLn "Error reading FurElise.mid.") play m