#define MyAppName "EasySpeech2Text"
#define MyAppVersion "1.0"
#define MyAppPublisher "akaki411"
#define MyAppExeName "EasySpeech2Text.exe"

[Setup]
AppId={{83A24A75-0986-4DC3-BEFF-ACD45A2DA292}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}

PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline dialog

DefaultDirName={localappdata}\{#MyAppName}

UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
OutputBaseFilename=easy-speech-2-text-setup
SetupIconFile=ui/resources/icons/icon.ico
SolidCompression=yes
WizardStyle=modern
Compression=lzma2/ultra64

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "dist\EasySpeech2Text\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\EasySpeech2Text\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent