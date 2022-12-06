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

program TuningTrouble;

var
   f: Textfile;
   line: String;
   cnts: array['a'..'z'] of Integer;
   nmulti, i, k: Integer;
   c: Char;
begin
   if ParamCount <> 1 then begin
      writeln(stderr, 'Missing filename');
      halt(1);
   end;

   Assign(f, ParamStr(1));
   Reset(f);
   while not Eof(f) do begin
      Readln(f, line);

      for k in [4, 14] do begin
         for c := Low(cnts) to High(cnts) do cnts[c] := 0;
         nmulti := 0;
         for i := Low(line) to High(line) do begin
            if i > k then begin // strings start at 1
               dec(cnts[line[i-k]]);
               if cnts[line[i-k]] = 1 then dec(nmulti);
            end;
            inc(cnts[line[i]]);
            if cnts[line[i]] = 2 then inc(nmulti);
            if (i >= k) and (nmulti = 0) then begin
               write(k, ': ', i, '  ');
               break;
            end
         end;
      end;
      writeln;
   end;
end.
