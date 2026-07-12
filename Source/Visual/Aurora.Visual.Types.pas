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
	//glowing 
    GlowEnabled: Boolean;
    GlowColor: TColor;
    GlowIntensity: Single;
    GlowHeightRatio: Single;	

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
  //glowing
  Result.GlowEnabled := True;
  Result.GlowColor := RGB(80, 200, 255);
  Result.GlowIntensity := 0.16;
  Result.GlowHeightRatio := 0.55;
  
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
        Result.BarColor := RGB(112, 64, 64);
        Result.PeakColor := clWhite;
        Result.PeakMarkerColor := clWhite;

        Result.BarSpacing := 2;
        Result.BlockHeight := 4;
        Result.BlockSpacing := 2;
        Result.MarginLeft := 1;
        Result.MarginTop := 2;
        Result.MarginRight := 1;
        Result.MarginBottom := 3;
        Result.PeakMarkerHeight := 2;
        Result.MinimumBarHeight := 1;
        Result.TopHighlightEnabled := True;
        Result.TopHighlightColor := RGB(166, 131, 131);
        Result.TopHighlightRatio := 0.15;

        Result.GlowEnabled := True;
        Result.GlowColor := RGB(240, 20, 238);
        Result.GlowIntensity := 0.24;
        Result.GlowHeightRatio := 0.40;
		
      end;

    TSpectrumThemePreset.AuroraMint:
      begin
        Result.BackgroundColor := clBlack;
        Result.BarColor := RGB(219, 190, 26);
        Result.PeakColor := RGB(230, 255, 245);
        Result.PeakMarkerColor := RGB(230, 255, 245);

        Result.BarSpacing := 2;
        Result.BlockHeight := 4;
        Result.BlockSpacing := 2;
        Result.MarginLeft := 1;
        Result.MarginTop := 2;
        Result.MarginRight := 1;
        Result.MarginBottom := 3;
        Result.PeakMarkerHeight := 2;
        Result.MinimumBarHeight := 1;
        Result.TopHighlightEnabled := True;
        Result.TopHighlightColor := RGB(255, 224, 150);
        Result.TopHighlightRatio := 0.15;
		
		//glowing
		Result.GlowEnabled := True;
        Result.GlowColor := RGB(90, 255, 210);
        Result.GlowIntensity := 0.2;
        Result.GlowHeightRatio := 0.55;
      end;

    TSpectrumThemePreset.OkaraDark:
      begin
        Result.BackgroundColor := clBlack;
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
        Result.TopHighlightRatio := 0.2;

		Result.GlowEnabled := True;
        Result.GlowColor := RGB(40, 180, 255);
        Result.GlowIntensity := 0.18;
        Result.GlowHeightRatio := 0.55;
      end;

    TSpectrumThemePreset.WaterGrid:
      begin
        Result.BackgroundColor := clBlack;
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
        Result.TopHighlightRatio := 0.18;
		
        Result.GlowEnabled := True;
        Result.GlowColor := RGB(50, 190, 255);
        Result.GlowIntensity := 0.16;
        Result.GlowHeightRatio := 0.60;		
      end;

    TSpectrumThemePreset.StoicAmber:
      begin
        Result.BackgroundColor := clBlack;
        Result.BarColor := RGB(255, 178, 64);
        Result.PeakColor := RGB(255, 235, 185);
        Result.PeakMarkerColor := RGB(255, 235, 185);

        Result.BarSpacing := 2;
        Result.BlockHeight := 4;
        Result.BlockSpacing := 2;
        Result.MarginLeft := 1;
        Result.MarginTop := 2;
        Result.MarginRight := 1;
        Result.MarginBottom := 3;
        Result.PeakMarkerHeight := 2;
        Result.MinimumBarHeight := 1;
        Result.TopHighlightEnabled := True;
        Result.TopHighlightColor := RGB(255, 224, 150);
        Result.TopHighlightRatio := 0.15;	

	    Result.GlowEnabled := True;
        Result.GlowColor := RGB(255, 145, 36);
        Result.GlowIntensity := 0.26;
        Result.GlowHeightRatio := 0.24;
      end;

  end;
end;

end.