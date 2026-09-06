{
  Демонстрация 1 — перспективная проекция и алгоритм художника.

  Облако из 512 блоков вращается вокруг точки (0, 0, PivotZ).
  Сами блоки по осям не поворачиваются: меняется только их положение,
  поэтому все они остаются выровненными по осям координат.
  Поворот самих блоков показан в 3D_v2.pas.

  Выход — клавиша Esc или закрытие окна.
}
program Demo3D_v1;

uses GraphABC, Render3D;

const
  WinW = 400;             //ширина окна
  WinH = 400;             //высота окна
  CamFocal = 400.0;       //фокусное расстояние камеры
  BlockCount = 512;       //сколько блоков в облаке
  PivotZ = 40.0;          //центр, вокруг которого вращается облако
  MaxSpin = 3.0;          //предел угловой скорости, градусов за кадр
  FrameMs = 16;           //бюджет кадра, мс (примерно 60 кадров в секунду)
  TrailAlpha = 32;        //непрозрачность заливки фона: даёт следы движения

var
  Cloud: array of Point3D;
  Tint: ColorWalk;
  NoRotation: Rot3;
  Pivot: Point3D;
  SpinX, SpinY, SpinZ: double;
  Running := True;

procedure KeyDown(k: integer);
begin
  if k = VK_Escape then
    Running := False;
end;

begin
  SetWindowSize(WinW, WinH);
  SetWindowTitle('3D Works — v1: проекция');
  CenterWindow;
  SetViewport(WinW, WinH, CamFocal);
  OnKeyDown := KeyDown;

  SetLength(Cloud, BlockCount);
  for var i := 0 to BlockCount - 1 do
    Cloud[i] := new Point3D(Random(-16, 16), Random(-16, 16), Random(30, 50));

  Tint := new ColorWalk(128, 128, 128);
  NoRotation := new Rot3(0, 0, 0);
  Pivot := new Point3D(0, 0, PivotZ);

  LockDrawing;
  while Running do
  begin
    var frameStart := Milliseconds;

    ClearWindow(ARGB(TrailAlpha, 0, 0, 0));
    Tint.Step;

    SpinX := Limit(SpinX + Random(-1, 1)*0.1, -MaxSpin, MaxSpin);
    SpinY := Limit(SpinY + Random(-1, 1)*0.1, -MaxSpin, MaxSpin);
    SpinZ := Limit(SpinZ + Random(-1, 1)*0.1, -MaxSpin, MaxSpin);

    //Углы одни на весь кадр, поэтому синусы и косинусы считаются один раз,
    //а не заново для каждого из 512 блоков
    var CloudSpin := new Rot3(SpinX, SpinY, SpinZ);

    //Сначала сдвигаем облако, затем сортируем: рисовать нужно уже новый порядок
    for var i := 0 to BlockCount - 1 do
      Cloud[i] := RotateAbout(Cloud[i], Pivot, CloudSpin);
    SortByDepth(Cloud);

    for var i := 0 to BlockCount - 1 do
      DrawBlock(Cloud[i].X, Cloud[i].Y, Cloud[i].Z, NoRotation, Tint.R, Tint.G, Tint.B);

    Redraw;

    //Ограничение частоты кадров: без него цикл занимает ядро целиком
    var spent := Milliseconds - frameStart;
    if spent < FrameMs then
      Sleep(FrameMs - spent);
  end;
end.
