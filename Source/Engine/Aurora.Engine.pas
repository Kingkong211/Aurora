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
  Aurora.Analysis.Spectrum;

type
  TAuroraSpectrumEngine = class
  private
    FSampleRate: Integer;
    FFFTSize: Integer;
    FBarCount: Integer;
    FDynamicRangeDB: Single;

    FWindow: TWindowPlan;
    FFFTPlan: TFFTPlan;
    FSpectrum: TSpectrumAnalyzer;

    FMono: TArray<Single>;
    FComplex: TArray<TComplex32>;
    FMagnitudes: TArray<Single>;
    FRawBars: TArray<Single>;
    FBars: TArray<Single>;

    procedure ValidateInput(
      const ASamples: PSingle;
      const ASampleFrameCount: Integer;
      const AChannelCount: Integer);

    procedure ConvertInterleavedToMono(
      const ASamples: PSingle;
      const ASampleFrameCount: Integer;
      const AChannelCount: Integer);

    procedure BuildComplexInput;
    procedure NormalizeBars;
  public
    constructor Create(
      const ASampleRate: Integer;
      const AFFTSize: Integer = 2048;
      const ABarCount: Integer = 80);

    destructor Destroy; override;

    procedure ProcessInterleavedFloat32(
      const ASamples: PSingle;
      const ASampleFrameCount: Integer;
      const AChannelCount: Integer);

    function BarsPointer: PSingle;

    property SampleRate: Integer read FSampleRate;
    property FFTSize: Integer read FFFTSize;
    property BarCount: Integer read FBarCount;
    property DynamicRangeDB: Single read FDynamicRangeDB write FDynamicRangeDB;
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
end;

destructor TAuroraSpectrumEngine.Destroy;
begin
  FSpectrum.Free;
  FFFTPlan.Free;
  FWindow.Free;

  inherited;
end;

procedure TAuroraSpectrumEngine.ValidateInput(
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

procedure TAuroraSpectrumEngine.NormalizeBars;
var
  Index: Integer;
  MaxValue: Single;
  DBValue: Single;
begin
  MaxValue := 0.0;

  for Index := 0 to FBarCount - 1 do
    if FRawBars[Index] > MaxValue then
      MaxValue := FRawBars[Index];

  if MaxValue <= 0.0 then
  begin
    for Index := 0 to FBarCount - 1 do
      FBars[Index] := 0.0;

    Exit;
  end;

  for Index := 0 to FBarCount - 1 do
  begin
    if FRawBars[Index] <= 0.0 then
      DBValue := -FDynamicRangeDB
    else
      DBValue := Single(10.0 * Log10(FRawBars[Index] / MaxValue));

    FBars[Index] := (DBValue + FDynamicRangeDB) / FDynamicRangeDB;

    if FBars[Index] < 0.0 then
      FBars[Index] := 0.0
    else if FBars[Index] > 1.0 then
      FBars[Index] := 1.0;
  end;
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

  NormalizeBars;
end;

function TAuroraSpectrumEngine.BarsPointer: PSingle;
begin
  if Length(FBars) = 0 then
    Exit(nil);

  Result := @FBars[0];
end;

end.