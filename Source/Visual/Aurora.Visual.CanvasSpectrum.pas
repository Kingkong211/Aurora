unit Aurora.Visual.CanvasSpectrum;

interface

uses
  System.SysUtils,
  System.Types,
  System.Math,
  Vcl.Graphics,
  Aurora.Visual.Types,
  Aurora.Visual.Frame;

type
  TCanvasSpectrumRenderer = class
  private
    FStyle: TSpectrumStyle;
    FBackBuffer: TBitmap;

    procedure EnsureBackBuffer(
      const AWidth: Integer;
      const AHeight: Integer
    );

    procedure ClearCanvas(
      const ACanvas: TCanvas;
      const ARect: TRect
    );

    function Clamp01(
      const AValue: Single
    ): Single;

    procedure RenderSolidBars(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const AFrame: TDisplayFrame
    );

    procedure RenderBlockBars(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const AFrame: TDisplayFrame
    );

    procedure RenderPeakMarkers(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const AFrame: TDisplayFrame;
      const ABarWidth: Integer;
      const ATotalWidth: Integer;
      const AStartX: Integer
    );

  public
    constructor Create;
    destructor Destroy; override;

    procedure RenderDisplayFrame(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const AFrame: TDisplayFrame
    );

    property Style: TSpectrumStyle read FStyle write FStyle;
  end;

implementation

{ TCanvasSpectrumRenderer }

constructor TCanvasSpectrumRenderer.Create;
begin
  inherited Create;

  FStyle := TSpectrumStyle.Default;

  FBackBuffer := TBitmap.Create;
  FBackBuffer.PixelFormat := pf32bit;
end;

destructor TCanvasSpectrumRenderer.Destroy;
begin
  FBackBuffer.Free;

  inherited;
end;

function TCanvasSpectrumRenderer.Clamp01(
  const AValue: Single
): Single;
begin
  if AValue < 0.0 then
    Exit(0.0);

  if AValue > 1.0 then
    Exit(1.0);

  Result := AValue;
end;

procedure TCanvasSpectrumRenderer.EnsureBackBuffer(
  const AWidth: Integer;
  const AHeight: Integer
);
begin
  if (AWidth <= 0) or (AHeight <= 0) then
    Exit;

  if (FBackBuffer.Width <> AWidth) or
     (FBackBuffer.Height <> AHeight) then
  begin
    FBackBuffer.SetSize(AWidth, AHeight);
    FBackBuffer.PixelFormat := pf32bit;
  end;
end;

procedure TCanvasSpectrumRenderer.ClearCanvas(
  const ACanvas: TCanvas;
  const ARect: TRect
);
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FStyle.BackgroundColor;
  ACanvas.Pen.Style := psClear;
  ACanvas.FillRect(ARect);
  ACanvas.Pen.Style := psSolid;
end;

procedure TCanvasSpectrumRenderer.RenderDisplayFrame(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame
);
var
  LocalRect: TRect;
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  EnsureBackBuffer(
    ARect.Width,
    ARect.Height
  );

  LocalRect := Rect(
    0,
    0,
    FBackBuffer.Width,
    FBackBuffer.Height
  );

  ClearCanvas(
    FBackBuffer.Canvas,
    LocalRect
  );

  if (AFrame.BarCount > 0) and
     (Length(AFrame.Bars) >= AFrame.BarCount) then
  begin
    case FStyle.BarStyle of
      TSpectrumBarStyle.Blocks:
        RenderBlockBars(
          FBackBuffer.Canvas,
          LocalRect,
          AFrame
        );
    else
      RenderSolidBars(
        FBackBuffer.Canvas,
        LocalRect,
        AFrame
      );
    end;
  end;

  ACanvas.Draw(
    ARect.Left,
    ARect.Top,
    FBackBuffer
  );
end;

procedure TCanvasSpectrumRenderer.RenderSolidBars(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame
);
var
  WorkRect: TRect;
  BarCount: Integer;
  Spacing: Integer;
  AvailableWidth: Integer;
  BarWidth: Integer;
  TotalWidth: Integer;
  StartX: Integer;
  Index: Integer;
  X: Integer;
  H: Integer;
  MaxHeight: Integer;
  V: Single;
  R: TRect;
begin
  BarCount := AFrame.BarCount;

  if BarCount <= 0 then
    Exit;

  WorkRect := Rect(
    ARect.Left + FStyle.MarginLeft,
    ARect.Top + FStyle.MarginTop,
    ARect.Right - FStyle.MarginRight,
    ARect.Bottom - FStyle.MarginBottom
  );

  if (WorkRect.Width <= 0) or (WorkRect.Height <= 0) then
    Exit;

  Spacing := Max(0, FStyle.BarSpacing);
  AvailableWidth := WorkRect.Width - ((BarCount - 1) * Spacing);

  if AvailableWidth <= 0 then
    Exit;

  BarWidth := Max(1, AvailableWidth div BarCount);

  TotalWidth :=
    (BarWidth * BarCount) +
    (Spacing * (BarCount - 1));

  StartX :=
    WorkRect.Left + ((WorkRect.Width - TotalWidth) div 2);

  MaxHeight := WorkRect.Height;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FStyle.BarColor;
  ACanvas.Pen.Style := psClear;

  for Index := 0 to BarCount - 1 do
  begin
    V := Clamp01(AFrame.Bars[Index]);

    H := Round(V * MaxHeight);

    if (H > 0) and (H < FStyle.MinimumBarHeight) then
      H := FStyle.MinimumBarHeight;

    if H <= 0 then
      Continue;

    X := StartX + Index * (BarWidth + Spacing);

    R := Rect(
      X,
      WorkRect.Bottom - H,
      X + BarWidth,
      WorkRect.Bottom
    );

    ACanvas.FillRect(R);
  end;

  ACanvas.Pen.Style := psSolid;

  RenderPeakMarkers(
    ACanvas,
    WorkRect,
    AFrame,
    BarWidth,
    TotalWidth,
    StartX
  );
end;

procedure TCanvasSpectrumRenderer.RenderBlockBars(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame
);
var
  WorkRect: TRect;
  BarCount: Integer;
  Spacing: Integer;
  AvailableWidth: Integer;
  BarWidth: Integer;
  TotalWidth: Integer;
  StartX: Integer;
  Index: Integer;
  X: Integer;
  H: Integer;
  MaxHeight: Integer;
  BlockHeight: Integer;
  BlockSpacing: Integer;
  BlockPitch: Integer;
  Y: Integer;
  MinY: Integer;
  V: Single;
  R: TRect;
begin
  BarCount := AFrame.BarCount;

  if BarCount <= 0 then
    Exit;

  WorkRect := Rect(
    ARect.Left + FStyle.MarginLeft,
    ARect.Top + FStyle.MarginTop,
    ARect.Right - FStyle.MarginRight,
    ARect.Bottom - FStyle.MarginBottom
  );

  if (WorkRect.Width <= 0) or (WorkRect.Height <= 0) then
    Exit;

  Spacing := Max(0, FStyle.BarSpacing);
  AvailableWidth := WorkRect.Width - ((BarCount - 1) * Spacing);

  if AvailableWidth <= 0 then
    Exit;

  BarWidth := Max(1, AvailableWidth div BarCount);

  TotalWidth :=
    (BarWidth * BarCount) +
    (Spacing * (BarCount - 1));

  StartX :=
    WorkRect.Left + ((WorkRect.Width - TotalWidth) div 2);

  MaxHeight := WorkRect.Height;

  BlockHeight := Max(1, FStyle.BlockHeight);
  BlockSpacing := Max(0, FStyle.BlockSpacing);
  BlockPitch := BlockHeight + BlockSpacing;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FStyle.BarColor;
  ACanvas.Pen.Style := psClear;

  for Index := 0 to BarCount - 1 do
  begin
    V := Clamp01(AFrame.Bars[Index]);

    H := Round(V * MaxHeight);

    if (H > 0) and (H < FStyle.MinimumBarHeight) then
      H := FStyle.MinimumBarHeight;

    if H <= 0 then
      Continue;

    X := StartX + Index * (BarWidth + Spacing);

    MinY := WorkRect.Bottom - H;
    Y := WorkRect.Bottom - BlockHeight;

    while Y >= MinY do
    begin
      R := Rect(
        X,
        Y,
        X + BarWidth,
        Y + BlockHeight
      );

      ACanvas.FillRect(R);

      Dec(Y, BlockPitch);
    end;
  end;

  ACanvas.Pen.Style := psSolid;

  RenderPeakMarkers(
    ACanvas,
    WorkRect,
    AFrame,
    BarWidth,
    TotalWidth,
    StartX
  );
end;

procedure TCanvasSpectrumRenderer.RenderPeakMarkers(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame;
  const ABarWidth: Integer;
  const ATotalWidth: Integer;
  const AStartX: Integer
);
var
  Index: Integer;
  X: Integer;
  MarkerX: Integer;
  MarkerY: Integer;
  MarkerW: Integer;
  MarkerH: Integer;
  Spacing: Integer;
  MaxHeight: Integer;
  V: Single;
  R: TRect;
begin
  if not FStyle.PeakMarkerEnabled then
    Exit;

  if Length(AFrame.PeakBars) < AFrame.BarCount then
    Exit;

  Spacing := Max(0, FStyle.BarSpacing);
  MaxHeight := ARect.Height;

  MarkerH := Max(1, FStyle.PeakMarkerHeight);

  if FStyle.PeakMarkerWidth > 0 then
    MarkerW := Min(FStyle.PeakMarkerWidth, ABarWidth)
  else
    MarkerW := ABarWidth;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FStyle.PeakMarkerColor;
  ACanvas.Pen.Style := psClear;

  for Index := 0 to AFrame.BarCount - 1 do
  begin
    V := Clamp01(AFrame.PeakBars[Index]);

    if V <= 0.0 then
      Continue;

    X := AStartX + Index * (ABarWidth + Spacing);

    MarkerX := X + ((ABarWidth - MarkerW) div 2);
    MarkerY := ARect.Bottom - Round(V * MaxHeight);

    if MarkerY < ARect.Top then
      MarkerY := ARect.Top;

    if MarkerY > ARect.Bottom - MarkerH then
      MarkerY := ARect.Bottom - MarkerH;

    R := Rect(
      MarkerX,
      MarkerY,
      MarkerX + MarkerW,
      MarkerY + MarkerH
    );

    ACanvas.FillRect(R);
  end;

  ACanvas.Pen.Style := psSolid;
end;

end.