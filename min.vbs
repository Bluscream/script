Option Explicit

' Check if at least one argument is provided
If WScript.Arguments.Count < 1 Then
    MsgBox "Please provide the full path of the executable as the first argument.", vbExclamation
    WScript.Quit
End If

' Retrieve the executable path from the first argument
Dim strExecutablePath
strExecutablePath = WScript.Arguments(0)

' Initialize the arguments string
Dim strArguments
strArguments = ""

' Concatenate additional arguments provided beyond the executable path
If WScript.Arguments.Count > 1 Then
    Dim i
    For i = 1 To WScript.Arguments.Count - 1
        If WScript.Arguments(i) <> strExecutablePath Then
            If strArguments <> "" Then
                strArguments = strArguments & " "
            End If
            strArguments = strArguments & WScript.Arguments(i)
        End If
    Next
End If

' Run the executable
CreateObject("WScript.Shell").Run """" & strExecutablePath & """ " & strArguments, 0, False

If Err.Number <> 0 Then
    MsgBox "An error occurred while running the executable:", vbCritical
    MsgBox "Error code: " & Err.Number & ", Description: " & Err.Description, vbCritical
End If
