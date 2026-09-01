for ($i = 1; $i -le 3; $i++) {
    Write-Host "Running Maestro test, iteration $i"
    maestro test e2e\test_login_testuser.yaml
}
Write-Host "All test iterations completed."
