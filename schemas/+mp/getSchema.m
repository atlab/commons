function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    common.getSchema;
    schemaObject = dj.Schema(dj.conn, 'mp', 'common_multipatch');
end

obj = schemaObject;
end
