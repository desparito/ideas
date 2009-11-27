-----------------------------------------------------------------------------
-- Copyright 2009, Open Universiteit Nederland. This file is distributed 
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
module Service.ModeXML (processXML) where

import Common.Context
import Common.Exercise
import Common.Strategy hiding (not, fail)
import Common.Transformation hiding (name, defaultArgument)
import Common.Utils (Some(..))
import Control.Monad
import Data.Char
import Data.List
import Data.Maybe
import Service.ExerciseList
import Service.ProblemDecomposition
import Service.Request
import Service.Revision (version)
import Service.ServiceList 
import Service.TypedAbstractService hiding (exercise)
import Service.Types hiding (State)
import Text.OpenMath.Object
import Text.OpenMath.Reply (replyToXML)
import Text.OpenMath.Request (xmlToRequest)
import Text.XML
import qualified Common.Transformation as Rule
import qualified Service.Types as Tp

processXML :: String -> IO (Request, String, String)
processXML input = 
   either fail return $ do
      xml <- parseXML input
      req <- xmlRequest xml
      out <- xmlRequestHandler xml
      return (req, showXML out, "application/xml") 

xmlRequest :: XML -> Either String Request
xmlRequest xml = do   
   unless (name xml == "request") $
      fail "expected xml tag request"
   srv  <- findAttribute "service" xml
   let code = extractExerciseCode xml
   enc  <- case findAttribute "encoding" xml of
              Just s  -> liftM Just (readEncoding s)
              Nothing -> return Nothing 
   return Request 
      { service    = srv
      , exerciseID = code
      , source     = findAttribute "source" xml
      , dataformat = XML
      , encoding   = enc
      }

xmlReply :: Request -> XML -> Either String XML
xmlReply request xml 
   | service request == "mathdox" = do
        code <- maybe (fail "unknown exercise code") return (exerciseID request)
        Some pkg <- getPackage code
        (st, sloc, answer) <-  xmlToRequest xml (fromOpenMath pkg) (exercise pkg)
        return (replyToXML (toOpenMath pkg) (problemDecomposition st sloc answer))

--   | service request == "ping" = do
--        return (resultOk (return ()))

xmlReply request xml = do
   pkg <- case exerciseID request of 
             Just i -> getPackage i
             _ | service request == "exerciselist" -> return (Some (package emptyExercise))
               | otherwise -> fail "unknown exercise code"
   case encoding request of
      Just StringEncoding -> do 
         case stringFormatConverter pkg of
            Some conv -> do
               srv <- getService (service request)
               res <- evalService conv srv xml 
               return (resultOk res)
      _ -> do 
         case openMathConverter pkg of
            Some conv -> do
               srv <- getService (service request)
               res <- evalService conv srv xml 
               return (resultOk res)

xmlRequestHandler :: Monad m => XML -> m XML
xmlRequestHandler xml =
   case xmlRequest xml of 
      Left err -> return (resultError err)
      Right request ->  
         case xmlReply request xml of
            Left err     -> return (resultError err)
            Right result -> return result

extractExerciseCode :: Monad m => XML -> m ExerciseCode
extractExerciseCode xml =
   case liftM (break (== '.')) (findAttribute "exerciseid" xml) of
      Just (as, _:bs) -> return (makeCode as bs)
      Just (as, _)    -> maybe (fail "invalid code") return (readCode as)
      -- being backwards compatible with early MathDox
      Nothing ->
         case fmap getData (findChild "strategy" xml) of
            Just name -> 
               let s ~= t = f s == f t 
                   f = map toLower . filter isAlphaNum
               in case [ exerciseCode ex | Some ex <- exercises, name ~= description ex ] of
                     [code] -> return code
                     _ -> fail $ "Unknown strategy name " ++ show name
            _ -> fail "no exerciseid attribute, nor a known strategy element" 

resultOk :: XMLBuilder -> XML
resultOk body = makeXML "reply" $ do 
   "result"  .=. "ok"
   "version" .=. version
   body

resultError :: String -> XML
resultError txt = makeXML "reply" $ do 
   "result"  .=. "error"
   "version" .=. version
   element "message" (text txt)

------------------------------------------------------------
-- Mixing abstract syntax (OpenMath format) and concrete syntax (string)

stringFormatConverter :: Some ExercisePackage -> Some (Evaluator (Either String) XML XMLBuilder)
stringFormatConverter (Some pkg) = 
   Some $ Evaluator (xmlEncoder False f ex) (xmlDecoder False g pkg)
 where
   ex = exercise pkg
   f  = return . element "expr" . text . prettyPrinter ex
   g xml = do
      xml <- findChild "expr" xml -- quick fix
      -- guard (name xml == "expr")
      let input = getData xml
      either (fail . show) return (parser ex input)
        
openMathConverter :: Some ExercisePackage -> Some (Evaluator (Either String) XML XMLBuilder)
openMathConverter (Some pkg) =
   Some $ Evaluator (xmlEncoder True f ex) (xmlDecoder True g pkg)
 where
   ex = exercise pkg
   f = return . builder . toXML . toOpenMath pkg
   g xml = do
      xob   <- findChild "OMOBJ" xml
      omobj <- xml2omobj xob
      case fromOpenMath pkg omobj of
         Just a  -> return a
         Nothing -> fail "Unknown OpenMath object"

xmlEncoder :: Monad m => Bool -> (a -> m XMLBuilder) -> Exercise a -> Encoder m XMLBuilder a
xmlEncoder b f ex = Encoder
   { encodeType  = encode (xmlEncoder b f ex)
   , encodeTerm  = f
   , encodeTuple = sequence_
   }
 where
   encode :: Monad m => Encoder m XMLBuilder a -> Type a t -> t -> m XMLBuilder
   encode enc serviceType =
      case serviceType of
         Tp.List t1  -> \xs -> 
            case allAreTagged t1 of
               Just f -> do
                  let make = element "elem" . mapM_ (uncurry (.=.)) . f
                  let elems = mapM_ make xs
                  return (element "list" elems)
               _ -> do
                  bs <- mapM (encode enc t1) xs
                  let elems = mapM_ (element "elem") bs
                  return (element "list" elems)
         Tp.Elem t1  -> liftM (element "elem") . encode enc t1
         Tp.Tag s t1 -> liftM (element s) . encode enc t1  -- quick fix
         Tp.Rule     -> return . ("ruleid" .=.) . Rule.name
         Tp.Term     -> encodeTerm enc
         Tp.Context  -> encodeContext b (encodeTerm enc)
         Tp.Location -> return . text . show
         Tp.Bool     -> return . text . show
         Tp.String   -> return . text
         Tp.Int      -> return . text . show
         Tp.State    -> encodeState b (encodeTerm enc)
         _           -> encodeDefault enc serviceType

xmlDecoder :: MonadPlus m => Bool -> (XML -> m a) -> ExercisePackage a -> Decoder m XML a
xmlDecoder b f pkg = Decoder
   { decodeType     = decode (xmlDecoder b f pkg)
   , decodeTerm     = f
   , decoderPackage = pkg
   }
 where
   decode :: MonadPlus m => Decoder m XML a -> Type a t -> XML -> m (t, XML)
   decode dec serviceType = 
      case serviceType of
         Tp.State       -> decodeState b (decoderExercise dec) (decodeTerm dec)
         Tp.Location    -> leave $ liftM (read . getData) . findChild "location"
         Tp.Rule        -> leave $ fromMaybe (fail "unknown rule") . liftM (getRule (decoderExercise dec) . getData) . findChild "ruleid"
         Tp.Term        -> \xml -> decodeTerm dec xml >>= \a -> return (a, xml)
         Tp.StrategyCfg -> decodeConfiguration
         _              -> decodeDefault dec serviceType
         
   leave :: Monad m => (XML -> m a) -> XML -> m (a, XML)
   leave f xml = liftM (\a -> (a, xml)) (f xml)
         
allAreTagged :: Type a t -> Maybe (t -> [(String, String)])
allAreTagged (Tuple t1 t2) = do 
   f1 <- allAreTagged t1
   f2 <- allAreTagged t2
   return $ \(a,b) -> f1 a ++ f2 b
allAreTagged (Triple t1 t2 t3) = do 
   f1 <- allAreTagged t1
   f2 <- allAreTagged t2
   f3 <- allAreTagged t3
   return $ \(a,b,c) -> f1 a ++ f2 b ++ f3 c
allAreTagged (Quadruple t1 t2 t3 t4) = do 
   f1 <- allAreTagged t1
   f2 <- allAreTagged t2
   f3 <- allAreTagged t3
   f4 <- allAreTagged t4
   return $ \(a,b,c,d) -> f1 a ++ f2 b ++ f3 c ++ f4 d
allAreTagged (Tag tag Bool)   = Just $ \b -> [(tag, show b)]
allAreTagged (Tag tag String) = Just $ \s -> [(tag, s)]
allAreTagged _ = Nothing
         
decodeState :: Monad m => Bool -> Exercise a -> (XML -> m a) -> XML -> m (State a, XML)
decodeState b ex f top = do
   xml <- findChild "state" top
   unless (name xml == "state") (fail "expected a state tag")
   let sp = maybe "[]" getData (findChild "prefix" xml)
   expr <- f xml
   env  <- decodeEnvironment b xml
   let state  = State ex (Just (makePrefix (read sp) $ strategy ex)) term
       term   = makeContext env expr
   return (state, top)

decodeEnvironment :: Monad m => Bool -> XML -> m Environment
decodeEnvironment b xml =
   case findChild "context" xml of 
      Just this -> foldM add emptyEnv (children this)
      Nothing   -> return emptyEnv
 where
   add env item = do 
      unless (name item == "item") $ 
         fail $ "expecting item tag, found " ++ name item
      name  <- findAttribute "name"  item
      case findChild "OMOBJ" item of
         -- OpenMath object found inside item tag
         Just this | b -> do
            case xml2omobj this of
               Left err -> fail err
               Right omobj -> 
                  return (storeEnv name omobj env)
         -- Simple value in attribute
         _ -> do
            value <- findAttribute "value" item
            return (storeEnv name value env)

decodeConfiguration :: MonadPlus m => XML -> m (StrategyConfiguration, XML)
decodeConfiguration xml =
   case findChild "configuration" xml of
      Just this -> mapM decodeAction (children this) >>= \xs -> return (xs, xml)
      Nothing   -> fail "no strategy configuration" 
 where
   decodeAction item = do 
      guard (null (children item))
      action <- 
         case find (\a -> map toLower (show a) == name item) configActions of
            Just a  -> return a
            Nothing -> fail $ "unknown action " ++ show (name item)
      cfgloc <- findAttribute "name" item
      return $ (ByName cfgloc, action)


encodeState :: Monad m => Bool -> (a -> m XMLBuilder) -> State a -> m XMLBuilder
encodeState b f state = f (term state) >>= \body -> return $
   element "state" $ do
      element "prefix"  (text $ maybe "[]" show (prefix state))
      encodeEnvironment b (getEnvironment (context state))
      body

encodeEnvironment :: Bool -> Environment -> XMLBuilder
encodeEnvironment b env
   | nullEnv env = return ()
   | otherwise   = element "context" $ do
        forM_ (keysEnv env) $ \k -> do
           element "item" $ do 
              "name"  .=. k
              case lookupEnv k env of 
                 Just omobj | b -> builder  (omobj2xml omobj)
                 _              -> "value" .=. fromMaybe "" (lookupEnv k env)
            
encodeContext :: Monad m => Bool -> (a -> m XMLBuilder) -> Context a -> m XMLBuilder
encodeContext b f ctx = do
   xml <- f (fromContext ctx)
   return (xml >> encodeEnvironment b (getEnvironment ctx))