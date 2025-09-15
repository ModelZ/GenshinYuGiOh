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

	-- Destruction replacement: remove 1 Akara Counter instead
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_DESTROY_REPLACE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetTarget(s.reptg)
    e5:SetValue(s.repval)
    e5:SetOperation(s.repop)
    c:RegisterEffect(e5)


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

-- Target: check if we can replace destruction
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return eg:IsExists(function(tc) 
            return tc:IsControler(tp) and tc:IsOnField() and tc:IsReason(REASON_EFFECT)
        end,1,nil) 
        and Duel.IsCanRemoveCounter(tp,1,0,0x301,1,REASON_COST)
    end
    return true
end

-- Value: say “yes, we replace this destruction”
function s.repval(e,c)
    return c:IsControler(e:GetHandlerPlayer()) and c:IsOnField() and c:IsReason(REASON_EFFECT)
end

-- Operation: actually do the replacement
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.RemoveCounter(tp,1,0,0x301,1,REASON_COST)
    Duel.ChangeBattleDamage(tp,0) -- if battle damage is involved, nullify
end


