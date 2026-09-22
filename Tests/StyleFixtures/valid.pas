unit ValidStyleFixture;

interface

const
  VALID_VALUE = 42;

type
  TValidObject = class
  private
    FValue: Integer;
  public
    function Calculate(AInput: Integer): Integer;
  end;

implementation

function TValidObject.Calculate(AInput: Integer): Integer;
begin
  Result:=0;

  if (AInput > 0) AND NOT (FValue = 0) then
    Result:=AInput DIV FValue;
end;

end.
