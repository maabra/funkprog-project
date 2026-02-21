module Genetic (
    evolve,
    writeMusic
) where

import Euterpea
-- | import Codec.Midi (exportFile)
import System.Random (randomRIO)
import Control.Monad (replicateM, foldM)
import Data.List (sortOn)

type Melody = [Pitch]
type Population = [Melody]

melodyLen :: Int
melodyLen = 8

{-
-- | rng gen za element iz liste
elements :: [a] -> IO a
elements xs = (xs !!) <$> randomRIO (0, length xs - 1)
-}
-- | generiranje random pitcheva, ogranicenje na major skali
randomPitch :: IO Pitch
randomPitch = do
    let pitches = [C, D, E, F, G, A, B]
    pc <- (pitches !!) <$> randomRIO (0, 6)
    oct <- randomRIO (4, 5)
    return (pc, oct)

randomMelody :: IO Melody
randomMelody = replicateM melodyLen randomPitch

randomPopulation :: Int -> IO Population
randomPopulation n = replicateM n randomMelody
{-
-- | major skala, ali to je samo da se ne bi zezali sa invalidnim notama
randomPitch :: IO Pitch
randomPitch = do
    pc <- elements [C, D, E, F, G, A, B]
    oct <- randomRIO (4, 5)
    return (pc, oct)
-}

-- | fitness, poboljsani, isti princip
fitness :: Melody -> Double
fitness m = fromIntegral $ length $ filter id $ zipWith smallInterval m (tail m)
  where
    smallInterval p1 p2 = abs (absPitch p1 - absPitch p2) <= 2

-- | descending, da se najbolje melodije nalaze na pocetku liste
selectBest :: Population -> Int -> Population
selectBest pop n = take n $ reverse $ sortOn fitness pop
{-
-- | bazicni fitness, koji nagraduje melodije koje imaju male intervale izmedu susjednih nota (<= 2 polutona), da je muzikalno
fitness :: Melody -> Double
fitness m = fromIntegral $ sum $ zipWith score m (tail m)
  where
    score :: Pitch -> Pitch -> Int
    score (pc1, o1) (pc2, o2)
        | abs (absPitch (pc1, o1) - absPitch (pc2, o2)) <= 2 = 1
        | otherwise = 0
-}

-- | crossover, spaja dvije melodije tako da uzima pocetak od jedne i kraj od druge, na random crossover pointu
crossover :: Melody -> Melody -> IO Melody
crossover a b = do
    point <- randomRIO (1, melodyLen - 1)
    return $ take point a ++ drop point b

-- | mutiranje, mijenja jednu notu u melodiji na random poziciji
mutate :: Melody -> IO Melody
mutate m = do
    idx <- randomRIO (0, melodyLen - 1)
    newp <- randomPitch
    return $ take idx m ++ [newp] ++ drop (idx + 1) m

-- | generira novu generaciju: zadrzava najbolje melodije (elites) i popunjava ostatak populacije djecom nastalom crossoverom i mutacijom
nextGeneration :: Population -> IO Population
nextGeneration pop = do
    let elites = selectBest pop (length pop `div` 2)
    children <- replicateM (length pop - length elites) $ do
        i <- randomRIO (0, length elites - 1)
        j <- randomRIO (0, length elites - 1)
        child <- crossover (elites !! i) (elites !! j)
        mutate child
    return $ elites ++ children

-- | loop, koji ponavlja proces evolucije za zadani broj generacija
evolve :: Int     -- ^ generacije
       -> Int     -- ^ popSize
       -> IO (Music Pitch)
evolve gens popSize = do
    pop0 <- randomPopulation popSize
    finalPop <- foldM (\pop _ -> nextGeneration pop) pop0 [1..gens]
    let bestMelody = head $ selectBest finalPop 1
    return $ melodyToMusic bestMelody

-- | konvertiranje melodije u Euterpea glazbu          

-- | melodyToMusic :: Melody -> Music Pitch
-- | melodyToMusic = line . map (note qn)

-- | writeMusic :: FilePath -> Music Pitch -> IO ()
-- | writeMusic fp m = writeMidi fp (toMidi m)

melodyToMusic :: Melody -> Music Pitch
melodyToMusic = line . map (note qn)

writeMusic :: FilePath -> Music Pitch -> IO ()
writeMusic = writeMidi
