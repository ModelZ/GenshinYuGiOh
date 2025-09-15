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

	-- Add Akara Counters when another card leaves the field
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
    e3:SetCode(EVENT_LEAVE_FIELD)  -- trigger when a card leaves the field
    e3:SetRange(LOCATION_MZONE)
    e3:SetOperation(s.acop)
    c:RegisterEffect(e3)

	-- Quick effect: prevent destruction or damage
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_DESTROY_REPLACE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTarget(s.damcon)
    e4:SetValue(s.damop)
    c:RegisterEffect(e4)

    -- You can remove any number of Akara counter(s) and target your monster that had the counter on it on the field (Quick Effect); 
    -- increase the number of that Counter by the number of removed Akara counter(s)..

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

-- Place an Akara Counter when another card leaves the field (ignores itself)
function s.acop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Another card left the field → give this card 1 Akara Counter
    c:AddCounter(0x301,1)
end

-- Destruction replacement condition
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsCanRemoveCounter(tp,1,0,0x301,1,REASON_COST)
end

-- Destruction replacement operation
function s.damop(e,tp,eg,ep,ev,re,r,rp)

    -- Remove 1 Akara Counter as the replacement cost
    Duel.RemoveCounter(tp,1,0,0x301,1,REASON_COST)

    -- took no battle damage
    if Duel.RemoveCounter(tp,1,0,0x301,1,REASON_COST) then
        -- Prevent the destruction
        return true
    else
        return false
    end

end

