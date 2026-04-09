## ClashFX 1.0.9

### Bug Fixes

- **Fix remote config validation rejecting configs that use proxy-providers** — Configs referencing proxy-groups supplied by `proxy-providers` were rejected during import with errors like "proxy group: '…' not found", because the pre-validation performed full semantic checks before providers were fetched. Switched remote config verification to lightweight YAML-only validation; full validation still occurs when the config is loaded by the core. Fixes #12

---

### Bug 修复

- **修复导入使用 proxy-providers 的远程配置时报格式错误** — 当配置中的 proxy-group 引用了由 `proxy-providers` 提供的节点或组时，导入时会因 "proxy group: '…' not found" 而被拒绝，原因是预校验在 provider 尚未拉取时就执行了完整的语义检查。已将远程配置预校验改为仅验证 YAML 语法；完整校验仍在内核加载配置时执行。修复 #12
