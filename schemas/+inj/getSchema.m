function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'inj', 'common_injections');
end
obj = schemaObject;
end
