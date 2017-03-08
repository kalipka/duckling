-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.Number.ID.Rules
  ( rules ) where

import Data.Maybe
import qualified Data.Text as Text
import Prelude
import Data.String

import Duckling.Dimensions.Types
import Duckling.Number.Helpers
import Duckling.Number.Types (NumberData (..))
import qualified Duckling.Number.Types as TNumber
import Duckling.Regex.Types
import Duckling.Types

ruleTeen :: Rule
ruleTeen = Rule
  { name = "teen"
  , pattern =
    [ numberBetween 2 10
    , regex "belas"
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v}):_) -> double $ v + 10
      _ -> Nothing
  }

ruleNumberCommaNumber :: Rule
ruleNumberCommaNumber = Rule
  { name = "number comma number"
  , pattern =
    [ dimension DNumber
    , regex "koma"
    , numberWith TNumber.grain isNothing
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber nd1:_:Token DNumber nd2:_) ->
        double $ TNumber.value nd1 + decimalsToDouble (TNumber.value nd2)
      _ -> Nothing
  }

ruleNumbersPrefixWithNegativeOrMinus :: Rule
ruleNumbersPrefixWithNegativeOrMinus = Rule
  { name = "numbers prefix with -, negative or minus"
  , pattern =
    [ regex "-|minus\\s?|negatif\\s?"
    , dimension DNumber
    ]
  , prod = \tokens -> case tokens of
      (_:Token DNumber nd:_) -> double (TNumber.value nd * (-1))
      _ -> Nothing
  }

ruleIntegerNumeric :: Rule
ruleIntegerNumeric = Rule
  { name = "integer (numeric)"
  , pattern =
    [ regex "(\\d{1,18})"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) -> do
        v <- toInteger <$> parseInt match
        integer v
      _ -> Nothing
  }

ruleTen :: Rule
ruleTen = Rule
  { name = "ten"
  , pattern =
    [ regex "(se)?puluh"
    ]
  , prod = \_ -> integer 10 >>= withGrain 1
  }

ruleDecimalWithThousandsSeparator :: Rule
ruleDecimalWithThousandsSeparator = Rule
  { name = "decimal with thousands separator"
  , pattern =
    [ regex "(\\d+(\\.\\d\\d\\d)+,\\d+)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):
       _) -> let dot = Text.singleton '.'
                 comma = Text.singleton ','
                 fmt = Text.replace comma dot $ Text.replace dot Text.empty match
        in parseDouble fmt >>= double
      _ -> Nothing
  }

ruleMultiply :: Rule
ruleMultiply = Rule
  { name = "compose by multiplication"
  , pattern =
    [ dimension DNumber
    , numberWith TNumber.multipliable id
    ]
  , prod = \tokens -> case tokens of
      (token1:token2:_) -> multiply token1 token2
      _ -> Nothing
  }


ruleDecimalNumber :: Rule
ruleDecimalNumber = Rule
  { name = "decimal number"
  , pattern =
    [ regex "(\\d*,\\d+)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) -> parseDecimal False match
      _ -> Nothing
  }

ruleInteger3 :: Rule
ruleInteger3 = Rule
  { name = "integer 21..99"
  , pattern =
    [ oneOf [70, 20, 60, 50, 40, 90, 30, 80]
    , numberBetween 1 10
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v1}):
       Token DNumber (NumberData {TNumber.value = v2}):
       _) -> double $ v1 + v2
      _ -> Nothing
  }

ruleIntersect :: Rule
ruleIntersect = Rule
  { name = "intersect"
  , pattern =
    [ numberWith (fromMaybe 0 . TNumber.grain) (>1)
    , numberWith TNumber.multipliable not
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = val1, TNumber.grain = Just g}):
       Token DNumber (NumberData {TNumber.value = val2}):
       _) | (10 ** fromIntegral g) > val2 -> double $ val1 + val2
      _ -> Nothing
  }

ruleSomefewcouple :: Rule
ruleSomefewcouple = Rule
  { name = "some/few/couple"
  , pattern =
    [ regex "beberapa"
    ]
  , prod = \_ -> integer 3
  }

ruleNumbersSuffixesKMG :: Rule
ruleNumbersSuffixesKMG = Rule
  { name = "numbers suffixes (K, M, G)"
  , pattern =
    [ dimension DNumber
    , regex "([kmg])(?=[\\W\\$\x20ac]|$)"
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v}):
       Token RegexMatch (GroupMatch (match:_)):
       _) -> case Text.toLower match of
         "k" -> double $ v * 1e3
         "m" -> double $ v * 1e6
         "g" -> double $ v * 1e9
         _   -> Nothing
      _ -> Nothing
  }

rulePowersOfTen :: Rule
rulePowersOfTen = Rule
  { name = "powers of tens"
  , pattern =
    [ regex "(se)?(ratus|ribu|juta)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (_:match:_)):_) -> case Text.toLower match of
        "ratus"-> double 1e2 >>= withGrain 2 >>= withMultipliable
        "ribu" -> double 1e3 >>= withGrain 3 >>= withMultipliable
        "juta" -> double 1e6 >>= withGrain 6 >>= withMultipliable
        _      -> Nothing
      _ -> Nothing
  }

ruleDozen :: Rule
ruleDozen = Rule
  { name = "dozen"
  , pattern =
    [ regex "(se)?lusin"
    ]
  , prod = \_ -> integer 12 >>= withGrain 1 >>= withMultipliable
  }

ruleInteger :: Rule
ruleInteger = Rule
  { name = "integer (0..9 11)"
  , pattern =
    [ regex "(kosong|nol|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sebelas)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) -> case Text.toLower match of
        "kosong" -> integer 0
        "nol" -> integer 0
        "satu" -> integer 1
        "dua" -> integer 2
        "tiga" -> integer 3
        "empat" -> integer 4
        "lima" -> integer 5
        "enam" -> integer 6
        "tujuh" -> integer 7
        "delapan" -> integer 8
        "sembilan" -> integer 9
        "sebelas" -> integer 11
        _ -> Nothing
      _ -> Nothing
  }

ruleInteger2 :: Rule
ruleInteger2 = Rule
  { name = "integer 20..90"
  , pattern =
    [ numberBetween 2 10
    , numberWith TNumber.value (== 10)
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v1}):
       Token DNumber (NumberData {TNumber.value = v2, TNumber.grain = Just g}):
       _) -> double (v1 * v2) >>= withGrain g
      _ -> Nothing
  }

ruleIntegerWithThousandsSeparator :: Rule
ruleIntegerWithThousandsSeparator = Rule
  { name = "integer with thousands separator ."
  , pattern =
    [ regex "(\\d{1,3}(\\.\\d\\d\\d){1,5})"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        parseDouble (Text.replace (Text.singleton '.') Text.empty match) >>= double
      _ -> Nothing
  }

rules :: [Rule]
rules =
  [ ruleDecimalNumber
  , ruleDecimalWithThousandsSeparator
  , ruleDozen
  , ruleInteger
  , ruleInteger2
  , ruleInteger3
  , ruleIntegerNumeric
  , ruleIntegerWithThousandsSeparator
  , ruleIntersect
  , ruleMultiply
  , ruleNumberCommaNumber
  , ruleNumbersPrefixWithNegativeOrMinus
  , ruleNumbersSuffixesKMG
  , rulePowersOfTen
  , ruleSomefewcouple
  , ruleTeen
  , ruleTen
  ]
