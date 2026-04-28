{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}

module Constraint
  ( solveMelody
  , solveMelodyWithSeed
  , extractPCs
  , MusicConstraint(..)
  ) where
import Euterpea hiding (pcToInt) -- izbjegavamo konflikt s funkcijom pcToInt u SMT solveru
import qualified Euterpea as E
import Data.SBV
import Data.SBV.Control
import Control.Monad (forM, when)
import System.Random (randomRIO)
import Data.List (tails)

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
solveMelody n constraints = tryRandom 1000000 1
  where
    root = getRoot constraints

    tryRandom 0 _ = return $ Left "Nije pronadena validna melodija nakon 1000 pokusaja"

    tryRandom k attempt = do
      putStrLn $ "Pokusaj " ++ show attempt ++ " / 1000"

      m <- rngMelody n root   -- ✅ FIXED
      let vals = extractPCs m
      ok <- checkMelody vals constraints

      if ok
        then do
          putStrLn $ "Pronadena solucija nakon " ++ show attempt
          return (Right m)
        else tryRandom (k - 1) (attempt + 1)


solveMelodyWithSeed :: [Integer] -> [MusicConstraint] -> IO (Either String (Music Pitch))
solveMelodyWithSeed seed constraints = runSMT $ do

  notes <- forM (zip [1..] seed) $ \(i, v) -> do
      p <- sInteger ("note" ++ show i)
      constrain $ p .== literal v   -- forsiranje note iz genetske melodije kao pocetne tocke
      return p

  mapM_ (applyConstraint notes) constraints

  query $ do
    cs <- checkSat
    case cs of
      Unsat -> return $ Left "GA melodija ne zadovoljava sve constrainte"
      Sat   -> return $ Right (buildMusic seed)
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
  let maxV = literal (fromIntegral maxVal)
  mapM_ (\(n1, n2) ->
    constrain $ sAbs (n2 - n1) .<= maxV
    ) (zip notes (tail notes))

-- MinStep: osigurava minimalni interval između uzastopnih nota (za raznolikost)
applyConstraint notes (MinStep minVal) = do
  let minV = literal (fromIntegral minVal)
  mapM_ (\(n1, n2) ->
    constrain $ sAbs (n2 - n1) .>= minV
    ) (zip notes (tail notes))

-- MotifLength: osigurava varijaciju u frazama (svaka N nota mora biti različita)
applyConstraint notes (MotifLength m) = do
  let total = length notes

  sequence_
    [ constrain (a ./= b)
    | i <- [0, m .. total - m]
    , let segment = take m (drop i notes)
    , (a:rest) <- tails segment
    , b <- rest
    ]
    
-- gradnja Euterpea glazbe iz rjesenja
buildMusic :: [Integer] -> Music Pitch
buildMusic pcs =
  E.line $ map (\pc -> E.note E.qn (intToPc pc, 4)) pcs

-- RNG melodija: nasumična melodija od n nota u zadanoj ljestvici
rngMelody :: Int -> PitchClass -> IO (Music Pitch)
rngMelody n root = do
  let scale = majorScale root
  notes <- sequence $ replicate n $ do
    r <- randomRIO (0, length scale - 1)
    return $ scale !! r
  return $ E.line $ map (\pc -> E.note E.qn (intToPc pc, 4)) notes

checkMelody :: [Integer] -> [MusicConstraint] -> IO Bool
checkMelody vals constraints = runSMT $ do
  notes <- forM (zip [1..] vals) $ \(i, v) -> do
    p <- sInteger ("note" ++ show i)
    constrain $ p .== literal v
    return p

  mapM_ (applyConstraint notes) constraints

  query $ do
    cs <- checkSat
    return (cs == Sat)

extractPCs :: Music Pitch -> [Integer]
extractPCs (Prim (Note _ (pc, _))) = [pcToInt pc]
extractPCs (m1 :+: m2) = extractPCs m1 ++ extractPCs m2
extractPCs _ = []

sAbs :: SInteger -> SInteger
sAbs x = ite (x .>= 0) x (-x)

getRoot :: [MusicConstraint] -> PitchClass
getRoot constraints =
  case [r | InKey r <- constraints] of
    (r:_) -> r
    []    -> C  -- default if none provided
{-
-- TEST
example :: IO ()
example = do
  result <- solveMelody 8 [InKey C]
  case result of
    Left err -> putStrLn err
    Right music -> E.writeMidi "output.mid" music
-}