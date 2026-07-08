program Test_Spectrum;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  Aurora.Numerics.Complex in '..\..\Source\Numerics\Aurora.Numerics.Complex.pas',
  Aurora.DSP.FFT.Plan in '..\..\Source\DSP\FFT\Aurora.DSP.FFT.Plan.pas',
  Aurora.DSP.FFT.Radix2 in '..\..\Source\DSP\FFT\Aurora.DSP.FFT.Radix2.pas',
  Aurora.DSP.Magnitude in '..\..\Source\DSP\Aurora.DSP.Magnitude.pas',
  Aurora.Analysis.Spectrum in '..\..\Source\Analysis\Aurora.Analysis.Spectrum.pas';

const
  SampleRate = 44100;
  FFTSize = 2048;
  BarCount = 80;
  TestFrequency = 440.0;

var
  Plan: TFFTPlan;
  Analyzer: TSpectrumAnalyzer;
  Buffer: array of TComplex32;
  Magnitudes: array of Single;
  Bars: array of Single;
  Index: Integer;
  PeakBar: Integer;
  PeakValue: Single;
  Phase: Double;

begin
  try
    SetLength(Buffer, FFTSize);
    SetLength(Magnitudes, FFTSize div 2);
    SetLength(Bars, BarCount);

    for Index := 0 to FFTSize - 1 do
    begin
      Phase := 2.0 * Pi * TestFrequency * Index / SampleRate;
      Buffer[Index] := TComplex32.Create(Single(Sin(Phase)), 0.0);
    end;

    Plan := TFFTPlan.Create(FFTSize);
    Analyzer := TSpectrumAnalyzer.Create(FFTSize, SampleRate, BarCount);
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

      Analyzer.Analyze(
        @Magnitudes[0],
        @Bars[0]
      );

      PeakBar := 0;
      PeakValue := 0.0;

      for Index := 0 to BarCount - 1 do
      begin
        if Bars[Index] > PeakValue then
        begin
          PeakValue := Bars[Index];
          PeakBar := Index;
        end;
      end;

      Writeln('Spectrum Validation');
      Writeln('-------------------');
      Writeln('Sample rate : ', SampleRate);
      Writeln('FFT size    : ', FFTSize);
      Writeln('Bar count   : ', BarCount);
      Writeln('Frequency   : ', TestFrequency:0:2, ' Hz');
      Writeln('Peak bar    : ', PeakBar);
      Writeln('Peak value  : ', PeakValue:0:4);
      Writeln;

      if PeakValue > 0.0 then
        Writeln('PASS')
      else
        Writeln('FAIL');

    finally
      Analyzer.Free;
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