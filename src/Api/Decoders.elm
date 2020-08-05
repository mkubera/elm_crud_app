module Api.Decoders exposing (..)

import Json.Decode exposing (..)
import Model exposing (..)


usersDecoder : Decoder FetchedUsers
usersDecoder =
    list
        userDecoder


userDecoder : Decoder FetchedUser
userDecoder =
    map3 FetchedUser
        (at [ "id" ] string)
        (at [ "name" ] string)
        (at [ "verified" ] bool)


userIdDecoder : Decoder UserId
userIdDecoder =
    string
