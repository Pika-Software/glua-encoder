-- Libraries
local string = string
local util = util

-- Variables
local table_IsSequential = table.IsSequential
local ArgAssert = ArgAssert
local tostring = tostring
local tonumber = tonumber
local TypeID = TypeID
local ipairs = ipairs
local pairs = pairs
local error = error
local type = type

local lib = {}

-- Encode
do

    local encoders = {}

    function lib.GetEncoder( typeID )
        return encoders[ typeID ]
    end

    function lib.SetEncoder( typeID, encoder )
        ArgAssert( typeID, 1, "number" )
        ArgAssert( encoder, 2, "function" )
        encoders[ typeID ] = encoder
    end

    function lib.Encode( value, compress )
        local valueType = TypeID( value )
        local encoder = lib.GetEncoder( valueType )
        if not encoder then
            error( "Encoding failed, unsupported value type: `" .. type( value ) .. "`" )
        end

        local str = encoder( value )
        if TypeID( str ) ~= TYPE_STRING then
            error( "Encoder error, invalid data type returned, expected string." )
        end

        local encoded = string.char( valueType ) .. str
        if compress then
            return util.Compress( encoded )
        end

        return encoded
    end

end

-- Decode
do

    local decoders = {}

    function lib.GetDecoder( typeID )
        return decoders[ string.char( typeID ) ]
    end

    function lib.SetDecoder( typeID, decoder )
        ArgAssert( typeID, 1, "number" )
        ArgAssert( decoder, 2, "function" )
        decoders[ string.char( typeID ) ] = decoder
    end

    function lib.Decode( encoded, decompress )
        if decompress then
            encoded = util.Decompress( encoded )
        end

        local key = string.byte( encoded, 1, 1 )
        if not key then
            error( "Decoding failed, format of the encoded string is invalid." )
        end

        local decoder = lib.GetDecoder( key )
        if not decoder then
            error( "Decoding failed, unknown type of encoding." )
        end

        return decoder( string.sub( encoded, 2, #encoded ) )
    end

end

-- Nil
lib.SetEncoder( TYPE_NIL, function()
    return ""
end )

lib.SetDecoder( TYPE_NIL, function()
    return nil
end )

-- Boolean
lib.SetEncoder( TYPE_BOOL, function( bool )
    return bool and "1" or ""
end )

lib.SetDecoder( TYPE_BOOL, function( str )
    return str == "1"
end )

-- String
lib.SetEncoder( TYPE_STRING, function( str )
    return str
end )

lib.SetDecoder( TYPE_STRING, function( str )
    return str
end )

-- Number
lib.SetEncoder( TYPE_NUMBER, function( number )
    return tostring( number )
end )

lib.SetDecoder( TYPE_NUMBER, function( str )
    return tonumber( str ) or 0
end )

-- Table
lib.SetEncoder( TYPE_TABLE, function( tbl )
    local isSequential = table_IsSequential( tbl )
    local str = lib.Encode( isSequential ) .. ";"
    if isSequential then
        local lenght = #tbl
        for index, value in ipairs( tbl ) do
            str = str .. lib.Encode( value )
            if index ~= lenght then
                str = str .. ";"
            end
        end
    else
        for key, value in pairs( tbl ) do
            str = str .. lib.Encode( key ) .. ";" .. lib.Encode( value ) .. ";"
        end
    end

    return lib.Encode( str )
end )

lib.SetDecoder( TYPE_TABLE, function( str )
    local result, isSequential = {}, nil

    local data = string.Split( lib.Decode( str ), ";" )
    for index, line in ipairs( data ) do
        if index == 1 then
            isSequential = lib.Decode( line )
            continue
        end

        local previousIndex = index - 1
        if isSequential then
            result[ previousIndex ] = lib.Decode( line )
            continue
        end

        if previousIndex % 2 ~= 0 then
            continue
        end

        result[ lib.Decode( data[ previousIndex ] ) ] = lib.Decode( data[ index ] )
    end

    return result
end )

do

    local Angle = Angle
    local Vector = Vector

    local function encodeVector( vector )
        return lib.Encode( vector[1] ) .. " " .. lib.Encode( vector[2] ) .. " " .. lib.Encode( vector[3] )
    end

    local function decodeVector( str )
        local parts = string.Split( str, " " )
        return lib.Decode( parts[ 1 ] ), lib.Decode( parts[ 2 ] ), lib.Decode( parts[ 3 ] )
    end

    -- Angle
    lib.SetEncoder( TYPE_ANGLE, encodeVector )
    lib.SetDecoder( TYPE_ANGLE, function( str ) return Angle( decodeVector( str ) ) end )

    -- Vector
    lib.SetEncoder( TYPE_VECTOR, encodeVector )
    lib.SetDecoder( TYPE_VECTOR, function( str ) return Vector( decodeVector( str ) ) end )

end

do

    local Color = Color

    -- Color
    lib.SetEncoder( TYPE_COLOR, function( color )
        return lib.Encode( color.r ) .. " " .. lib.Encode( color.g ) .. " " .. lib.Encode( color.b ) .. " " .. lib.Encode( color.a )
    end )

    lib.SetDecoder( TYPE_COLOR, function( str )
        local parts = string.Split( str, " " )
        return Color( lib.Decode( parts[ 1 ] ), lib.Decode( parts[ 2 ] ), lib.Decode( parts[ 3 ] ), lib.Decode( parts[ 4 ] ) )
    end )

end

do

    local IsValid = IsValid
    local Entity = Entity

    -- Entity
    lib.SetEncoder( TYPE_ENTITY, function( ent )
        if IsValid( ent ) or ent:IsWorld() then
            return lib.Encode( ent:EntIndex() )
        end

        return ""
    end )

    lib.SetDecoder( TYPE_ENTITY, function( str )
        if #str == 0 then return NULL end
        return Entity( lib.Decode( str ) )
    end )

end

do

    local GetConVar = GetConVar

    -- ConVar
    lib.SetEncoder( TYPE_CONVAR, function( conVar )
        return conVar:GetName()
    end )

    lib.SetDecoder( TYPE_CONVAR, function( str )
        return GetConVar( str )
    end )

end

return lib