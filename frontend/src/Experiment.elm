module Experiment exposing (Experiment, fetch, fetchAllBySample)

{-| The interface to the Sample data structure.
-}

import Http
import HttpBuilder
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required, optional)
import Json.Encode as Encode
import Config exposing (apiBaseUrl)
--import Debug exposing (toString)



-- TYPES


type alias Experiment  =
    { id : Int
    , name : String
    , accn : String
    , library_name : String
    , library_strategy : String
    , library_source : String
    , library_selection : String
    , library_protocol : String
    , library_layout : String
    , library_length : Maybe Int
    , sampleId : Int
    , sampleAccn : String
    , projectId : Int
    , projectName : String
    }



-- SERIALIZATION


experimentDecoder : Decoder Experiment
experimentDecoder =
    Decode.succeed Experiment
        |> required "experiment_id" Decode.int
        |> required "name" Decode.string
        |> required "accn" Decode.string
        |> optional "library_name" Decode.string  ""
        |> optional "library_strategy" Decode.string  ""
        |> optional "library_source" Decode.string  ""
        |> optional "library_selection" Decode.string  ""
        |> optional "library_protocol" Decode.string  ""
        |> optional "library_layout" Decode.string  ""
        |> optional "library_length" (Decode.nullable Decode.int) Nothing
        |> optional "sample_id" Decode.int 0
        |> optional "sample_accn" Decode.string ""
        |> optional "project_id" Decode.int 0
        |> optional "project_name" Decode.string ""



-- REQUESTS


fetch : Int -> Http.Request Experiment
fetch id  =
    let
        url =
            apiBaseUrl ++ "/experiments/" ++ (String.fromInt id)
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson experimentDecoder)
        |> HttpBuilder.toRequest


fetchAllBySample : Int -> Http.Request (List Experiment)
fetchAllBySample id =
    let
        url =
            apiBaseUrl ++ "/samples/" ++ (String.fromInt id) ++ "/experiments"
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson (Decode.list experimentDecoder))
        |> HttpBuilder.toRequest