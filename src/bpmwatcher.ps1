#############################
# BPMs / PROBES MAINTANACE
 
# VARIABLES
 $storageDir = "D:\Work\tmp"
 $strict = 1;
 # DATES IN SECONDS
 $now = [int][double]::Parse((Get-Date -UFormat %s))
 $weekAgo = [int]($now - (60*60*24*7))
 $monthAgo = [int] ($now - (60*60*24*30))
 $threeMonthsAgo = [int] ($now - (60*60*24*90))
 $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
 
 # NUMBER OF MONTHS - HOW FAR AGO TO REACH FOR DATA [ SHOULD BE EITHER 1 OR 3 ]
 $numberOfMonths = 3
 
 # TRANSACTIONS ARRAY
 $faultyT = New-Object object[] 150
 $faultyTIndex = 0;
 
 # PROFILES TABLE
 $faultyP = New-Object object[] 6
 $faultyPIndex = 0;
 
 # PROBES TABLE
 $faultyPr = New-Object object[] 150
 $faultyPrIndex = 0;
 
 # EFFECTIVELY FOUR DIMENTIONAL ARRAY OF
 # PROFILES -> TRANSACTIONS -> PROBES -> [PROBE NAME][TIMESTAMP]
 $profileProbes = New-Object object[] 6
 
 # THREE DIMENTIONAL ARRAY OF
 # PROFILES -> TRANSACTIONS -> [TRANSACTON NAME][TIMESTAMP]
 $profiles = New-Object object[] 6
 
 # MANUALLY FILLED ARRAY OF PROFILE NAMES
 $profilesNames = New-Object object[] 6
 $profilesNames[0] = "A"
 $profilesNames[1] = "B"
 $profilesNames[2] = "C"
 $profilesNames[3] = "D"
 $profilesNames[4] = "E"
 $profilesNames[5] = "F"
 
# FUNCTIONS
function downloadTransactions( [string]$profile )
{
  $webclient = New-Object System.Net.WebClient
  $url = "https://BAC.URL/gdeopenapi/GdeOpenApi?method=getData&user=XXX&password=XXX&query=SELECT DISTINCT szTransactionName as transaction, MAX(time_stamp) as time FROM trans_t WHERE profile_name='" + $profile + "' and time_stamp>" + $weekAgo + " &resultType=csv&customerID=1"
  $file = "$storageDir\" + $profile + ".csv"
  $webclient.DownloadFile($url,$file)
}
 
function downloadProbes( [string]$transaction )
{
  $webclient = New-Object System.Net.WebClient
  $url = "https://BAC.URL/gdeopenapi/GdeOpenApi?method=getData&user=XXX&password=XXX&query=SELECT DISTINCT szLocationName as probe, MAX(time_stamp) as time FROM trans_t WHERE szTransactionName='" + $transaction + "' and time_stamp>" + $monthAgo + " &resultType=csv&customerID=1"
  $file = "$storageDir\" + $transaction + ".csv"
  $webclient.DownloadFile($url,$file)
}
 
function downloadProbesQuaterly( [string]$transaction )
{
  $webclient = New-Object System.Net.WebClient
  $url = "https://BAC.URL/gdeopenapi/GdeOpenApi?method=getData&user=XXX&password=XXX&query=SELECT DISTINCT szLocationName as probe, MAX(time_stamp) as time FROM trans_t WHERE szTransactionName='" + $transaction + "' and time_stamp>" + $threeMonthsAgo + " &resultType=csv&customerID=1"
  $file = "$storageDir\" + $transaction + ".csv"
  $webclient.DownloadFile($url,$file)
}
 
function showFaultyProfiles()
{
  for ($i = 0; $i -lt $faultyP.Length; $i++)
  {
    if ( $faultyP[$i].Length -gt 1 )
    {
      Write-host "`t" $faultyP[$i]
    }
  }
}
 
function showFaultyTransactions()
{
 Write-host -foregroundcolor green "+---------------------+-----//------+";
 Write-host -foregroundcolor green "|  HOURS WITHOUT DATA | TRANSACTION |";
 Write-host -foregroundcolor green "+---------------------+-----//------+";
 for ($i = 0; $i -lt $faultyT.Length; $i++)
 {
   for ($j = 0; $j -lt $faultyT[$i].Length; $j=$j+2)
  {
   $size = 55;
   $tranName = [string]$faultyT[$i][$j]
   $spaces = [int]([int]$size - [int]$tranName.Length)
   for ($k = 0; $k -lt $spaces; $k++)
   {
    $tranName = " " + $tranName;
    }
   $size = 18;
   $tranTime = [string]$faultyT[$i][$j+1]
   $spaces = [int]([int]$size - [int]$tranTime.Length)
   for ($k = 0; $k -lt $spaces; $k++)
   {
    $tranTime = " " + $tranTime;
   }
   Write-host -foregroundcolor green "| " $tranTime "|"  $tranName "|"
   Write-host -foregroundcolor green "+---------------------+-----//----+";
   }
 }
}
 
function printRow ( [string]$dateString, [string]$diffString,
   [string]$probeString, [string]$transactionString,  [string]$color )
{
  Write-host -nonewline -foregroundcolor green "| "
  Write-host -nonewline -foregroundcolor $color $dateString
  Write-host -nonewline -foregroundcolor green " | "
  Write-host -nonewline -foregroundcolor $color $diffString
  Write-host -nonewline -foregroundcolor green " | "
  Write-host -nonewline -foregroundcolor $color $probeString
  Write-host -nonewline -foregroundcolor green " | "
  Write-host -nonewline -foregroundcolor $color $transactionString
  Write-host -foregroundcolor green " |"
}
 
function drawLine()
{
  Write-host -foregroundcolor green "+--//--+--//--+--//--+--//--+";
}
function drawHeader()
{
  Write-host -foregroundcolor green "+--//--+--//--+--//--+--//--+";
  Write-host -foregroundcolor green "| LAST SEEN | HOURS LOST | PROBE | LAST TRANSACTION |";
  Write-host -foregroundcolor green "+--//--+--//--+--//--+--//--+";
}
 
# PROFILES
 
Write-Host -nonewline -foregroundcolor green " COLLECTING PROFILE TRANSACTIONS `t-"
$progress = "-"
for ($i = 0; $i -lt $profilesNames.Length; $i++)
{
  downloadTransactions ([string]$profilesNames[$i])
  $file = $storageDir + "\" + $profilesNames[$i] + ".csv"
  $tmp = Import-Csv "$file" -header("transaction","time","o")
  $counter = 0;
  $tmp | ForEach-Object
      {
        if ( $_.transaction -ne "transaction" -and
          $_.transaction -ne "" )
        { $counter++ }
      }
  $transactions = New-Object object[] $counter
  $j = 0;
  $tmp | ForEach-Object {
    if ( $_.transaction -ne "transaction" -and
          $_.transaction -ne "" -and
          $_.transaction -ne "The data is empty" )
    {
         $time = [int][double]::Parse(($_.time));
      $pair = New-Object object[] 2
      $pair[0] = $_.transaction;
      $pair[1] = $time
      $transactions[$j] = $pair
      $j++
    }
  }
  $profiles[$i] = $transactions
  if ($progress -eq "-") {Write-host -nonewline "`b\" ; $progress = "\"; continue}
  if ($progress -eq "\") {Write-host -nonewline "`b|"; $progress = "|";continue}
  if ($progress -eq "|") {Write-host -nonewline "`b/"; $progress = "/";continue}
  if ($progress -eq "/") {Write-host -nonewline "`b-"; $progress = "-";continue}
}
Write-host -foregroundcolor green "`b`b`tV"
Write-host -nonewline -foregroundcolor green " COLLECTING TRANSACTIONS' TIMESTAMPS `t-"
 
for ($i = 0; $i -lt $profiles.Length; $i++)
{
 for ($j = 0; $j -lt $profiles[$i].Length; $j++)
 {
   $diff = 0;
   if ( $profiles[$i][$j].Length -gt 0 )
   {
    # CALCULATE TIME SINCE LAST RESPONSE
    $diff = $now - [int][double]::Parse(($profiles[$i][$j][1]));
 
    # PARSE TO HOURS
    $diff = $diff / 60 / 60;
 
    # ROUNDING
    $diff = [int]$diff;
 
    if ( $diff -gt 25 )
    {
     $transaction = New-Object object[] 2
     $transaction[0] = $profiles[$i][$j][0];
     $transaction[1] = $diff;
     $faultyT[$faultyTIndex] = $transaction;
     $faultyTIndex++;
    }
   }
   else
   {
     $faultyP[$faultyPIndex] = $profilesNames[$i];
     $faultyPIndex++;
   }
   if ($progress -eq "-") {Write-host -nonewline "`b\" ; $progress = "\"; continue}
   if ($progress -eq "\") {Write-host -nonewline "`b|"; $progress = "|";continue}
   if ($progress -eq "|") {Write-host -nonewline "`b/"; $progress = "/";continue}
   if ($progress -eq "/") {Write-host -nonewline "`b-"; $progress = "-";continue}
 }
}
 
Write-host -foregroundcolor green "`b`b`tV"
 
Write-host -nonewline -foregroundcolor green " COLLECTING PROBES' TIMESTAMPS `t`t-"
 
for ($i = 0; $i -lt $profiles.Length; $i++)
{
  $transactionProbes = New-Object object[] 200
  for ($j = 0; $j -lt $profiles[$i].Length; $j++)
  {
   if ( $profiles[$i][$j] )
   {
    $transaction = $profiles[$i][$j][0].Replace('&', '%26')
    $transaction = $transaction.Replace('+', '%2B')
    if ( $numberOfMonths -eq 3 )
    {
     downloadProbesQuaterly ($transaction)
    }
    else
    {
     downloadProbes ($transaction)
    }
 
    $file = $storageDir + "\" + $transaction + ".csv"
    $tmp = Import-Csv "$file" -header("probe","time","o")
    $counter = 0;
    $tmp | ForEach-Object
         {
           if ( $_.probe -ne "probe" -and $_.probe -ne "" )
           { $counter++; }
         }
    $probes = New-Object object[] $counter
    $k = 0;
    $tmp | ForEach-Object
    {
     if ( $_.probe -ne "probe" -and
               $_.probe -ne "" -and
               $_.probe -ne "The data is empty" )
     {
       $time = [int][double]::Parse(($_.time));
       $probe = New-Object object[] 2
       $probe[0] = $_.probe;
       $probe[1] = $time
       $probes[$k] = $probe
       $k++
     }
    }
    $transactionProbes[$j] = $probes;
   }
    if ($progress -eq "-") {Write-host -nonewline "`b\" ; $progress = "\"; continue}
    if ($progress -eq "\") {Write-host -nonewline "`b|"; $progress = "|";continue}
    if ($progress -eq "|") {Write-host -nonewline "`b/"; $progress = "/";continue}
    if ($progress -eq "/") {Write-host -nonewline "`b-"; $progress = "-";continue}
  }
  $profileProbes[$i] = $transactionProbes;
}
 
Write-host -foregroundcolor green "`b`b`tV"
 
Write-host -nonewline -foregroundcolor green " SANITAZING PROBES' TIMESTAMPS `t`t-"
 
for ($i = 0; $i -lt $profileProbes.Length; $i++)
{
  for ($j = 0; $j -lt $profileProbes[$i].Length; $j++)
  {
    $validation = 0;
     for ($b = 0; $b -lt $faultyT.Length; $b++)
     {
      if ($faultyT[$b])
      {
       if ($profiles[$i][$j])
       {
        if ( $faultyT[$b][0] -eq $profiles[$i][$j][0] )
        {
          $validation = 1
        }
       }
      }
     }
 
    if ($validation -eq 0)
    {
      for ($k = 0; $k -lt $profileProbes[$i][$j].Length; $k++)
      {
    $diff = $now - [int][double]::Parse(($profileProbes[$i][$j][$k][1]))
    $diff = $diff / 60 / 60;
    $diff = [int]$diff;
 
    if ($diff -gt 25)
    {
       $containCheck = 0;
      for ($a = 0; $a -lt $faultyPr.Length; $a++)
      {
     if ( $faultyPr[$a] )
     {
      if ( $faultyPr[$a][0] -eq $profileProbes[$i][$j][$k][0] )
      {
       $containCheck = 1;
       if ( $faultyPr[$a][1] -lt $profileProbes[$i][$j][$k][1] )
       {
         $faultyPr[$a][1] = $profileProbes[$i][$j][$k][1]
         $faultyPr[$a][2] = $profiles[$i][$j][0]
       }
       }
      }
    }
    if ( $containCheck -eq 0 )
    {
      $probe = New-Object object[] 3
      $probe[0] = $profileProbes[$i][$j][$k][0]
      $probe[1] = $profileProbes[$i][$j][$k][1]
      $probe[2] = $profiles[$i][$j][0]
      $faultyPr[$faultyPrIndex] = $probe
      $faultyPrIndex++;
    }
   }
  }
  }
  }
  if ($progress -eq "-") {Write-host -nonewline "`b\" ; $progress = "\"; continue}
  if ($progress -eq "\") {Write-host -nonewline "`b|"; $progress = "|";continue}
  if ($progress -eq "|") {Write-host -nonewline "`b/"; $progress = "/";continue}
  if ($progress -eq "/") {Write-host -nonewline "`b-"; $progress = "-";continue}
}
 
if ($strict -eq 1)
{
  for ( $a = 0; $a -lt $faultyPr.Length; $a++ )
  {
    if ($faultyPr[$a])
    {
    for ($i = 0; $i -lt $profileProbes.Length; $i++)
     {
     for ($j = 0; $j -lt $profileProbes[$i].Length; $j++)
      {
      for ($k = 0; $k -lt $profileProbes[$i][$j].Length; $k++)
      {
        if ( ($profileProbes[$i][$j][$k]) -and ($faultyPr[$a]) )
        {
         if ( $faultyPr[$a][0] -eq $profileProbes[$i][$j][$k][0] )
         {
          if ( $faultyPr[$a][1] -lt $profileProbes[$i][$j][$k][1] )
         {
          $diff = $now - [int][double]::Parse(($profileProbes[$i][$j][$k][1]))
          $diff = $diff / 60 / 60;
          $diff = [int]$diff;
          if ( $diff -lt 25)
          {
            $faultyPr[$a] = $null;
          }
          else
          {
            $faultyPr[$a][1] = $profileProbes[$i][$j][$k][1];
            $faultyPr[$a][2] = $profiles[$i][$j][0];
          }
         }
         }
        }
      }
     }
     }
    }
  }
}
 
Write-host -foregroundcolor green "`b`b`tV"
 
# PRINTING INFO
Write-host -foregroundcolor green "`n PROFILES MISSING DATA: ";
  showFaultyProfiles;
 
Write-host -foregroundcolor green "`n UNRESPONSIVE TRANSACTIONS: ";
  showFaultyTransactions;
 
Write-host -foregroundcolor green "`n INACTIVE PROBES: ";
  drawHeader;
 
# SORTING TABLE
$faultyPr = $faultyPr | sort-object @{Expression={$_[1]}; Ascending=$true}
 
# PRINTING INACTIVE PROBES
for ( $i = 0; $i -lt $faultyPr.Length; $i++ )
{
  if ($faultyPr[$i])
  {
   $whatIWant = $origin.AddSeconds($faultyPr[$i][1]);
   $size = 21;
   $dateString = [string]$whatIWant
   $spaces = [int]([int]$size - [int]$dateString.Length)
   for ($j = 0; $j -lt $spaces; $j++)
   {
     $dateString = $dateString + " ";
   }
 
   $diff = $now - [int][double]::Parse(($faultyPr[$i][1]))
   $diff = $diff / 60 / 60;
   $diff = [int]$diff;
   $size = 12;
   $diffString = [string]$diff
   $spaces = [int]([int]$size - [int]$diffString.Length)
   for ($j = 1; $j -lt $spaces; $j++)
   {
     $diffString = " " + $diffString;
   }
 
   $size = 25;
   $probeString = [string]$faultyPr[$i][0]
   $spaces = [int]([int]$size - [int]$probeString.Length)
   for ($j = 1; $j -lt $spaces; $j++)
   {
     $probeString = " " + $probeString;
   }
   $size = 45;
   $transactionString = [string]$faultyPr[$i][2]
   $spaces = [int]([int]$size - [int]$transactionString.Length)
   for ($j = 1; $j -lt $spaces; $j++)
   {
     $transactionString = " " + $transactionString;
   }
   if ( $diff -gt 1440 )
   {
     printRow ($dateString) ($diffString) ($probeString) ($transactionString) ("Magenta")
   }
   elseif ( $diff -gt 720 )
   {
     printRow ($dateString) ($diffString) ($probeString) ($transactionString) ("Red")
   }
   elseif ( $diff -gt 168 )
   {
     printRow ($dateString) ($diffString) ($probeString) ($transactionString) ("Yellow")
   }
   else
   {
     printRow ($dateString) ($diffString) ($probeString) ($transactionString) ("Green")
   }
    drawLine;
 }
}
####################