# Define your variables
$workspaceId = "<Your-Workspace-ID>"
$clientId = "<Your-Client-ID>"
$clientSecret = "<Your-Client-Secret>"
$tenantId = "<Your-Tenant-ID>"
$logQuery = "AzureActivity | where TimeGenerated > ago(1d) | take 10"
$resource = "https://api.loganalytics.io/"  # Use this for token request

# Acquire the OAuth2 token
$tokenRequestBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = $resource
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Body $tokenRequestBody
$authHeader = @{
    "Authorization" = "Bearer $($tokenResponse.access_token)"
    "Content-Type"  = "application/json"
}

# Prepare the query
$queryUri = "https://api.loganalytics.azure.com/v1/workspaces/$workspaceId/query"
$queryBody = @{
    query = $logQuery
} | ConvertTo-Json -Depth 3

# Execute the query
$response = Invoke-RestMethod -Method Post -Uri $queryUri -Headers $authHeader -Body $queryBody

# Convert to objects with column names
$table = $response.tables[0]
$columns = $table.columns.name
$rows = $table.rows | ForEach-Object {
    $obj = [PSCustomObject]@{}
    for ($i = 0; $i -lt $columns.Count; $i++) {
        $obj | Add-Member -MemberType NoteProperty -Name $columns[$i] -Value $_[$i]
    }
    $obj
}

# Create a timestamped folder
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$folderPath = ".\\LogAnalytics_$timestamp"
New-Item -ItemType Directory -Path $folderPath -Force | Out-Null

# Export to CSV inside the folder
$csvPath = "$folderPath\\LogAnalyticsResults.csv"
$rows | Export-Csv -Path $csvPath -NoTypeInformation

# Optional: Display the results in the console
$rows | Format-Table -AutoSize

Write-Host "Results saved to: $csvPath"
