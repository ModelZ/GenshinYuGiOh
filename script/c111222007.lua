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
    e4:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_FIELD)
    e4:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.damcon)
    e4:SetOperation(s.damrepop)
    c:RegisterEffect(e4)

    -- When a card would be destroyed by card effect (Quick Effect): You can remove 1 Akara Counter; that "Genshin" monster cannot destroy card effect and take no damage.
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_QUICK_O+EFFECT_TYPE_FIELD)
    e5:SetCode(EVENT_CHAINING)
    e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e5:SetRange(LOCATION_ONFIELD)
    e5:SetCondition(s.protcon)
    e5:SetOperation(s.protop)
    c:RegisterEffect(e5)

    -- You can remove any number of Akara counter(s) and target your monster that had the counter on it on the field (Quick Effect); 
    -- increase the number of that Counter by the number of removed Akara counter(s)..
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,1))
    e6:SetCategory(CATEGORY_COUNTER)
    e6:SetType(EFFECT_TYPE_QUICK_O+EFFECT_TYPE_FIELD)
    e6:SetCode(EVENT_FREE_CHAIN)
    e6:SetRange(LOCATION_MZONE)
    e6:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e6:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
    e6:SetCondition(s.cntcon)
    e6:SetTarget(s.rdcnttg)
    e6:SetOperation(s.rdcntop)
    c:RegisterEffect(e6)

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

-- Prevent opponent from responding to your "Genshin" card activations
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
    local rc = re:GetHandler()
    -- Check if the activating card is yours and is a "Genshin" card
    if rc:IsSetCard(0x700) and rp==tp then
        -- Set the chain limit so no one can respond to this chain link
        Duel.SetChainLimit(aux.FALSE)
    end
end


-- Place an Akara Counter when another card leaves the field (ignores itself)
function s.acop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Another card left the field → give this card 1 Akara Counter
    c:AddCounter(0x301,1)
end

-- target gain indestruction condition
function s.damcon(e,tp,eg,ep,ev,re,r,rp,chk)
    local tc=Duel.GetAttackTarget()
    if tc==nil then return false end
    return e:GetHandler():GetCounter(0x301)>0 and
        tc:IsSetCard(0x700) and tc:IsControler(tp)
end

-- target gain indestruction operation
function s.damrepop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:GetCounter(0x301)>0 then
        c:RemoveCounter(tp,0x301,1,REASON_COST)
        local tc=Duel.GetAttackTarget()
        if tc and tc:IsSetCard(0x700) and tc:IsControler(tp) then
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
end


function s.protcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Debug.Message("protcon called")

    -- Only opponent's card effect
    if rp==tp or not re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP) then 
        return false 
    end
    -- Debug.Message("protcon: opponent's effect")

    -- Only effects that have CATEGORY_DESTROY
    if not re:IsHasCategory(CATEGORY_DESTROY) then 
        return false 
    end
    -- Debug.Message("protcon: effect has CATEGORY_DESTROY")

    -- Check that it has at least 1 Akara counter
    if c:GetCounter(0x301)<=0 then
        return false
    end

    -- Debug.Message("protcon: has at least 1 Akara counter")

    -- Check previous chain link
    local ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
    
    -- Debug.Message("protcon: ex="..tostring(ex).." tg="..tostring(tg).." tc="..tostring(tc))

    -- Check if there is at least 1 face-up "Genshin" card you control that would be destroyed by the previous effect
    return ex and tg~=nil and tc+tg:FilterCount(Card.IsOnField,nil)-#tg>0 and
        -- Check if there is at least 1 face-up "Genshin" card you control
        tg:IsExists(function(c) return c:IsFaceup() and c:IsSetCard(0x700) and c:IsControler(tp) end, 1, nil)
end



-- Operation: remove 1 Akara Counter and prevent destruction + damage
function s.protop(e,tp,eg,ep,ev,re,r,rp)
    -- Check if effect has destruction targets
    local ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
    if not tg then return end

    -- Debug.Message("protop: ex="..tostring(ex).." tg="..tostring(tg).." tc="..tostring(tc))

    local c=e:GetHandler()
    if c:GetCounter(0x301)<=0 then return end

    -- Remove 1 Akara Counter
    c:RemoveCounter(tp,0x301,1,REASON_EFFECT)

    -- Give indestructible + no effect damage to each targeted monster
    for tc in aux.Next(tg) do

        -- Indestructible against this effect
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_CHAIN)
        tc:RegisterEffect(e1)

        -- Prevent damage from this effect (if applicable)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
        e2:SetValue(1)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_CHAIN)
        tc:RegisterEffect(e2)

    end
end

-- Can target your face-up monster that can accept counters (not itself)
function s.rdcntfilter(c,sc)
    if not c:IsFaceup() then return false end
    if c==sc then return false end -- exclude self
    local counters=c:GetAllCounters()
    if not counters then return false end
    for ct,_ in pairs(counters) do
        return true -- at least one counter type exists
    end
    return false
end


-- Condition: at least 1 valid target exists
function s.cntcon(e,tp,eg,ep,ev,re,r,rp)
    -- Debug.Message("cntcon called: "..tostring(Duel.IsExistingTarget(s.rdcntfilter,tp,LOCATION_MZONE,0,1,nil)))
    return Duel.IsExistingTarget(s.rdcntfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Target function: can only select other face-up monsters
function s.rdcnttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.rdcntfilter(chkc,e:GetHandler()) end
    if chk==0 then 
        return e:GetHandler():GetCounter(0x301)>0
           and Duel.IsExistingTarget(s.rdcntfilter,tp,LOCATION_MZONE,0,1,nil,e:GetHandler())
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    Duel.SelectTarget(tp,s.rdcntfilter,tp,LOCATION_MZONE,0,1,1,nil,e:GetHandler())
end

-- Operation: remove Akara counters and add same type as target already has
function s.rdcntop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
    local maxct=c:GetCounter(0x301)
    if maxct<=0 then return end

    -- Choose how many to remove
    Duel.Hint(HINT_NUMBER,tp,HINTMSG_NUMBER)
    -- Generate a list {1,2,3,...,maxct}
    local choices = {}
    for i=1,maxct do
        table.insert(choices,i)
    end
    -- Ask the player to choose
    local ct = Duel.AnnounceNumber(tp,table.unpack(choices))
    if ct<=0 or not c:RemoveCounter(tp,0x301,ct,REASON_EFFECT) then return end

    -- Find the first counter type the target has
    local counter_type
    local counters = tc:GetAllCounters()
    for k,_ in pairs(counters) do
        counter_type = k
        break
    end

    if counter_type then
        tc:AddCounter(counter_type,ct)
    end
end

