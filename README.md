# gdscript function type auto-completion

this is a simple godot 4 plugin that helps you write functions faster by auto-completing return types and adding default return values. just write your function and hit tab.

check out [how to use it here](https://youtu.be/iefqy_YVMIM).

## what does it do?

when you hit tab after writing a function, it:
- adds the return type for you (-> void if you don't specify one)
- puts in default return value
- keeps your parameters and types intact
- works with partial or complete function declarations

## default return values

here's what you get based on the return type:

```gdscript
# void functions get 'pass'
func do_something() -> void:
    pass

# bools get 'false'
func is_something() -> bool:
    return false

# numbers get zeros
func count_stuff() -> int:
    return 0
func get_speed() -> float:
    return 0.0

# strings get empty quotes
func get_name() -> String:
    return ""

# arrays and dictionaries start empty
func get_items() -> Array:
    return []
func get_data() -> Dictionary:
    return {}

# objects get null
func get_node() -> Node:
    return null
```

## how it handles different ways of writing functions

```gdscript
# works with complete functions
func do_math(value: int) -> int:
    return 0

# works with incomplete ones
func not_done(value: int
->
func not_done(value: int) -> void:
    pass

# works with arrows
func arrows_are_cool() ->
->
func arrows_are_cool() -> void:
    pass

# works without arrows
func give_string String
->
func give_string() -> String:
    return ""

# keeps your parameters safe
func move_stuff(pos: vector2, speed: float
->
func move_stuff(pos: vector2, speed: float) -> void:
    pass
```

## need help?
if something's not working, file an issue and provide the following:
- what's going wrong
- what version of godot you're using
- what operating system you're on
