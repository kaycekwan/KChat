# KChat
As an exercise using PowerShell to implement a multiple-client command-line chat program.
To Run, in a PowerShell Window, Change the directory to the location where the PowerShell script KCSTcpServerClient_v1.0.15.ps1 is, and enter
. .\KCSTcpServerClient_v1.0.15.ps1
As a Server, execute Start-KCSServer 9999 # any port number
As a Client, execute Start-KCSClient "RemoteHost" 9999 # or "RemoteHost:9999", where RemoteHost is the Host or IP where "Server" is started.
Enter Help to show the Help Menu.
To send your message to any particular session: 
> @n your message
> @0 your message to all
session id was originally used, use:
> callme yourname
to identify yourself.
then use:
> @name your message
To see who is online:
> whoarehere
To see who am i:
> whoami
