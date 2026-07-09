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
      AChannelCount: Integer
    );

    function Process: Boolean;

    procedure Render(
      const ACanvas: TCanvas;
      const ARect: TRect
    );

    procedure Reset;

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

  //FRawFrame.BarCount := 0;
  FDisplayFrame.BarCount := 0;
end;

destructor TAuroraVisualRuntime.Destroy;
begin
  FRenderer.Free;
  FDisplayProcessor.Free;
  FEngine.Free;

  inherited;
end;

procedure TAuroraVisualRuntime.PushInterleavedFloat32(
  const ASamples: TArray<Single>;
  AChannelCount: Integer
);
var
  SampleFrameCount: Integer;
begin
  if (FEngine = nil) or (AChannelCount <= 0) then
    Exit;

  if Length(ASamples) = 0 then
    Exit;

  SampleFrameCount := Length(ASamples) div AChannelCount;

  if SampleFrameCount <= 0 then
    Exit;

  FEngine.PushInterleavedFloat32(
    @ASamples[0],
    SampleFrameCount,
    AChannelCount
  );
end;

function TAuroraVisualRuntime.Process: Boolean;
begin
  Result := False;

  if (FEngine = nil) or (FDisplayProcessor = nil) then
    Exit;

  if not FEngine.TryProcessFrame then
    Exit;

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
  if FEngine <> nil then
    FEngine.Free;

  if FDisplayProcessor <> nil then
    FDisplayProcessor.Free;// .Reset;

 // FRawFrame.BarCount := 0;
  FDisplayFrame.BarCount := 0;
end;

end.