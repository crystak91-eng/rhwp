# Hancom 2018 compatibility conversion

Put a trusted Windows rhwp.exe alongside RUN_CONVERT.bat, put HWP files into input, double-click RUN_CONVERT.bat. PowerShell converts with `export-hwpx --verify --verify-pages`, then changes only `faceColor="none"` and `shadeColor="none"` in `Contents/header.xml` to `#FFFFFFFF`. Original files are preserved. Test on a few documents before bulk use; appearance is not universally guaranteed.

For a folder-picker desktop interface, use the separate Windows Forms GUI ZIP supplied in the conversation. This repository branch currently contains the batch variant, not the GUI bundle or compiled executable.
