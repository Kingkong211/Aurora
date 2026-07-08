{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Core.Frame                                                      }
{                                                                              }
{  Description: Energy frame model shared by engines and renderers.             }
{                                                                              }
{******************************************************************************}

unit Aurora.Core.Frame;

interface

{$SCOPEDENUMS ON}

type
  TAuroraFrame = record
  public
    TimeStamp: Int64;
    SampleRate: Integer;
    FFTSize: Integer;
    HopSize: Integer;
    BarCount: Integer;
    Bars: TArray<Single>;
    Peak: Single;
    RMS: Single;
    Energy: Single;

    class function Create(
      const ASampleRate: Integer;
      const AFFTSize: Integer;
      const AHopSize: Integer;
      const ABarCount: Integer): TAuroraFrame; static;

    procedure Clear;
  end;

implementation

{ TAuroraFrame }

class function TAuroraFrame.Create(
  const ASampleRate: Integer;
  const AFFTSize: Integer;
  const AHopSize: Integer;
  const ABarCount: Integer): TAuroraFrame;
begin
  Result.TimeStamp := 0;
  Result.SampleRate := ASampleRate;
  Result.FFTSize := AFFTSize;
  Result.HopSize := AHopSize;
  Result.BarCount := ABarCount;
  Result.Peak := 0.0;
  Result.RMS := 0.0;
  Result.Energy := 0.0;

  SetLength(Result.Bars, ABarCount);
end;

procedure TAuroraFrame.Clear;
var
  Index: Integer;
begin
  TimeStamp := 0;
  Peak := 0.0;
  RMS := 0.0;
  Energy := 0.0;

  for Index := 0 to Length(Bars) - 1 do
    Bars[Index] := 0.0;
end;

end.