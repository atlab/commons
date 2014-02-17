function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    common.getSchema;
    psy.getSchema;
    patch.getSchema;
    schemaObject = dj.Schema(dj.conn, 'reso', 'common_resonant');
    bs.getSchema;
end

obj = schemaObject;
end