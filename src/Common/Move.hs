-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- (todo)
--
-----------------------------------------------------------------------------
module Common.Move where

import Control.Monad
import Common.Context
import Common.Transformation
import Common.Utils
import Test.QuickCheck
import Data.List
import Data.Maybe

instance Uniplate a => Move (Context a) where
   moveUp c
      | null (location c) = Nothing
      | otherwise         = Just (changeLocation init c)
   moveLeft = moveToChild $ \xs -> 
                 case xs of
                    [_, _] -> Just 0
                    _      -> Nothing
   moveRight = moveToChild $ \xs -> 
                 case xs of
                    [_, _] -> Just 1
                    _      -> Nothing
   moveDown = moveToChild $ \xs -> 
                 case xs of
                    [_] -> Just 0
                    _   -> Nothing

moveToChild :: Uniplate a => ([a] -> Maybe Int) -> Context a -> Maybe (Context a)
moveToChild f c = do
   p <- currentFocus c
   n <- f (children p)
   return $ changeLocation (++[n]) c
   
class Move a where
   moveLeft, moveRight, moveUp, moveDown :: a -> Maybe a
   movesDown :: a -> [a]
   moveTop :: a -> a
   -- default definition
   moveTop x = maybe x moveTop (moveUp x)
   movesDown x = catMaybes [moveLeft x, moveRight x, moveDown x]

data Movement = MoveLeft | MoveRight | MoveUp | MoveDown
   deriving (Show, Eq, Ord, Enum, Bounded)

-- | Reachable locations (with Left/Right/Down)
reachable :: Move a => a -> [a]
reachable a = a : [ c | Just b <- map ($ a) [moveLeft, moveRight, moveDown], c <- reachable b ]

move :: Move a => Movement -> a -> Maybe a
move MoveLeft  = moveLeft
move MoveRight = moveRight
move MoveUp    = moveUp
move MoveDown  = moveDown

ruleMoveLeft, ruleMoveRight, ruleMoveDown, ruleMoveUp, ruleMoveTop :: Move a => Rule a
ruleMoveLeft  = minorRule $ makeSimpleRule "MoveLeft"  moveLeft
ruleMoveRight = minorRule $ makeSimpleRule "MoveRight" moveRight
ruleMoveUp    = minorRule $ makeSimpleRule "MoveUp"    moveUp
ruleMoveDown  = minorRule $ makeSimpleRule "MoveDown"  moveDown
ruleMoveTop   = minorRule $ makeSimpleRule "MoveTop"   (Just . moveTop)
ruleMovesDown = minorRule $ makeSimpleRuleList "MovesDown" movesDown

ruleMovesDown :: Move a => Rule a

instance Arbitrary Movement where
   arbitrary   = oneof $ map return [minBound..]
   coarbitrary = variant . fromMaybe (-1) . flip elemIndex [minBound..]


{- propM1, propM2, propM3, propM4 :: LogicInContext -> Property
propM1 x = isJust my ==> my==Just x
 where my = applyList [ruleMoveLeft, ruleMoveRight] x
propM2 x = isJust my ==> my==Just x
 where my = applyList [ruleMoveRight, ruleMoveLeft] x
propM3 x = isJust my ==> my==Just x
 where my = applyList [ruleMoveDown, ruleMoveUp] x
propM4 x = isJust my ==> my==Just x
 where my = applyList [ruleMoveUp, ruleMoveDown] x  -}