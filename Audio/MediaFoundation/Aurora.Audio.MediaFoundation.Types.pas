{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Audio.MediaFoundation.Types                                     }
{                                                                              }
{  Description: Media Foundation specific types for Aurora audio decoding.      }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                            }
{                                                                              }
{  License: MIT                                                                 }
{                                                                              }
{******************************************************************************}

unit Aurora.Audio.MediaFoundation.Types;

interface

{$SCOPEDENUMS ON}

uses
  Aurora.Core.Types,
  Aurora.Audio.Types;

type
  /// <summary>
  /// Decoder state for Media Foundation backed audio readers.
  /// </summary>
  TMFDecoderState = (
    Closed,
    Open,
    EndOfStream,
    Error
  );

  /// <summary>
  /// Basic metadata exposed by a Media Foundation audio decoder.
  /// </summary>
  TMFDecoderInfo = record
  public
    FileName: string;
    Audio: TAudioDescriptor;
    DurationSeconds: Double;

    class function Empty: TMFDecoderInfo; static;
    function IsValid: Boolean;
  end;

implementation

{ TMFDecoderInfo }

class function TMFDecoderInfo.Empty: TMFDecoderInfo;
begin
  Result.FileName := '';
  Result.Audio.Signal := TSignalDescriptor.Empty;
  Result.Audio.Layout := TAudioSampleLayout.Unknown;
  Result.DurationSeconds := 0.0;
end;

function TMFDecoderInfo.IsValid: Boolean;
begin
  Result :=
    (FileName <> '') and
    Audio.IsValid and
    (DurationSeconds >= 0.0);
end;

end.