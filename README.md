# DD-DOS, A Small DOS Virtual Machine

DD-DOS aims to be a simple compatibility layer between the host OS and an emulated world for DOS applications, just like NTDVM, but for all systems.

## Structure

| Folder | Build type | Description |
|---|---|---|
| src | executable | Main source |
| tests | unittest | Unit testing |
| bench | bench | Benchmarks |

## Building

Use `dub build`.

## Testing

Use `dub test`.

## Benchmarking

Use `dub test -b bench`.

Currently, only the utility functions are benchmarked.