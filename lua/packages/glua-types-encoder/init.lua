local util = util

module( "gte", package.seeall )

-- Encode
do

    local encoders = {}

    function GetEncoder( typeID )
        return encoders[ typeID ]
    end

    function SetEncoder( typeID, encoder )
        ArgAssert( typeID, 1, "number" )
        ArgAssert( encoder, 2, "function" )
        encoders[ typeID ] = encoder
    end

    function Encode( value, compress )
        local valueType = TypeID( value )
        local encoder = GetEncoder( valueType )
        if not encoder then
            error( "Encoding failed, unsupported value type: `" .. type( value ) .. "`" )
        end

        local str, key = encoder( value )
        if TypeID( str ) ~= TYPE_STRING then
            error( "Encoder error, invalid data type returned, expected string." )
        end

        if TypeID( key ) ~= TYPE_STRING then
            key = tostring( valueType )
        end

        local encoded = key .. ";" .. str .. ";"
        if compress then
            return util.Compress( encoded )
        end

        return encoded
    end

end

-- Decode
do

    local decoders = {}

    function GetDecoder( key )
        return decoders[ key ]
    end

    function SetDecoder( key, decoder )
        ArgAssert( key, 1, "string" )
        ArgAssert( decoder, 2, "function" )
        decoders[ key ] = decoder
    end

    function Decode( encoded, decompress )
        if decompress then
            encoded = util.Decompress( encoded )
        end

        local key, str = string.match( encoded, "^([^;]+);(.+);$" )
        if not key then
            error( "Decoding failed, format of the encoded string is invalid." )
        end

        local decoder = GetDecoder( key )
        if not decoder then
            error( "Decoding failed, unknown type of encoding." )
        end

        return decoder( str )
    end

end

-- Boolean
SetEncoder( TYPE_BOOL, function( bool )
    return bool and "1" or "0"
end )

SetDecoder( "b", function( str )
    return str == "1"
end )

-- String
SetEncoder( TYPE_STRING, function( str )
    return str, "s"
end )

SetDecoder( "s", function( str )
    return str
end )

-- Number
SetEncoder( TYPE_NUMBER, function( number )
    return GetEncoder( TYPE_STRING )( tostring( number ) ), "n"
end )

SetDecoder( "n", function( str )
    return tonumber( GetDecoder( "s" )( str ) ) or 0
end )

-- Table
SetEncoder( TYPE_TABLE, function( tbl )
    return util.TableToJSON( tbl ), "t"
end )

SetDecoder( "t", function( str )
    return util.JSONToTable( str )
end )

-- Vector
SetEncoder( TYPE_VECTOR, function( vector )
    local encoder = GetEncoder( TYPE_NUMBER )
    return encoder( vector[1] ) .. "," .. encoder( vector[2] ) .. "," .. encoder( vector[3] ), "V"
end )

SetDecoder( "V", function( str )
    local parts, decoder = string.Split( str, "," ), GetDecoder( "n" )
    return Vector( decoder( parts[ 1 ] ), decoder( parts[ 2 ] ), decoder( parts[ 3 ] ) )
end )

-- Angle
SetEncoder( TYPE_ANGLE, function( angle )
    return GetEncoder( TYPE_VECTOR )( angle ), "A"
end )

SetDecoder( "A", function( str )
    local parts, decoder = string.Split( str, "," ), GetDecoder( "n" )
    return Angle( decoder( parts[ 1 ] ), decoder( parts[ 2 ] ), decoder( parts[ 3 ] ) )
end )

-- Entity
SetEncoder( TYPE_ENTITY, function( ent )
    if IsValid( ent ) then
        if ent:IsPlayer() and not ent:IsBot() then
            return GetEncoder( TYPE_STRING )( ent:SteamID64() ), "P"
        end

        return GetEncoder( TYPE_NUMBER )( ent:EntIndex() ), "E"
    end

    return GetEncoder( TYPE_NUMBER )( -1 ), "E"
end )

SetDecoder( "E", function( str )
    local index = GetDecoder( "n" )( str )
    if index < 0 then return NULL end

    return Entity( index )
end )

-- Player
SetDecoder( "P", function( str )
    return player.GetBySteamID64( GetDecoder( "s" )( str ) )
end )

-- local encoded = Encode( "TEXT", true )
-- print( encoded )

-- local decoded = Decode( encoded, true )
-- print( decoded )
