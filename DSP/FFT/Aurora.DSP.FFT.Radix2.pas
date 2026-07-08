{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.DSP.FFT.Radix2                                                  }
{                                                                              }
{  Description: In-place radix-2 FFT implementation.                            }
{                                                                              }
{******************************************************************************}

unit Aurora.DSP.FFT.Radix2;

interface

{$SCOPEDENUMS ON}

uses
  Aurora.Numerics.Complex,
  Aurora.DSP.FFT.Plan;

type
  TRadix2FFT = class
  public
    class procedure Execute(
      const APlan: TFFTPlan;
      const ABuffer: PComplex32;
      const ADirection: TFFTDirection); static;
  end;

implementation

uses
  System.SysUtils;

{ TRadix2FFT }

class procedure TRadix2FFT.Execute(
  const APlan: TFFTPlan;
  const ABuffer: PComplex32;
  const ADirection: TFFTDirection);
var
  Size: Integer;
  Index: Integer;
  SwapIndex: Integer;
  HalfSize: Integer;
  StepSize: Integer;
  TableStep: Integer;
  GroupStart: Integer;
  PairIndex: Integer;
  TwiddleIndex: Integer;
  Temp: TComplex32;
  Twiddle: TComplex32;
  EvenValue: TComplex32;
  OddValue: TComplex32;
  Scale: Single;
begin
  if APlan = nil then
    raise EArgumentNilException.Create('FFT plan must not be nil.');

  if ABuffer = nil then
    raise EArgumentNilException.Create('FFT buffer must not be nil.');

  Size := APlan.Size;

  { Bit-reversal permutation. }
  for Index := 0 to Size - 1 do
  begin
    SwapIndex := APlan.BitReverse[Index];

    if SwapIndex > Index then
    begin
      Temp := ABuffer[Index];
      ABuffer[Index] := ABuffer[SwapIndex];
      ABuffer[SwapIndex] := Temp;
    end;
  end;

  HalfSize := 1;

  while HalfSize < Size do
  begin
    StepSize := HalfSize * 2;
    TableStep := Size div StepSize;

    GroupStart := 0;

    while GroupStart < Size do
    begin
      TwiddleIndex := 0;

      for PairIndex := GroupStart to GroupStart + HalfSize - 1 do
      begin
        Twiddle := APlan.Twiddles[TwiddleIndex];

        if ADirection = TFFTDirection.Inverse then
          Twiddle.Imag := -Twiddle.Imag;

        EvenValue := ABuffer[PairIndex];
        OddValue := ABuffer[PairIndex + HalfSize] * Twiddle;

        ABuffer[PairIndex] := EvenValue + OddValue;
        ABuffer[PairIndex + HalfSize] := EvenValue - OddValue;

        Inc(TwiddleIndex, TableStep);
      end;

      Inc(GroupStart, StepSize);
    end;

    HalfSize := StepSize;
  end;

  if ADirection = TFFTDirection.Inverse then
  begin
    Scale := 1.0 / Size;

    for Index := 0 to Size - 1 do
      ABuffer[Index] := ABuffer[Index] * Scale;
  end;
end;

end.