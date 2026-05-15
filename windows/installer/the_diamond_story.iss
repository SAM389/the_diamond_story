; Inno Setup script for The Diamond Story
; Build the Windows release first, then compile this script.

#ifndef MyAppId
	#define MyAppId "the_diamond_story"
#endif
#ifndef MyAppName
	#define MyAppName "The Diamond Story"
#endif
#ifndef MyAppVersion
	#define MyAppVersion "1.0.0"
#endif
#ifndef MyAppPublisher
	#define MyAppPublisher "TheDiamondStorySetup"
#endif
#ifndef MyAppExeName
	#define MyAppExeName "the_diamond_story.exe"
#endif
#ifndef MyReleaseDir
	#define MyReleaseDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
LicenseFile=license.txt
DefaultDirName={localappdata}\Programs\{#MyAppName}
UsePreviousAppDir=no
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=no
OutputDir=..\..\dist\installer
OutputBaseFilename=TheDiamondStorySetup-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "{#MyReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs restartreplace

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
var
	ResultCode: Integer;
begin
	Exec(ExpandConstant('{cmd}'), '/C taskkill /F /IM the_diamond_story.exe /T >NUL 2>&1', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
	Result := True;
end;
