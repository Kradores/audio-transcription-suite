var
  SuiteProgress: TOutputProgressWizardPage;
  StageLabels: array[0..6] of TNewStaticText;
  StageNames: array[0..6] of String;
  StageStates: array[0..6] of String;
  ActiveStage: Integer;
  ProgressFailed: Boolean;

procedure InitializeSuiteProgress;
var I: Integer;
begin
  StageNames[0] := 'Installing MCP Server and preparing files';
  StageNames[1] := 'Downloading Claude';
  StageNames[2] := 'Verifying Claude download';
  StageNames[3] := 'Waiting for administrator approval';
  StageNames[4] := 'Installing Claude';
  StageNames[5] := 'Installing Audio Transcription Service';
  StageNames[6] := 'Updating Claude configuration';
  SuiteProgress := CreateOutputProgressPage('Installing Audio Transcription Suite', 'Progress for the current step');
  for I := 0 to 6 do
  begin
    StageLabels[I] := TNewStaticText.Create(WizardForm);
    StageLabels[I].Parent := SuiteProgress.Surface;
    StageLabels[I].SetBounds(0, ScaleY(54 + I * 20), SuiteProgress.SurfaceWidth, ScaleY(19));
    StageLabels[I].AutoSize := False;
    StageLabels[I].Caption := '    ' + StageNames[I];
    StageStates[I] := 'pending';
  end;
  SuiteProgress.ProgressBar.Top := ScaleY(204);
  SuiteProgress.ProgressBar.Max := 100;
end;

procedure BeginSuiteProgress;
begin
  StageStates[0] := 'done';
  StageLabels[0].Caption := #$2713 + ' ' + StageNames[0];
  ActiveStage := 1;
  ProgressFailed := False;
  SuiteProgress.SetText('Starting component installation...', '');
  SuiteProgress.ProgressBar.Visible := True;
  SuiteProgress.ProgressBar.Style := npbstMarquee;
  SuiteProgress.Show;
end;

procedure SuiteOutput(const S: String; const Error, FirstLine: Boolean);
var
  Parts: TStringList;
  Stage: Integer;
  Received, Total: Int64;
  State, Detail: String;
begin
  Log(S);
  if Error then begin ProgressFailed := True; Exit; end;
  if Copy(S, 1, 13) <> 'ATS_PROGRESS|' then Exit;
  Parts := TStringList.Create;
  try
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := S;
    if Parts.Count <> 5 then Exit;
    Stage := StrToIntDef(Parts[1], -1);
    State := Parts[2];
    Received := StrToInt64Def(Parts[3], -2);
    Total := StrToInt64Def(Parts[4], -2);
    if (Stage < 1) or (Stage > 6) or (Received < 0) or (Total < -1) then Exit;
    if (Total >= 0) and (Received > Total) then Exit;
    if (State <> 'active') and (State <> 'done') and (State <> 'failed') then Exit;
    if ProgressFailed or (Stage < ActiveStage) then Exit;
    if Stage > ActiveStage then
    begin
      if (Stage <> ActiveStage + 1) or (StageStates[ActiveStage] <> 'done') then Exit;
    end;
    if (StageStates[Stage] = 'done') and (State <> 'failed') then Exit;
    ActiveStage := Stage;
    StageStates[Stage] := State;
    Detail := '';
    SuiteProgress.ProgressBar.Style := npbstMarquee;
    if State = 'failed' then
    begin
      ProgressFailed := True;
      StageLabels[Stage].Caption := 'X ' + StageNames[Stage] + ' - failed';
      SuiteProgress.ProgressBar.Style := npbstNormal;
      SuiteProgress.ProgressBar.Position := 0;
      SuiteProgress.ProgressBar.State := npbsError;
    end
    else if State = 'done' then
      StageLabels[Stage].Caption := #$2713 + ' ' + StageNames[Stage]
    else
    begin
      StageLabels[Stage].Caption := '> ' + StageNames[Stage];
      if Stage = 1 then
      begin
        Detail := Format('%.1f MB downloaded', [Received / 1048576.0]);
        if (Total > 0) and (Received <= Total) then
        begin
          SuiteProgress.ProgressBar.Style := npbstNormal;
          SuiteProgress.ProgressBar.Position := Round(Received * 100.0 / Total);
          Detail := Format('%d%% - %.1f / %.1f MB', [SuiteProgress.ProgressBar.Position, Received / 1048576.0, Total / 1048576.0]);
        end;
      end;
    end;
    SuiteProgress.SetText(StageNames[Stage], Detail);
  finally
    Parts.Free;
  end;
end;

function FinishSuiteProgress(ExitCode: Integer): Boolean;
var I: Integer;
begin
  Result := (ExitCode = 0) and not ProgressFailed and (StageStates[6] = 'done');
  SuiteProgress.ProgressBar.Style := npbstNormal;
  if Result then
  begin
    for I := 0 to 6 do StageLabels[I].Caption := #$2713 + ' ' + StageNames[I];
    SuiteProgress.ProgressBar.State := npbsNormal;
    SuiteProgress.SetText('Installation complete', 'All components installed and configured.');
    SuiteProgress.ProgressBar.Position := 100;
  end
  else
  begin
    StageLabels[ActiveStage].Caption := 'X ' + StageNames[ActiveStage] + ' - failed';
    SuiteProgress.SetText('Setup incomplete: ' + StageNames[ActiveStage], 'See the setup log for details.');
    SuiteProgress.ProgressBar.Position := 0;
    SuiteProgress.ProgressBar.State := npbsError;
  end;
end;
