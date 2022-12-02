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

program Calories;

uses sysutils, generics.collections;

var
   f: Textfile;
   line: String;
   totals: array of Integer = ();
   sum, n, i: Integer;
begin
   Assign(f, ParamStr(1));
   Reset(f);
   sum := 0;
   n := 0;
   while not Eof(f) do begin
      readln(f, line);
      if Eof(f) or (line = '') then begin
         if n + 1 >= Length(totals) then SetLength(totals, 1 + 2 * Length(totals));
         totals[n] := sum;
         inc(n);
         sum := 0;
      end else
         sum += StrToInt(line);
   end;
   Close(f);

   SetLength(totals, n);
   specialize TArrayHelper<Integer>.Sort(totals);

   writeln('max elf total: ', totals[n-1]);
   sum := 0;
   for i := n - 3 to n - 1 do sum += totals[i];
   writeln('top-3 total  : ', sum);
end.
