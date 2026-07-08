program Test_FFT;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  Aurora.Numerics.Complex in '..\..\Source\Numerics\Aurora.Numerics.Complex.pas',
  Aurora.DSP.FFT.Plan in '..\..\Source\DSP\FFT\Aurora.DSP.FFT.Plan.pas',
  Aurora.DSP.FFT.Radix2 in '..\..\Source\DSP\FFT\Aurora.DSP.FFT.Radix2.pas',
  Aurora.DSP.Magnitude in '..\..\Source\DSP\Aurora.DSP.Magnitude.pas';

const
  SampleRate = 44100;
  FFTSize = 2048;
  TestFrequency = 440.0;

var
  Plan: TFFTPlan;
  Buffer: array of TComplex32;
  Index: Integer;
  PeakBin: Integer;
  ExpectedBin: Integer;
  Magnitude: Single;
  PeakMagnitude: Single;
  Phase: Double;
    Magnitudes: array of Single;

begin
  try
    SetLength(Buffer, FFTSize);
    SetLength(Magnitudes, FFTSize div 2);

    for Index := 0 to FFTSize - 1 do
    begin
      Phase := 2.0 * Pi * TestFrequency * Index / SampleRate;
      Buffer[Index] := TComplex32.Create(Single(Sin(Phase)), 0.0);
    end;

    Plan := TFFTPlan.Create(FFTSize);
    try
      TRadix2FFT.Execute(
        Plan,
        PComplex32(@Buffer[0]),
        TFFTDirection.Forward
      );

TMagnitude.ComputePower(
  PComplex32(@Buffer[0]),
  @Magnitudes[0],
  FFTSize div 2
);
      PeakBin := 0;
      PeakMagnitude := 0.0;

      for Index := 0 to (FFTSize div 2) - 1 do
      begin
       // Magnitude := Buffer[Index].MagnitudeSquared;
       Magnitude := Magnitudes[Index];

        if Magnitude > PeakMagnitude then
        begin
          PeakMagnitude := Magnitude;
          PeakBin := Index;
        end;
      end;

      ExpectedBin := Round(TestFrequency / (SampleRate / FFTSize));

      Writeln('FFT Validation');
      Writeln('--------------');
      Writeln('Sample rate  : ', SampleRate);
      Writeln('FFT size     : ', FFTSize);
      Writeln('Frequency    : ', TestFrequency:0:2, ' Hz');
      Writeln('Expected bin : ', ExpectedBin);
      Writeln('Peak bin     : ', PeakBin);
      Writeln('Peak power   : ', PeakMagnitude:0:4);
      Writeln;

      if Abs(PeakBin - ExpectedBin) <= 1 then
        Writeln('PASS')
      else
        Writeln('FAIL');
    finally
      Plan.Free;
    end;

  except
    on E: Exception do
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
  end;

  Writeln;
  Writeln('Press ENTER to exit...');
  Readln;
end.