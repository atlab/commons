function tf = isPyramidal(s)
% s is a structure with a field "cell_type"
% checks to see if s.cell_type is 'Pyramidal'
% returns 1 if true, 0 if false

tf = strncmp(s.cell_type,'Pyramidal',9);
end
