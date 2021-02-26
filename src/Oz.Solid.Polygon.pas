(* Oz Solid Library for Pascal
 * Copyright (c) 2020 Marat Shaimardanov
 *
 * This file is part of Oz Solid Library for Pascal
 * is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this file. If not, see <https://www.gnu.org/licenses/>.
 *)

unit Oz.Solid.Polygon;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, Oz.Solid.VectorInt, Oz.Solid.Svg;

{$EndRegion}

{$T+}

{$Region 'types'}

const
  EXIT_SUCCESS = 0;
  EXIT_FAILURE = 1;

type
  tInFlag = (Pin, Qin, Unknown);

  tPointd = record
    x, y: Double;
  end;

  // type integer polygon
  tPolygoni = TArray<T2i>;

{$EndRegion}

{$Region 'TsvgIO'}

  TsvgIO = record
  private
    filename: string;
    svg: TsvgBuilder;
    log: TStrings;
    xmin, ymin, xmax, ymax: Integer;
  public
    procedure Init(const filename: string);
    procedure Free;
    // Prints svg and log
    procedure PrintAll;
    // Debug print
    procedure Dbp; overload;
    procedure Dbp(const line: string); overload;
    procedure Dbp(const fs: string; const args: array of const); overload;
  end;

{$EndRegion}

{$Region 'TPolyBuilder'}

  TPolyBuilder = record
  private
    io: TsvgIO;
    n, m: Integer;
    P, Q: tPolygoni;
    procedure ClosePostscript();
    procedure PrintSharedSeg(p, q: tPointd);

    function Dot(a, b: T2i): Double;
    function AreaSign(a, b, c: T2i): Integer;
    function SegSegInt(a, b, c, d: T2i; p, q: tPointd): Char;
    function ParallelInt(a, b, c, d: T2i; p, q: tPointd): Char;
    function Between(a, b, c: T2i): Boolean;
    procedure Assigndi(p: tPointd; a: T2i);
    procedure SubVec(a, b, c: T2i);
    function LeftOn(a, b, c: T2i): Boolean;
    function Left(a, b, c: T2i): Boolean;
    procedure PrintPoly(n: Integer; P: tPolygoni);

    function InOut(p: tPointd; inflag: tInFlag; aHB, bHA: Integer): tInFlag;

    function Advance(poly: TsvgPolygon; a: Integer; var aa: Integer;
      n: Integer; inside: Boolean; v: T2i): Integer;
    // Read polygons
    procedure ReadPolygons(const filename: string);
    // Write to svg
    procedure OutputPolygons;
  public
    procedure From(const filename: string);
    procedure Build;
    procedure Free;
    // P has n vertices, Q has m vertices.
    function ConvexIntersect(P, Q: tPolygoni; n, m: Integer): Integer;
  end;

{$EndRegion}

implementation

{$Region 'TsvgIO'}

procedure TsvgIO.Init(const filename: string);
begin
  Self.filename := filename;
  svg := TsvgBuilder.Create(800, 600);
  log := TStringList.Create;
end;

procedure TsvgIO.Free;
begin
  FreeAndNil(svg);
  FreeAndNil(log);
end;

procedure TsvgIO.PrintAll;
begin
  svg.SaveToFile(filename + '.svg');
  log.SaveToFile(filename + '.txt');
end;

procedure TsvgIO.Dbp;
begin
  log.Add('');
end;

procedure TsvgIO.Dbp(const line: string);
begin
  log.Add(line);
end;

procedure TsvgIO.Dbp(const fs: string; const args: array of const);
begin
  log.Add(Format(fs, args));
end;

{$EndRegion}

{$Region 'TPolyBuilder'}

procedure TPolyBuilder.From(const filename: string);
begin
  io.Init(filename);
end;

procedure TPolyBuilder.Free;
begin
  io.Free;
end;

procedure TPolyBuilder.Build;
begin
  ReadPolygons(io.filename);
  OutputPolygons;
  ConvexIntersect(P, Q, n, m);
  ClosePostscript;
end;

procedure TPolyBuilder.ReadPolygons(const filename: string);
var
  str: TStrings;
  i: Integer;

  procedure ReadPoly(var P: tPolygoni; var n: Integer);
  var
    line: string;
    j: Integer;
  begin
    n := 0;
    str.LoadFromFile(filename);
    line := str.Strings[i];
    n := Integer.Parse(line);
    while (j > 0) and (i < str.Count) do
    begin
      io.Dbp('Polygon: %d', [n]);
      io.Dbp('  i   x   y');
      io.Dbp('%3d%4d%4d', [n, P[n].x, P[n].y]);
      Dec(j);
      Inc(i);
    end;
  end;

begin
  str := TStringList.Create;
  try
    i := 0;
    ReadPoly(P, n);
    ReadPoly(Q, m);
  finally
    str.Free;
  end;
end;

procedure TPolyBuilder.ClosePostscript;
begin
//  printf("closepath stroke\n");
//  printf("showpage\n%%%%EOF\n");
end;

procedure TPolyBuilder.PrintSharedSeg(p, q: tPointd);
begin
//  printf("%%A int B:\n");
//  printf("%8.2lf %8.2lf moveto\n", p.x, p.y );
//  printf("%8.2lf %8.2lf lineto\n", q.x, q.y );
//  ClosePostscript();
end;

function TPolyBuilder.Dot(a, b: T2i): Double;
begin

end;

function TPolyBuilder.AreaSign(a, b, c: T2i): Integer;
begin

end;

function TPolyBuilder.SegSegInt(a, b, c, d: T2i; p, q: tPointd): Char;
begin

end;

function TPolyBuilder.ParallelInt(a, b, c, d: T2i; p, q: tPointd): Char;
begin

end;

function TPolyBuilder.Between(a, b, c: T2i): Boolean;
begin

end;

procedure TPolyBuilder.Assigndi(p: tPointd; a: T2i);
begin

end;

procedure TPolyBuilder.SubVec(a, b, c: T2i);
begin

end;

function TPolyBuilder.LeftOn(a, b, c: T2i): Boolean;
begin

end;

function TPolyBuilder.Left(a, b, c: T2i): Boolean;
begin

end;

procedure TPolyBuilder.PrintPoly(n: Integer; P: tPolygoni);
begin

end;

function TPolyBuilder.ConvexIntersect(P, Q: tPolygoni; n, m: Integer): Integer;
var
  a, b: Integer;       // indices on P and Q (resp.)
  a1, b1: Integer;     // a-1, b-1 (resp.)
  A_, B_: T2i;         // directed edges on P and Q (resp.)
  Qp, Pp: TsvgPolygon;
  cross: Integer;      // sign of z-component of A x B
  bHA, aHB: Integer;   // b in H(A); a in H(b).
  Origin: T2i;
  p_: tPointd;         // Double point of intersection
  q_: tPointd;         // second point of intersection
  inflag: tInFlag;     // {Pin, Qin, Unknown}: which inside
  aa, ba: Integer;     // # advances on a & b indices (after 1st inter.)
  FirstPoint: Boolean; // Is this the first point? (used to initialize).
  p0: tPointd;         // The first point.
  code: Char;          // SegSegInt return code.
begin
  Origin.x := 0;
  Origin.y := 0;
  // Initialize variables.
  a := 0; b := 0; aa := 0; ba := 0;
  inflag := Unknown;
  FirstPoint := TRUE;

  repeat
    io.Dbp('Before Advances: a=%d, b=%d; aa=%d, ba=%d; inflag=%d',
      [a, b, aa, ba, Ord(inflag)]);
    // Computations of key variables.
    a1 := (a + n - 1) mod n;
    b1 := (b + m - 1) mod m;

    SubVec(P[a], P[a1], A_);
    SubVec(Q[b], Q[b1], B_);

    cross := AreaSign(Origin, A_, B_);
    aHB := AreaSign(Q[b1], Q[b], P[a]);
    bHA := AreaSign(P[a1], P[a], Q[b]);
    io.Dbp('cross=%d, aHB=%d, bHA=%d', [cross, aHB, bHA]);

    // If A_ & B_ intersect, update inflag.
    code := SegSegInt(P[a1], P[a], Q[b1], Q[b], p_, q_);
    io.Dbp('SegSegInt: code = %c', [code]);
    if (code = '1') or (code = 'v') then
    begin
      if (inflag = Unknown) and FirstPoint then
      begin
        aa := 0; ba := 0;
        FirstPoint := FALSE;
        p0.x := p_.x;
        p0.y := p_.y;
        io.Dbp('%8.2lf %8.2lf moveto', [p0.x, p0.y]);
      end;
      inflag := InOut(p_, inflag, aHB, bHA);
      io.Dbp('InOut sets inflag=%d', [Ord(inflag)]);
    end;

    // Advance rule

    // Special case: A_ & B_ overlap and oppositely oriented.
    if (code = 'e' ) and (Dot(A_, B_) < 0) then
    begin
      PrintSharedSeg( p_, q_);
      exit(EXIT_SUCCESS);
    end;

    // Special case: A_ & B_ parallel and separated.
    if (cross = 0) and (aHB < 0) and (bHA < 0) then
    begin
      io.Dbp('P and Q are disjoint.');
      exit(EXIT_SUCCESS);
    end
    // Special case: A_ & B_ collinear.
    else if (cross = 0) and ( aHB = 0) and (bHA = 0) then
    begin
      // Advance but do not output point.
      if inflag = Pin then
        b := Advance(Qp, b, ba, m, inflag = Qin, Q[b])
      else
        a := Advance(Pp, a, aa, n, inflag = Pin, P[a]);
    end
    // Generic cases.
    else if cross >= 0 then
    begin
      if bHA > 0 then
        a := Advance(Pp, a, aa, n, inflag = Pin, P[a])
      else
        b := Advance(Qp, b, ba, m, inflag = Qin, Q[b]);
    end
    else // if ( cross < 0 )
    begin
      if aHB > 0 then
        b := Advance(Qp, b, ba, m, inflag = Qin, Q[b])
      else
        a := Advance(Pp, a, aa, n, inflag = Pin, P[a]);
    end;
    io.Dbp('After advances:a=%d, b=%d; aa=%d, ba=%d; inflag=%d',
      [a, b, aa, ba, Ord(inflag)]);

    // Quit when both adv. indices have cycled, or one has cycled twice.
  until not (((aa < n) or (ba < m)) and (aa < 2 * n) and (ba < 2 * m));

  if not FirstPoint then
    // If at least one point output, close up.
    io.Dbp('%8.2lf %8.2lf lineto', [p0.x, p0.y]);

  // Deal with special cases: not implemented.
  if inflag = Unknown then
    io.Dbp('The boundaries of P and Q do not cross.');
end;

function TPolyBuilder.Advance(poly: TsvgPolygon; a: Integer; var aa: Integer;
  n: Integer; inside: Boolean; v: T2i): Integer;
begin
  if inside then
    poly.Point(v);
  Inc(aa);
  Result := (a + 1) mod n;
end;

function TPolyBuilder.InOut(p: tPointd; inflag: tInFlag; aHB, bHA: Integer): tInFlag;
begin

end;

procedure TPolyBuilder.OutputPolygons;
var
  xmin, ymin, xmax, ymax: Integer;
  width, height: Integer;

  // Compute Bounding Box
  procedure BBox(const P: tPolygoni);
  var
    i, xmin, ymin, xmax, ymax: Integer;
  begin
    for i := 1 to High(P) do
    begin
      if P[i].x > xmax then
        xmax := P[i].x
      else if P[i].x < xmin then
        xmin := P[i].x;
      if P[i].y > ymax then
        ymax := P[i].y
      else if P[i].y < ymin then
        ymin := P[i].y;
    end;
  end;

  // Write polygon to svg
  procedure PolygonToSvg(const P: tPolygoni; const color: string);
  var
    i: Integer;
    g: TsvgPolygon;
  begin
    g := io.svg.Polygon;
    for i := 0 to High(P) do
      g.Point(P[i].x, P[i].y);
    g.Stroke(color).StrokeWidth(0.2);
  end;

begin
  // Compute Bounding Box
  xmin := P[0].x;
  xmax := P[0].x;
  ymin := P[0].y;
  ymax := P[0].y;
  BBox(P);
  BBox(Q);

  // ViewBox
  width := xmax - xmin + 1;
  height := xmax - xmin + 1;
  io.svg.ViewBox(xmin, ymin, width, height);

  PolygonToSvg(P, 'green');
  PolygonToSvg(Q, 'red');
end;

{$EndRegion}

end.

