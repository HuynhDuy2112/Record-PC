Option Explicit

Dim fso, baseFolder, subFolder
Dim today, folderName, datePattern

Set fso = CreateObject("Scripting.FileSystemObject")

baseFolder = "C:\ProgramData\WinRC"

' dd-MM-yyyy
today = Year(Now)
today = Right("0" & Day(Now), 2) & "-" & Right("0" & Month(Now), 2) & "-" & Year(Now)

If Not fso.FolderExists(baseFolder) Then
    WScript.Quit
End If

Dim folder, subFolders
Set folder = fso.GetFolder(baseFolder)
Set subFolders = folder.SubFolders  

For Each subFolder In subFolders
    folderName = subFolder.Name

    Dim regEx
    Set regEx = New RegExp
    regEx.Pattern = "^\d{2}-\d{2}-\d{4}$"
    regEx.IgnoreCase = True

    If regEx.Test(folderName) Then
        If folderName <> today Then
            On Error Resume Next
            fso.DeleteFolder baseFolder & "\" & folderName, True
            On Error GoTo 0
        End If
    End If
Next
