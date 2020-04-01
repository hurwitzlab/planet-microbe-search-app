module Page.Browse exposing (Model, Msg, init, toSession, update, view)

import Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Page
import Route exposing (Route)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)
--import Page.Error as Error exposing (PageLoadError)
import Task exposing (Task)
import String.Extra
import Dict exposing (Dict)
--import Debug exposing (toString)
import Project exposing (Project)
import Sample exposing (Sample)
import Icon



---- MODEL ----


type alias Model =
    { session : Session
    , projects : Maybe (List Project)
    , samples : Maybe (List Sample)
    , projectDescriptionStates : Dict Int Bool
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , projects = Nothing
      , samples = Nothing
      , projectDescriptionStates = Dict.empty
      }
      , Cmd.batch
        [ Project.fetchAll |> Http.send GetProjectsCompleted
        , Sample.fetchAll |> Http.send GetSamplesCompleted
        ]
    )


toSession : Model -> Session
toSession model =
    model.session



-- UPDATE --


type Msg
    = GetProjectsCompleted (Result Http.Error (List Project))
    | GetSamplesCompleted (Result Http.Error (List Sample))
    | ToggleProjectDescription Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetProjectsCompleted (Ok projects) ->
            ( { model | projects = Just projects }, Cmd.none )

        GetProjectsCompleted (Err error) -> --TODO
--            let
--                _ = Debug.log "GetProjectsCompleted" (toString error)
--            in
            ( model, Cmd.none )

        GetSamplesCompleted (Ok samples) ->
            ( { model | samples = Just samples }, Cmd.none )

        GetSamplesCompleted (Err error) -> --TODO
--            let
--                _ = Debug.log "GetSamplesCompleted" (toString error)
--            in
            ( model, Cmd.none )

        ToggleProjectDescription id ->
            let
                val =
                    if Dict.get id model.projectDescriptionStates == Just True then
                        False
                    else
                        True

                projectDescriptionStates =
                    Dict.insert id val model.projectDescriptionStates
            in
            ( { model | projectDescriptionStates = projectDescriptionStates }, Cmd.none )



-- VIEW --


view : Model -> Html Msg
view model =
    let
        numProjects =
            model.projects |> Maybe.withDefault [] |> List.length

        numSamples =
            model.samples |> Maybe.withDefault [] |> List.length
    in
    div [ class "container" ]
        [ div [ class "pt-5" ]
            [ Page.viewTitle1 "Projects" False
            , span [ class "badge badge-pill badge-primary align-middle ml-2" ]
                [ if numProjects == 0 then
                    text ""
                  else
                    text (String.fromInt numProjects)
                ]
            , a [ class "btn btn-primary mt-2 float-right", href "https://www.planetmicrobe.org/download/", target "_blank" ]
                [ Icon.externalLink
                , text " Download"
                ]
            ]
        , div [ class "pt-2" ]
            [ viewProjects model.projects model.projectDescriptionStates
            ]
        , div [ class "pt-4" ]
            [ Page.viewTitle1 "Samples" False
            , span [ class "badge badge-pill badge-primary align-middle ml-2" ]
                [ if numSamples == 0 then
                    text ""
                  else
                    text (String.fromInt numSamples)
                ]
            ]
        , div [ class "pt-2", style "overflow-y" "auto", style "max-height" "80vh"]
            [ viewSamples model.samples
            ]
        ]


viewProjects : Maybe (List Project) -> Dict Int Bool -> Html Msg
viewProjects maybeProjects descriptionStates =
    let


        mkRow project =
            tr []
                [ td [ class "text-nowrap" ]
                    [ a [ Route.href (Route.Project project.id) ] [ text project.name ] ]
                , td [] [ Page.viewToggleText project.description (Dict.get project.id descriptionStates |> Maybe.withDefault False) (ToggleProjectDescription project.id) ]
                , td [] [ text (String.Extra.toSentenceCase project.type_) ]
                , td [] [ text (String.fromInt project.sampleCount) ]
                ]
    in
    case maybeProjects of
        Nothing ->
            Page.viewSpinner

        Just projects ->
            if projects == [] then
                text "None"
            else
                table [ class "table" ]
                    [ thead []
                        [ tr []
                            [ th [] [ text "Name" ]
                            , th [] [ text "Description" ]
                            , th [] [ text "Type" ]
                            , th [] [ text "Samples" ]
                            ]
                        ]
                    , tbody []
                        (projects |> List.sortBy .name |> List.map mkRow)
                    ]


viewSamples : Maybe (List Sample) -> Html Msg
viewSamples maybeSamples =
    let
        mkRow sample =
            tr []
                [ td [ class "text-nowrap" ]
                    [ a [ Route.href (Route.Sample sample.id) ] [ text sample.accn ] ]
                , td [ class "text-nowrap" ]
                    [ a [ Route.href (Route.Project sample.projectId) ] [ text sample.projectName ] ]
                ]
    in
    case maybeSamples of
        Nothing ->
            Page.viewSpinner

        Just samples ->
            if samples == [] then
                text "None"
            else
                table [ class "table" ]
                    [ thead []
                        [ tr []
                            [ th [] [ text "Accn" ]
                            , th [] [ text "Project" ]
                            ]
                        ]
                    , tbody []
                        (samples |> List.sortBy .accn |> List.map mkRow)
                    ]