unit UCL.TUCaptionBar;

interface

uses
  Classes, Types, Windows, Messages, Controls, ExtCtrls, Forms, Graphics,
  UCL.Classes, UCL.TUThemeManager, UCL.Utils, UCL.Colors;

type
  TUCaptionBar = class(TPanel, IUThemeComponent)
    private
      FThemeManager: TUThemeManager;
      FBackColor: TUThemeColorSet;

      FDragMovement: Boolean;
      FSystemMenuEnabled: Boolean;
      FCustomColor: TColor;

      //  Setters
      procedure SetThemeManager(const Value: TUThemeManager);

      //  Child events
      procedure BackColor_OnChange(Sender: TObject);

      //  Messages
      procedure WM_LButtonDblClk(var Msg: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
      procedure WM_LButtonDown(var Msg: TWMLButtonDown); message WM_LBUTTONDOWN;
      procedure WM_RButtonUp(var Msg: TMessage); message WM_RBUTTONUP;
      procedure WM_NCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;

    protected
      procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
      procedure UpdateTheme;

    published
      property ThemeManager: TUThemeManager read FThemeManager write SetThemeManager;
      property BackColor: TUThemeColorSet read FBackColor write FBackColor;

      property DragMovement: Boolean read FDragMovement write FDragMovement default true;
      property SystemMenuEnabled: Boolean read FSystemMenuEnabled write FSystemMenuEnabled default true;
      property CustomColor: TColor read FCustomColor write FCustomColor default $D77800;

      property Align default alTop;
      property Alignment default taLeftJustify;
      property BevelOuter default bvNone;
      property Height default 32;
  end;

implementation

{ TUCustomCaptionBar }

//  THEME

procedure TUCaptionBar.SetThemeManager(const Value: TUThemeManager);
begin
  if Value <> FThemeManager then
    begin
      if FThemeManager <> nil then
        FThemeManager.Disconnect(Self);

      if Value <> nil then
        begin
          Value.Connect(Self);
          Value.FreeNotification(Self);
        end;

      FThemeManager := Value;
      UpdateTheme;
    end;
end;

procedure TUCaptionBar.UpdateTheme;
var
  setBack: TUThemeColorSet;
begin
  //  Select active style
  if (ThemeManager = nil) or (BackColor.Enabled) then
    setBack := BackColor  //  Custom style
  else
    setBack := CAPTIONBAR_BACK;   //  Default style

  //  Background & text color
  Color := setBack.GetColor(ThemeManager);
  Font.Color := GetTextColorFromBackground(Color);

  //  Repaint
  //  Do not repaint, not necessary
end;

procedure TUCaptionBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FThemeManager) then
    FThemeManager := nil;
end;

// MAIN CLASS

constructor TUCaptionBar.Create(aOwner: TComponent);
begin
  inherited;
  FDragMovement := true;
  FSystemMenuEnabled := true;
  FCustomColor := $D77800;

  Align := alTop;
  Alignment := taLeftJustify;
  Caption := '   TUCaptionBar';
  BevelOuter := bvNone;
  Height := 32;

  FBackColor := TUThemeColorSet.Create;
  FBackColor.OnChange := BackColor_OnChange;
  FBackColor.Assign(CAPTIONBAR_BACK);
end;

destructor TUCaptionBar.Destroy;
begin
  FBackColor.Free;
  inherited;
end;

// MESSAGES

procedure TUCaptionBar.WM_LButtonDblClk(var Msg: TWMLButtonDblClk);
var
  ParentForm: TCustomForm;
begin
  inherited;

  ParentForm := GetParentForm(Self, true);
  if ParentForm is TForm then
    if biMaximize in (ParentForm as TForm).BorderIcons then
      begin
        if ParentForm.WindowState = wsMaximized then
          ParentForm.WindowState := wsNormal
        else if ParentForm.WindowState = wsNormal then
          ParentForm.WindowState := wsMaximized;
      end;
end;

procedure TUCaptionBar.WM_LButtonDown(var Msg: TWMLButtonDown);
begin
  inherited;
  if DragMovement then
    begin
      ReleaseCapture;
      Parent.Perform(WM_SYSCOMMAND, $F012, 0);
    end;
end;

procedure TUCaptionBar.WM_RButtonUp(var Msg: TMessage);
const
  WM_SYSMENU = 787;
var
  P: TPoint;
begin
  inherited;
  if SystemMenuEnabled then
    begin
      P.X := Msg.LParamLo;
      P.Y := Msg.LParamHi;
      P := ClientToScreen(P);
      Msg.LParamLo := P.X;
      Msg.LParamHi := P.Y;
      PostMessage(Parent.Handle, WM_SYSMENU, 0, Msg.LParam);
    end;
end;

procedure TUCaptionBar.WM_NCHitTest(var Msg: TWMNCHitTest);
var
  P: TPoint;
  ParentForm: TCustomForm;
begin
  inherited;

  ParentForm := GetParentForm(Self, true);
  if (ParentForm.WindowState = wsNormal) and (Align = alTop) then
    begin
      P := Point(Msg.Pos.x, Msg.Pos.y);
      P := ScreenToClient(P);
      if P.Y < 5 then
        Msg.Result := HTTRANSPARENT;  //  Send event to parent
    end;
end;

//  CHILD EVENTS

procedure TUCaptionBar.BackColor_OnChange(Sender: TObject);
begin
  UpdateTheme;
end;

end.
