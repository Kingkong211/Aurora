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
  WinApi.MediaFoundationApi.MfApi,
  WinApi.MediaFoundationApi.MfObjects,
  WinApi.MediaFoundationApi.MfReadWrite,
  Aurora.Core.Types,
  Aurora.Core.Buffer,
  Aurora.Audio.Types,
  Aurora.Audio.MediaFoundation.Types;

type
  TMFAudioDecoder = class
  private
    FInfo: TMFDecoderInfo;
    FState: TMFDecoderState;
    FReader: IMFSourceReader;

    procedure CheckHR(const AHR: HRESULT; const AMessage: string);
    procedure RequireOpen;
    procedure ConfigureFloat32Output;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Close;
    procedure OpenFile(const AFileName: string);

    function DecodeAll: TSignalBuffer;

    property Info: TMFDecoderInfo read FInfo;
    property State: TMFDecoderState read FState;
  end;

implementation

{ TMFAudioDecoder }

constructor TMFAudioDecoder.Create;
begin
  inherited Create;
  FInfo := TMFDecoderInfo.Empty;
  FState := TMFDecoderState.Closed;
end;

destructor TMFAudioDecoder.Destroy;
begin
  Close;
  inherited;
end;

procedure TMFAudioDecoder.CheckHR(
  const AHR: HRESULT;
  const AMessage: string);
begin
  if Failed(AHR) then
  begin
    FState := TMFDecoderState.Error;
    raise EOleException.Create(AMessage, AHR, '', '', 0);
  end;
end;

procedure TMFAudioDecoder.Close;
begin
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

  FInfo.FileName := AFileName;
  FState := TMFDecoderState.Open;
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
      nil,
      MediaType
    ),
    'Could not configure source reader for Float32 audio.'
  );

  CheckHR(
    FReader.GetCurrentMediaType(
      MF_SOURCE_READER_FIRST_AUDIO_STREAM,
      CurrentType
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

procedure TMFAudioDecoder.RequireOpen;
begin
  if (FState <> TMFDecoderState.Open) or (FReader = nil) then
    raise EInvalidOperation.Create('Decoder is not open.');
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
          Sample
        ),
        'Could not read audio sample.'
      );

      if (Flags and MF_SOURCE_READERF_ENDOFSTREAM) <> 0 then
        Break;

      if Sample = nil then
        Continue;

      CheckHR(
        Sample.ConvertToContiguousBuffer(MediaBuffer),
        'Could not convert audio sample to contiguous buffer.'
      );

      Data := nil;
      MaxLength := 0;
      CurrentLength := 0;

      CheckHR(
        MediaBuffer.Lock(Data, MaxLength, CurrentLength),
        'Could not lock audio buffer.'
      );

      try
        if CurrentLength > 0 then
        begin
          ScalarCount := CurrentLength div SizeOf(Single);
          SampleFrameCount := ScalarCount div FInfo.Audio.Signal.ChannelCount;

          if SampleFrameCount > 0 then
            Buffer.AppendFloat32(PSingle(Data), SampleFrameCount);
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