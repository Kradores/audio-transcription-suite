#ifndef SuiteRoot
  #define SuiteRoot ".."
#endif
#ifndef Gpu
  #define Gpu "Nvidia"
#endif
[Setup]
AppId={{852B60B4-72C7-4DD2-A3CE-02E2FE29C4C0}
AppName=Audio Transcription Suite
AppVersion=0.1.0
DefaultDirName={localappdata}\Programs\AudioTranscriptionSuite
PrivilegesRequired=lowest
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
WizardStyle=modern
DisableProgramGroupPage=yes
OutputDir={#SuiteRoot}\dist
OutputBaseFilename=AudioTranscriptionSuite-{#Gpu}-Setup-0.1.0
Compression=lzma2/fast
SolidCompression=no
DiskSpanning=no
SetupLogging=yes
UninstallDisplayIcon={app}\CoreMcp.Server.exe
#if Gpu == "Amd"
InfoBeforeFile=SetupNotes-Amd.txt
#else
InfoBeforeFile=SetupNotes.txt
#endif

[Files]
Source: "{#SuiteRoot}\CoreMcp.Server.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "Configure-Claude.ps1"; DestDir: "{app}\installer"; Flags: ignoreversion
Source: "Install-Dependencies.ps1"; DestDir: "{app}\installer"; Flags: ignoreversion
Source: "{#SuiteRoot}\AudioTranscriptionService-{#Gpu}-Setup-0.1.0.exe"; DestDir: "{tmp}\suite-payload"; DestName: "AudioTranscriptionService-Setup.exe"; Flags: deleteafterinstall nocompression

[Code]
var
  DatabasePage: TInputFileWizardPage;
  SetupFailed: Boolean;

procedure InitializeWizard;
begin
  DatabasePage := CreateInputFilePage(wpSelectDir, 'Transcript database',
    'Choose the database used by Audio Transcription Service.',
    'The default matches a new installation. If you customized database.path in the service configuration, select that location. The database does not have to exist yet.');
  DatabasePage.Add('Transcript database:', 'SQLite database|*.db|All files|*.*', '.db');
  DatabasePage.Values[0] := ExpandConstant('{localappdata}\AudioTranscriptionService\data\transcripts.db');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = DatabasePage.ID then
    if (Length(DatabasePage.Values[0]) < 3) or (Pos('"', DatabasePage.Values[0]) > 0) or
      ((Copy(DatabasePage.Values[0], 2, 2) <> ':\') and (Copy(DatabasePage.Values[0], 1, 2) <> '\\')) then
    begin
      MsgBox('Enter an absolute database path.', mbError, MB_OK);
      Result := False;
    end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ExitCode: Integer;
  Params, LogPath: String;
begin
  if CurStep = ssPostInstall then
  begin
    WizardForm.StatusLabel.Caption := 'Installing Audio Transcription Service and latest Claude. This may take several minutes...';
    LogPath := ExpandConstant('{localappdata}\AudioTranscriptionSuite\logs\setup.log');
    Params := '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\installer\Install-Dependencies.ps1') +
      '" -PayloadDirectory "' + ExpandConstant('{tmp}\suite-payload') + '" -ServerPath "' + ExpandConstant('{app}\CoreMcp.Server.exe') +
      '" -DatabasePath "' + DatabasePage.Values[0] + '" -LogPath "' + LogPath + '"';
    if not Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Params, '', SW_HIDE, ewWaitUntilTerminated, ExitCode) then
      SetupFailed := True
    else
      SetupFailed := ExitCode <> 0;
    if SetupFailed then
      MsgBox('Suite setup is incomplete. See ' + LogPath + ' for the error, then run setup again. Installed components have been retained.', mbError, MB_OK);
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
    if SetupFailed then
    begin
      WizardForm.FinishedHeadingLabel.Caption := 'Setup incomplete';
      WizardForm.FinishedLabel.Caption := 'One or more steps failed. Check the setup log in your local app-data AudioTranscriptionSuite\logs folder, resolve the error, and run setup again.';
    end
    else
      WizardForm.FinishedLabel.Caption := 'Audio Transcription Service, CoreMcp, and Claude are installed and configured. Start Audio Transcription Service from the Start menu to create the database and record transcripts, then open Claude.';
end;

function GetCustomSetupExitCode: Integer;
begin
  if SetupFailed then Result := 1 else Result := 0;
end;
