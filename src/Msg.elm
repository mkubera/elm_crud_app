module Msg exposing (..)

import Http
import Model exposing (..)


type Msg
    = -- Cmds
      GotUsers (Result Http.Error FetchedUsers)
    | GotCreatedUser (Result Http.Error FetchedUser)
    | GotUpdatedUser (Result Http.Error FetchedUser)
    | GotDeletedUser (Result Http.Error UserId)
    | GotVerifiedUser (Result Http.Error UserId)
      -- Other Msgs
    | AddUser
    | MakeEditable UserId
    | StoreEnteredUsername String
    | CloseEdit UserId
    | UpdateUser UserId
    | DeleteUser UserId
    | VerifyUser UserId
    | CloseErrorMessage
