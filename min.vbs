Option Explicit

' Check if at least one argument is provided
If WScript.Arguments.Count < 1 Then
    MsgBox "Please provide the full path of the executable as the first argument."
    WScript.Quit
End If

' Retrieve the executable path from the first argument
Dim strExecutablePath
strExecutablePath = WScript.Arguments(0)

' Initialize the arguments string
Dim strArguments
strArguments = ""

' Declare the loop counter variable
Dim i

' Concatenate additional arguments provided beyond the executable path
If WScript.Arguments.Count > 1 Then
    For i = 1 To WScript.Arguments.Count - 1
        ' Correctly concatenate arguments
        strArguments = strArguments & " " & WScript.Arguments(i)
    Next
End If

' Run the executable with /MIN switch to start minimized
CreateObject("WScript.Shell").Run Chr(34) & strExecutablePath & Chr(34) & " " & strArguments, 9
