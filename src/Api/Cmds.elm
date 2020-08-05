module Api.Cmds exposing (..)

import Api.Decoders exposing (..)
import Api.Encoders exposing (..)
import Http
import Model exposing (..)
import Msg exposing (..)


getUsers : Cmd Msg
getUsers =
    Http.get
        { url = "/api/users"
        , expect = Http.expectJson GotUsers usersDecoder
        }


postNewUser : Cmd Msg
postNewUser =
    Http.post
        { url = "/api/users/create"
        , body = Http.jsonBody newUserEncoder
        , expect = Http.expectJson GotCreatedUser userDecoder
        }


putEditedUser : FetchedUser -> Cmd Msg
putEditedUser user =
    Http.request
        { method = "PUT"
        , headers = []
        , url = "/api/users/" ++ user.id ++ "/update"
        , body = Http.jsonBody (editedUserEncoder user)
        , expect = Http.expectJson GotUpdatedUser userDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


deleteUser : UserId -> Cmd Msg
deleteUser userId =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "/api/users/" ++ userId ++ "/delete"
        , body = Http.emptyBody
        , expect = Http.expectJson GotDeletedUser userIdDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


verifyUser : UserId -> Cmd Msg
verifyUser userId =
    Http.get
        { url = "/api/users/" ++ userId ++ "/verify"
        , expect = Http.expectJson GotVerifiedUser userIdDecoder
        }
