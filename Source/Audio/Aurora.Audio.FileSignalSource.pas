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
  Aurora.Audio.MediaFoundation.Decoder,
  System.SysUtils,
  System.Math,
  Aurora.Core.Types;

type
  TFileSignalSource = class
  private
    FDecoder: TMFAudioDecoder;
    FSampleCount: Integer;
    FPosition: Integer;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    function Read(
      const ADestination: System.PSingle;
      const ASampleFrameCount: Integer): Integer;

    function SampleRate: Integer;
    function ChannelCount: Integer;
    function SampleCount: Integer;
    procedure SeekFrame(const AFrameIndex: Integer);
    procedure SeekSeconds(const ASeconds: Double);

    property PositionFrame: Integer read FPosition;	
  end;

implementation



type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

{ TFileSignalSource }

constructor TFileSignalSource.Create(const AFileName: string);
var
  EstimatedSamples: Double;
begin
  inherited Create;

  FDecoder := TMFAudioDecoder.Create;
  try
    FDecoder.OpenFile(AFileName);
    EstimatedSamples :=
      FDecoder.Info.DurationSeconds * FDecoder.Info.Audio.Signal.SampleRate;
    if EstimatedSamples > MaxInt then
      FSampleCount := MaxInt
    else
      FSampleCount := Max(0, Round(EstimatedSamples));
    FPosition := 0;
  except
    FDecoder.Free;
    raise;
  end;
end;

destructor TFileSignalSource.Destroy;
begin
  FDecoder.Free;

  inherited;
end;

function TFileSignalSource.Read(
  const ADestination: System.PSingle;
  const ASampleFrameCount: Integer): Integer;
begin
  if ADestination = nil then
    raise EArgumentNilException.Create('Destination pointer must not be nil.');

  if ASampleFrameCount < 0 then
    raise EArgumentOutOfRangeException.Create('Sample frame count must be non-negative.');

  if ASampleFrameCount = 0 then
    Exit(0);

  Result := FDecoder.ReadFrames(ADestination, ASampleFrameCount);

  Inc(FPosition, Result);
end;

procedure TFileSignalSource.SeekFrame(
  const AFrameIndex: Integer
);
var
  NewPosition: Integer;
begin
  if AFrameIndex < 0 then
    NewPosition := 0
  else if AFrameIndex > FSampleCount then
    NewPosition := FSampleCount
  else
    NewPosition := AFrameIndex;

  FDecoder.SeekSeconds(NewPosition / SampleRate);
  FPosition := NewPosition;
end;

procedure TFileSignalSource.SeekSeconds(
  const ASeconds: Double
);
begin
  SeekFrame(
    Round(ASeconds * SampleRate)
  );
end;

function TFileSignalSource.SampleRate: Integer;
begin
  Result := FDecoder.Info.Audio.Signal.SampleRate;
end;

function TFileSignalSource.ChannelCount: Integer;
begin
  Result := FDecoder.Info.Audio.Signal.ChannelCount;
end;

function TFileSignalSource.SampleCount: Integer;
begin
  Result := FSampleCount;
end;

end.
