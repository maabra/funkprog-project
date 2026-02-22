{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}

module Constraint where

import Euterpea
import Data.SBV
import Data.SBV.Control
import Control.Monad (forM)

{-
solveComposition :: CompositionSpec -> SolveResult
solveComposition spec =
  let m = basePattern spec
      cs = constraints spec
  in if all (checkConstraint m) cs
        then Right m
        else Left "base pattern does not satisfy all constraints"
-}

-- NOVI SMT SOLVER

-- mapiranje PitchClass -> Int (0-11)
pcToInt :: PitchClass -> Integer
pcToInt pc = case pc of
  C  -> 0;  Cs -> 1;  D  -> 2;  Ds -> 3
  E  -> 4;  F  -> 5;  Fs -> 6;  G  -> 7
  Gs -> 8;  A  -> 9;  As -> 10; B  -> 11

intToPc :: Integer -> PitchClass
intToPc n = case n `mod` 12 of
  0  -> C; 1  -> Cs; 2  -> D; 3  -> Ds
  4  -> E; 5  -> F; 6  -> Fs; 7  -> G
  8  -> Gs; 9  -> A; 10 -> As; 11 -> B
  _  -> C

-- skala (Major)

majorScale :: PitchClass -> [Integer]
majorScale root =
  let r = pcToInt root
      intervals = [0,2,4,5,7,9,11]
  in map (\i -> (r + i) `mod` 12) intervals

-- constraint tipovi

data MusicConstraint
  = InKey PitchClass
  | MelodyLength Int
  deriving (Show, Eq)

-- SMT Solver koristeći SBV (Z3 backend)

solveMelody :: Int -> [MusicConstraint] -> IO (Either String (Music Pitch))
solveMelody n constraints = runSMT $ do

  -- n simboličkih nota (pitch class 0-11)
  notes <- forM [1..n] $ \i ->
      sInteger ("note" ++ show i)

  -- svaka nota mora biti 0-11
  mapM_ (\p -> constrain $ p .>= 0 .&& p .<= 11) notes

  -- primjena constrainta
  mapM_ (applyConstraint notes) constraints

  query $ do
    cs <- checkSat
    case cs of
      Unsat -> return $ Left "No solution"
      Sat -> do
        vals <- mapM getValue notes
        return $ Right (buildMusic vals)

-- primjena constrainta

applyConstraint :: [SInteger] -> MusicConstraint -> Symbolic ()

applyConstraint notes (InKey root) = do
  let scale = majorScale root
  mapM_ (\p -> constrain $ sOr [p .== literal x | x <- scale]) notes

applyConstraint notes (MelodyLength n) =
  constrain $ literal (length notes) .== literal n

-- gradnja Euterpea glazbe iz rješenja

buildMusic :: [Integer] -> Music Pitch
buildMusic pcs =
  line $ map (\pc -> note qn (intToPc pc, 4)) pcs

-- TEST

example :: IO ()
example = do
  result <- solveMelody 8 [InKey C]
  case result of
    Left err -> putStrLn err
    Right music -> writeMidi "output.mid" music