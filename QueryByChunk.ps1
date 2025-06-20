##  Before running this script run   Connect-AzAccount   to authenticate to Azure
##  if the wrong subscription was selected run   Select-AzSubscription -SubscriptionId  ########-####-####-####-###########
##
##  Update the variables below as needed 

Connect-AzAccount
Select-AzSubscription -SubscriptionId ""

$workspaceID    = ""            # Target Log Analytics Workspace ID.
$OutputFileName = ".\OutputQueryByChunk"                    # Output file, you can modify the path where you will create the .csv – Or file will be created in the path were you executed the script.
$SendAllqueryReultsToASingleFile = $True                   # Use single file for output?
$NumberOfQueryResultsToHoldPerFile = 60                    # If using multiple files, this controls the # of queries per file.
$MinuteInterval = 10000                                    # Chunk size in minutes.
$StartDatestr   = "19/03/2025 12:00:00.000 AM"              # Get data staring from this Date/time, from Log Analytics workspace
$EndDatestr     = "20/06/2025, 12:00:00.000 PM"            # Get data ending at this Date/time, from Log Analytics workspace

## Update the Query below as needed.  
## The first line of the query should be the Table name.
## The second line of the query should be the following and any remaining filters should be after the line below with no blank lines in the middle or above the table name
## Note, if your table does not contain TimeGenerated update to the field name to the Date/Time name in your table

$Query = @'
AzureActivity
| where TimeGenerated between (START..END)

'@

###############################################################################################
## Update the variables above as needed
###############################################################################################
###############################################################################################

cls
$CRLF = "`r`n"
$StartDate = get-date $StartDatestr
$EndDate =  get-date $EndDatestr
$currentDate = $StartDate
$OutputFile = $OutputFileName + $currentDate.ToString("_yyyy-MM-dd_HH-mm-ss")+".csv"
if (test-path $OutputFile) {del $OutputFile} # file should not exist if it does delete it
$xx = 0
do
{
  $StartDateString = $currentDate.ToString("yyyy-MM-dd HH:mm:ss.ffffff")+"1"   # Formating is case sensitive do not modify, +"1" to prevent duplicates
  $currentDate = $currentDate.AddMinutes($MinuteInterval)

  If ($currentDate -gt $EndDate) {$currentDate = $EndDate}                     # If adding MinuteInterval goes past enddate correct
  $EndDateString = $currentDate.ToString("yyyy-MM-dd HH:mm:ss.ffffff")+"1"     # Formating is case sensitive do not modify, +"1" to prevent duplicates

  $WHQLstart = 'let START = datetime('+ $StartDateString + ');' + $CRLF
  $WHQLend =  'let END = datetime('+ $EndDateString + ');' + $CRLF

  $WHQLQuery = $WHQLstart + $WHQLend + $Query

  if ($xx % $NumberOfQueryResultsToHoldPerFile -eq 0) {  "";(Get-date).tostring() + "  Sample WHQL query being submitted ";""; $WHQLQuery;""}

  $Results = Invoke-AzOperationalInsightsQuery -WorkspaceID $workspaceID -Query $WHQLQuery
  $results.Results | Export-csv $OutputFile -Append -NoTypeInformation
  $xx++
  (Get-date).tostring() + "  Append query result from $StartDateString - $EndDateString to $OutputFile"
  if ($xx % $NumberOfQueryResultsToHoldPerFile -eq 0 -and (!($SendAllqueryReultsToASingleFile)))  # increment file name if needed
    {$OutputFile = $OutputFileName + $currentDate.ToString("_yyyy-MM-dd_HH-mm-ss")+".csv"
     if (test-path $OutputFile) {del $OutputFile} # file should not exist if it does delete it
    } 
} while ($currentDate -ne $EndDate)
  (Get-date).tostring() + "  Done"
