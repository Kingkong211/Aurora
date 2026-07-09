unit Aurora.Visual.DisplayProcessor;

interface

uses
  Aurora.Core.Frame,
  Aurora.Visual.Frame,
  Aurora.Analysis.PeakHold;

type
  TDisplayProcessor = class
  private
    FPeakHold: TPeakHold;

  public
    constructor Create(
      const ABarCount: Integer);

    destructor Destroy; override;

    procedure Process(
      const ASource: TAuroraFrame;
      var ADestination: TDisplayFrame);
  end;

implementation

uses
  System.SysUtils;

constructor TDisplayProcessor.Create(
  const ABarCount: Integer);
begin
  inherited Create;

  FPeakHold := TPeakHold.Create(
    ABarCount,
    0.975);
end;

destructor TDisplayProcessor.Destroy;
begin
  FPeakHold.Free;
  inherited;
end;

procedure TDisplayProcessor.Process(
  const ASource: TAuroraFrame;
  var ADestination: TDisplayFrame);
begin
  if ASource.BarCount <> ADestination.BarCount then
    raise EInvalidOperation.Create(
      'Display frame size mismatch.');

  Move(
    ASource.Bars[0],
    ADestination.Bars[0],
    ASource.BarCount * SizeOf(Single));

  // -------------------------------------------------------
  // Display pipeline
  //
  // Future stages:
  //   Attack
  //   Release
  //   Gamma
  //   Dynamic Range Mapping
  //   Glow Curve
  // -------------------------------------------------------

  FPeakHold.Process(
    @ADestination.Bars[0],
    @ADestination.PeakBars[0]);
end;

end.