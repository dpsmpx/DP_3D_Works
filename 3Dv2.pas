[id787989088|Якто], итак, вот новая версия программы:
{
  TODO:
    -Отрисовка блока с поворотом [самого блока, а не камеры]
    -Отрисовка только трёх видимых, передних граней блока
    -Отрисовка только видимых блоков
    -Освещение
    -Отражение?
    -Прозрачные блоки
      -Изменить поиск видимых блоков с учетом прозрачности блоков
}
Uses GraphABC;
type
  FPoint = record
    X,Y: double;
    constructor Create(_x,_y: integer);
    begin
      X := _x;
      Y := _y;
    end;
    constructor Create(_x,_y: double);
    begin
      X := _x;
      Y := _y;
    end;
  end;
  Point3D = record
    X,Y,Z: double;
    constructor Create(_x,_y,_z: integer);
    begin
      X := _x;
      Y := _y;
      Z := _z;
    end;
    constructor Create(_x,_y,_z: double);
    begin
      X := _x;
      Y := _y;
      Z := _z;
    end;
  end;
var
  W := 400;
  H := 400;
  _W := 400;
  _H := 400;
  X,GX,Y,GY,Z,GZ: INTEGER;
  DX,DY,DZ: INTEGER;
  R := 128.0;dR := 0.0;
  G := 128.0;dG := 0.0;
  B := 128.0;dB := 0.0;
  _aX, _aY, _aZ: double;
  
procedure SetC(R,G,B: integer) := Brush.Color := RGB(R,G,B);
procedure SetC(R,G,B: double) := Brush.Color := RGB(R.Round,G.Round,B.Round);
procedure SetC(A,R,G,B: integer) := Brush.Color := ARGB(A,R,G,B);
procedure SetC(c: Color) := Brush.Color := c;
function Len2D(x1,y1,x2,y2: double) := Sqrt(Sqr(x2-x1)+Sqr(y2-y1));
function RND(max: integer) := Random(max);
function RND(min,max: integer) := Random(min,max);

function Ang(x0,y0,x1,y1: double): double;
begin
  var r:=sqrt(sqr(x1 - x0) + sqr(y1 - y0));
  if r <> 0 then result:=Arccos((x1 - x0)/r)*180/pi else result:= 0;
  if (y0-y1)<=0 then result:= 360-result;result:=360-result;{инверсия}
end;

///Принимает:
///  координаты точки, которую нужно повернуть
///  координаты точки, вокруг которой_поворачивать
///  угол, на который нужно повернуть
function Rotate(X, Y, oX, oY, ang_: double): FPoint;
var dir, len: double;
    SX := oX;
    SY := oY;
begin
  //Используя Ang и Len2D, вычислить новую позицию
  X -= oX;
  Y -= oY;
  oX := 0;
  oY := 0;
  dir := Ang(X,Y,oX,oY);
  len := Len2D(X,Y,oX,oY);
  Result := new FPoint(SX+Cos(DegToRad(dir+ang_))*len,SY+Sin(DegToRad(dir+ang_))*len);
end;

///Принимает:
///  координаты точки, которую нужно повернуть
///  координаты точки, вокруг которой_поворачивать
///  угол, на который нужно повернуть
function Rotate3D(X, Y, Z, oX, oY, oZ, ang_x, ang_y, ang_z: double): Point3D;
begin
  Result := new Point3D(Rotate(X,Y,oX,oY,ang_z).X,Rotate(X,Y,oX,oY,ang_z).Y,Z);
  X := Result.X;
  Y := Result.Y;
  Result := new Point3D(X,Rotate(Y,Z,oY,oZ,ang_x).X,Rotate(Y,Z,oY,oZ,ang_x).Y);
  Y := Result.Y;
  Z := Result.Z;
  Result := new Point3D(Rotate(X,Z,oX,oZ,ang_y).X,Y,Rotate(X,Z,oX,oZ,ang_y).Y);
end;

procedure FR(X,Y,FW,FH: double) := FillRect(X.Round,Y.Round,X.Round+FW.Round,Y.Round+FH.Round);

procedure FC3D(X, Y, Z: INTEGER) := FR(X/Z*_W+W/2, Y/Z*_W+H/2,-Z,-Z);

procedure BLOCK(X, Y, Z: INTEGER);
var Dots: array of Point;
begin
  try
  begin
    SetLength(Dots, 4);
    
    //Back
    Dots[0] := new Point(Round(X/Z*_W+W/2), Round(Y/Z*_W+H/2));
    Dots[1] := new Point(Round(X/Z*_W+W/2), Round((Y+1)/Z*_W+H/2));
    Dots[2] := new Point(Round((X+1)/Z*_W+W/2), Round((Y+1)/Z*_W+H/2));
    Dots[3] := new Point(Round((X+1)/Z*_W+W/2), Round(Y/Z*_W+H/2));
    FillPolygon(Dots);
    
    //Down
    Dots[0] := new Point(Round(X/Z*_W+W/2), Round((Y+1)/Z*_W+H/2));
    Dots[1] := new Point(Round(X/(Z+1)*_W+W/2), Round((Y+1)/(Z+1)*_W+H/2));
    Dots[2] := new Point(Round((X+1)/(Z+1)*_W+W/2), Round((Y+1)/(Z+1)*_W+H/2));
    Dots[3] := new Point(Round((X+1)/Z*_W+W/2), Round((Y+1)/Z*_W+H/2));
    FillPolygon(Dots);
    
    //Up
    Dots[0] := new Point(Round(X/(Z+1)*_W+W/2), Round(Y/(Z+1)*_W+H/2));
    Dots[1] := new Point(Round(X/Z*_W+W/2), Round(Y/Z*_W+H/2));
    Dots[2] := new Point(Round((X+1)/Z*_W+W/2), Round(Y/Z*_W+H/2));
    Dots[3] := new Point(Round((X+1)/(Z+1)*_W+W/2), Round(Y/(Z+1)*_W+H/2));
    FillPolygon(Dots);
    
    //Right
    Dots[0] := new Point(Round((X+1)/(Z+1)*_W+W/2), Round(Y/(Z+1)*_W+H/2));
    Dots[1] := new Point(Round((X+1)/(Z+1)*_W+W/2), Round((Y+1)/(Z+1)*_W+H/2));
    Dots[3] := new Point(Round((X+1)/Z*_W+W/2), Round(Y/Z*_W+H/2));
    Dots[2] := new Point(Round((X+1)/Z*_W+W/2), Round((Y+1)/Z*_W+H/2));
    FillPolygon(Dots);
    
    //Left
    Dots[0] := new Point(Round(X/(Z+1)*_W+W/2), Round(Y/(Z+1)*_W+H/2));
    Dots[1] := new Point(Round(X/(Z+1)*_W+W/2), Round((Y+1)/(Z+1)*_W+H/2));
    Dots[3] := new Point(Round(X/Z*_W+W/2), Round(Y/Z*_W+H/2));
    Dots[2] := new Point(Round(X/Z*_W+W/2), Round((Y+1)/Z*_W+H/2));
    FillPolygon(Dots);
    
    //Face
    Dots[0] := new Point(Round(X/(Z+1)*_W+W/2), Round(Y/(Z+1)*_W+H/2));
    Dots[1] := new Point(Round(X/(Z+1)*_W+W/2), Round((Y+1)/(Z+1)*_W+H/2));
    Dots[2] := new Point(Round((X+1)/(Z+1)*_W+W/2), Round((Y+1)/(Z+1)*_W+H/2));
    Dots[3] := new Point(Round((X+1)/(Z+1)*_W+W/2), Round(Y/(Z+1)*_W+H/2));
    FillPolygon(Dots);
  end
  except
  end;
end;

//Отрисовка с поворотом
procedure _BLOCK(X, Y, Z, aX, aY, aZ: Double);
const
  // Индексы вершин куба (8 штук)
  // 0: (-,-,-), 1: (+,-,-), 2: (+,+,-), 3: (-,+,-)
  // 4: (-,-,+), 5: (+,-,+), 6: (+,+,+), 7: (-,+,+)
  VertIndices: array[0..7, 0..2] of Integer = (
    (-1,-1,-1), ( 1,-1,-1), ( 1, 1,-1), (-1, 1,-1),
    (-1,-1, 1), ( 1,-1, 1), ( 1, 1, 1), (-1, 1, 1)
  );
  // Грани: каждая грань — 4 индекса вершин (порядок обхода важен)
  Faces: array[0..5, 0..3] of Integer = (
    (0,1,2,3),  // задняя (Z-)
    (4,5,6,7),  // передняя (Z+)
    (0,1,5,4),  // нижняя (Y-)
    (2,3,7,6),  // верхняя (Y+)
    (0,3,7,4),  // левая (X-)
    (1,2,6,5)   // правая (X+)
  );
var
  Center: Point3D;
  WorldVerts: array[0..7] of Point3D;   // мировые координаты вершин
  RotVerts:   array[0..7] of Point3D;   // после поворота
  ScreenVerts: array[0..7] of TPoint;   // экранные координаты
  i, f: Integer;
  p: TPoint;
begin
  // 1. Центр блока
  Center := new Point3D(X + 0.5, Y + 0.5, Z + 0.5);

  // 2. Получаем мировые координаты вершин (смещения ±0.5)
  for i := 0 to 7 do
    WorldVerts[i] := new Point3D(
      Center.X + VertIndices[i,0] * 0.5,
      Center.Y + VertIndices[i,1] * 0.5,
      Center.Z + VertIndices[i,2] * 0.5
    );

  // 3. Поворачиваем каждую вершину вокруг центра
  for i := 0 to 7 do
    RotVerts[i] := Rotate3D(
      WorldVerts[i].X, WorldVerts[i].Y, WorldVerts[i].Z,
      Center.X, Center.Y, Center.Z,
      aX, aY, aZ
    );

  // 4. Проецируем на экран (перспектива с делением на Z)
  for i := 0 to 7 do
  begin
    if Abs(RotVerts[i].Z) < 1e-6 then  // защита от деления на ноль
      Continue;
    ScreenVerts[i].X := Round(RotVerts[i].X / RotVerts[i].Z * _W + W / 2);
    ScreenVerts[i].Y := Round(RotVerts[i].Y / RotVerts[i].Z * _W + H / 2);
  end;

  // 5. Рисуем все 6 граней (каждая — полигон из 4 точек)
  for f := 0 to 5 do
  begin
    SetLength(Dots, 4);
    for i := 0 to 3 do
      Dots[i] := ScreenVerts[Faces[f, i]];
    FillPolygon(Dots);
  end;
end;

procedure ChangeColor;
begin
  dR += RND(-1,1)*0.1;
  dG += RND(-1,1)*0.1;
  dB += RND(-1,1)*0.1;
  if dR > 2 then dR := 2;
  if dR < -2 then dR := -2;
  if dG > 2 then dG := 2;
  if dG < -2 then dG := -2;
  if dB > 2 then dB := 2;
  if dB < -2 then dB := -2;
  
  R += dR;
  IF R < 0 THEN R := 0;
  IF R > 255 THEN R := 255;
  G += dG;
  IF G < 0 THEN G := 0;
  IF G > 255 THEN G := 255;
  B += dB;
  IF B < 0 THEN B := 0;
  IF B > 255 THEN B := 255;
end;

procedure RotateTest;
var Figure: array of Point3D;
    Num := 512;
    Rx, Ry, Rz: double;
begin
  SetLength(Figure,Num);
  for i: integer := 0 to Num-1 do
    Figure[i] := new Point3D(Random(-16,16),Random(-16,16),Random(30,50));
  LockDrawing;
  while true do
  begin
    ClearWindow(ARGB(32,0,0,0));
    ChangeColor;
    Brush.Color := RGB(R.Round,G.Round,B.Round);
    Rx += Random(-1,1)*0.1;
    Ry += Random(-1,1)*0.1;
    Rz += Random(-1,1)*0.1;
    if Rx < -3 then Rx := -3;
    if Rx >  3 then Rx :=  3;
    if Ry < -3 then Ry := -3;
    if Ry >  3 then Ry :=  3;
    if Rz < -3 then Rz := -3;
    if Rz >  3 then Rz :=  3;
    for i: integer := 0 to Num-1 do
    begin
      Block(Figure[i].X.Round,Figure[i].Y.Round,Figure[i].Z.Round);//,_aX,_aY,_aZ);
      Figure[i] := Rotate3D(Figure[i].X,Figure[i].Y,Figure[i].Z,0,0,40,Rx,Ry,Rz);
      _aX += 1;
      _aY += 2;
      _aZ += 3;
    end;
    Redraw;
  end;
end;

procedure Init;
begin
  SetWindowSize(W,H);
  SetWindowTitle('3D Works');
  CenterWindow;
  LockDrawing;
end;

begin
  Init;
  RotateTest;
end.