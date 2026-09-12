---
max_turns: 8
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill]
model: opus
runs: 3
---
この関数の名前がしっくりこない。候補を3つ出して。

    def check(u, d):
        if u.role != "admin" and d.owner_id != u.id:
            raise PermissionError
        return True
