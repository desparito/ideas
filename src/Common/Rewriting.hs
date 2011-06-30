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
module Common.Rewriting 
   ( module Common.Rewriting.Term
   , module Common.Rewriting.Operator
   , module Common.Rewriting.RewriteRule
   ) where

import Common.Rewriting.Operator
import Common.Rewriting.RewriteRule
import Common.Rewriting.Term hiding (Term(..))
import Common.Rewriting.Term (Term)