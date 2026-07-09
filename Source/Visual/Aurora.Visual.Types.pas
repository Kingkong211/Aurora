{******************************************************************************}
{                                                                              }
{  Aurora Signal Processing Framework                                           }
{                                                                              }
{  Unit: Aurora.Visual.Types                                                    }
{                                                                              }
{  Description: Shared visualization types for Aurora renderers.                }
{                                                                              }
{******************************************************************************}

unit Aurora.Visual.Types;

interface

{$SCOPEDENUMS ON}

uses
  System.UITypes,
  Vcl.Graphics,
  Winapi.Windows;  

type
  TSpectrumBarStyle = (
    Solid,
    Blocks
  );

  TSpectrumOrientation = (
    BottomUp,
    Centered,
    Mirrored
  );

  TSpectrumThemePreset = (
    ClassicWinamp,
    AuroraMint,
    OkaraDark,
    WaterGrid,
    StoicAmber
  );

  TSpectrumStyle = record
  public
    BarColor: TColor;
    PeakColor: TColor;
    BackgroundColor: TColor;
    BarSpacing: Integer;
    BlockHeight: Integer;
    BlockSpacing: Integer;
    Orientation: TSpectrumOrientation;
    BarStyle: TSpectrumBarStyle;
    PeakMarkerColor: TColor;
    PeakMarkerHeight: Integer;
    PeakMarkerWidth: Integer;
    PeakMarkerEnabled: Boolean;

    class function Default: TSpectrumStyle; static;
  class function FromPreset(
    APreset: TSpectrumThemePreset
  ): TSpectrumStyle; static;	
  end;

implementation

{ TSpectrumStyle }

class function TSpectrumStyle.Default: TSpectrumStyle;
begin
  Result.BarColor := TColors.Lime;
  Result.PeakColor := TColors.White;
  Result.BackgroundColor := TColors.Black;
  Result.BarSpacing := 2;
  Result.BlockHeight := 4;
  Result.BlockSpacing := 1;
  Result.Orientation := TSpectrumOrientation.BottomUp;
  Result.BarStyle := TSpectrumBarStyle.Solid;
  Result.PeakMarkerEnabled := True;
  Result.PeakMarkerColor := TColors.White;
  Result.PeakMarkerHeight := 3;
  Result.PeakMarkerWidth := 0;   // 0 = cùng chiều rộng với bar
end;

class function TSpectrumStyle.FromPreset(
  APreset: TSpectrumThemePreset
): TSpectrumStyle;
begin
  Result := TSpectrumStyle.Default;

  case APreset of

    TSpectrumThemePreset.ClassicWinamp:
      begin
        Result.BackgroundColor := clBlack;
        Result.BarColor := RGB(96, 255, 192);
        Result.PeakColor := clWhite;
        Result.PeakMarkerColor := clWhite;

        Result.BarSpacing := 2;
        Result.BlockHeight := 4;
        Result.BlockSpacing := 2;

        Result.PeakMarkerEnabled := True;
        Result.PeakMarkerHeight := 2;
        Result.PeakMarkerWidth := 0;
      end;

    TSpectrumThemePreset.AuroraMint:
      begin
        Result.BackgroundColor := RGB(4, 10, 12);
        Result.BarColor := RGB(112, 255, 210);
        Result.PeakColor := RGB(230, 255, 245);
        Result.PeakMarkerColor := RGB(230, 255, 245);

        Result.BarSpacing := 2;
        Result.BlockHeight := 4;
        Result.BlockSpacing := 2;

        Result.PeakMarkerEnabled := True;
        Result.PeakMarkerHeight := 2;
        Result.PeakMarkerWidth := 0;
      end;

    TSpectrumThemePreset.OkaraDark:
      begin
        Result.BackgroundColor := RGB(10, 12, 18);
        Result.BarColor := RGB(70, 210, 255);
        Result.PeakColor := RGB(245, 250, 255);
        Result.PeakMarkerColor := RGB(245, 250, 255);

        Result.BarSpacing := 2;
        Result.BlockHeight := 5;
        Result.BlockSpacing := 2;

        Result.PeakMarkerEnabled := True;
        Result.PeakMarkerHeight := 2;
        Result.PeakMarkerWidth := 0;
      end;

    TSpectrumThemePreset.WaterGrid:
      begin
        Result.BackgroundColor := RGB(3, 18, 28);
        Result.BarColor := RGB(70, 190, 255);
        Result.PeakColor := RGB(200, 245, 255);
        Result.PeakMarkerColor := RGB(200, 245, 255);

        Result.BarSpacing := 2;
        Result.BlockHeight := 4;
        Result.BlockSpacing := 2;

        Result.PeakMarkerEnabled := True;
        Result.PeakMarkerHeight := 2;
        Result.PeakMarkerWidth := 0;
      end;

    TSpectrumThemePreset.StoicAmber:
      begin
        Result.BackgroundColor := RGB(14, 10, 6);
        Result.BarColor := RGB(255, 176, 72);
        Result.PeakColor := RGB(255, 235, 190);
        Result.PeakMarkerColor := RGB(255, 235, 190);

        Result.BarSpacing := 2;
        Result.BlockHeight := 4;
        Result.BlockSpacing := 2;

        Result.PeakMarkerEnabled := True;
        Result.PeakMarkerHeight := 2;
        Result.PeakMarkerWidth := 0;
      end;

  end;
end;

end.