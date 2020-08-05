module Api.Encoders exposing (..)

import Json.Encode exposing (..)
import Model exposing (..)


newUserEncoder : Value
newUserEncoder =
    object
        [ ( "name", string "" )
        , ( "verified", bool False )
        ]


editedUserEncoder : FetchedUser -> Value
editedUserEncoder user =
    object
        [ ( "name", string user.name )
        ]
