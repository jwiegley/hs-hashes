{-# LANGUAGE CPP #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- |
-- Module: Test.Data.Hash.FNV1
-- Copyright: Copyright © 2021 Lars Kuhtz <lakuhtz@gmail.com>
-- License: MIT
-- Maintainer: Lars Kuhtz <lakuhtz@gmail.com>
-- Stability: experimental
--
module Test.Data.Hash.FNV1
( tests
, run
) where

import Data.Bifunctor
import qualified Data.ByteString as B
import qualified Data.ByteString.Unsafe as B
import Data.Word

import GHC.Ptr

import System.IO.Unsafe

import Test.Syd

-- internal modules

import Data.Hash.FNV1

-- -------------------------------------------------------------------------- --
-- All tests

run :: Bool
run = run64
    && run32
    && run64a
    && run32a
    && runPrim
    && runPrima

tests :: Spec
tests = do
    describe "FNV1 64 bit" tests64
    describe "FNV1 32 bit" tests32
    describe "FNV1a 64 bit" tests64a
    describe "FNV1a 32 bit" tests32a
    describe "FNV1 host word size" testsPrim
    describe "FNV1a host word size" testsPrima

-- -------------------------------------------------------------------------- --
-- 64 bit FNV1

run64 :: Bool
run64 = all test64 testVectors64
    && all testZero64 zeros64

tests64 :: Spec
tests64 = do
    describe "Test Vectors" $ do
        mapM_ (\x -> it (show x) (test64 x)) testVectors64
    describe "Inputs up to 9 bytes that hash to 0" $ do
        mapM_ (\x -> it (show x) (testZero64 x)) zeros64

test64 :: (B.ByteString, Word64) -> Bool
test64 (b, r) = hashByteString @Fnv164Hash b == Fnv164Hash r

testZero64 :: B.ByteString -> Bool
testZero64 b = hashByteString @Fnv164Hash b == Fnv164Hash 0

testVectors64 :: [(B.ByteString, Word64)]
testVectors64 = []

-- | All FNV1 64 bit inputs that result in a hash of 0 up to a length of nine
-- bytes.
--
-- (cf. http://www.isthe.com/chongo/tech/comp/fnv/)
--
zeros64 :: [B.ByteString]
zeros64 = B.pack <$>
    [ [0x92, 0x06, 0x77, 0x4c, 0xe0, 0x2f, 0x89, 0x2a, 0xd2]
    , [0xfb, 0x6c, 0x4f, 0xdb, 0x00, 0x41, 0xdb, 0xc0, 0xfe]
    , [0x9f, 0x72, 0x72, 0x35, 0x80, 0x4b, 0x8d, 0x6b, 0x06]
    , [0x3d, 0x82, 0x76, 0x00, 0x80, 0x7c, 0x52, 0x62, 0x1a]
    , [0x58, 0x21, 0xf5, 0xa2, 0xe1, 0x01, 0x9d, 0x80, 0xe0]
    , [0x52, 0xa1, 0xeb, 0x10, 0xa0, 0xe9, 0x45, 0x96, 0x05]
    , [0xbe, 0x64, 0x8a, 0x14, 0xe1, 0x46, 0x17, 0x18, 0xff]
    , [0x9e, 0x50, 0x1d, 0xf2, 0x41, 0x75, 0x55, 0xac, 0x05]
    , [0xb3, 0x92, 0xa9, 0x6f, 0x80, 0xe4, 0x29, 0xa4, 0x63]
    , [0x82, 0xba, 0xb3, 0x41, 0x81, 0x0f, 0xdb, 0x83, 0x15]
    , [0x92, 0xf4, 0x6e, 0x0e, 0xe1, 0xb9, 0xe5, 0x45, 0x2d]
    , [0x3c, 0xea, 0x57, 0x50, 0x81, 0x67, 0x67, 0x9b, 0xe0]
    , [0x36, 0xe3, 0x96, 0x34, 0xe2, 0x1d, 0x36, 0x00, 0x61]
    , [0xaf, 0xfa, 0xff, 0xee, 0x61, 0xb0, 0x5e, 0xc4, 0x04]
    , [0xd5, 0xc9, 0x88, 0x15, 0x02, 0x2f, 0xd3, 0x38, 0xc2]
    , [0xbc, 0xa7, 0x38, 0x51, 0xe2, 0x2f, 0xb1, 0x1b, 0x22]
    , [0x70, 0xf2, 0x10, 0xba, 0x02, 0x45, 0x37, 0xb3, 0xe8]
    , [0x5b, 0xa3, 0xa0, 0x4e, 0x81, 0xfc, 0x4f, 0x32, 0x5b]
    , [0xcd, 0x50, 0x99, 0x68, 0x22, 0xd4, 0x78, 0x2f, 0xb0]
    , [0xfa, 0xff, 0x0d, 0xfa, 0xe2, 0xf0, 0x43, 0xb4, 0x9a]
    , [0x16, 0x3f, 0xba, 0x47, 0x43, 0x94, 0x44, 0xfe, 0x86]
    , [0x46, 0xe0, 0x03, 0x71, 0xc2, 0x57, 0xf0, 0xbc, 0xda]
    , [0x60, 0x74, 0x4a, 0x52, 0xe3, 0x06, 0x42, 0x36, 0xf2]
    , [0x97, 0x20, 0x3a, 0xf8, 0xa2, 0xf6, 0x8a, 0x62, 0xa6]
    , [0x98, 0xf5, 0xcc, 0xd5, 0x03, 0x32, 0x22, 0x1a, 0xe2]
    , [0x5d, 0xd5, 0x14, 0xe8, 0xe3, 0x43, 0x8b, 0x5a, 0x9e]
    , [0x95, 0xb8, 0x11, 0x62, 0x03, 0x5a, 0xed, 0xd2, 0xcb]
    , [0xf9, 0xcb, 0x23, 0x1d, 0x03, 0x71, 0xc5, 0xca, 0x5c]
    , [0xc3, 0x04, 0x1c, 0x59, 0x82, 0xa5, 0xaa, 0x9b, 0x55]
    , [0x68, 0x10, 0x80, 0x61, 0xa3, 0x5e, 0x72, 0x31, 0x48]
    , [0x43, 0x0a, 0xeb, 0x89, 0xc2, 0xc1, 0x9d, 0xd8, 0x2a]
    , [0x5a, 0xa3, 0xe3, 0x40, 0x23, 0xce, 0x90, 0xbc, 0xa2]
    , [0x27, 0xe1, 0x3f, 0xaa, 0xa3, 0x8f, 0xaf, 0x6a, 0x51]
    , [0x0c, 0x5b, 0xac, 0x36, 0x24, 0x22, 0xa2, 0x7c, 0x24]
    , [0xea, 0xbc, 0xd7, 0x7c, 0x24, 0x49, 0x58, 0x66, 0x57]
    , [0x5a, 0x30, 0x62, 0x51, 0x83, 0x9c, 0x97, 0xc3, 0x75]
    , [0x7a, 0x18, 0x75, 0xd3, 0xc3, 0x88, 0x65, 0x0b, 0x3a]
    , [0x02, 0x38, 0x25, 0x95, 0x25, 0x0b, 0x3b, 0x0c, 0xa8]
    , [0x33, 0x1c, 0xae, 0xdd, 0x83, 0xfc, 0x55, 0xf4, 0x63]
    , [0xcb, 0x87, 0x3d, 0xb9, 0xe5, 0x38, 0x0b, 0xbd, 0xca]
    , [0x3a, 0x25, 0xba, 0x67, 0xa4, 0xc7, 0x49, 0x80, 0xe9]
    , [0x49, 0x14, 0x3b, 0x94, 0x05, 0x63, 0xb5, 0xde, 0xd6]
    , [0x45, 0xfb, 0x0d, 0x28, 0x45, 0x19, 0x66, 0x63, 0x27]
    , [0x92, 0x7a, 0xe5, 0xa6, 0xe5, 0x88, 0xba, 0x55, 0x68]
    , [0xc3, 0x93, 0x7c, 0x11, 0xc4, 0x1a, 0x2f, 0xe0, 0x8b]
    , [0xa1, 0xd8, 0x5e, 0x71, 0xa5, 0x6a, 0x96, 0x5e, 0x64]
    , [0x77, 0x7b, 0xd7, 0x7d, 0x05, 0xdc, 0x73, 0x64, 0xc3]
    , [0x3d, 0x3f, 0xd4, 0xd6, 0xa6, 0x71, 0xb2, 0x9d, 0x65]
    , [0x8d, 0x45, 0x9e, 0xd0, 0x27, 0x66, 0xb4, 0x46, 0x34]
    , [0xf1, 0xda, 0x16, 0xa1, 0x85, 0xfe, 0x43, 0xa7, 0x30]
    , [0x97, 0x6b, 0x02, 0xe3, 0x66, 0x10, 0x3d, 0x6e, 0xab]
    , [0x84, 0x2b, 0xd9, 0x13, 0xa7, 0x25, 0x5a, 0x8a, 0x22]
    , [0x0c, 0x2b, 0x2f, 0xd2, 0x28, 0x3a, 0x91, 0xdf, 0x95]
    , [0x1c, 0x01, 0xed, 0xaa, 0x47, 0x2f, 0x64, 0x6a, 0x8b]
    , [0x71, 0x66, 0x6f, 0x98, 0x47, 0x74, 0x48, 0xeb, 0x39]
    , [0x2b, 0xb3, 0x61, 0xde, 0xe8, 0x6c, 0x33, 0xfd, 0x32]
    , [0xc5, 0x33, 0x7e, 0xc3, 0x87, 0x9c, 0x0c, 0x24, 0x4b]
    , [0xb7, 0x44, 0xea, 0x2c, 0xa8, 0x59, 0xbc, 0xfc, 0xc5]
    , [0xb2, 0x8c, 0x40, 0x98, 0x67, 0x46, 0x6f, 0xce, 0x35]
    , [0x04, 0x34, 0x61, 0xb3, 0x87, 0xd4, 0xe5, 0x1a, 0x7f]
    , [0x20, 0xba, 0x15, 0x17, 0xe8, 0xdd, 0xd9, 0xf6, 0x19]
    , [0x36, 0xc4, 0xd3, 0xef, 0x88, 0x53, 0x6e, 0x86, 0x56]
    , [0x32, 0x55, 0xce, 0xf0, 0x48, 0x73, 0xaf, 0x8d, 0x9d]
    , [0x18, 0x3c, 0xd8, 0x70, 0x08, 0x71, 0x6a, 0x47, 0xa3]
    , [0xa8, 0xad, 0xfb, 0x29, 0xa8, 0xe4, 0x8e, 0x82, 0xc4]
    , [0x47, 0x47, 0xbf, 0x58, 0x08, 0x7f, 0xab, 0xbc, 0x34]
    , [0x8f, 0x68, 0x71, 0x3a, 0xe9, 0x56, 0x8f, 0xd0, 0x0f]
    , [0x64, 0x5e, 0xdc, 0x14, 0x88, 0x93, 0x8d, 0xb4, 0x35]
    , [0xb4, 0x33, 0xd0, 0x6d, 0x48, 0xbb, 0x3a, 0x5d, 0x3d]
    , [0x22, 0xe4, 0x4d, 0x0a, 0x48, 0xbd, 0x95, 0x1e, 0x8e]
    , [0x78, 0x6e, 0x06, 0x7d, 0x48, 0xce, 0xdb, 0x12, 0x33]
    , [0x7e, 0x1f, 0x4d, 0x02, 0x48, 0xf8, 0xd2, 0xa5, 0xc2]
    , [0x90, 0x6b, 0x26, 0x4e, 0xc7, 0xef, 0x12, 0xf2, 0x20]
    , [0x90, 0x10, 0xa8, 0x21, 0x09, 0x16, 0x22, 0x57, 0xbc]
    , [0x5b, 0x1a, 0x8c, 0xbc, 0x09, 0x2c, 0xa4, 0x2d, 0x9c]
    , [0x2c, 0x1a, 0x6e, 0x44, 0xa9, 0x7d, 0x98, 0xe0, 0x39]
    , [0x8a, 0x2b, 0x35, 0xab, 0x49, 0x97, 0xd5, 0xf7, 0xbc]
    , [0x29, 0xbc, 0x62, 0x5e, 0x0a, 0x4e, 0x9e, 0x34, 0x40]
    , [0xe7, 0xe6, 0xc7, 0x00, 0xaa, 0xd3, 0x26, 0x5a, 0x4a]
    , [0x7e, 0x65, 0xe5, 0x51, 0x2b, 0x66, 0xe8, 0xb5, 0xb2]
    , [0x2b, 0xd7, 0xcf, 0x6a, 0x6a, 0x6f, 0xb4, 0x56, 0xc9]
    , [0x33, 0x51, 0x09, 0xaf, 0xab, 0x42, 0x80, 0x8b, 0x07]
    , [0xd1, 0x78, 0x30, 0x6b, 0xc9, 0x9c, 0xaf, 0x1f, 0xd4]
    , [0xc6, 0x00, 0xf9, 0xbf, 0x4b, 0x38, 0xf0, 0x00, 0xc6]
    , [0xa1, 0x81, 0x99, 0x9a, 0xc9, 0xf2, 0x8e, 0x4c, 0x6f]
    , [0xb3, 0xd1, 0x6c, 0x57, 0x2c, 0x62, 0x3c, 0xb0, 0x5c]
    , [0xc7, 0x50, 0xc1, 0x4d, 0xec, 0xde, 0x91, 0xe8, 0xfd]
    , [0x54, 0x51, 0xfe, 0xaa, 0xec, 0xe9, 0x6b, 0xf2, 0xa2]
    , [0x5d, 0xdc, 0x27, 0xf3, 0x4b, 0xc8, 0xb0, 0x9a, 0xc9]
    , [0xd2, 0x4d, 0xe1, 0x77, 0x8c, 0x0a, 0x8f, 0x2d, 0x44]
    , [0xce, 0xe4, 0xe5, 0x80, 0xca, 0x8a, 0x07, 0xdc, 0x67]
    , [0x0f, 0xd0, 0x8f, 0x67, 0xca, 0x9f, 0x94, 0xa5, 0x86]
    , [0x89, 0xe9, 0xed, 0xdd, 0xed, 0x84, 0x84, 0x50, 0x26]
    , [0x76, 0xf5, 0xbe, 0x03, 0xac, 0x82, 0x5a, 0x09, 0x26]
    , [0xf8, 0x71, 0x02, 0xca, 0x6c, 0x6d, 0xa5, 0xae, 0xfc]
    , [0xe8, 0xcb, 0x80, 0x56, 0xad, 0x00, 0xa0, 0xd1, 0xd2]
    , [0x88, 0x89, 0x0c, 0xdd, 0x0c, 0xcf, 0xb2, 0x5d, 0xd7]
    , [0x69, 0xad, 0x8f, 0xdb, 0x0d, 0x03, 0x8a, 0xca, 0x37]
    , [0x96, 0x58, 0x24, 0x93, 0xcb, 0xbf, 0xd7, 0xf1, 0xfe]
    , [0xee, 0xb1, 0xf6, 0xd2, 0x6d, 0x9b, 0x46, 0x7d, 0x3f]
    , [0xde, 0x64, 0x18, 0xd6, 0x2e, 0x86, 0x5b, 0x3c, 0x0c]
    , [0x24, 0x05, 0x66, 0xe4, 0x0d, 0xf1, 0xc8, 0xb1, 0xd3]
    , [0x77, 0xd7, 0x5f, 0x5f, 0xef, 0x81, 0x2d, 0xb3, 0x37]
    , [0x58, 0x53, 0xf5, 0xb5, 0x2e, 0xec, 0x51, 0xfe, 0x25]
    , [0xba, 0x65, 0x2a, 0x3b, 0x8e, 0xc6, 0xbb, 0xa8, 0xb6]
    , [0xe5, 0x81, 0x4f, 0x09, 0xf0, 0x0c, 0xec, 0xf9, 0xfa]
    , [0x50, 0x5b, 0xe8, 0xf9, 0xf0, 0x6a, 0x47, 0xb4, 0x64]
    , [0xd3, 0x0e, 0xf4, 0xc7, 0x6e, 0xd9, 0x60, 0x31, 0xb5]
    , [0x58, 0xe4, 0x4a, 0x3c, 0xcd, 0x97, 0xd6, 0xfd, 0x84]
    , [0x6f, 0x82, 0xaa, 0xca, 0x2f, 0xe7, 0x1a, 0x8d, 0xb1]
    , [0x8f, 0x50, 0xec, 0x2f, 0x2f, 0xe7, 0x30, 0x4c, 0xdb]
    , [0xf0, 0x3b, 0x01, 0xdb, 0x6f, 0x33, 0xdb, 0x82, 0x41]
    , [0x13, 0x3c, 0x71, 0xe4, 0x8f, 0x75, 0x46, 0x48, 0x8f]
    , [0x2f, 0xa5, 0xa5, 0x41, 0xcd, 0xf5, 0xb4, 0xc6, 0x45]
    , [0x8b, 0x1a, 0x4c, 0x12, 0x30, 0x38, 0xc3, 0x61, 0x08]
    , [0x6f, 0x9c, 0x5c, 0x3f, 0x8f, 0xd6, 0x47, 0x70, 0xf7]
    , [0xc1, 0x0e, 0x16, 0x18, 0x50, 0x1b, 0x47, 0x48, 0xf8]
    , [0x2b, 0x94, 0x3f, 0xad, 0x30, 0xad, 0x5e, 0xc4, 0x85]
    , [0x5f, 0x55, 0x92, 0xc6, 0xce, 0xb9, 0xf5, 0x05, 0x08]
    , [0x42, 0x8e, 0x3a, 0xbb, 0xf1, 0xbd, 0x08, 0x09, 0x25]
    , [0x28, 0x84, 0xf5, 0x2b, 0xce, 0xf1, 0x3e, 0x47, 0x41]
    , [0x25, 0xd1, 0x2c, 0xbf, 0x90, 0x5c, 0x71, 0x24, 0x85]
    , [0xd0, 0x25, 0x3d, 0xf3, 0x90, 0x64, 0x67, 0xae, 0xf9]
    , [0xc5, 0x1d, 0xe5, 0x36, 0x11, 0xa9, 0x7b, 0x4d, 0xe0]
    , [0x88, 0xc2, 0x24, 0xda, 0x50, 0xf9, 0x55, 0x03, 0xdc]
    , [0xff, 0x54, 0x4f, 0x75, 0xcf, 0x6d, 0xbb, 0xc4, 0x4b]
    , [0x9e, 0x49, 0xc2, 0x63, 0x11, 0xd7, 0xb0, 0x74, 0x25]
    , [0xac, 0xb1, 0x42, 0x65, 0xcf, 0x7d, 0x84, 0x0e, 0x37]
    , [0x05, 0xa5, 0x28, 0x18, 0x11, 0xe3, 0x0d, 0x6a, 0xaa]
    , [0x03, 0x8d, 0x11, 0xce, 0xf2, 0x6f, 0x0e, 0x0a, 0xcf]
    , [0xbf, 0xd6, 0x88, 0x3d, 0x51, 0x75, 0x18, 0x67, 0x0e]
    , [0x69, 0xa2, 0xdd, 0x69, 0xcf, 0xe4, 0x94, 0x5e, 0xe3]
    , [0xe4, 0x62, 0x0b, 0x95, 0xb1, 0x58, 0xa1, 0xd4, 0x25]
    , [0xc0, 0x75, 0xc6, 0xec, 0x51, 0x9e, 0xd4, 0xc7, 0x4c]
    , [0x83, 0x9d, 0xb3, 0x97, 0x32, 0x54, 0x9b, 0x04, 0xec]
    , [0x9a, 0x7f, 0x71, 0x94, 0x32, 0xcf, 0xbb, 0x97, 0x38]
    , [0x7a, 0x4f, 0xe4, 0x60, 0x13, 0x93, 0xfd, 0x7d, 0x50]
    , [0x76, 0x48, 0x71, 0xf5, 0x52, 0x2f, 0xcb, 0xf7, 0xe2]
    , [0xda, 0x0e, 0x88, 0x1f, 0x13, 0xba, 0xd5, 0xa7, 0x2f]
    , [0x2a, 0xbe, 0xca, 0xe7, 0x33, 0x12, 0x4e, 0x33, 0x26]
    , [0x79, 0xce, 0x5e, 0xee, 0x92, 0x27, 0x5d, 0xc7, 0x17]
    , [0x36, 0x91, 0x77, 0xd3, 0x72, 0x5a, 0xde, 0x9f, 0x0b]
    , [0x3a, 0x33, 0xcd, 0x8d, 0x52, 0x7a, 0xb8, 0x2a, 0xd8]
    , [0x25, 0x66, 0xec, 0xc3, 0x52, 0x8b, 0xd0, 0x13, 0x4f]
    , [0xde, 0xd7, 0xa1, 0x1f, 0xb2, 0x58, 0x65, 0xd8, 0xd7]
    , [0x8a, 0xe5, 0xcb, 0x54, 0x33, 0xb0, 0xde, 0x92, 0x42]
    , [0x71, 0x49, 0x0a, 0xbb, 0x33, 0xd8, 0x35, 0xb3, 0x59]
    , [0x03, 0x36, 0x3b, 0x64, 0xf4, 0x98, 0x4b, 0x21, 0x99]
    , [0x8c, 0xf5, 0x50, 0x02, 0xd2, 0x10, 0xdb, 0x86, 0x1d]
    , [0xc3, 0x4f, 0xcf, 0x6e, 0x93, 0x4e, 0xb5, 0xd8, 0xb4]
    , [0x2a, 0xfb, 0x95, 0x75, 0x73, 0x8c, 0x85, 0x76, 0x82]
    , [0x35, 0xc0, 0x2a, 0x8b, 0xf5, 0x56, 0x45, 0x66, 0x45]
    , [0x68, 0x2a, 0x76, 0x44, 0x73, 0xcf, 0x31, 0x3a, 0x8e]
    , [0x98, 0x4c, 0xa0, 0x05, 0x93, 0x9a, 0xcf, 0x65, 0xa1]
    , [0xa5, 0x3e, 0x3b, 0xf8, 0x94, 0x0e, 0x6e, 0x74, 0x73]
    , [0x4b, 0x75, 0x16, 0xe9, 0x35, 0x47, 0xe2, 0xaf, 0x21]
    , [0x3c, 0x84, 0xfb, 0xee, 0xf6, 0x10, 0x6c, 0x09, 0x3f]
    , [0x45, 0x52, 0x87, 0x53, 0x74, 0x7c, 0x1b, 0x2c, 0xa1]
    , [0xa0, 0x8b, 0x28, 0xe0, 0xd3, 0x34, 0xbe, 0x90, 0xcb]
    , [0x67, 0x57, 0x50, 0xd0, 0x16, 0x3c, 0x23, 0xaf, 0xe1]
    , [0xa8, 0xa6, 0x4d, 0x44, 0x16, 0x52, 0x57, 0xba, 0x95]
    , [0x9e, 0x0c, 0xbe, 0x6a, 0x75, 0x1d, 0x3f, 0x6c, 0x20]
    , [0x14, 0x1b, 0x43, 0x7a, 0xb5, 0x4e, 0x40, 0x88, 0xb0]
    , [0x68, 0x3b, 0xbd, 0xd6, 0xf7, 0xae, 0xd7, 0xf9, 0x28]
    , [0xab, 0xc0, 0x61, 0xa3, 0x76, 0x20, 0xb8, 0xf7, 0x3b]
    , [0x05, 0xe8, 0x00, 0x91, 0xb5, 0xdd, 0xbe, 0x7e, 0xaf]
    , [0x14, 0xdd, 0x60, 0xa4, 0x96, 0x19, 0x04, 0x05, 0x16]
    , [0x7e, 0xe5, 0x14, 0xcd, 0x76, 0x87, 0x03, 0x4c, 0x2d]
    , [0x07, 0xf0, 0x09, 0x29, 0x18, 0x7d, 0x7d, 0xfe, 0x8a]
    , [0xb9, 0xb4, 0xa5, 0xc6, 0x37, 0x99, 0xfd, 0x49, 0xff]
    , [0xd2, 0xdd, 0x5a, 0x63, 0x37, 0xe4, 0x08, 0x8e, 0xd4]
    , [0xa2, 0x0b, 0xf2, 0x5e, 0x76, 0xfd, 0x65, 0x2c, 0x80]
    , [0xc8, 0xd7, 0xdf, 0xba, 0x37, 0xe8, 0xd9, 0x2b, 0x0c]
    , [0x6e, 0x40, 0x03, 0xeb, 0x37, 0xea, 0xeb, 0xa6, 0x93]
    , [0x27, 0xf9, 0x53, 0x0f, 0x37, 0xfc, 0x0e, 0x28, 0x60]
    , [0xc2, 0x72, 0x49, 0x23, 0xd5, 0xce, 0x7e, 0xbb, 0xef]
    , [0x3e, 0x11, 0xd8, 0x6b, 0xb6, 0xe9, 0x30, 0x2f, 0xab]
    , [0x0e, 0xdd, 0xb7, 0xd7, 0x19, 0x45, 0x86, 0xd7, 0x79]
    , [0xa3, 0xf7, 0x21, 0x85, 0x97, 0x07, 0x7d, 0xe1, 0x4b]
    , [0x4e, 0x76, 0x21, 0xee, 0x19, 0x67, 0x54, 0x55, 0x23]
    , [0x0f, 0x19, 0x18, 0xda, 0x38, 0x60, 0x1c, 0x0b, 0x9c]
    , [0xa4, 0x91, 0x5d, 0x2c, 0x77, 0x7f, 0xb4, 0xcb, 0xc6]
    , [0xc1, 0xb7, 0xee, 0x41, 0x19, 0x7a, 0x60, 0x4d, 0x7e]
    , [0x88, 0x47, 0x7b, 0x0c, 0xd6, 0x4c, 0xe0, 0xc1, 0x20]
    , [0x73, 0x88, 0xeb, 0x4f, 0xd6, 0x53, 0x4f, 0x7c, 0x6a]
    , [0xf4, 0x5a, 0xe5, 0xb3, 0xf9, 0xcf, 0x96, 0x88, 0x8f]
    , [0xba, 0x5c, 0xb1, 0x28, 0x58, 0x2f, 0x33, 0x16, 0xcc]
    , [0x04, 0xcd, 0x1f, 0xc8, 0x1a, 0x7a, 0x20, 0xf1, 0xd0]
    , [0x5f, 0x2c, 0x1c, 0x63, 0xb8, 0x48, 0x83, 0x82, 0xa4]
    , [0x22, 0xf5, 0xed, 0xa6, 0x98, 0x51, 0xeb, 0xa3, 0xf8]
    , [0xf8, 0x6b, 0x6d, 0x33, 0xfa, 0x65, 0x24, 0xbd, 0x5c]
    , [0x10, 0x3b, 0xb6, 0xae, 0xd7, 0x86, 0x73, 0x25, 0xd3]
    , [0x52, 0x31, 0x6c, 0x5a, 0x79, 0x03, 0xbe, 0x55, 0x95]
    , [0xaf, 0xc9, 0xab, 0x5e, 0x1b, 0x54, 0xde, 0x1d, 0x84]
    , [0xc2, 0xed, 0xf4, 0x36, 0x79, 0x77, 0x81, 0x0d, 0xee]
    , [0x36, 0xf5, 0xdb, 0xeb, 0xd8, 0x30, 0xd9, 0x69, 0xf6]
    , [0x43, 0x84, 0x92, 0xb9, 0x79, 0x90, 0x66, 0xa4, 0xe6]
    , [0x7d, 0xe9, 0x4d, 0x0e, 0x1b, 0xda, 0x69, 0xeb, 0x57]
    , [0x2d, 0x03, 0x20, 0x62, 0xfb, 0x3b, 0x6e, 0x88, 0x65]
    , [0xe5, 0x69, 0xec, 0xd2, 0x79, 0xbe, 0xd8, 0xaa, 0x8e]
    , [0xac, 0x26, 0x0a, 0xdd, 0xfb, 0x68, 0x43, 0x1f, 0x6d]
    , [0x3c, 0x96, 0xc1, 0xbe, 0x3a, 0xbe, 0x22, 0xae, 0x76]
    , [0xde, 0x73, 0x09, 0xf1, 0x1c, 0x39, 0x67, 0x8a, 0x0c]
    , [0x56, 0x2e, 0x5f, 0x2c, 0x3a, 0xfd, 0x30, 0x40, 0x7d]
    , [0x68, 0x57, 0xce, 0x1c, 0x59, 0xe0, 0xe0, 0xeb, 0x04]
    , [0xdf, 0xf7, 0xe6, 0x75, 0x1c, 0x66, 0x88, 0x86, 0x90]
    , [0xfd, 0xaf, 0xf5, 0x8b, 0x5a, 0x06, 0xae, 0x0b, 0x40]
    , [0x4e, 0xcf, 0xa7, 0xe9, 0x1c, 0x93, 0xaf, 0x36, 0xa8]
    , [0x56, 0xdc, 0x13, 0xcf, 0xfc, 0x12, 0x88, 0xbb, 0xb8]
    , [0x1f, 0x5f, 0xc2, 0xb2, 0x3b, 0x75, 0xfb, 0x7c, 0x92]
    , [0x4e, 0x9c, 0xbb, 0xba, 0x5a, 0x74, 0xe3, 0xa4, 0xe1]
    , [0x0b, 0xa0, 0xc8, 0xc5, 0x1d, 0x99, 0x06, 0x87, 0x5e]
    , [0xff, 0xef, 0xb0, 0x25, 0x1d, 0xf4, 0x9d, 0xdf, 0xdb]
    , [0x09, 0x67, 0xcb, 0x8f, 0x7c, 0x13, 0x3c, 0x75, 0x97]
    , [0x05, 0xbf, 0xfe, 0x4d, 0xfd, 0xd2, 0x6e, 0x61, 0x64]
    , [0xa4, 0xd7, 0x4b, 0x6d, 0x3d, 0x2a, 0xbb, 0xee, 0x4c]
    , [0xb9, 0x8c, 0x01, 0xcb, 0x5b, 0xf2, 0x50, 0x15, 0xf0]
    , [0x31, 0x45, 0x17, 0x91, 0x1e, 0xa3, 0x7f, 0x25, 0x52]
    , [0x10, 0x6c, 0x0c, 0x98, 0xdb, 0x0f, 0x9b, 0x1e, 0x88]
    , [0x06, 0xec, 0xcc, 0xb6, 0x9b, 0xda, 0xa2, 0x3a, 0x16]
    , [0x23, 0x66, 0x38, 0x19, 0x7c, 0xac, 0x80, 0xd3, 0x78]
    , [0xb8, 0xf3, 0xd7, 0x98, 0xbc, 0x11, 0x60, 0x0f, 0xbf]
    , [0x27, 0x24, 0x2d, 0xa8, 0xdb, 0xc2, 0x99, 0x28, 0x65]
    , [0x64, 0x61, 0x39, 0xc2, 0xbc, 0x79, 0xb5, 0xb1, 0xa6]
    , [0xdf, 0xff, 0x2a, 0x12, 0x5c, 0xfb, 0x42, 0x6d, 0x01]
    , [0xaf, 0x1d, 0xea, 0x4e, 0xff, 0x0d, 0x46, 0x95, 0x5e]
    , [0x2a, 0xb0, 0xc6, 0x54, 0x9c, 0xe9, 0x98, 0x43, 0xe1]
    , [0x7c, 0xe5, 0x9e, 0x74, 0x7d, 0xc8, 0x44, 0xef, 0x9e]
    , [0x56, 0x14, 0xd1, 0x31, 0xdc, 0xce, 0x77, 0x17, 0xc3]
    , [0xed, 0x6b, 0x65, 0x68, 0x3f, 0x05, 0x36, 0x41, 0x9b]
    , [0x2f, 0xd2, 0x24, 0x7e, 0xdd, 0x19, 0x4f, 0x91, 0x72]
    , [0xc8, 0x96, 0xf0, 0x54, 0x9d, 0x92, 0x5b, 0xcc, 0xb1]
    , [0x47, 0x5d, 0x76, 0x63, 0xbe, 0x17, 0x24, 0xad, 0xd4]
    , [0x4f, 0x88, 0x0b, 0x03, 0x9e, 0x4a, 0x48, 0xee, 0x14]
    , [0x26, 0xec, 0x1b, 0x56, 0x5e, 0xb8, 0x5d, 0x5e, 0x39]
    , [0xc3, 0xa8, 0x2d, 0x1a, 0x5e, 0xfc, 0xb7, 0x81, 0x49]
    , [0x14, 0x3a, 0x3b, 0x0b, 0xbe, 0xe7, 0xb2, 0x4d, 0x75]
    , [0x27, 0xa0, 0xf4, 0x22, 0xdf, 0xb5, 0xb6, 0x5e, 0x4a]
    ]

-- -------------------------------------------------------------------------- --
-- 64 bit FNV1a

run64a :: Bool
run64a = all test64a testVectors64a
    && all testZero64a zeros64a

tests64a :: Spec
tests64a = do
    describe "Test Vectors" $ do
        mapM_ (\x -> it (show x) (test64a x)) testVectors64a
    describe "Inputs up to 8 bytes that hash to 0" $ do
        mapM_ (\x -> it (show x) (testZero64a x)) zeros64a

test64a :: (B.ByteString, Word64) -> Bool
test64a (b, r) = hashByteString @Fnv1a64Hash b == Fnv1a64Hash r

testZero64a :: B.ByteString -> Bool
testZero64a b = hashByteString @Fnv1a64Hash b == Fnv1a64Hash 0

testVectors64a :: [(B.ByteString, Word64)]
testVectors64a = []

-- | All FNV1a 64 bit inputs that result in a hash of 0 up to a length of eight
-- bytes.
--
-- (cf. http://www.isthe.com/chongo/tech/comp/fnv/)
--
zeros64a :: [B.ByteString]
zeros64a = B.pack <$>
    [ [0xd5, 0x6b, 0xb9, 0x53, 0x42, 0x87, 0x08, 0x36]
    ]

-- -------------------------------------------------------------------------- --
-- 32 bit FNV1

run32 :: Bool
run32 = all test32 testVectors32
    && all testZero32 zeros32
    && testZero32 zero32ff

tests32 :: Spec
tests32 = do
    describe "Test Vectors" $ do
        mapM_ (\x -> it (show x) (test32 x)) testVectors32
    describe "Two out of 254 inputs of up to 5 bytes that hash to 0" $ do
        mapM_ (\x -> it (show x) (testZero32 x)) zeros32

test32 :: (B.ByteString, Word32) -> Bool
test32 (b, r) = hashByteString @Fnv132Hash b == Fnv132Hash r

testVectors32 :: [(B.ByteString, Word32)]
testVectors32 = []

testZero32 :: B.ByteString -> Bool
testZero32 b = hashByteString @Fnv132Hash b == Fnv132Hash 0

-- | Two out of 254 inputs of up to 5 bytes length that result in a
-- fnv1 32 bit hash of 0.
--
-- (cf. http://www.isthe.com/chongo/tech/comp/fnv/)
--
zeros32 :: [B.ByteString]
zeros32 = B.pack <$>
    [ [0x01, 0x47, 0x6c, 0x10, 0xf3]
    , [0xfd, 0x45, 0x41, 0x08, 0xa0]
    ]

-- | The shortest set of consecutive 0xff octets for which the 32-bit FNV-1 hash
-- is 0.
--
-- (cf. http://www.isthe.com/chongo/tech/comp/fnv/)
--
zero32ff :: B.ByteString
zero32ff = B.replicate 428876705 0xff

-- -------------------------------------------------------------------------- --
-- 32 bit FNV1a

run32a :: Bool
run32a = all test32a testVectors32a
    && all testZero32a zeros32a
    && testZero32a zero32ffa

tests32a :: Spec
tests32a = do
    describe "Test Vectors" $ do
        mapM_ (\x -> it (show x) (test32a x)) testVectors32a
    describe "Inputs up to 4 bytes that hash to 0" $ do
        mapM_ (\x -> it (show x) (testZero32a x)) zeros32a

test32a :: (B.ByteString, Word32) -> Bool
test32a (b, r) = hashByteString @Fnv1a32Hash b == Fnv1a32Hash r

testVectors32a :: [(B.ByteString, Word32)]
testVectors32a = []

testZero32a :: B.ByteString -> Bool
testZero32a b = hashByteString @Fnv1a32Hash b == Fnv1a32Hash 0

-- | All FNV1a 32 bit inputs that result in a hash of 0 up to a length of four
-- bytes.
--
-- (cf. http://www.isthe.com/chongo/tech/comp/fnv/)
--
zeros32a :: [B.ByteString]
zeros32a = B.pack <$>
    [ [0xcc, 0x24, 0x31, 0xc4]
    , [0xe0, 0x4d, 0x9f, 0xcb]
    ]

zero32ffa :: B.ByteString
zero32ffa = B.replicate 3039744951 0xff

-- -------------------------------------------------------------------------- --
-- Primitive FNV1

primitiveFnv1 :: B.ByteString -> Word
primitiveFnv1 b = unsafeDupablePerformIO $
    B.unsafeUseAsCStringLen b $ \(addr, n) -> fnv1_host (castPtr addr) n
{-# INLINE primitiveFnv1 #-}

runPrim :: Bool
runPrim = all testPrim testVectorsPrim
    && all testZeroPrim zerosPrim

testsPrim :: Spec
testsPrim = do
    describe "Test Vectors" $ do
        mapM_ (\x -> it (show x) (testPrim x)) testVectorsPrim
    describe "Inputs up to 9 bytes that hash to 0" $ do
        mapM_ (\x -> it (show x) (testZeroPrim x)) zerosPrim

testPrim :: (B.ByteString, Word) -> Bool
testPrim (b, r) = primitiveFnv1 b == r

testZeroPrim :: B.ByteString -> Bool
testZeroPrim b = primitiveFnv1 b == 0

testVectorsPrim :: [(B.ByteString, Word)]
#if defined(x86_64_HOST_ARCH)
testVectorsPrim = second fromIntegral <$> testVectors64
#elif defined(i386_HOST_ARCH)
testVectorsPrim = second fromIntegral <$> testVectors32
#else
testVectorsPrim = error "testVectorsPrim: unsupported hardware platform"
#endif

zerosPrim :: [B.ByteString]
#if defined(x86_64_HOST_ARCH)
zerosPrim = zeros64
#elif defined(i386_HOST_ARCH)
zerosPrim = zeros32
#else
zerosPrim = error "zerosPrim: unsupported hardware platform"
#endif

-- -------------------------------------------------------------------------- --
-- Primitive FNV1a

primitiveFnv1a :: B.ByteString -> Word
primitiveFnv1a b = unsafeDupablePerformIO $
    B.unsafeUseAsCStringLen b $ \(addr, n) -> fnv1a_host (castPtr addr) n
{-# INLINE primitiveFnv1a #-}

runPrima :: Bool
runPrima = all testPrima testVectorsPrima
    && all testZeroPrima zerosPrima

testsPrima :: Spec
testsPrima = do
    describe "Test Vectors" $ do
        mapM_ (\x -> it (show x) (testPrima x)) testVectorsPrima
    describe "Inputs up to 8 bytes that hash to 0" $ do
        mapM_ (\x -> it (show x) (testZeroPrima x)) zerosPrima

testPrima :: (B.ByteString, Word) -> Bool
testPrima (b, r) = primitiveFnv1a b == r

testZeroPrima :: B.ByteString -> Bool
testZeroPrima b = primitiveFnv1a b == 0

testVectorsPrima :: [(B.ByteString, Word)]
#if defined(x86_64_HOST_ARCH)
testVectorsPrima = second fromIntegral <$> testVectors64a
#elif defined(i386_HOST_ARCH)
testVectorsPrima = second fromIntegral <$> testVectors32a
#endif

zerosPrima :: [B.ByteString]
#if defined(x86_64_HOST_ARCH)
zerosPrima = zeros64a
#elif defined(i386_HOST_ARCH)
zerosPrima = zeros32a
#endif

