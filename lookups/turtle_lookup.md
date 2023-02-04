# turtle_lookup

This script only requires `turtle`. It provides 2 lookup constructors for making lookup table with its own internal state lookup. This enables the functions to behave differently depending on the modes it is in.

## Simple Lookup

From a constructor function `create_simple_lookup`, this lookup is an example of how to create a lookup with its own state lookup.

### How to use

`fbudlr`: These instructions will make the turtle to go `forward`, `back`, `up`, `down`, `turnLeft`, and `turnRight` respectively.

The default state of the lookup is `normal`, thus above instructions are a normal move functions.

`DAPRS`: These instruction switches the state to `dig`, `attack`, `place`, `drop`, and `suck` respectively. So, if an instruction is written as `Du`, the state will switch to `dig` and the turtle will `digUp`. After the first move instruction `u`, the next instructions will be switched back to `normal` state.

It can also select an inventory. Usually it goes like this:
1. `x` resets the number inside the lookup to 0.
2. `i` increments the number by 1. `3i` will set the number to 3.
3. `s` select the turtle slot by the number. E.g `3`.

For complete example, `x3is` select slot 3, `x12is` select slot 12.

Examples:
- `ud Duu`: up, down, digUp, up
- `ADuu`: digUp, up (2 consecutive state change, the last overrides the rest.)
- `DuSu`: digUp, suckUp
- `3(fSub)`: 3 times (forward, suckUp, back)
- `4(fl)`: 4 times (forward, turnLeft) (turtle spin)

## General Purpose Lookup

From a constructor function `create_lookup`, this lookup is meant to be used more as a general purpose one. It contains more sophisticated internal state management with its own stack machine.

### How to use

There are several state that are being used to switch between internal function. The default state is `normal` state.

In the `normal` state, these instructions are available:
- `.`: Do nothing, because it's already in normal state.
- `m`: Change state to `move`.
- `a`: Change state to `arithmetic`.
- `i`: Change state to `inventory`.

In the `move` state, these instructions are available:
- `.`: Change state to `normal`.
- `fbudlr`: Similarly to the simple lookup, moves the turtle `forward`, `back`, `up`, `down`, `turnLeft`, and `turnRight` respectively.
- `DAPRSVW`: Similarly to the simple lookup, switches the move state (not to be confused with the general state) to `dig`, `attack`, `place`, `drop`, `suck`, `drop_amount`, and `suck_amount` respectively. the state with `_amount` prefix consumes 1 value from the stack as its argument.

In the `arithmetic` state, these instructions are available:
- `.`: Change state to `normal`.
- `r`: Resets the currently operating number to 0.
- `i`: Increments the number by 1.
- `_`: Multiplies the number by 10.
- `p`: Pushes the number to the stack.
- `d`: Pops the number from the stack.
- `e`: Peeks the number on the top of the stack.
- `c`: Prints the length of the stack.

In the `inventory` state, these instructions are available:
- `.`: Change state to `normal`.
- `s`: Selects the turtle inventory slot by consuming 1 value from the stack.
- `c`: Craft in the turtle inventory.
- `C`: Craft in the turtle inventory by consuming 1 value from the stack as the amount.
- `f`: Refuel the turtle from the selected slot.
- `F`: Refuel the turtle from the selected slot by consuming 1 value from the stack as the amount.
- `t`: Transfer items from the selected slot to the destination slot.
  The destination slot is specified by consuming 1 value from the stack.
- `T`: Transfer items from the selected slot to the destination slot by a certain amount.
  The destination slot is specified by consuming 1 value from the stack.
  The amount is specified by consuming 1 value from the stack.
  The top stack is comsumed for the amount, then the second top stack is used for the destination amount.

Example:
```lua
[=[
    .a r3ip       [[ Pushes 3 to the stack                           ]]
    .i s f        [[ Calls select(3) and refuel()                    ]]
    .a r3ip r6ip  [[ Pushes 3 and 6 to the stack                     ]]
    .i T          [[ Calls transferTo (6, 3)                         ]]
    .a c          [[ Prints the stack count                          ]]
    .a r2i_4ip ed [[ Pushes 24 to the stack, prints the top, and pop ]]
    .m 2(ud) 4l4r [[ Moves up and down, 2 times,                     ]]
                  [[   then 4 times left and 4 times right           ]]
]=]
```