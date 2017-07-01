unit uThread;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.SyncObjs, uFormats;

type
  TFindObjList = class(TList)
  private
    cs: TCriticalSection;
    procedure AddToFindList;
  public
    PFind     : PBoolean;
    HandleList: TArray<THandle>;
    ThreadList: TArray<TThread>;
    SizeList  : TArray<Integer>;
    procedure CloseThread;
    function WaiteKill: Boolean;
    function AddThread(Item: TEvent; FindSize: Integer): Integer;
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TThreadFindText = class(TThread)
  private
    PFindObj : TFindObjList;
    Index    : Integer;
  public
    FFileName: string;
    FText    : string;
    constructor Create(const Event: TFindObjList; const AIndex: Integer);
    destructor Destroy; override;
    procedure Execute; override;
  end;

implementation

{ TFindObjList }

function TFindObjList.WaiteKill: Boolean;
var
  i: Integer;
begin
  Result := False;
  while not Result do
  begin
    if Length(ThreadList) = 0 then Break;
    for I := Low(ThreadList) to High(ThreadList) do
    begin
      Result := not Assigned(ThreadList[i]);
      if not Result then
        Break;
    end;
  end;
end;

function TFindObjList.AddThread(Item: TEvent; FindSize: Integer): Integer;
begin
  Result := Add( Item );
  SetLength(HandleList,Length(HandleList)+1);
  HandleList[ Length(HandleList)-1 ] := Item.Handle;

  SetLength(ThreadList,Length(ThreadList)+1);
  ThreadList[ Length(ThreadList)-1 ] := nil;
end;

procedure TFindObjList.CloseThread;
var
  I: integer;
  c: Integer;
begin
  try
    if Length(ThreadList) > 0 then
    begin
      for I := Low(ThreadList) to High(ThreadList) do
        if Assigned(ThreadList[i]) then
          ThreadList[i].Terminate;
    end;
  finally
//    SetLength(ThreadList,0);
  end;
end;

constructor TFindObjList.Create;
begin
  inherited;
  cs := TCriticalSection.Create;
end;

destructor TFindObjList.Destroy;
begin
  FreeAndNil( cs );
  inherited;
end;

{ TThreadFindText }

procedure TFindObjList.AddToFindList;
begin
  cs.Enter;
  try
    PFind^ := true;
    //Закриваємо відкриті потоки, якщо знайшли текст у файлі
    CloseThread;
  finally
    CS.Leave;
  end;
end;

constructor TThreadFindText.Create(const Event: TFindObjList; const AIndex: Integer);
begin
  inherited Create( true );
  FreeOnTerminate := True;
  Index    := AIndex;
  PFindObj := Event;
//  PThread  := Event.ThreadList;
  Event.ThreadList[Index] := Self;
end;

destructor TThreadFindText.Destroy;
begin
  TEvent(PFindObj.Items[Index]).SetEvent;
  PFindObj.ThreadList[Index] := nil;
  inherited;
end;

procedure TThreadFindText.Execute;
VAR
  isFind    : Boolean;
  SearchText: TSearchAll;
begin
  inherited;
  SearchText := TSearchAll.Create( FFileName );
  try
    SearchText.Thread := PFindObj.ThreadList[Index];

    isFind := SearchText.Search(FText, Index * PFindObj.SizeList[0], PFindObj.SizeList[Index]);
    if isFind then
      PFindObj.AddToFindList;
  finally
    FreeAndNil( SearchText );
  end;
end;

end.
