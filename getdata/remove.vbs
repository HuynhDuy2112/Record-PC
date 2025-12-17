Option Explicit

Dim fso, baseFolder, subFolder
Dim folderName

Set fso = CreateObject("Scripting.FileSystemObject")

baseFolder = "C:\ProgramData\WinRC"

If Not fso.FolderExists(baseFolder) Then
    WScript.Quit
End If

Dim folder, subFolders
Set folder = fso.GetFolder(baseFolder)
Set subFolders = folder.SubFolders  

Dim regEx
Set regEx = New RegExp
regEx.Pattern = "^\d{2}-\d{2}-\d{4}$"
regEx.IgnoreCase = True

For Each subFolder In subFolders
    folderName = subFolder.Name

    ' Nếu đúng format dd-MM-yyyy thì xóa
    If regEx.Test(folderName) Then
        On Error Resume Next
        fso.DeleteFolder subFolder.Path, True
        On Error GoTo 0
    End If
Next
