{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.DSP.FFT.Plan                                                    }
{                                                                              }
{  Description: Precomputed FFT plan for radix-2 transforms.                    }
{                                                                              }
{******************************************************************************}

unit Aurora.DSP.FFT.Plan;

interface

{$SCOPEDENUMS ON}

uses
  Aurora.Numerics.Complex;

type
  TFFTDirection = (
    Forward,
    Inverse
  );

  TFFTPlan = class
  private
    FSize: Integer;
    FStages: Integer;
    FBitReverse: TArray<Integer>;
    FTwiddles: TArray<TComplex32>;

    procedure ValidateSize(const ASize: Integer);
    procedure BuildBitReverse;
    procedure BuildTwiddles;

    class function IsPowerOfTwo(const AValue: Integer): Boolean; static;
    class function Log2Int(const AValue: Integer): Integer; static;
    class function ReverseBits(
      const AValue: Integer;
      const ABitCount: Integer): Integer; static;
  public
    constructor Create(const ASize: Integer);

    property Size: Integer read FSize;
    property Stages: Integer read FStages;

    property BitReverse: TArray<Integer> read FBitReverse;
    property Twiddles: TArray<TComplex32> read FTwiddles;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

{ TFFTPlan }

constructor TFFTPlan.Create(const ASize: Integer);
begin
  inherited Create;

  ValidateSize(ASize);

  FSize := ASize;
  FStages := Log2Int(FSize);

  SetLength(FBitReverse, FSize);
  SetLength(FTwiddles, FSize div 2);

  BuildBitReverse;
  BuildTwiddles;
end;

procedure TFFTPlan.ValidateSize(const ASize: Integer);
begin
  if ASize < 2 then
    raise EArgumentOutOfRangeException.Create('FFT size must be at least 2.');

  if not IsPowerOfTwo(ASize) then
    raise EArgumentException.Create('FFT size must be a power of two.');
end;

class function TFFTPlan.IsPowerOfTwo(const AValue: Integer): Boolean;
begin
  Result :=
    (AValue > 0) and
    ((AValue and (AValue - 1)) = 0);
end;

class function TFFTPlan.Log2Int(const AValue: Integer): Integer;
var
  Value: Integer;
begin
  Result := 0;
  Value := AValue;

  while Value > 1 do
  begin
    Value := Value shr 1;
    Inc(Result);
  end;
end;

class function TFFTPlan.ReverseBits(
  const AValue: Integer;
  const ABitCount: Integer): Integer;
var
  Index: Integer;
  Value: Integer;
begin
  Result := 0;
  Value := AValue;

  for Index := 0 to ABitCount - 1 do
  begin
    Result := (Result shl 1) or (Value and 1);
    Value := Value shr 1;
  end;
end;

procedure TFFTPlan.BuildBitReverse;
var
  Index: Integer;
begin
  for Index := 0 to FSize - 1 do
    FBitReverse[Index] := ReverseBits(Index, FStages);
end;

procedure TFFTPlan.BuildTwiddles;
var
  Index: Integer;
  Angle: Double;
begin
  for Index := 0 to (FSize div 2) - 1 do
  begin
    Angle := -2.0 * Pi * Index / FSize;

    FTwiddles[Index] := TComplex32.Create(
      Single(Cos(Angle)),
      Single(Sin(Angle))
    );
  end;
end;

end.