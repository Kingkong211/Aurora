{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Core.RingBuffer                                                 }
{                                                                              }
{  Description: Float32 ring buffer for real-time signal pipelines.             }
{                                                                              }
{******************************************************************************}

unit Aurora.Core.RingBuffer;

interface

{$SCOPEDENUMS ON}

type
  TFloatRingBuffer = class
  private
    FData: TArray<Single>;
    FCapacity: Integer;
    FReadPos: Integer;
    FWritePos: Integer;
    FCount: Integer;

    procedure ValidateCapacity(const ACapacity: Integer);
    function IncrementPosition(
      const APosition: Integer;
      const ADelta: Integer): Integer;
  public
    constructor Create(const ACapacity: Integer);

    procedure Clear;

    function Write(
      const ASamples: PSingle;
      const ACount: Integer): Integer;

    function Read(
      const ADestination: PSingle;
      const ACount: Integer): Integer;

    function Peek(
      const ADestination: PSingle;
      const ACount: Integer): Integer;

    function Drop(const ACount: Integer): Integer;

    property Capacity: Integer read FCapacity;
    property Available: Integer read FCount;
    property FreeSpace: Integer read FCapacity;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

{ TFloatRingBuffer }

constructor TFloatRingBuffer.Create(const ACapacity: Integer);
begin
  inherited Create;

  ValidateCapacity(ACapacity);

  FCapacity := ACapacity;
  SetLength(FData, FCapacity);

  Clear;
end;

procedure TFloatRingBuffer.ValidateCapacity(const ACapacity: Integer);
begin
  if ACapacity <= 0 then
    raise EArgumentOutOfRangeException.Create('Ring buffer capacity must be positive.');
end;

procedure TFloatRingBuffer.Clear;
begin
  FReadPos := 0;
  FWritePos := 0;
  FCount := 0;
end;

function TFloatRingBuffer.IncrementPosition(
  const APosition: Integer;
  const ADelta: Integer): Integer;
begin
  Result := APosition + ADelta;

  if Result >= FCapacity then
    Result := Result mod FCapacity;
end;

function TFloatRingBuffer.Write(
  const ASamples: PSingle;
  const ACount: Integer): Integer;
var
  Source: PSingleArray;
  FirstChunk: Integer;
  Remaining: Integer;
begin
  if ACount < 0 then
    raise EArgumentOutOfRangeException.Create('Write count must be non-negative.');

  if ACount = 0 then
    Exit(0);

  if ASamples = nil then
    raise EArgumentNilException.Create('Samples pointer must not be nil.');

  Result := Min(ACount, FCapacity - FCount);

  if Result <= 0 then
    Exit(0);

  Source := PSingleArray(ASamples);

  FirstChunk := Min(Result, FCapacity - FWritePos);
  Move(Source^[0], FData[FWritePos], FirstChunk * SizeOf(Single));

  Remaining := Result - FirstChunk;

  if Remaining > 0 then
    Move(Source^[FirstChunk], FData[0], Remaining * SizeOf(Single));

  FWritePos := IncrementPosition(FWritePos, Result);
  Inc(FCount, Result);
end;

function TFloatRingBuffer.Read(
  const ADestination: PSingle;
  const ACount: Integer): Integer;
begin
  Result := Peek(ADestination, ACount);
  Drop(Result);
end;

function TFloatRingBuffer.Peek(
  const ADestination: PSingle;
  const ACount: Integer): Integer;
var
  Destination: PSingleArray;
  FirstChunk: Integer;
  Remaining: Integer;
begin
  if ACount < 0 then
    raise EArgumentOutOfRangeException.Create('Read count must be non-negative.');

  if ACount = 0 then
    Exit(0);

  if ADestination = nil then
    raise EArgumentNilException.Create('Destination pointer must not be nil.');

  Result := Min(ACount, FCount);

  if Result <= 0 then
    Exit(0);

  Destination := PSingleArray(ADestination);

  FirstChunk := Min(Result, FCapacity - FReadPos);
  Move(FData[FReadPos], Destination^[0], FirstChunk * SizeOf(Single));

  Remaining := Result - FirstChunk;

  if Remaining > 0 then
    Move(FData[0], Destination^[FirstChunk], Remaining * SizeOf(Single));
end;

function TFloatRingBuffer.Drop(const ACount: Integer): Integer;
begin
  if ACount < 0 then
    raise EArgumentOutOfRangeException.Create('Drop count must be non-negative.');

  Result := Min(ACount, FCount);

  if Result <= 0 then
    Exit(0);

  FReadPos := IncrementPosition(FReadPos, Result);
  Dec(FCount, Result);
end;

end.