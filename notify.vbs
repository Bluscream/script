Set objShell = CreateObject("WScript.Shell")

' Path to the batch file
strBatchPath = "C:\Scripts\notify.bat"

' Get the remaining arguments
strArgs = ""
For i = 1 To WScript.Arguments.Count - 1
    strArgs = strArgs & " " & WScript.Arguments(i)
Next

' Run the batch file silently
objShell.Run Chr(34) & strBatchPath & Chr(34) & strArgs, 0, False

Set objShell = Nothing
