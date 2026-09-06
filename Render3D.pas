{
  Render3D — ядро простого программного рендерера кубических блоков.

  Система координат:
    X — вправо, Y — ВНИЗ, Z — от камеры вглубь сцены (левая тройка, как на экране).
    Камера находится в начале координат и смотрит вдоль +Z.
    Блок с координатами (X,Y,Z) занимает куб [X..X+1] x [Y..Y+1] x [Z..Z+1],
    поэтому его БЛИЖНЯЯ грань лежит на Z, а ДАЛЬНЯЯ — на Z+1.

  Проекция перспективная: экранная координата = мировая / Z * Focal + центр окна.
  Чем больше Z, тем меньше объект на экране.
}
unit Render3D;

interface

uses GraphABC;

const
  ///Ближняя плоскость отсечения: блоки ближе неё не рисуются
  NearPlane = 0.5;

///Ограничивает V отрезком [Lo..Hi]
function Limit(V, Lo, Hi: double): double;

type
  ///Точка на плоскости
  FPoint = record
    X, Y: double;
    constructor Create(AX, AY: double);
    begin
      X := AX;
      Y := AY;
    end;
  end;

  ///Точка (или вектор) в пространстве
  Point3D = record
    X, Y, Z: double;
    constructor Create(AX, AY, AZ: double);
    begin
      X := AX;
      Y := AY;
      Z := AZ;
    end;
  end;

  ///Поворот на три угла с заранее вычисленными синусами и косинусами.
  ///Создаётся один раз на блок, а не на каждую из восьми вершин:
  ///это 6 вызовов тригонометрии вместо 48.
  Rot3 = record
    SX, CX, SY, CY, SZ, CZ: double;
    constructor Create(AngX, AngY, AngZ: double);
    begin
      var a := DegToRad(AngX);
      SX := Sin(a);
      CX := Cos(a);
      a := DegToRad(AngY);
      SY := Sin(a);
      CY := Cos(a);
      a := DegToRad(AngZ);
      SZ := Sin(a);
      CZ := Cos(a);
    end;
  end;

  ///Случайное блуждание цвета — плавно «плывущий» оттенок заливки
  ColorWalk = record
    R, G, B: double;
    dR, dG, dB: double;
    constructor Create(AR, AG, AB: double);
    begin
      R := AR;
      G := AG;
      B := AB;
      dR := 0;
      dG := 0;
      dB := 0;
    end;
    ///Один шаг блуждания: скорость меняется случайно, цвет — плавно
    procedure Step;
    begin
      dR := Limit(dR + Random(-1, 1)*0.1, -2, 2);
      dG := Limit(dG + Random(-1, 1)*0.1, -2, 2);
      dB := Limit(dB + Random(-1, 1)*0.1, -2, 2);
      R := Limit(R + dR, 0, 255);
      G := Limit(G + dG, 0, 255);
      B := Limit(B + dB, 0, 255);
    end;
  end;

///Задаёт параметры камеры: размер окна и фокусное расстояние
procedure SetViewport(AWidth, AHeight, AFocal: double);

///Поворачивает точку (X,Y) вокруг точки (oX,oY) на AngDeg градусов
function Rotate(X, Y, oX, oY, AngDeg: double): FPoint;

///Поворачивает точку P вокруг точки Origin; углы уже разложены в R
function RotateAbout(P, Origin: Point3D; R: Rot3): Point3D;

///Поворачивает точку (X,Y,Z) вокруг (oX,oY,oZ) на три угла в градусах.
///Порядок применения осей: Z, затем X, затем Y.
///Удобно для одиночной точки. Если углы одни и те же для многих точек,
///создайте Rot3 один раз и вызывайте RotateAbout — это втрое дешевле.
function Rotate3D(X, Y, Z, oX, oY, oZ, AngX, AngY, AngZ: double): Point3D;

///Проецирует точку на экран.
///Возвращает False, если точка ближе NearPlane — тогда S не меняется.
function Project(P: Point3D; var S: Point): boolean;

///Рисует блок с ребром 1 и ближним верхним углом (X,Y,Z),
///повёрнутый на R вокруг собственного центра.
///Рисуются только грани, обращённые к камере (их не больше трёх),
///каждая — со своей яркостью по закону Ламберта.
///Возвращает False, если блок целиком отсечён.
function DrawBlock(X, Y, Z: double; R: Rot3; BaseR, BaseG, BaseB: double): boolean;

///Упорядочивает блоки по глубине для алгоритма художника:
///дальние — в начало массива, ближние — в конец.
procedure SortByDepth(Blocks: array of Point3D);

implementation

const
  //Смещения восьми вершин куба от центра, в половинах ребра.
  //  0..3 — ближняя грань (Z-), 4..7 — дальняя (Z+)
  VertSigns: array[0..7, 0..2] of integer = (
    (-1, -1, -1), ( 1, -1, -1), ( 1,  1, -1), (-1,  1, -1),
    (-1, -1,  1), ( 1, -1,  1), ( 1,  1,  1), (-1,  1,  1)
  );

  //Шесть граней куба, по четыре вершины на грань.
  //Обход выбран так, чтобы нормаль (v1-v0)x(v2-v0) смотрела НАРУЖУ куба
  //при оси Y, направленной вниз (левая тройка). Согласованность обхода —
  //обязательное условие для отсечения задних граней.
  Faces: array[0..5, 0..3] of integer = (
    (0, 3, 2, 1),   //ближняя Z-
    (4, 5, 6, 7),   //дальняя Z+
    (0, 1, 5, 4),   //верхняя Y-
    (3, 7, 6, 2),   //нижняя  Y+
    (0, 4, 7, 3),   //левая   X-
    (1, 2, 6, 5)    //правая  X+
  );

  //Направление, в котором ИДЁТ свет (единичный вектор).
  //Источник за левым плечом наблюдателя, сверху.
  LightX = 0.424;
  LightY = 0.566;
  LightZ = 0.707;

  //Доля рассеянного света: грань, отвёрнутая от источника, не становится чёрной
  Ambient = 0.35;

var
  //Параметры камеры
  ScrW := 400.0;
  ScrH := 400.0;
  Focal := 400.0;

  //Рабочие буферы. Размер постоянен, поэтому они выделяются один раз при
  //загрузке модуля, а не на каждый блок (иначе это 512 выделений за кадр).
  //Как следствие, DrawBlock не является реентерабельной — для однопоточного
  //рендерера этого достаточно.
  WorldVerts: array[0..7] of Point3D;
  ScreenVerts: array[0..7] of Point;
  Dots: array of Point := new Point[4];

function Limit(V, Lo, Hi: double): double;
begin
  if V < Lo then
    Result := Lo
  else if V > Hi then
    Result := Hi
  else
    Result := V;
end;

///Приводит вещественную компоненту цвета к допустимому байту
function Clamp255(V: double): integer := Round(Limit(V, 0, 255));

procedure SetViewport(AWidth, AHeight, AFocal: double);
begin
  ScrW := AWidth;
  ScrH := AHeight;
  Focal := AFocal;
end;

function Rotate(X, Y, oX, oY, AngDeg: double): FPoint;
begin
  //Поворот матрицей. Прежний вариант считал направление через Arccos,
  //разбирал квадранты вручную и терял точность при малом радиусе;
  //здесь два вызова тригонометрии и никаких особых случаев.
  var a := DegToRad(AngDeg);
  var s := Sin(a);
  var c := Cos(a);
  var dx := X - oX;
  var dy := Y - oY;
  Result := new FPoint(oX + dx*c - dy*s, oY + dx*s + dy*c);
end;

function RotateAbout(P, Origin: Point3D; R: Rot3): Point3D;
begin
  var dx := P.X - Origin.X;
  var dy := P.Y - Origin.Y;
  var dz := P.Z - Origin.Z;

  //Вокруг Z — поворот в плоскости XY
  var tx := dx*R.CZ - dy*R.SZ;
  var ty := dx*R.SZ + dy*R.CZ;
  dx := tx;
  dy := ty;

  //Вокруг X — поворот в плоскости YZ
  ty := dy*R.CX - dz*R.SX;
  var tz := dy*R.SX + dz*R.CX;
  dy := ty;
  dz := tz;

  //Вокруг Y — поворот в плоскости XZ
  tx := dx*R.CY - dz*R.SY;
  tz := dx*R.SY + dz*R.CY;
  dx := tx;
  dz := tz;

  Result := new Point3D(Origin.X + dx, Origin.Y + dy, Origin.Z + dz);
end;

function Rotate3D(X, Y, Z, oX, oY, oZ, AngX, AngY, AngZ: double): Point3D
  := RotateAbout(new Point3D(X, Y, Z), new Point3D(oX, oY, oZ), new Rot3(AngX, AngY, AngZ));

function Project(P: Point3D; var S: Point): boolean;
begin
  Result := P.Z >= NearPlane;
  if not Result then
    exit;
  S := new Point(Round(P.X / P.Z * Focal + ScrW/2),
                 Round(P.Y / P.Z * Focal + ScrH/2));
end;

function DrawBlock(X, Y, Z: double; R: Rot3; BaseR, BaseG, BaseB: double): boolean;
begin
  Result := False;

  //Центр блока: сам блок занимает куб [X..X+1] x [Y..Y+1] x [Z..Z+1]
  var Center := new Point3D(X + 0.5, Y + 0.5, Z + 0.5);

  //1. Вершины в мировых координатах, повёрнутые вокруг центра блока
  for var i := 0 to 7 do
    WorldVerts[i] := RotateAbout(
      new Point3D(Center.X + VertSigns[i, 0]*0.5,
                  Center.Y + VertSigns[i, 1]*0.5,
                  Center.Z + VertSigns[i, 2]*0.5),
      Center, R);

  //2. Проекция на экран. Если хоть одна вершина оказалась за ближней
  //   плоскостью, пропускаем блок целиком: корректное отсечение потребовало бы
  //   резки граней по плоскости, а частичная проекция даёт вывернутую геометрию.
  for var i := 0 to 7 do
    if not Project(WorldVerts[i], ScreenVerts[i]) then
      exit;

  //3. Грани: отбрасываем отвёрнутые от камеры, оставшиеся затеняем
  for var f := 0 to 5 do
  begin
    var A := WorldVerts[Faces[f, 0]];
    var B := WorldVerts[Faces[f, 1]];
    var C := WorldVerts[Faces[f, 2]];

    //Нормаль грани = (B-A) x (C-A); при выбранном обходе она смотрит наружу
    var ux := B.X - A.X;
    var uy := B.Y - A.Y;
    var uz := B.Z - A.Z;
    var vx := C.X - A.X;
    var vy := C.Y - A.Y;
    var vz := C.Z - A.Z;
    var nx := uy*vz - uz*vy;
    var ny := uz*vx - ux*vz;
    var nz := ux*vy - uy*vx;

    //Камера стоит в начале координат, поэтому вектор взгляда на грань — это
    //сама точка A. Грань видима, когда нормаль направлена навстречу взгляду.
    if nx*A.X + ny*A.Y + nz*A.Z >= 0 then
      continue;

    //Затенение по Ламберту: чем ближе нормаль к направлению на источник,
    //тем ярче грань.
    var k := Ambient;
    var nlen := Sqrt(nx*nx + ny*ny + nz*nz);
    if nlen > 0 then
    begin
      var d := -(nx*LightX + ny*LightY + nz*LightZ) / nlen;
      if d > 0 then
        k := Ambient + (1 - Ambient)*d;
    end;

    Brush.Color := RGB(Clamp255(BaseR*k), Clamp255(BaseG*k), Clamp255(BaseB*k));

    for var i := 0 to 3 do
      Dots[i] := ScreenVerts[Faces[f, i]];
    FillPolygon(Dots);
    Result := True;
  end;
end;

procedure SortByDepth(Blocks: array of Point3D);
begin
  //Сортировка вставками: между соседними кадрами порядок меняется мало,
  //поэтому на почти отсортированных данных это фактически O(n).
  for var i := 1 to Blocks.Length - 1 do
  begin
    var cur := Blocks[i];
    var j := i - 1;
    while (j >= 0) and (Blocks[j].Z < cur.Z) do
    begin
      Blocks[j + 1] := Blocks[j];
      j -= 1;
    end;
    Blocks[j + 1] := cur;
  end;
end;

end.
