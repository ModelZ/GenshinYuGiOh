-- Furina De Fontaine
local s,id=GetID()
function s.initial_effect(c)
    c:EnableCounterPermit(0x300) -- Can Place Lulaby Counter 
    c:EnableReviveLimit() -- Limit monster revive
    -- Fusion Summon procedure
    Fusion.AddProcMix(c,true,true,s.fusionfilter1,s.fusionfilter2)
    
    -- When this card is Fusion Summoned: Return 1 opponent's monster to the hand, also place 1 Lullaby Counter on this card
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCountLimit(1,id)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.condition) -- condition when fusion is performed
    e1:SetTarget(s.target) -- target opponent's monster
    e1:SetOperation(s.activate) -- execute the return and counter placement
    c:RegisterEffect(e1)

    -- When your opponent adds a card, place 1 Lullaby Counter on this card
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
    e2:SetCode(EVENT_CHAIN_SOLVED)
    e2:SetRange(LOCATION_MZONE)
    e2:SetOperation(s.acop) -- add 1 Lullaby counter on resolution
    c:RegisterEffect(e2)

	-- Negate any summon using Lullaby Counter
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_SUMMON) -- Normal Summon
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL+EFFECT_FLAG_NO_TURN_RESET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.condition1) -- condition to check summon
	e4:SetCost(s.cost1) -- cost to remove counter
	e4:SetTarget(s.target1) -- negate summon and return monster to hand
	e4:SetOperation(s.activate1)
	c:RegisterEffect(e4)

	-- Add effect for Flip Summons
	local e5=e4:Clone()
	e5:SetCode(EVENT_FLIP_SUMMON) -- Flip Summon
	c:RegisterEffect(e5)

	-- Add effect for Special Summons
	local e6=e4:Clone()
	e6:SetCode(EVENT_SPSUMMON) -- Special Summon
	c:RegisterEffect(e6)

end

function s.IsExactSet(c,setcode)
    local codes={c:GetSetCard()}
    for _,v in ipairs(codes) do
        if v==setcode then return true end
    end
    return false
end

-- Fusion filters for "Fontaine" monster and "Genshin" WATER monster
function s.fusionfilter1(c)
    return s.IsExactSet(c,0x5700) and c:IsType(TYPE_MONSTER) -- Fontaine monsters
end
function s.fusionfilter2(c)
    return c:IsSetCard(0x700) and c:IsAttribute(ATTRIBUTE_WATER) -- Genshin WATER monsters
end

-- Condition to check if this card was Fusion Summoned
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) -- trigger if Fusion Summoned
end

-- Select target for returning to hand
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,0)
end

-- Execute return and counter placement
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    -- Place 1 Lullaby Counter on this card (always)
    e:GetHandler():AddCounter(0x300,1)
    
    -- Now try to return an opponent's monster to hand
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,0,LOCATION_MZONE,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT) -- return selected monster to hand
    end
end

-- Filter for targetable monsters
function s.tgfilter(c)
    return c:IsMonster() and c:IsAbleToHand()
end

-- Place a Lullaby Counter when opponent adds a card (draw/search)
function s.acop(e,tp,eg,ep,ev,re,r,rp)
    -- Check if the effect is from the opponent
    if (re:IsHasCategory(CATEGORY_DRAW) or re:IsHasCategory(CATEGORY_SEARCH)) and re:GetOwnerPlayer()~=tp then
        -- Add 1 Lullaby Counter when the opponent draws/searches
        e:GetHandler():AddCounter(0x300,1)
    end
end


-- Condition to negate summon
function s.condition1(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetCurrentChain()==0 and ep~=tp -- only when opponent is summoning
end

-- Cost to remove counter for summon negation
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x300,1,REASON_COST) end
    e:GetHandler():RemoveCounter(tp,0x300,1,REASON_COST)
end

-- Target and negate summon
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,#eg,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,eg,#eg,0,0)
end

-- Negate the summon and return to hand
function s.activate1(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateSummon(eg)
    Duel.SendtoHand(eg,nil,REASON_EFFECT)
end
