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
  let m = basePattern spec
      cs = constraints spec
  in if all (checkConstraint m) cs
        then Right m
        else Left "base pattern does not satisfy all constraints"

-- | verifikacija
checkConstraint :: Music Pitch -> MusicConstraint -> Bool
checkConstraint m (InKey pc)        = all (== pc) (musicPitchClasses m)
checkConstraint m (RhythmPattern ps) = musicDurations m == ps
checkConstraint _ NoParallelFifths   = True    -- placeholder
checkConstraint _ (CustomConstraint _) = True  -- placeholder

{-
-- | pokusaj ekstrakcije pitcheva glazbe
musicPitchClasses :: Music Pitch -> [PitchClass]
musicPitchClasses m = case m of
  Prim (Note _ (pc, _)) -> [pc]
  Prim (Rest _)         -> []
  m1 :+: m2             -> musicPitchClasses m1 ++ musicPitchClasses m2
  m1 :=: m2             -> musicPitchClasses m1 ++ musicPitchClasses m2
  Modify _ m'           -> musicPitchClasses m'

-- | pokusaj ekstrakcije trajanja glazbe
musicDurations :: Music Pitch -> [Dur]
musicDurations m = case m of
  Prim (Note d _) -> [d]
  Prim (Rest d)   -> [d]
  m1 :+: m2       -> musicDurations m1 ++ musicDurations m2
  m1 :=: m2       -> musicDurations m1 ++ musicDurations m2
  Modify _ m'     -> musicDurations m'
-}

-- | helper za flattenanje glazbe s ekstrakcijom vrijednosti
flattenMusic :: (Primitive Pitch -> [a]) -> Music Pitch -> [a]
flattenMusic f m = case m of
  Prim p        -> f p
  m1 :+: m2     -> flattenMusic f m1 ++ flattenMusic f m2
  m1 :=: m2     -> flattenMusic f m1 ++ flattenMusic f m2
  Modify _ m'   -> flattenMusic f m'

-- | ekstrakcija pitch klasa
musicPitchClasses :: Music Pitch -> [PitchClass]
musicPitchClasses = flattenMusic $ \p -> case p of
  Note _ (pc, _) -> [pc]
  Rest _         -> []

-- | ekstrakcija trajanja
musicDurations :: Music Pitch -> [Dur]
musicDurations = flattenMusic $ \p -> case p of
  Note d _ -> [d]
  Rest d   -> [d]

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
