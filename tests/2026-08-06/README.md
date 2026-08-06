# 2026-08-06 evaluation artifacts

本目录保存本轮评估的原始请求、候选文本、评分规程、盲评结果和定向 smoke test。匿名是在评分前完成的；下面的身份映射只用于评分结束后的汇总与复核。

## 全新四项目候选

- `delta-candidate-amber.md`：craft 优化版，第 1 次
- `delta-candidate-cobalt.md`：human-writing v1.1.0
- `delta-candidate-drift.md`：humanizer-chinese
- `delta-candidate-ember.md`：blader/humanizer
- `delta-candidate-birch.md`：craft 优化前基线，第 1 次

## 新旧 craft 重复候选

- 优化版：`amber`、`amber-2`、`amber-3`
- 优化前：`birch`、`birch-2`、`birch-3`

重复盲评中的匿名映射：

| 标签 | 来源 |
|---|---|
| P | amber-2 |
| Q | birch-3 |
| R | birch |
| S | amber-3 |
| T | birch-2 |
| U | amber |

`birch-2` 的 D4 把“4 月”改成“4月”，触发逐字返回 hard fail。`posttrim-smoke.md` 保存优化版中间状态复现同一错误的证据。`verbatim-smoke-*` 与 `postfix-mixed-*` 保存最终字面校验门加入后的 20 个通过样本。

## 主要入口

- `delta-requests.md`：8 个全新任务
- `delta-rubric.md`：评分规程与 hard gate
- `delta-judge-a.md`、`delta-judge-b.md`：四项目首轮盲评
- `repeat-judge-b.md`、`repeat-judge-backup.md`：三次重复盲评
- `regression-judge-a.md`、`regression-judge-b.md`：14 题历史回归
- `verbatim-smoke-requests.md`：最终逐字返回定向测试

分数和解释以 [`docs/EVALUATION-2026-08-06.md`](../../docs/EVALUATION-2026-08-06.md) 为汇总入口。
