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
      const ABarCount: Integer
    ): TDisplayFrame; static;

    procedure Resize(
      const ABarCount: Integer
    );

    procedure Clear;
  end;

implementation

{ TDisplayFrame }

class function TDisplayFrame.Create(
  const ABarCount: Integer
): TDisplayFrame;
begin
  Result.BarCount := 0;
  SetLength(Result.Bars, 0);
  SetLength(Result.PeakBars, 0);

  Result.Resize(ABarCount);
  Result.Clear;
end;

procedure TDisplayFrame.Resize(
  const ABarCount: Integer
);
begin
  BarCount := ABarCount;

  SetLength(Bars, ABarCount);
  SetLength(PeakBars, ABarCount);
end;

procedure TDisplayFrame.Clear;
var
  I: Integer;
begin
  for I := 0 to BarCount - 1 do
  begin
    Bars[I] := 0.0;
    PeakBars[I] := 0.0;
  end;
end;

end.