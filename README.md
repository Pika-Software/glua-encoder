# glua-encoder

## Functions list
- encoder.Decode( `string` str, `bool` decompress )
- encoder.Encode( `any` value, `bool` compress )
- encoder.GetDecoder( `number` typeID )
- encoder.SetDecoder( `number` typeID, `function` decodeFunc )
- encoder.GetEncoder( `number` typeID )
- encoder.SetEncoder( `number` typeID, `function` compressFunc )

### Example
```lua
  local encoder = install( "packages/glua-encoder", "https://github.com/Pika-Software/glua-encoder" )

  local encoded = encoder.Encode( "foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoo", true )
  local decoded = encoder.Decode( encoded, true )
  print( decoded )

```

## Supported types
- TYPE_NIL
- TYPE_BOOL
- TYPE_STRING
- TYPE_NUMBER
- TYPE_TABLE `( does not support table links )`
- TYPE_ANGLE
- TYPE_VECTOR
- TYPE_COLOR
- TYPE_ENTITY
- TYPE_CONVAR
