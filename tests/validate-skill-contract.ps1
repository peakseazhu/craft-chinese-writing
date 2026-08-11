[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$errors = [System.Collections.Generic.List[string]]::new()
$officialValidatorRan = $false

function Add-ContractError {
    param([string]$Message)
    $errors.Add($Message)
}

function Read-RepoText {
    param([string]$RelativePath)
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-ContractError "缺少文件：$RelativePath"
        return $null
    }
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Invoke-OfficialSkillValidator {
    $validatorCandidates = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $validatorCandidates.Add((Join-Path $env:CODEX_HOME 'skills\.system\skill-creator\scripts\quick_validate.py'))
    }
    $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
        $validatorCandidates.Add((Join-Path $userProfile '.codex\skills\.system\skill-creator\scripts\quick_validate.py'))
    }

    $validatorPath = $validatorCandidates |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
    if ($null -eq $validatorPath) {
        Write-Warning '未发现当前Codex Skill Creator的quick_validate.py；已跳过官方结构校验，只运行仓库合同检查。'
        return
    }

    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $pythonCommand) {
        Add-ContractError '已发现quick_validate.py，但PATH中没有可用的python。'
        return
    }

    $previousPythonUtf8 = [Environment]::GetEnvironmentVariable('PYTHONUTF8', 'Process')
    try {
        [Environment]::SetEnvironmentVariable('PYTHONUTF8', '1', 'Process')
        $validatorOutput = & $pythonCommand.Source $validatorPath (Join-Path $repoRoot 'skill') 2>&1
        $script:officialValidatorRan = $true
        if ($LASTEXITCODE -ne 0) {
            Add-ContractError "官方Skill结构校验失败：$($validatorOutput -join ' ')"
        }
    } finally {
        [Environment]::SetEnvironmentVariable('PYTHONUTF8', $previousPythonUtf8, 'Process')
    }
}

Invoke-OfficialSkillValidator

$versionText = Read-RepoText 'VERSION'
if ($null -eq $versionText) {
    $version = ''
} else {
    $version = $versionText.Trim()
}
$readme = Read-RepoText 'README.md'
$skill = Read-RepoText 'skill\SKILL.md'
$openAiYaml = Read-RepoText 'skill\agents\openai.yaml'
$foundations = Read-RepoText 'skill\references\foundations.md'
$realityWriting = Read-RepoText 'skill\references\reality-writing.md'

if ($version -notmatch '^\d+\.\d+\.\d+$') {
    Add-ContractError "VERSION不是语义化版本：$version"
}
if ($null -ne $readme -and -not $readme.Contains("v$version")) {
    Add-ContractError "README没有声明当前版本v$version。"
}
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "docs\VERSION-$version.md") -PathType Leaf)) {
    Add-ContractError "缺少docs/VERSION-$version.md。"
}

if ($null -ne $skill) {
    if ($skill -notmatch '(?m)^name:\s*craft-chinese-writing\s*$') {
        Add-ContractError 'SKILL.md的name不正确。'
    }
    $descriptionMatch = [regex]::Match($skill, '(?m)^description:\s*(?<description>.+)$')
    if (-not $descriptionMatch.Success) {
        Add-ContractError 'SKILL.md缺少description。'
    } else {
        $description = $descriptionMatch.Groups['description'].Value
        $crystallizePosition = $description.IndexOf('Crystallize', [System.StringComparison]::OrdinalIgnoreCase)
        $diagnosePosition = $description.IndexOf('Diagnose', [System.StringComparison]::OrdinalIgnoreCase)
        if ($crystallizePosition -lt 0 -or ($diagnosePosition -ge 0 -and $crystallizePosition -gt $diagnosePosition)) {
            Add-ContractError 'description没有把结晶触发放在通用改稿触发之前。'
        }
        foreach ($requiredPhrase in @('current model', 'first-principles', 'Do not use')) {
            if ($description -notmatch [regex]::Escape($requiredPhrase)) {
                Add-ContractError "description缺少边界短语：$requiredPhrase"
            }
        }
    }
    foreach ($requiredSection in @('## Hold the quality hierarchy', '## Route the task', 'Before promoting a source-derived idea')) {
        if (-not $skill.Contains($requiredSection)) {
            Add-ContractError "SKILL.md缺少关键合同：$requiredSection"
        }
    }
    if ($skill -notmatch 'another general Chinese writing skill') {
        Add-ContractError 'SKILL.md缺少通用中文写作Skill的分流规则。'
    }
    if ($skill -notmatch 'pass an external-evidence gate before committing to an outline or solution') {
        Add-ContractError 'SKILL.md没有把外部知识候选与实际检索拆成两级路由。'
    }
    foreach ($gatePhrase in @('time-sensitive, unfamiliar, disputed, high-impact', 'contains open-world load-bearing claims', 'Do not run discovery for closed-source work', 'stable low-risk knowledge and simple direct work normally take this path', 'Stable model knowledge may generate candidates', 'start with one pass over the minimum source families needed', 'A single authoritative source may be sufficient')) {
        if ($skill -notmatch [regex]::Escape($gatePhrase)) {
            Add-ContractError "SKILL.md的外部证据门缺少路由边界：$gatePhrase"
        }
    }
}

if ($null -ne $openAiYaml) {
    if (-not $openAiYaml.Contains('$craft-chinese-writing')) {
        Add-ContractError 'openai.yaml的default_prompt没有显式调用$craft-chinese-writing。'
    }
    if ($openAiYaml -notmatch '高熵|结晶|当前认识|当前模型') {
        Add-ContractError 'openai.yaml没有把高熵材料结晶作为可见入口。'
    }
    if ($openAiYaml -notmatch '来源模式' -or $openAiYaml -notmatch '开放世界|混合') {
        Add-ContractError 'openai.yaml没有保留封闭／开放／混合来源的研究边界。'
    }
    if ($openAiYaml -notmatch '先过外部证据门' -or $openAiYaml -notmatch '只在承重主张需要时') {
        Add-ContractError 'openai.yaml没有表达先过证据门、按承重主张自适应发现的默认入口。'
    }
}

if ($null -ne $foundations) {
    if ($foundations -notmatch '外部已有知识应进入候选空间.*不等于.*每次都调用检索工具') {
        Add-ContractError 'foundations没有区分外部知识候选与实际检索。'
    }
    if ($foundations -notmatch '优先发现也不等于优先相信、照搬或长期保存') {
        Add-ContractError 'foundations没有区分外部知识的发现、采信、迁移与保存。'
    }
}

if ($null -ne $realityWriting) {
    if ($realityWriting -notmatch '不要在本页另建一套触发逻辑') {
        Add-ContractError 'reality-writing重复定义检索触发，可能与SKILL.md漂移。'
    }
    if ($realityWriting -notmatch '来源边界封闭时不检索' -or $realityWriting -notmatch '其余任务仍按主门的触发与轻路径判断') {
        Add-ContractError 'reality-writing没有服从SKILL.md对封闭来源与轻路径的单一触发逻辑。'
    }
}

foreach ($regressionFile in @(
    'tests\2026-08-10\abstraction-scope-requests.md',
    'tests\2026-08-10\abstraction-scope-rubric.md',
    'tests\2026-08-10\skill-routing-requests.md',
    'tests\2026-08-10\skill-routing-rubric.md',
    'tests\2026-08-11\external-prior-requests.md',
    'tests\2026-08-11\external-prior-rubric.md'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $regressionFile) -PathType Leaf)) {
        Add-ContractError "缺少回归材料：$regressionFile"
    }
}

$externalRequests = Read-RepoText 'tests\2026-08-11\external-prior-requests.md'
$externalRubric = Read-RepoText 'tests\2026-08-11\external-prior-rubric.md'
if ($null -ne $externalRequests) {
    foreach ($requiredCase in @('稳定低风险解释不触发研究', '持久规则与重复决策需要外部证据', '先恢复判据，不能被首个框架锚定', '持久但封闭的本地事实不触发研究', '狭窄当前事实不机械扩张来源')) {
        if ($externalRequests -notmatch [regex]::Escape($requiredCase)) {
            Add-ContractError "外部证据门回归缺少代表性路径：$requiredCase"
        }
    }
}
if ($null -ne $externalRubric -and ($externalRubric -notmatch '输入与输出Token' -or $externalRubric -notmatch '仅凭总耗时不能归因于规则')) {
    Add-ContractError '外部证据门回归没有区分质量、工具调用、Token、总耗时与冷启动干扰。'
}

if ($errors.Count -gt 0) {
    Write-Host "FAIL: Skill合同检查发现 $($errors.Count) 个问题。"
    foreach ($contractError in $errors) {
        Write-Host "- $contractError"
    }
    exit 1
}

Write-Host 'PASS: Skill版本、发现描述、运行元数据与分流回归材料一致。'
if ($officialValidatorRan) {
    Write-Host 'PASS: 当前Codex Skill Creator官方结构校验在显式UTF-8环境中通过。'
}
Write-Host '说明：该结果不替代真实写作请求的语义评审。'
