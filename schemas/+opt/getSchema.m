function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    common.getSchema;
    psy.getSchema;
    schemaObject = dj.Schema(dj.conn, 'opt', 'common_optical');
end

obj = schemaObject;
end