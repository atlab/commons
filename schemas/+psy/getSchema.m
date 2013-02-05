function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    common.getSchema;
    schemaObject = dj.Schema(dj.conn, 'psy', 'common_psy');
end

obj = schemaObject;
end