function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'virus', 'common_virus');
end
obj = schemaObject;
end
