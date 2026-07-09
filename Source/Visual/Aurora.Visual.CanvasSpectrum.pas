{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Visual.CanvasSpectrum                                           }
{                                                                              }
{  Description: VCL Canvas renderer for normalized spectrum bars.               }
{                                                                              }
{******************************************************************************}

unit Aurora.Visual.CanvasSpectrum;

interface

{$SCOPEDENUMS ON}

uses
  System.Types,
  Vcl.Graphics,
  Aurora.Core.Frame,
  Aurora.Visual.Frame,
  Aurora.Visual.Types;

type
  TCanvasSpectrumRenderer = class
  private
    FStyle: TSpectrumStyle;

    function Clamp01(const AValue: Single): Single;

    procedure RenderSolidBars(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const ABars: PSingle;
      const ACount: Integer);

    procedure RenderBlockBars(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const ABars: PSingle;
      const ACount: Integer);

procedure RenderPeakMarkers(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame);

  public
    constructor Create;

  procedure RenderFrame(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TAuroraFrame);

  procedure Render(
      const ACanvas: TCanvas;
      const ARect: TRect;
      const ABars: PSingle;
      const ACount: Integer);

  property Style: TSpectrumStyle read FStyle write FStyle;

procedure RenderDisplayFrame(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame);

  end;

implementation

uses
  System.SysUtils;

type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

{ TCanvasSpectrumRenderer }

constructor TCanvasSpectrumRenderer.Create;
begin
  inherited Create;
  FStyle := TSpectrumStyle.Default;
end;


function TCanvasSpectrumRenderer.Clamp01(const AValue: Single): Single;
begin
  if AValue < 0.0 then
    Exit(0.0);

  if AValue > 1.0 then
    Exit(1.0);

  Result := AValue;
end;

procedure TCanvasSpectrumRenderer.RenderDisplayFrame(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame);
begin
  if AFrame.BarCount <= 0 then
    Exit;

  Render(
    ACanvas,
    ARect,
    @AFrame.Bars[0],
    AFrame.BarCount
  );

  RenderPeakMarkers(
    ACanvas,
    ARect,
    AFrame
  );
end;

procedure TCanvasSpectrumRenderer.RenderPeakMarkers(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TDisplayFrame);
var
  BarIndex: Integer;
  AvailableWidth: Integer;
  BarWidth: Integer;
  MarkerWidth: Integer;
  LeftPos: Integer;
  RightPos: Integer;
  MarkerTop: Integer;
  Value: Single;
begin
  if not FStyle.PeakMarkerEnabled then
    Exit;

  if AFrame.BarCount <= 0 then
    Exit;

  AvailableWidth :=
    ARect.Width -
    (AFrame.BarCount - 1) * FStyle.BarSpacing;

  if AvailableWidth <= 0 then
    Exit;

  BarWidth := AvailableWidth div AFrame.BarCount;

  if BarWidth <= 0 then
    BarWidth := 1;

  MarkerWidth := FStyle.PeakMarkerWidth;

  if MarkerWidth <= 0 then
    MarkerWidth := BarWidth;

  ACanvas.Brush.Color := FStyle.PeakMarkerColor;

  for BarIndex := 0 to AFrame.BarCount - 1 do
  begin
    Value := Clamp01(AFrame.PeakBars[BarIndex]);

    MarkerTop :=
      ARect.Bottom -
      Round(Value * ARect.Height);

    if MarkerTop < ARect.Top then
      MarkerTop := ARect.Top;

    LeftPos :=
      ARect.Left +
      BarIndex * (BarWidth + FStyle.BarSpacing) +
      (BarWidth - MarkerWidth) div 2;

    RightPos := LeftPos + MarkerWidth;

    ACanvas.FillRect(
      Rect(
        LeftPos,
        MarkerTop,
        RightPos,
        MarkerTop + FStyle.PeakMarkerHeight
      )
    );
  end;
end;

procedure TCanvasSpectrumRenderer.RenderFrame(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const AFrame: TAuroraFrame);
begin
  if Length(AFrame.Bars) = 0 then
    Exit;

  Render(
    ACanvas,
    ARect,
    @AFrame.Bars[0],
    Length(AFrame.Bars)
  );
end;


procedure TCanvasSpectrumRenderer.Render(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const ABars: PSingle;
  const ACount: Integer);
begin
  if ACanvas = nil then
    raise EArgumentNilException.Create('Canvas must not be nil.');

  if ABars = nil then
    raise EArgumentNilException.Create('Bars pointer must not be nil.');

  if ACount <= 0 then
    Exit;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FStyle.BackgroundColor;
  ACanvas.FillRect(ARect);

  case FStyle.BarStyle of
    TSpectrumBarStyle.Solid:
      RenderSolidBars(ACanvas, ARect, ABars, ACount);

    TSpectrumBarStyle.Blocks:
      RenderBlockBars(ACanvas, ARect, ABars, ACount);
  end;
end;

procedure TCanvasSpectrumRenderer.RenderSolidBars(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const ABars: PSingle;
  const ACount: Integer);
var
  Bars: PSingleArray;
  BarIndex: Integer;
  AvailableWidth: Integer;
  BarWidth: Integer;
  LeftPos: Integer;
  RightPos: Integer;
  BarHeight: Integer;
  Value: Single;
  BarRect: TRect;
begin
  Bars := PSingleArray(ABars);

  AvailableWidth := ARect.Width - (ACount - 1) * FStyle.BarSpacing;

  if AvailableWidth <= 0 then
    Exit;

  BarWidth := AvailableWidth div ACount;

  if BarWidth <= 0 then
    BarWidth := 1;

  ACanvas.Brush.Color := FStyle.BarColor;

  for BarIndex := 0 to ACount - 1 do
  begin
    Value := Clamp01(Bars^[BarIndex]);
    BarHeight := Round(Value * ARect.Height);

    LeftPos := ARect.Left + BarIndex * (BarWidth + FStyle.BarSpacing);
    RightPos := LeftPos + BarWidth;

    case FStyle.Orientation of
      TSpectrumOrientation.BottomUp:
        BarRect := Rect(
          LeftPos,
          ARect.Bottom - BarHeight,
          RightPos,
          ARect.Bottom
        );

      TSpectrumOrientation.Centered:
        BarRect := Rect(
          LeftPos,
          ARect.Top + (ARect.Height - BarHeight) div 2,
          RightPos,
          ARect.Top + (ARect.Height + BarHeight) div 2
        );

      TSpectrumOrientation.Mirrored:
        BarRect := Rect(
          LeftPos,
          ARect.Top,
          RightPos,
          ARect.Bottom
        );
    else
      BarRect := Rect(
        LeftPos,
        ARect.Bottom - BarHeight,
        RightPos,
        ARect.Bottom
      );
    end;

    ACanvas.FillRect(BarRect);
  end;
end;

procedure TCanvasSpectrumRenderer.RenderBlockBars(
  const ACanvas: TCanvas;
  const ARect: TRect;
  const ABars: PSingle;
  const ACount: Integer);
var
  Bars: PSingleArray;
  BarIndex: Integer;
  BlockIndex: Integer;
  AvailableWidth: Integer;
  BarWidth: Integer;
  LeftPos: Integer;
  RightPos: Integer;
  BlockPitch: Integer;
  MaxBlocks: Integer;
  ActiveBlocks: Integer;
  BlockTop: Integer;
  Value: Single;
begin
  Bars := PSingleArray(ABars);

  AvailableWidth := ARect.Width - (ACount - 1) * FStyle.BarSpacing;

  if AvailableWidth <= 0 then
    Exit;

  BarWidth := AvailableWidth div ACount;

  if BarWidth <= 0 then
    BarWidth := 1;

  BlockPitch := FStyle.BlockHeight + FStyle.BlockSpacing;

  if BlockPitch <= 0 then
    Exit;

  MaxBlocks := ARect.Height div BlockPitch;

  if MaxBlocks <= 0 then
    Exit;

  ACanvas.Brush.Color := FStyle.BarColor;

  for BarIndex := 0 to ACount - 1 do
  begin
    Value := Clamp01(Bars^[BarIndex]);
    ActiveBlocks := Round(Value * MaxBlocks);

    LeftPos := ARect.Left + BarIndex * (BarWidth + FStyle.BarSpacing);
    RightPos := LeftPos + BarWidth;

    for BlockIndex := 0 to ActiveBlocks - 1 do
    begin
      BlockTop :=
        ARect.Bottom -
        (BlockIndex + 1) * BlockPitch;

      ACanvas.FillRect(
        Rect(
          LeftPos,
          BlockTop,
          RightPos,
          BlockTop + FStyle.BlockHeight
        )
      );
    end;
  end;
end;

end.