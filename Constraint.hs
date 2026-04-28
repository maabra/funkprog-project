{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}

module Constraint where

import Euterpea hiding (pcToInt) -- izbjegavamo konflikt s funkcijom pcToInt u SMT solveru
import qualified Euterpea as E
import Data.SBV
import Data.SBV.Control
import Control.Monad (forM, when)

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
  -- | MelodyLength Int
  | Diverse                    -- bez uzastopnih identičnih nota
  | MaxStep Int                -- max interval između uzastopnih nota (za veće skokove)
  | MinStep Int                -- min interval između uzastopnih nota (za raznolikost)
  | MotifLength Int           -- duljina motiva/fraze za varijaciju
  deriving (Show, Eq)

-- SMT Solver koristeći SBV (Z3 backend)
solveMelody :: Int -> [MusicConstraint] -> IO (Either String (Music Pitch))
solveMelody n constraints = runSMT $ do

  -- n simbolickih nota (pitch class 0-11)
  notes <- forM [1..n] $ \i ->
      sInteger ("note" ++ show i)

  -- svaka nota mora biti 0-11
  mapM_ (\p -> constrain $ p .>= 0 .&& p .<= 11) notes

  -- primjena constrainta
  mapM_ (applyConstraint notes) constraints

  query $ do
    cs <- checkSat
    case cs of
      Unsat -> return $ Left "Nema rjesenja"
      Sat -> do
        vals <- mapM getValue notes
        return $ Right (buildMusic vals)

-- primjena constrainta
applyConstraint :: [SInteger] -> MusicConstraint -> Symbolic ()
applyConstraint notes (InKey root) = do
  let scale = majorScale root
  mapM_ (\p -> constrain $ sOr [p .== literal x | x <- scale]) notes
{- 

-- neiskorišteni constraint za duljinu melodije, no duljina je prethodno definirana tako da je nepotrebna
applyConstraint notes (MelodyLength n) = do
  -- length notes vraca Int, treba nam Integer za SBV
  let actualLen = fromIntegral (length notes) :: Integer
      expectedLen = fromIntegral n :: Integer
  constrain $ literal actualLen .== literal expectedLen
-}
-- Diverse constraint: zabrana uzastopnih identičnih nota
{-
applyConstraint notes Diverse = do
  -- zabrana susjednih identičnih nota
  mapM_ (\(n1, n2) -> constrain $ n1 .!= n2) (zip notes (tail notes))
  -- minimum 50% različitih nota
  let n = length notes
      minVariety = (fromIntegral n + 1) `div` 2 :: Integer
  distinctCount <- sInteger "distinctCount"
  constrain $ distinctCount .>= literal minVariety
-}

applyConstraint notes Diverse = do
  -- zabrana susjednih identičnih nota
  mapM_ (\(n1, n2) -> constrain $ sNot (n1 .== n2)) (zip notes (tail notes))

-- MaxStep: ograničava maksimalni interval između uzastopnih nota
applyConstraint notes (MaxStep maxVal) = do
  let pairs = zip notes (tail notes)
  mapM_ (\(n1, n2) -> constrain $ sOr 
        [ n2 .== n1 + literal (fromIntegral maxVal)
        , n2 .== n1 - literal (fromIntegral maxVal)
        , sNot (n1 .== n2)  -- ili ista nota
        ]) pairs

-- MinStep: osigurava minimalni interval između uzastopnih nota (za raznolikost)
applyConstraint notes (MinStep minVal) = do
  let pairs = zip notes (tail notes)
      minValInt = fromIntegral minVal :: Integer
  mapM_ (\(n1, n2) -> constrain $ 
        sOr [ sNot (n1 .== n2)  -- različite note
            , sAnd [ n2 .== n1 + literal i | i <- [-minValInt..minValInt] ]  -- ili minimalan pomak
            ]) pairs

-- MotifLength: osigurava varijaciju u frazama (svaka N nota mora biti različita)
applyConstraint notes (MotifLength motifLen) = do
  let totalNotes = length notes
      indices = [0, motifLen .. totalNotes - 1]
  mapM_ (\i -> do
    let segment = take motifLen (drop i notes)
    when (length segment >= 2) $ do
      mapM_ (\(n1, n2) -> constrain $ sNot (n1 .== n2)) 
            (zip segment (tail segment))
    ) indices

-- gradnja Euterpea glazbe iz rjesenja
buildMusic :: [Integer] -> Music Pitch
buildMusic pcs =
  E.line $ map (\pc -> E.note E.qn (intToPc pc, 4)) pcs
{-
-- TEST
example :: IO ()
example = do
  result <- solveMelody 8 [InKey C]
  case result of
    Left err -> putStrLn err
    Right music -> E.writeMidi "output.mid" music
-}