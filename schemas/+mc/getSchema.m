function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'mc', 'common_microcolumns');
end

obj = schemaObject;
end