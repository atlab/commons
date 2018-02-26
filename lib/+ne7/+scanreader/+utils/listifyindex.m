function indexAsList = listifyindex(index, dimSize)
%LISTIFYINDEX Generates the list representation of an index for the given dim_size.
if strcmp(index, ':')
    indexAsList = 1:dimSize;
else
    indexAsList = index;
end