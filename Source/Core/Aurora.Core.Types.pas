{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Core.Types                                                      }
{                                                                              }
{  Description: Core signal types shared by all Aurora modules.                 }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                            }
{                                                                              }
{  License: MIT                                                                 }
{                                                                              }
{******************************************************************************}

unit Aurora.Core.Types;

interface

{$SCOPEDENUMS ON}

type
  /// <summary>
  /// Signed sample index used as Aurora's canonical time position.
  /// </summary>
  /// <remarks>
  /// Sample index is preferred over floating-point time because it is exact,
  /// deterministic, and independent from presentation units.
  /// </remarks>
  TSampleIndex = Int64;

  /// <summary>
  /// High-level kind of signal represented by a source or buffer.
  /// </summary>
  TSignalKind = (
    Unknown,
    Audio,
    EEG,
    EMG,
    ECG,
    HRV,
    Control,
    Generated
  );
  
  TSpectrumFrame = record
  public
    BarCount: Integer;
    Values: TArray<Single>;

    procedure Resize(ABarCount: Integer);
    procedure Clear;
  end;
  /// <summary>
  /// Physical sample format before or after conversion.
  /// </summary>
  /// <remarks>
  /// Aurora DSP modules should generally operate on Float32. Other formats
  /// exist so decoders and input devices can describe their native data.
  /// </remarks>
  TSampleFormat = (
    Unknown,
    Float32,
    Float64,
    Int16,
    Int24,
    Int32
  );

  /// <summary>
  /// Describes the layout and timing of a signal stream.
  /// </summary>
  /// <remarks>
  /// This record intentionally avoids domain-specific concepts such as
  /// audio left/right channels or EEG electrode names. Channel meaning belongs
  /// to higher-level modules such as Aurora.Audio or Aurora.Bio.
  /// </remarks>
  TSignalDescriptor = record
  public
    Kind: TSignalKind;
    SampleRate: Integer;
    ChannelCount: Integer;
    SampleFormat: TSampleFormat;

    class function Create(
      const AKind: TSignalKind;
      const ASampleRate: Integer;
      const AChannelCount: Integer;
      const ASampleFormat: TSampleFormat): TSignalDescriptor; static;

    class function Empty: TSignalDescriptor; static;

    function IsValid: Boolean;
  end;

  /// <summary>
  /// Describes a continuous region inside a signal buffer.
  /// </summary>
  /// <remarks>
  /// A region does not own memory. It is only a view definition:
  /// where to start and how many sample frames to read.
  /// </remarks>
  TSignalRegion = record
  public
    StartSample: TSampleIndex;
    SampleCount: Integer;

    class function Create(
      const AStartSample: TSampleIndex;
      const ASampleCount: Integer): TSignalRegion; static;

    class function Empty: TSignalRegion; static;

    function IsEmpty: Boolean;
    function IsValid: Boolean;
    function EndSampleExclusive: TSampleIndex;
  end;

implementation

{ TSignalDescriptor }

class function TSignalDescriptor.Create(
  const AKind: TSignalKind;
  const ASampleRate: Integer;
  const AChannelCount: Integer;
  const ASampleFormat: TSampleFormat): TSignalDescriptor;
begin
  Result.Kind := AKind;
  Result.SampleRate := ASampleRate;
  Result.ChannelCount := AChannelCount;
  Result.SampleFormat := ASampleFormat;
end;

class function TSignalDescriptor.Empty: TSignalDescriptor;
begin
  Result := TSignalDescriptor.Create(
    TSignalKind.Unknown,
    0,
    0,
    TSampleFormat.Unknown
  );
end;

function TSignalDescriptor.IsValid: Boolean;
begin
  Result :=
    (Kind <> TSignalKind.Unknown) and
    (SampleRate > 0) and
    (ChannelCount > 0) and
    (SampleFormat <> TSampleFormat.Unknown);
end;

{ TSignalRegion }

class function TSignalRegion.Create(
  const AStartSample: TSampleIndex;
  const ASampleCount: Integer): TSignalRegion;
begin
  Result.StartSample := AStartSample;
  Result.SampleCount := ASampleCount;
end;

class function TSignalRegion.Empty: TSignalRegion;
begin
  Result := TSignalRegion.Create(0, 0);
end;

function TSignalRegion.IsEmpty: Boolean;
begin
  Result := SampleCount = 0;
end;

function TSignalRegion.IsValid: Boolean;
begin
  Result :=
    (StartSample >= 0) and
    (SampleCount >= 0);
end;

function TSignalRegion.EndSampleExclusive: TSampleIndex;
begin
  Result := StartSample + SampleCount;
end;

procedure TSpectrumFrame.Resize(ABarCount: Integer);
begin
  BarCount := ABarCount;
  SetLength(Values, ABarCount);
end;

procedure TSpectrumFrame.Clear;
begin
  BarCount := 0;
  SetLength(Values, 0);
end;

end.