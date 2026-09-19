param(
    [string]$OutputDirectory = "dist"
)

$ErrorActionPreference = "Stop"
$appDirectory = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $appDirectory "pubspec.yaml"
$versionLine = Select-String -Path $pubspecPath -Pattern '^version:\s*([^\s]+)' | Select-Object -First 1

if ($null -eq $versionLine) {
    throw "Could not read the app version from pubspec.yaml."
}

$version = $versionLine.Matches[0].Groups[1].Value
$resolvedOutputDirectory = [System.IO.Path]::GetFullPath((Join-Path $appDirectory $OutputDirectory))
$allowedOutputPrefix = [System.IO.Path]::GetFullPath($appDirectory) + [System.IO.Path]::DirectorySeparatorChar
if (-not $resolvedOutputDirectory.StartsWith($allowedOutputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputDirectory must be inside the app directory."
}
$archivePath = Join-Path $resolvedOutputDirectory "sikhi-word-games-web-$version.zip"

Push-Location $appDirectory
try {
    dart run tool\build_release_content.dart --check
    if ($LASTEXITCODE -ne 0) {
        throw "Release content is stale or could not be verified."
    }
    dart run tool\audit_release_content.dart
    if ($LASTEXITCODE -ne 0) {
        throw "Release content failed its distribution audit."
    }
    flutter build web --release --no-web-resources-cdn --pwa-strategy=none --suppress-analytics
    if ($LASTEXITCODE -ne 0) {
        throw "The Flutter web release build failed."
    }
    $indexPath = Join-Path $appDirectory "build\web\index.html"
    $indexHtml = Get-Content -LiteralPath $indexPath -Raw
    if ($indexHtml -match '<base href="/">') {
        $indexHtml = $indexHtml.Replace('<base href="/">', '<base href="./">')
        Set-Content -LiteralPath $indexPath -Value $indexHtml -NoNewline
    } elseif ($indexHtml -notmatch '<base href="\./">') {
        throw "The release index did not contain a supported base path."
    }
    Copy-Item -LiteralPath (Join-Path $appDirectory "THIRD_PARTY_NOTICES.txt") -Destination (Join-Path $appDirectory "build\web\THIRD_PARTY_NOTICES.txt")
    Copy-Item -LiteralPath (Join-Path $appDirectory "assets\fonts\noto_sans\OFL.txt") -Destination (Join-Path $appDirectory "build\web\Noto-Sans-OFL.txt")
    Copy-Item -LiteralPath (Join-Path $appDirectory "assets\fonts\noto_sans_gurmukhi\OFL.txt") -Destination (Join-Path $appDirectory "build\web\Noto-Sans-Gurmukhi-OFL.txt")
    dart run tool\generate_web_app_cache.dart --build-dir=build\web --version=$version
    if ($LASTEXITCODE -ne 0) {
        throw "The offline app cache manifest could not be generated."
    }
    $privateContent = Get-ChildItem -LiteralPath (Join-Path $appDirectory "build\web") -File -Recurse | Where-Object {
        $_.FullName -match '[\\/]content[\\/](generated|curation)([\\/]|$)'
    }
    if ($null -ne $privateContent) {
        $paths = ($privateContent | Select-Object -ExpandProperty FullName) -join [Environment]::NewLine
        throw "The web build contains authoring-only content that must not be distributed:$([Environment]::NewLine)$paths"
    }
    New-Item -ItemType Directory -Force -Path $resolvedOutputDirectory | Out-Null
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath
    }
    Compress-Archive -Path "build\web\*" -DestinationPath $archivePath
} finally {
    Pop-Location
}

Write-Output "Created $archivePath"
