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
    MarginLeft: Integer;
    MarginTop: Integer;
    MarginRight: Integer;
    MarginBottom: Integer;

    MinimumBarHeight: Integer;	
    TopHighlightEnabled: Boolean;
    TopHighlightColor: TColor;
    TopHighlightRatio: Single;	

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
  Result.MarginLeft := 2;
  Result.MarginTop := 2;
  Result.MarginRight := 2;
  Result.MarginBottom := 2;

  Result.MinimumBarHeight := 1;  
  Result.TopHighlightEnabled := True;
  Result.TopHighlightColor := clWhite;
  Result.TopHighlightRatio := 0.22;  
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
        Result.TopHighlightEnabled := True;
        Result.TopHighlightColor := RGB(220, 255, 240);
        Result.TopHighlightRatio := 0.30;		
		
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
        Result.TopHighlightEnabled := True;
        Result.TopHighlightColor := RGB(210, 255, 240);
        Result.TopHighlightRatio := 0.32;		
      end;

    TSpectrumThemePreset.OkaraDark:
      begin
        Result.BackgroundColor := RGB(7, 9, 14);
        Result.BarColor := RGB(55, 205, 255);
        Result.PeakColor := RGB(245, 250, 255);
        Result.PeakMarkerColor := RGB(245, 250, 255);

        Result.BarSpacing := 2;
        Result.BlockHeight := 5;
        Result.BlockSpacing := 1;

        Result.PeakMarkerEnabled := True;
        Result.PeakMarkerHeight := 2;
        Result.PeakMarkerWidth := 0;

        Result.MarginLeft := 2;
        Result.MarginTop := 2;
        Result.MarginRight := 2;
        Result.MarginBottom := 2;

        Result.MinimumBarHeight := 1;
        Result.TopHighlightEnabled := True;
        Result.TopHighlightColor := RGB(160, 240, 255);
        Result.TopHighlightRatio := 0.4;		
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
        Result.TopHighlightEnabled := True;
        Result.TopHighlightColor := RGB(185, 240, 255);
        Result.TopHighlightRatio := 0.3;		
      end;

    TSpectrumThemePreset.StoicAmber:
      begin
        Result.BackgroundColor := RGB(12, 9, 5);
        Result.BarColor := RGB(255, 178, 64);
        Result.PeakColor := RGB(255, 235, 185);
        Result.PeakMarkerColor := RGB(255, 235, 185);

        Result.BarSpacing := 2;
        Result.BlockHeight := 4;
        Result.BlockSpacing := 2;
        Result.MarginLeft := 2;
        Result.MarginTop := 2;
        Result.MarginRight := 2;
        Result.MarginBottom := 3;
        Result.PeakMarkerHeight := 2;
        Result.MinimumBarHeight := 1;
        Result.TopHighlightEnabled := True;
        Result.TopHighlightColor := RGB(255, 224, 150);
        Result.TopHighlightRatio := 0.4;		
      end;

  end;
end;

end.