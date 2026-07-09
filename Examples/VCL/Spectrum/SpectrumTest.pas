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
    FRenderer: TCanvasSpectrumRenderer;
    FBars: TArray<Single>;
    FPhase: Double;
  FSource : TFileSignalSource;
  FEngine : TAuroraSpectrumEngine;
  FTempBuffer : TArray<Single>;
  FDisplayProcessor: TDisplayProcessor;
  FDisplayFrame: TDisplayFrame;

    procedure GenerateDemoBars;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Style: TSpectrumStyle;
begin

TimerSpectrum.Enabled := False;
CoInitialize(nil);
MFStartup(MF_VERSION, MFSTARTUP_FULL);
//SetLength(FTempBuffer, 1024);

FSource :=
  TFileSignalSource.Create(
    'D:\Music_At_Work\MacThuy\MacThuy_Bi\ChieuTim.wav');

SetLength(FTempBuffer, 1024 * FSource.ChannelCount);

{
FEngine :=
  TAuroraSpectrumEngine.Create(
    FSource.SampleRate,
    2048,
    80);

 //exit;  }


FEngine :=
    TAuroraSpectrumEngine.Create(
      FSource.SampleRate,
      2048,
      80);

FDisplayProcessor := TDisplayProcessor.Create(80);
FDisplayFrame := TDisplayFrame.Create(80);

  FRenderer := TCanvasSpectrumRenderer.Create;

  Style := TSpectrumStyle.Default;
  Style.BarColor := $00C8FF80;
  Style.BackgroundColor := clBlack;
  Style.BarSpacing := 3;
  Style.BarStyle := TSpectrumBarStyle.Blocks;
  Style.BlockHeight := 5;
  Style.BlockSpacing := 2;

  FRenderer.Style := Style;

  DoubleBuffered := True;
  Color := clBlack;

TimerSpectrum.Interval := 16;
TimerSpectrum.Enabled := True;

end;

procedure TForm1.GenerateDemoBars;
var
  Index: Integer;
  X: Double;
  Envelope: Double;
  Wave1: Double;
  Wave2: Double;
begin
  FPhase := FPhase + 0.08;

  for Index := 0 to High(FBars) do
  begin
    X := Index / Max(1, High(FBars));

    Envelope := Power(1.0 - X, 0.65);
    Wave1 := 0.5 + 0.5 * Sin(FPhase + Index * 0.23);
    Wave2 := 0.5 + 0.5 * Sin(FPhase * 1.7 + Index * 0.071);

    FBars[Index] := Single(Envelope * (0.15 + 0.65 * Wave1 * Wave2));

    if FBars[Index] > 1.0 then
      FBars[Index] := 1.0;
  end;
end;

procedure TForm1.PaintBoxSpectrumPaint(Sender: TObject);
begin
  PaintBoxSpectrum.Canvas.Brush.Color := clRed;
  PaintBoxSpectrum.Canvas.FillRect(PaintBoxSpectrum.ClientRect);

  if (FRenderer = nil) or (FEngine = nil) then
    Exit;

 { FRenderer.RenderFrame(
    PaintBoxSpectrum.Canvas,
    PaintBoxSpectrum.ClientRect,
    FEngine.CurrentFrame
  );    }

FRenderer.Render(
  PaintBoxSpectrum.Canvas,
  PaintBoxSpectrum.ClientRect,
  @FDisplayFrame.Bars[0],
  FDisplayFrame.BarCount
);

end;

procedure TForm1.TimerSpectrumTimer(Sender: TObject);
var
  FramesRead: Integer;
  HadFrame: Boolean;
begin
// Caption := 'Timer running ' + TimeToStr(Now);
  FramesRead := FSource.Read(@FTempBuffer[0], 1024);

  if FramesRead <= 0 then
  begin
    TimerSpectrum.Enabled := False;
    Caption := 'EOF';
    Exit;
  end;

  FEngine.PushInterleavedFloat32(
    @FTempBuffer[0],
    FramesRead,
    FSource.ChannelCount
  );

  HadFrame := False;

  while FEngine.TryProcessFrame do
    HadFrame := True;

  if HadFrame then
  begin
    Caption := Format(
      'Frame=%d Peak=%.3f RMS=%.3f',
      [
        FEngine.CurrentFrame.TimeStamp,
        FEngine.CurrentFrame.Peak,
        FEngine.CurrentFrame.RMS
      ]
    );

    //PaintBoxSpectrum.Invalidate;

    FDisplayProcessor.Process(
    FEngine.CurrentFrame,
    FDisplayFrame
    );

   PaintBoxSpectrum.Invalidate;

  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
FDisplayProcessor.Free;
FRenderer.Free;
FEngine.Free;
FSource.Free;
MFShutdown;
CoUninitialize;



end;

end.
