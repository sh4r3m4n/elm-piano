port module InteractivePiano exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe exposing (Maybe(..), withDefault)
import Set
import PlayerController
import Piano
import Utils exposing (debugNotes, sizeSelector)


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { midiJSLoaded : Bool
    , pianoState : Piano.State
    , pianoSize : ( Piano.Note, Piano.Note )
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model
        False
        Piano.initialState
        Piano.keyboard25Keys
    , Cmd.none
    )



-- UPDATE


type Msg
    = MidiJSLoaded
    | PianoEvent Piano.Msg
    | ChangePianoSize ( Piano.Note, Piano.Note )


port noteOn : Int -> Cmd msg


port noteOff : Int -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MidiJSLoaded ->
            ( { model | midiJSLoaded = True }
            , Cmd.none )

        PianoEvent pianoMsg ->
            let
                ( pianoState, keys ) =
                    Piano.update pianoMsg model.pianoState

                noteOnCmds : List (Cmd msg)
                noteOnCmds =
                    Piano.newNotes keys
                        |> Set.toList
                        |> List.map noteOn

                noteOffCmds : List (Cmd msg)
                noteOffCmds =
                    Piano.releasedNotes keys
                        |> Set.toList
                        |> List.map noteOff
            in
                ( { model | pianoState = pianoState }
                , Cmd.batch (noteOnCmds ++ noteOffCmds)
                )

        ChangePianoSize size ->
            ( { model | pianoSize = size }
            , Cmd.none
            )



-- SUBSCRIPTIONS


port midiJSLoaded : (() -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    midiJSLoaded (always MidiJSLoaded)



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        pianoConfig =
            Piano.makeConfig model.pianoSize
    in
        if model.midiJSLoaded then
            { title = "Interactive Piano"
            , body =
                [ Piano.viewInteractive
                    pianoConfig
                    model.pianoState
                    |> Html.map PianoEvent
                , debugNotes model.pianoState
                , sizeSelector ChangePianoSize
                ]
            }
        else
            { title = "Loading..."
            , body = [ text "MIDI.js not loaded" ]
            }
