-- Ajouter config pour steam/licence mysql
-- Corriger bug chat

------------------------
-- Variables and Init --
------------------------



-- From config 

local ownerEmail = Config.email
local kickReason = Config.lang[Config.langInfo].kickVpn
local url = Config.webhooks

-- Misc related

local kickThreshold = 0.99 -- Anything equal to or higher than this value will be kicked. (0.99 Recommended as Lowest)
local flags = 'm' -- Quickest and most accurate check. Checks IP blacklist.

-- Data variables

local payss
local ispss
local playerName
local playerIP
local def

-- Switchs var

local printFailed = true

----------
-- Code --
----------

-- Main : Event Handler and main function

if Config['activeSecurity'] == true then
    AddEventHandler('playerConnecting',function(playerNames, setKickReason, deferrals)
        if GetNumPlayerIndices() < GetConvarInt('sv_maxclients', 32) then
            def = deferrals
            playerName = playerNames
            deferrals.defer()
            deferrals.update(Config.lang[Config.langInfo].MessageAttente)
            playerIP = GetPlayerEP(source)
            guid = GetPlayerToken(source,1)
            if Config.identifier == "steam" then 
                playerIdentifier = GetPlayerIdentifiers(source)[1]
            elseif Config.identifer == "licence" then
                playerIdentifier = GetPlayerIdentifiers(source)[2]
            end
           
            if string.match(playerIP, ":") then
                playerIP = splitString(playerIP, ":")[1]
            end

            if IsPlayerAceAllowed(source, "blockVPN.bypass") then
                deferrals.done()
                return
            else
                local probability = 0
                for k,v in ipairs(Config.AllowList) do
                print(v)
                    if playerIP == v then
                        deferrals.done()
                        return
                    end
                end
                
                PerformHttpRequest(Config['apiUrl'] .. '' .. playerIP ..'&contact=' .. ownerEmail .. '&flags=' ..flags, function(statusCode, response, headers)
                    if response then
                        if tonumber(response) == -5 then
                            if Config.debug then
                                print('~r~[ERR-000]~r~ CONTACTER BLOODY CITY')
                            end
                            probability = -5
                        elseif tonumber(response) == -6 then
                            if Config.debug then
                                print('~r~[ERR-001]~r~ CONTACTER BLOODY CITY')
                            end
                            probability = -6
                        elseif tonumber(response) == -4 then
                            if Config.debug then
                                print('~r~[ERR-002]~r~ CONTACTER BLOODY CITY')
                            end
                            probability = -4
                        else
                            probability = tonumber(response)
                        end
                    end
                   
                    if probability >= kickThreshold and Config.Vpn then
                        deferrals.done(kickReason)
                        local username = Config['botUsername']
                        local color = "15158332"
                        local title = Config.lang[Config.langInfo].vpn
                        local content = Config.lang[Config.langInfo].vpnDiscord.." \n"..Config.lang[Config.langInfo].vpnProba.. " "..probability.. "\n"..Config.lang[Config.langInfo].ipName.." :".. playerIP .. " \n"..Config.lang[Config.langInfo].playerName.." : "..playerName        
                        

                        sendDiscord(url, username, color, title, content)
                        if printFailed then
                            if Config.debug then
                                print('[SECURITY][BLOCKED]' .. playerName ..' was blocked from joining with a value of ' ..probability)
                            end
                        end
                       
                    else
                        PerformHttpRequest(Config.apiUrl2 .. "" .. playerIP,function(errorCode, result, resultHeaders)
                            local json = json.decode(result)
                            local isp_value = json.isp
                            local pays_value = json.countryCode

                            

                            if Config.debug then
                                print(isp_value, pays_value)
                            end

                            MySQL.Async.fetchAll('SELECT * FROM list_isp_auth WHERE code = @code',{['@code'] = isp_value}, function(isp)
                                MySQL.Async.fetchAll('SELECT code FROM list_pays_auth WHERE code = @code2 ',{['@code2'] = pays_value}, function(pays)
                                    MySQL.Async.fetchAll('SELECT ip FROM list_ip_auth WHERE ip = @code3 ', {['@code3'] = playerIP}, function(ips)

                                        payss = pays_value
                                        isps = isp_value
                                        local p = false
                                        local t = false
                                        local ip = false
                                        local random = math.random(1000,500000)
                                                   
                                        for _, v in ipairs(isp) do
                                            if v.code then
                                                p = true
                                            end
                                        end

                                        for _, j in ipairs(pays) do
                                            if j.code then
                                                t = true
                                            end
                                        end

                                        for _, k in ipairs(ips) do
                                            if k.ip then
                                                ip = true
                                            end
                                        end
                                        
                                        if Config.Blacklist then
                                            if Config.debug then
                                                print(playerName)
                                            end
                                            MySQL.Async.fetchAll('SELECT * FROM list_guid_blacklist WHERE guid = @id', { ['@id'] = guid }, function(result)
                                                if result[1] ~= nil then
                                                    deferrals.done("~r~[ERR-004]~r~ CONTACTER NOUS \n"..Config.lang[Config.langInfo].kickBlacklist.." <<"..result[1].raison.." >> By "..result[1].who)
                                                else 
                                                    if Config.Ip == false and Config.Pays == false and Config.Isp == false then
                                                        deferrals.done()
                                                        connexion(playerName,playerIP,isps, payss)
                                                    end 
                                                end
                                            end)
                                        end

                                        if Config.Isp and Config.Pays and Config.Ip then
                                            if p ~= true then
                                                sendError(true,false,false)
                                            elseif t ~= true then
                                                sendError(false,true,false)
                                            elseif ip ~= true then
                                                sendError(false,false,true)
                                            else
                                                deferrals.done()
                                                connexion(playerName,playerIP,isps, payss)
                                                --MySQL.Async.execute('UPDATE users SET IP = @ip, isp = @isp, pays = @pays, name = @name, guid = @guid WHERE IP = @ip',{['@ip'] = playerIP,['@name'] = playerName,['@isp'] = isps,['@pays'] = payss, ['@guid'] = guid},
                                                MySQL.Async.execute('UPDATE users SET IP = @ip, isp = @isp, pays = @pays, guid = @guid WHERE identifier = @playerIdentifier',{['@ip'] = playerIP,['@isp'] = isps,['@pays'] = payss, ['@guid'] = guid, ['@playerIdentifier'] =  playerIdentifier},
                                                function(affectedRows)
                                                    if Config.debug then
                                                        print(affectedRows)
                                                    end
                                                end)
                                            end
                                            
                                        elseif Config.Isp and Config.Ip and Config.Pays == false then
                                            if p ~= true then
                                                sendError(true,false,false)
                                            elseif ip ~= true then
                                                sendError(false,false,true)
                                            else
                                                deferrals.done()
                                                connexion(playerName,playerIP,isps, payss)
                                                MySQL.Async.execute('UPDATE users SET IP = @ip, isp = @isp, pays = @pays, guid = @guid WHERE identifier = @playerIdentifier',{['@ip'] = playerIP,['@isp'] = isps,['@pays'] = payss, ['@guid'] = guid, ['@playerIdentifier'] =  playerIdentifier},
                                                function(affectedRows)
                                                    if Config.debug then
                                                        print(affectedRows)
                                                    end
                                                end)
                                            end

                                        elseif Config.Ip and Config.Pays and Config.Isp == false then
                                            if t ~= true then
                                                sendError(false,true,false)
                                            elseif ip ~= true then
                                                sendError(false,false,true)
                                            else
                                                deferrals.done()
                                                connexion(playerName,playerIP,isps, payss)
                                                MySQL.Async.execute('UPDATE users SET IP = @ip, isp = @isp, pays = @pays, guid = @guid WHERE identifier = @playerIdentifier',{['@ip'] = playerIP,['@isp'] = isps,['@pays'] = payss, ['@guid'] = guid, ['@playerIdentifier'] =  playerIdentifier},
                                                function(affectedRows)
                                                    if Config.debug then
                                                        print(affectedRows)
                                                    end
                                                end)
                                            end

                                        elseif Config.Ip == false and Config.Pays and Config.Isp == false then
                                            if t ~= true then
                                                sendError(false,true,false)
                                            else
                                                deferrals.done()
                                                connexion(playerName,playerIP,isps, payss)
                                                MySQL.Async.execute('UPDATE users SET IP = @ip, isp = @isp, pays = @pays, guid = @guid WHERE identifier = @playerIdentifier',{['@ip'] = playerIP,['@isp'] = isps,['@pays'] = payss, ['@guid'] = guid, ['@playerIdentifier'] =  playerIdentifier},
                                                function(affectedRows)
                                                    if Config.debug then
                                                        print(affectedRows)
                                                    end
                                                end)
                                            end
                                        elseif Config.Ip == false and Config.Pays == false and Config.Isp then
                                            if p ~= true then
                                                sendError(true,false,false)
                                            else
                                                deferrals.done()
                                                connexion(playerName,playerIP,isps, payss)
                                                MySQL.Async.execute('UPDATE users SET IP = @ip, isp = @isp, pays = @pays, guid = @guid WHERE identifier = @playerIdentifier',{['@ip'] = playerIP,['@isp'] = isps,['@pays'] = payss, ['@guid'] = guid, ['@playerIdentifier'] =  playerIdentifier},
                                                function(affectedRows)
                                                    if Config.debug then
                                                        print(affectedRows)
                                                    end
                                                end)
                                            end

                                        elseif  Config.Isp and Config.Pays and Config.Ip == false then
                                            if p ~= true then
                                                sendError(true,false,false)
                                            elseif t ~= true then
                                                sendError(false,true,false)
                                            else
                                                deferrals.done()
                                                connexion(playerName,playerIP,isps, payss)
                                                MySQL.Async.execute('UPDATE users SET IP = @ip, isp = @isp, pays = @pays, guid = @guid WHERE identifier = @playerIdentifier',{['@ip'] = playerIP,['@isp'] = isps,['@pays'] = payss, ['@guid'] = guid, ['@playerIdentifier'] =  playerIdentifier},
                                                function(affectedRows)
                                                    if Config.debug then
                                                        print(affectedRows)
                                                    end
                                                end)
                                            end
                                        end                  
                                    end)
                                end)
                            end)
                        end)
                    end
                end)
            end
        end
    end)
end

---------------
-- Functions --
---------------

-- DOCUMENTATION : 

    -- SendError : Return the specified error to the client and close the connexion
    -- connexion : Allow connexion to player 
    -- splitString : split and compare string 
    -- sendDiscord : send a discord query to the specified 

function sendError(isp,pays,ip)
    if ip then
        def.done(Config.lang[Config.langInfo].deferalMessageIp.." -> "..Config.discordUrl)
        local username = Config['botUsername']
        local xPlayer = playerName
        local randPlayer = math.random(1,1569865)
        local color = "15158332"
        local title = Config.lang[Config.langInfo].whitelist
        local content = Config.lang[Config.langInfo].ipDiscord.." \n"..Config.lang[Config.langInfo].ispName.." :"..isps .." \n"..Config.lang[Config.langInfo].paysName.." :"..payss .. " \n"..Config.lang[Config.langInfo].ipName.." :".. playerIP .. " \n"..Config.lang[Config.langInfo].playerName.." : "..playerName        
        sendDiscord(url,username,color,title,content)
    elseif isp then
        def.done( Config.lang[Config.langInfo].deferalMessageisp.." -> " ..Config.discordUrl)
        local username = Config['botUsername']
        local color = "15158332"
        local title = Config.lang[Config.langInfo].isp
        local content = Config.lang[Config.langInfo].ispDiscord.." \n"..Config.lang[Config.langInfo].ispName.." :"..isps .." \n"..Config.lang[Config.langInfo].paysName.." :"..payss .. " \n"..Config.lang[Config.langInfo].ipName.." :".. playerIP .. " \n"..Config.lang[Config.langInfo].playerName.." : "..playerName       
        sendDiscord(url,username,color,title,content)
    elseif pays then
        def.done(Config.lang[Config.langInfo].deferalMessagePays.." -> "..Config.discordUrl )
        local username = Config['botUsername']
        local color = "15158332"
        local title = Config.lang[Config.langInfo].pays
        local content = Config.lang[Config.langInfo].paysDiscord.." \n"..Config.lang[Config.langInfo].ispName.." :"..isps .." \n"..Config.lang[Config.langInfo].paysName.." :"..payss .. " \n"..Config.lang[Config.langInfo].ipName.." :".. playerIP .. " \n"..Config.lang[Config.langInfo].playerName.." : "..playerName
        sendDiscord(url,username,color,title,content)
    end    
end

function connexion(playerName, playerIP, isp, pays)
    local username = Config['botUsername']
    local color = "3066993"
    local title = Config.lang[Config.langInfo].connexionOk
    local content = Config.lang[Config.langInfo].connectDiscord.." \n"..Config.lang[Config.langInfo].ispName.." :"..isps .." \n"..Config.lang[Config.langInfo].paysName.." :"..payss .. " \n"..Config.lang[Config.langInfo].ipName.." :".. playerIP .. " \n"..Config.lang[Config.langInfo].playerName.." : "..playerName.. " \n Guid" ..guid  
    sendDiscord(url,username,color,title,content)
end

function sendDiscord(url, usernames, color, title, content)
    PerformHttpRequest(url, function(err, text, headers) end, 'POST',
        json.encode({
            username = usernames,
            embeds = {{
                ["color"] = color,
                ["title"] = title,
                ["description"] = content,
                ["text"] = Config.discordfooter
            }
        },
        avatar_url = Config.avatarUrl,
        tts = false
    }), {['Content-Type'] = 'application/json'})
end

function splitString(inputstr, sep)
    local t = {};
    i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

--------------
-- Commands --
--------------

RegisterCommand("add:ip", function(source, args, rawCommand)
    local ip = args[1]
    local name = GetPlayerName(source)

    MySQL.Async.fetchAll('SELECT * FROM list_ip_auth WHERE IP = @code', { ['@code'] = ip }, function(result)
        if result[1] ~= nil then
            TriggerClientEvent('security:client:chat', source, Config.lang[Config.langInfo].IpMessageErrorBdd)
        else
            MySQL.Async.execute('INSERT INTO list_ip_auth (IP,who) VALUES (@code, @name)',{ ['@code'] = ip , ['@name'] = name  },
            function(affectedRows)
                if Config.debug then
                   print(affectedRows)
                end
            end)
        end
    end)
end, true)

RegisterCommand("add:blacklist", function(source, args, rawCommand)
    local guids = args[1]
    local name = GetPlayerName(source)
    local m=GetPlayerIdentifier(source)

    MySQL.Async.fetchAll('SELECT * FROM list_guid_blacklist WHERE guid = @guid', { ['@guid'] = guid }, function(result)
        if result[1] ~= nil then
            TriggerClientEvent('security:client:notify', source, Config.error[Config.langInfo].BlacklistMessageErrorBdd)
        else
            MySQL.Async.execute('INSERT INTO list_guid_blacklist (guid,who,raison) VALUES (@guid, @who, @raison)',{ ['@guid'] = args[1] , ['@who'] = args[2], ['@raison'] = args[3]  },
            function(affectedRows)
                if Config.debug then
                    print(affectedRows)
                    -- if args[4] then
                    --     setKickReason('SECURITY CORE \n 🧊🧊🧊 - Joueur : ' .. tostring(name) .. ' \n Identifier: ' .. tostring(m) .. ' \n\n Raison: ' .. (tostring(args[3]) .. ' \n BAN / Kick)
                    -- end
                end
            end)
        end
    end)
end, true)

RegisterCommand("get:player", function(source, args, rawCommand)
    local commande = args[1]
    local name = GetPlayerName(source)

    MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @name or IP = @ip', { ['@name'] = commande, ['@ip'] = commande}, function(result)
        if result[1] == nil then
            TriggerClientEvent('security:client:notify', source, Config.error[Config.langInfo].BlacklistMessageSendErrorBdd)
        else
            TriggerClientEvent('security:client:chat', source, Config.lang[Config.langInfo].titlePlayerBlacklistMessage.. "" ..result[1].guid)
            Wait(5)
            TriggerClientEvent('security:client:chat', source, Config.lang[Config.langInfo].titlePlayerBlacklistMessage2.. "" ..result[1].name)
            Wait(5)
            TriggerClientEvent('security:client:chat', source, Config.lang[Config.langInfo].titlePlayerBlacklistMessage3.. "" ..result[1].IP)
        end
    end)
end, true)

RegisterCommand("add:pays", function(source, args, rawCommand)
    local pays = args[1]
    local name = GetPlayerName(source)
    MySQL.Async.fetchAll('SELECT * FROM list_pays_auth WHERE code = @code', { ['@code'] = pays }, function(result)
        if result[1] ~= nil then
            TriggerClientEvent('security:client:chat', source, Config.lang[Config.langInfo].PaysMessageErrorBdd)
        else
            MySQL.Async.execute('INSERT INTO list_pays_auth (code,who) VALUES (@code, @name)',{ ['@code'] = pays , ['@name'] = name  },
            function(affectedRows)
                if Config.debug then
                    print(affectedRows)
                end
            end)
        end
    end)
end, true)

RegisterCommand("add:isp", function(source, args, rawCommand)
    local isp
    local name = GetPlayerName(source)

    if args[1] ~= nil and args[2] ~= nil and args[3] == nil then
        isp = args[1].." "..args[2]
    elseif args[1] ~= nil and args[2] ~= nil and args[3] ~= nil and args[4] == nil then
        isp = args[1].." "..args[2].." "..args[3]
    elseif args[1] ~= nil and args[2] ~= nil and args[3] ~= nil and args[4] ~= nil then
        isp = args[1].." "..args[2].." "..args[3].." "..args[4]
    elseif args[1] ~= nil and args[2] ~= nil and args[3] ~= nil and args[4] ~= nil and args[5]  ~= nil then
        isp = args[1].." "..args[2].." "..args[3].." "..args[4].." "..args[5]
    elseif args[1] ~= nil and args[2] ~= nil and args[3] ~= nil and args[4] ~= nil and args[5]  ~= nil and args[6]  ~= nil then
        isp = args[1].." "..args[2].." "..args[3].." "..args[4].." "..args[5].." "..args[6]
    elseif args[1] ~= nil and args[2] ~= nil and args[3] ~= nil and args[4] ~= nil and args[5]  ~= nil and args[6]  ~= nil and args[7]  ~= nil then
        isp = args[1].." "..args[2].." "..args[3].." "..args[4].." "..args[5].." "..args[6].." "..args[7]
    elseif args[1] ~= nil and args[2] ~= nil and args[3] ~= nil and args[4] ~= nil and args[5]  ~= nil and args[6]  ~= nil and args[7]  ~= nil and args[8]  ~= nil then
        isp = args[1].." "..args[2].." "..args[3].." "..args[4].." "..args[5].." "..args[6].." "..args[7].." "..args[8]
    elseif args[1] ~= nil and args[2] ~= nil and args[3] ~= nil and args[4] ~= nil and args[5]  ~= nil and args[6]  ~= nil and args[7]  ~= nil and args[8]  ~= nil and args[9]  ~= nil then
        isp = args[1].." "..args[2].." "..args[3].." "..args[4].." "..args[5].." "..args[6].." "..args[7].." "..args[8].." "..args[9]
    elseif args[1] ~= nil and args[2] ~= nil and args[3] ~= nil and args[4] ~= nil and args[5]  ~= nil and args[6]  ~= nil and args[7]  ~= nil and args[8]  ~= nil and args[9]  ~= nil and args[10]  ~= nil then
        isp = args[1].." "..args[2].." "..args[3].." "..args[4].." "..args[5].." "..args[6].." "..args[7].." "..args[8].." "..args[9].." "..args[10]
    else
        isp = args[1]
    end

    MySQL.Async.fetchAll('SELECT * FROM list_isp_auth WHERE code = @code', { ['@code'] = isp }, function(result)
        if result[1] ~= nil then
            TriggerEvent('chat:addMessage', {color = { 255, 0, 0}, multiline = false, args = {Config.lang[Config.langInfo].ispMessageErrorBdd}})
        else
            MySQL.Async.execute('INSERT INTO list_isp_auth (code,who) VALUES (@code, @name)',{ ['@code'] = isp , ['@name'] = name  },
            function(affectedRows)
                if Config.debug then
                    print(affectedRows)
                end
            end)
        end
    end)
end, true)


Citizen.CreateThread(function()
    if (GetCurrentResourceName() == "security") then
        if Config.activeSecurity == true and Config.activeInfo == true then
            if Config.langInfo == "fr" then
            print('┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬')
            if Config.Isp then
            print("Protection ISP :  🔰✅")
            else
                print("Protection ISP :  ⚠️❌")
            end

            if Config.Pays then
                print("Protection PAYS :  🔰✅")
            else
                print("Protection PAYS :  ⚠️❌")
            end

            if Config.Ip then
                print("Protection WHITELIST :  🔰✅")
            else
                print("Protection WHITELIST :  ⚠️❌")
            end

            if Config.Vpn then
                print("Protection VPN :  🔰✅")
            else
                print("Protection VPN :  ⚠️❌")
            end

            if Config.Blacklist then
                print("Protection BLACKLIST :  🔰✅")
            else
                print("Protection BLACKLIST :  ⚠️❌")
            end

            print("Langue du script :"..Config.langInfo)
        else
            print("☢️ SYSTEME TOTALEMENT COUPER☢️")
        end
    else
        if Config.langInfo == "en" then
            print('┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬')
            if Config.Isp then
            print("ISP Protection :  🔰✅")
            else
                print("ISP Protection :  ⚠️❌")
            end

            if Config.Pays then
                print("COUNTRY Protection :  🔰✅")
            else
                print("COUNTRY Protection :  ⚠️❌")
            end

            if Config.Ip then
                print("Protection WHITELIST :  🔰✅")
            else
                print("Protection WHITELIST :  ⚠️❌")
            end

            if Config.Vpn then
                print("Protection VPN :  🔰✅")
            else
                print("Protection VPN :  ⚠️❌")
            end

            if Config.Blacklist then
                print("Protection BLACKLIST :  🔰✅")
            else
                print("Protection BLACKLIST :  ⚠️❌")
            end

            print("Script language :"..Config.langInfo)
        else
            print("☢️ TOTALLY CUT SYSTEM ☢️")
        end
    end

        print("┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴")
    end
  end)
