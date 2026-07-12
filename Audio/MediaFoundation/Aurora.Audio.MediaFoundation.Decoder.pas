{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Audio.MediaFoundation.Decoder                                   }
{                                                                              }
{  Description: Media Foundation audio decoder using IMFSourceReader.           }
{                                                                              }
{******************************************************************************}

unit Aurora.Audio.MediaFoundation.Decoder;

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  WinApi.Windows,
  WinApi.ActiveX,
  WinApi.ActiveX.PropIdl,
  WinApi.MediaFoundationApi.MfApi,
  WinApi.MediaFoundationApi.MfIdl,
  WinApi.MediaFoundationApi.MfObjects,
  WinApi.MediaFoundationApi.MfReadWrite,
  Aurora.Core.Types,
  Aurora.Core.Buffer,
  Aurora.Audio.Types,
  Aurora.Audio.MediaFoundation.Types,
  System.Math;

type
  TMFAudioDecoder = class
  private
    FInfo: TMFDecoderInfo;
    FState: TMFDecoderState;
    FReader: IMFSourceReader;
    FPending: TArray<Single>;
    FPendingOffset: Integer;
    FPendingCount: Integer;
    FEndOfStream: Boolean;

    procedure CheckHR(const AHR: HRESULT; const AMessage: string);
    procedure RequireOpen;
    procedure ConfigureFloat32Output;
    procedure ReadDuration;
    function LoadNextBlock: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Close;
    procedure OpenFile(const AFileName: string);

    function ReadFrames(const ADestination: System.PSingle;
      const ASampleFrameCount: Integer): Integer;
    procedure SeekSeconds(const ASeconds: Double);

    function DecodeAll: TSignalBuffer;

    property Info: TMFDecoderInfo read FInfo;
    property State: TMFDecoderState read FState;
  end;

implementation

{ TMFAudioDecoder }

type
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

constructor TMFAudioDecoder.Create;
begin
  inherited Create;
  FInfo := TMFDecoderInfo.Empty;
  FState := TMFDecoderState.Closed;
  FPendingOffset := 0;
  FPendingCount := 0;
  FEndOfStream := False;
  SetLength(FPending, 0);
end;

destructor TMFAudioDecoder.Destroy;
begin
  Close;
  inherited;
end;

{
procedure TMFAudioDecoder.CheckHR(
  const AHR: HRESULT;
  const AMessage: string);
begin
  if Failed(AHR) then
  begin
    FState := TMFDecoderState.Error;
    raise EOleException.Create(AMessage, AHR, '', '', 0);
  end;
end;  }
procedure TMFAudioDecoder.CheckHR(
  const AHR: HRESULT;
  const AMessage: string);
begin
  if Failed(AHR) then
  begin
    FState := TMFDecoderState.Error;
    raise Exception.CreateFmt(
      '%s HRESULT: 0x%.8x',
      [AMessage, Cardinal(AHR)]
    );
  end;
end;

procedure TMFAudioDecoder.Close;
begin
  SetLength(FPending, 0);
  FPendingOffset := 0;
  FPendingCount := 0;
  FEndOfStream := False;
  FReader := nil;
  FInfo := TMFDecoderInfo.Empty;
  FState := TMFDecoderState.Closed;
end;

procedure TMFAudioDecoder.OpenFile(const AFileName: string);
begin
  if AFileName.Trim = '' then
    raise EArgumentException.Create('File name must not be empty.');

  if not FileExists(AFileName) then
    raise EFileNotFoundException.CreateFmt(
      'Audio file not found: %s',
      [AFileName]
    );

  Close;

  CheckHR(
    MFCreateSourceReaderFromURL(PWideChar(AFileName), nil, FReader),
    'Could not create Media Foundation source reader.'
  );

  ConfigureFloat32Output;
  ReadDuration;

  FInfo.FileName := AFileName;
  FState := TMFDecoderState.Open;
  FEndOfStream := False;
  FPendingOffset := 0;
  FPendingCount := 0;
  SetLength(FPending, 0);
end;

procedure TMFAudioDecoder.ConfigureFloat32Output;
var
  MediaType: IMFMediaType;
  CurrentType: IMFMediaType;
  SampleRate: UINT32;
  ChannelCount: UINT32;
begin
  CheckHR(
    MFCreateMediaType(MediaType),
    'Could not create Media Foundation media type.'
  );

  CheckHR(
    MediaType.SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio),
    'Could not set audio major type.'
  );

  CheckHR(
    MediaType.SetGUID(MF_MT_SUBTYPE, MFAudioFormat_Float),
    'Could not set Float32 audio subtype.'
  );

  CheckHR(
    FReader.SetCurrentMediaType(
      MF_SOURCE_READER_FIRST_AUDIO_STREAM,
      0,
      MediaType
    ),
    'Could not configure source reader for Float32 audio.'
  );

  CheckHR(
    FReader.GetCurrentMediaType(
      MF_SOURCE_READER_FIRST_AUDIO_STREAM,
      @CurrentType
    ),
    'Could not read current audio media type.'
  );

  CheckHR(
    CurrentType.GetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, SampleRate),
    'Could not read audio sample rate.'
  );

  CheckHR(
    CurrentType.GetUINT32(MF_MT_AUDIO_NUM_CHANNELS, ChannelCount),
    'Could not read audio channel count.'
  );

  FInfo.Audio := TAudioDescriptor.CreateFloat32Interleaved(
    Integer(SampleRate),
    Integer(ChannelCount)
  );

  FInfo.DurationSeconds := 0.0;
end;

procedure TMFAudioDecoder.ReadDuration;
var
  Value: WinApi.ActiveX.PropIdl.PROPVARIANT;
  HR: HRESULT;
begin
  FInfo.DurationSeconds := 0.0;
  WinApi.ActiveX.PropIdl.PropVariantInit(Value);
  try
    HR := FReader.GetPresentationAttribute(
      MF_SOURCE_READER_MEDIASOURCE,
      MF_PD_DURATION,
      Value
    );

    if Succeeded(HR) and (Value.vt = VT_UI8) then
      FInfo.DurationSeconds := Value.uhVal.QuadPart / 10000000.0;
  finally
    WinApi.ActiveX.PropIdl.PropVariantClear(Value);
  end;
end;

procedure TMFAudioDecoder.RequireOpen;
begin
  if (FReader = nil) or
     (FState = TMFDecoderState.Closed) or
     (FState = TMFDecoderState.Error) then
    raise Exception.Create('Decoder is not open.');
end;

function TMFAudioDecoder.LoadNextBlock: Boolean;
var
  StreamIndex: DWORD;
  Flags: DWORD;
  TimeStamp: LONGLONG;
  Sample: IMFSample;
  MediaBuffer: IMFMediaBuffer;
  Data: PByte;
  MaxLength: DWORD;
  CurrentLength: DWORD;
  ScalarCount: Integer;
  ChannelCount: Integer;
begin
  Result := False;
  FPendingOffset := 0;
  FPendingCount := 0;

  if FEndOfStream then
    Exit;

  ChannelCount := FInfo.Audio.Signal.ChannelCount;

  while not FEndOfStream do
  begin
    Sample := nil;
    MediaBuffer := nil;
    Flags := 0;

    CheckHR(
      FReader.ReadSample(
        MF_SOURCE_READER_FIRST_AUDIO_STREAM,
        0,
        @StreamIndex,
        @Flags,
        @TimeStamp,
        @Sample
      ),
      'Could not read an audio sample.'
    );

    if (Flags and MF_SOURCE_READERF_ENDOFSTREAM) <> 0 then
    begin
      FEndOfStream := True;
      FState := TMFDecoderState.EndOfStream;
      Exit;
    end;

    if Sample = nil then
      Continue;

    CheckHR(
      Sample.ConvertToContiguousBuffer(@MediaBuffer),
      'Could not convert an audio sample to a contiguous buffer.'
    );

    Data := nil;
    MaxLength := 0;
    CurrentLength := 0;

    CheckHR(
      MediaBuffer.Lock(Data, @MaxLength, @CurrentLength),
      'Could not lock an audio buffer.'
    );
    try
      ScalarCount := CurrentLength div SizeOf(Single);
      ScalarCount := (ScalarCount div ChannelCount) * ChannelCount;

      if ScalarCount <= 0 then
        Continue;

      if Length(FPending) < ScalarCount then
        SetLength(FPending, ScalarCount);
      Move(Data^, FPending[0], ScalarCount * SizeOf(Single));
      FPendingOffset := 0;
      FPendingCount := ScalarCount;
      Result := True;
      Exit;
    finally
      MediaBuffer.Unlock;
    end;
  end;
end;

function TMFAudioDecoder.ReadFrames(
  const ADestination: System.PSingle;
  const ASampleFrameCount: Integer): Integer;
var
  ChannelCount: Integer;
  RequestedScalars: Integer;
  WrittenScalars: Integer;
  AvailableScalars: Integer;
  CopyScalars: Integer;
begin
  if ADestination = nil then
    raise EArgumentNilException.Create('Destination pointer must not be nil.');

  if ASampleFrameCount < 0 then
    raise EArgumentOutOfRangeException.Create(
      'Sample frame count must be non-negative.');

  if ASampleFrameCount = 0 then
    Exit(0);

  RequireOpen;
  ChannelCount := FInfo.Audio.Signal.ChannelCount;
  RequestedScalars := ASampleFrameCount * ChannelCount;
  WrittenScalars := 0;

  while WrittenScalars < RequestedScalars do
  begin
    AvailableScalars := FPendingCount - FPendingOffset;
    if AvailableScalars <= 0 then
    begin
      if not LoadNextBlock then
        Break;
      AvailableScalars := FPendingCount;
    end;

    CopyScalars := Min(AvailableScalars,
      RequestedScalars - WrittenScalars);

    Move(
      FPending[FPendingOffset],
      PSingleArray(ADestination)^[WrittenScalars],
      CopyScalars * SizeOf(Single)
    );

    Inc(FPendingOffset, CopyScalars);
    Inc(WrittenScalars, CopyScalars);
  end;

  Result := WrittenScalars div ChannelCount;
end;

procedure TMFAudioDecoder.SeekSeconds(const ASeconds: Double);
var
  Position: WinApi.ActiveX.PropIdl.PROPVARIANT;
  TargetSeconds: Double;
begin
  RequireOpen;

  TargetSeconds := Max(0.0, ASeconds);
  if (FInfo.DurationSeconds > 0.0) and
     (TargetSeconds > FInfo.DurationSeconds) then
    TargetSeconds := FInfo.DurationSeconds;

  WinApi.ActiveX.PropIdl.PropVariantInit(Position);
  try
    Position.vt := VT_I8;
    Position.hVal.QuadPart := Round(TargetSeconds * 10000000.0);
    CheckHR(
      FReader.SetCurrentPosition(GUID_NULL, Position),
      'Could not seek the audio source reader.'
    );
  finally
    WinApi.ActiveX.PropIdl.PropVariantClear(Position);
  end;

  SetLength(FPending, 0);
  FPendingOffset := 0;
  FPendingCount := 0;
  FEndOfStream := False;
  FState := TMFDecoderState.Open;
end;

function TMFAudioDecoder.DecodeAll: TSignalBuffer;
var
  Buffer: TSignalBuffer;
  StreamIndex: DWORD;
  Flags: DWORD;
  TimeStamp: LONGLONG;
  Sample: IMFSample;
  MediaBuffer: IMFMediaBuffer;
Data: PByte;
MaxLength: DWORD;
CurrentLength: DWORD;
  ScalarCount: Integer;
  SampleFrameCount: Integer;
begin
  RequireOpen;

  Buffer := TSignalBuffer.Create(FInfo.Audio.Signal);

  try
    while True do
    begin
      Sample := nil;

      CheckHR(
        FReader.ReadSample(
          MF_SOURCE_READER_FIRST_AUDIO_STREAM,
          0,
          @StreamIndex,
          @Flags,
          @TimeStamp,
          @Sample
        ),
        'Could not read audio sample.'
      );

      if (Flags and MF_SOURCE_READERF_ENDOFSTREAM) <> 0 then
        Break;

      if Sample = nil then
        Continue;

CheckHR(
  Sample.ConvertToContiguousBuffer(@MediaBuffer),
  'Could not convert audio sample to contiguous buffer.'
);

      Data := nil;
      MaxLength := 0;
      CurrentLength := 0;

 CheckHR(
  MediaBuffer.Lock(Data, @MaxLength, @CurrentLength),
  'Could not lock audio buffer.'
);
      try
        if CurrentLength > 0 then
        begin
          ScalarCount := CurrentLength div SizeOf(Single);
          SampleFrameCount := ScalarCount div FInfo.Audio.Signal.ChannelCount;

          if SampleFrameCount > 0 then
          Buffer.AppendFloat32(System.PSingle(Data), SampleFrameCount);
          // Buffer.AppendFloat32(PSingle(Data), SampleFrameCount);
           //Buffer.AppendFloat32(PSingle(Data), SampleFrameCount);
        end;
      finally
        MediaBuffer.Unlock;
      end;
    end;

    FState := TMFDecoderState.EndOfStream;
    Result := Buffer;
  except
    Buffer.Free;
    raise;
  end;
end;

end.
