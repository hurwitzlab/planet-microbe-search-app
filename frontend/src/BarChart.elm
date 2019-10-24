module BarChart exposing (Config, defaultConfig, view)

-- Modified from https://code.gampleman.eu/elm-visualization/BarChart/
--TODO move into own elm package

import Axis
import DateFormat
import Scale exposing (BandConfig, BandScale, ContinuousScale, defaultBandConfig)
import Time
import TypedSvg exposing (g, rect, style, svg, text_)
import TypedSvg.Attributes exposing (class, textAnchor, transform, viewBox)
import TypedSvg.Attributes.InPx exposing (height, width, x, y)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (AnchorAlignment(..), Transform(..))


type alias Config a =
    { width : Float
    , height : Float
    , padding : Float
    , formatter : (a -> String)
    , title : Maybe String
    }


defaultConfig : Config String
defaultConfig =
    { width = 900
    , height = 450
    , padding = 30
    , formatter = (\s -> s)
    , title = Nothing
    }


xScale : Float -> Float -> List ( a, Float ) -> BandScale a
xScale w padding model =
    List.map Tuple.first model
        |> Scale.band { defaultBandConfig | paddingInner = 0.1, paddingOuter = 0.2 } ( 0, w - 2 * padding )


yScale : Float -> Float -> (Float, Float) -> ContinuousScale Float
yScale h padding range =
    Scale.linear ( h - 2 * padding, 0 ) range


dateFormat : Time.Posix -> String
dateFormat =
    DateFormat.format [ DateFormat.dayOfMonthFixed, DateFormat.text " ", DateFormat.monthNameAbbreviated ] Time.utc


xAxis : Float -> Float -> List ( a, Float ) -> (a -> String) -> Svg msg
xAxis w padding model formatter =
    Axis.bottom [] (Scale.toRenderable formatter (xScale w padding model))


yAxis : Float -> Float -> (Float, Float) -> Svg msg
yAxis h padding range =
    Axis.left [ Axis.tickCount 5 ] (yScale h padding range)


column : Float -> Float -> Float -> (Float, Float) -> (a -> String) -> BandScale a -> (a, Float ) -> Svg msg
column w h padding range formatter scale ( label, value ) =
    g [ class [ "column" ] ]
        [ rect
            [ x <| Scale.convert scale label
            , y <| Scale.convert (yScale h padding range) value
            , width <| Scale.bandwidth scale
            , height <| h - Scale.convert (yScale h padding range) value - 2 * padding
            ]
            []
        , text_
            [ x <| Scale.convert (Scale.toRenderable formatter scale) label
            , y <| Scale.convert (yScale h padding range) value - 5
            , textAnchor AnchorMiddle
            ]
            [ text <| String.fromFloat value ]
        ]


view : Config a -> List ( a, Float ) -> Svg msg
view config model =
    let
        min =
            model |> List.map Tuple.second |> List.minimum |> Maybe.withDefault 0

        max =
            model |> List.map Tuple.second |> List.maximum |> Maybe.withDefault 10

        range =
            ( if min < 0 then min else 0 -- Always start from 0 on y axis unless min is negative
            , max
            )
    in
    svg [ viewBox 0 0 config.width config.height ]
        [ style [] [ text """
            .column rect { fill: rgba(118, 214, 78, 0.8); }
            .column text { display: none; }
            .column:hover rect { fill: rgb(118, 214, 78); }
            .column:hover text { display: inline; }
          """ ]
        , case config.title of
            Just title ->
                g [] [ text title ]

            Nothing ->
                g [] []
        , g [ transform [ Translate (config.padding - 1) (config.height - config.padding) ] ]
            [ xAxis config.width config.padding model config.formatter ]
        , g [ transform [ Translate (config.padding - 1) config.padding ] ]
            [ yAxis config.height config.padding range ]
        , g [ transform [ Translate config.padding config.padding ], class [ "series" ] ] <|
            List.map (column config.width config.height config.padding range config.formatter (xScale config.width config.padding model)) model
        ]