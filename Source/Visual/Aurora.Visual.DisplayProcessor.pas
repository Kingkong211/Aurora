unit Aurora.Visual.DisplayProcessor;

interface

uses
  Aurora.Core.Frame,
  Aurora.Visual.Frame,
  Aurora.Analysis.Envelope,
  Aurora.Analysis.PeakHold;

type
  TDisplayProcessor = class
  private
    FPeakHold: TPeakHold;
    FEnvelope: TEnvelopeFollower;	

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
	
 FEnvelope := TEnvelopeFollower.Create(
  ABarCount,
  0.50,   // Attack
  0.12);  // Release
  
end;

destructor TDisplayProcessor.Destroy;
begin
  FEnvelope.Free;
  FPeakHold.Free;
  inherited;
end;

procedure TDisplayProcessor.Process(
  const ASource: TAuroraFrame;
  var ADestination: TDisplayFrame);
begin
  if ASource.BarCount <> ADestination.BarCount then
    //raise EInvalidOperation.Create(
     // 'Display frame size mismatch.');
     raise Exception.Create(
     'Display frame size mismatch.');

 { Move(
    ASource.Bars[0],
    ADestination.Bars[0],
    ASource.BarCount * SizeOf(Single));}
	

  // -------------------------------------------------------
// Display Pipeline
//
// 1. Envelope
// 2. Peak Hold
// 3. (Future) Gamma
// 4. (Future) Glow
// 5. (Future) Theme Mapping
  // -------------------------------------------------------
  FEnvelope.Process(
    @ASource.Bars[0],
    @ADestination.Bars[0]);	

  FPeakHold.Process(
    @ADestination.Bars[0],
    @ADestination.PeakBars[0]);
end;

end.