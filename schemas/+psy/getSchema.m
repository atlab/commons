function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    common.getSchema;
    schemaObject = dj.Schema(dj.conn, 'psy', 'common_psy');
    tp.getSchema;
end

obj = schemaObject;
end