unit SpectrumTest;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  System.Math,
  Aurora.Visual.Types,
  Aurora.Audio.FileSignalSource,
  Aurora.Engine,
  Winapi.ActiveX,
  Aurora.Visual.Frame,
  Aurora.Visual.Runtime,
  Aurora.Visual.DisplayProcessor,
  WinApi.MediaFoundationApi.MfApi,
  Aurora.Visual.CanvasSpectrum;

type
  TForm1 = class(TForm)
    PaintBoxSpectrum: TPaintBox;
    TimerSpectrum: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerSpectrumTimer(Sender: TObject);
    procedure PaintBoxSpectrumPaint(Sender: TObject);
  private
    { Private declarations }
FSource: TFileSignalSource;
FTempBuffer: TArray<Single>;
FAurora: TAuroraVisualRuntime;


   // procedure GenerateDemoBars;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  TimerSpectrum.Enabled := False;

  CoInitialize(nil);
  MFStartup(MF_VERSION, MFSTARTUP_FULL);

  FSource :=
    TFileSignalSource.Create(
      'D:\Music_At_Work\MacThuy\MacThuy_Bi\ChieuTim.wav'
    );

  SetLength(FTempBuffer, 1024 * FSource.ChannelCount);

  FAurora :=
    TAuroraVisualRuntime.Create(
      FSource.SampleRate,
      2048,
      80
    );

  FAurora.SetTheme(TSpectrumThemePreset.OkaraDark);

  DoubleBuffered := True;
  Color := clBlack;

  TimerSpectrum.Interval := 16;
  TimerSpectrum.Enabled := True;
end;


procedure TForm1.PaintBoxSpectrumPaint(Sender: TObject);
begin
  if FAurora = nil then
    Exit;

  FAurora.Render(
    PaintBoxSpectrum.Canvas,
    PaintBoxSpectrum.ClientRect
  );
end;


procedure TForm1.TimerSpectrumTimer(Sender: TObject);
var
  FramesRead: Integer;
begin
  if (FSource = nil) or (FAurora = nil) then
    Exit;

  if Length(FTempBuffer) = 0 then
    Exit;

  FramesRead :=
    FSource.Read(
      @FTempBuffer[0],
      1024
    );

  if FramesRead <= 0 then
  begin
    TimerSpectrum.Enabled := False;
    Caption := 'EOF';
    Exit;
  end;

  FAurora.PushInterleavedFloat32(
    FTempBuffer,
    FramesRead,
    FSource.ChannelCount
  );

  {
  if FAurora.Process then
  begin
    Caption := Format(
      'Frame=%d Peak=%.3f RMS=%.3f',
      [
        FAurora.Engine.CurrentFrame.TimeStamp,
        FAurora.Engine.CurrentFrame.Peak,
        FAurora.Engine.CurrentFrame.RMS
      ]
    );

    PaintBoxSpectrum.Invalidate;
  end;    }
 if FAurora.ProcessAvailableFrames then
begin
  Caption := Format(
    'Frame=%d Peak=%.3f RMS=%.3f',
    [
      FAurora.Engine.CurrentFrame.TimeStamp,
      FAurora.Engine.CurrentFrame.Peak,
      FAurora.Engine.CurrentFrame.RMS
    ]
  );

  PaintBoxSpectrum.Invalidate;
end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TimerSpectrum.Enabled := False;

  FAurora.Free;
  FSource.Free;

  MFShutdown;
  CoUninitialize;
end;

end.
