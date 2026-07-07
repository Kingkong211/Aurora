{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Audio.MediaFoundation.Decoder                                   }
{                                                                              }
{  Description: Public Media Foundation audio decoder facade.                   }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                            }
{                                                                              }
{  License: MIT                                                                 }
{                                                                              }
{******************************************************************************}

unit Aurora.Audio.MediaFoundation.Decoder;

interface

{$SCOPEDENUMS ON}

uses
  System.SysUtils,
  Aurora.Core.Types,
  Aurora.Core.Buffer,
  Aurora.Audio.Types,
  Aurora.Audio.MediaFoundation.Types;

type
  /// <summary>
  /// Media Foundation backed audio decoder facade.
  /// </summary>
  /// <remarks>
  /// This class owns decoder state and exposes decoded Float32 interleaved
  /// samples through Aurora Core buffers.
  ///
  /// The current unit defines the stable public API. The Media Foundation
  /// internals will be added behind this API in the next commit.
  /// </remarks>
  TMFAudioDecoder = class
  private
    FInfo: TMFDecoderInfo;
    FState: TMFDecoderState;

    procedure RequireOpen;
  public
    constructor Create;

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

procedure TMFAudioDecoder.Close;
begin
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

  FInfo := TMFDecoderInfo.Empty;
  FInfo.FileName := AFileName;

  { Real Media Foundation probing will be implemented in the next commit. }
  FState := TMFDecoderState.Open;
end;

procedure TMFAudioDecoder.RequireOpen;
begin
  if FState <> TMFDecoderState.Open then
    raise EInvalidOperation.Create('Decoder is not open.');
end;

function TMFAudioDecoder.DecodeAll: TSignalBuffer;
begin
  RequireOpen;

  { Real decoding will be implemented in the next commit. }
  raise ENotImplemented.Create(
    'Media Foundation decoding is not implemented yet.'
  );
end;

end.