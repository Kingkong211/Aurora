{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                          }
{                                                                              }
{  Unit: Aurora.Core.Math                                                      }
{                                                                              }
{  Description: General mathematical helper functions shared by Aurora.        }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                           }
{                                                                              }
{  License: MIT                                                                }
{                                                                              }
{******************************************************************************}

unit Aurora.Core.Math;

interface

uses
  System.Math;

function Clamp(const AValue, AMin, AMax: Integer): Integer; overload;
function Clamp(const AValue, AMin, AMax: Single): Single; overload;

function Lerp(const A, B, T: Single): Single;

function NearlyEqual(
  const A,
        B : Double;
  const Epsilon : Double = 1E-12): Boolean;

function IsPowerOfTwo(const AValue: Cardinal): Boolean;

function NextPowerOfTwo(const AValue: Cardinal): Cardinal;

function AlignUp(
  const AValue,
        AAlignment : Cardinal): Cardinal;

implementation

function Clamp(
  const AValue,
        AMin,
        AMax: Integer): Integer;
begin
  if AValue < AMin then
    Exit(AMin);

  if AValue > AMax then
    Exit(AMax);

  Result := AValue;
end;

function Clamp(
  const AValue,
        AMin,
        AMax: Single): Single;
begin
  if AValue < AMin then
    Exit(AMin);

  if AValue > AMax then
    Exit(AMax);

  Result := AValue;
end;

function Lerp(
  const A,
        B,
        T: Single): Single;
begin
  Result := A + (B - A) * T;
end;

function NearlyEqual(
  const A,
        B: Double;
  const Epsilon: Double): Boolean;
begin
  Result := Abs(A - B) <= Epsilon;
end;

function IsPowerOfTwo(const AValue: Cardinal): Boolean;
begin
  Result :=
    (AValue <> 0) and
    ((AValue and (AValue - 1)) = 0);
end;

function NextPowerOfTwo(
  const AValue: Cardinal): Cardinal;
var
  Value: Cardinal;
begin
  if AValue <= 1 then
    Exit(1);

  Value := AValue - 1;

  Value := Value or (Value shr 1);
  Value := Value or (Value shr 2);
  Value := Value or (Value shr 4);
  Value := Value or (Value shr 8);
  Value := Value or (Value shr 16);

  Result := Value + 1;
end;

function AlignUp(
  const AValue,
        AAlignment: Cardinal): Cardinal;
begin
  if AAlignment = 0 then
    Exit(AValue);

  Result :=
    ((AValue + AAlignment - 1) div AAlignment) * AAlignment;
end;

end.