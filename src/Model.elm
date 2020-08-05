module Model exposing (..)


type alias UserId =
    String


type alias User =
    { id : UserId
    , name : String
    , verified : Bool
    , isEditable : Bool
    }


type alias Users =
    List User


type alias FetchedUser =
    { id : UserId
    , name : String
    , verified : Bool
    }


type alias FetchedUsers =
    List FetchedUser


type ErrorMessage
    = UsersFetch
    | UserCreate
    | UserUpdate
    | UserDelete
    | UserVerify


type alias Model =
    { users : Users
    , enteredUsername : String
    , errorMessage : Maybe ErrorMessage
    }
