import Euterpea
import Codec.Midi (importFile)

readMidi :: FilePath -> IO (Maybe Music1)
readMidi path =
    importFile path >>= \case
        Right midi -> pure $ Just (fromMidi midi)
        Left _     -> pure Nothing

main :: IO ()
main =
    readMidi "FurElise.mid" >>= \m ->
        maybe (putStrLn "Error.") play m