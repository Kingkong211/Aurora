{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Core.Buffer                                                     }
{                                                                              }
{  Description: Owned Float32 signal buffer for interleaved sample data.        }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                            }
{                                                                              }
{  License: MIT                                                                 }
{                                                                              }
{******************************************************************************}

unit Aurora.Core.Buffer;

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  Aurora.Core.Types,
  Aurora.Core.Interfaces;

type
  /// <summary>
  /// Owns interleaved Float32 signal data.
  /// </summary>
  /// <remarks>
  /// SampleCount is measured in sample frames, not scalar float values.
  /// For stereo audio, one sample frame contains two Float32 values.
  /// </remarks>
  TSignalBuffer = class(TInterfacedObject, ISignalProvider)
  private
    FDescriptor: TSignalDescriptor;
    FData: TArray<Single>;
    FSampleCount: Integer;

    function GetDescriptor: TSignalDescriptor;
    function GetScalarCount: Integer;
    function GetCapacitySamples: Integer;

    procedure ValidateDescriptor(const ADescriptor: TSignalDescriptor);
    procedure EnsureCapacityScalars(const AScalarCount: Integer);
  public
    constructor Create(const ADescriptor: TSignalDescriptor);

    procedure Clear;
    procedure ReserveSamples(const ASampleCapacity: Integer);

    procedure AppendFloat32(
      const ASamples: PSingle;
      const ASampleCount: Integer);

    function CanRead(const ARegion: TSignalRegion): Boolean;

    function ReadFloat32(
      const ARegion: TSignalRegion;
      const ADestination: PSingle;
      const ADestinationSampleCapacity: Integer): Integer;

    function GetReadPointer(const AStartSample: TSampleIndex): PSingle;

    property Descriptor: TSignalDescriptor read GetDescriptor;
    property SampleCount: Integer read FSampleCount;
    property ScalarCount: Integer read GetScalarCount;
    property CapacitySamples: Integer read GetCapacitySamples;
  end;

implementation

{ TSignalBuffer }

constructor TSignalBuffer.Create(const ADescriptor: TSignalDescriptor);
begin
  inherited Create;
  ValidateDescriptor(ADescriptor);

  FDescriptor := ADescriptor;
  FSampleCount := 0;
end;

procedure TSignalBuffer.ValidateDescriptor(const ADescriptor: TSignalDescriptor);
begin
  if not ADescriptor.IsValid then
    raise EArgumentException.Create('Invalid signal descriptor.');

  if ADescriptor.SampleFormat <> TSampleFormat.Float32 then
    raise EArgumentException.Create('TSignalBuffer stores Float32 samples only.');
end;

function TSignalBuffer.GetDescriptor: TSignalDescriptor;
begin
  Result := FDescriptor;
end;

function TSignalBuffer.GetScalarCount: Integer;
begin
  Result := FSampleCount * FDescriptor.ChannelCount;
end;

function TSignalBuffer.GetCapacitySamples: Integer;
begin
  if FDescriptor.ChannelCount <= 0 then
    Exit(0);

  Result := Length(FData) div FDescriptor.ChannelCount;
end;

procedure TSignalBuffer.EnsureCapacityScalars(const AScalarCount: Integer);
begin
  if AScalarCount <= Length(FData) then
    Exit;

  SetLength(FData, AScalarCount);
end;

procedure TSignalBuffer.Clear;
begin
  FSampleCount := 0;
end;

procedure TSignalBuffer.ReserveSamples(const ASampleCapacity: Integer);
var
  ScalarCapacity: Integer;
begin
  if ASampleCapacity < 0 then
    raise EArgumentOutOfRangeException.Create('Sample capacity must be non-negative.');

  ScalarCapacity := ASampleCapacity * FDescriptor.ChannelCount;
  EnsureCapacityScalars(ScalarCapacity);
end;

procedure TSignalBuffer.AppendFloat32(
  const ASamples: PSingle;
  const ASampleCount: Integer);
var
  OldScalarCount: Integer;
  AppendScalarCount: Integer;
begin
  if ASampleCount < 0 then
    raise EArgumentOutOfRangeException.Create('Sample count must be non-negative.');

  if ASampleCount = 0 then
    Exit;

  if ASamples = nil then
    raise EArgumentNilException.Create('Samples pointer must not be nil.');

  OldScalarCount := GetScalarCount;
  AppendScalarCount := ASampleCount * FDescriptor.ChannelCount;

  EnsureCapacityScalars(OldScalarCount + AppendScalarCount);

  Move(
    ASamples^,
    FData[OldScalarCount],
    AppendScalarCount * SizeOf(Single)
  );

  Inc(FSampleCount, ASampleCount);
end;

function TSignalBuffer.CanRead(const ARegion: TSignalRegion): Boolean;
begin
  Result :=
    ARegion.IsValid and
    (ARegion.EndSampleExclusive <= FSampleCount);
end;

function TSignalBuffer.ReadFloat32(
  const ARegion: TSignalRegion;
  const ADestination: PSingle;
  const ADestinationSampleCapacity: Integer): Integer;
var
  ScalarCount: Integer;
  Source: PSingle;
begin
  Result := 0;

  if not CanRead(ARegion) then
    Exit;

  if ARegion.IsEmpty then
    Exit;

  if ADestination = nil then
    raise EArgumentNilException.Create('Destination pointer must not be nil.');

  if ADestinationSampleCapacity < ARegion.SampleCount then
    raise EArgumentOutOfRangeException.Create('Destination sample capacity is too small.');

  Source := GetReadPointer(ARegion.StartSample);
  ScalarCount := ARegion.SampleCount * FDescriptor.ChannelCount;

  Move(
    Source^,
    ADestination^,
    ScalarCount * SizeOf(Single)
  );

  Result := ARegion.SampleCount;
end;

function TSignalBuffer.GetReadPointer(const AStartSample: TSampleIndex): PSingle;
var
  ScalarIndex: Int64;
begin
  if (AStartSample < 0) or (AStartSample >= FSampleCount) then
    raise EArgumentOutOfRangeException.Create('Start sample is outside the buffer.');

  ScalarIndex := AStartSample * FDescriptor.ChannelCount;

  if ScalarIndex > High(Integer) then
    raise ERangeError.Create('Signal buffer is too large for this build.');

  Result := @FData[Integer(ScalarIndex)];
end;

end.