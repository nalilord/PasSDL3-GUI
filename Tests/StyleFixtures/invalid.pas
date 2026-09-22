unit InvalidStyleFixture;

interface

const
  INVALID_VALUE=42;

type
  TInvalidObject = class
  public
    BadField: Integer;
  end;

implementation

procedure InvalidCode;
label RetryPoint;
var
  Value: Integer;
begin
  Value := 1;
  Value:=Value div 1;
  if not (Value in [1, 2]) then begin var &Type: Integer; goto RetryPoint; end;
  Value:=Value + 1; Value:=Value + 2;
  Value:=Value + 123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890;
end;

end.
