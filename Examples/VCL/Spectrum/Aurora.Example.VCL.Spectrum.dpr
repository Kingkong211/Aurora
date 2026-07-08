program Aurora_Example_VCL_Spectrum;

uses
  Vcl.Forms,
  Main in 'Main.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.