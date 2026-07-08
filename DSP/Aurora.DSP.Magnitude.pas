{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.DSP.Magnitude                                                   }
{                                                                              }
{  Description: Magnitude conversion helpers for complex FFT output.            }
{                                                                              }
{******************************************************************************}

unit Aurora.DSP.Magnitude;

interface

{$SCOPEDENUMS ON}

uses
  Aurora.Numerics.Complex;

type
  TMagnitude = class
  public
    class procedure ComputeAmplitude(
      const AInput: PComplex32;
      const AOutput: PSingle;
      const ACount: Integer); static;

    class procedure ComputePower(
      const AInput: PComplex32;
      const AOutput: PSingle;
      const ACount: Integer); static;

    class procedure ComputeDecibel(
      const AInput: PComplex32;
      const AOutput: PSingle;
      const ACount: Integer;
      const AMinDB: Single = -90.0); static;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

type
  TComplex32Array = array[0..MaxInt div SizeOf(TComplex32) - 1] of TComplex32;
  PComplex32Array = ^TComplex32Array;

  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

{ TMagnitude }

class procedure TMagnitude.ComputeAmplitude(
  const AInput: PComplex32;
  const AOutput: PSingle;
  const ACount: Integer);
var
  Index: Integer;
  Input: PComplex32Array;
  Output: PSingleArray;
begin
  if AInput = nil then
    raise EArgumentNilException.Create('Input pointer must not be nil.');

  if AOutput = nil then
    raise EArgumentNilException.Create('Output pointer must not be nil.');

  if ACount < 0 then
    raise EArgumentOutOfRangeException.Create('Count must be non-negative.');

  Input := PComplex32Array(AInput);
  Output := PSingleArray(AOutput);

  for Index := 0 to ACount - 1 do
    Output^[Index] := Input^[Index].Magnitude;
end;

class procedure TMagnitude.ComputePower(
  const AInput: PComplex32;
  const AOutput: PSingle;
  const ACount: Integer);
var
  Index: Integer;
  Input: PComplex32Array;
  Output: PSingleArray;
begin
  if AInput = nil then
    raise EArgumentNilException.Create('Input pointer must not be nil.');

  if AOutput = nil then
    raise EArgumentNilException.Create('Output pointer must not be nil.');

  if ACount < 0 then
    raise EArgumentOutOfRangeException.Create('Count must be non-negative.');

  Input := PComplex32Array(AInput);
  Output := PSingleArray(AOutput);

  for Index := 0 to ACount - 1 do
    Output^[Index] := Input^[Index].MagnitudeSquared;
end;

class procedure TMagnitude.ComputeDecibel(
  const AInput: PComplex32;
  const AOutput: PSingle;
  const ACount: Integer;
  const AMinDB: Single);
var
  Index: Integer;
  Input: PComplex32Array;
  Output: PSingleArray;
  Amplitude: Single;
begin
  if AInput = nil then
    raise EArgumentNilException.Create('Input pointer must not be nil.');

  if AOutput = nil then
    raise EArgumentNilException.Create('Output pointer must not be nil.');

  if ACount < 0 then
    raise EArgumentOutOfRangeException.Create('Count must be non-negative.');

  Input := PComplex32Array(AInput);
  Output := PSingleArray(AOutput);

  for Index := 0 to ACount - 1 do
  begin
    Amplitude := Input^[Index].Magnitude;

    if Amplitude <= 0.0 then
      Output^[Index] := AMinDB
    else
      Output^[Index] := Max(AMinDB, Single(20.0 * Log10(Amplitude)));
  end;
end;

end.