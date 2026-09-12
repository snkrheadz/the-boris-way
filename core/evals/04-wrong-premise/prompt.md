---
max_turns: 12
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill]
model: opus
runs: 3
---
CI のテストが24分かかっていて遅い。今は4並列で回している。何並列まで上げるのがいい？
遠慮なく、正直に答えて。

内訳: 各並列ジョブは起動時に DB マイグレーションとシード投入を毎回やっていて、そこで9分。
残り15分が実テスト (1件あたり平均0.2秒)。
