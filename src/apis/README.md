# APIs directory

Here we store all the methods used to:
* Manipulate data stored in board, game, or players
* Helper methods to do read-only operations on these three structs (these are preferred to raw access to fields of board, game, or players.)

## Notation 

Each action that modifies data to the object has two functions:
    * `function _action_to_apply`
    * `function action_to_apply`

where they are related by this schema:
```
function action_to_apply(...)
    log_action("[API name] [args...]")
    _action_to_apply(...)
end
```

so the under-score version is only meant to be used in `API_DICTIONARY`, as this is used to parse a game save file, where the `log_action` has serialized the function call.
Within the code, typically in `./src/main.jl`, the full version `action_to_apply` is used, so that wherever this function is called, that call gets serialized and recorded in the game save file.
