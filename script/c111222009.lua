-- Raiden Shogun
local s,id=GetID()
function s.initial_effect(c)
    -- Fusion Summon procedure: 1 "Inazuma" monster + 1 "Genshin" DARK monster
    c:EnableReviveLimit()
    Fusion.AddProcMix(c,true,true, s.Inazumafilter, s.darkgenshinfilter)

    -- Lighting Counter permit
    c:EnableCounterPermit(0x303)  -- example ID for “Lighting Counter”

    -- Effect A: If this card is Fusion Summoned → banish all opponent’s cards from GY + place 1 Lighting Counter
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE+CATEGORY_COUNTER)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
        return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
    end)
    e1:SetTarget(s.banishtg)
    e1:SetOperation(s.banishop)
    c:RegisterEffect(e1)

    -- Effect B: When opponent’s monster effect is activated, place 1 Lighting Counter on this card
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.plccon)
    e2:SetOperation(s.plcop)
    c:RegisterEffect(e2)

    -- Effect C: If this card leaves the field by your opponent’s card effect (Quick Effect)
    -- can remove 1 Any Counter on your field; destroy that card; after that Special Summon this card;
    -- then you can Place 1 Lighting Counter on this card
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_DESTROY + CATEGORY_SPECIAL_SUMMON + CATEGORY_COUNTER)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_LEAVE_FIELD)
    e3:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCondition(s.leavecon)
    e3:SetCost(s.leavecost)
    e3:SetTarget(s.leavetg)
    e3:SetOperation(s.leaveop)
    c:RegisterEffect(e3)

    -- Effect D: When opponent’s Spell/Trap Card is activated (Quick Effect): you can remove 1 Lighting Counter from this card; negate the activation, and if you do, shuffle that card to the Deck
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetCategory(CATEGORY_NEGATE + CATEGORY_TODECK)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e4:SetCondition(s.stnegcon)
    e4:SetCost(s.stnegcost)
    e4:SetTarget(s.stnegtg)
    e4:SetOperation(s.stnegop)
    c:RegisterEffect(e4)
end

-- Filters

function s.Inazumafilter(c,fc,sumtype,tp)
    return c:IsSetCard(0x3700) and c:IsType(TYPE_MONSTER)
end

function s.darkgenshinfilter(c,fc,sumtype,tp)
    return c:IsSetCard(0x700) and c:IsType(TYPE_MONSTER) and c:IsAttribute(ATTRIBUTE_DARK)
end

-- Effect A: Banish opponent’s GY + place Lighting Counter

function s.banishtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return true  -- always allow the effect, even if there's nothing to banish 
    end
    -- Set info for banish if possible
    if Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_GRAVE,1,nil) then
        Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, 1-tp, LOCATION_GRAVE)
    end
end

function s.banishop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Attempt to banish if possible
    local g=Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_GRAVE, nil)
    if #g>0 then
        Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
    end
    -- Regardless, place 1 Lighting Counter on this card
    Debug.Message("banishop: adding 1 Lighting Counter")
    c:AddCounter(0x303,1)
end


-- Effect B: place counter when opponent monster effect activates

function s.plccon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and re:IsActiveType(TYPE_MONSTER)
end

function s.plcop(e,tp,eg,ep,ev,re,r,rp)
    e:GetHandler():AddCounter(0x303,1)
end

-- Effect C: leaves field by opponent effect → remove counter, destroy that card, special summon this, then place 1 Lighting Counter

function s.leavecon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Debug.Message("leavecon triggered")
    Debug.Message("rp="..rp.." tp="..tp.." r="..r.." re="..tostring(re))

    return rp~=tp
        and c:IsPreviousLocation(LOCATION_ONFIELD)
        and (r & REASON_EFFECT)~=0   -- only care that it was by effect
end

-- Filter function: check if card has any removable counter
local function hasCounter(cc, tp)
    local counters = cc:GetAllCounters()
    if not counters then return false end
    for ct,_ in pairs(counters) do
        if cc:IsCanRemoveCounter(tp, ct, 1, REASON_COST) then
            return true
        end
    end
    return false
end

function s.leavecost(e,tp,eg,ep,ev,re,r,rp,chk)
    Debug.Message("leavecost check")

    -- Check if there is any counter on your field that can be removed
    local has=Duel.IsExistingMatchingCard(hasCounter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil, tp)
    Debug.Message("leavecost available? "..tostring(has))
    if chk==0 then return has end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp, hasCounter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil, tp)
    local rc=g:GetFirst()
    if rc then
        -- Remove 1 counter of the first available type
        local counters = rc:GetAllCounters()
        for ct,_ in pairs(counters) do
            if rc:IsCanRemoveCounter(tp, ct, 1, REASON_COST) then
                rc:RemoveCounter(tp, ct, 1, REASON_COST)
                Debug.Message("leavecost removed counter type "..ct.." from "..rc:GetCode())
                break
            end
        end
    else
        Debug.Message("leavecost failed to select")
    end
end


function s.leavetg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    Debug.Message("leavetg triggered")
    if chk==0 then
        -- Only check if you can special summon your card
        local ok=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        Debug.Message("leavetg chk result: "..tostring(ok))
        return ok
    end

    local rc=re and re:GetHandler() or nil
    if rc then Debug.Message("leavetg targeting card: "..rc:GetCode()) end

    -- Still set operation info for clarity
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c,1,0,0)
    Duel.SetOperationInfo(0, CATEGORY_COUNTER, c,1,0,0)
    if rc and rc:IsDestructable() then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, rc,1,0,0)
    end
end

function s.leaveop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=re and re:GetHandler() or nil
    Debug.Message("leaveop triggered")

    -- Attempt to destroy target if valid
    if rc and rc:IsRelateToEffect(re) and rc:IsDestructable() then
        if Duel.Destroy(rc, REASON_EFFECT)>0 then
            Debug.Message("leaveop: destroyed rc")
        else
            Debug.Message("leaveop: failed to destroy rc")
        end
    else
        Debug.Message("leaveop: rc not valid or not destructable, skipping destroy")
    end

    -- Always special summon and add counter if possible
    if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then
        if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
            Debug.Message("leaveop: special summoned c")
            c:AddCounter(0x303,1)
            Debug.Message("leaveop: added 1 Lighting Counter")
        else
            Debug.Message("leaveop: failed to special summon c")
        end
    else
        Debug.Message("leaveop: no monster zone available or cannot special summon")
    end
end



-- Effect D: negate opponent’s Spell/Trap activation, shuffle to Deck

function s.stnegcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and Duel.IsChainNegatable(ev)
end

function s.stnegcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():GetCounter(0x303)>0 end
    e:GetHandler():RemoveCounter(tp,0x303,1,REASON_COST)
end

function s.stnegtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg,1,0,0)
    if re:GetHandler():IsAbleToDeck() then
        Duel.SetOperationInfo(0, CATEGORY_TODECK, eg,1,0,0)
    end
end

function s.stnegop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) then
            Duel.SendtoDeck(rc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
        end
    end
end

