# Leer el JSON desde archivo
$json = Get-Content -Raw -Path "response.json" | ConvertFrom-Json

# Extraer tabla
$table = $json.tables[0]
$columns = $table.columns.name
$rows = $table.rows

# Convertir filas a objetos con nombres de columna
$objects = $rows | ForEach-Object {
    $obj = [PSCustomObject]@{}
    for ($i = 0; $i -lt $columns.Count; $i++) {
        $obj | Add-Member -MemberType NoteProperty -Name $columns[$i] -Value $_[$i]
    }
    $obj
}

# Exportar a CSV
$objects | Export-Csv -Path "output.csv" -NoTypeInformation
Write-Host "CSV generado en output.csv"
