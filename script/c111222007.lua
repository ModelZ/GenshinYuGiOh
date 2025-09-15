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

	-- When your "Genshin" card would be destroyed by battle or a card effect (Quick Effect): 
    -- You can remove 1 Akara Counter; that "Genshin" monster cannot destroy by battle or card effect and take no damage.
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_QUICK_O+EFFECT_TYPE_FIELD)
    e4:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTarget(s.damtg)
    e4:SetOperation(s.damrepop)
    c:RegisterEffect(e4)

    -- If a card would be destroyed by card effect (Quick Effect): You can remove 1 Akara Counter instead and take no damage.
    -- local e5=Effect.CreateEffect(c)
    -- e5:SetType(EFFECT_TYPE_QUICK_O+EFFECT_TYPE_FIELD)


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

-- Destruction replacement target
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:GetCounter(0x301)>0 end
    return true
end

-- Destruction replacement operation
function s.damrepop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:GetCounter(0x301)>0 then
        c:RemoveCounter(tp,0x301,1,REASON_COST)
        local tc=Duel.GetAttackTarget()
        if tc and tc:IsSetCard(0x700) then
            -- Make the target indestructible by battle and card effect this time
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
            e1:SetValue(1)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
            tc:RegisterEffect(e1)
            local e2=e1:Clone()
            -- Prevent battle damage
            e2:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
            tc:RegisterEffect(e2)
            
    end
end


