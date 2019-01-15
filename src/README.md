# DD-DOS source folder structure

| Folder | Description |
|---|---|
| src | Main application |
| src/os | OS utilities and I/O functions |
| src/vcpu | Virtual x86 processor |
| src/vdos | Virtual DOS system, shell, and machine |

```
|------------ DD-DOS ------------|
+------+     +------+     +------+     +-----------+
| vcpu | <=> | vdos | <=> | os.* | <=> | OS (host) |
+------+     +------+     +------+     +-----------+
```