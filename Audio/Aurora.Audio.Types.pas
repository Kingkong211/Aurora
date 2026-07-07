{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Audio.Types                                                     }
{                                                                              }
{  Description: Audio-domain types and helpers for Aurora.                      }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                            }
{                                                                              }
{  License: MIT                                                                 }
{                                                                              }
{******************************************************************************}

unit Aurora.Audio.Types;

interface

{$SCOPEDENUMS ON}

uses
  Aurora.Core.Types;

type
  /// <summary>
  /// Common speaker/channel positions for audio streams.
  /// </summary>
  TAudioChannel = (
    Unknown,
    Left,
    Right,
    Center,
    LFE,
    BackLeft,
    BackRight,
    SideLeft,
    SideRight
  );

  /// <summary>
  /// Audio sample layout.
  /// </summary>
  TAudioSampleLayout = (
    Unknown,
    Interleaved,
    Planar
  );

  /// <summary>
  /// Audio-domain stream descriptor.
  /// </summary>
  TAudioDescriptor = record
  public
    Signal: TSignalDescriptor;
    Layout: TAudioSampleLayout;

    class function CreateFloat32Interleaved(
      const ASampleRate: Integer;
      const AChannelCount: Integer): TAudioDescriptor; static;

    function IsValid: Boolean;
  end;

implementation

{ TAudioDescriptor }

class function TAudioDescriptor.CreateFloat32Interleaved(
  const ASampleRate: Integer;
  const AChannelCount: Integer): TAudioDescriptor;
begin
  Result.Signal := TSignalDescriptor.Create(
    TSignalKind.Audio,
    ASampleRate,
    AChannelCount,
    TSampleFormat.Float32
  );

  Result.Layout := TAudioSampleLayout.Interleaved;
end;

function TAudioDescriptor.IsValid: Boolean;
begin
  Result :=
    Signal.IsValid and
    (Signal.Kind = TSignalKind.Audio) and
    (Layout <> TAudioSampleLayout.Unknown);
end;

end.