unit Aurora.Visual.Runtime;

interface

uses
  System.SysUtils,
  System.Types,
  Vcl.Graphics,
  Aurora.Engine,
  Aurora.Visual.Types,
  Aurora.Core.Frame,
   Aurora.Core.Types,
  Aurora.Visual.Frame,
  Aurora.Visual.DisplayProcessor,
  Aurora.Visual.CanvasSpectrum;

type
  TAuroraVisualRuntime = class
  private
    FEngine: TAuroraSpectrumEngine;
    FDisplayProcessor: TDisplayProcessor;
    FRenderer: TCanvasSpectrumRenderer;

   // FRawFrame: TSpectrumFrame;
    FDisplayFrame: TDisplayFrame;

    FSampleRate: Integer;
    FFFTSize: Integer;
    FBarCount: Integer;

  public
    constructor Create(
      ASampleRate: Integer;
      AFFTSize: Integer;
      ABarCount: Integer
    );

    destructor Destroy; override;

  procedure PushInterleavedFloat32(
    const ASamples: TArray<Single>;
    ASampleFrameCount: Integer;
    AChannelCount: Integer
   );

    function Process: Boolean;

    procedure Render(
      const ACanvas: TCanvas;
      const ARect: TRect
    );
	
   function ProcessAvailableFrames: Boolean;	

    procedure Reset;
    procedure SetTheme(APreset: TSpectrumThemePreset);

    property DisplayFrame: TDisplayFrame read FDisplayFrame;
    property Engine: TAuroraSpectrumEngine read FEngine;
    property DisplayProcessor: TDisplayProcessor read FDisplayProcessor;
    property Renderer: TCanvasSpectrumRenderer read FRenderer;
  end;

implementation

{ TAuroraVisualRuntime }

constructor TAuroraVisualRuntime.Create(
  ASampleRate: Integer;
  AFFTSize: Integer;
  ABarCount: Integer
);
begin
  inherited Create;

  FSampleRate := ASampleRate;
  FFFTSize := AFFTSize;
  FBarCount := ABarCount;

  FEngine := TAuroraSpectrumEngine.Create(
    FSampleRate,
    FFFTSize,
    FBarCount
  );

FDisplayProcessor := TDisplayProcessor.Create(FBarCount);
FRenderer := TCanvasSpectrumRenderer.Create;

FDisplayFrame := TDisplayFrame.Create(FBarCount);
end;

destructor TAuroraVisualRuntime.Destroy;
begin
  FRenderer.Free;
  FDisplayProcessor.Free;
  FEngine.Free;

  inherited;
end;

procedure TAuroraVisualRuntime.SetTheme(
  APreset: TSpectrumThemePreset
);
begin
  if FRenderer = nil then
    Exit;

  FRenderer.Style := TSpectrumStyle.FromPreset(APreset);
end;

procedure TAuroraVisualRuntime.PushInterleavedFloat32(
  const ASamples: TArray<Single>;
  ASampleFrameCount: Integer;
  AChannelCount: Integer
);
var
  NeededScalarCount: Integer;
begin
  if (FEngine = nil) or (AChannelCount <= 0) then
    Exit;

  if ASampleFrameCount <= 0 then
    Exit;

  NeededScalarCount := ASampleFrameCount * AChannelCount;

  if Length(ASamples) < NeededScalarCount then
    Exit;

  FEngine.PushInterleavedFloat32(
    @ASamples[0],
    ASampleFrameCount,
    AChannelCount
  );
end;

function TAuroraVisualRuntime.ProcessAvailableFrames: Boolean;
begin
  Result := False;

  while Process do
    Result := True;
end;

function TAuroraVisualRuntime.Process: Boolean;
begin
  Result := False;

  if (FEngine = nil) or (FDisplayProcessor = nil) then
    Exit;

  if not FEngine.TryProcessFrame then
    Exit;

  if FDisplayFrame.BarCount <> FEngine.BarCount then
    FDisplayFrame.Resize(FEngine.BarCount);

  FDisplayProcessor.Process(
    FEngine.CurrentFrame,
    FDisplayFrame
  );

  Result := FDisplayFrame.BarCount > 0;
end;

procedure TAuroraVisualRuntime.Render(
  const ACanvas: TCanvas;
  const ARect: TRect
);
begin
  if (FRenderer = nil) or (FDisplayFrame.BarCount <= 0) then
    Exit;

  FRenderer.RenderDisplayFrame(
    ACanvas,
    ARect,
    FDisplayFrame
  );
end;

procedure TAuroraVisualRuntime.Reset;
begin
  FreeAndNil(FEngine);
  FreeAndNil(FDisplayProcessor);

  FEngine :=
    TAuroraSpectrumEngine.Create(
      FSampleRate,
      FFFTSize,
      FBarCount
    );

  FDisplayProcessor := TDisplayProcessor.Create(FBarCount);

  FDisplayFrame.Resize(FBarCount);
end;

end.