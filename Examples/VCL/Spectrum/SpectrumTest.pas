unit SpectrumTest;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  System.Math,
  Aurora.Visual.Types,
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
  SetLength(FBars, 80);

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
FRenderer.Render(
  PaintBoxSpectrum.Canvas,
  PaintBoxSpectrum.ClientRect,
  @FBars[0],
  Length(FBars)
);
end;

procedure TForm1.TimerSpectrumTimer(Sender: TObject);
begin
GenerateDemoBars;
PaintBoxSpectrum.Invalidate;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
FRenderer.Free;
end;

end.
