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
-- Main module for feedback services
--
-----------------------------------------------------------------------------
{-# OPTIONS -fglasgow-exts #-}
module Main (main) where

import Common.Logging
import Common.Utils (stringToHex, useFixedStdGen)
import Service.Options
import Service.ModeXML  (processXML)
import Service.ModeJSON (processJSON)
import Network.CGI
import Control.Monad.Trans
import Control.Monad
import Data.Maybe
import Data.Char

main :: IO ()
main = do
   flags <- serviceOptions
   (if withLogging flags then logActionWith config "Response time" else id) $ do
   case withInputFile flags of
      Just file -> do  
         useFixedStdGen                 -- use a predictable "random" number generator
         input    <- readFile file
         (txt, _) <- process Nothing Nothing flags input
         putStrLn txt
      Nothing -> runCGI $ do
         raw    <- getInput "input"     -- read input
         mode   <- getInput "mode" 
         method <- requestMethod        -- HTTP method, e.g. GET, HEAD or POST
         body   <- queryString
         addr   <- remoteAddr           -- the IP address of the remote host making the request
         server <- serverName
         script <- scriptName

         setHeader "Content-type" "text/plain"
         output $ body
{-         
         let self = "http://" ++ server ++ script ++ "?mode=html&input="
             htmlMode | mode==Just "html" = Just self
                      | otherwise         = Nothing
             
         case fmap convert raw of
            Nothing    -> fail "Invalid request: environment variable \"input\" is empty"
            Just input ->
               do (txt, ctp) <- lift $ process htmlMode (Just addr) flags input
                  setHeader "Content-type" ctp
                  output txt
-}
   closeDB config -- close the database connection (in case of a file do nothing (ie return () ))

   
process :: Maybe String -> Maybe String -> [Flag] -> String -> IO (String, String)
process htmlMode maybeIP flags input = do
   pair@(out, _) <- rec (withMode flags)
   when (withLogging flags && isNothing htmlMode) $ 
      case maybeIP of 
         Just addr -> logMessageWith config ("IP address: " ++ addr ++ "\n" ++ input ++ "\n" ++ out)
         Nothing   -> return ()
   return pair
 where 
   rec :: Mode -> IO (String, String)
   rec Mixed =
      let b = take 1 (dropWhile isSpace input) == "<"
      in rec (if b then XML else JSON)
   rec XML  = processXML htmlMode input
   rec JSON = processJSON input

config :: LogConfig
config = defaultLogConfig
   { logDest    = File "service.log",
     logRetries = 1
   }

-- Convert escaped characters ('%')   
convert :: String -> String
convert [] = []
convert ('%':c1:c2:cs) =
   case stringToHex [c1, c2] of
      Just i  -> chr i : convert cs
      Nothing -> '%' : convert (c1:c2:cs)
convert (c:cs) = c : convert cs