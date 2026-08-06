# craft-chinese-writing

面向中文非虚构写作的 Codex Skill。它用于诊断、起草、重构、改写与编辑文章、报告、知识页、技术说明、演讲、公共表达和其他需要兼顾事实、推理、读者效用、文体与作者声音的作品。

本仓库把可运行 Skill 与项目材料分开：`skill/` 是唯一运行源码；评估、版本说明和测试保存在仓库外围，不进入 Skill 的运行上下文。

## 当前版本

`v1.0.0` 是首个归档版本。它形成于对以下三个项目及中国古代文章学、文论传统的比较吸收之后，但早于 `human-writing v1.1.0` 的最新一轮语义诊断增量：

- [KKKKhazix/human-writing](https://github.com/KKKKhazix/human-writing)
- [jiji262/humanizer-chinese](https://github.com/jiji262/humanizer-chinese)
- [blader/humanizer](https://github.com/blader/humanizer)

项目吸收可迁移的原则与方法，不把第三方项目的禁词表、固定阈值或风格偏好机械合并为一套规则。

## 仓库结构

```text
skill/       可直接被 Codex 发现和使用的唯一 Skill 源码
docs/        版本说明、评估报告与设计判断
tests/       测试请求、评分规程和可复核结果
```

`skill/` 内只保留运行所需的 `SKILL.md`、`agents/` 与 `references/`。README、版本记录和测试不放入运行包。

## 使用

把 `skill/` 目录安装或链接到 Codex 的 Skill 发现目录，并保持目录名为 `craft-chinese-writing`。推荐使用目录联接或符号链接，使仓库中的 `skill/` 始终是唯一正本。

## 版本历史

- `v1.0.0`：优化前基线版本，作为后续比较与回退锚点。

详细内容见 [v1.0.0 版本说明](docs/VERSION-1.0.0.md)。

## 权利与第三方项目

本仓库尚未声明面向公众的项目许可证。第三方项目的权利归各自作者，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 及其原始仓库许可证。

