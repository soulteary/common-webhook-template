local key = "your_sec_key_here"
local owner = "soulteary"
local script = "/usr/local/openresty/nginx/lua/common/cmd.sh"
local log = "/var/log/nginx-lua-github-trigger.log"
-- 默认使用 404 防止接口被爬虫抓到
local exitCode = 404


local headers = ngx.req.get_headers()
local signature = headers["X-Hub-Signature"]

if signature == nil then return ngx.exit(exitCode) end

ngx.req.read_body()

local t = {};
for k, v in string.gmatch(signature, "(%w+)=(%w+)") do t[k] = v end

local String = require "resty.string"
local body = ngx.req.get_body_data();
local digest = ngx.hmac_sha1(key, body)

if not String.to_hex(digest) == t["sha1"] then return ngx.exit(exitCode) end

local JSON = require "cjson"
local data = JSON.decode(body)

if data.pusher.name == owner and data.pusher.name == data.repository.owner.name then
    local event = headers["X-GitHub-Event"];

    if event == "push" then
        ngx.say("[" .. owner .. "] update code")
        os.execute("bash " .. script .. " " .. event .. " >> " .. log)
        ngx.exit(200)
    end

    ngx.say("ignore event: " .. owner .. "," .. event)
    ngx.exit(100)
else
    ngx.say("ignore owner not equl: " .. owner)
    ngx.exit(100)
end;
