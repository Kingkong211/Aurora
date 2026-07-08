{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Numerics.Complex                                                }
{                                                                              }
{  Description: Float32 complex number type for DSP and analysis modules.       }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                            }
{                                                                              }
{  License: MIT                                                                 }
{                                                                              }
{******************************************************************************}

unit Aurora.Numerics.Complex;

interface

{$SCOPEDENUMS ON}

type
  /// <summary>
  /// Float32 complex number.
  /// </summary>
  /// <remarks>
  /// Aurora uses Float32 for DSP hot paths to keep memory bandwidth predictable
  /// and to prepare for future SIMD optimization.
  /// </remarks>
  TComplex32 = packed record
  public
    Real: Single;
    Imag: Single;

    class function Create(
      const AReal: Single;
      const AImag: Single): TComplex32; static;

    class function Zero: TComplex32; static;
    class function One: TComplex32; static;
    class function ImaginaryOne: TComplex32; static;

    class operator Add(
      const ALeft,
            ARight: TComplex32): TComplex32;

    class operator Subtract(
      const ALeft,
            ARight: TComplex32): TComplex32;

    class operator Negative(
      const AValue: TComplex32): TComplex32;

    class operator Multiply(
      const ALeft,
            ARight: TComplex32): TComplex32;

    class operator Multiply(
      const ALeft: TComplex32;
      const ARight: Single): TComplex32;

    class operator Multiply(
      const ALeft: Single;
      const ARight: TComplex32): TComplex32;

    class operator Divide(
      const ALeft: TComplex32;
      const ARight: Single): TComplex32;

    function MagnitudeSquared: Single;
    function Magnitude: Single;
    function Conjugate: TComplex32;
  end;

implementation

uses
  System.Math;

{ TComplex32 }

class function TComplex32.Create(
  const AReal,
        AImag: Single): TComplex32;
begin
  Result.Real := AReal;
  Result.Imag := AImag;
end;

class function TComplex32.Zero: TComplex32;
begin
  Result := TComplex32.Create(0.0, 0.0);
end;

class function TComplex32.One: TComplex32;
begin
  Result := TComplex32.Create(1.0, 0.0);
end;

class function TComplex32.ImaginaryOne: TComplex32;
begin
  Result := TComplex32.Create(0.0, 1.0);
end;

class operator TComplex32.Add(
  const ALeft,
        ARight: TComplex32): TComplex32;
begin
  Result.Real := ALeft.Real + ARight.Real;
  Result.Imag := ALeft.Imag + ARight.Imag;
end;

class operator TComplex32.Subtract(
  const ALeft,
        ARight: TComplex32): TComplex32;
begin
  Result.Real := ALeft.Real - ARight.Real;
  Result.Imag := ALeft.Imag - ARight.Imag;
end;

class operator TComplex32.Negative(
  const AValue: TComplex32): TComplex32;
begin
  Result.Real := -AValue.Real;
  Result.Imag := -AValue.Imag;
end;

class operator TComplex32.Multiply(
  const ALeft,
        ARight: TComplex32): TComplex32;
begin
  Result.Real := ALeft.Real * ARight.Real - ALeft.Imag * ARight.Imag;
  Result.Imag := ALeft.Real * ARight.Imag + ALeft.Imag * ARight.Real;
end;

class operator TComplex32.Multiply(
  const ALeft: TComplex32;
  const ARight: Single): TComplex32;
begin
  Result.Real := ALeft.Real * ARight;
  Result.Imag := ALeft.Imag * ARight;
end;

class operator TComplex32.Multiply(
  const ALeft: Single;
  const ARight: TComplex32): TComplex32;
begin
  Result := ARight * ALeft;
end;

class operator TComplex32.Divide(
  const ALeft: TComplex32;
  const ARight: Single): TComplex32;
begin
  Result.Real := ALeft.Real / ARight;
  Result.Imag := ALeft.Imag / ARight;
end;

function TComplex32.MagnitudeSquared: Single;
begin
  Result := Real * Real + Imag * Imag;
end;

function TComplex32.Magnitude: Single;
begin
  Result := Sqrt(MagnitudeSquared);
end;

function TComplex32.Conjugate: TComplex32;
begin
  Result.Real := Real;
  Result.Imag := -Imag;
end;

end.