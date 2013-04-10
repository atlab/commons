function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    common.getSchema;
    psy.getSchema;
    tp.getSchema;
    schemaObject = dj.Schema(dj.conn, 'pop', 'dimitri_population');
end

obj = schemaObject;
end