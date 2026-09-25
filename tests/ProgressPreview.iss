[Setup]
AppName=Suite Progress Preview
AppVersion=0.2.1
CreateAppDir=no
Uninstallable=no
DefaultDirName={tmp}\SuiteProgressPreview
PrivilegesRequired=lowest
OutputDir=..\dist\tests
OutputBaseFilename=ProgressPreview
WizardStyle=modern
DisableWelcomePage=yes
DisableReadyPage=yes
[Files]
Source: "Simulate-Progress.ps1"; Flags: dontcopy
Source: "..\installer\Progress.ps1"; Flags: dontcopy
[Code]
#include "..\installer\ProgressUI.iss"
procedure InitializeWizard;
begin
  InitializeSuiteProgress;
end;
procedure Require(Value: Boolean; MessageText: String);
begin
  if not Value then RaiseException(MessageText);
end;
procedure CurStepChanged(CurStep: TSetupStep);
var Code: Integer; Params: String;
begin
  if CurStep = ssPostInstall then
  begin
    BeginSuiteProgress;
    try
      SuiteOutput('ATS_PROGRESS|bad|active|0|-1', False, False);
      SuiteOutput('ATS_PROGRESS|1|active|-3|10', False, False);
      SuiteOutput('ATS_PROGRESS|6|done|0|-1', False, False);
      Require(StageStates[1] = 'pending', 'Malformed or out-of-order event accepted');
      SuiteOutput('ATS_PROGRESS|1|active|1048576|-1', False, False);
      Require(SuiteProgress.ProgressBar.Style = npbstMarquee, 'Unknown size must animate');
      SuiteOutput('ATS_PROGRESS|1|active|1048576|4194304', False, False);
      Require(SuiteProgress.ProgressBar.Position = 25, 'Wrong measured percentage');
      Require(not FinishSuiteProgress(0), 'Premature success accepted');
      SuiteProgress.ProgressBar.State := npbsNormal;
      ExtractTemporaryFile('Simulate-Progress.ps1');
      ExtractTemporaryFile('Progress.ps1');
      Params := '-NoProfile -ExecutionPolicy Bypass -File "' + ExpandConstant('{tmp}\Simulate-Progress.ps1') + '"';
      if ExpandConstant('{param:fail|0}') = '1' then Params := Params + ' -Fail';
      if not ExecAndLogOutput(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Params, '', SW_SHOWNORMAL, ewWaitUntilTerminated, Code, @SuiteOutput) then RaiseException('Preview process failed');
      if ExpandConstant('{param:fail|0}') = '1' then
      begin
        Require(not FinishSuiteProgress(Code), 'Failure accepted as completion');
        Require(StageStates[5] = 'pending', 'Later stage marked complete after failure');
      end
      else begin
        Require(FinishSuiteProgress(Code), 'Successful sequence not completed');
        Require(not FinishSuiteProgress(1), 'Nonzero process result ignored');
        FinishSuiteProgress(Code);
      end;
      Log('PROGRESS_PREVIEW_PASS');
      if not WizardSilent then MsgBox('Preview passed. No applications were installed.', mbInformation, MB_OK);
    finally SuiteProgress.Hide; end;
  end;
end;
