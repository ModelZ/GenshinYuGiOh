-- Lesser Lord Kusanali
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion material
	c:EnableReviveLimit()
    c:EnableCounterPermit(0x301) -- Can Place Akara Counter 
	Fusion.AddProcMix(c,true,true,s.sumerufilter,s.lightfilter)

    -- Opponent cannot respond to your "Genshin" cards
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetOperation(s.chainop)
    c:RegisterEffect(e1)

	-- Continuous effect: observe counters
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_ADJUST) -- triggers every game state update
    e3:SetRange(LOCATION_MZONE)
    e3:SetOperation(s.observe_counter)
    c:RegisterEffect(e3)

	-- Quick effect: prevent destruction or damage
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.damcon)
	e4:SetCost(s.damcost)
	e4:SetOperation(s.damop)
	c:RegisterEffect(e4)

    -- You can remove any number of Akara counter(s) and target your monster that had the counter on it on the field (Quick Effect); 
    -- increase the number of that Counter by the number of removed Akara counter(s)..

end

-- Table to store last known counter counts
s.last_counters = {}

-- Observe counters on all face-up cards and add Akara Counter to this card if another card gains counters
function s.observe_counter(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
    for tc in aux.Next(g) do
        local id = tc:GetFieldID()
        local last = s.last_counters[id] or 0
        local now = tc:GetCounter(0x301)
        if tc~=c and now>last then
            -- Another card gained 1 or more Akara counters → give this card 1 Akara Counter
            c:AddCounter(0x301,1)
        end
        s.last_counters[id] = now
    end
end

function s.IsExactSet(c,setcode)
    local codes={c:GetSetCard()}
    for _,v in ipairs(codes) do
        if v==setcode then return true end
    end
    return false
end

--Fusion materials
function s.sumerufilter(c,fc,sumtype,tp)
    return s.IsExactSet(c,0x4700) and c:IsType(TYPE_MONSTER)  -- Sumeru monster
end

function s.lightfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x700) and c:IsAttribute(ATTRIBUTE_LIGHT)  -- "Genshin" LIGHT monster
end


function s.chainop(e,tp,eg,ep,ev,re,r,rp)
    local rc=re:GetHandler()
    if rc:IsSetCard(0x700) and rp==tp then
        -- make this chain unrespondable
        Duel.SetChainLimit(aux.FALSE)
    end
end
-- -- Place a Akara Counter when other's card place a counter (ignores itself)
-- function s.acop(e,tp,eg,ep,ev,re,r,rp)
--     local c=e:GetHandler()
--     -- eg = group of cards that got counters
--     for tc in aux.Next(eg) do
--         if tc~=c then
--             -- Another card got counters → give this card 1 Akara Counter
--             c:AddCounter(0x301,1)
--             break -- only once per event, no matter how many got counters
--         end
--     end
-- end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return true -- you can add battle/effect destruction check
end
function s.damcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetCounter(0x301)>0 end
	c:RemoveCounter(tp,0x301,1,REASON_COST)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChangeBattleDamage(tp,0)
end
