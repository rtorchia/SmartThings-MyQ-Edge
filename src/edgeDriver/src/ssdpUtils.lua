local socket = require('socket')
local config = require('config')
local log = require('log')

local ssdp_handler = {}

function ssdp_handler.find_device()
    -- UDP socket initialization
    local upnp = socket.udp()
    upnp:setsockname('*', 0)
    upnp:setoption('broadcast', true)
    upnp:settimeout(config.MC_TIMEOUT)

    -- Broadcast search
    log.info('===== SCANNING NETWORK...')
    upnp:sendto(config.MSEARCH, config.MC_ADDRESS, config.MC_PORT)

    local res = upnp:receive()

    -- close udp socket
    upnp:close()

    if res ~= nil then
      local parsedResponse = parse_ssdp(res);
      if parsedResponse.location and string.find(parsedResponse.usn, "MyQBetaDoor") then
        log.info('===== MyQ Server FOUND IN NETWORK AT: ' ..parsedResponse.location)
        return parsedResponse
      else
        log.info('===== Ignoring response from: ' ..parsedResponse.location)
        return nil
      end
    end
    --log.error('===== No MyQ Bridge found in network')
    return nil
end


function parse_ssdp(data)
    local res = {}
    res.status = data:sub(0, data:find('\r\n'))
    for k, v in data:gmatch('([%w-]+): ([%a+-: /=]+)') do
      res[k:lower()] = v
    end
    return res
  end

  return ssdp_handler