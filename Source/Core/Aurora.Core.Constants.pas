{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Core.Constants                                                  }
{                                                                              }
{  Description: Shared constants for Aurora Core.                               }
{                                                                              }
{  Copyright (c) 2026 Aurora Project                                            }
{                                                                              }
{  License: MIT                                                                 }
{                                                                              }
{******************************************************************************}

unit Aurora.Core.Constants;

interface

{$SCOPEDENUMS ON}

const
  AuroraName = 'Aurora';
  AuroraVersionMajor = 0;
  AuroraVersionMinor = 1;
  AuroraVersionPatch = 0;
  AuroraVersionString = '0.1.0';

  AuroraDefaultAudioSampleRate = 44100;
  AuroraDefaultEEGSampleRate = 256;

  AuroraDefaultFFTSize = 2048;
  AuroraDefaultHopSize = 1024;

  AuroraMaxSignalChannels = 256;

  AuroraMinDecibel = -120.0;
  AuroraSilenceThreshold = 1.0E-12;

implementation

end.