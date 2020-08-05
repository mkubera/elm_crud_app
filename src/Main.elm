module Main exposing (main)

import Api.Cmds exposing (..)
import Api.Decoders exposing (..)
import Api.Encoders exposing (..)
import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Http
import Model exposing (..)
import Msg exposing (..)


main =
    Browser.element { init = initialModel, update = update, view = view, subscriptions = subs }



-- SUBS


subs model =
    Sub.none



-- INIT


initialModel : () -> ( Model, Cmd Msg )
initialModel _ =
    ( { users = []
      , enteredUsername = ""
      , errorMessage = Nothing
      }
    , Cmd.batch [ getUsers ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUsers result ->
            case result of
                Ok fetchedUsers ->
                    let
                        newUsers =
                            fetchedUsers |> List.map (\{ id, name, verified } -> { id = id, name = name, verified = verified, isEditable = False })
                    in
                    ( { model | users = newUsers }, Cmd.none )

                Err _ ->
                    ( { model | errorMessage = Just UsersFetch }, Cmd.none )

        GotCreatedUser result ->
            case result of
                Ok { id, name, verified } ->
                    let
                        newUser =
                            { id = id, name = name, verified = verified, isEditable = True }

                        newUsers =
                            newUser :: model.users
                    in
                    ( { model | users = newUsers }, Cmd.none )

                Err _ ->
                    ( { model | errorMessage = Just UserCreate }, Cmd.none )

        GotUpdatedUser result ->
            case result of
                Ok { id, name } ->
                    let
                        newUsers =
                            model.users
                                |> List.map
                                    (\u ->
                                        if u.id == id then
                                            { u | name = name, isEditable = False }

                                        else
                                            u
                                    )
                    in
                    ( { model | users = newUsers }, Cmd.none )

                Err _ ->
                    ( { model | errorMessage = Just UserUpdate }, Cmd.none )

        GotDeletedUser result ->
            case result of
                Ok userId ->
                    let
                        newUsers =
                            model.users |> List.filter (\u -> u.id /= userId)
                    in
                    ( { model | users = newUsers }, Cmd.none )

                Err _ ->
                    ( { model | errorMessage = Just UserDelete }, Cmd.none )

        GotVerifiedUser result ->
            case result of
                Ok userId ->
                    let
                        newUsers =
                            model.users
                                |> List.map
                                    (\u ->
                                        if u.id == userId then
                                            { u | verified = True }

                                        else
                                            u
                                    )
                    in
                    ( { model | users = newUsers }, Cmd.none )

                Err _ ->
                    ( { model | errorMessage = Just UserVerify }, Cmd.none )

        AddUser ->
            ( model, Cmd.batch [ postNewUser ] )

        MakeEditable userId ->
            ( { model
                | users =
                    List.map
                        (\u ->
                            if u.id == userId then
                                { u | isEditable = True }

                            else
                                u
                        )
                        model.users
                , enteredUsername =
                    chosenUser userId model.users |> .name
              }
            , Cmd.none
            )

        StoreEnteredUsername uname ->
            ( { model | enteredUsername = uname }, Cmd.none )

        CloseEdit userId ->
            ( { model
                | users =
                    List.map
                        (\u ->
                            if u.id == userId then
                                { u | isEditable = False }

                            else
                                u
                        )
                        model.users
              }
            , Cmd.none
            )

        UpdateUser userId ->
            let
                user =
                    chosenUser userId model.users

                editedUser =
                    FetchedUser userId model.enteredUsername user.verified
            in
            ( model, Cmd.batch [ putEditedUser editedUser ] )

        DeleteUser userId ->
            ( model, Cmd.batch [ deleteUser userId ] )

        VerifyUser userId ->
            ( model, Cmd.batch [ verifyUser userId ] )

        CloseErrorMessage ->
            ( { model | errorMessage = Nothing }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    layout [ Background.color color.gray245, Font.family [ Font.typeface "Recursive" ] ] <|
        column [ width fill, paddingXY 200 20, centerX, inFront (viewErrorMessage model.errorMessage) ]
            [ column [ width fill, spacing 5 ]
                [ viewHeader
                , viewUsers model
                ]
            ]


color =
    { white = rgb255 255 255 255
    , black = rgb255 0 0 0
    , gray100 = rgb255 100 100 100
    , gray150 = rgb255 150 150 150
    , gray200 = rgb255 200 200 200
    , gray240 = rgb255 240 240 240
    , gray245 = rgb255 245 245 245
    , gray250 = rgb255 250 250 250
    , errMsgBg = rgb255 82 185 255
    }


viewHeader : Element Msg
viewHeader =
    el [ centerX, padding 40, Border.rounded 5, Font.center, Font.bold, Font.size 24, Font.letterSpacing 2, Background.color color.white, Border.glow color.gray240 5 ] (text "CRUD App - Elm - Jexia")


viewBtn : List (Attribute Msg) -> Maybe Msg -> String -> Element Msg
viewBtn attrs mbMsg txt =
    Input.button attrs
        { onPress = mbMsg
        , label = text txt
        }


viewUsers : Model -> Element Msg
viewUsers model =
    column [ width fill, paddingXY 180 70, spacing 10, Border.rounded 5, Background.color color.white, Border.glow color.gray240 5 ]
        [ row [ width fill ] [ viewBtn [ width fill, Font.center, padding 20, Border.rounded 5, Border.width 2, Border.dashed, Border.color (rgb255 0 0 0), mouseOver [ Border.color color.gray100, Font.color color.gray100 ] ] (Just AddUser) "Add a new User" ]
        , row [ width fill ]
            [ column [ width fill, spacing 10 ]
                (model.users
                    |> List.sortBy .name
                    |> List.map
                        (\u ->
                            row [ width fill, Font.center, padding 20, spacing 10, Border.rounded 5, Border.width 1, Border.solid, Border.color (rgb255 230 230 230), Background.color color.white, Border.glow color.gray245 5, mouseOver [ Border.color (rgb255 220 220 220) ] ] <|
                                case u.isEditable of
                                    True ->
                                        [ Input.text [ centerX, height (px 30), padding 4 ]
                                            { onChange = StoreEnteredUsername
                                            , text = model.enteredUsername
                                            , placeholder = Nothing
                                            , label = Input.labelHidden "Entered username"
                                            }
                                        , viewBtn [ centerX, Font.size 14, Border.rounded 5, padding 5, Background.color (rgb255 160 248 180), mouseOver [ alpha 0.8 ] ] (Just (UpdateUser u.id)) "yes"
                                        , viewBtn [ centerX, Font.size 14, Border.rounded 5, padding 5, Background.color (rgb255 240 112 121), mouseOver [ alpha 0.8 ] ] (Just (CloseEdit u.id)) "no"
                                        ]

                                    False ->
                                        [ viewBtn [ centerX ] (Just (MakeEditable u.id)) u.name
                                        , viewBtn [ centerX, Font.size 14, Border.rounded 5, padding 5, Background.color (rgb255 240 112 121), mouseOver [ alpha 0.8 ] ] (Just (DeleteUser u.id)) "remove"
                                        , case u.verified of
                                            True ->
                                                el [ centerX, Font.size 14, Border.solid, Border.width 1, Border.rounded 5, padding 5, Font.color color.gray150, Border.color color.gray150 ] (text "approved")

                                            False ->
                                                viewBtn [ centerX, Font.size 14, Border.rounded 5, padding 5, Background.color (rgb255 160 248 180), mouseOver [ alpha 0.8 ] ] (Just (VerifyUser u.id)) "approve"
                                        ]
                        )
                )
            ]
        ]


viewErrorMessage : Maybe ErrorMessage -> Element Msg
viewErrorMessage mbErrorMessage =
    case mbErrorMessage of
        Just errorMessage ->
            row [ width fill, padding 20, Font.center, Font.color color.white, Background.color color.errMsgBg ]
                [ paragraph []
                    [ text <|
                        case errorMessage of
                            UsersFetch ->
                                "Failed to fetch Users."

                            UserCreate ->
                                "Failed to create new User."

                            UserUpdate ->
                                "Failed to update the User."

                            UserDelete ->
                                "Failed to delete the User."

                            UserVerify ->
                                "Failed to verify the User."
                    ]
                , viewBtn [] (Just CloseErrorMessage) "❌"
                ]

        Nothing ->
            none



--FUNCTIONS


chosenUser userId users =
    users
        |> List.filter (\u -> u.id == userId)
        |> List.head
        |> Maybe.withDefault dummyUser



-- DUMMY DATA


dummyFetchedUser : FetchedUser
dummyFetchedUser =
    FetchedUser "" "" False


dummyUser : User
dummyUser =
    User "" "" False False
