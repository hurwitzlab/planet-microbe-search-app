module Sample exposing (Sample, PURL, Metadata, Field, Value(..), SearchTerm, fetch, fetchAll, fetchAllByProject, fetchAllBySamplingEvent, fetchAllByCampaign, fetchMetadata, fetchSearchTerms, fetchSearchTerm)

{-| The interface to the Sample data structure.
-}

import Http
import HttpBuilder
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required, optional)
import Json.Encode as Encode
import Dict exposing (Dict)
import LatLng exposing (LatLng)
import Config exposing (apiBaseUrl)
import Debug exposing (toString)



-- TYPES


type alias Sample  =
    { id : Int
    , accn : String
    , locations : List LatLng
    , samplingEventId : Int
    , samplingEventType : String
    , samplingEventName : String
    , campaignId : Int
    , campaignName : String
    , campaignType : String
    , projectId : Int
    , projectName : String
    }


type alias PURL =
    String


type alias Metadata =
    { schema_id : Int
    , fields : List Field
    , values : List (Maybe Value)
    }


type alias Term =
    { purl : PURL
    , label : String
    }


type alias Field =
    { name : String
    , type_ : String
    , rdfType : PURL
    , unitRdfType : PURL
    }


type Value
    = StringValue String
    | IntValue Int
    | FloatValue Float


type alias SearchTerm =
    { type_ : String
    , id : PURL
    , label : String
    , unitLabel : String
    , aliases : List String
    , min : Float
    , max : Float
    , values : Dict String Int --FIXME change to List (String, Int)
--    , viewType : String -- "range", "offset", "exact"
    }



-- SERIALIZATION


sampleDecoder : Decoder Sample
sampleDecoder =
    Decode.succeed Sample
        |> required "sample_id" Decode.int
        |> required "accn" Decode.string
        |> required "locations" (Decode.list LatLng.decoder)
        |> optional "sampling_event_id" Decode.int 0
        |> optional "sampling_event_type" Decode.string ""
        |> optional "sampling_event_name" Decode.string ""
        |> optional "campaign_id" Decode.int 0
        |> optional "campaign_name" Decode.string ""
        |> optional "campaign_type" Decode.string ""
        |> optional "project_id" Decode.int 0
        |> optional "project_name" Decode.string ""


metadataDecoder : Decoder Metadata
metadataDecoder =
    Decode.succeed Metadata
        |> required "schema_id" Decode.int
        |> required "fields" (Decode.list fieldDecoder)
        |> required "values" (Decode.list valueDecoder)


fieldDecoder : Decoder Field
fieldDecoder =
    Decode.succeed Field
        |> required "name" Decode.string
        |> required "type" Decode.string
        |> optional "rdfType" Decode.string ""
        |> optional "pm:unitRdfType" Decode.string ""


valueDecoder : Decoder (Maybe Value)
valueDecoder =
    Decode.nullable
        (Decode.oneOf
            [ Decode.map StringValue Decode.string
            , Decode.map IntValue Decode.int
            , Decode.map FloatValue Decode.float
            ]
        )


searchTermDecoder : Decoder SearchTerm
searchTermDecoder =
    Decode.succeed SearchTerm
        |> required "type" Decode.string
        |> required "id" Decode.string
        |> required "label" Decode.string
        |> optional "unitLabel" Decode.string ""
        |> optional "aliases" (Decode.list Decode.string) []
        |> optional "min" Decode.float 0
        |> optional "max" Decode.float 0
        |> optional "values" (Decode.dict Decode.int) Dict.empty



-- REQUESTS


fetch : Int -> Http.Request Sample
fetch id  =
    let
        url =
            apiBaseUrl ++ "/samples/" ++ (toString id)
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson sampleDecoder)
        |> HttpBuilder.toRequest


fetchAll : Http.Request (List Sample)
fetchAll =
    let
        url =
            apiBaseUrl ++ "/samples"
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson (Decode.list sampleDecoder))
        |> HttpBuilder.toRequest


fetchAllByProject : Int -> Http.Request (List Sample)
fetchAllByProject id =
    let
        url =
            apiBaseUrl ++ "/projects/" ++ (toString id) ++ "/samples"
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson (Decode.list sampleDecoder))
        |> HttpBuilder.toRequest


fetchAllBySamplingEvent : Int -> Http.Request (List Sample)
fetchAllBySamplingEvent id =
    let
        url =
            apiBaseUrl ++ "/sampling_events/" ++ (toString id) ++ "/samples"
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson (Decode.list sampleDecoder))
        |> HttpBuilder.toRequest


fetchAllByCampaign : Int -> Http.Request (List Sample)
fetchAllByCampaign id =
    let
        url =
            apiBaseUrl ++ "/campaigns/" ++ (toString id) ++ "/samples"
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson (Decode.list sampleDecoder))
        |> HttpBuilder.toRequest


fetchMetadata : Int -> Http.Request Metadata
fetchMetadata id =
    let
        url =
            apiBaseUrl ++ "/samples/" ++ (toString id) ++ "/metadata"
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson metadataDecoder)
        |> HttpBuilder.toRequest


fetchSearchTerms : Http.Request (List SearchTerm)
fetchSearchTerms =
    let
        url =
            apiBaseUrl ++ "/searchTerms" --FIXME change to samples/searchTerms
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson (Decode.list searchTermDecoder))
        |> HttpBuilder.toRequest


fetchSearchTerm : PURL -> Http.Request SearchTerm
fetchSearchTerm id =
    let
        url =
            apiBaseUrl ++ "/searchTerms/" ++ id --FIXME change to samples/searchTerms
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson searchTermDecoder)
        |> HttpBuilder.toRequest