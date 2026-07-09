{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Visual.Frame                                                    }
{                                                                              }
{  Description: Display-ready frame model for visualization renderers.          }
{                                                                              }
{******************************************************************************}

unit Aurora.Visual.Frame;

interface

{$SCOPEDENUMS ON}

type
  TDisplayFrame = record
  public
    BarCount: Integer;
    Bars: TArray<Single>;
    PeakBars: TArray<Single>;

    class function Create(
      const ABarCount: Integer): TDisplayFrame; static;

    procedure Clear;
  end;

implementation

{ TDisplayFrame }

class function TDisplayFrame.Create(
  const ABarCount: Integer): TDisplayFrame;
begin
  Result.BarCount := ABarCount;

  SetLength(Result.Bars, ABarCount);
  SetLength(Result.PeakBars, ABarCount);

  Result.Clear;
end;

procedure TDisplayFrame.Clear;
var
  Index: Integer;
begin
  for Index := 0 to BarCount - 1 do
  begin
    Bars[Index] := 0.0;
    PeakBars[Index] := 0.0;
  end;
end;

end.