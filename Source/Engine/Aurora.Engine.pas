{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Engine                                                          }
{                                                                              }
{  Description: High-level spectrum energy engine.                              }
{                                                                              }
{******************************************************************************}

unit Aurora.Engine;

interface

{$SCOPEDENUMS ON}

uses
  Aurora.Numerics.Complex,
  Aurora.DSP.Window,
  Aurora.DSP.FFT.Plan,
  Aurora.Core.RingBuffer,
  Aurora.Core.Frame,
  Aurora.Analysis.Normalization,
  Aurora.Analysis.Spectrum;

type
  TAuroraSpectrumEngine = class
  private
    FSampleRate: Integer;
    FFFTSize: Integer;
    FBarCount: Integer;
    FDynamicRangeDB: Single;
    FHopSize: Integer;

    FWindow: TWindowPlan;
    FFFTPlan: TFFTPlan;
    FSpectrum: TSpectrumAnalyzer;

    FRingBuffer: TFloatRingBuffer;
    FFrameBuffer: TArray<Single>;

    FMono: TArray<Single>;
    FComplex: TArray<TComplex32>;
    FMagnitudes: TArray<Single>;
    FRawBars: TArray<Single>;
    FBars: TArray<Single>;
    FCurrentFrame: TAuroraFrame;

    procedure ValidateProcessInput(
      const ASamples: PSingle;
      const ASampleFrameCount: Integer;
      const AChannelCount: Integer);

procedure ValidatePushInput(
  const ASamples: PSingle;
  const ASampleFrameCount: Integer;
  const AChannelCount: Integer);

    procedure ConvertInterleavedToMono(
      const ASamples: PSingle;
      const ASampleFrameCount: Integer;
      const AChannelCount: Integer);

    procedure BuildComplexInput;

  public
    constructor Create(
      const ASampleRate: Integer;
      const AFFTSize: Integer = 2048;
      const ABarCount: Integer = 80);

    destructor Destroy; override;

procedure PushInterleavedFloat32(
  const ASamples: PSingle;
  const ASampleFrameCount: Integer;
  const AChannelCount: Integer);

function TryProcessFrame: Boolean;

    procedure ProcessInterleavedFloat32(
      const ASamples: PSingle;
      const ASampleFrameCount: Integer;
      const AChannelCount: Integer);

    function GetBars: PSingle;

    property SampleRate: Integer read FSampleRate;
    property FFTSize: Integer read FFFTSize;
    property BarCount: Integer read FBarCount;
    property DynamicRangeDB: Single read FDynamicRangeDB write FDynamicRangeDB;
    property Bars: PSingle read GetBars;
    property HopSize: Integer read FHopSize;
    property CurrentFrame: TAuroraFrame read FCurrentFrame;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  Aurora.DSP.FFT.Radix2,
  Aurora.DSP.Magnitude;

type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

{ TAuroraSpectrumEngine }

constructor TAuroraSpectrumEngine.Create(
  const ASampleRate: Integer;
  const AFFTSize: Integer;
  const ABarCount: Integer);
begin
  inherited Create;

  if ASampleRate <= 0 then
    raise EArgumentOutOfRangeException.Create('Sample rate must be positive.');

  if AFFTSize <= 0 then
    raise EArgumentOutOfRangeException.Create('FFT size must be positive.');

  if ABarCount <= 0 then
    raise EArgumentOutOfRangeException.Create('Bar count must be positive.');

  FSampleRate := ASampleRate;
  FFFTSize := AFFTSize;
  FHopSize := FFFTSize div 2;
  FBarCount := ABarCount;
  FDynamicRangeDB := 60.0;

  FWindow := TWindowPlan.Create(TWindowKind.Hann, FFFTSize);
  FFFTPlan := TFFTPlan.Create(FFFTSize);
  FSpectrum := TSpectrumAnalyzer.Create(FFFTSize, FSampleRate, FBarCount);

  SetLength(FMono, FFFTSize);
  SetLength(FComplex, FFFTSize);
  SetLength(FMagnitudes, FFFTSize div 2);
  SetLength(FRawBars, FBarCount);
  SetLength(FBars, FBarCount);
FCurrentFrame :=
  TAuroraFrame.Create(
    FSampleRate,
    FFFTSize,
    FHopSize,
    FBarCount
  );

  FRingBuffer := TFloatRingBuffer.Create(FFFTSize * 16);
  SetLength(FFrameBuffer, FFFTSize);
end;

destructor TAuroraSpectrumEngine.Destroy;
begin
  FRingBuffer.Free;
  FSpectrum.Free;
  FFFTPlan.Free;
  FWindow.Free;

  inherited;
end;

procedure TAuroraSpectrumEngine.ValidateProcessInput(
  const ASamples: PSingle;
  const ASampleFrameCount: Integer;
  const AChannelCount: Integer);
begin
  if ASamples = nil then
    raise EArgumentNilException.Create('Samples pointer must not be nil.');

  if ASampleFrameCount < FFFTSize then
    raise EArgumentOutOfRangeException.Create('Not enough sample frames for FFT.');

  if AChannelCount <= 0 then
    raise EArgumentOutOfRangeException.Create('Channel count must be positive.');
end;

procedure ValidatePushInput(
  const ASamples: PSingle;
  const ASampleFrameCount: Integer;
  const AChannelCount: Integer);
begin
  if ASamples = nil then
    raise EArgumentNilException.Create('Samples pointer must not be nil.');

  if ASampleFrameCount < 0 then
    raise EArgumentOutOfRangeException.Create('Sample frame count must be non-negative.');

  if AChannelCount <= 0 then
    raise EArgumentOutOfRangeException.Create('Channel count must be positive.');
end;

procedure TAuroraSpectrumEngine.ConvertInterleavedToMono(
  const ASamples: PSingle;
  const ASampleFrameCount: Integer;
  const AChannelCount: Integer);
var
  Input: PSingleArray;
  FrameIndex: Integer;
  ChannelIndex: Integer;
  ScalarIndex: Integer;
  Sum: Single;
begin
  Input := PSingleArray(ASamples);

  for FrameIndex := 0 to FFFTSize - 1 do
  begin
    Sum := 0.0;
    ScalarIndex := FrameIndex * AChannelCount;

    for ChannelIndex := 0 to AChannelCount - 1 do
      Sum := Sum + Input^[ScalarIndex + ChannelIndex];

    FMono[FrameIndex] := Sum / AChannelCount;
  end;
end;

procedure TAuroraSpectrumEngine.BuildComplexInput;
var
  Index: Integer;
begin
  for Index := 0 to FFFTSize - 1 do
    FComplex[Index] := TComplex32.Create(FMono[Index], 0.0);
end;


procedure TAuroraSpectrumEngine.ProcessInterleavedFloat32(
  const ASamples: PSingle;
  const ASampleFrameCount: Integer;
  const AChannelCount: Integer);
begin
  ValidateInput(ASamples, ASampleFrameCount, AChannelCount);

  ConvertInterleavedToMono(ASamples, ASampleFrameCount, AChannelCount);
  FWindow.ApplyInPlace(@FMono[0]);

  BuildComplexInput;

  TRadix2FFT.Execute(
    FFFTPlan,
    PComplex32(@FComplex[0]),
    TFFTDirection.Forward
  );

  TMagnitude.ComputePower(
    PComplex32(@FComplex[0]),
    @FMagnitudes[0],
    FFFTSize div 2
  );

  FSpectrum.Analyze(
    @FMagnitudes[0],
    @FRawBars[0]
  );


TSignalNormalizer.NormalizePowerTo01(
  @FRawBars[0],
  @FBars[0],
  FBarCount,
  FDynamicRangeDB
);

Move(
  FBars[0],
  FCurrentFrame.Bars[0],
  FBarCount * SizeOf(Single)
);

end;

function TAuroraSpectrumEngine.GetBars: PSingle;
begin
  if Length(FBars) = 0 then
    Exit(nil);

  Result := @FBars[0];
end;

procedure TAuroraSpectrumEngine.PushInterleavedFloat32(
  const ASamples: PSingle;
  const ASampleFrameCount: Integer;
  const AChannelCount: Integer);
var
  TempMono: TArray<Single>;
  Input: PSingleArray;
  FrameIndex: Integer;
  ChannelIndex: Integer;
  ScalarIndex: Integer;
  Sum: Single;
begin
  ValidateInput(ASamples, FFFTSize, AChannelCount);

  if ASampleFrameCount <= 0 then
    Exit;

  SetLength(TempMono, ASampleFrameCount);
  Input := PSingleArray(ASamples);

  for FrameIndex := 0 to ASampleFrameCount - 1 do
  begin
    Sum := 0.0;
    ScalarIndex := FrameIndex * AChannelCount;

    for ChannelIndex := 0 to AChannelCount - 1 do
      Sum := Sum + Input^[ScalarIndex + ChannelIndex];

    TempMono[FrameIndex] := Sum / AChannelCount;
  end;

  FRingBuffer.Write(@TempMono[0], ASampleFrameCount);
end;

function TAuroraSpectrumEngine.TryProcessFrame: Boolean;
begin
  Result := False;

  if FRingBuffer.Available < FFFTSize then
    Exit;

 // FRingBuffer.Read(@FFrameBuffer[0], FFFTSize);
 FRingBuffer.Peek(@FFrameBuffer[0], FFFTSize);

  Move(
    FFrameBuffer[0],
    FMono[0],
    FFFTSize * SizeOf(Single)
  );

  FWindow.ApplyInPlace(@FMono[0]);
  BuildComplexInput;

  TRadix2FFT.Execute(
    FFFTPlan,
    PComplex32(@FComplex[0]),
    TFFTDirection.Forward
  );

  TMagnitude.ComputePower(
    PComplex32(@FComplex[0]),
    @FMagnitudes[0],
    FFFTSize div 2
  );

  FSpectrum.Analyze(
    @FMagnitudes[0],
    @FRawBars[0]
  );


TSignalNormalizer.NormalizePowerTo01(
  @FRawBars[0],
  @FBars[0],
  FBarCount,
  FDynamicRangeDB
);

  Move(
    FBars[0],
    FCurrentFrame.Bars[0],
    FBarCount * SizeOf(Single)
  );

  FCurrentFrame.Peak := 0.0;

  for I := 0 to FBarCount - 1 do
    if FBars[I] > FCurrentFrame.Peak then
      FCurrentFrame.Peak := FBars[I];

  Sum := 0.0;

  for I := 0 to FBarCount - 1 do
    Sum := Sum + FBars[I] * FBars[I];

  FCurrentFrame.RMS := Sqrt(Sum / FBarCount);
  FCurrentFrame.Energy := FCurrentFrame.RMS;
  Inc(FCurrentFrame.TimeStamp, FHopSize);


  FRingBuffer.Drop(FHopSize);
  Result := True;
end;

end.