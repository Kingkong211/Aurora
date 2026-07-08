{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Audio.FileSignalSource                                          }
{                                                                              }
{  Description: File-backed Float32 signal source for Aurora examples.          }
{                                                                              }
{******************************************************************************}

unit Aurora.Audio.FileSignalSource;

interface

{$SCOPEDENUMS ON}

uses
  Aurora.Core.Buffer,
  Aurora.Audio.MediaFoundation.Decoder,
  System.SysUtils,
  System.Math,
  Aurora.Core.Types;

type
  TFileSignalSource = class
  private
    FDecoder: TMFAudioDecoder;
    FBuffer: TSignalBuffer;
    FPosition: Integer;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    function Read(
      const ADestination: PSingle;
      const ASampleFrameCount: Integer): Integer;

    function SampleRate: Integer;
    function ChannelCount: Integer;
    function SampleCount: Integer;
  end;

implementation



type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

{ TFileSignalSource }

constructor TFileSignalSource.Create(const AFileName: string);
begin
  inherited Create;

  FDecoder := TMFAudioDecoder.Create;
  FDecoder.OpenFile(AFileName);

  FBuffer := FDecoder.DecodeAll;
  FPosition := 0;
end;

destructor TFileSignalSource.Destroy;
begin
  FBuffer.Free;
  FDecoder.Free;

  inherited;
end;

function TFileSignalSource.Read(
  const ADestination: PSingle;
  const ASampleFrameCount: Integer): Integer;
var
  RegionCount: Integer;
begin
  if ADestination = nil then
    raise EArgumentNilException.Create('Destination pointer must not be nil.');

  if ASampleFrameCount < 0 then
    raise EArgumentOutOfRangeException.Create('Sample frame count must be non-negative.');

  if ASampleFrameCount = 0 then
    Exit(0);

  RegionCount := Min(ASampleFrameCount, FBuffer.SampleCount - FPosition);

  if RegionCount <= 0 then
    Exit(0);

Result :=
  FBuffer.ReadFloat32(
    TSignalRegion.Create(FPosition, RegionCount),
    ADestination,
    RegionCount
  );

  Inc(FPosition, Result);
end;

function TFileSignalSource.SampleRate: Integer;
begin
  Result := FBuffer.Descriptor.SampleRate;
end;

function TFileSignalSource.ChannelCount: Integer;
begin
  Result := FBuffer.Descriptor.ChannelCount;
end;

function TFileSignalSource.SampleCount: Integer;
begin
  Result := FBuffer.SampleCount;
end;

end.