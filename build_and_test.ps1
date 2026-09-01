$ErrorActionPreference = "Stop"
$env:ANDROID_HOME = "C:\Users\Krisman\Android\Sdk"

Write-Host "Building APK..."
flutter build apk --debug

Write-Host "Installing APK..."
C:\Users\Krisman\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v3.3.4\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk

Write-Host "Starting app on device..."
C:\Users\Krisman\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v3.3.4\adb.exe shell am start -n com.studycenter.sc_student/com.studycenter.sc_student.MainActivity

Write-Host "Running Maestro test..."
maestro test e2e\test_comprehensive_dual_role.yaml
