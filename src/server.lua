#!/usr/bin/env tarantool

-- Настраиваем подключение к tarantool
box.cfg {
    listen = 3301,
    -- background = true, -- for production
    log = '../logs/LogFileDB.log',
    pid_file = '../logs/PidFileDB.pid'
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

-- require('console').start() -- for debug

-- Настраиваем http-сервер
json = require('json')

local function check_body(self, method)
    -- Функция для проверки правильно ввода json
    local key, value, status, body
    status, body = pcall(function() return self:json() end)
    if not status then return false end

    status, value = pcall(function() return json.encode(body['value']) end)
    if not status or body['value'] == nil then return false end

    if method then 
        key = body['key']
        if key == nil then return false end
        return true, value, tostring(key)
    end
    return true, value
end

local function error_resp(req, number)
    -- Функция для возврать сообщений с ошибками
    local resp = req:render({ text = 'Bad request' })
    resp.status = number
    return resp
end

local function handler_create(self)
    -- Функция, отвечающая на POST
    local status, value, key = check_body(self, true)
    if not status then return error_resp(self, 400) end
    if box.space.tester:select(key)[1] ~= nil then 
        return error_resp(self, 409)
    end

    if pcall(function(a, b) box.space.tester:insert{a, b} end, key, value) then
        return self:render{ text = 'Received '..key..' with '..value }
    end
    return error_resp(self, 400)
end

local function handler_get(self)
    -- Функция, отвечающая на GET
    local key = self:stash('id')
    local element = box.space.tester:select(key)[1]
    if element == nil then
        return error_resp(self, 404)
    end
    return self:render{ json = json.decode(element[2]) }
end

local function handler_delete(self)
    -- Функция, отвечающая на DELETE
    local key = self:stash('id')
    local element = box.space.tester:delete(key)
    if element == nil then
        return error_resp(self, 404)
    end
    return self:render({ text = 'Successfully deleted; key: '..key..
        '; value '..element[2]
    })
end

local function handler_update(self)
    -- Функция, отвечающая на PUT
    local key = self:stash('id')
    local status, value = check_body(self, false)
    if not status then return error_resp(self, 400) end

    local element = box.space.tester:update({ key }, {{ '=', 2, value }})
    if element == nil then
        return error_resp(self, 404)
    end
    return self:render({ text = 'Successfully updated; key: '..key..
        '; new value '..value
    })
end

local function get_all(self)
    -- Функция, возвращающаяся все объекты
    return self:render{ json = box.space.tester:select() }
end

local server = require('http.server').new(nil, 8080)
server:route({ path = 'kv/', method = 'POST' }, handler_create)
server:route({ path = 'kv/:id', method = 'GET' }, handler_get)
server:route({ path = 'kv/:id', method = 'DELETE' }, handler_delete)
server:route({ path = 'kv/:id', method = 'PUT' }, handler_update)
server:route({ path = 'all/', method = 'GET' }, get_all)
server:start()
