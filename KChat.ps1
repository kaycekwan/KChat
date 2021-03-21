## Do NOT execute in ISE; This version uses only DataStream (StreamReader and StreamWriter are NOT in use)
## Sessions are reused once disconnected; SID is incremental and gone.
<##################################################################################################>

Function Start-KCSServer {

param (
  [int]$Port = 9999
  )

Try     {
$Host.UI.RawUI.FlushInputBuffer()
$Host.UI.RawUI.WindowTitle = "KCSServer"

$Sessions  = @()
$Session   = New-Object -TypeName PSObject
$Session   | Add-Member -MemberType NoteProperty -Name SID        -Value $(0-1)
$Session   | Add-Member -MemberType NoteProperty -Name Client     -Value ""
$Session   | Add-Member -MemberType NoteProperty -Name LocalIP    -Value "0.0.0.0"
$Session   | Add-Member -MemberType NoteProperty -Name RemoteIP   -Value "0.0.0.0"
$Session   | Add-Member -MemberType NoteProperty -Name RemotePort -Value 0
$Session   | Add-Member -MemberType NoteProperty -Name Stream     -Value ""
$Session   | Add-Member -MemberType NoteProperty -Name UserName   -Value "Server"
$Sessions += $Session

$socket = new-object System.Net.Sockets.TcpListener([ipaddress]::Any, $port)
Try   {$socket.start()}
Catch {Write-Host $_ -ForegroundColor Red; Return}

$i         = 0
$Sessions[$i].Client  = $Socket
$Sessions[$i].LocalIP = $Socket.LocalEndPoint
$i++

Write-Host "KCSServer Version 1.0.15"

$loop = $true; While ($loop) {
##########
  if ($($Socket.Pending())) {
    $Client      = $Socket.AcceptTcpClient()
    If ($($Sessions.where({$_.SID -eq 0}).count) -eq 0) {
      $Session   = New-Object -TypeName PSObject
      $Session   | Add-Member -MemberType NoteProperty -Name SID        -Value $i
      $Session   | Add-Member -MemberType NoteProperty -Name Client     -Value $Client
      $Session   | Add-Member -MemberType NoteProperty -Name LocalIP    -Value $Client.Client.LocalEndPoint.Address
      $Session   | Add-Member -MemberType NoteProperty -Name RemoteIP   -Value $Client.Client.RemoteEndPoint.Address # .IPAddressToString
      $Session   | Add-Member -MemberType NoteProperty -Name RemotePort -Value $Client.Client.RemoteEndPoint.Port
      $Session   | Add-Member -MemberType NoteProperty -Name Stream     -Value $Client.GetStream()
      $Session   | Add-Member -MemberType NoteProperty -Name UserName   -Value ""
      $Sessions += $Session
      $ii        = $i
      }
    Else {
      $ii        = $($Sessions.SID.indexof(0))
      $Sessions[$ii].SID        = $i
      $Sessions[$ii].Client     = $Client
      $Sessions[$ii].LocalIP    = $Client.Client.LocalEndPoint.Address
      $Sessions[$ii].RemoteIP   = $Client.Client.RemoteEndPoint.Address.IPAddressToString
      $Sessions[$ii].RemotePort = $Client.Client.RemoteEndPoint.Port
      $Sessions[$ii].Stream     = $Client.GetStream()
      $Sessions[$ii].UserName   = ""
      }
    write-output $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] Client {2}:{3} Connected." -f $Sessions[0].UserName, $Sessions[$ii].SID, $Sessions[$ii].RemoteIP, $Sessions[$ii].RemotePort)
    $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] Host {2}:{3} Connected.`r`nTell your name by entering callme yourname.`r`n" -f $Sessions[0].UserName, $Sessions[$ii].SID, $Sessions[$ii].LocalIP, $Port))
    $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.length)
    $Sessions[$ii].Stream.Flush()
    $i++
  }
##########
  For ($ii = 1; $ii -lt $($Sessions.Count); $ii++) {
    If ($($Sessions[$ii].SID) -ne 0) {
      #####
      If ($($Sessions[$ii].Client.Connected) -and $($Sessions[$ii].Stream.DataAvailable)) {
        If ($Sessions[$ii].UserName -eq "") {
          $FromWho = $($Sessions[$ii].SID)
          }
        Else {
          $FromWho = $($Sessions[$ii].UserName)
          }
        $buffer = new-object System.Byte[] 1024
        $recvlines = ""; do {
          $recvlines += $([Text.Encoding]::ASCII.GetString($buffer, 0, $($Sessions[$ii].Stream.Read($buffer, 0, $buffer.length))))
          } While ($Session[$ii].Stream.DataAvailable)
        Write-Host -NoNewLine $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] $recvlines" -f $FromWho)
        $cmd = $recvlines.substring(0,$recvlines.length-2)
        If     ($cmd.substring(0,1) -eq "@")      {
          $i3 = $cmd.substring(1).split(" ")[0]
          If ($i3 -match "^\d+$") {
            If ($i3 -gt 0) {
              $i4 = $($Sessions.SID.IndexOf($($Sessions.where({$_.SID -eq $i3}).SID)))
              If ($i4 -gt 0) {
                $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] $cmd`r`n" -f $FromWho))
                $Sessions[$i4].Stream.Write($Buffer,0,$Buffer.Length)
                $Sessions[$i4].Stream.Flush()
                }
              Else {
                $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [@{1}] is either offline or NOT exist.`r`n" -f $Sessions[0].UserName, $i3))
                $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
                $Sessions[$ii].Stream.Flush()
                }
              }
            Else {
              For ($i5 = 1; $i5 -lt $($Sessions.Count); $i5++) {
                If (($($Sessions[$i5].SID) -ne 0) -and ($($Sessions[$i5].SID) -ne $($Sessions[$ii].SID))) { # except myself
                  $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] $cmd`r`n" -f $FromWho))
                  $Sessions[$i5].Stream.Write($Buffer,0,$Buffer.Length)
                  $Sessions[$i5].Stream.Flush()
                  }
                }
              }
            }
          Else {
            $i4 = $($Sessions.UserName.IndexOf($($Sessions.where({$_.UserName -eq $i3}).UserName)))
            If ($i4 -gt 0) {
              $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] $cmd`r`n" -f $FromWho))
              $Sessions[$i4].Stream.Write($Buffer,0,$Buffer.Length)
              $Sessions[$i4].Stream.Flush()
              }
            Else {
              $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [@{1}] is either offline or NOT exist.`r`n" -f $Sessions[0].UserName, $i3))
              $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
              $Sessions[$ii].Stream.Flush()
              }
            }
          }
        ElseIf ($cmd.split()[0] -eq "callme")     {
          $tokens   = $cmd.split()
          $UserName = $tokens[1]
          If ($UserName -notlike $null) {
            $i3 = $($Sessions.UserName.IndexOf($($Sessions.where({$_.UserName -eq $UserName}).UserName)))
            If ($i3 -lt 0) {
              $Sessions[$ii].UserName = $UserName
              $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] Wellcome {1}!`r`n" -f $Sessions[0].UserName, $UserName))
              $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
              $Sessions[$ii].Stream.Flush()  
              if ($tokens[2] -eq "-RunAs") {$RunAs = $UserName}
              }
            ElseIf ($i3 -eq $ii) {
              $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] You're already {1}!`r`n" -f $Sessions[0].UserName, $UserName))
              $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
              $Sessions[$ii].Stream.Flush()
              if ($tokens[2] -eq "-RunAs") {$RunAs = $UserName}  
              }
            Else {
              $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] Name {1} already in use! Please choose another one.`r`n" -f $Sessions[0].UserName, $UserName))
              $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
              $Sessions[$ii].Stream.Flush()
              }
            }
          Else {
            $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] Name {1} can't be set! Please choose another one.`r`n" -f $Sessions[0].UserName, $UserName))
            $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
            $Sessions[$ii].Stream.Flush()
            }
          }
        elseif ($cmd.split()[0] -eq "disconnect") {
          if ($Sessions[$ii].UserName -eq $RunAs) {
            $i3 = $cmd.split(" ")[1]
            If ($i3 -match "^\d+$") {
              If ($i3 -gt 0) {
                $i4 = $($Sessions.SID.IndexOf($($Sessions.where({$_.SID -eq $i3}).SID)))
                If ($i4 -gt 0) {
                  If ($i4 -ne $ii) {
                    If ($Sessions[$i4].UserName -notlike $null) {
                      $i3n = $Sessions[$i4].UserName
                      }
                    Else {
                      $i3n = $i3
                      }
                    $Sessions[$i4].SID      = 0
                    $Sessions[$i4].UserName = ""
                    $Sessions[$i4].Stream.Close(); $Sessions[$i4].Stream.Dispose()
                    $Sessions[$i4].Client.Close(); $Sessions[$i4].Client.Dispose()
                    $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] Disconnected.`r`n" -f $Sessions[0].UserName, $i3n))
                    $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
                    $Sessions[$ii].Stream.Flush()
                    }
                  Else {
                    $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] Please use exit to disconnect.`r`n" -f $Sessions[0].UserName, $i3n))
                    $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
                    $Sessions[$ii].Stream.Flush()
                    }
                  }
                Else {
                  $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] is either offline or NOT exist.`r`n" -f $Sessions[0].UserName, $i3))
                  $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
                  $Sessions[$ii].Stream.Flush()
                  }
                }
              }
            Else {
              $i4 = $($Sessions.UserName.IndexOf($($Sessions.where({$_.UserName -eq $i3}).UserName)))
              If ($i4 -gt 0) {
                If ($i4 -ne $ii) {
                  $Sessions[$i4].SID      = 0
                  $Sessions[$i4].UserName = ""
                  $Sessions[$i4].Stream.Close(); $Sessions[$i4].Stream.Dispose()
                  $Sessions[$i4].Client.Close(); $Sessions[$i4].Client.Dispose()
                  $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] Disconnected.`r`n" -f $Sessions[0].UserName, $i3))
                  $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
                  $Sessions[$ii].Stream.Flush()
                  }
                Else {
                  $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] Please use exit to disconnect.`r`n" -f $Sessions[0].UserName, $i3))
                  $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
                  $Sessions[$ii].Stream.Flush()
                  }
                }
              Else {
                $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] is either offline or NOT exist.`r`n" -f $Sessions[0].UserName, $i3))
                $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
                $Sessions[$ii].Stream.Flush()
                }
              }
            }
          }      
        ElseIf ($cmd -eq "whoami")                {
          If ($($Sessions[$ii].UserName) -notlike $null) {
            $whoami = $($Sessions[$ii].UserName)
            } 
          Else {
            $whoami = $($Sessions[$ii].SID)
            }
          $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] You're [{1}].`r`n" -f $Sessions[0].UserName, $whoami))
          $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
          $Sessions[$ii].Stream.Flush()
          }
        ElseIf ($cmd -eq "whoarehere")            {
          $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}]`r`n{1}" -f $Sessions[0].UserName, $($Sessions | Where-Object {$_.SID -gt 0} | Select-Object SID, UserName, LocalIP, RemoteIP, RemotePort | Format-Table | Out-String)))
          $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.length)
          $Sessions[$ii].Stream.Flush()
          }
        ElseIf ($cmd -eq "whoisincharge")         {
          $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] is in charge.`r`n" -f $Sessions[0].UserName, $RunAs))
          $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
          $Sessions[$ii].Stream.Flush()
          }
        ElseIf ($cmd -eq "status")                {
          $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}]`r`n{1}" -f $Sessions[0].UserName, $($Sessions[1..$($Sessions.Count-1)] | Format-Table | Out-String)))
          $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.length)
          $Sessions[$ii].Stream.Flush()
          }
        ElseIf ($cmd -eq "help")                  {
          $help = "
          @0 yourmessage_to_all
          @n yourmessage_to_n
          @name yourmessage_to_name
          callme yourname
          disconnect n
          disconnect name
          whoami
          whoarehere
          whoisincharge
          status
          help
          "
          $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}]`r`n{1}`r`n" -f $Sessions[0].UserName, $help))
          $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
          $Sessions[$ii].Stream.Flush()
          }
        ElseIf ($cmd -eq "option")                {
          $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] Work in progress, Come back later.`r`n" -f $Sessions[0].UserName))
          $Sessions[$ii].Stream.Write($Buffer,0,$Buffer.Length)
          $Sessions[$ii].Stream.Flush()
          }
        }
      #####
      If ($($Sessions[$ii].Client.Client.Poll(1,[System.Net.Sockets.SelectMode]::SelectRead)) -and ($($Sessions[$ii].Client.Client.Available) -eq 0)) {
        $Sessions[$ii].Client.Client.Shutdown([System.Net.Sockets.SocketShutdown]::Both)
        $Sessions[$ii].Client.Client.Close()
        Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] Connection {2}:{3} was closed remotely." -f $Sessions[0].UserName, $($Sessions[$ii].SID), $Sessions[$ii].RemoteIP, $Sessions[$ii].RemotePort)
        $Sessions[$ii].SID      = 0
        $Sessions[$ii].UserName = ""
        $Sessions[$ii].Stream.Close(); $Sessions[$ii].Stream.Dispose()
        $Sessions[$ii].Client.Close(); $Sessions[$ii].Client.Dispose()
        }
      #####
      }
    }
##########
  If ([Console]::KeyAvailable) { # $Host.UI.RawUI.KeyAvailable
    Write-Host -NoNewLine "> "
    $cmd = read-host
    If ($cmd -eq "exit") {$loop = $false} # Break
    Elseif ($cmd -ne "") {
      If ($cmd.substring(0,1) -eq "@") {
        $i3 = $cmd.substring(1).split(" ")[0]
        If ($i3 -match "^\d+$") {
          If ($i3 -gt 0) {
            $i4 = $($Sessions.SID.IndexOf($($Sessions.where({$_.SID -eq $i3}).SID)))
            If ($i4 -gt 0) {
              $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] $cmd`r`n" -f $Sessions[0].UserName))
              $Sessions[$i4].Stream.Write($Buffer,0,$Buffer.Length)
              $Sessions[$i4].Stream.Flush()
              }
            Else {
              Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [@{1}] is either offline or NOT exist." -f $Sessions[0].UserName, $i3)
              }
            }
          Else {
            For ($i5 = 1; $i5 -lt $($Sessions.Count); $i5++) {
              If ($($Sessions[$i5].SID) -ne 0) {
                $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] $cmd`r`n" -f $Sessions[0].UserName))
                $Sessions[$i5].Stream.Write($Buffer,0,$Buffer.Length)
                $Sessions[$i5].Stream.Flush()
                }
              }
            }
          }
        Else {
          $i4 = $($Sessions.UserName.IndexOf($($Sessions.where({$_.UserName -eq $i3}).UserName)))
          If ($i4 -gt 0) {
            $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] $cmd`r`n" -f $Sessions[0].UserName))
            $Sessions[$i4].Stream.Write($Buffer,0,$Buffer.Length)
            $Sessions[$i4].Stream.Flush()
            }
          Else {
            Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [@{1}] is either offline or NOT exist." -f $Sessions[0].UserName, $i3)
            }
          }
        }
      ElseIf ($cmd.split(" ")[0] -eq "disconnect") {
        $i3 = $cmd.split(" ")[1]
        If ($i3 -match "^\d+$") {
          If ($i3 -gt 0) {
            $i4 = $($Sessions.SID.IndexOf($($Sessions.where({$_.SID -eq $i3}).SID)))
            If ($i4 -gt 0) {
              If ($Sessions[$i4].UserName -notlike $null) {
                $i3n = $Sessions[$i4].UserName
                }
              Else {
                $i3n = $i3
                }
              $Sessions[$i4].SID      = 0
              $Sessions[$i4].UserName = ""
              $Sessions[$i4].Stream.Close(); $Sessions[$i4].Stream.Dispose()
              $Sessions[$i4].Client.Close(); $Sessions[$i4].Client.Dispose()
              Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] Disconnected" -f $i3n)
              }
            Else {
              Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] is either offline or NOT exist.`r`n" -f $Sessions[0].UserName, $i3)
              }
            }
          }
        Else {
          $i4 = $($Sessions.UserName.IndexOf($($Sessions.where({$_.UserName -eq $i3}).UserName)))
          If ($i4 -gt 0) {
            $Sessions[$i4].SID      = 0
            $Sessions[$i4].UserName = ""
            $Sessions[$i4].Stream.Close(); $Sessions[$i4].Stream.Dispose()
            $Sessions[$i4].Client.Close(); $Sessions[$i4].Client.Dispose()
            Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] Disconnected" -f $i3)
            }
          Else {
            Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] is either offline or NOT exist.`r`n" -f $Sessions[0].UserName, $i3)
            }
          }
        }
      ElseIf ($cmd -eq "whoisincharge")            {
        Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] [{1}] is in charge.`r`n" -f $Sessions[0].UserName, $RunAs)
        }
      ElseIf ($cmd -eq "status")                   {
        $Sessions | Format-Table
        }
      ElseIf ($cmd -eq "help")                     {
        $help = "
          @0 yourmessage_to_all
          @n yourmessage_to_n
          @name yourmessage_to_name
          [callme yourname [-RunAs]]
          disconnect n
          disconnect name
          [whoami]
          [whoarehere]
          whoisincharge
          status
          help
          "
        Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}]`r`n{1}`r`n" -f $Sessions[0].UserName, $help)
        }
      ElseIf ($cmd -eq "option")                   {
        Write-Host $("$(Get-Date -format "yyyy-MM-dd HH:mm:ss") [{0}] Work in progress, Come back later.`r`n" -f $Sessions[0].UserName)
        }
      }
    }
##########
  Start-Sleep -m 100
##########
  }
  }
Catch   {
  Write-Host $_ -ForegroundColor red
  }
Finally {
  For ($ii = 1; $ii -lt $($Sessions.count); $ii++) {
    If ($($Sessions[$ii].SID) -ne 0) {
      if ($($Sessions[$ii].Stream)) {$Sessions[$ii].Stream.Close(); $Sessions[$ii].Stream.Dispose()}
      if ($($Sessions[$ii].Client)) {$Sessions[$ii].Client.close(); $Sessions[$ii].Client.Dispose()}
      }
    }
  $socket.Stop()
  }

  }

<##################################################################################################>

Function Start-KCSClient() {

param (
  [parameter(Mandatory)]
  [String]
  $RemoteHost,

  [Int]
  $Port = 23
  )

if ($RemoteHost -match ":") {
  $Port       = $RemoteHost.Split(':')[1]
  $RemoteHost = $RemoteHost.Split(':')[0]
  }

if ([String]::IsNullOrEmpty($RemoteHost)) {
  Write-Host -Object "Error: Invalid host address (null or empty)." -ForegroundColor Red
  return
  }
  
Try     {
$Host.UI.RawUI.FlushInputBuffer()
$Host.UI.RawUI.WindowTitle = "KCSClient"

$Socket = New-Object System.Net.Sockets.TcpClient # ($RemoteHost, $Port)

do {
  Try   {$Socket.Connect($RemoteHost, $Port)}
  Catch {
    Write-Host $("Can't connect to Host {0} on port {1}." -f $RemoteHost, $Port) -ForegroundColor Red
    Write-Host "$_.Exception.Message" -ForegroundColor Cyan
    Start-Sleep -m 100
    }
  } While (-not $Socket.Connected)
$Stream = $Socket.GetStream()

While ($Socket.Connected) {
  #####
  If ($Stream.DataAvailable) {
    $buffer = new-object System.Byte[] 1024
    $recvlines = ""; do {
      $recvlines += $([Text.Encoding]::ASCII.GetString($buffer, 0, $($stream.Read($buffer, 0, $buffer.Length))))
      } While ($Stream.DataAvailable)
    Write-Host -NoNewLine $recvlines
    }
  #####
  If ($($Socket.Client.Poll(1,[System.Net.Sockets.SelectMode]::SelectRead)) -and $($Socket.Client.Available -eq 0)) {
    $Socket.Client.Shutdown([System.Net.Sockets.SocketShutdown]::Both)
    $Socket.Client.Close()
    Write-Host "$(Get-Date -format "yyyy-MM-dd HH:mm:ss") Connection was closed remotely."
    $Stream.Close(); $Stream.Dispose()
    $Socket.Close(); $socket.Dispose()
    }
  #####
  If ([Console]::KeyAvailable) { # $Host.UI.RawUI.KeyAvailable
    Write-Host -NoNewline "> "
    $cmd = Read-Host
    if ($cmd -eq "exit") {
      Write-Host "$(Get-Date -format "yyyy-MM-dd HH:mm:ss") Disconnected."
      break
      }
    elseif ($cmd -ne "") {
      $Buffer = [System.Text.Encoding]::ASCII.GetBytes($("$cmd`r`n"))
      $Stream.Write($Buffer,0,$Buffer.length)
      $Stream.Flush()
      }
    }
  #####
  Start-Sleep -m 100
  #####
  }
  }
Catch   {
  Write-Host $_ -ForegroundColor red
  }
Finally {
  if($Stream) {$Stream.Close(); $Stream.Dispose()}
  if($Socket) {$Socket.Close(); $socket.Dispose()}
  }

  }