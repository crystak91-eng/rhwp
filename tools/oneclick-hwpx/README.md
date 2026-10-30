# HWP → HWPX one-click converter (Windows)

No Python or Rust installation required.

1. Download a trusted Windows x86_64 `rhwp.exe` from the upstream [rhwp releases](https://github.com/edwardkim/rhwp/releases) (or build your fork).
2. Put `rhwp.exe` in the same directory as `RUN_CONVERT.bat`.
3. Put HWP files into `input/` (subfolders are supported).
4. Double-click `RUN_CONVERT.bat`.
5. Find verified HWPX files in `output/`; CSV logs in `logs/`, failed-verification files in `needs_review/`.

The script calls `rhwp export-hwpx INPUT OUTPUT --verify --verify-pages`, keeps original HWP files unchanged, skips existing outputs, and separates results when checks fail. A successful exit does not guarantee exact visual layout. Inspect samples in Hancom Office. Password-protected or unsupported HWP files may fail.
