# KIMI — Hotfix v21: LookupItem code instead of id

Your project LookupItem model uses `code`, not `id`.
This hotfix updates search_section.dart to use:
- `_selectedGovernorate?.code`
- `_selectedLgu?.code`
