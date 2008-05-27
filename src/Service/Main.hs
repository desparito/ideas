-----------------------------------------------------------------------------
-- Copyright 2008, Open Universiteit Nederland. This file is distributed 
-- under the terms of the GNU General Public License. For more information, 
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- (...add description...)
--
-----------------------------------------------------------------------------
module Main (main) where

import Common.Exercise hiding (SyntaxError)
import Common.Context
import Common.Strategy (emptyPrefix, makePrefix)
import Common.Transformation (name)
import Common.Utils
import Service.JSON
import Service.XML
import Service.AbstractService
import qualified Service.TypedAbstractService as TAS
import Domain.Derivative.Exercises (derivativeExercise, toExpr, fromExpr)
import Domain.Derivative.Basic
import OpenMath.Object
import System.Environment
import Control.Monad
import Data.Maybe
import Data.Char
import qualified Data.Map as M
import System.IO.Unsafe

main :: IO ()
main = do
   args <- getArgs
   case args of
      [] -> jsonRPCOverHTTP myHandler
      ["--file", filename] -> do
         input <- readFile filename
         txt <- jsonRPC input myHandler
         putStrLn txt
      ["--xml", filename] -> do
         input <- readFile filename
         case parseXML input of
            Left err  -> error err
            Right xml -> putStrLn $ showXML $ serviceXML xml
      _ -> do
         putStrLn "service  (use json-rpc to post a request)"
         putStrLn "   --file filename   (to read the request from file)"

type Service a = a -> [JSON] -> IO JSON

infixr 5 .->.
infix  3 .:.

-- temporary
serviceXML :: XML -> XML
serviceXML request =
   case request of
      Tag "request" attrs _
         | check "derivation" attrs -> 
              let state  = xml2State (fromMaybe (error $ "no state tag" ++ show request) $ findChild (isTag "state") request)
                  list   = TAS.derivation state
                  f (r, a) = Tag "elem" [("ruleid", show r)] [omobj2xml (fromExpr (fromContext a))]
              in Tag "reply" [("result", "ok"), ("version", "0.1")] [Tag "list" [] (map f list)]
         | check "allfirsts" attrs -> 
              let state  = xml2State (fromMaybe (error $ "no state tag" ++ show request) $ findChild (isTag "state") request)
                  list   = TAS.allfirsts state
                  f (r, _, a) = Tag "elem" [("ruleid", show r)] [state2xml a]
              in Tag "reply" [("result", "ok"), ("version", "0.1")] [Tag "list" [] (map f list)]
         | check "onefirst" attrs -> 
              let state  = xml2State (fromMaybe (error $ "no state tag" ++ show request) $ findChild (isTag "state") request)
                  this   = TAS.onefirst state
                  f (r, _, a) = Tag "elem" [("ruleid", show r)] [state2xml a]
              in Tag "reply" [("result", "ok"), ("version", "0.1")] [f this]
         | check "ready" attrs -> 
              let state = xml2State (fromMaybe (error $ "no state tag" ++ show request) $ findChild (isTag "state") request)
                  bool  = TAS.ready state
              in Tag "reply" [("result", "ok"), ("version", "0.1")] [Text $ show bool]
         | check "stepsremaining" attrs -> 
              let state = xml2State (fromMaybe (error $ "no state tag" ++ show request) $ findChild (isTag "state") request)
                  int  = TAS.ready state
              in Tag "reply" [("result", "ok"), ("version", "0.1")] [Text $ show int]
         | check "applicable" attrs -> 
              let loc   = fromMaybe (error "no location") (extractText "location" request)
                  state = xml2State (fromMaybe (error $ "no state tag" ++ show request) $ findChild (isTag "state") request)
                  list  = TAS.applicable (read loc) state
                  f r   = Tag "elem" [("ruleid", show r)] []
              in Tag "reply" [("result", "ok"), ("version", "0.1")] [Tag "list" [] (map f list)]
         | check "apply" attrs -> 
              let rid   = fromMaybe (error "no ruleid") (extractText "ruleid" request)
                  rule  = fromMaybe (error "invalid ruleid") $ safeHead $ filter p (ruleset derivativeExercise)
                  p     = (==rid) . name
                  loc   = fromMaybe (error "no location") (extractText "location" request)
                  state = xml2State (fromMaybe (error $ "no state tag" ++ show request) $ findChild (isTag "state") request)
                  this  = TAS.apply rule (read loc) state
              in Tag "reply" [("result", "ok"), ("version", "0.1")] [state2xml this]
         | check "generate" attrs -> 
              let diff  = fromMaybe (error "no difficulty") $ lookup "difficulty" attrs 
                  state = unsafePerformIO $ TAS.generate derivativeExercise (read diff)
              in Tag "reply" [("result", "ok"), ("version", "0.1")] [state2xml state]
      _ -> error "invalid request"
 where
   check s attrs = lookup "exerciseid" attrs == Just "Derivative" && 
                   lookup "service" attrs == Just s

xml2State :: XML -> TAS.State Expr
xml2State xml@(Tag "state" _ _) = fromMaybe (error "invalid state in request") $ do
   sp <- extractText "prefix"  xml
   sc <- Just $ maybe "" id $ extractText "context" xml
   x  <- findChild (isTag "OMOBJ") xml
   let state  = (derivativeExercise, Just (makePrefix (read sp) $ strategy derivativeExercise), term)
       contxt = fromMaybe (error $ "invalid context" ++ show sc) $ parseContext sc
       expr   = either (error . show) toExpr $ xml2omobj x
       term   = fmap (const expr) contxt
   return state
xml2State _ = error "expected a state tag"

state2xml :: TAS.State Expr -> XML
state2xml (ex, mp, ca) = Tag "state" [] 
   [ Tag "prefix"  [] [Text $ maybe "[]" show mp]
   , Tag "context" [] [Text $ showContext ca] 
   , omobj2xml (fromExpr (fromContext ca))
   ]

service :: InJSON a => Service a
service a xs = do
   unless (null xs) (fail "Too many arguments for service")
   return (toJSON a)
     
(.->.) :: InJSON a => c -> Service b -> Service (a -> b)
_ .->. srv = \f args ->
   case args of 
      x:xs ->
         case fromJSON x of
            Just b -> srv (f b) xs
            _      -> fail "Invalid argument"
      _ -> fail $ "Argument not found for service"

(.:.) :: a -> (a -> b) -> b
(.:.) = flip ($)

io :: InJSON a => Service a -> Service (IO a)
io srv ma xs = do
   a <- ma
   srv a xs

service1 f = (() .->. service)  f 
service2 f = (() .->. service1) f
service3 f = (() .->. service2) f

serviceTable :: M.Map String ([JSON] -> IO JSON)
serviceTable = M.fromList
   [ ("stepsremaining", stepsremaining .:. service1)
   , ("ready",          ready          .:. service1)
   , ("apply",          apply          .:. service3)
   , ("applicable",     applicable     .:. service2)
   , ("onefirst",       onefirst       .:. service1)
   , ("allfirsts",      allfirsts      .:. service1)
   , ("derivation",     derivation     .:. service1)
   , ("generate",       generate       .:. () .->. () .->. io (service))
   , ("submit",         submit         .:. service2)
   ]
{- 
 where
   state      = P "state"      :: Parameter State
   ruleid     = P "ruleid"     :: Parameter RuleID
   location   = P "location"   :: Parameter Location
   exerciseid = P "exerciseid" :: Parameter ExerciseID
   int        = P "int"        :: Parameter Int
   expression = P "expression" :: Parameter Expression -}

-- data Parameter a = P String

myHandler :: JSON_RPC_Handler
myHandler fun arg = 
   case (M.lookup fun serviceTable, arg) of
      (Just f, Array args) -> f args
      (Just _, _) -> fail $ "The params part is not an object"
      _ -> fail $ "Unknown function: " ++ fun

instance InJSON a => InJSON (Context a) where
   toJSON   = toJSON . fromContext
   fromJSON = fmap inContext . fromJSON
   
instance InJSON Location where
   toJSON              = toJSON . show
   fromJSON (String s) = case reads s of
                            [(loc, rest)] | all isSpace rest -> Just loc
                            _ -> Nothing
   fromJSON _          = Nothing

instance InJSON Result where
   toJSON result = Object $
      case result of
         SyntaxError   -> [("result", String "SyntaxError")]
         Buggy rs      -> [("result", String "Buggy"), ("rules", Array $ map String rs)]
         NotEquivalent -> [("result", String "NotEquivalent")]   
         Ok rs st      -> [("result", String "Ok"), ("rules", Array $ map String rs), ("state", toJSON st)]
         Detour rs st  -> [("result", String "Detour"), ("rules", Array $ map String rs), ("state", toJSON st)]
         Unknown st    -> [("result", String "Unknown"), ("state", toJSON st)]
   fromJSON (Object xs) = do
      mj <- lookup "result" xs
      ms <- fromString mj
      let getRules = (lookup "rules" xs >>= fromJSON) :: Maybe [RuleID]
          getState = (lookup "state" xs >>= fromJSON) :: Maybe State
      case ms of
         "syntaxerror"   -> return SyntaxError
         "buggy"         -> liftM  Buggy getRules
         "notequivalent" -> return NotEquivalent
         "ok"            -> liftM2 Ok getRules getState
         "detour"        -> liftM2 Detour getRules getState
         "unkown"        -> liftM  Unknown getState
   fromJSON _ = Nothing

fromString :: JSON -> Maybe String
fromString (String s) = Just (map toLower s)
fromString _          = Nothing

{-fromXmlRequest :: XML -> Either String (String, [JSON])
fromXmlRequest (Tag "request" attrs xs) = 
   case lookup "method" attrs of 
      Just f -> return (f, undefined)
fromXmlRequest _ = fail "not a request tag"

json2xml :: JSON -> XML
json2xml json = 
   case json of
      Number (I n) -> single "int" (show n)
      Number (F f) -> single "float" (show f)
      Boolean b    -> single "bool" (if b then "true" else "false")
      Null         -> Tag "null" [] []
      String s     -> Text s
      _            -> Tag "list" [] (json2xmls json)
 where
   single tag v = Tag tag [("value", v)] []
      
json2xmls :: JSON -> [XML]
json2xmls json =
   case json of 
      Array xs  -> map json2xml xs
      Object xs -> map (\(s, x) -> Tag s [] (json2xmls x)) xs
      _ -> [json2xml json]
      
xml2json :: XML -> JSON
xml2json xml =
   case xml of
      Text s            -> String s
      Tag "int"   as [] -> Number $ I $ fromMaybe 0 $ lookup "value" as >>= safeRead
      Tag "float" as [] -> Number $ F $ fromMaybe 0 $ lookup "value" as >>= safeRead
      Tag "bool"  as [] -> Boolean $ maybe False ((=="true") . trim) (lookup "value" as)
      Tag "null"  as [] -> Null
      Tag "list"  as [] -> undefined
 where      
   safeRead :: Read a => String -> Maybe a
   safeRead s = case reads s of 
                   [(a, rest)] | all isSpace rest -> return a
                   _ -> Nothing
                   
xmls2json :: [XML] -> JSON
xmls2json = mapM f 
 where
   f (Tag-}