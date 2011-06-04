{-# LANGUAGE Rank2Types #-}
-----------------------------------------------------------------------------
-- Copyright 2010, Open Universiteit Nederland. This file is distributed 
-- under the terms of the GNU General Public License. For more information, 
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-----------------------------------------------------------------------------
module Service.OpenMathSupport
   ( -- * Conversion functions to/from OpenMath
     toOpenMath, fromOpenMath
   , termToOMOBJ, omobjToTerm
   ) where

import Common.Library
import Common.Rewriting.Term
import Control.Monad
import Data.Char
import Data.List
import Text.OpenMath.Object
import qualified Text.OpenMath.Symbol as OM
import Text.OpenMath.Dictionary.Fns1

-----------------------------------------------------------------------------
-- Utility functions for conversion to/from OpenMath

toOpenMath :: Monad m => Exercise a -> a -> m OMOBJ 
toOpenMath ex a = do
   v <- hasTermViewM ex 
   return (termToOMOBJ (build v a))

fromOpenMath :: MonadPlus m => Exercise a -> OMOBJ -> m a
fromOpenMath ex omobj = do 
   v <- hasTermViewM ex 
   a <- omobjToTerm omobj
   matchM v a

termToOMOBJ :: Term -> OMOBJ
termToOMOBJ term =
   case term of
      Var s     -> OMV s
      Con s     -> OMS (idToSymbol (getId s))
      Meta i    -> OMV ('$' : show i)
      Num n     -> OMI n
      Float d   -> OMF d
      Apply _ _ -> let (f, xs) = getSpine term
                   in make (map termToOMOBJ (f:xs))
 where
   make [OMS s, OMV x, body] | s == lambdaSymbol = 
      OMBIND (OMS s) [x] body
   make xs = OMA xs

omobjToTerm :: MonadPlus m => OMOBJ -> m Term
omobjToTerm omobj =
   case omobj of 
      OMV x -> case isMeta x of
                  Just n  -> return (Meta n)
                  Nothing -> return (Var x)
      OMS s -> return (symbol (newSymbol (OM.dictionary s # OM.symbolName s)))
      OMI n -> return (Num n)
      OMF a -> return (Float a)
      OMA (x:xs) -> liftM2 makeTerm (omobjToTerm x) (mapM omobjToTerm xs)
      OMBIND binder xs body ->
         omobjToTerm (OMA (binder:map OMV xs++[body]))
      _ -> fail "Invalid OpenMath object"
 where
   isMeta ('$':xs) = Just (foldl' (\a b -> a*10+ord b-48) 0 xs) -- '
   isMeta _        = Nothing

idToSymbol :: Id -> OM.Symbol
idToSymbol a
   | null (qualifiers a) = 
        OM.extraSymbol (unqualified a)
   | otherwise = 
        OM.makeSymbol (qualification a) (unqualified a)
        
hasTermViewM  :: Monad m => Exercise a -> m (View Term a)
hasTermViewM = maybe (fail "No support for terms") return . hasTermView