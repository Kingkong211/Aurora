{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.DSP.Window                                                      }
{                                                                              }
{  Description: Precomputed DSP window functions for Float32 buffers.           }
{                                                                              }
{******************************************************************************}

unit Aurora.DSP.Window;

interface

{$SCOPEDENUMS ON}

type
  TWindowKind = (
    Rectangular,
    Hann,
    Hamming,
    Blackman
  );

  TWindowPlan = class
  private
    FKind: TWindowKind;
    FSize: Integer;
    FCoefficients: TArray<Single>;

    procedure Build;
  public
    constructor Create(
      const AKind: TWindowKind;
      const ASize: Integer);

    procedure Apply(
      const AInput: PSingle;
      const AOutput: PSingle);

    procedure ApplyInPlace(
      const ABuffer: PSingle);

    property Kind: TWindowKind read FKind;
    property Size: Integer read FSize;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

{ TWindowPlan }

constructor TWindowPlan.Create(
  const AKind: TWindowKind;
  const ASize: Integer);
begin
  inherited Create;

  if ASize <= 0 then
    raise EArgumentOutOfRangeException.Create('Window size must be positive.');

  FKind := AKind;
  FSize := ASize;

  SetLength(FCoefficients, FSize);
  Build;
end;

procedure TWindowPlan.Build;
var
  Index: Integer;
  Phase: Double;
begin
  if FSize = 1 then
  begin
    FCoefficients[0] := 1.0;
    Exit;
  end;

  for Index := 0 to FSize - 1 do
  begin
    Phase := 2.0 * Pi * Index / (FSize - 1);

    case FKind of
      TWindowKind.Rectangular:
        FCoefficients[Index] := 1.0;

      TWindowKind.Hann:
        FCoefficients[Index] := Single(0.5 - 0.5 * Cos(Phase));

      TWindowKind.Hamming:
        FCoefficients[Index] := Single(0.54 - 0.46 * Cos(Phase));

      TWindowKind.Blackman:
        FCoefficients[Index] := Single(
          0.42 -
          0.5 * Cos(Phase) +
          0.08 * Cos(2.0 * Phase)
        );
    else
      FCoefficients[Index] := 1.0;
    end;
  end;
end;

procedure TWindowPlan.Apply(
  const AInput: PSingle;
  const AOutput: PSingle);
var
  Index: Integer;
begin
  if AInput = nil then
    raise EArgumentNilException.Create('Input pointer must not be nil.');

  if AOutput = nil then
    raise EArgumentNilException.Create('Output pointer must not be nil.');

  for Index := 0 to FSize - 1 do
    AOutput[Index] := AInput[Index] * FCoefficients[Index];
end;

procedure TWindowPlan.ApplyInPlace(
  const ABuffer: PSingle);
var
  Index: Integer;
begin
  if ABuffer = nil then
    raise EArgumentNilException.Create('Buffer pointer must not be nil.');

  for Index := 0 to FSize - 1 do
    ABuffer[Index] := ABuffer[Index] * FCoefficients[Index];
end;

end.