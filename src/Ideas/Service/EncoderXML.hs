{-# LANGUAGE GADTs #-}
-----------------------------------------------------------------------------
-- Copyright 2011, Open Universiteit Nederland. This file is distributed
-- under the terms of the GNU General Public License. For more information,
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- Services using XML notation
--
-----------------------------------------------------------------------------
module Ideas.Service.EncoderXML (xmlEncoder, encodeState) where

import Control.Monad
import Data.Char
import Data.Maybe
import Ideas.Common.Library hiding (exerciseId, (:=))
import Ideas.Common.Utils (Some(..))
import Ideas.Service.Diagnose
import Ideas.Service.Evaluator
import Ideas.Service.FeedbackScript.Syntax
import Ideas.Service.OpenMathSupport
import Ideas.Service.RulesInfo (rulesInfoXML)
import Ideas.Service.State
import Ideas.Service.StrategyInfo
import Ideas.Service.BasicServices (StepInfo)
import Ideas.Service.Types
import qualified Ideas.Service.ProblemDecomposition as PD
import Ideas.Text.OpenMath.Object
import Ideas.Text.XML
import qualified Ideas.Service.FeedbackText as FeedbackText

xmlEncoder :: Bool -> (a -> XMLBuilder) -> Exercise a -> Encoder (Type a) XMLBuilder
xmlEncoder isOM enc ex tv@(val ::: tp) = msum
   [ encodeWith (encodeDiagnosis isOM enc) tv
   , encodeWith (encodeDecompositionReply isOM enc) tv
   , encodeWith (encodeDerivation rec) tv
   , encodeWith (encodeDerivationText isOM enc) tv
   ] `mplus`
   case tp of
      -- meta-information
      Tag "RuleShortInfo" t -> do
         f <- equalM t (Const Rule)
         ruleShortInfo (f val)
      Tag "difficulty" (Iso iso (Const String)) ->
         "difficulty" .=. to iso val
      Tag "RulesInfo" _ -> 
         rulesInfoXML ex enc
      Tag "message" _ -> do
         f <- equalM tp (typed :: Type a FeedbackText.Message)
         let msg = f val
         element "message" $ do
            case FeedbackText.accept msg of
               Just b  -> "accept" .=. showBool b
               Nothing -> return ()
            encodeText enc ex (FeedbackText.text msg)
      Tag "elem" t -> 
         element "elem" (xmlEncoder isOM enc ex (val ::: t))
      -- special case for onefirst service; insert elem Tag
      Const String :|: Pair t (Const State) | isJust (equal stepInfoType t) ->
         rec (val ::: (Const String :|: Tag "elem" (Pair t (Const State))))
      -- special case for exceptions
      Const String :|: t -> 
         case val of
            Left s  -> fail s
            Right a -> rec (a ::: t)
      -- special cases for lists
      List (Const Rule) -> encodeAsList (map ruleShortInfo val)
      List t -> encodeAsList (map (\a -> rec (a ::: t)) val)
      _ -> encodeTypeRepFix (xmlEncoderConst isOM enc ex) rec tv
 where
   rec = xmlEncoder isOM enc ex

   stepInfoType :: Type a (StepInfo a)
   stepInfoType = typed

encodeAsList :: [XMLBuilder] -> XMLBuilder
encodeAsList = element "list" . mapM_ (element "elem")

xmlEncoderConst :: Bool -> (a -> XMLBuilder) -> Exercise a -> Encoder (Const a) XMLBuilder
xmlEncoderConst isOM enc ex tv@(val ::: tp) =
   case tp of
      SomeExercise -> case val of
                         Some a -> exerciseInfo a
      Strategy  -> builder (strategyToXML val)
      Rule      -> "ruleid" .=. show val
      State     -> encodeState isOM enc val
      Context   -> encodeContext isOM enc val
      Location  -> "location" .=. show val
      Environment -> encodeEnvironment isOM val
      Text      -> encodeText enc ex val
      Bool      -> text (showBool val)
      _         -> text (show tv)

encodeState :: Bool -> (a -> XMLBuilder) -> State a -> XMLBuilder
encodeState isOM enc st = element "state" $ do
   mapM_ (element "prefix" . text . show) (statePrefixes st)
   encodeContext isOM enc (stateContext st)

ruleShortInfo :: Rule (Context a) -> XMLBuilder
ruleShortInfo r = do 
   "name"        .=. showId r
   "buggy"       .=. showBool (isBuggy r)
   "arguments"   .=. show (length (getRefs r))
   "rewriterule" .=. showBool (isRewriteRule r)

encodeEnvironment :: HasEnvironment a => Bool -> a -> XMLBuilder
encodeEnvironment isOM = mapM_ (encodeTypedBinding isOM) . bindings

encodeContext :: Bool -> (a -> XMLBuilder) -> Context a -> XMLBuilder
encodeContext isOM f ctx = do
   a <- fromContext ctx
   f a
   unless (null values) $ element "context" $
      forM_ values $ \tb ->
         element "item" $ do
            "name"  .=. showId tb
            case getTermValue tb of
               term | isOM -> 
                  builder (omobj2xml (toOMOBJ term))
               _ -> "value" .=. showValue tb
 where
   loc    = fromLocation (location ctx)
   values = bindings (withLoc ctx)
   withLoc
      | null loc  = id
      | otherwise = insertRef (makeRef "location") loc

encodeTypedBinding :: Bool -> Binding -> XMLBuilder
encodeTypedBinding b tb = element "argument" $ do
   "description" .=. showId tb
   case getTermValue tb of
      term | b -> builder $ 
         omobj2xml $ toOMOBJ term
      _ -> text (showValue tb)

encodeDerivation :: Encoder (Type a) XMLBuilder -> Derivation (Rule (Context a), Environment) (Context a) -> XMLBuilder
encodeDerivation enc d = 
   let xs = [ (s, a) | (_, s, a) <- triples d ]
   in enc (xs ::: typed)

encodeDerivationText :: Bool -> (a -> XMLBuilder) -> Derivation String (Context a) -> XMLBuilder
encodeDerivationText isOM enc = encodeAsList . map f . triples
 where
   f (_, s, a) = do
      "ruletext" .=. s
      encodeContext isOM enc a

encodeDiagnosis :: Bool -> (a -> XMLBuilder) -> Diagnosis a -> XMLBuilder
encodeDiagnosis isOM enc diagnosis = 
   case diagnosis of
      Buggy env r -> element "buggy" $ do 
         encodeEnvironment isOM env
         "ruleid" .=. showId r
      NotEquivalent -> tag "notequiv"
      Similar b st -> element "similar" $ do
         "ready" .=. showBool b
         encodeState isOM enc st
      Expected b st r -> element "expected" $ do
         "ready" .=. showBool b
         encodeState isOM enc st
         "ruleid" .=. showId r
      Detour b st env r -> element "detour" $ do
         "ready" .=. showBool b
         encodeState isOM enc st
         encodeEnvironment isOM env
         "ruleid" .=. showId r
      Correct b st -> element "correct" $ do
         "ready" .=. showBool b
         encodeState isOM enc st
   
encodeDecompositionReply :: Bool -> (a -> XMLBuilder) -> PD.Reply a -> XMLBuilder
encodeDecompositionReply isOM enc reply =
   case reply of
      PD.Ok loc st -> element "correct" $ do 
         element "location" $ text $ show loc
         encodeState isOM enc st
      PD.Incorrect eq loc st env -> element "incorrect" $ do
         "equivalent" .=. showBool eq
         element "location" $ text $ show loc
         encodeState isOM enc st
         encodeEnvironment isOM env
   
encodeText :: (a -> XMLBuilder) -> Exercise a -> Text -> XMLBuilder
encodeText f ex = mapM_ make . textItems
 where
   make t@(TextTerm a) = fromMaybe (text (show t)) $ do
      v <- hasTermView ex
      b <- match v a
      return (f b)
   make a = text (show a)

exerciseInfo :: Exercise a -> XMLBuilder 
exerciseInfo ex = do
   "exerciseid"  .=. showId ex
   "description" .=. description ex
   "status"      .=. show (status ex)

showBool :: Bool -> String
showBool = map toLower . show