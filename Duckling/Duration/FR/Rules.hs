-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.Duration.FR.Rules
  ( rules ) where

import Prelude
import Data.String

import Duckling.Dimensions.Types
import Duckling.Duration.Helpers
import Duckling.Number.Types (NumberData(..))
import qualified Duckling.Number.Types as TNumber
import Duckling.Regex.Types
import qualified Duckling.TimeGrain.Types as TG
import Duckling.Types

ruleNumberQuotes :: Rule
ruleNumberQuotes = Rule
  { name = "<integer> + '\""
  , pattern =
    [ Predicate isNatural
    , regex "(['\"])"
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v}):
       Token RegexMatch (GroupMatch (x:_)):
       _) -> case x of
         "'"  -> Just . Token Duration . duration TG.Minute $ floor v
         "\"" -> Just . Token Duration . duration TG.Second $ floor v
         _    -> Nothing
      _ -> Nothing
  }

ruleUneUnitofduration :: Rule
ruleUneUnitofduration = Rule
  { name = "une <unit-of-duration>"
  , pattern =
    [ regex "une|la|le?"
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (_:
       Token TimeGrain grain:
       _) -> Just . Token Duration $ duration grain 1
      _ -> Nothing
  }

ruleUnQuartDHeure :: Rule
ruleUnQuartDHeure = Rule
  { name = "un quart d'heure"
  , pattern =
    [ regex "(1/4\\s?h(eure)?|(un|1) quart d'heure)"
    ]
  , prod = \_ -> Just . Token Duration $ duration TG.Minute 15
  }

ruleUneDemiHeure :: Rule
ruleUneDemiHeure = Rule
  { name = "une demi heure"
  , pattern =
    [ regex "(1/2\\s?h(eure)?|(1|une) demi(e)?(\\s|-)heure)"
    ]
  , prod = \_ -> Just . Token Duration $ duration TG.Minute 30
  }

ruleTroisQuartsDHeure :: Rule
ruleTroisQuartsDHeure = Rule
  { name = "trois quarts d'heure"
  , pattern =
    [ regex "(3/4\\s?h(eure)?|(3|trois) quart(s)? d'heure)"
    ]
  , prod = \_ -> Just . Token Duration $ duration TG.Minute 45
  }

-- TODO(jodent) precision t13807342
ruleDurationEnviron :: Rule
ruleDurationEnviron = Rule
  { name = "environ <duration>"
  , pattern =
    [ regex "environ"
    ]
    , prod = \tokens -> case tokens of
      -- TODO(jodent) +precision approximate
      (_:token:_) -> Just token
      _ -> Nothing
  }

rules :: [Rule]
rules =
  [ ruleUneUnitofduration
  , ruleUnQuartDHeure
  , ruleUneDemiHeure
  , ruleTroisQuartsDHeure
  , ruleDurationEnviron
  , ruleNumberQuotes
  ]
