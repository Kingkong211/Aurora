{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Analysis.Spectrum                                               }
{                                                                              }
{  Description: Converts FFT magnitude bins into visual spectrum bars.          }
{                                                                              }
{******************************************************************************}

unit Aurora.Analysis.Spectrum;

interface

{$SCOPEDENUMS ON}

type
  TSpectrumAnalyzer = class
  private
    FFFTSize: Integer;
    FSampleRate: Integer;
    FBarCount: Integer;
    FBinCount: Integer;
    FMinFrequency: Single;
    FMaxFrequency: Single;
    FBandStart: TArray<Integer>;
    FBandEnd: TArray<Integer>;

    procedure Validate;
    procedure BuildLogBands;

    function FrequencyToBin(const AFrequency: Single): Integer;
    procedure SetMinFrequency(const AValue: Single);
    procedure SetMaxFrequency(const AValue: Single);
  public
    constructor Create(
      const AFFTSize: Integer;
      const ASampleRate: Integer;
      const ABarCount: Integer = 80);

    procedure Analyze(
      const AMagnitudes: PSingle;
      const ABars: PSingle);

    property FFTSize: Integer read FFFTSize;
    property SampleRate: Integer read FSampleRate;
    property BarCount: Integer read FBarCount;
property MinFrequency: Single read FMinFrequency write SetMinFrequency;
property MaxFrequency: Single read FMaxFrequency write SetMaxFrequency;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

{ TSpectrumAnalyzer }

constructor TSpectrumAnalyzer.Create(
  const AFFTSize: Integer;
  const ASampleRate: Integer;
  const ABarCount: Integer);
begin
  inherited Create;

  FFFTSize := AFFTSize;
  FSampleRate := ASampleRate;
  FBarCount := ABarCount;
  FBinCount := FFFTSize div 2;

  FMinFrequency := 20.0;
  FMaxFrequency := FSampleRate / 2.0;

  Validate;
  BuildLogBands;
end;

procedure TSpectrumAnalyzer.SetMinFrequency(const AValue: Single);
begin
  if AValue <= 0.0 then
    raise EArgumentOutOfRangeException.Create('Minimum frequency must be positive.');

  if AValue >= FMaxFrequency then
    raise EArgumentOutOfRangeException.Create('Minimum frequency must be lower than maximum frequency.');

  FMinFrequency := AValue;
  BuildLogBands;
end;

procedure TSpectrumAnalyzer.SetMaxFrequency(const AValue: Single);
begin
  if AValue <= FMinFrequency then
    raise EArgumentOutOfRangeException.Create('Maximum frequency must be higher than minimum frequency.');

  if AValue > FSampleRate / 2.0 then
    raise EArgumentOutOfRangeException.Create('Maximum frequency must not exceed Nyquist frequency.');

  FMaxFrequency := AValue;
  BuildLogBands;
end;

procedure TSpectrumAnalyzer.Validate;
begin
  if FFFTSize < 2 then
    raise EArgumentOutOfRangeException.Create('FFT size must be at least 2.');

  if (FFFTSize and (FFFTSize - 1)) <> 0 then
    raise EArgumentException.Create('FFT size must be a power of two.');

  if FSampleRate <= 0 then
    raise EArgumentOutOfRangeException.Create('Sample rate must be positive.');

  if FBarCount <= 0 then
    raise EArgumentOutOfRangeException.Create('Bar count must be positive.');
end;

function TSpectrumAnalyzer.FrequencyToBin(
  const AFrequency: Single): Integer;
begin
  Result := Round(AFrequency * FFFTSize / FSampleRate);

  if Result < 0 then
    Result := 0;

  if Result >= FBinCount then
    Result := FBinCount - 1;
end;

procedure TSpectrumAnalyzer.BuildLogBands;
var
  BarIndex: Integer;
  StartFrequency: Single;
  EndFrequency: Single;
  Ratio: Double;
begin
  SetLength(FBandStart, FBarCount);
  SetLength(FBandEnd, FBarCount);

  Ratio := Power(FMaxFrequency / FMinFrequency, 1.0 / FBarCount);

  StartFrequency := FMinFrequency;

  for BarIndex := 0 to FBarCount - 1 do
  begin
    EndFrequency := StartFrequency * Single(Ratio);

    FBandStart[BarIndex] := FrequencyToBin(StartFrequency);
    FBandEnd[BarIndex] := FrequencyToBin(EndFrequency);

    if FBandEnd[BarIndex] <= FBandStart[BarIndex] then
      FBandEnd[BarIndex] := FBandStart[BarIndex] + 1;

    if FBandEnd[BarIndex] >= FBinCount then
      FBandEnd[BarIndex] := FBinCount - 1;

    StartFrequency := EndFrequency;
  end;
end;

procedure TSpectrumAnalyzer.Analyze(
  const AMagnitudes: PSingle;
  const ABars: PSingle);
var
  BarIndex: Integer;
  BinIndex: Integer;
  StartBin: Integer;
  EndBin: Integer;
  MaxValue: Single;
  Magnitudes: PSingleArray;
  Bars: PSingleArray;
begin
  if AMagnitudes = nil then
    raise EArgumentNilException.Create('Magnitude pointer must not be nil.');

  if ABars = nil then
    raise EArgumentNilException.Create('Bars pointer must not be nil.');

  Magnitudes := PSingleArray(AMagnitudes);
  Bars := PSingleArray(ABars);

  for BarIndex := 0 to FBarCount - 1 do
  begin
    StartBin := FBandStart[BarIndex];
    EndBin := FBandEnd[BarIndex];

    MaxValue := 0.0;

    for BinIndex := StartBin to EndBin do
    begin
      if Magnitudes^[BinIndex] > MaxValue then
        MaxValue := Magnitudes^[BinIndex];
    end;

    Bars^[BarIndex] := MaxValue;
  end;
end;

end.