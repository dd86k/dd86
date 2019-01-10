# DD-DOS source folder structure

| Folder | Description |
|---|---|
| src | Main application |
| src/os | Groups OS utilities and I/O functions |
| src/vcpu | Virtual x86 processor |
| src/vdos | Virtual DOS system, shell, and machine |

# Modules

| Module | Description |
|---|---|
| main | Starting point, initializations, CLI options |
| logger | Logging suite |
| ddc | C functions compability module |
| appconfig | Compile settings |
| os.io | File tools and other I/O |
| os.sleep | Thread sleeping utilities |
| os.term | Console/terminal library |
| os.timer | OS timers |
| vcpu.core | x86 core emulation module |
| vcpu.cpuid | CPUID instruction |
| vcpu.mm | Memory manager (i.e. protected mode) |
| vcpu.utils | ModR/M and SIB bytes management |
| vcpu.v16 | Real-mode instructions |
| vcpu.v32 | (80386+) Protected-mode instructions |
| vdos.codes | Error codes |
| vdos.interrupts | Interrupt handling (between vcpu and os) |
| vdos.loader | COM and EXE file loader |
| vdos.os | Virtual DOS operating system |
| vdos.screen | Virtual video adapter, prints directly on screen |
| vdos.shell | Virtual shell, includes internal commands |
| vdos.structs | System and DOS structures |