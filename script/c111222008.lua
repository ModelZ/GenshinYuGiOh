-- Rex Lapis
local s,id=GetID()
function s.initial_effect(c)
    -- Fusion Summon procedure
    c:EnableReviveLimit()
    Fusion.AddProcMix(c,true,true, s.filLiyue, s.filRockGenshin)

    -- Opponent's effects cannot target your "Genshin" cards while this card is on the field or GY
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e1:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.gentg)  -- target your Genshin cards
    e1:SetValue(aux.tgoval) -- or 1 depending on your engine
    c:RegisterEffect(e1)

    -- While this card is on field or GY, opponent's monsters cannot attack any monster except this one
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
    e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e2:SetTargetRange(0,LOCATION_MZONE)
    e2:SetValue(s.atktg)
    c:RegisterEffect(e2)

    -- When a Spell/Trap card or effect is activated, place 1 Pillar Counter on this card
    c:EnableCounterPermit(0x302)  -- 0x302 = Pillar Counter (example ID)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_CHAIN_ACTIVATING)
    e3:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e3:SetCondition(s.stccon)
    e3:SetOperation(s.stcop)
    c:RegisterEffect(e3)

    -- Quick effect: when an opponent's monster effect is activated
    -- Remove 1 Pillar Counter; negate that effect and, if you do, send it to GY
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_NEGATE+CATEGORY_TOGRAVE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e4:SetCondition(s.negcon)
    e4:SetCost(s.negcost)
    e4:SetTarget(s.negtg)
    e4:SetOperation(s.negop)
    c:RegisterEffect(e4)
end

function s.IsExactSet(c,setcode)
    local codes={c:GetSetCard()}
    for _,v in ipairs(codes) do
        if v==setcode then return true end
    end
    return false
end

-- Filters for fusion materials
function s.filLiyue(c,fc,sumtype,tp)
    return s.IsExactSet(c,0x2700) and c:IsType(TYPE_MONSTER)  -- replace 0xXXXX with your Liyue setcode
end
function s.filRockGenshin(c,fc,sumtype,tp)
    return c:IsSetCard(0x700) and c:IsAttribute(ATTRIBUTE_EARTH) -- Genshin ROCK monster
end

-- Target for cannot be effect target
function s.gentg(e,c)
    return c:IsSetCard(0x700) -- all your Genshin cards
end

-- Attack target restriction: opponent's monsters cannot attack other monsters except this card
function s.atktg(e,c)
    return c~=e:GetHandler() -- can only attack this card
end

-- Condition for adding pillar counter when a S/T is activated
function s.stccon(e,tp,eg,ep,ev,re,r,rp)
    -- Check if the activating card is Spell/Trap
    return re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsHasType(TYPE_SPELL+TYPE_TRAP)
end
function s.stcop(e,tp,eg,ep,ev,re,r,rp)
    e:GetHandler():AddCounter(0x302,1)
end

-- Condition for negation effect
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
end

-- Cost: remove 1 Pillar Counter
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:HasCounter(0x302) end
    c:RemoveCounter(tp,0x302,1,REASON_COST)
end

-- Target function for negation
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsAbleToGrave() then
        Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,eg,1,0,0)
    end
end

-- Operation: negate and send to GY
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) then
            Duel.SendtoGrave(rc,REASON_EFFECT)
        end
    end
end
