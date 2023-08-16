if not util.IsLuaModuleInstalled( "niknaks" ) then
    import( "https://github.com/Nak2/NikNaks" )
end

require( "niknaks" )

-- Libraries
local NikNaks = NikNaks
local string = string
local util = util

-- Variables
local TYPE_NIL = TYPE_NIL
local TYPE_BOOL = TYPE_BOOL
local TYPE_STRING = TYPE_STRING
local TYPE_NUMBER = TYPE_NUMBER
local TYPE_TABLE = TYPE_TABLE
local TYPE_VECTOR = TYPE_VECTOR
local TYPE_ANGLE = TYPE_ANGLE
local TYPE_COLOR = TYPE_COLOR
local TYPE_ENTITY = TYPE_ENTITY
local TYPE_CONVAR = TYPE_CONVAR
local ArgAssert = ArgAssert
local TypeID = TypeID
local error = error
local type = type

local lib = {}
gec = lib

-- Encode
do

    local encoders = {}

    function lib.GetEncoder( valueType )
        return encoders[ valueType ]
    end

    function lib.SetEncoder( valueType, encoder )
        ArgAssert( valueType, 1, "number" )
        ArgAssert( encoder, 2, "function" )
        encoders[ valueType ] = encoder
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

    function lib.GetDecoder( valueType )
        return decoders[ string.char( valueType ) ]
    end

    function lib.SetDecoder( valueType, decoder )
        ArgAssert( valueType, 1, "number" )
        ArgAssert( decoder, 2, "function" )
        decoders[ string.char( valueType ) ] = decoder
    end

    function lib.Decode( encoded, decompress )
        if decompress then
            encoded = util.Decompress( encoded )
        end

        local valueType = string.byte( encoded )
        if not valueType then
            error( "Decoding failed, format of the encoded string is invalid." )
        end

        local decoder = lib.GetDecoder( valueType )
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
    if bool then
        return " "
    end

    return ""
end )

lib.SetDecoder( TYPE_BOOL, function( raw )
    return raw == " "
end )

-- String
lib.SetEncoder( TYPE_STRING, function( str )
    local buffer = NikNaks.BitBuffer()
    buffer:WriteString( str )
    buffer:Seek( 0 )
    return buffer:Read()
end )

lib.SetDecoder( TYPE_STRING, function( raw )
    local buffer = NikNaks.BitBuffer()
    buffer:Write( raw )
    buffer:Seek( 0 )
    return buffer:ReadString()
end )

-- Number
lib.SetEncoder( TYPE_NUMBER, function( number )
    local buffer = NikNaks.BitBuffer()
    buffer:WriteDouble( number )
    buffer:Seek( 0 )
    return buffer:Read()
end )

lib.SetDecoder( TYPE_NUMBER, function( raw )
    local buffer = NikNaks.BitBuffer()
    buffer:Write( raw )
    buffer:Seek( 0 )
    return buffer:ReadDouble()
end )

-- Table
lib.SetEncoder( TYPE_TABLE, function( tbl )
    local buffer = NikNaks.BitBuffer()
    buffer:WriteTable( tbl )
    buffer:Seek( 0 )
    return buffer:Read()
end )

lib.SetDecoder( TYPE_TABLE, function( raw )
    local buffer = NikNaks.BitBuffer()
    buffer:Write( raw )
    buffer:Seek( 0 )
    return buffer:ReadTable()
end )

-- Vector
lib.SetEncoder( TYPE_VECTOR, function( vector )
    local buffer = NikNaks.BitBuffer()
    buffer:WriteVector( vector )
    buffer:Seek( 0 )
    return buffer:Read()
end )

lib.SetDecoder( TYPE_VECTOR, function( raw )
    local buffer = NikNaks.BitBuffer()
    buffer:Write( raw )
    buffer:Seek( 0 )
    return buffer:ReadVector()
end )

-- Angle
lib.SetEncoder( TYPE_ANGLE, function( angle )
    local buffer = NikNaks.BitBuffer()
    buffer:WriteAngle( angle )
    buffer:Seek( 0 )
    return buffer:Read()
end )

lib.SetDecoder( TYPE_ANGLE, function( raw )
    local buffer = NikNaks.BitBuffer()
    buffer:Write( raw )
    buffer:Seek( 0 )
    return buffer:ReadAngle()
end )

-- Color
lib.SetEncoder( TYPE_COLOR, function( color )
    local buffer = NikNaks.BitBuffer()
    buffer:WriteColor( color )
    buffer:Seek( 0 )
    return buffer:Read()
end )

lib.SetDecoder( TYPE_COLOR, function( raw )
    local buffer = NikNaks.BitBuffer()
    buffer:Write( raw )
    buffer:Seek( 0 )
    return buffer:ReadColor()
end )

-- Entity
lib.SetEncoder( TYPE_ENTITY, function( entity )
    local buffer = NikNaks.BitBuffer()
    buffer:WriteType( entity )
    buffer:Seek( 0 )
    return buffer:Read()
end )

lib.SetDecoder( TYPE_ENTITY, function( raw )
    local buffer = NikNaks.BitBuffer()
    buffer:Write( raw )
    buffer:Seek( 0 )
    return buffer:ReadType()
end )

-- ConVar
do

    local GetConVar = GetConVar

    lib.SetEncoder( TYPE_CONVAR, function( conVar )
        local encoder = lib.GetEncoder( TYPE_STRING )
        return encoder( conVar:GetName() )
    end )

    lib.SetDecoder( TYPE_CONVAR, function( raw )
        local decoder = lib.GetDecoder( TYPE_STRING )
        return GetConVar( decoder( raw ) )
    end )

end

-- DamageInfo
do

    local CTakeDamageInfo = FindMetaTable( "CTakeDamageInfo" )

    lib.SetEncoder( TYPE_DAMAGEINFO, function( damageInfo )
        local data = {}
        for key, func in pairs( CTakeDamageInfo ) do
            if not string.StartWith( key, "Get" ) then continue end
            data[ string.sub( key, 4 ) ] = func( damageInfo )
        end

        return lib.Encode( data, false )
    end )

    lib.SetDecoder( TYPE_DAMAGEINFO, function( raw )
        local damageInfo = DamageInfo()
        for key, value in pairs( lib.Decode( raw, false ) ) do
            damageInfo[ "Set" .. key ]( damageInfo, value )
        end

        return damageInfo
    end )

end

return lib