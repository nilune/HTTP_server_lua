#!/usr/bin/env tarantool

-- подключаемся к БД
box.cfg {
    listen = 3301
}
box.once("bootstrap", function()
    box.schema.space.create('tester')
    box.space.tester:format({
        {name = 'key', type = 'string'},
        {name = 'value', type = 'string'}
    })
    box.space.tester:create_index('primary',
        { type = 'hash', parts = {'key'}})
end)

-- require('console').start()

json=require('json')

-- настраиваем сервер
local function handler_post(self)
    local body = self:json()
    local key, value = body['key'], json.encode(body['value'])
    box.space.tester:insert{key, value}
    return self:render{ text = 'Received '..key..' with '..value }
end

local function handler_get(self)
    local key = self:stash('id')
    local element = box.space.tester:select(key)[1]
    if element == nil then
        return self:render{ text = 'Not element' }
    end
    return self:render{ json = json.decode(element[2]) }
end

local function handler_delete(self)
    local key = self:stash('id')
    local element = box.space.tester:delete(key)
    if element == nil then
        return self:render{ text = 'Not element' }
    end
    return self:render{ text = 'Was deleted' }
end

local function handler_put(self)
    local body = self:json()
    local key, value = self:stash('id'), json.encode(body['value'])
    box.space.tester:update({ key }, {{ '=', 2, value }})
    return self:render{ text = 'Received '..key..' with '..value }
end


local server = require('http.server').new(nil, 8080)
server:route({ path = 'kv/', method = 'POST' }, handler_post)
server:route({ path = 'kv/:id', method = 'GET' }, handler_get)
server:route({ path = 'kv/:id', method = 'DELETE' }, handler_delete)
server:route({ path = 'kv/:id', method = 'PUT' }, handler_put)
server:start()

-- Доделать функции, проверки, логирование, 
-- у функции возвращать правильные коды ошибки