

Width = 40 -- Width 
Height = 40 -- Height 
Range = 0




Colors = {
    red = "\27[31m",
    green = "\27[32m",
    blue = "\27[34m",
    reset = "\27[0m",
    gray = "\27[90m"
}


local zhTips = {
    points="点",
    excavate = "开始挖掘",
    power = " 攻击力:",
    dodge = " 闪避:",
    defense=" 防御力:",
    health=" 血量:",
    energy=" 能量：",
    get="获得",
    excavate1="能量不足,无法挖掘",
    excavate2="非常幸运,额外挖掘到",
    excavate3="该区域已被挖掘",
    calculateHurt1="成功闪避攻击",
    calculateHurt2=" 他的血量：",
    calculateHurt3="点伤害",
    calculateHurt4="受到了",
    calculateHurt5="您成功淘汰",
    calculateHurt6="成功防御攻击",
    attack1="攻击完成！",
    attack2="发起攻击",
    move1="缺少能量",
    move2="移动到",
    move3="错误的方向"
}


local enTips = {
    points="Points",
    excavate = "Start Digging",
    power = " Attack Power:",
    dodge = " Dodge:",
    defense = " Defense:",
    health=" health:",
    energy=" Energy:",
    get="Get",
    excavate1="Insufficient energy, unable to excavate",
    excavate2="Very lucky to have discovered additional resources",
    excavate3="The area has been excavated",
    calculateHurt1="Successfully dodged the attack",
    calculateHurt2=" His health:",
    calculateHurt3="Point damage",
    calculateHurt4="Received",
    calculateHurt5="You have successfully eliminated",
    calculateHurt6="Successfully defended against attacks",
    attack1="Attack completed!",
    attack2="Launch an attack",
    move1="Lack of energy",
    move2="Move to",
    move3="Wrong direction"
}


ExcavateTable = {}

AoExcavateTable = {}

-- Player energy settings
MaxEnergy = 100 -- Maximum energy a player can have
EnergyPerSec = 1 -- Energy gained per second





function CreateAoPoint(x, y,aoPoint)
    return {x = x, y = y,aoPoint=aoPoint}
end

function CreatePoint(x, y)
    return {x = x, y = y}
end

function PointExists(points, x, y)
    for _, point in ipairs(points) do
        if point.x == x and point.y == y then
            return point
        end
    end
    return nil
end



function InRange(x1, y1, x2, y2, range)
    return math.abs(x1 - x2) <= range and math.abs(y1 - y2) <= range
end

function PlayerInitState()
    return {
        x = math.random(0, Width),
        y = math.random(0, Height),
        health = 100,
        energy = 0,

        dodge=0,
        defense=0,
        power=1,
        aoToken=0,
        language="zh"
    }
end

--设计随机种子
function SetRandomSeedByfrom(from)
    local numberPid= from:gsub("%D", "")
    if #numberPid<8 then
        numberPid = string.format("%08d", tonumber(numberPid))
    end
    numberPid = string.sub(numberPid, 1, 8)
    math.randomseed(tonumber(numberPid))
end

function SetLanguage(from)
    if Players[from].language == 'zh' then
        return zhTips
    else
        return enTips
    end
end

-- 挖掘获得属性
function Excavate(msg) 
    local playerToExcavate = msg.From

    local Tips=SetLanguage(playerToExcavate)

    local x=Players[playerToExcavate].x
    local y=Players[playerToExcavate].y
    if Players[playerToExcavate].energy<30 then
        Announce("excavate", Colors.green..Tips.excavate1)
        return;
    end
    if PointExists(ExcavateTable,x,y) ~= nil then
        Announce("excavate", Colors.green..Tips.excavate3)
        return;
    end

    local isExistenceAoToken=PointExists(AoExcavateTable,x,y)
    if isExistenceAoToken~=nil then
        Announce("excavate", Colors.green..Tips.excavate2..isExistenceAoToken.aoPoint)
        Players[playerToExcavate].aoToken=Players[playerToExcavate].aoToken+isExistenceAoToken.aoPoint
    end

    SetRandomSeedByfrom(playerToExcavate)

    local random_number = math.random(1, 100)
    if random_number%4==0 then
        return;
    end

    local addType = math.random(1, 3)
    local addNumber = math.random(1, 5)
    if addType==1 then
        if Players[playerToExcavate]<70  then
            Players[playerToExcavate].dodge = Players[playerToExcavate].dodge+addNumber
            Announce("excavate", Colors.green..Tips.get..addNumber..Tips.points..Tips.dodge)
        end
    elseif addType==2 then
        Players[playerToExcavate].defense = Players[playerToExcavate].defense+addNumber
        Announce("excavate", Colors.green..Tips.get..addNumber..Tips.points..Tips.defense)
    elseif addType==3 then
        Players[playerToExcavate].power = Players[playerToExcavate].power+addNumber
        Announce("excavate", Colors.green..Tips.get..addNumber..Tips.points..Tips.power )
    end
    Players[playerToExcavate].energy = Players[playerToExcavate].energy-30
    table.insert(ExcavateTable, CreatePoint(Players[playerToExcavate].x,Players[playerToExcavate].y))

end



--时钟
function OnTick(msg)
    Now = msg.Timestamp
    if GameMode ~= "Playing" then return end  -- Only active during "Playing" state

    if LastTick == nil then LastTick = Now end

    local Elapsed = Now - LastTick
    if Elapsed >= 1000 then  -- Actions performed every second
        for _, state in pairs(Players) do
            local newEnergy = math.floor(math.min(MaxEnergy, state.energy + (Elapsed * EnergyPerSec // 2000)))
            state.energy = newEnergy
        end
        LastTick = Now
    end
end


-- 计算属性
function CalculateHurt(me,other)
    local meData= Players[me]
    local otherData= Players[other]
    local Tips=SetLanguage(me)

    SetRandomSeedByfrom(other)

    local random_number = math.random(1, 100)

    if random_number<=otherData.dodge then
        Announce("attack", Colors.red..other..Tips.calculateHurt1
      ..Tips.calculateHurt2..otherData.health..Tips.energy..otherData.energy
      ..Tips.power..otherData.power..Tips.defense..otherData.defense
      ..Tips.dodge..otherData.dodge
        )
    elseif meData.power-otherData.defense>0 then
        otherData.health=otherData.health-(meData.power-otherData.defense)
        Announce("attack", Colors.red..other..Tips.calculateHurt4..(meData.power-otherData.defense)..Tips.calculateHurt3
      ..Tips.calculateHurt2..otherData.health..Tips.energy..otherData.energy
      ..Tips.power..otherData.power..Tips.defense..otherData.defense
      ..Tips.dodge..otherData.dodge
        )
    elseif meData.power-otherData.defense<=0 then
        Announce("attack", Colors.red..other..Tips.calculateHurt6
      ..Tips.calculateHurt2..otherData.health..Tips.energy..otherData.energy
      ..Tips.power..otherData.power..Tips.defense..otherData.defense
      ..Tips.dodge..otherData.dodge
        )
    end

    if otherData.health<=0 then
        EliminatePlayer(other,me)
        Announce("attack", Colors.blue..Tips.calculateHurt5..other)
        meData.aoToken=meData.aoToken+otherData.aoToken
    end

    meData.energy=meData.energy-10

end


-- 攻击
function Attack(msg)
    local player = msg.From
    local Tips=SetLanguage(player)
    local x = Players[player].x
    local y = Players[player].y

    Announce("attack", player..","..x..","..y..Tips.attack2..Tips.power..Players[player].power.."!")

    for target, state in pairs(Players) do
        if target ~= player and InRange(x, y, state.x, state.y, 1) then
            CalculateHurt(player,target)
        end
    end
    OnTick(msg)
    ao.send({Target = player, Action = "Tick"})
    Announce("attack", Colors.red..Tips.attack1
  ..Tips.health..Players[player].health..Tips.energy..Players[player].energy
  ..Tips.power..Players[player].power..Tips.defense..Players[player].defense
  ..Tips.dodge..Players[player].dodge
    )

end



-- 移动
function Move(msg)
    local playerToMove = msg.From
    local direction = msg.Tags.Direction
    local Tips=SetLanguage(playerToMove)
    local directionMap = {
        Up = {x = 0, y = -1}, Down = {x = 0, y = 1},
        Left = {x = -1, y = 0}, Right = {x = 1, y = 0},
        UpRight = {x = 1, y = -1}, UpLeft = {x = -1, y = -1},
        DownRight = {x = 1, y = 1}, DownLeft = {x = -1, y = 1}
    }

    if Players[playerToMove].energy<5 then
        ao.send({Target = playerToMove, Action = "Move-Failed", Reason = Tips.move1})
    elseif directionMap[direction] then
        local newX = Players[playerToMove].x + directionMap[direction].x
        local newY = Players[playerToMove].y + directionMap[direction].y

        Players[playerToMove].x = (newX - 1) % Width + 1
        Players[playerToMove].y = (newY - 1) % Height + 1

        Announce("move", playerToMove..Tips.move2..Players[playerToMove].x..","..Players[playerToMove].y..".")
    else
        ao.send({Target = playerToMove, Action = "Move-Failed", Reason = Tips.attack3})
    end
    OnTick(msg) 
    ao.send({Target = playerToMove, Action = "Tick"})

    Announce("move", Colors.red.."移动完成！"
   ..Tips.health..Players[playerToMove].health..Tips.energy..Players[playerToMove].energy
   ..Tips.power..Players[playerToMove].power..Tips.defense..Players[playerToMove].defense
   ..Tips.dodge..Players[playerToMove].dodge )
end

function Language(msg)
    local player = msg.From
    if msg.Data == "zh" then
        Players[player].language="zh"
    elseif msg.Data == "en" then
        Players[player].language="en"
    else
        Announce("Error", "Please enter 'en' or 'zh' for data")
    end
end

Handlers.add("Excavate", Handlers.utils.hasMatchingTag("Action", "Excavate"), Excavate)

Handlers.add("Move", Handlers.utils.hasMatchingTag("Action", "Move"), Move)

Handlers.add("Attack", Handlers.utils.hasMatchingTag("Action", "Attack"), Attack)

Handlers.add("Language", Handlers.utils.hasMatchingTag("Action", "Language"), Language)





















































GameMode = "Not-Started"
StateChangeTime = nil

-- State durations (in milliseconds)
WaitTime = WaitTime or 2 * 60 * 1000 -- 2 minutes
GameTime = GameTime or 20 * 60 * 1000 -- 20 minutes
Now = nil -- Current time, updated on every message.

-- Token information for player stakes.
UNIT = 0
PaymentToken = "7K0PPRCB6na3aC2SNy8C8HszrMxfgvNNorMGpQSgpOY"   -- Token address
AoTokenAddres="Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc"
PaymentQty = PaymentQty or tostring(math.floor(UNIT))    -- Quantity of tokens for registration

-- Players waiting to join the next game and their payment status.
Waiting = {}
-- Active players and their game states.
Players = {}
-- Number of winners in the current game.
Winners = 0
-- Processes subscribed to game announcements.
Listeners =  {}
-- Minimum number of players required to start a game.
MinimumPlayers = 2


-- Sends a state change announcement to all registered listeners.
-- @param event: The event type or name.
-- @param description: Description of the event.
function Announce(event, description)
    for _, address in pairs(Listeners) do
        ao.send({
            Target = address,
            Action = "Announcement",
            Event = event,
            Data = description
        })
    end
    -- print(Colors.gray.."Announcement: "..Colors.red..event.." "..Colors.blue..description..Colors.reset)
end

-- Sends a reward to a player.
-- @param recipient: The player receiving the reward.
-- @param qty: The quantity of the reward.
-- @param reason: The reason for the reward.
function SendReward(recipient, qty, reason,tokenAddres)
    if type(qty) ~= "number" then
      qty = tonumber(qty)
    end
    ao.send({
        Target = tokenAddres,
        Action = "Transfer",
        Quantity = tostring(qty),
        Recipient = recipient,
        Reason = reason
    })
    return print(Colors.gray.."Sent Reward: "..
      Colors.blue..tostring(qty)..
      Colors.gray..' tokens to '..
      Colors.green..recipient.." "..
      Colors.blue..reason..Colors.reset
    )
end

-- Starts the waiting period for players to become ready to play.
function StartWaitingPeriod()
    GameMode = "Waiting"
    StateChangeTime = Now + WaitTime
    Announce("Started-Waiting-Period", "Say Send({ Target = Game, Action = 'Ready'})")
    print('Starting Waiting Period')
end

-- Starts the game if there are enough players.
function StartGamePeriod()
    local paidPlayers = 0
    for player, hasPaid in pairs(Waiting) do
        if hasPaid then
            paidPlayers = paidPlayers + 1
        end
    end

    if paidPlayers < MinimumPlayers then
        Announce("Not-Enough-Players", "Not enough players registered! Restarting...")
        for player, hasPaid in pairs(Waiting) do
            if hasPaid then
                Waiting[player] = false
                SendReward(player, PaymentQty, "Refund",PaymentToken)
            end
        end
        StartWaitingPeriod()
        return
    end

    LastTick = nil
    GameMode = "Playing"
    StateChangeTime = Now + GameTime
    local AttendNumber=0
    for player, hasPaid in pairs(Waiting) do
        if hasPaid then
            Players[player] = PlayerInitState()
            AttendNumber=AttendNumber+1
        else
            ao.send({
                Target = player,
                Action = "Ejected",
                Reason = "Did-Not-Pay"
            })
            RemoveListener(player) -- Removing player from listener if they didn't pay
        end
    end

    if AttendNumber>10 then
        DisperseAO(AttendNumber)
    end
    Announce("Started-Game", "The game has started. Good luck!")
    print("Game Started....")
end

function DisperseAO(AttendNumber)

    
    for i = 1, AttendNumber do
        local x = math.random(0, Width)
        local y = math.random(0, Height)
        local aoPoint = math.random(0, 50)
        CreateAoPoint(x,y,aoPoint)

        if PointExists(AoExcavateTable,x,y)~=nil then
            i=i-1;
        else 
            table.insert(AoExcavateTable,CreatePoint(x,y))
        end

    end
    
end

-- Handles the elimination of a player from the game.
-- @param eliminated: The player to be eliminated.
-- @param eliminator: The player causing the elimination.
function EliminatePlayer(eliminated, eliminator)
    -- SendReward(eliminator, PaymentQty, "Eliminated-Player")
    Waiting[eliminated] = false
    Players[eliminated] = nil

    ao.send({
        Target = eliminated,
        Action = "Eliminated",
        Eliminator = eliminator
    })

    Announce("Player-Eliminated", eliminated.." was eliminated by "..eliminator.."!")

    local playerCount = 0
    for player, _ in pairs(Players) do
        playerCount = playerCount + 1
    end
    print("Eliminating player: "..eliminated.." by: "..eliminator) -- Useful for tracking eliminations

    if playerCount < MinimumPlayers then
        EndGame()
    end

end

-- Ends the current game and starts a new one.
function EndGame()
    print("Game Over")

    for player, value in pairs(Players) do
        -- addLog("EndGame", "Sending reward of:"..Winnings + PaymentQty.."to player: "..player) -- Useful for tracking rewards
        SendReward(player, value.aoToken, "Win",AoTokenAddres)
        Waiting[player] = false
    end

    Players = {}
    Announce("Game-Ended", "Congratulations! The game has ended. Remaining players at conclusion: "..Winners..".")
    StartWaitingPeriod()
end

-- Removes a listener from the listeners' list.
-- @param listener: The listener to be removed.
function RemoveListener(listener)
    local idx = 0
    for i, v in ipairs(Listeners) do
        if v == listener then
            idx = i
            break
        end
    end
    if idx > 0 then
        table.remove(Listeners, idx)
    end 
end



-- Handler for cron messages, manages game state transitions.
Handlers.add(
    "Game-State-Timers",
    function(Msg)
        return "continue"
    end,
    function(Msg)
        Now = Msg.Timestamp
        if GameMode == "Not-Started" then
            StartWaitingPeriod()
        elseif GameMode == "Waiting" then
            if Now > StateChangeTime then
                StartGamePeriod()
            end
        elseif GameMode == "Playing" then
            if OnTick and type(OnTick) == "function" then
              OnTick(Msg)
            end
            if Now > StateChangeTime then
                EndGame()
            end
        end
    end
)

-- Handler for player deposits to participate in the next game.
Handlers.add(
    "Ready",
    Handlers.utils.hasMatchingTag("Action", "Ready"),
    function(Msg)
        Waiting[Msg.From] = true
        ao.send({
            Target = Msg.From,
            Action = "Payment-Received"
        })
        Announce("Player-Ready", Msg.From.." is ready to play!")
    end
)

-- Registers new players for the next game and subscribes them for event info.
Handlers.add(
    "Register",
    Handlers.utils.hasMatchingTag("Action", "Register"),
    function(Msg)
        if Msg.Mode ~= "Listen" and Waiting[Msg.From] == nil then
            Waiting[Msg.From] = false
        end
        RemoveListener(Msg.From)
        table.insert(Listeners, Msg.From)
        ao.send({
            Target = Msg.From,
            Action = "Registered"
        })
        Announce("New Player Registered", Msg.From.." has joined in waiting.")
    end
)

-- Unregisters players and stops sending them event info.
Handlers.add(
    "Unregister",
    Handlers.utils.hasMatchingTag("Action", "Unregister"),
    function(Msg)
        RemoveListener(Msg.From)
        ao.send({
            Target = Msg.From,
            Action = "Unregistered"
        })
    end
)



-- Retrieves the current game state.
Handlers.add(
    "GetGameState",
    Handlers.utils.hasMatchingTag("Action", "GetGameState"),
    function (Msg)
        local json = require("json")
        local TimeRemaining = StateChangeTime - Now
        local GameState = json.encode({
            GameMode = GameMode,
            TimeRemaining = TimeRemaining,
            Players = Players,
            })
        ao.send({
            Target = Msg.From,
            Action = "GameState",
            Data = GameState})
    end
)

-- Alerts users regarding the time remaining in each game state.
Handlers.add(
    "AnnounceTick",
    Handlers.utils.hasMatchingTag("Action", "Tick"),
    function (Msg)
        local TimeRemaining = StateChangeTime - Now
        if GameMode == "Waiting" then
            Announce("Tick", "The game will start in "..(TimeRemaining/1000).." seconds.")
        elseif GameMode == "Playing" then
            Announce("Tick", "The game will end in "..(TimeRemaining/1000).." seconds.")
        end
    end
)

