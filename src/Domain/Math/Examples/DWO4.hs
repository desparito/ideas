-----------------------------------------------------------------------------
-- Copyright 2010, Open Universiteit Nederland. This file is distributed 
-- under the terms of the GNU General Public License. For more information, 
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  alex.gerdes@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- Example exercises from the Digital Mathematics Environment (DWO),
-- see: http://www.fi.uu.nl/dwo/gr/frameset.html.
--
-----------------------------------------------------------------------------
module Domain.Math.Examples.DWO4 
   ( brokenEquations, normBroken, normBroken2, normBrokenCon, deelUit
   , powerEquations
   ) where

import Prelude hiding ((^))
import Domain.Math.Data.Relation
import Domain.Math.Expr

----------------------------------------------------------
-- HAVO B applets

-- Hoofdstuk 7, vergelijkingen met machten algebraisch (6)
powerEquations :: [[Equation Expr]]
powerEquations = 
  -- los vergelijkingen algebraisch op
  let x = Var "x" in
  [ [ x^14 :==: 25
    , x^(-7) :==: 110
    , 2*x^(Number 3.5) :==: 70
    , 8*x^(Number (-9.2)) :==: 1000
    ]
  , [ root x 5 :==: Number 2.9
    , 5 * root x 3 :==: 7
    , root (x^3) 4 :==: 720
    , root (x^2) 5 :==: Number 5.5
    ]
  , [ 4*x^(-12) :==: 28 
    , 7*x^(Number 5.1) + 16 :==: 100
    , 8*x^(Number (-1.9)) - 5 :==: 2
    , Number 0.8 * x^(Number 0.7) + 7 :==: Number 12.5
    ]
  , [ 4*root x 7 + 7 :==: Number 11.8
    , 9*x^(Number 3.2)+17 :==: 37
    , 6*x^(Number (-3.1))-9 :==: 12
    , Number 0.7 * x^(Number (-1.1)) + 17 :==: 40
    ]
  ]

-- Hoofdstuk 7, exponentiele vergelijkingen algebraisch (7)
expEquations :: [[Equation Expr]]
expEquations =
  -- los exponentiele vergelijkingen algebraisch op
  let x = Var "x" in
  [ [ 2^x :==: 16 * sqrt 2
    , 2^(x+2) :==: 1/4
    , 3^(x-1) :==: 81
    , 3^(x+5) :==: 243/(sqrt 3)
    ]
  , [ 5^(2-x) :==: Number 0.04
    , 3^(2*x) :==: 1/9
    , 3^(1-3*x) :==: 81
    , 3^(3*x-2) :==: 3*sqrt 3
    ]
  , [ 5*2^(x-1) :==: 20*sqrt 2
    , 6*5^(2-x) :==: 150
    , 2*7^(4*x-1) :==: 98
    , 8*3^(5-2*x) :==: 72*sqrt 3
    ]
  , [ 2^x-7 :==: 9
    , 4^(3*x)+5 :==: 69
    , 7*3^(2*x+1) :==: 189
    , 5*2^(1-4*x)+11 :==: 51
    ]
  , [ 5^(x-4) :==: (1/5)^(2*x+1)
    , 7^(1-2*x) :==: 1
    , 4^(2*x-3) :==: 2*sqrt 2
    , 2*9^(1-2*x) :==: 6*sqrt 3
    ]
  ]

-- Hoofdstuk 7, logaritmische vergelijkingen algebraisch (8)
logEquations :: [[Equation Expr]]
logEquations =
  -- los algebraisch op
  let x = Var "x" in
  [ [ logBase x 2 :==: 7
    , logBase (x-2) 3 :==: 2
    , logBase (x-3) 4 :==: 1+(1/2)
    , logBase ((1/10)*x-3) 5 :==: -1
    , logBase 7 x :==: 1
    , logBase 4 x :==: -1
    , logBase (x^2-1) 2 :==: 3
    , logBase (1-5*x) (1/3) :==: -1
    ]
  ]


----------------------------------------------------------
-- VWO A/C applets

-- Hoofdstuk 5, hogeremachtswortels (1)
higherPowerEquations :: [[Equation Expr]]
higherPowerEquations =
  -- bereken exacte oplossing
  let x = Var "x" in
  [ [ 2*x^3+9 :==: 19
    , 4*x^5-17 :==: 27
    , 3*x^7+8 :==: 62
    , 5*x^3-1 :==: 9
    , 6-5*x^3 :==: 76
    , 11-7*x^5 :==: 53
    , 4-(1/5)*x^7 :==: 9
    , 18-11*x^7 :==: 62
    ]
  , [ (1/2)*x^4+5 :==: 12
    , 5*x^6-37 :==: 68
    , 4*x^8-19 :==: 9
    , 5*x^6+7 :==: 97
    , 18-7*x^4 :==: -38
    , 3+(1/3)*x^6 :==: 7
    , 1-(1/9)*x^8 :==: -4
    , 47+15*x^8 :==: 77
    ]
  , [ 18*x^8-11 :==: 7
    , (1/4)*x^6+14 :==: 30
    , 5*x^4+67 :==: 472
    , 5*x^4-1 :==: 4
    , (1/8)*x^7+24 :==: 40
    , (1/5)*x^3+27 :==: 52
    , 32*x^3+18 :==: 22
    , 4*x^3-8 :==: 100
    ]
  , [ 14-2*x^3 :==: 700
    , 4-3*x^5 :==: 100
    , 14-11*x^7 :==: 25
    , 1-3*x^5 :==: 97
    ]
    -- Geef in twee decimalen nauwkeurig
  , [ 3*x^5+7 :==: 15
    , Number 0.7 * x^4 - Number 1.3 :==: 2
    , (1/3)*x^7 :==: 720
    ]
  ]

-- Hoofdstuk 5, hogeremachtswortels (2)
rootEquations :: [[Equation Expr]]
rootEquations = 
  -- Bereken exacte oplossing
  let x = Var "x" in
  let y = Var "y" in
  [ [ x^4 :==: 6
    , root x 4 :==: 6
    , sqrt x :==: 10
    , root x 5 :==: 2
    ]
  , [ 3*x^5-1 :==: 20
    , 3*root (x-1) 5 - 1 :==: 20
    , (1/10)*sqrt x + 2 :==: 12
    , (1/5)*x^7+8 :==: 26
    ]
  , [ 3*root x 4+2 :==: 14
    , (1/2)*x^8-2 :==: 18
    , 5-2*root x 3 :==: 3
    ]
  -- Maak x vrij
  , [ y :==: x^5
    , y :==: 2*x^5+4
    , y :==: (1/10)*x^3-6
    , y :==: root x 7
    , y :==: 2*root x 3+8
    , y :==: (1/10)*root x 5-6
    ]
  , [ y :==: 3*root x 7-6
    , y :==: (1/4)*x^9-6
    , y :==: 8+(1/2)*root x 3
    ]
  ]



----------------------------------------------------------
-- VWO B applets

-- Hoofdstuk 1, wortelvergelijkingen
rootEquations2 :: [[Equation Expr]]
rootEquations2 =
  let x = Var "x" in
  -- los algebraisch op
  [ [ 5-2*sqrt x :==: 1
    , 7-3*sqrt x :==: 5
    , 4-2*sqrt x :==: -3
    , 6-3*sqrt x :==: 2
    ]
  , [ 2*sqrt x :==: x
    , 2*sqrt x :==: 3*x
    , x-3*sqrt x :==: 0
    , 3*x-5*sqrt x :==: 0
    ]
  , [ x :==: sqrt (2*x+3)
    , x :==: sqrt (3*x+10)
    , x :==: sqrt (4*x+21)
    , x :==: sqrt (3*x+4)
    ]
  , [ 5*x :==: sqrt (50*x+75)
    , 2*x :==: sqrt (24*x+28)
    , 3*x :==: sqrt (27*x-18)
    , 2*x :==: sqrt (28*x-40)
    , 3*x :==: sqrt (3*x+42)
    , 5*x :==: sqrt (49*x+2)
    , 3*x :==: sqrt (10*x-1)
    , 5*x :==: sqrt (30*x-5)
    ]
  , [ x-sqrt x :==: 6
    , x-4*sqrt x :==: 12
    , x-sqrt x :==: 12
    , x-sqrt x :==: 2
    , 2*x+sqrt x :==: 3
    , 3*x+4*sqrt x :==: 20
    , 2*x+sqrt x :==: 15
    , 2*x-3*sqrt x :==: 27
    ]
  ]

-- Hoofdstuk 1, wortelvergelijkingen
rootSubstEquations :: [[Equation Expr]]
rootSubstEquations =
  let x = Var "x" in
  -- los algebraisch op
  [ [ 8*x^3+1 :==: 9*x*sqrt x
    , 27*x^3 :==: 28*x*sqrt x-1
    , x^3+3 :==: 4*x*sqrt x
    , x^3 :==: 10*x*sqrt x-16
    ]
  , [ x^3 :==: 6*x*sqrt x+16
    , x^3-24*x*sqrt x :==: 81
    , x^3+x*sqrt x :==: 20
    , x^3-15 :==: 2*x*sqrt x
    ]
  , [ x^5+32 :==: 33*x^2*sqrt x
    , 243*x^5-244*x^2*sqrt x+1 :==: 0
    , 32*x^5+31*x^2*sqrt x :==: 1
    , x^5 :==: 242*x^2*sqrt x+243
    ]
  , [ x^5+8 :==: 6*x^2*sqrt x
    , x^5 :==: 9*x^2*sqrt x-18
    , x^5 :==: 5*x^2*sqrt x+24
    , x^5+4*x^2*sqrt x :==:12
    ]
  ]

-- Hoofdstuk 1, gebroken vergelijkingen
brokenEquations :: [[Equation Expr]]
brokenEquations =
   -- Bereken exact de oplossingen
   let x = Var "x" in
   [ [ (2*x^2-10) / (x^2+3) :==: 0
     , (7*x^2-21) / (2*x^2-5) :==: 0
     , (3*x^2-6) / (4*x^2+1) :==: 0
     , (4*x^2-24) / (6*x^2-2) :==: 0
     , x^2 / (x+4) :==: (3*x+4) / (x+4)
     , (x^2+2) / (x-2) :==: (x+8) / (x-2)
     , (x^2+6*x-6)/(x^2-1) :==: (4*x+9)/(x^2-1)
     , (x^2+6)/(x^2-2) :==: (7*x)/(x^2-2)
     ]
   , [ (x^2+6*x)/(x^2-1) :==: (3*x+4)/(x^2-1)
     , (x^2+6)/(x-3) :==: (5*x)/(x-3) 
     , (x^2+4*x)/(x^2-4) :==: (3*x + 6)/(x^2-4)
     , (x^2+2*x-4)/(x-5) :==: (4*x+11)/(x-5)
     , (5*x+2)/(2*x-1) :==: (5*x+2)/(3*x+5)
     , (x^2-9)/(4*x-1) :==: (x^2-9)/(2*x+7)
     , (3*x-2)/(2*x^2) :==: (3*x-2)/(x^2+4)
     , (2*x+1)/(x^2+3*x) :==: (2*x+1)/(5*x+8)
     ]
   , [ (x^2-1)/(2*x+2) :==: (x^2-1)/(x+8)
     , (x^2-4)/(3*x-6) :==: (x^2-4)/(2*x+1)
     , (x^2+5*x)/(2*x^2) :==: (x^2+5*x)/(x^2+4)
     , (x^2-3*x)/(2*x-6) :==: (x^2-3*x)/(4*x+2)
     , x/(x+1) :==: 1 + 3/4
     , (x+2)/(3*x) :==: 1 + 1/3
     , (2*x+3)/(x-1) :==: 3 + 1/2
     , (x-3)/(1-x) :==: 1 + 2/5
     ]
   , [ (x+4)/(x+3) :==: (x+1)/(x+2)
     , (2*x+3)/(x-1) :==: (2*x-1) / (x-2)
     , (3*x+6)/(3*x-1) :==: (x+4)/(x+1)
     , (x+2)/(2*x+5) :==: (x+4)/(2*x-3)
     , (x+5)/(2*x) + 2 :==: 5
     , (3*x+4)/(x+2) - 3 :==: 2
     , (x^2)/(5*x+6) + 4 :==: 5
     , (x^2)/(2*x-3) + 3 :==: 7
     ]
   , [ (x-2)/(x-3) :==: x/2
     , (x+9)/(x-5) :==: 2/x
     , (x+2)/(x+4) :==: 2/(x+1)
     , (-3)/(x-5) :==: (x+3)/(x+1)
     , (x+1)/(x+2) :==: (7*x+1)/(2*x-4)
     , (2*x-7)/(5-x) :==: (x+1)/(3*x-7)
     , (x+1)/(x-1) :==: (3*x-7)/(x-2)
     , (3*x-7)/(x-2) :==: (7-x)/(3*x-3)
     ]
   ]
   
-- Hoofdstuk 4, gebroken vorm herleiden (1 en 1a)
normBroken :: [[Expr]]
normBroken =
   -- Herleid
   let x = Var "x" in
   let y = Var "y" in
   let a = Var "a" in
   let b = Var "b" in
   [ [ 7/(2*x) + 3/(5*x), 3/(2*x) + 2/(3*x), 4/(5*x)-2/(3*x)
     , 2/(7*x) - 1/(4*x), 5/(6*a)+3/(7*a), 3/(8*a)+5/(3*a)
     , 7/(2*a)-2/(3*a),  9/(5*a)-1/(2*a)
     ]
   , [ 1/x+1/y, 2/(3*x)+1/(2*y), 3/(x^2*y) - 5/(2*x*y), 2/(x*y)-7/(5*y)
     , 2/a - 3/b, 4/(3*a)-2/(5*b), 2/(a*b)+4/(3*a), 7/(4*a)+3/(4*b)
     ]
   , [ 3+1/(2*x), 2*x+(3/(5*x)), 5/(2*x)-3, 3-5/(7*x), 5/(3*a)+1
     , 4*a+3/(2*a), 2*a-1/(3*a), 7/(5*a)-2
     ]
   , [ 5/(x+2)+4/(x+3), 3/(x-1)+2/(x+3), 4/(x+5)+2/(x-3), 3/(x-2)+2/(x-3)
     , 4/(x+3)-6/(x+2), 1/(x+5)-3/(x-4), 7/(x-3)-2/(x+1), 6/(x-1)-3/(x-2)
     ]
   , [ (x+1)/(x+2)+(x+2)/(x-3), (x-2)/(x+3)+(x-1)/(x+2), (x+3)/(x-1)+(x+2)/(x-4)
     , (x-4)/(x+5)+(x-2)/(x-3), (x-1)/(x+1)-(x+2)/(x-2), (x+5)/(x+3)-(x+3)/(x+5)
     , (x-1)/(x+2)-(x+4)/(x+1), (x-3)/(x-1)-(x+2)/(x+4)
     ]
   , [ (2*x)/(x-1)+x/(x+2), (3*x)/(x-4)+(5*x)/(x-2)
     , (4*x)/(x+2)-(2*x)/(x+1), x/(x+5)-(4*x)/(x+6)
     ]
   ]

-- Hoofdstuk 4, gebroken vorm herleiden (2 en 2a)
normBroken2 :: [[Expr]]
normBroken2 =
   -- Herleid
   let x = Var "x" in
   let a = Var "a" in
   let p = Var "p" in
   [ [ (x^2+4*x-5)/(x^2+5*x-6), (x^2+2*x-8)/(x^2+10*x+24)
     , (x^2-7*x+12)/(x^2+x-20), (x^2+7*x+12)/(x^2+5*x+6)
     , (a^2-a-2)/(a^2+4*a-12), (a^2-3*a-10)/(a^2-a-20)
     , (a^2-2*a-15)/(a^2-3*a-18), (a^2+a-2)/(a^2+3*a+2)
     ]
   , [ (x^2-16)/(x^2+x-12), (x^2-2*x+1)/(x^2-1), (x^2-9)/(x^2+6*x+9)
     , (x^2-7*x+6)/(x^2-1), (2*p^2+8*p)/(p^2-16), (-(p^2)+5*p)/(p^2-10*p+25)
     , (p^2-4)/(4*p^2+8*p), (p^2-12*p+36)/(p^2-6*p)
     ]
   , [ (x^3+3*x^2+2*x)/(x^2+4*x+4), (x^3+10*x^2+24*x)/(x^2+7*x+6)
     , (x^2+5*x+6)/(x^3-x^2-6*x), (x^2+3*x-4)/(x^3-6*x^2+5*x)
     , (a^3+7*a^2+12*a)/(a^2+6*a+9), (a^3+7*a^2+10*a)/(a^2-a-6)
     , (a^2-9)/(a^3-4*a^2+3*a), (a^2-2*a-15)/(a^3-3*a^2-10*a)
     ]
   ]
   
deelUit :: [[Expr]]
deelUit =
   let x = Var "x" in
   let a = Var "a" in
   let p = Var "p" in
   let t = Var "t" in
   [ -- laatste sommen van gebroken vorm herleiden (2), niveau 5
     [ (-6*a^2-1)/a, -2*p^2+3/(7*p), (7*t^2+4)/(-4*t), (9*x^2+8)/(8*x)
     ]
   , -- sommen (2a)
     [ (-7*a^2-4*a-6)/(-6*a), (3*p^2+6*p-8)/p, (2*t^2-9*t-8)/(-2*t)
     , (x^2+5*x+5)/(2*x), (5*a^3-4*a+2)/(9*a), (5*p^3-7*p^2+9)/(2*p)
     , (-3*t^3+6*t-4)/(3*t), (4*x^3-3*x^2+4)/(7*x)
     ]
   ]
   
-- Vervolg hoofdstuk 4, gebroken vorm herleiden (2 en 2a), vanaf niveau 4
normBrokenCon :: [[Equation Expr]]
normBrokenCon =
   -- Herleid
   let a = Var "a" in
   let p = Var "p" in
   let t = Var "t" in
   let ca = symbol (toSymbol "A") in
   let ct = symbol (toSymbol "T") in
   let cn = symbol (toSymbol "N") in
   [ [ ca :==: (p^2+2*p)/(p^2-4), ca :==: (6*p^2-18*p)/(p^2-9)
     , ca :==: (p^2-1)/(-2*p^2+2*p), ca :==: (p^2-16)/(4*p^2+16*p)
     , ct :==: (t^3-2*t^2)/(t^2-4), ct :==: (t^3+4*t^2)/(t^2-16)
     , ct :==: (t^2-1)/(t^3+t^2), ct :==: (t^2-25)/(t^3-5*t^2)
     ]
   , [ cn :==: (a^4+4*a^2-5)/(a^4-1), cn :==: (a^4+5*a^2+6)/(a^4+4*a^2+3)
     , cn :==: (a^4-5*a^2+6)/(a^4-7*a^2+10), cn :==: (a^4-8*a^2+16)/(a^4-5*a^2+4)
     ]
   ]

-- Hoofdstuk 5, exponentiele vergelijkingen exact oplossen (1, 2, 2a)
expEquations2 :: [[Equation Expr]]
expEquations2 =
  let x = Var "x" in
  -- los algebraisch op
  -- 1
  [ [ 2^(2*x-1) :==: 1/16
    , 3^(1-x) :==: 81
    , 5^(1-2*x) :==: 1/5
    , (1/2)^(4*x-3) :==: 1/4
    , (1/3)^(5*x+2) :==: 1/3
    , 6^(3*x-2) :==: 1/216
    ]
  , [ 2^(3*x+2) :==: 2*sqrt 2
    , 3^(2*x+1) :==: 9*sqrt 3
    , 5^(4*x+3) :==: 625*sqrt 5
    , (1/2)^(x+1) :==: 4
    , (1/3)^(x-3) :==: 3
    , 4^(x+2) :==: 64*root 4 3
    ]
  , [ 2^(x+3) :==: (1/2)*root 2 3
    , 3^(4*x+1) :==: 27
    , 5^(-x+2) :==: 1/25
    , (1/2)^(1-x) :==: sqrt 2
    , (1/3)^(x+1) :==: (1/9)*sqrt 3
    , 2^(1-3*x) :==: (1/8)*sqrt 2
    ]
  , [ 3*2^x+1 :==: 25
    , 4*3^x-9 :==: 27
    , 2*5^x+4 :==: 14
    , 5*(1/2)^x+11 :==: 51
    , 8*(1/3)^x+27 :==: 99
    , 3*(1/5)^x-35 :==: 40
    ]
  , [ 2^(4*x+3) :==: 1
    , (1/2)^(2*x-1) :==: 1
    , 3^(2*x+4) :==: 1
    , (1/3)^(x-3) :==: 1
    , 4^(4*x-7) :==: 1
    , 5^(3*x-6) :==: 1
    ]
  -- 2
  , [ 2^(2*x+1) :==: (1/2)^(x+2)
    , 4^(2*x-1) :==: 2^(3*x+2)
    , 2^(5*x-4) :==: 8^(x-3)
    , (1/4)^(2*x+1) :==: 2^(6-2*x)
    , (1/3)^(2*x-3) :==: 3^(4*x-3)
    , 3^(3*x-2) :==: 9^(2-x)
    , 27^(2*x+1) :==: 3^(2*x-5)
    , 3^(5*x-1) :==: (1/9)^(2*x-1)
    ]
  , [ 6^(7*x-3) :==: 36^(2*x+3)
    , (1/7)^(2*x-1) :==: 7^(2*x-7)
    , 5^(5-2*x) :==: (1/5)^(x+2)
    , 25^(4*x+1) :==: 5^(5*x-4)
    , 3^(x^2) :==: (1/3)^(2*x)
    , (1/2)^(x^2) :==: 2^(2*x)
    , 5^(x^2) :==: 25^(3*x)
    , 2^(x^2) :==: (1/8)^(-x)
    ]
  , [ (1/2)^(2-2*x) :==: 4^(3*x+5)
    , 8^(x+1) :==: (1/2)^(x+7)
    , (1/4)^(x+2) :==: 8^(2*x-1)
    , 8^(2*x-3) :==: 16^(2*x+3)
    , (1/3)^(x-2) :==: 9^(x+4)
    , 9^(2*x-1) :==: 27^(2*x-1)
    , (1/9)^(x+3) :==: 27^(2*x+2)
    , 27^(3-2*x) :==: (1/3)^(4*x+3)
    ]
  , [ 4*2^x :==: 2^(3*x-2)
    , 2^(5*x-9) :==: (1/8)*2^x
    , 3^(4*x+6) :==: 27*3^x
    , (1/9)*3^x :==: 3^(2-3*x)
    , 3*3^x :==: (1/3)^(2*x+5)
    , 4^(x+1) :==: 8*2^x
    , (1/2)*2^x :==: (1/2)^x
    , 9^(x+2) :==: (1/3)*3^x
    ]
  , [ (1/5)*5^(3*x-2) :==: 25^(x+1)
    , 9*3^(2*x+1) :==: (1/3)^(4*x-3)
    , 4^(3*x-5) :==: 8*2^(x+2)
    , (1/2)^(3-2*x) :==: (1/4)*2^(3*x-4)
    , 2^(x+2)+2^x :==: 40
    , 2^(x+4) :==: 3/4+2^(x+2)
    , 2^(x-2)+2^(x+1) :==: 9
    , 2^(x+5)-2^(x+4) :==: 16
    ]
  -- 2a
  , [ 3^(x+2) :==: 72+3^x
    , 3^(x-1)+3^(x+1) :==: 10
    , 3^(x+3)+3^(x+2) :==: 12
    , 3^x-3^(x-1) :==: 54
    ]
  , [ 5^(x+1)+5^x :==: 150
    , 5^(x+1) :==: 100+5^x
    , 5^(x+2)+5^x :==:1+1/25
    , 5^(x+1)+5^(x+2) :==: 30
    ]
  , [ 2^(x+4)-2^(x-2) :==: 63*sqrt 2
    , 3^(x-1)+3^x :==: 12*sqrt 3
    , 5^x-5^(x-1) :==: 4*sqrt 5
    , 2^(x+2)+2^(x-3) :==: 66*sqrt 2
    ]
  ]