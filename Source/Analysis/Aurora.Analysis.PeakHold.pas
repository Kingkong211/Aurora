{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Analysis.PeakHold                                               }
{                                                                              }
{  Description: Peak hold processor for normalized spectrum bars.               }
{                                                                              }
{******************************************************************************}

unit Aurora.Analysis.PeakHold;

interface

{$SCOPEDENUMS ON}

type
  TPeakHold = class
  private
    FCount: Integer;
    FDecay: Single;
    FPeaks: TArray<Single>;
  public
    constructor Create(
      const ACount: Integer;
      const ADecay: Single = 0.96);

    procedure Reset;

    procedure Process(
      const AInput: PSingle;
      const AOutput: PSingle);

    property Count: Integer read FCount;
    property Decay: Single read FDecay write FDecay;
  end;

implementation

uses
  System.SysUtils;

type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

constructor TPeakHold.Create(
  const ACount: Integer;
  const ADecay: Single);
begin
  inherited Create;

  if ACount <= 0 then
    raise EArgumentOutOfRangeException.Create('Peak count must be positive.');

  FCount := ACount;
  FDecay := ADecay;

  SetLength(FPeaks, FCount);
  Reset;
end;

procedure TPeakHold.Reset;
var
  Index: Integer;
begin
  for Index := 0 to FCount - 1 do
    FPeaks[Index] := 0.0;
end;

procedure TPeakHold.Process(
  const AInput: PSingle;
  const AOutput: PSingle);
var
  Index: Integer;
  Input: PSingleArray;
  Output: PSingleArray;
begin
  if AInput = nil then
    raise EArgumentNilException.Create('Input pointer must not be nil.');

  if AOutput = nil then
    raise EArgumentNilException.Create('Output pointer must not be nil.');

  Input := PSingleArray(AInput);
  Output := PSingleArray(AOutput);

  for Index := 0 to FCount - 1 do
  begin
    if Input^[Index] >= FPeaks[Index] then
      FPeaks[Index] := Input^[Index]
    else
      FPeaks[Index] := FPeaks[Index] * FDecay;

    if FPeaks[Index] < 0.0 then
      FPeaks[Index] := 0.0;

    Output^[Index] := FPeaks[Index];
  end;
end;

end.