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
  System.UITypes;

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

    class function Default: TSpectrumStyle; static;
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
end;

end.