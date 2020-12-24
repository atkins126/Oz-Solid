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
unit Oz.Solid.DelaunayTri;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Math, Oz.Solid.VectorInt, Oz.Solid.Svg;

{$EndRegion}

{$T+}

type
  tVertex = ^tsVertex;
  tFace = ^tsFace;
  tEdge = ^tsEdge;

  T3i = record
    x, y, z: Integer;
  end;

{$Region 'tsVertex: vertices'}

  tsVertex = record
    v: T3i;
    vnum: Integer;
    duplicate: tEdge;  // pointer to incident cone edge (or nil)
    onhull: Boolean;   // T iff point on hull.
    mark: Boolean;     // T iff point already processed.
    next: tVertex;
    prev: tVertex;
  end;

{$EndRegion}

{$Region 'tsEdge: edges'}

  tsEdge = record
    adjface: array [0..1] of tFace;
    endpts: array [0..1] of tVertex;
    newface: tFace;     // pointer to incident cone face.
    delete: Boolean;    // T iff edge should be delete.
    next: tEdge;
    prev: tEdge;
  end;

{$EndRegion}

{$Region 'tsFace: faces'}

  tsFace = record
    edge: array [0..2] of tEdge;
    vertex: array [0..2] of tVertex;
    visible: Boolean;   // T iff face visible from new point.
    lower: Boolean;     // T iff on the lower hull
    next: tFace;
    prev: tFace;
  end;

{$EndRegion}

{$Region 'TsvgIO'}

  TsvgIO = record
  strict private
    filename: string;
    svg: TsvgBuilder;
    log: TStrings;
    xmin, ymin, xmax, ymax: Integer;
    // Compute bounding box for Encapsulated SVG.
    function CalcBounds(vertices: tVertex): Integer;
  public
    debug: Boolean;
    check: Boolean;
    procedure Init(const filename: string);
    procedure Free;
    // Prints out the vertices and the faces. Uses the vnum indices
    // corresponding to the order in which the vertices were input.
    procedure Print(vertices: tVertex; edges: tEdge; faces: tFace);
    // CheckEuler checks Euler's relation, as well as its implications when
    // all faces are known to be triangles.  Only prints positive information
    // when debug is true, but always prints negative information.
    procedure CheckEuler(V, E, F: Integer);
    // Debug print
    procedure Dbp; overload;
    procedure Dbp(const line: string); overload;
    procedure Dbp(const fs: string; const args: array of const); overload;
  end;

{$EndRegion}

{$Region 'TDelaunayTri'}

  TDelaunayTri = class
  private
    io: TsvgIO;
    vertices: tVertex;
    edges: tEdge;
    faces: tFace;
    xmin, ymin, xmax, ymax: Integer;
    procedure Add(var head: tVertex; p: tVertex);
    procedure Delete(var head: tVertex; p: tVertex);
    // Volumed is the same as VolumeSign but computed with doubles.
    // For protection against overflow.
    function Volumed(f: tFace; p: tVertex): Double;
    function Volumei(f: tFace; p: tVertex): Integer;
  public
    procedure Build(const filename: string);
    // MakeNullVertex: Makes a vertex, nulls out fields
    function MakeNullVertex: tVertex;
    // Reads in the vertices, and links them into a circular
    // list with MakeNullVertex. There is no need for the # of vertices
    // to be the first line: the function looks for EOF instead.
    function ReadVertices(const filename: string): Integer;
    // SubVec: Computes a - b and puts it into c.
    procedure SubVec(const a, b: T3i; var c: T3i);
    // DoubleTriangle builds the initial Double triangle.  It first finds 3
    // noncollinear points and makes two faces out of them, in opposite order.
    // It then finds a fourth point that is not coplanar with that face.  The
    // vertices are stored in the face structure in counterclockwise order so
    // that the volume between the face and the point is negative. Lastly, the
    // 3 newfaces to the fourth point are constructed and the data structures
    // are cleaned up.
    procedure DoubleTriangle;
    // ConstructHull adds the vertices to the hull one at a time.
    // The hull vertices are those in the list marked as onhull.
    procedure ConstructHull;
    // AddOne is passed a vertex.  It first determines all faces visible from
    // that point.  If none are visible then the point is marked as not
    // onhull.  Next is a loop over edges.  If both faces adjacent to an edge
    // are visible, then the edge is marked for deletion.  If just one of the
    // adjacent faces is visible then a new face is constructed.
    function AddOne(p: tVertex): Boolean;
    // VolumeSign exit(s the sign of the volume of the tetrahedron determined by f
    // and p.  VolumeSign is +1 iff p is on the negative side of f,
    // where the positive side is determined by the rh-rule.  So the volume
    // is positive if the ccw normal to f points outside the tetrahedron.
    // The final fewer-multiplications form is due to Robert Fraczkiewicz.
    function VolumeSign(f: tFace; p: tVertex): Integer;
    // MakeConeFace makes a new face and two new edges between the
    // edge and the point that are passed to it. It exit(s a pointer to
    // the new face.
    function MakeConeFace(e: tEdge; p: tVertex): tFace;
    // MakeCcw puts the vertices in the face structure in counterclock wise
    // order. We want to store the vertices in the same
    // order as in the visible face.  The third vertex is always p.
    procedure MakeCcw(f: tFace; e: tEdge; p: tVertex);
    // MakeNullEdge creates a new cell and initializes all pointers to nil
    // and sets all flags to off.  It exit(s a pointer to the empty cell.
    function MakeNullEdge: tEdge;
    // MakeNullFace creates a new face structure and initializes all of its
    // flags to nil and sets all the flags to off.  It exit(s a pointer
    // to the empty cell.
    function MakeNullFace: tFace;
    // MakeFace creates a new face structure from three vertices
    // (in ccw order).  It exit(s a pointer to the face.
    function MakeFace(v0, v1, v2: tVertex; f: tFace): tFace;
    // CleanUp goes through each data structure list and clears all
    // flags and NULLs out some pointers.  The order of processing
    // (edges, faces, vertices) is important.
    procedure CleanUp;
    // CleanEdges runs through the edge list and cleans up the structure.
    // If there is a newface then it will put that face in place of the
    // visible face and nil out newface. It also deletes so marked edges.
    procedure CleanEdges;
    // CleanFaces runs through the face list and deletes any face marked visible.
    procedure CleanFaces;
    // CleanVertices runs through the vertex list and deletes the
    // vertices that are marked as processed but are not incident to any
    // undeleted edges.
    procedure CleanVertices;
    // Collinear checks to see if the three points given are collinear,
    // by checking to see if each element of the cross product is zero.
    function Collinear(a, b, c: tVertex): Boolean;
    // Computes the z-coordinate of the vector normal to face f.
    function Normz(f: tFace): Integer;
    procedure PrintPoint(p: tVertex);
    procedure Checks;
    // Consistency runs through the edge list and checks that all
    // adjacent faces have their endpoints in opposite order.
    // This verifies that the vertices are in counterclockwise order.
    procedure Consistency;
    // Convexity checks that the volume between every face and every
    // point is negative.  This shows that each point is inside every face
    // and therefore the hull is convex.
    procedure Convexity;
    // These functions are used whenever the debug flag is set.
    // They print out the entire contents of each data structure.
    procedure PrintOut(v: tVertex);
    procedure PrintVertices;
    procedure PrintEdges;
    procedure PrintFaces;
    procedure LowerFaces;
  end;

{$EndRegion}

implementation

const
  // Define flags
  ONHULL = True;
  REMOVED = True;
  VISIBLE = True;
  PROCESSED = True;
  SAFE = 1000000;    // Range of safe coord values

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

procedure TsvgIO.Print(vertices: tVertex; edges: tEdge; faces: tFace);
var
  // Pointers to vertices, edges, faces.
  v: tVertex ;
  e: tEdge;
  f: tFace;
  Vc, Ec, Fc: Integer;
  nvertices: Integer;
begin
  // Counters for Euler's formula.
  Vc := 0; Ec := 0; Fc := 0;
  nvertices := CalcBounds(vertices);

  // Svg header
  // Format('%%not PS');
  // Format('%%%%BoundingBox: %d %d %d %d', xmin, ymin, xmax, ymax);
  // Format('.00 .00 setlinewidth');
  // Format('%d %d translate', -xmin+100, -ymin+100 );
  // The +72 shifts the figure one inch from the lower left corner

  // Vertices
  v := vertices;
  repeat
    if v.mark then Inc(Vc);
    v := v.next;
  until v = vertices;
  // Format('\n%%%% Vertices:\tV = %d', Vc);
  // Format('%%%% index:\tx\ty\tz');
  repeat
    // printf( '%%%% %5d:\t%d\t%d\t%d', v.vnum, v.v.x, v.v.y, v.v.z );
    // Format('newpath');
    // Format('%d\t%d 2 0 360 arc', v.v.x, v.v.y);
    // Format('closepath stroke\n');
    v := v.next;
  until v = vertices;

  // Faces.
  // visible faces are printed as PS output
  f := faces;
  repeat
    Inc(Fc);
    f := f.next;
  until f = faces;
  // Format('\n%%%% Faces:\tF = %d', Fc );
  // Format('%%%% Visible faces only: ');
  repeat
    // Print face only if it is lower
    if f.lower then
    begin
      Dbp(Format('vnums: %d  %d  %d',
        [f.vertex[0].vnum, f.vertex[1].vnum, f.vertex[2].vnum]));
      svg.Polygon
        .Point(f.vertex[0].v.x, f.vertex[0].v.y)
        .Point(f.vertex[1].v.x, f.vertex[1].v.y)
        .Point(f.vertex[2].v.x, f.vertex[2].v.y);
    end;
    f := f.next;
  until f = faces;

  // prints a list of all faces
  Dbp('List of all faces');
  Dbp('v0 v1 v2 (vertex indices)');
  repeat
    Dbp(Format('%d %d %d',
      [f.vertex[0].vnum, f.vertex[1].vnum, f.vertex[2].vnum]));
    f := f.next;
  until f = faces;

  // Edges.
  e := edges;
  repeat
    Inc(Ec);
    e := e.next;
  until e = edges;
  Dbp(Format('Edges: E = %d', [Ec]));
  // Edges not printed out (but easily added).

  check := True;
  CheckEuler(Vc, Ec, Fc);
end;

procedure TsvgIO.CheckEuler(V, E, F: Integer);
begin
  if check then
    Dbp(Format('Checks: V, E, F = %d %d %d:', [V, E, F]));
  if (V - E + F) <> 2 then
    Dbp('Checks: V - E + F <> 2')
  else if check then
    Dbp('V - E + F = 2');
  if F <> (2 * V - 4) then
    Dbp(Format('Checks: F=%d <> 2 * V - 4=%d; V=%d', [F, 2 * V - 4, V]))
  else if check then
    Dbp('F = 2 * V - 4');
  if 2 * E <> 3 * F then
    Dbp(Format('Checks: 2E=%d <> 3F=%d; E=%d, F=%d', [2 * E, 3 * F, E, F]))
  else if check then
    Dbp('2 * E = 3 * F');
end;

function TsvgIO.CalcBounds(vertices: tVertex): Integer;
var
  v: tVertex;
begin
  Result := 0;
  v := vertices;
  xmin := v.v.x; xmax := v.v.x;
  ymin := v.v.y; ymax := v.v.y;
  repeat
    if v.v.x > xmax then
      xmax := v.v.x
    else if v.v.x < xmin then
      xmin := v.v.x;
    if v.v.y > ymax then
      ymax := v.v.y
    else if v.v.y < ymin then
      ymin := v.v.y;
    v := v.next;
    Inc(Result);
  until v = vertices;
end;

procedure TsvgIO.Dbp;
begin
  Log.Add('');
end;

procedure TsvgIO.Dbp(const line: string);
begin
  Log.Add(line);
end;

procedure TsvgIO.Dbp(const fs: string; const args: array of const);
begin
  Log.Add(Format(fs, args));
end;

{$EndRegion}

{$Region 'TDelaunayTri'}

procedure TDelaunayTri.Build(const filename: string);
begin
  ReadVertices(filename);
  DoubleTriangle;
  ConstructHull;
  LowerFaces;
  io.Print(vertices, edges, faces);
end;

procedure TDelaunayTri.Add(var head: tVertex; p: tVertex);
begin
  if head <> nil then
  begin
    p.next := head;
    p.prev := head.prev;
    head.prev := p;
    p.prev.next := p;
  end
  else
  begin
    head := p;
    head.next := p;
    head.prev := p;
  end;
end;

procedure TDelaunayTri.Delete(var head: tVertex; p: tVertex);
begin
  if head = head.next then
    head := nil
  else if p = head then
    head := head.next;
  p.next.prev := p.prev;
  p.prev.next := p.next;
  Dispose(p);
end;

function TDelaunayTri.MakeNullVertex: tVertex;
var
  v: tVertex;
begin
  New(v);
  v.duplicate := nil;
  v.onhull := not ONHULL;
  v.mark := not PROCESSED;
  Add(vertices, v);
  Result := v;
end;

function TDelaunayTri.ReadVertices(const filename: string): Integer;
var
  v: tVertex;
  i, x, y, z, vnum: Integer;
  str: TStrings;
  line: string;
  sa: TArray<string>;
begin
  vnum := 0;
  str := TStringList.Create;
  try
    str.LoadFromFile(filename);
    for i := 0 to str.Count - 1 do
    begin
      line := str.Strings[i];
      sa := line.Split([Chr(9)]);
      if sa = nil then break;
      x := Integer.Parse(sa[0]);
      y := Integer.Parse(sa[1]);
      z := x * x + y * y;
      v := MakeNullVertex;
      v.v.x := x;
      v.v.y := y;
      v.v.z := z;
      v.vnum := vnum;
      Inc(vnum);
      if (Abs(x) > SAFE) or (Abs(y) > SAFE) or (Abs(z) > SAFE) then
      begin
        PrintPoint(v);
        raise Exception.Create('Too large coordinate of vertex');
      end;
    end;
    if vnum < 3 then
      raise Exception.CreateFmt('ReadVertices: nvertices=%d < 3', [vnum]);
  finally
    str.Free;
  end;
  Result := vnum;
end;

procedure TDelaunayTri.SubVec(const a, b: T3i; var c: T3i);
begin
  c.x := a.x - b.x;
  c.y := a.y - b.y;
  c.z := a.z - b.z;
end;

procedure TDelaunayTri.DoubleTriangle;
var
  v0, v1, v2, v3, t: tVertex;
  f0, f1: tFace;
  e0, e1, e2, s: tEdge;
  vol: Integer;
begin
  f1 := nil;
  (* Find 3 non-Collinear points. *)
  v0 := vertices;
  while Collinear(v0, v0.next, v0.next.next) do
  begin
    v0 := v0.next;
    if v0 = vertices then
      raise Exception.Create('DoubleTriangle:  All points are Collinear!');
  end;
  v1 := v0.next;
  v2 := v1.next;

  // Mark the vertices as processed.
  v0.mark := PROCESSED;
  v1.mark := PROCESSED;
  v2.mark := PROCESSED;

  // Create the two 'twin' faces.
  f0 := MakeFace( v0, v1, v2, f1 );
  f1 := MakeFace( v2, v1, v0, f0 );

  // Link adjacent face fields.
  f0.edge[0].adjface[1] := f1;
  f0.edge[1].adjface[1] := f1;
  f0.edge[2].adjface[1] := f1;
  f1.edge[0].adjface[1] := f0;
  f1.edge[1].adjface[1] := f0;
  f1.edge[2].adjface[1] := f0;

  // Find a fourth, non-coplanar point to form tetrahedron.
  v3 := v2.next;
  vol := VolumeSign(f0, v3);
  while IsZero(vol) do
  begin
    v3 := v3.next;
    if v3 = v0 then
      raise Exception.Create('DoubleTriangle:  All points are coplanar!');
    vol := VolumeSign(f0, v3);
  end;

  // Insure that v3 will be the first added.
  vertices := v3;
  if io.debug then
  begin
    io.Dbp('DoubleTriangle: finished. Head repositioned at v3.');
    PrintOut(vertices);
  end;
end;

procedure TDelaunayTri.ConstructHull;
var
  v, vnext: tVertex ;
  vol: Integer;
  changed: Boolean;  // T if addition changes hull; not used.
begin
  v := vertices;
  repeat
    vnext := v.next;
    if not v.mark then
    begin
      v.mark := PROCESSED;
      changed := AddOne(v);
      CleanUp;
      if io.check then
      begin
        io.Dbp(Format('ConstructHull: After Add of %d & Cleanup:', [v.vnum]));
        Checks;
      end;
      if io.debug then PrintOut(v);
    end;
    v := vnext;
  until v = vertices;
end;

function TDelaunayTri.AddOne(p: tVertex): Boolean;
var
  f: tFace;
  e, temp: tEdge;
  vol: Integer;
  vis: Boolean;
begin
  vis := False;
  if io.debug then
  begin
    io.Dbp('AddOne: starting to add v%d.', [p.vnum]);
    PrintOut(vertices);
  end;

  // Mark faces visible from p.
  f := faces;
  repeat
    vol := VolumeSign(f, p);
    if io.debug then
      io.Dbp('faddr: %6x   paddr: %6x   Vol = %d', [f, p, vol]);
    if vol < 0 then
    begin
      f.visible := VISIBLE;
      vis := True;
    end;
    f := f.next;
  until f = faces;

  // If no faces are visible from p, then p is inside the hull.
  if not vis then
  begin
    p.onhull := not ONHULL;
    exit(False);
  end;

  // Mark edges in interior of visible region for deletion.
  // Erect a newface based on each border edge.
  e := edges;
  repeat
    temp := e.next;
    if e.adjface[0].visible and e.adjface[1].visible then
      // e interior: mark for deletion.
      e.delete := REMOVED
    else if e.adjface[0].visible or e.adjface[1].visible then
      // e border: make a new face.
      e.newface := MakeConeFace(e, p);
    e := temp;
  until e = edges;
  Result := True;
end;

function TDelaunayTri.VolumeSign(f: tFace; p: tVertex): Integer;
var
  vol: Double;
  voli: Integer;
  ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz: Double;
  bxdx, bydy, bzdz, cxdx, cydy, czdz: Double;
begin
  ax := f.vertex[0].v.x;
  ay := f.vertex[0].v.y;
  az := f.vertex[0].v.z;
  bx := f.vertex[1].v.x;
  by := f.vertex[1].v.y;
  bz := f.vertex[1].v.z;
  cx := f.vertex[2].v.x;
  cy := f.vertex[2].v.y;
  cz := f.vertex[2].v.z;
  dx := p.v.x;
  dy := p.v.y;
  dz := p.v.z;

  bxdx := bx - dx;
  bydy := by - dy;
  bzdz := bz - dz;
  cxdx := cx - dx;
  cydy := cy - dy;
  czdz := cz - dz;
  vol := (az - dz) * (bxdx * cydy - bydy * cxdx)
       + (ay - dy) * (bzdz * cxdx - bxdx * czdz)
       + (ax - dx) * (bydy * czdz - bzdz * cydy);
  if io.debug then
    io.Dbp('Face=%6x; Vertex=%d: vol(Integer) = %d, vol(Double) = %lf',
      [f, p.vnum, voli, vol]);

  // The volume should be an integer.
  if vol > 0.5 then
    Result := 1
  else if vol < -0.5 then
    Result := -1
  else
    Result := 0;
end;

function TDelaunayTri.Volumei(f: tFace; p: tVertex): Integer;
var
  i, vol: Integer;
  ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz: Integer;
  bxdx, bydy, bzdz, cxdx, cydy, czdz: Integer;
  vold: Double;
begin
  ax := f.vertex[0].v.x;
  ay := f.vertex[0].v.y;
  az := f.vertex[0].v.z;
  bx := f.vertex[1].v.x;
  by := f.vertex[1].v.y;
  bz := f.vertex[1].v.z;
  cx := f.vertex[2].v.x;
  cy := f.vertex[2].v.y;
  cz := f.vertex[2].v.z;
  dx := p.v.x;
  dy := p.v.y;
  dz := p.v.z;

  bxdx := bx - dx;
  bydy := by - dy;
  bzdz := bz - dz;
  cxdx := cx - dx;
  cydy := cy - dy;
  czdz := cz - dz;
  vol := (az - dz) * (bxdx * cydy - bydy * cxdx)
       + (ay - dy) * (bzdz * cxdx - bxdx * czdz)
       + (ax - dx) * (bydy * czdz - bzdz * cydy);

  Result := vol;
end;

function TDelaunayTri.Volumed(f: tFace; p: tVertex): Double;
var
  vol, ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz: Double;
  bxdx, bydy, bzdz, cxdx, cydy, czdz: Double;
begin
  ax := f.vertex[0].v.x;
  ay := f.vertex[0].v.y;
  az := f.vertex[0].v.z;
  bx := f.vertex[1].v.x;
  by := f.vertex[1].v.y;
  bz := f.vertex[1].v.z;
  cx := f.vertex[2].v.x;
  cy := f.vertex[2].v.y;
  cz := f.vertex[2].v.z;
  dx := p.v.x;
  dy := p.v.y;
  dz := p.v.z;

  bxdx := bx - dx;
  bydy := by - dy;
  bzdz := bz - dz;
  cxdx := cx - dx;
  cydy := cy - dy;
  czdz := cz - dz;
  vol := (az - dz) * (bxdx * cydy - bydy * cxdx)
       + (ay - dy) * (bzdz * cxdx - bxdx * czdz)
       + (ax - dx) * (bydy * czdz - bzdz * cydy);

  Result := vol;
end;

function TDelaunayTri.MakeConeFace(e: tEdge; p: tVertex): tFace;
var
  i, j: Integer;
  new_edge: array [0..1] of tEdge;
  new_face: tFace;
begin
  // Make two new edges (if don't already exist).
  for i := 0 to 1 do
  begin
    new_edge[i] := e.endpts[i].duplicate;
    // If the edge exists, copy it into new_edge.
    if new_edge[i] = nil then
    begin
      // Otherwise (duplicate is nil), MakeNullEdge.
      new_edge[i] := MakeNullEdge;
      new_edge[i].endpts[0] := e.endpts[i];
      new_edge[i].endpts[1] := p;
      e.endpts[i].duplicate := new_edge[i];
    end;
  end;

  // Make the new face.
  new_face := MakeNullFace();
  new_face.edge[0] := e;
  new_face.edge[1] := new_edge[0];
  new_face.edge[2] := new_edge[1];
  MakeCcw(new_face, e, p);

  // Set the adjacent face pointers.
  for i := 0 to 1 do
    for j := 0 to 1 do
      // Only one nil link should be set to new_face.
      if new_edge[i].adjface[j] = nil then
      begin
        new_edge[i].adjface[j] := new_face;
        break;
      end;

  Result := new_face;
end;

procedure TDelaunayTri.MakeCcw(f: tFace; e: tEdge; p: tVertex);
begin
//   tFace  fv;   (* The visible face adjacent to e *)
//   Integer    i;    (* Index of e.endpoint[0] in fv. *)
//   tEdge  s;  (* Temporary, for swapping *)
//
//   if  ( e.adjface[0].visible )
//        fv = e.adjface[0];
//   else fv = e.adjface[1];
//
//   (* Set vertex[0] & [1] of f to have the same orientation
//      as do the corresponding vertices of fv. *)
//   for ( i=0; fv.vertex[i] <> e.endpts[0]; ++i )
//      ;
//   (* Orient f the same as fv. *)
//   if ( fv.vertex[ (i+1) % 3 ] <> e.endpts[1] ) begin
//      f.vertex[0] = e.endpts[1];
//      f.vertex[1] = e.endpts[0];
//   end;
//   else begin
//      f.vertex[0] = e.endpts[0];
//      f.vertex[1] = e.endpts[1];
//      SWAP( s, f.edge[1], f.edge[2] );
//   end;
//   (* This swap is tricky. e is edge[0]. edge[1] is based on endpt[0],
//      edge[2] on endpt[1].  So if e is oriented 'forwards,' we
//      need to move edge[1] to follow [0], because it precedes. *)
//
//   f.vertex[2] = p;
end;

procedure TDelaunayTri.Checks;
var
  v: tVertex;
  e: tEdge;
  f: tFace;
  Vc, Ec, Fc: Integer;
begin
  Vc := 0; Ec := 0; Fc := 0;
  Consistency;
  Convexity;
  if v = vertices then
    repeat
      if v.mark then Inc(Vc);
      v := v.next;
    until v = vertices;
  if e = edges then
    repeat
      Inc(Ec);
      e := e.next;
      until e = edges;
  if f = faces then
    repeat
      Inc(Fc);
      f := f.next;
    until f = faces;
  io.CheckEuler(Vc, Ec, Fc);
end;

procedure TDelaunayTri.CleanEdges;
begin
//   tEdge  e;  (* Primary index into edge list. *)
//   tEdge  t;  (* Temporary edge pointer. *)
//
//   (* Integrate the newface's into the data structure. *)
//   (* Check every edge. *)
//   e = edges;
//   repeat
//      if ( e.newface ) begin
//   if ( e.adjface[0].visible )
//      e.adjface[0] = e.newface;
//   else  e.adjface[1] = e.newface;
//   e.newface = nil;
//      end;
//      e = e.next;
//   until e <> edges );
//
//   (* Delete any edges marked for deletion. *)
//   while ( edges and edges.delete ) begin
//      e = edges;
//      DELETE( edges, e );
//   end;
//   e = edges.next;
//   repeat
//      if ( e.delete ) begin
//   t = e;
//   e = e.next;
//   DELETE( edges, t );
//      end;
//      else e = e.next;
//   until e <> edges );
end;

procedure TDelaunayTri.CleanFaces;
begin
//   tFace  f;  (* Primary pointer into face list. *)
//   tFace  t;  (* Temporary pointer, for deleting. *)
//
//
//   while ( faces and faces.visible ) begin
//      f = faces;
//      DELETE( faces, f );
//   end;
//   f = faces.next;
//   repeat
//      if ( f.visible ) begin
//   t = f;
//   f = f.next;
//   DELETE( faces, t );
//      end;
//      else f = f.next;
//   until f <> faces );
end;

procedure TDelaunayTri.CleanUp;
begin
  CleanEdges();
  CleanFaces();
  CleanVertices();
end;

procedure TDelaunayTri.CleanVertices;
begin
//   tEdge    e;
//   tVertex  v, t;
//
//   (* Mark all vertices incident to some undeleted edge as on the hull. *)
//   e = edges;
//   repeat
//      e.endpts[0].onhull = e.endpts[1].onhull = ONHULL;
//      e = e.next;
//   end; while (e <> edges);
//
//   (* Delete all vertices that have been processed but
//      are not on the hull. *)
//   while ( vertices and vertices.mark and not vertices.onhull ) begin
//      v = vertices;
//      DELETE( vertices, v );
//   end;
//   v = vertices.next;
//   repeat
//      if ( v.mark and not v.onhull ) begin
//   t = v;
//   v = v.next;
//   DELETE( vertices, t )
//      end;
//      else v = v.next;
//   until v = vertices;
//
//   (* Reset flags. *)
//   v = vertices;
//   repeat
//      v.duplicate = nil;
//      v.onhull = not ONHULL;
//      v = v.next;
//   until v = vertices;
end;

function TDelaunayTri.Collinear(a, b, c: tVertex): Boolean;
begin
//   exit(
//         ( c.v.z - a.v.z ) * ( b.v.y - a.v.y ) -
//         ( b.v.z - a.v.z ) * ( c.v.y - a.v.y ) == 0
//      and ( b.v.z - a.v.z ) * ( c.v.x - a.v.x ) -
//         ( b.v.x - a.v.x ) * ( c.v.z - a.v.z ) == 0
//      and ( b.v.x - a.v.x ) * ( c.v.y - a.v.y ) -
//         ( b.v.y - a.v.y ) * ( c.v.x - a.v.x ) == 0  ;
end;

procedure TDelaunayTri.Consistency;
begin
//   register tEdge  e;
//   register Integer    i, j;
//
//   e = edges;
//
//   repeat
//      (* find index of endpoint[0] in adjacent face[0] *)
//      for ( i = 0; e.adjface[0].vertex[i] <> e.endpts[0]; ++i )
//   ;
//
//      (* find index of endpoint[0] in adjacent face[1] *)
//      for ( j = 0; e.adjface[1].vertex[j] <> e.endpts[0]; ++j )
//   ;
//
//      (* check if the endpoints occur in opposite order *)
//      if ( not ( e.adjface[0].vertex[ (i+1) % 3 ] ==
//        e.adjface[1].vertex[ (j+2) % 3 ] or
//        e.adjface[0].vertex[ (i+2) % 3 ] ==
//        e.adjface[1].vertex[ (j+1) % 3 ] )  )
//   break;
//      e = e.next;
//
//   until e <> edges );
//
//   if ( e <> edges )
//      io.Dbp( stderr, 'Checks: edges are NOT consistent.');
//   else
//      io.Dbp( stderr, 'Checks: edges consistent.');
end;

procedure TDelaunayTri.Convexity;
begin
//   register tFace    f;
//   register tVertex  v;
//   Integer               vol;
//
//   f = faces;
//
//   repeat
//      v = vertices;
//      repeat
//   if ( v.mark ) begin
//      vol = VolumeSign( f, v );
//      if ( vol < 0 )
//         break;
//   end;
//   v = v.next;
//      until v = vertices;
//
//      f = f.next;
//
//   until f <> faces );
//
//   if ( f <> faces )
//      io.Dbp( stderr, 'Checks: NOT convex.');
//   else if ( check )
//      io.Dbp( stderr, 'Checks: convex.');
end;

procedure TDelaunayTri.LowerFaces;
var
  f: tFace;
  Flower, z: Integer; // Total number of lower faces.
begin
  f := faces;
  Flower := 0;
  repeat
    z := Normz(f);
    if z < 0 then
    begin
      Inc(Flower);
      f.lower := True;
      io.Dbp(Format('z=%10d; lower face indices: %d, %d, %d',
        [z, f.vertex[0].vnum, f.vertex[1].vnum, f.vertex[2].vnum]));
    end
    else
      f.lower := False;
    f := f.next;
   until f = faces;
   io.Dbp(Format('A total of %d lower faces identified.', [Flower]));
end;

function TDelaunayTri.MakeFace(v0, v1, v2: tVertex; f: tFace): tFace;
begin
//   tFace  f;
//   tEdge  e0, e1, e2;
//
//   (* Create edges of the initial triangle. *)
//   if( not fold ) begin
//     e0 = MakeNullEdge();
//     e1 = MakeNullEdge();
//     e2 = MakeNullEdge();
//   end;
//   else begin (* Copy from fold, in reverse order. *)
//     e0 = fold.edge[2];
//     e1 = fold.edge[1];
//     e2 = fold.edge[0];
//   end;
//   e0.endpts[0] = v0;              e0.endpts[1] = v1;
//   e1.endpts[0] = v1;              e1.endpts[1] = v2;
//   e2.endpts[0] = v2;              e2.endpts[1] = v0;
//
//   (* Create face for triangle. *)
//   f = MakeNullFace();
//   f.edge[0]   = e0;  f.edge[1]   = e1; f.edge[2]   = e2;
//   f.vertex[0] = v0;  f.vertex[1] = v1; f.vertex[2] = v2;
//
//   (* Link edges to face. *)
//   e0.adjface[0] = e1.adjface[0] = e2.adjface[0] = f;
//
//   exit( f;
end;

function TDelaunayTri.MakeNullEdge: tEdge;
begin
//   tEdge  e;
//   NEW( e, tsEdge );
//   e.adjface[0] = e.adjface[1] = e.newface = nil;
//   e.endpts[0] = e.endpts[1] = nil;
//   e.delete = not REMOVED;
//   ADD( edges, e );
//   exit( e;
end;

function TDelaunayTri.MakeNullFace: tFace;
begin
//   tFace  f;
//   Integer    i;
//
//   NEW( f, tsFace);
//   for ( i=0; i < 3; ++i ) begin
//      f.edge[i] = nil;
//      f.vertex[i] = nil;
//   end;
//   f.visible = not VISIBLE;
//   ADD( faces, f );
//   exit( f;
end;

function TDelaunayTri.Normz(f: tFace): Integer;
begin
//   tVertex a, b, c;
//   (*Double ba0, ca1, ba1, ca0,z;*)
//
//   a = f.vertex[0];
//   b = f.vertex[1];
//   c = f.vertex[2];
//
//(*
//   ba0 = ( b.v.x - a.v.x );
//   ca1 = ( c.v.y - a.v.y );
//   ba1 = ( b.v.y - a.v.y );
//   ca0 = ( c.v.x - a.v.x );
//
//   z = ba0 * ca1 - ba1 * ca0;
//   Format('Normz = %lf=%g', z,z);
//   if      ( z > 0.0 )  exit(  1;
//   else if ( z < 0.0 )  exit( -1;
//   else                 exit(  0;
//*)
//   exit(
//      ( b.v.x - a.v.x ) * ( c.v.y - a.v.y ) -
//      ( b.v.y - a.v.y ) * ( c.v.x - a.v.x );
end;

procedure TDelaunayTri.PrintEdges;
var
  temp: tEdge;
  i: Integer;
begin
  temp := edges;
  io.Dbp('Edge List');
  if edges <> nil then
  repeat
    io.Dbp(Format('  addr: %6x'#9, [edges]));
    io.Dbp('adj: ');
    for i := 0 to 1 do
      io.Dbp(Format('%6x', [edges.adjface[i]]));
    io.Dbp('  endpts:');
    for i := 0 to 1 do
      io.Dbp(Format('%4d', [edges.endpts[i].vnum]));
    io.Dbp(Format('  del:%3d', [edges.delete]));
    edges := edges.next;
  until edges = temp;
end;

procedure TDelaunayTri.PrintFaces;
var
  temp: tFace;
  i: Integer;
begin
  temp := faces;
  io.Dbp('Face List');
  if faces <> nil then
  repeat
    io.Dbp(Format('  addr: %6x'#9, [faces]));
    io.Dbp('  edges:');
    for i := 0 to 2 do
      io.Dbp(Format('%6x', [faces.edge[i]]));
    io.Dbp('  vert:');
    for i := 0 to 2 do
      io.Dbp(Format('%4d', [faces.vertex[i].vnum]));
    io.Dbp(Format('  vis: %d', [faces.visible]));
    faces := faces.next;
  until faces = temp;
end;

procedure TDelaunayTri.PrintOut(v: tVertex);
begin
  io.Dbp(Format('Head vertex %d = %6x :', [v.vnum, v]));
  PrintVertices;
  PrintEdges;
  PrintFaces;
end;

procedure TDelaunayTri.PrintPoint(p: tVertex);
begin
  io.Dbp(Format(#9'%d', [p.v.x, p.v.y, p.v.z]));
  io.Dbp('');
end;

procedure TDelaunayTri.PrintVertices;
var
  temp: tVertex;
  i: Integer;
begin
  io.Dbp('Vertex List');
  if vertices <> nil then
  repeat
    io.Dbp(Format('  addr %6x\t', [vertices]));
    io.Dbp(Format('  vnum %4d', [vertices.vnum]));
    io.Dbp(Format('   (%6d, %6d, %6d)',
      [vertices.v.x, vertices.v.y, vertices.v.z]));
    io.Dbp(Format('   active:%3d', [vertices.onhull]));
    io.Dbp(Format('   dup:%5x', [vertices.duplicate]));
    io.Dbp(Format('   mark:%2d', [vertices.mark]));
    vertices := vertices.next;
  until vertices = temp;
end;

{$EndRegion}

end.

