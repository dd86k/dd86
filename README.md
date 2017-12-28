# DD-DOS, A Small DOS Virtual Machine

```
_______ _______        _______  ______  _______
|  __  \|  __  \  ___  |  __  \/  __  \/ _____/
| |  \ || |  \ | |___| | |  \ || /  \ |\____ \
| |__/ || |__/ |       | |__/ || \__/ |_____\ \
|______/|______/       |______/\______/\______/
```

DD-DOS aims to be a simple compatibility layer, like NTVDM.

There is a reference manual available over the Wiki.

## Folder structure

| Folder | Build type | Description |
|---|---|---|
| src | executable | Main source |
| tests | unittest | Unit testing |
| bench | bench | Benchmarks |

## Source structure

| File | Description |
|---|---|
| dd-dos.d | OS emulation, interrupts, and internal shell |
| Interpreter.d | Intel 8086/80486 emulator |
| InterpreterUtils.d | Helper functions for the emulator |
| Loader.d | Executable/file loader for dd-dos |
| main.d | Command Line Interface |
| ddcon.d | In-house console/terminal library |
| Utilities.d | Generic utilities |

## Building

Use `dub build` for the default settings, enough for debugging.

For a release build : `dub build -b release`

## Testing

Use `dub test`.

## Benchmarking

Use `dub test -b bench`.

Currently, only the utility functions are benchmarked.

# Credits

Original author -- dd86k