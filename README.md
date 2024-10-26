
# Function Type Auto-Complete

This tool enables auto-completion of functions.

If you don't input anything after parenthesis, it will automatically append -> void: and a pass statement after you ***press tab***.

If you put a type after the parentheses, it will complete with that type instead.

## Examples

```func new()```
<br>
turns into
<br>
```
func new() -> void:
    pass
```
<br>


```func new() String```
<br>
turns into
<br>
```
func new() -> String:
    pass
```
<br>