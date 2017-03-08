-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.


{-# LANGUAGE OverloadedStrings #-}

module Duckling.Finance.ES.Corpus
  ( corpus ) where

import Prelude
import Data.String

import Duckling.Finance.Types
import Duckling.Lang
import Duckling.Resolve
import Duckling.Testing.Types

corpus :: Corpus
corpus = (testContext {lang = ES}, allExamples)

allExamples :: [Example]
allExamples = concat
  [ examples (FinanceValue Dollar 10)
             [ "$10"
             , "10$"
             , "diez dollars"
             , "diez dólares"
             ]
  , examples (FinanceValue Dollar 10000)
             [ "$10.000"
             , "10K$"
             , "$10k"
             ]
  , examples (FinanceValue USD 1.23)
             [ "USD1,23"
             ]
  , examples (FinanceValue EUR 20)
             [ "20€"
             , "20 euros"
             , "20 Euro"
             , "20 Euros"
             , "EUR 20"
             ]
  , examples (FinanceValue EUR 29.99)
             [ "EUR29,99"
             ]
  , examples (FinanceValue Pound 9)
             [ "£9"
             , "nueve pounds"
             , "9 libras"
             ]
  , examples (FinanceValue GBP 3.01)
             [ "GBP3,01"
             , "GBP 3,01"
             , "3 gbp 1 centavo"
             , "3 gbp y 1 centavo"
             ]
  , examples (FinanceValue PTS 15)
             [ "15 Pt"
             , "15pta"
             , "15Ptas"
             ]
  ]
