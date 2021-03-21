# KChat
As an exercise using PowerShell to implement a command-line chat program.
In a PowerShell Window, Change the directory to the location where the PowerShell script KCSTcpServerClient_v1.0.15.ps1 is, and enter
. .\KCSTcpServerClient_v1.0.15.ps1
On "Server" side, execute Start-KCSServer 9999 # any port number
On "Client" side, execute Start-KCSClient "RemoteHost" 9999 # or "RemoteHost:9999", where RemoteHost is the Host or IP where "Server" is started.
Enter Help to show the Help Menu.
Operation: 
> @n your message
> @name your message
to send your message to any particular session
> @0 your message to all
session id was originally used, use:
> callme yourname
to identify yourself.
To see who is online:
> whoarehere
