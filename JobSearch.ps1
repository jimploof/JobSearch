param (
[Parameter(Mandatory=$true)][string]$filename,
[Parameter(Mandatory=$true)][string]$pwd
)

# Set default parameters incase none are specified in config file
$default_title = "Automated Dice JobSearch" 
$default_country = "USA"
$default_age = "21"
$default_sort = "1"
$default_fulltime = $false
$default_telecommute = $false
$default_direct = $false
$default_contract = $false
$default_parttime = $false
$default_city = $null
$default_state = $null

# Fixed numerical parameters used by Dice
$telecommute_param = "1102"
$fulltime_param = "1001"
$parttime_param = "1008"
$contract_param = @("1002", "1003", "1004", "1005", "1006", "1007")

# Initialize these arrays
$include = New-Object System.Collections.ArrayList
$exclude = New-Object System.Collections.ArrayList
$addparams = New-Object System.Collections.ArrayList

# Read in the config file and initialze variables
$obj = Get-Content -Raw -Path $filename | ConvertFrom-Json
$mailconfig = $obj.'mail-config'
$searches = $obj.searches

# If the URI field is not populated in config file, exit
if([string]::IsNullOrEmpty($obj.uri)) { exit }


# Iterate through the configured searches
for ($x = 0; $x -le ($obj.searches.Count - 1) ; $x++) {

    # Set default values each iteration
    $baseuri = $obj.uri
    $includeFilter = $null
    $excludeFilter = $null
    $include.Clear()
    $exclude.Clear()
    $addparams.Clear()

    # Set values based on config file, if nothing exists in config file, use defaults
    if(![string]::IsNullOrEmpty($obj.searches[$x].keyword)) { $keyword = $obj.searches[$x].keyword } else { continue }
    if(![string]::IsNullOrEmpty($obj.searches[$x].title)) { $title = $obj.searches[$x].title } else { $title = $default_title }
    if(![string]::IsNullOrEmpty($obj.searches[$x].country)) { $country = $obj.searches[$x].country } else { $country = $default_country }
    if(![string]::IsNullOrEmpty($obj.searches[$x].state)) { $state = $obj.searches[$x].state } else { $state = $default_state }
    if(![string]::IsNullOrEmpty($obj.searches[$x].city)) { $city = $obj.searches[$x].city } else { $city = $default_city }
    if(![string]::IsNullOrEmpty($obj.searches[$x].age)) { $age = $obj.searches[$x].age } else { $age = $default_age }
    if(![string]::IsNullOrEmpty($obj.searches[$x].sort)) { $sort = $obj.searches[$x].sort } else { $sort = $default_sort }
    if(![string]::IsNullOrEmpty($obj.searches[$x].direct)) { if ($obj.searches[$x].direct -eq "true") { $direct = $true } elseif ($obj.searches[$x].direct -eq "false") { $direct = $false } else { $direct = $default_direct }} else { $direct = $default_direct } 
    if(![string]::IsNullOrEmpty($obj.searches[$x].fulltime)) { if ($obj.searches[$x].fulltime -eq "true") { $fulltime = $true } elseif ($obj.searches[$x].fulltime -eq "false") { $fulltime = $false } else { $fulltime = $default_fulltime }} else { $fulltime = $default_fulltime } 
    if(![string]::IsNullOrEmpty($obj.searches[$x].parttime)) { if ($obj.searches[$x].parttime -eq "true") { $parttime = $true } elseif ($obj.searches[$x].parttime -eq "false") { $parttime = $false } else { $parttime = $default_parttime }} else { $parttime = $default_parttime } 
    if(![string]::IsNullOrEmpty($obj.searches[$x].contract)) { if ($obj.searches[$x].contract -eq "true") { $contract = $true } elseif ($obj.searches[$x].contract -eq "false") { $contract = $false } else { $contract = $default_contract }} else { $contract = $default_contract } 
    if(![string]::IsNullOrEmpty($obj.searches[$x].telecommute)) { if ($obj.searches[$x].telecommute -eq "true") { $telecommute = $true } elseif ($obj.searches[$x].telecommute -eq "false") { $telecommute = $false } else { $telecommute = $default_telecommute }} else { $telecommute = $default_telecommute } 
    
    # If the include array exists in config file, iterate through it
    if(![string]::IsNullOrEmpty($obj.searches[$x].include)) {
        for($i = 0; $i -le ($obj.searches[$x].include.Count - 1); $i++) {
            $include.Add($([string]::Format("*{0}*", $obj.searches[$x].include[$i]))) | Out-Null
        }
    }
    
    # If the exclude array exists in config file, iterate through it
    if(![string]::IsNullOrEmpty($obj.searches[$x].exclude)) {
        for($i = 0; $i -le ($obj.searches[$x].exclude.Count - 1); $i++) {
            $exclude.Add($([string]::Format("*{0}*", $obj.searches[$x].exclude[$i]))) | Out-Null
        }
    }

    # Create the include filter
    if(![string]::IsNullOrEmpty($include)) {
        if ($include.count -gt 0) {
            $i = 0
            foreach ($in in $include) {
                if ($i -eq 0) {
                    $includeFilter = $([string]::Format('if ($node.jobTitle.InnerText -like "{0}"', $in.Trim()))
                    $i++
                }
                else {
                    $includeFilter = $([string]::Format('{0} -or $node.jobTitle.InnerText -like "{1}"', $includeFilter, $in.Trim()))
                }
            }
            $includeFilter = $([string]::Format('{0}) {{ $includeBol = $true }}', $includeFilter))
        }
    }


    # Create the exclude filter
    if(![string]::IsNullOrEmpty($exclude)) {
        if ($exclude.count -gt 0) {
            $i = 0
            foreach ($ex in $exclude) {
                if ($i -eq 0) {
                    $excludeFilter = $([string]::Format('if ($node.jobTitle.InnerText -like "{0}"', $ex.Trim()))
                    $i++
                }
                else {
                    $excludeFilter = $([string]::Format('{0} -or $node.jobTitle.InnerText -like "{1}"', $excludeFilter, $ex.Trim()))
                }
            }
            $excludeFilter = $([string]::Format('{0}) {{ $excludeBol = $true }}', $excludeFilter))
        }
    }


    # Build the URL based off of config file and default files
    $baseUri = $([string]::Format("{0}text={1}&country={2}&sort={3}&age={4}", $baseUri, $keyword, $country, $sort, $age))
    if (![string]::IsNullOrEmpty($state)) { $baseUri = $([string]::Format("{0}&state={1}", $baseUri,$state)) }
    if (![string]::IsNullOrEmpty($city)) { $baseUri = $([string]::Format("{0}&city={1}", $baseUri,$city)) }
    if (![string]::IsNullOrEmpty($skill)) { $baseUri = $([string]::Format("{0}&skill={1}", $baseUri,$skill)) }
    if ($direct) { $baseUri = $([string]::Format("{0}&direct=1", $baseUri)) }
    
    if ($telecommute -eq $true -or $fulltime -eq $true -or $parttime -eq $true -or $contract -eq $true) { 
        $baseUri = $([string]::Format("{0}&N=", $baseUri))
        if ($telecommute -eq $true) { $addparams.Add($telecommute_param) | Out-Null } 
        if ($fulltime -eq $true) { $addparams.Add($fulltime_param) | Out-Null }
        if ($parttime -eq $true) { $addparams.Add($parttime_param) | Out-Null }
        if ($contract -eq $true) { 
            for($i=0; $i -le ($contract_param.Count - 1); $i++) {
                $addparams.Add($contract_param[$i]) | Out-Null
            }
        }
        for ($i=0; $i -le ($addparams.Count - 1); $i++) {
            $baseUri = $([string]::Format("{0}{1}+", $baseUri, $addparams[$i]))
        }
        $baseuri = $baseuri.Substring(0, ($baseuri.Length - 1))

    }



    # Create HTML headers and TABLE headers for email results
    $htmlEmail = $([string]::Format('<html>' + "`n"))
    $htmlEmail = $([string]::Format('{0}<head>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}</head>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<body>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<table style="border-collapse: collapse;width: 100%;">' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<thead>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<tr>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<th style="text-align:left;padding:8px;background-color:rgb(47, 117, 181);color:white;">Title</th>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<th style="text-align:left;padding:8px;background-color:rgb(47, 117, 181);color:white;">Company</th>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<th style="text-align:left;padding:8px;background-color:rgb(47, 117, 181);color:white;">Location</th>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<th style="text-align:left;padding:8px;background-color:rgb(47, 117, 181);color:white;">Date</th>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<th style="text-align:left;padding:8px;background-color:rgb(47, 117, 181);color:white;">Link</th>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}</tr>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}</thead>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}<tbody>' + "`n", $htmlEmail))


    # Invoke the web request and grab XML payload
    $diceUrl = $baseUri
    [xml]$payload = Invoke-WebRequest -uri $diceUrl
    
    # Determine number of pages returned
    $countnode = $payload.SelectNodes('result/count') | % { $_.InnerText } | select –Unique
    $numpages = ($countnode / 30)
    $numpages = [math]::Round($numpages)

    $resultCount = 0
    $rowcount = 0


    # Iterate through results, number of pages, and also filter results based on include/exclude filters if they exist
    for ($i=1; $i -le ($numpages + 1); $i++) {
        $diceUrl = $([string]::Format("{0}&page={1}", $baseUri, $i))
        [xml]$payload = Invoke-WebRequest -uri $diceUrl
        $nodes = $payload.SelectNodes("result/resultItemList/resultItem")
        foreach ($node in $nodes) {
            $includeBol = $true
            $excludeBol = $false
            if(![string]::IsNullOrEmpty($includeFilter)) {
                $includeBol = $false
                Invoke-Expression $includeFilter
            }
            if(![string]::IsNullOrEmpty($excludeFilter)) {
                $excludeBol = $false
                Invoke-Expression $excludeFilter
            }
            if ($includeBol -eq $true -and $excludeBol -eq $false) {
                if ($rowcount % 2 -eq 0) { 
                    $htmlEmail = $([string]::Format('{0}<tr style="background-color:rgb(221, 235, 247);">' + "`n", $htmlEmail))
                }
                else {
                    $htmlEmail = $([string]::Format('{0}<tr>' + "`n", $htmlEmail))
                }
                $htmlEmail = $([string]::Format('{0}<td>{1}</td>' + "`n", $htmlEmail, $node.jobTitle.InnerText))
                $htmlEmail = $([string]::Format('{0}<td>{1}</td>' + "`n", $htmlEmail, $node.company.InnerText))
                $htmlEmail = $([string]::Format('{0}<td>{1}</td>' + "`n", $htmlEmail, $node.location.InnerText))
                $htmlEmail = $([string]::Format('{0}<td style="padding-right:1em">{1}</td>' + "`n", $htmlEmail, $node.date.InnerText))
                $htmlEmail = $([string]::Format('{0}<td style="padding-top: .35em;padding-bottom: .35em;"><a href="{1}" target="_blank" style="vertical-align:middle;text-align:center;">Go</a></td>' + "`n", $htmlEmail, $node.detailUrl.InnerText))
                $htmlEmail = $([string]::Format('{0}</tr>' + "`n", $htmlEmail))
                $rowcount++
                $resultCount++
            }
        }
    }

    # Closing HTML tags for e-mail body
    $htmlEmail = $([string]::Format('{0}</tbody>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}</table>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}</body>' + "`n", $htmlEmail))
    $htmlEmail = $([string]::Format('{0}</html>' + "`n", $htmlEmail))


    # E-mail settings
    $From = $mailconfig.from
    $To = $mailconfig.to
    $Subject = $([string]::Format('{0} Results for {1}', $resultCount, $title))
    $SMTPServer = $mailconfig.smtp
    $SMTPPort = $mailconfig.port

    $User = $mailconfig.username
    $PWord = ConvertTo-SecureString –String $pwd –AsPlainText -Force
    $Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord

    # Send an HTML email with the results
    if ($resultCount -gt 0) {
        Send-MailMessage -From $From -to $To -Subject $Subject -Body $htmlEmail -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -BodyAsHtml -Credential $Credential 
    }

    # Inserted a small timeout before continuining to next search. Multiple emails werent sending without this
    start-sleep 60

}
