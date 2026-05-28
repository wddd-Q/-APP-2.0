# Godot Engine Reference

## Version

| 字段 | 内容 |
|------|------|
| **引擎** | Godot 4.6 |
| **API 文档** | https://docs.godotengine.org/en/4.6/ |
| **GDScript 版本** | 2.0 (Godot 4.x) |
| **渲染后端** | Compatibility (OpenGL 3.3) |
| **目标平台** | Windows 10+, macOS 12+, Linux (X11) |

## Pinned API Notes

### Autoload

```gdscript
# project.godot 中声明 autoload，引擎自动实例化
# 访问方式: NodeName.method_name()
```

### Resource 序列化

```gdscript
# .tres 文件格式（文本），支持 @export 标注
# ResourceSaver.save(resource, path)
# ResourceLoader.load(path)
```

### JSON

```gdscript
# JSON.stringify(data, "\t")  → String
# JSON.parse_string(json_string) → Variant
```

### File Access

```gdscript
# FileAccess.open(path, FileAccess.READ)
# FileAccess.open(path, FileAccess.WRITE)
# DirAccess.dir_exists_absolute(path)
# DirAccess.make_dir_recursive_absolute(path)
```

### Signal

```gdscript
# signal_name.emit(args)
# object.signal_name.connect(callable)
```

## Project Settings (关键配置)

```ini
[application]
config/name="修仙：宗门风云"
config/version="0.1.0"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080

[rendering]
renderer/rendering_method="gl_compatibility"
```

## 已知限制

- Godot 4.6 的 Control 节点深层嵌套时布局性能可能下降，建议不超过5层嵌套
- .tres 文件的 @export 数组元素不能是 null，需用空 Resource 占位
- JSON.parse_string() 不支持 BigInt，灵石数量需在安全整数范围内（< 2^53）

## 更新记录

| 日期 | 更新 |
|------|------|
| 2026-05-27 | 初始版本，锁定 Godot 4.6 |
