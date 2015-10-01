function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'l1seq', 'cathryn_l1seq');
end
obj = schemaObject;
end
