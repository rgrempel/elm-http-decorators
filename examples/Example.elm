module Example exposing ()

import Task exposing (Task, toResult)
import Html exposing (Html, h4, div, text, button, input)
import Html.Attributes exposing (id, type')
import Html.Events exposing (onClick, targetValue, on)
import Html.App as App

import Http.Decorators exposing (addCacheBuster, promoteError, interpretStatus)
import Http exposing (..)


oneTask : Task RawError Response
oneTask =
    addCacheBuster Http.send Http.defaultSettings
        { verb = "GET"
        , headers = []
        , url = Http.url "http://www.elm-lang.org/" []
        , body = Http.empty
        }


specialSend : Settings -> Request -> Task RawError Response
specialSend = addCacheBuster Http.send


useSpecialSend : Task RawError Response
useSpecialSend =
    specialSend defaultSettings
        { verb = "GET"
        , headers = []
        , url = Http.url "http://github.com/" []
        , body = Http.empty
        }


verySpecialSend : Request -> Task Error Response
verySpecialSend = interpretStatus << addCacheBuster Http.send Http.defaultSettings


useVerySpecialSend : Task Error Response
useVerySpecialSend =
    verySpecialSend
        { verb = "GET"
        , headers = []
        , url = Http.url "http://www.apple.com/" []
        , body = Http.empty
        }


lessSpecialSend : Settings -> Request -> Task Error Response
lessSpecialSend settings = interpretStatus << addCacheBuster Http.send settings


useLessSpecialSend : Task Error Response
useLessSpecialSend =
    lessSpecialSend defaultSettings
        { verb = "GET"
        , headers = []
        , url = Http.url "http://package.elm-lang.org/" []
        , body = Http.empty
        }


app =
    App.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


main = app.html


type alias Model =
    { message : String
    }


init : (Model, Cmd Msg)
init = (Model "Initial state", Cmd.none)


type Msg
    = OneTask
    | SpecialSend
    | VerySpecialSend
    | LessSpecialSend
    | HandleRawResponse (Result RawError Response)
    | HandleResponse (Result Error Response)


never : Never -> a
never n = never n


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        OneTask ->
            ( { model | message = "Sending with addCacheBuster" }
            , oneTask
                |> toResult
                |> Task.perform never HandleRawResponse
            )

        SpecialSend ->
            ( { model | message = "Sending with specialSend" }
            , useSpecialSend
                |> toResult
                |> Task.perform never HandleRawResponse
            )

        VerySpecialSend ->
            ( { model | message = "Sending with verySpecialSend" }
            , useVerySpecialSend
                |> toResult
                |> Task.perform never HandleResponse
            )

        LessSpecialSend ->
            ( { model | message = "Sending with lessSpecialSend" }
            , useLessSpecialSend
                |> toResult
                |> Task.perform never HandleResponse
            )

        HandleRawResponse result ->
            ( { model | message = toString result }
            , Cmd.none
            )

        HandleResponse result ->
            ( { model | message = toString result }
            , Cmd.none
            )


view : Model -> Html Msg
view address model =
    div []
        [ button
            [ onClick OneTask ]
            [ text "addCacheBuster" ]
        , button
            [ onClick SpecialSend ]
            [ text "specialSend" ]
        , button
            [ onClick VerySpecialSend ]
            [ text "verySpecialSend" ]
        , button
            [ onClick LessSpecialSend ]
            [ text "lessSpecialSend" ]

        , h4 [] [ text "Message" ]
        , div [ id "message" ] [ text model.message ]
        ]

