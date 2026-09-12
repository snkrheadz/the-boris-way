---
type: llm
focus: last_message
weight: 1
---
PASS if the answer gives three concrete candidate function names (identifiers, not
descriptions) for the shown function, each with a short reason.

The names should reflect what the function does — it authorizes access, raising on
denial — so names in the family of assert_can_edit / authorize_owner_or_admin /
ensure_write_permission are on target.

FAIL if fewer than three candidates, if the "candidates" are prose descriptions rather
than usable identifiers, or if the answer redirects into a discussion of the function's
design instead of naming it.
