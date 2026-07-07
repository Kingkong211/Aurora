program Test_MFDecoder;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  WinApi.ActiveX,
  WinApi.MediaFoundationApi.MfApi,
  Aurora.Core.Buffer in '..\..\Source\Core\Aurora.Core.Buffer.pas',
  Aurora.Core.Types in '..\..\Source\Core\Aurora.Core.Types.pas',
  Aurora.Audio.Types in '..\..\Source\Audio\Aurora.Audio.Types.pas',
  Aurora.Audio.MediaFoundation.Types in '..\..\Source\Audio\MediaFoundation\Aurora.Audio.MediaFoundation.Types.pas',
  Aurora.Audio.MediaFoundation.Decoder in '..\..\Source\Audio\MediaFoundation\Aurora.Audio.MediaFoundation.Decoder.pas';

var
  Decoder: TMFAudioDecoder;
  Buffer: TSignalBuffer;
  FileName: string;

begin
  try
    if ParamCount < 1 then
    begin
      Writeln('Usage: Test.MFDecoder.exe <audio-file>');
      Exit;
    end;

    FileName := ParamStr(1);

   // OleCheck(CoInitializeEx(nil, COINIT_MULTITHREADED));
   //CoInitialize(nil);
   if Failed(CoInitialize(nil)) then
  raise Exception.Create('CoInitialize failed.');
    try
     // OleCheck(MFStartup(MF_VERSION, MFSTARTUP_FULL));
     if Failed(MFStartup(MF_VERSION, MFSTARTUP_FULL)) then
  raise Exception.Create('MFStartup failed.');
      try
        Decoder := TMFAudioDecoder.Create;
        try
          Decoder.OpenFile(FileName);
          Buffer := Decoder.DecodeAll;
          try
            Writeln('Decoded OK');
            Writeln('File        : ', Decoder.Info.FileName);
            Writeln('SampleRate  : ', Decoder.Info.Audio.Signal.SampleRate);
            Writeln('Channels    : ', Decoder.Info.Audio.Signal.ChannelCount);
            Writeln('Samples     : ', Buffer.SampleCount);
            Writeln('Scalars     : ', Buffer.ScalarCount);
          finally
            Buffer.Free;
          end;
        finally
          Decoder.Free;
        end;
      finally
        MFShutdown;
      end;
    finally
      CoUninitialize;
    end;
  except
    on E: Exception do
    begin
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.