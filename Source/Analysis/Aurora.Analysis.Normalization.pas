unit Aurora.Analysis.Normalization;

interface

{$SCOPEDENUMS ON}

type
  TSignalNormalizer = class
  public
    class procedure NormalizePowerTo01(
      const AInput: PSingle;
      const AOutput: PSingle;
      const ACount: Integer;
      const ADynamicRangeDB: Single = 60.0); static;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

class procedure TSignalNormalizer.NormalizePowerTo01(
  const AInput: PSingle;
  const AOutput: PSingle;
  const ACount: Integer;
  const ADynamicRangeDB: Single);
var
  Index: Integer;
  MaxValue: Single;
  DBValue: Single;
  Input: PSingleArray;
  Output: PSingleArray;
begin
  if AInput = nil then
    raise EArgumentNilException.Create('Input pointer must not be nil.');

  if AOutput = nil then
    raise EArgumentNilException.Create('Output pointer must not be nil.');

  if ACount < 0 then
    raise EArgumentOutOfRangeException.Create('Count must be non-negative.');

  if ADynamicRangeDB <= 0.0 then
    raise EArgumentOutOfRangeException.Create('Dynamic range must be positive.');

  Input := PSingleArray(AInput);
  Output := PSingleArray(AOutput);

  MaxValue := 0.0;

  for Index := 0 to ACount - 1 do
    if Input^[Index] > MaxValue then
      MaxValue := Input^[Index];

  if MaxValue <= 0.0 then
  begin
    for Index := 0 to ACount - 1 do
      Output^[Index] := 0.0;

    Exit;
  end;

  for Index := 0 to ACount - 1 do
  begin
    if Input^[Index] <= 0.0 then
      DBValue := -ADynamicRangeDB
    else
      DBValue := Single(10.0 * Log10(Input^[Index] / MaxValue));

    Output^[Index] := (DBValue + ADynamicRangeDB) / ADynamicRangeDB;

    if Output^[Index] < 0.0 then
      Output^[Index] := 0.0
    else if Output^[Index] > 1.0 then
      Output^[Index] := 1.0;
  end;
end;

end.