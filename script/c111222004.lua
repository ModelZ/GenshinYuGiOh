--Yaoyao
local s,id=GetID()
function s.initial_effect(c)
    s.listed_series={0x700} -- Genshin archetype

    -- 1. Negate opponent's monster effect in response to "Genshin" card effect
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id) -- once per turn
    e1:SetCondition(s.negcon)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- 2. Fusion Summon if another "Genshin" monster effect is activated
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1}) -- once per turn
    e2:SetCondition(s.fuscon)
    e2:SetTarget(s.fustg)
    e2:SetOperation(s.fusop)
    c:RegisterEffect(e2)
end

-- ========= Negate opponent effect =========
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    -- Must be opponent's monster effect responding to a "Genshin" card effect
    return rp~=tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
        and re:GetHandler():IsRelateToEffect(re)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsDiscardable() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsAbleToHand() then
        Duel.SetOperationInfo(0,CATEGORY_TOHAND,eg,1,0,0)
    end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.SendtoHand(re:GetHandler(),nil,REASON_EFFECT)
    end
end

-- ========= Fusion Summon =========
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
    local rc=re:GetHandler()
    -- Trigger only if another "Genshin" monster's effect is activated
    return rc:IsSetCard(0x700) and rc:IsType(TYPE_MONSTER) and rc~=e:GetHandler()
end

function s.fusfilter(c,e,tp,m,f,chkf)
    return c:IsType(TYPE_FUSION) and c:IsSetCard(0x700)
        and (not f or f(c)) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and c:CheckFusionMaterial(m,nil,chkf)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
    local chkf=tp
    local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
    if chk==0 then return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,nil,chkf) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
    local chkf=tp
    local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg,nil,chkf)
    local fc=sg:GetFirst()
    if fc then
        local mat=Duel.SelectFusionMaterial(tp,fc,mg,nil,chkf)
        fc:SetMaterial(mat)
        Duel.SendtoHand(mat,nil,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
        Duel.BreakEffect()
        Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
        fc:CompleteProcedure()
    end
end
