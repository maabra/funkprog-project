-- | bazicna struktura za constraint kompoziciju

module Constraint
where

import Euterpea
-- import solver neki

-- | tipovi ogranicenja
data MusicConstraint
  = InKey PitchClass
  | NoParallelFifths
  | RhythmPattern [Dur]
  | CustomConstraint String -- itd
  deriving (Show, Eq)

-- | kompozicijski specifikator koji sadrzi pocetni materijal i ograniceja
data CompositionSpec = CompositionSpec
  { basePattern :: Music Pitch      -- ^ pocetni pattern
  , constraints :: [MusicConstraint] -- ^ lista ogranicenja
  }

-- | rezultat rjesavanja poroblema kompozicije
type SolveResult = Either String (Music Pitch)

-- | funkcija, prima specifikaciju kompozicije i vraca glazbu ili gresku

solveComposition :: CompositionSpec -> SolveResult
solveComposition spec =
  Left "test"

-- | test
example :: IO ()
example = do
  let spec = CompositionSpec
        { basePattern = line [c 4 qn, e 4 qn, g 4 qn]
        , constraints = [InKey C, RhythmPattern [qn, qn, qn]]
        }
  case solveComposition spec of
    Left err -> putStrLn $ "Error " ++ err
    Right music -> writeMidi "output.mid" music
