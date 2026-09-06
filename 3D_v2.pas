{
  Демонстрация 2 — поворот самих блоков, отсечение и освещение.

  Каждый блок вращается вокруг собственного центра, а всё облако медленно
  поворачивается вокруг оси Y. Рисуются только грани, обращённые к камере
  (их никогда не больше трёх), каждая — со своей яркостью, поэтому поворот
  отдельного блока виден на глаз.

  Выход — клавиша Esc или закрытие окна.
}
program Demo3D_v2;

uses GraphABC, Render3D;

const
  WinW = 400;             //ширина окна
  WinH = 400;             //высота окна
  CamFocal = 400.0;       //фокусное расстояние камеры
  BlockCount = 512;       //сколько блоков в облаке
  PivotZ = 40.0;          //центр, вокруг которого вращается облако
  OrbitSpeed = 0.3;       //скорость облёта облака, градусов за кадр
  SpinSpeedX = 1.0;       //скорость собственного вращения блока по X
  SpinSpeedY = 2.0;       //  ... по Y
  SpinSpeedZ = 3.0;       //  ... по Z
  FrameMs = 16;           //бюджет кадра, мс (примерно 60 кадров в секунду)
  ClearAlpha = 255;       //кадр очищается полностью, чтобы читалось освещение

var
  Cloud: array of Point3D;
  Tint: ColorWalk;
  BlockSpin: Rot3;
  Orbit: Rot3;
  Pivot: Point3D;
  AngX, AngY, AngZ: double;
  Running := True;

procedure KeyDown(k: integer);
begin
  if k = VK_Escape then
    Running := False;
end;

begin
  SetWindowSize(WinW, WinH);
  SetWindowTitle('3D Works — v2: поворот, отсечение, свет');
  CenterWindow;
  SetViewport(WinW, WinH, CamFocal);
  OnKeyDown := KeyDown;

  SetLength(Cloud, BlockCount);
  for var i := 0 to BlockCount - 1 do
    Cloud[i] := new Point3D(Random(-16, 16), Random(-16, 16), Random(30, 50));

  Tint := new ColorWalk(128, 128, 128);

  //Скорость облёта постоянна, поэтому раскладываем угол один раз за всю программу
  Orbit := new Rot3(0, OrbitSpeed, 0);
  Pivot := new Point3D(0, 0, PivotZ);

  LockDrawing;
  while Running do
  begin
    var frameStart := Milliseconds;

    ClearWindow(ARGB(ClearAlpha, 0, 0, 0));
    Tint.Step;

    //Углы собственного вращения общие для всего кадра, поэтому синусы и
    //косинусы раскладываются один раз, а не заново для каждого блока.
    //Свёртка в [0..360) нужна потому, что цикл бесконечен: иначе аргумент
    //синуса рос бы неограниченно, постепенно теряя точность.
    AngX := Frac((AngX + SpinSpeedX)/360)*360;
    AngY := Frac((AngY + SpinSpeedY)/360)*360;
    AngZ := Frac((AngZ + SpinSpeedZ)/360)*360;
    BlockSpin := new Rot3(AngX, AngY, AngZ);

    //Облёт облака вокруг вертикальной оси
    for var i := 0 to BlockCount - 1 do
      Cloud[i] := RotateAbout(Cloud[i], Pivot, Orbit);
    SortByDepth(Cloud);

    for var i := 0 to BlockCount - 1 do
      DrawBlock(Cloud[i].X, Cloud[i].Y, Cloud[i].Z, BlockSpin, Tint.R, Tint.G, Tint.B);

    Redraw;

    //Ограничение частоты кадров: без него цикл занимает ядро целиком
    var spent := Milliseconds - frameStart;
    if spent < FrameMs then
      Sleep(FrameMs - spent);
  end;
end.
