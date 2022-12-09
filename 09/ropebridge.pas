{
  Copyright (c) 2022 Frank Fischer <frank-fischer@shadow-soft.de>

  This program is free software: you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see  <http://www.gnu.org/licenses/>
}

{$mode objfpc}
{$H+}

program RopeBridge;

uses math, generics.collections;

type
   Pos = record
      x, y: Integer;
   end;

   TPosSet = specialize THashSet<Pos>;

var
   f: Textfile;
   rope: array[1..10] of Pos;
   dir: char;
   step: Integer;
   d: Pos;
   i, j: Integer;
   poss2, poss10: TPosSet;
begin
   if ParamCount < 1 then begin
      writeln(stderr, 'Missing filename');
      halt(1);
   end;
   Assign(f, ParamStr(1));
   Reset(f);

   for i := Low(rope) to High(rope) do begin
      rope[i].x := 0;
      rope[i].y := 0;
   end;

   poss2 := TPosSet.Create;
   poss10 := TPosSet.Create;
   while not Eof(f) do begin
      Readln(f, dir, step);
      case dir of
         'R': begin d.x := 1; d.y := 0; end;
         'L': begin d.x :=-1; d.y := 0; end;
         'U': begin d.x := 0; d.y :=+1; end;
         'D': begin d.x := 0; d.y :=-1; end;
         else begin
            writeln(stderr, 'Invalid step direction');
            halt(1);
         end;
      end;

      for j := 1 to step do begin
         rope[1].x += d.x;
         rope[1].y += d.y;
         for i := 2 to High(rope) do begin
            if (abs(rope[i-1].x - rope[i].x) > 1) or (abs(rope[i-1].y - rope[i].y) > 1) then begin
               rope[i].x += sign(rope[i-1].x - rope[i].x);
               rope[i].y += sign(rope[i-1].y - rope[i].y);
            end;
         end;
         poss2.Add(rope[2]);
         poss10.Add(rope[10]);
      end;
   end;

   writeln('Number of  2-tail fields: ', poss2.Count);
   writeln('Number of 10-tail fields: ', poss10.Count);

   poss2.Free;
   poss10.Free;

   Close(f);
end.
