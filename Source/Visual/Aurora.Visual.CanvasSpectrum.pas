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
  TBarLayoutItem = record
    Left: Integer;
    Right: Integer;
    CenterX: Integer;
  end;

  TCanvasSpectrumRenderer = class
  private
  FStyle: TSpectrumStyle;
  FBackBuffer: TBitmap;
    FLayoutDirty: Boolean;
    FCacheWidth: Integer;
    FCacheHeight: Integer;
    FCacheBarCount: Integer;

    FCacheWorkRect: TRect;
    FCacheBarWidth: Integer;
    FCacheTotalWidth: Integer;
    FCacheStartX: Integer;
	FBarLayout: TArray<TBarLayoutItem>;

    procedure InvalidateLayout;

    procedure SetStyle(
      const AValue: TSpectrumStyle
    );

    procedure EnsureLayout(
      const ARect: TRect;
      const ABarCount: Integer
    );

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

  property Style: TSpectrumStyle read FStyle write SetStyle;
  end;

implementation

{ TCanvasSpectrumRenderer }

constructor TCanvasSpectrumRenderer.Create;
begin
  inherited Create;

  FStyle := TSpectrumStyle.Default;

  FBackBuffer := TBitmap.Create;
  FBackBuffer.PixelFormat := pf32bit;

  FLayoutDirty := True;
  FCacheWidth := 0;
  FCacheHeight := 0;
  FCacheBarCount := 0;
end;

destructor TCanvasSpectrumRenderer.Destroy;
begin
  FBackBuffer.Free;

  inherited;
end;

procedure TCanvasSpectrumRenderer.InvalidateLayout;
begin
  FLayoutDirty := True;
end;

procedure TCanvasSpectrumRenderer.SetStyle(
  const AValue: TSpectrumStyle
);
begin
  FStyle := AValue;
  InvalidateLayout;
end;

procedure TCanvasSpectrumRenderer.EnsureLayout(
  const ARect: TRect;
  const ABarCount: Integer
);
var
  Spacing: Integer;
  AvailableWidth: Integer;
  Index: Integer;
  X: Integer;
begin
  if ABarCount <= 0 then
  begin
    SetLength(FBarLayout, 0);
    FCacheBarCount := 0;
    Exit;
  end;

  if (not FLayoutDirty) and
     (FCacheWidth = ARect.Width) and
     (FCacheHeight = ARect.Height) and
     (FCacheBarCount = ABarCount) then
    Exit;

  FCacheWidth := ARect.Width;
  FCacheHeight := ARect.Height;
  FCacheBarCount := ABarCount;

  FCacheWorkRect := Rect(
    ARect.Left + FStyle.MarginLeft,
    ARect.Top + FStyle.MarginTop,
    ARect.Right - FStyle.MarginRight,
    ARect.Bottom - FStyle.MarginBottom
  );

  SetLength(FBarLayout, 0);

  if (FCacheWorkRect.Width <= 0) or
     (FCacheWorkRect.Height <= 0) then
  begin
    FLayoutDirty := False;
    Exit;
  end;

  Spacing := Max(0, FStyle.BarSpacing);

  AvailableWidth :=
    FCacheWorkRect.Width - ((ABarCount - 1) * Spacing);

  if AvailableWidth <= 0 then
  begin
    FLayoutDirty := False;
    Exit;
  end;

  FCacheBarWidth :=
    Max(1, AvailableWidth div ABarCount);

  FCacheTotalWidth :=
    (FCacheBarWidth * ABarCount) +
    (Spacing * (ABarCount - 1));

  FCacheStartX :=
    FCacheWorkRect.Left +
    ((FCacheWorkRect.Width - FCacheTotalWidth) div 2);

  SetLength(FBarLayout, ABarCount);

  for Index := 0 to ABarCount - 1 do
  begin
    X :=
      FCacheStartX +
      Index * (FCacheBarWidth + Spacing);

    FBarLayout[Index].Left := X;
    FBarLayout[Index].Right := X + FCacheBarWidth;
    FBarLayout[Index].CenterX := X + (FCacheBarWidth div 2);
  end;

  FLayoutDirty := False;
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

  if (FBackBuffer.Width = AWidth) and
     (FBackBuffer.Height = AHeight) then
    Exit;

  FBackBuffer.SetSize(AWidth, AHeight);
  FBackBuffer.PixelFormat := pf32bit;
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

  // Clear nền trong bitmap, không clear trực tiếp PaintBox
  FBackBuffer.Canvas.Brush.Style := bsSolid;
  FBackBuffer.Canvas.Brush.Color := FStyle.BackgroundColor;
  FBackBuffer.Canvas.Pen.Style := psClear;
  FBackBuffer.Canvas.FillRect(LocalRect);
  FBackBuffer.Canvas.Pen.Style := psSolid;

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

  // Blit một phát ra PaintBox
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
  Index: Integer;
  H: Integer;
  MaxHeight: Integer;
  V: Single;
  R: TRect;
begin
  if AFrame.BarCount <= 0 then
    Exit;

  EnsureLayout(
    ARect,
    AFrame.BarCount
  );

  if Length(FBarLayout) < AFrame.BarCount then
    Exit;

  MaxHeight := FCacheWorkRect.Height;

  if MaxHeight <= 0 then
    Exit;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FStyle.BarColor;
  ACanvas.Pen.Style := psClear;

  for Index := 0 to AFrame.BarCount - 1 do
  begin
    V := Clamp01(AFrame.Bars[Index]);

    H := Round(V * MaxHeight);

    if (H > 0) and (H < FStyle.MinimumBarHeight) then
      H := FStyle.MinimumBarHeight;

    if H <= 0 then
      Continue;

    R := Rect(
      FBarLayout[Index].Left,
      FCacheWorkRect.Bottom - H,
      FBarLayout[Index].Right,
      FCacheWorkRect.Bottom
    );

    ACanvas.FillRect(R);
  end;

  ACanvas.Pen.Style := psSolid;

  RenderPeakMarkers(
    ACanvas,
    FCacheWorkRect,
    AFrame,
    FCacheBarWidth,
    FCacheTotalWidth,
    FCacheStartX
  );
end;
procedure TCanvasSpectrumRenderer.RenderBlockBars(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame
);
var
  Index: Integer;
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
  if AFrame.BarCount <= 0 then
    Exit;

  EnsureLayout(
    ARect,
    AFrame.BarCount
  );

  if Length(FBarLayout) < AFrame.BarCount then
    Exit;

  MaxHeight := FCacheWorkRect.Height;

  if MaxHeight <= 0 then
    Exit;

  BlockHeight := Max(1, FStyle.BlockHeight);
  BlockSpacing := Max(0, FStyle.BlockSpacing);
  BlockPitch := BlockHeight + BlockSpacing;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FStyle.BarColor;
  ACanvas.Pen.Style := psClear;

  for Index := 0 to AFrame.BarCount - 1 do
  begin
    V := Clamp01(AFrame.Bars[Index]);

    H := Round(V * MaxHeight);

    if (H > 0) and (H < FStyle.MinimumBarHeight) then
      H := FStyle.MinimumBarHeight;

    if H <= 0 then
      Continue;

    MinY := FCacheWorkRect.Bottom - H;
    Y := FCacheWorkRect.Bottom - BlockHeight;

    while Y >= MinY do
    begin
      R := Rect(
        FBarLayout[Index].Left,
        Y,
        FBarLayout[Index].Right,
        Y + BlockHeight
      );

      ACanvas.FillRect(R);

      Dec(Y, BlockPitch);
    end;
  end;

  ACanvas.Pen.Style := psSolid;

  RenderPeakMarkers(
    ACanvas,
    FCacheWorkRect,
    AFrame,
    FCacheBarWidth,
    FCacheTotalWidth,
    FCacheStartX
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
  MarkerX: Integer;
  MarkerY: Integer;
  MarkerW: Integer;
  MarkerH: Integer;
  MaxHeight: Integer;
  V: Single;
  R: TRect;
begin
  if not FStyle.PeakMarkerEnabled then
    Exit;

  if Length(AFrame.PeakBars) < AFrame.BarCount then
    Exit;

  if Length(FBarLayout) < AFrame.BarCount then
    Exit;

  MaxHeight := ARect.Height;

  if MaxHeight <= 0 then
    Exit;

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

    MarkerX :=
      FBarLayout[Index].CenterX -
      (MarkerW div 2);

    MarkerY :=
      ARect.Bottom - Round(V * MaxHeight);

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