{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Core.Interfaces                                                 }
{                                                                              }
{  Description: Core interfaces shared by signal providers and consumers.       }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                            }
{                                                                              }
{  License: MIT                                                                 }
{                                                                              }
{******************************************************************************}

unit Aurora.Core.Interfaces;

interface

{$SCOPEDENUMS ON}

uses
  Aurora.Core.Types;

type
  /// <summary>
  /// Base interface for all Aurora objects that can expose a signal descriptor.
  /// </summary>
  ISignalDescribed = interface
    ['{CC6D7C25-83EF-4A37-84A7-1D2D0F9C9221}']

    /// <summary>
    /// Returns the descriptor of the signal represented by this object.
    /// </summary>
    function GetDescriptor: TSignalDescriptor;

    /// <summary>
    /// Signal descriptor.
    /// </summary>
    property Descriptor: TSignalDescriptor read GetDescriptor;
  end;

  /// <summary>
  /// Provides read-only signal samples to Aurora modules.
  /// </summary>
  /// <remarks>
  /// Implementations may represent files, memory buffers, real-time devices,
  /// generated signals, or external SDK streams. Consumers must not assume
  /// ownership of returned memory.
  /// </remarks>
  ISignalProvider = interface(ISignalDescribed)
    ['{6A2E2074-6F52-42E3-8B0A-C4C5C1DE17DF}']

    /// <summary>
    /// Returns True when the provider can supply samples for the requested region.
    /// </summary>
    function CanRead(const ARegion: TSignalRegion): Boolean;

    /// <summary>
    /// Reads interleaved Float32 samples into the caller-owned destination buffer.
    /// </summary>
    /// <remarks>
    /// ARegion.SampleCount is measured in sample frames, not scalar float values.
    /// The destination buffer must have room for SampleCount * ChannelCount floats.
    /// The function returns the number of sample frames actually read.
    /// </remarks>
    function ReadFloat32(
      const ARegion: TSignalRegion;
      const ADestination: PSingle;
      const ADestinationSampleCapacity: Integer): Integer;
  end;

  /// <summary>
  /// Receives signal samples from another Aurora module.
  /// </summary>
  ISignalConsumer = interface
    ['{C01F29D8-B730-4E3D-83DF-601EAA58189F}']

    /// <summary>
    /// Processes interleaved Float32 samples from a signal region.
    /// </summary>
    /// <remarks>
    /// The input pointer is borrowed and must not be retained after this call.
    /// </remarks>
    procedure ProcessFloat32(
      const ADescriptor: TSignalDescriptor;
      const ARegion: TSignalRegion;
      const ASamples: PSingle);
  end;

implementation

end.