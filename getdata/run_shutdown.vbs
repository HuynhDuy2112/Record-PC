Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

WshShell.Run "cmd /c ""C:\ProgramData\WinRC\src\post.bat""", 0, True
If FSO.FileExists("C:\ProgramData\WinRC\src\post.success.txt") Then
    WshShell.Run "wscript.exe ""C:\ProgramData\WinRC\src\remove.vbs""", 0, True
End If
