unit Aurora.Analysis.Envelope;

interface

{$SCOPEDENUMS ON}

type
  TEnvelopeFollower = class
  private
    FCount: Integer;
    FAttack: Single;
    FRelease: Single;
    FValues: TArray<Single>;
  public
    constructor Create(
      const ACount: Integer;
      const AAttack: Single = 0.55;
      const ARelease: Single = 0.12);

    procedure Reset;

    procedure Process(
      const AInput: PSingle;
      const AOutput: PSingle);

    property Count: Integer read FCount;
    property Attack: Single read FAttack write FAttack;
    property Release: Single read FRelease write FRelease;
  end;

implementation

uses
  System.SysUtils;

type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

constructor TEnvelopeFollower.Create(
  const ACount: Integer;
  const AAttack: Single;
  const ARelease: Single);
begin
  inherited Create;

  if ACount <= 0 then
    raise EArgumentOutOfRangeException.Create('Envelope count must be positive.');

  FCount := ACount;
  FAttack := AAttack;
  FRelease := ARelease;

  SetLength(FValues, FCount);
  Reset;
end;

procedure TEnvelopeFollower.Reset;
var
  Index: Integer;
begin
  for Index := 0 to FCount - 1 do
    FValues[Index] := 0.0;
end;

procedure TEnvelopeFollower.Process(
  const AInput: PSingle;
  const AOutput: PSingle);
var
  Index: Integer;
  Input: PSingleArray;
  Output: PSingleArray;
  Target: Single;
  Coeff: Single;
begin
  if AInput = nil then
    raise EArgumentNilException.Create('Input pointer must not be nil.');

  if AOutput = nil then
    raise EArgumentNilException.Create('Output pointer must not be nil.');

  Input := PSingleArray(AInput);
  Output := PSingleArray(AOutput);

  for Index := 0 to FCount - 1 do
  begin
    Target := Input^[Index];

    if Target > FValues[Index] then
      Coeff := FAttack
    else
      Coeff := FRelease;

    FValues[Index] :=
      FValues[Index] +
      (Target - FValues[Index]) * Coeff;

    if FValues[Index] < 0.0 then
      FValues[Index] := 0.0
    else if FValues[Index] > 1.0 then
      FValues[Index] := 1.0;

    Output^[Index] := FValues[Index];
  end;
end;

end.