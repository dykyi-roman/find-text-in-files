unit uFormats;

interface

uses
  Classes, SysUtils;

type
  /// <summary>Клас пошуку входження рядка</summary>
  TCustomSearch = class(TObject)
  private
    Files: TFileStream;
    function SearchText(TextInByte: TBytes): Boolean;  overload; virtual;
    function SearchText(TextArr: TArray<TBytes>; FromSearch,ToSearch: Integer): Boolean; overload; virtual;
  public
    Thread: TThread;
    constructor Create(const FileName: string); virtual;
    destructor Destroy; override;
    function Search( Text: string): Boolean; virtual; abstract;
  end;
  TCustomSearchClass = class of TCustomSearch;

  //All Formats
  TSearchAll = class(TCustomSearch)
    function Search(Text: string; FromSearch, ToSearch: Integer): Boolean;
  end;

  //UTF8
  TSearchUTF8 = class(TCustomSearch)
    function Search(Text: string): Boolean; override;
  end;

  //Unicode
  TSearchUTF16 = class(TCustomSearch)
   function Search(Text: string): Boolean; override;
  end;

  //Ansi
  TSearchASCII = class(TCustomSearch)
    function Search(Text: String): Boolean; override;
  end;

implementation

constructor TCustomSearch.Create(const FileName: string);
begin
  //Загружаємо файл
  Files  := TFileStream.Create( FileName, fmOpenRead or fmShareDenyNone);
  If not Assigned( Files ) then
    raise Exception.CreateFmt('%s:"%s"',['Error Load Filecin stream',FileName]);
end;

destructor TCustomSearch.Destroy;
begin
  FreeAndNil( Files );
  inherited;
end;

function TCustomSearch.SearchText(TextInByte: TBytes): Boolean;
var
  b       : Byte;
  i       : integer;
  BufByte : TBytes;
begin
  Result := False;
    //Побайтовий пошук
    for i := 0 to Files.Seek(0, SoFromEnd) do
    begin
      // При потребі зупинемо потік
      if Assigned(Thread) then
        if Thread.CheckTerminated then
          Break;

      Files.Seek(i, soFromBeginning);
      Files.Read(b, sizeOf(b));
      { TODO : Для прискорення пошуку можна спробува читати по складам}
      if TextInByte[0] = b then
      begin
        //Якщо співпадіння - значить копіюємо блок для порівнняння
        Files.Seek(-1, soFromCurrent);
        SetLength(BufByte, Length(TextInByte));
        Files.Read(BufByte[0], Length(TextInByte));
//        if ReadCount = 0 the Exit;
        Result := CompareMem(@BufByte[0],@TextInByte[0], Length(TextInByte));
        if Result then
          Break;
      end;
    end;
end;

function TCustomSearch.SearchText(TextArr: TArray<TBytes>; FromSearch, ToSearch: Integer): Boolean;
var
  b       : Byte;
  i       : integer;

function CompareBytes(const Byte: Byte): Boolean;
var
  BufByte : TBytes;
  Format  : Integer;
begin
  Result := false;
  for Format := Low(TextArr) to High(TextArr) do
  begin
    if TextArr[Format][0] = Byte then
    begin
      //Якщо співпадіння - значить копіюємо блок для порівнняння
      Files.Seek(-1, soFromCurrent);
      SetLength(BufByte, Length(TextArr[Format]));
      Files.Read(BufByte[0], Length(TextArr[Format]));
  //        if ReadCount = 0 the Exit;
      Result := CompareMem(@BufByte[0],@TextArr[Format][0], Length(TextArr[Format]));
    end;
  end;
end;

function GetLong: integer;
var
  i: Integer;
begin
  Result := 0;
  for I := Low(TextArr) to High(TextArr) do
    if Length(TextArr[i]) > Result then
      Result := Length(TextArr[i]);
end;

begin
  Result := False;

  //Здвиг для 100% пошуку
  if FromSearch <> 0 then
    FromSearch := FromSearch - GetLong;

  //Побайтовий пошук
  for i := 0 to ToSearch do
  begin
    // При потребі зупинемо потік
    if Assigned(Thread) then
      if Thread.CheckTerminated then
        Break;

    Files.Seek(i + FromSearch, soFromBeginning);
    Files.Read(b, sizeOf(b));
    { TODO : Для прискорення пошуку можна спробува читати по складам}
    Result := CompareBytes( b );
    if Result then
      Break;
  end;
end;

{ TSearchASCII }

function TSearchASCII.Search(Text: String): Boolean;
begin
  Result := SearchText( TEncoding.ASCII.GetBytes( AnsiString( Text )));
end;

{ TSearchUTF8 }

function TSearchUTF8.Search(Text: String): Boolean;
begin
  Result := SearchText( TEncoding.UTF8.GetBytes( UTF8Encode( Text )));
end;

{ TSearchUTF16 }

function TSearchUTF16.Search(Text: string): Boolean;
begin
  Result := SearchText( TEncoding.Unicode.GetBytes( Text ));
end;

{ TSearchAll }

function TSearchAll.Search(Text: string; FromSearch, ToSearch: Integer): Boolean;
var
 tmp: TArray<TBytes>;
begin
  SetLength(tmp,3);
  tmp[0] := TEncoding.UTF8.GetBytes( UTF8Encode( Text ));
  tmp[1] := TEncoding.Unicode.GetBytes( Text );
  tmp[2] := TEncoding.ANSI.GetBytes( AnsiString( Text ));
  Result := SearchText(tmp, FromSearch, ToSearch);
end;

end.
