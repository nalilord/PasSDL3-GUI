# Code Style Guide

This document defines the preferred Pascal coding style.

The goal is readable, explicit, Delphi/FPC-friendly code with predictable formatting and low ambiguity.

## 1. Line Length

Keep project-owned Pascal lines at or below **160 characters**.

This is a style limit rather than a compiler limit. A narrowly unavoidable long
literal or external reference requires a documented checker exclusion; ordinary
declarations and executable code should be wrapped.

```pascal
SomeVeryLongCall(FirstArgument, SecondArgument, ThirdArgument, FourthArgument, FifthArgument);
```

When wrapping is needed, prefer a clear continuation style:

```pascal
SomeVeryLongCall(FirstArgument, SecondArgument, ThirdArgument, FourthArgument,
  FifthArgument, SixthArgument);
```

Do not place multiple executable statements on one line:

```pascal
A:=1000; B:=2000; DoSomething;
```

## 2. Assignment and Constant Formatting

### 2.1 Variable assignments

Do **not** place spaces around `:=`.

Preferred:

```pascal
VarName:=Value;
Result:=0;
FFrame:=nil;
```

Avoid:

```pascal
VarName := Value;
Result := 0;
FFrame := nil;
```

### 2.2 Constants

Use spaces around `=` in constants.

Preferred:

```pascal
const
  DEFAULT_CODEC = 'h264';
  MAX_QUEUE_SIZE = 1024;
```

Avoid:

```pascal
const
  DEFAULT_CODEC='h264';
  MAX_QUEUE_SIZE=1024;
```

## 3. Logical and Bitwise Keywords

Logical and bitwise operation keywords must be uppercase in conditional or math expressions.

Use:

```pascal
if Assigned(Node) AND Node.Enabled then
  Node.Start;

if NOT Assigned(FFrame) then
  Exit;

if (Flags AND FLAG_KEYFRAME) <> 0 then
  Packet.IsKeyFrame:=True;
```

Preferred uppercase keywords:

```text
AND
OR
NOT
XOR
SHL
SHR
DIV
MOD
IN
IS
AS
```

Normal Pascal structural keywords remain lowercase:

```pascal
if Value > 0 then
begin
end;
```

## 4. Block Structure

### 4.1 Single-statement `if`

For a single statement, do not use `begin/end` unless it improves clarity.

Preferred:

```pascal
if 1 = 2 then
  SingleStatement
else
  ElseStatement;
```

### 4.2 Multi-statement `if`

For multiple statements, use `begin/end`.

The `else` should be placed on the same line as the preceding `end`.

Preferred:

```pascal
if 1 = 2 then
begin
  // code
end else
begin
  // code
end;
```

### 4.3 `else if`

Use the explicit Pascal form with `else if` split as `end else if` style.

Preferred:

```pascal
if 1 = 2 then
begin
  // code
end else
if 1 = 2 then
begin
  // code
end;
```

This keeps nesting and alternative branches visually clear.

## 5. Case Statements

Preferred structure:

```pascal
case VarValue of
  1:
  begin
    // code
  end;

  2: Exit; // Single-line code can be placed directly after the label.

  else
  begin
    // code here
  end;
end;
```

Single-line case branches are allowed when they remain readable:

```pascal
case Packet.Kind of
  pkUnknown: Result:='unknown';
  pkFlvTag: Result:='flv';
  pkFFmpegPacket: Result:='ffmpeg';
  else Result:='other';
end;
```

For multi-line branches, use `begin/end`.

## 6. Flow Structure and Early Returns

### 6.1 General rule

Avoid hidden or deeply nested early exits.

Early `Exit` is acceptable for obvious guard clauses at the beginning of a routine.

Preferred:

```pascal
procedure Test;
begin
  if NOT Assigned(FooBar) then
    Exit;

  // normal routine logic here
end;
```

Avoid obscure exits inside complex nested logic:

```pascal
procedure Test;
begin
  if NOT Assigned(FooBar) then
    Exit; // This guard clause is ok.

  if A then
  begin
    if B then
      CallFunc;

    if C then
      Exit; // Avoid this style if possible. It is easy to miss inside nested logic.

    if D then
    begin
      // code
    end;
  end else
  begin
    // code
  end;
end;
```

Use such nested exits only when they are truly the clearest or only practical way to express the flow.

### 6.2 Function result defaults

Functions should assign `Result` a default value first.

This keeps the default behavior clear and avoids unnecessary `else` branches.

Preferred:

```pascal
function GetValue: Integer;
begin
  Result:=0;

  if Assigned(FooBar) then
    Result:=FooBar.Value;
end;
```

Preferred:

```pascal
function GetName: string;
begin
  Result:='';

  if Assigned(FItem) then
    Result:=FItem.Name;
end;
```

Avoid:

```pascal
function GetValue: Integer;
begin
  if Assigned(FooBar) then
    Result:=FooBar.Value
  else
    Result:=0;
end;
```

## 7. Naming Rules

### 7.1 Fields

Class and record fields must be prefixed with `F`.

Preferred:

```pascal
private
  FGraph: TAVGraph;
  FNodeName: string;
  FPacketCount: Int64;
```

### 7.2 Local variables

Local variables do not get a prefix.

Preferred:

```pascal
var
  Packet: TAVPacket;
  Frame: TAVFrame;
  StreamIndex: Integer;
```

Avoid:

```pascal
var
  LPacket: TAVPacket;
  LFrame: TAVFrame;
```

### 7.3 Arguments

Arguments usually get prefixed with `A`.

Preferred:

```pascal
constructor Create(AGraph: TAVGraph; const AName: string);
procedure Connect(AOutput: TAVOutputPin; AInput: TAVInputPin);
```

This is preferred, but existing code may be a mixed bag. When adding new public APIs, prefer the `A` prefix.

### 7.4 Avoid reserved keywords as names

Do not use Pascal keywords as variable names with `&`.

Avoid:

```pascal
var
  &Type: Integer;
```

Prefer a meaningful alternative:

```pascal
var
  Typ: Integer;
```

Or better:

```pascal
var
  MediaType: TAVMediaKind;
  PacketType: TAVPacketKind;
```

### 7.5 Loop variable names

For generic loops, use:

```pascal
I
J
K
```

For coordinates or multidimensional data, use:

```pascal
X
Y
Z
```

For count/size related loops, descriptive names such as `Count` or `Size` may be used when they make sense.

Examples:

```pascal
for I:=0 to FNodes.Count - 1 do
  FNodes[I].Open;

for Y:=0 to Height - 1 do
begin
  for X:=0 to Width - 1 do
    ProcessPixel(X, Y);
end;
```

### 7.6 Enumerator variable names

When iterating a list, name the enumerator after the singular form of the list name.

Preferred:

```pascal
for Item in Items do
  Item.Process;

for Node in Nodes do
  Node.Open;

for Packet in Packets do
  Packet.Unref;
```

Avoid unrelated generic names when the collection has a clear item type.

## 8. Semantics and Language Usage

### 8.1 Labels

Labels are generally prohibited.

Do not use labels/goto for normal flow control.

Exception:

Labels may be used only when there is a direct and justified performance impact, for example in parsers, scanners, or other low-level hot paths where the benefit is measurable and documented.

### 8.2 Inline variable declarations

Inline variable declarations are not allowed.

Avoid:

```pascal
begin
  var Packet:=TAVPacket.Create;
end;
```

Avoid inline loop variable declarations:

```pascal
for var I:=0 to Count - 1 do
  Process(I);
```

Preferred:

```pascal
var
  Packet: TAVPacket;
  I: Integer;
begin
  Packet:=TAVPacket.Create;
  try
    for I:=0 to Count - 1 do
      Process(I);
  finally
    Packet.Free;
  end;
end;
```

Reasons:

- Better Delphi/FPC compatibility.
- Clearer variable lifetime.
- Easier to read in larger routines.
- Avoids IDE/compiler differences.

## 9. Comments

Use comments to explain why something is done, not merely what the code is doing.

Good:

```pascal
// FFmpeg may return EAGAIN when the decoder needs more packets before producing another frame.
if ErrorCode = AVERROR_EAGAIN then
  Result:=False;
```

Less useful:

```pascal
// Assign Result to False.
Result:=False;
```

## 10. Ownership and Lifetime Style

Use explicit `try/finally` for owned objects.

Preferred:

```pascal
Packet:=TAVPacket.Create;
try
  ProcessPacket(Packet);
finally
  Packet.Free;
end;
```

For object fields, release ownership in destructors.

Preferred:

```pascal
destructor TAVNode.Destroy;
begin
  FPins.Free;
  inherited Destroy;
end;
```

Avoid ambiguous ownership.

Method names should make ownership behavior clear:

```pascal
Attach
Detach
Clone
MoveFrom
Unref
Clear
```

## 11. Example Routine Style

Preferred routine layout:

```pascal
function TAVGraph.Step: Boolean;
var
  I: Integer;
  Node: TAVNode;
begin
  Result:=False;

  if FNodes.Count = 0 then
    Exit;

  for I:=0 to FNodes.Count - 1 do
  begin
    Node:=TAVNode(FNodes[I]);

    if Node.Step then
      Result:=True;
  end;
end;
```

Preferred object creation style:

```pascal
procedure TAVGraph.Open;
var
  I: Integer;
  Node: TAVNode;
begin
  for I:=0 to FNodes.Count - 1 do
  begin
    Node:=TAVNode(FNodes[I]);
    Node.Open;
  end;
end;
```

## 12. Summary

Core style rules:

```text
Maximum line length 160 characters, apart from documented narrow exclusions.
One executable statement per line, except for the documented single-line case branches.
No spaces around := assignments.
Spaces around = in constants.
Logical/math keywords uppercase: AND, OR, NOT, XOR, SHL, SHR, DIV, MOD.
Field variables use F prefix.
Local variables use no prefix.
Arguments usually use A prefix.
Avoid reserved keyword names with &.
Avoid inline var declarations.
Avoid labels except for justified parser/hot-path performance.
Assign Result default value first.
Avoid hidden nested exits.
Keep begin/end structure clear and consistent.
```
