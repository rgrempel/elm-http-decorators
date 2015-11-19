module Example where

import Effects exposing (Effects, Never)
import StartApp exposing (App)
import Task exposing (Task, toResult)
import Html exposing (Html, h4, div, text, button, input)
import Html.Attributes exposing (id, type')
import Html.Events exposing (onClick, targetValue, on)
import Signal exposing (Signal, Address)

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


app : App Model
app =
    StartApp.start
        { init = init
        , update = update
        , view = view
        , inputs = []
        }


main : Signal Html
main = app.html


port tasks : Signal (Task.Task Never ())
port tasks = app.tasks


type alias Model =
    { message : String
    }


init : (Model, Effects Action)
init = (Model "Initial state", Effects.none)


type Action
    = OneTask
    | SpecialSend
    | VerySpecialSend
    | LessSpecialSend
    | HandleRawResponse (Result RawError Response)
    | HandleResponse (Result Error Response)


update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        OneTask ->
            ( { model | message = "Sending with addCacheBuster" }
            , oneTask
                |> toResult
                |> Task.map HandleRawResponse
                |> Effects.task
            )

        SpecialSend ->
            ( { model | message = "Sending with specialSend" }
            , useSpecialSend
                |> toResult
                |> Task.map HandleRawResponse
                |> Effects.task
            )

        VerySpecialSend ->
            ( { model | message = "Sending with verySpecialSend" }
            , useVerySpecialSend
                |> toResult
                |> Task.map HandleResponse
                |> Effects.task
            )

        LessSpecialSend ->
            ( { model | message = "Sending with lessSpecialSend" }
            , useLessSpecialSend
                |> toResult
                |> Task.map HandleResponse
                |> Effects.task
            )

        HandleRawResponse result ->
            ( { model | message = toString result }
            , Effects.none
            )
        
        HandleResponse result ->
            ( { model | message = toString result }
            , Effects.none
            )
 

view : Address Action -> Model -> Html
view address model =
    div []
        [ button
            [ onClick address OneTask ]
            [ text "addCacheBuster" ]
        , button
            [ onClick address SpecialSend ]
            [ text "specialSend" ]
        , button
            [ onClick address VerySpecialSend ]
            [ text "verySpecialSend" ]
        , button
            [ onClick address LessSpecialSend ]
            [ text "lessSpecialSend" ]

        , h4 [] [ text "Message" ]
        , div [ id "message" ] [ text model.message ]
        ]

