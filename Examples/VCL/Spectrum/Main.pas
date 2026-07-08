unit Main;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Aurora.Visual.Types,
  Aurora.Visual.CanvasSpectrum;

type
  TfrmMain = class(TForm)
  private
    FPaintBox: TPaintBox;
    FTimer: TTimer;
    FRenderer: TCanvasSpectrumRenderer;
    FBars: TArray<Single>;
    FPhase: Double;

    procedure OnTimer(Sender: TObject);
    procedure OnPaint(Sender: TObject);
    procedure GenerateDemoBars;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

constructor TfrmMain.Create(AOwner: TComponent);
var
  Style: TSpectrumStyle;
begin
  inherited;

  Caption := 'Aurora Spectrum Example';
  Width := 900;
  Height := 420;
  Color := clBlack;
  DoubleBuffered := True;

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

  FPaintBox := TPaintBox.Create(Self);
  FPaintBox.Parent := Self;
  FPaintBox.Align := alClient;
  FPaintBox.OnPaint := OnPaint;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 16;
  FTimer.OnTimer := OnTimer;
  FTimer.Enabled := True;
end;

destructor TfrmMain.Destroy;
begin
  FRenderer.Free;
  inherited;
end;

procedure TfrmMain.GenerateDemoBars;
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

procedure TfrmMain.OnTimer(Sender: TObject);
begin
  GenerateDemoBars;
  FPaintBox.Invalidate;
end;

procedure TfrmMain.OnPaint(Sender: TObject);
begin
  FRenderer.Render(
    FPaintBox.Canvas,
    FPaintBox.ClientRect,
    @FBars[0],
    Length(FBars)
  );
end;

end.