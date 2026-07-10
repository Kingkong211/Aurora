unit Aurora.Visual.CanvasSpectrum;

interface

uses
  System.SysUtils,
  System.Types,
  System.Math,

  Winapi.Windows,
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
    FBackBuffer: Vcl.Graphics.TBitmap;
    FLayoutDirty: Boolean;
    FCacheWidth: Integer;
    FCacheHeight: Integer;
    FCacheBarCount: Integer;

    FCacheWorkRect: TRect;
    FCacheBarWidth: Integer;
    FCacheTotalWidth: Integer;
    FCacheStartX: Integer;
	FBarLayout: TArray<TBarLayoutItem>;
	
    function BlendColor(
      const ABaseColor: TColor;
      const AGlowColor: TColor;
      const AAmount: Single
    ): TColor;

    function ComputeFrameEnergy(
      const AFrame: TDisplayFrame
    ): Single;

    procedure RenderBackgroundGlow(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const AFrame: TDisplayFrame
    );	

    procedure FillBarRect(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const AHeight: Integer
    );
    procedure InvalidateLayout;

    procedure SetStyle(
      const AValue: TSpectrumStyle
    );

    procedure EnsureLayout(
      const ARect: TRect;
      const ABarCount: Integer
    );

    procedure RenderBarAura(
      const ACanvas: TCanvas;
      const AFrame: TDisplayFrame
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

  FBackBuffer := Vcl.Graphics.TBitmap.Create;
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

function TCanvasSpectrumRenderer.BlendColor(
  const ABaseColor: TColor;
  const AGlowColor: TColor;
  const AAmount: Single
): TColor;
var
  BaseRGB: TColor;
  GlowRGB: TColor;
  Amount: Single;
  R: Integer;
  G: Integer;
  B: Integer;
begin
  Amount := AAmount;

  if Amount < 0.0 then
    Amount := 0.0
  else if Amount > 1.0 then
    Amount := 1.0;

  BaseRGB := ColorToRGB(ABaseColor);
  GlowRGB := ColorToRGB(AGlowColor);

  R :=
    Round(
      GetRValue(BaseRGB) * (1.0 - Amount) +
      GetRValue(GlowRGB) * Amount
    );

  G :=
    Round(
      GetGValue(BaseRGB) * (1.0 - Amount) +
      GetGValue(GlowRGB) * Amount
    );

  B :=
    Round(
      GetBValue(BaseRGB) * (1.0 - Amount) +
      GetBValue(GlowRGB) * Amount
    );

  Result := RGB(R, G, B);
end;

function TCanvasSpectrumRenderer.ComputeFrameEnergy(
  const AFrame: TDisplayFrame
): Single;
var
  I: Integer;
  Sum: Double;
  V: Single;
begin
  Result := 0.0;

  if (AFrame.BarCount <= 0) or
     (Length(AFrame.Bars) < AFrame.BarCount) then
    Exit;

  Sum := 0.0;

  for I := 0 to AFrame.BarCount - 1 do
  begin
    V := Clamp01(AFrame.Bars[I]);
    Sum := Sum + V * V;
  end;

  Result :=
    Sqrt(Sum / AFrame.BarCount);

  if Result > 1.0 then
    Result := 1.0;
end;

procedure TCanvasSpectrumRenderer.RenderBackgroundGlow(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame
);
var
  Energy: Single;
  GlowAmount: Single;
  GlowHeight: Integer;
  BandHeight: Integer;
  BottomY: Integer;
  R1: TRect;
  R2: TRect;
  R3: TRect;
begin
  if not FStyle.GlowEnabled then
    Exit;

  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  Energy := ComputeFrameEnergy(AFrame);

  if Energy <= 0.01 then
    Exit;

  GlowAmount :=
    FStyle.GlowIntensity * (0.35 + 0.65 * Energy);

  GlowHeight :=
    Round(ARect.Height * FStyle.GlowHeightRatio);

  if GlowHeight < 4 then
    Exit;

  if GlowHeight > ARect.Height then
    GlowHeight := ARect.Height;

  BottomY := ARect.Bottom;

  BandHeight := GlowHeight div 3;

  if BandHeight <= 0 then
    Exit;

  R1 := Rect(
    ARect.Left,
    BottomY - BandHeight,
    ARect.Right,
    BottomY
  );

  R2 := Rect(
    ARect.Left,
    BottomY - BandHeight * 2,
    ARect.Right,
    BottomY - BandHeight
  );

  R3 := Rect(
    ARect.Left,
    BottomY - GlowHeight,
    ARect.Right,
    BottomY - BandHeight * 2
  );

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Pen.Style := psClear;

  // gần chân bar sáng nhất
  ACanvas.Brush.Color :=
    BlendColor(
      FStyle.BackgroundColor,
      FStyle.GlowColor,
      GlowAmount
    );
  ACanvas.FillRect(R1);

  // giữa dịu hơn
  ACanvas.Brush.Color :=
    BlendColor(
      FStyle.BackgroundColor,
      FStyle.GlowColor,
      GlowAmount * 0.55
    );
  ACanvas.FillRect(R2);

  // trên cùng rất nhẹ
  ACanvas.Brush.Color :=
    BlendColor(
      FStyle.BackgroundColor,
      FStyle.GlowColor,
      GlowAmount * 0.25
    );
  ACanvas.FillRect(R3);

  ACanvas.Pen.Style := psSolid;
end;

//highlight top bar
procedure TCanvasSpectrumRenderer.FillBarRect(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AHeight: Integer
);
var
  HighlightHeight: Integer;
  HighlightRect: TRect;
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  ACanvas.Brush.Color := FStyle.BarColor;
  ACanvas.FillRect(ARect);

  if not FStyle.TopHighlightEnabled then
    Exit;

  if AHeight < 8 then
    Exit;

  HighlightHeight :=
    Round(AHeight * FStyle.TopHighlightRatio);

  if HighlightHeight < 2 then
    HighlightHeight := 2;

  if HighlightHeight > ARect.Height then
    HighlightHeight := ARect.Height;

  HighlightRect := Rect(
    ARect.Left,
    ARect.Top,
    ARect.Right,
    ARect.Top + HighlightHeight
  );

  ACanvas.Brush.Color := FStyle.TopHighlightColor;
  ACanvas.FillRect(HighlightRect);
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

procedure TCanvasSpectrumRenderer.RenderBarAura(
  const ACanvas: TCanvas;
  const AFrame: TDisplayFrame
);
var
  Index: Integer;
  H: Integer;
  MaxHeight: Integer;
  V: Single;
  GlowAmount: Single;
  ROuter: TRect;
  RInner: TRect;
  ExtraX: Integer;
  ExtraY: Integer;
begin
  if not FStyle.GlowEnabled then
    Exit;

  if AFrame.BarCount <= 0 then
    Exit;

  if Length(FBarLayout) < AFrame.BarCount then
    Exit;

  if Length(AFrame.Bars) < AFrame.BarCount then
    Exit;

  MaxHeight := FCacheWorkRect.Height;

  if MaxHeight <= 0 then
    Exit;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Pen.Style := psClear;

  ExtraX := 2;
  ExtraY := 3;

  for Index := 0 to AFrame.BarCount - 1 do
  begin
    V := Clamp01(AFrame.Bars[Index]);

    if V <= 0.04 then
      Continue;

    H := Round(V * MaxHeight);

    if H <= 0 then
      Continue;

    GlowAmount :=
      FStyle.GlowIntensity * (0.25 + 0.75 * V);

    if GlowAmount > 0.65 then
      GlowAmount := 0.65;

    ROuter := Rect(
      FBarLayout[Index].Left - ExtraX,
      FCacheWorkRect.Bottom - H - ExtraY,
      FBarLayout[Index].Right + ExtraX,
      FCacheWorkRect.Bottom
    );

    RInner := Rect(
      FBarLayout[Index].Left - 1,
      FCacheWorkRect.Bottom - H - 1,
      FBarLayout[Index].Right + 1,
      FCacheWorkRect.Bottom
    );

    ACanvas.Brush.Color :=
      BlendColor(
        FStyle.BackgroundColor,
        FStyle.GlowColor,
        GlowAmount * 0.45
      );

    ACanvas.FillRect(ROuter);

    ACanvas.Brush.Color :=
      BlendColor(
        FStyle.BackgroundColor,
        FStyle.GlowColor,
        GlowAmount * 0.75
      );

    ACanvas.FillRect(RInner);
  end;

  ACanvas.Pen.Style := psSolid;
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

  ClearCanvas(
    FBackBuffer.Canvas,
    LocalRect
  );

  if (AFrame.BarCount > 0) and
     (Length(AFrame.Bars) >= AFrame.BarCount) then
  begin
    EnsureLayout(
      LocalRect,
      AFrame.BarCount
    );

    RenderBackgroundGlow(
      FBackBuffer.Canvas,
      LocalRect,
      AFrame
    );

    RenderBarAura(
      FBackBuffer.Canvas,
      AFrame
    );

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
 // abc;
  
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

   FillBarRect(
      ACanvas,
      R,
      H
   );
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

      if FStyle.TopHighlightEnabled and
         (H >= 8) and
         (Y <= MinY + Round(H * FStyle.TopHighlightRatio)) then
        ACanvas.Brush.Color := FStyle.TopHighlightColor
      else
        ACanvas.Brush.Color := FStyle.BarColor;

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