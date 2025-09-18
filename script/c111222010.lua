-- Goddess Lumine
local s,id=GetID()
function s.initial_effect(c)
    -- Fusion summon procedure
    c:EnableReviveLimit()
    -- Fusion Material: 3 "Genshin" Fusion monsters
    Fusion.AddProcMixN(c, true, true, 
        aux.FilterBoolFunction(function(c) 
            return c:IsSetCard(0x700) and c:IsType(TYPE_FUSION) 
        end),
    3)


    -- Cannot be affected by other cards, summon cannot be negated or tributed
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_NEGATE)
    e0:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e0:SetRange(LOCATION_MZONE)
    e0:SetValue(aux.tgoval)
    c:RegisterEffect(e0)
    local e0b=e0:Clone()
    e0b:SetCode(EFFECT_CANNOT_BE_MATERIAL)
    c:RegisterEffect(e0b)
    
    local e0c=Effect.CreateEffect(c)
    e0c:SetType(EFFECT_TYPE_SINGLE)
    e0c:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
    c:RegisterEffect(e0c)
    
    local e0d=Effect.CreateEffect(c)
    e0d:SetType(EFFECT_TYPE_SINGLE)
    e0d:SetCode(EFFECT_UNRELEASABLE_SUM)
    e0d:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e0d:SetValue(1)
    c:RegisterEffect(e0d)

    -- Fusion Summon effect: banish opponent’s Extra Deck and shuffle their GY into deck
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.fuscon)
    e1:SetOperation(s.fusop)
    c:RegisterEffect(e1)

    -- Standby Phase special summon
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- Negate opponent's card/effect
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
end

-- Check fusion summon
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
    local g1=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_EXTRA,nil)
    Duel.Remove(g1,POS_FACEUP,REASON_EFFECT)
    local g2=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_GRAVE,nil)
    if #g2>0 then
        Duel.SendtoDeck(g2,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
end

-- Standby Phase special summon
function s.spfilter(c,e,tp)
    return (c:IsSetCard(0x700) or c:IsType(TYPE_FUSION)) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        and (c:IsLocation(LOCATION_EXTRA+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED))
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Negate opponent's card/effect
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return ep~=tp and re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
        and Duel.IsChainNegatable(ev)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckReleaseGroup(tp,Card.IsSetCard,1,nil,0x700) end
    local g=Duel.SelectReleaseGroup(tp,Card.IsSetCard,1,1,nil,0x700)
    Duel.Release(g,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        local code=re:GetHandler():GetCode()
        local g=Duel.GetMatchingGroup(Card.IsCode,tp,0,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,nil,code)
        Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
    end
end
