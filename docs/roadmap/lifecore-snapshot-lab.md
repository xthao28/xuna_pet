# LifeCore snapshot lab

Status: Implemented as an in-memory host experiment; not a storage-layout
decision and not an NVS/LittleFS implementation.

`LifeCoreSnapshotLab` exercises the existing 96-byte `LifeEngine` codec with
two A/B slots. It can boot/recover, commit a generation, simulate a cut before
commit, and corrupt a slot to verify fallback to the other valid generation.
The v2 learner is intentionally reset on boot because it is still a shadow
candidate and has no approved persistence format.

This gives S19a a deterministic reboot/power-cut fixture without touching the
owner's board or changing BLE v1 bytes.
