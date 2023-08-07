$path=$args[0]
$wordlistPath=$args[1]
$filter=$args[2]
$verb=$args[3]
$result=""

function banner()
{
write-host "==================================================="
write-host " __  ___      ___    __              "              
write-host '/__`  |   /\   |  | /  `              '            
write-host '.__/  |  /~~\  |  | \__,                 '          
write-host "                                          "        
write-host '             __   __   __   ___            '        
write-host '            /  ` /  \ |  \ |__              '      
write-host '   	    \__, \__/ |__/ |___				'         
write-host "                                              "    
write-host "                         __   ___         ___  "    
write-host "                        |__) |__  \  / | |__  |  | "
write-host "                        |  \ |___  \/  | |___ |/\| "
write-host "====================================================="
write-host ""
}

function help()
{
	write-host "./staic-code-review <repositoryPath> <wordlist> <filter> [[-v] [-vv]] [[-java] [-dontnet]]"
	write-host
	write-host "-v		Verbosity."
	write-host "-vv		Display category description."
	write-host "-java		Execute only java wordlists."
}


Function Trace-Word
{
    [Cmdletbinding()]
    [Alias("Highlight")]
    Param(
            [Parameter(ValueFromPipeline=$true, Position=0)] [string[]] $content,
            [Parameter(Position=1)] 
            [ValidateNotNull()]
            [String[]] $words = $(throw "Provide word[s] to be highlighted!")
    )
    
    Begin
    {
        
        $Color = @{       
                    0='Yellow'      
                    1='Magenta'     
                    2='Red'         
                    3='Cyan'        
                    4='Green'       
                    5 ='Blue'        
                    6 ='DarkGray'    
                    7 ='Gray'        
                    8 ='DarkYellow'    
                    9 ='DarkMagenta'    
                    10='DarkRed'     
                    11='DarkCyan'    
                    12='DarkGreen'    
                    13='DarkBlue'        
        }

        $ColorLookup =@{}

        For($i=0;$i -lt $words.count ;$i++)
        {
            if($i -eq 13)
            {
                $j =0
            }
            else
            {
                $j = $i
            }

            $ColorLookup.Add($words[$i],$Color[$j])
            $j++
        }
        
    }
    Process
    {
    $content | ForEach-Object {
    
        $TotalLength = 0
               
        $_.split() | `
        Where-Object {-not [string]::IsNullOrWhiteSpace($_)} | ` #Filter-out whiteSpaces
        ForEach-Object{
                        if($TotalLength -lt ($Host.ui.RawUI.BufferSize.Width-10))
                        {
                            #"TotalLength : $TotalLength"
                            $Token =  $_
                            $displayed= $False
                            
                            Foreach($Word in $Words)
                            {
                                if($Token -like "*$Word*")
                                {
                                    $Before, $after = $Token -Split "$Word"
                              
                                        
                                    #"[$Before][$Word][$After]{$Token}`n"
                                    
                                    Write-Host $Before -NoNewline ; 
                                    Write-Host $Word -NoNewline -Fore Black -Back $ColorLookup[$Word];
                                    Write-Host $after -NoNewline ; 
                                    $displayed = $true                                   
                                    #Start-Sleep -Seconds 1    
                                    #break  
                                }

                            } 
                            If(-not $displayed)
                            {   
                                Write-Host "$Token " -NoNewline                                    
                            }
                            else
                            {
                                Write-Host " " -NoNewline  
                            }
                            $TotalLength = $TotalLength + $Token.Length  + 1
                        }
                        else
                        {                      
                            Write-Host '' #New Line  
                            $TotalLength = 0 

                        }

                            #Start-Sleep -Seconds 0.5
                        
        }
        Write-Host '' #New Line               
    }
    }
    end
    {    }

}


function noVerbose($resultnumer)
{
	write-host "[*] $($line) " -BackgroundColor darkgray -nonewline
	
}


function init()
{
	if($path -eq  $null -Or $wordlistPath -eq $null -Or $filter -eq $null)
	{
		help
		write-host ""
		exit
	}
	elseif (!(Test-Path -Path $path)) 
	{
		write-host "Path doesen't exitst!"
		write-host ""
		exit 
	}
}


function getFiles($p) 
{ 
		if ($sp -eq "." -Or $sp -eq ".."){return} 
		if (((Get-Item $p) -is [System.IO.fileinfo]))
		{
			$wordlists += $p
			return $p
		}
		foreach ($item in Get-ChildItem $p)
		{
			getFiles("$($p)\$($item)")
		}
}

#=============================================
init
banner

write-host "Path: $($path)" -BackgroundColor yellow -ForegroundColor Black
write-host "Wordlist path: $($wordlistPath)" -BackgroundColor yellow -ForegroundColor Black
write-host "Filter: $($filter)" -BackgroundColor yellow -ForegroundColor Black
write-host "Verbosity level: $($verb)" -BackgroundColor yellow -ForegroundColor Black
write-host ""

[System.Collections.ArrayList]$wordlists = @()
$wordlists = getFiles $wordlistPath


foreach($wordlistFile in $wordlists)
{
	$title = $wordlistFile.split("\")
	$title = $title[$title.Length-1]
	
	
	write-host "==== $($title) ====" -BackgroundColor white -foregroundcolor black 

	foreach($line in Get-content "$($wordlistFile)")
	{
		if ($line -like "//*")
		{
			if ($verb -eq "-vv")
			{
				write-host "$($line)" -ForegroundColor darkgray -BackgroundColor white
			}
			continue
		}
		
		write-host "[*] $($line) " -BackgroundColor darkgray
		$result=get-childitem $path -filter $filter -recurse | select-string -pattern $line
		if($verb -eq $null)
		{
			write-host "$($result.Count) occurrence."
		}
		elseif ($verb -eq "-v" -Or $verb -eq "-vv")
		{
			foreach($line1 in $result)
			{
				Trace-Word -content  ($line1) -word $line
			}
		}
	}
	
}

exit 0