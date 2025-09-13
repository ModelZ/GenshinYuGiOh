--Kokomi
local s,id=GetID()
function c111222001.initial_effect(c)
    --Search a "Genshin" Monster card
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    -- If other "Genshin" Monster effect is activated (Quick Effect): You can Special Summon 1 "Genshin" monster from your Deck. 
    local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.condition1)
	e3:SetTarget(s.target1)
	e3:SetOperation(s.activate1)
	c:RegisterEffect(e3)
    -- If you control 2 or more "Genshin" Monster on the field, you can activate this effect: Fusion Summon 1 "Genshin" Monster, using monsters from your hand or field as Fusion Material.
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id+2) -- Once per turn restriction
    e4:SetCondition(s.fusioncondition) -- condition to check for 2+ "Genshin" monsters
    -- Fusion Summon using predefined fusion parameters
    local fusparams = {fusfilter=s.fusionfilter1, extrafil=nil, extraop=nil, gc=nil, chkf=tp}
    e4:SetTarget(Fusion.SummonEffTG(fusparams))
    e4:SetOperation(Fusion.SummonEffOP(fusparams))
    c:RegisterEffect(e4)

end
s.listed_series={0x700}
-- Search a "Genshin" monster
function s.filter(c)
	return c:IsSetCard(0x700) and c:IsAbleToHand() and c:IsType(TYPE_MONSTER)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
-- If another "Genshin" Monster effect is activated (ignores itself)
function s.condition1(e,tp,eg,ep,ev,re,r,rp)
    local rc = re:GetHandler()
    return rc and rc:IsSetCard(0x700)      -- Must be a "Genshin" monster
       and rc:IsType(TYPE_MONSTER)         -- Must be a monster
       and rc ~= e:GetHandler()            -- Must not be this card
end

-- only "Genshin" Monster
function s.filter1(c,e,tp)
	return c:IsSetCard(0x700) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
-- Condition for activating card
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
-- You can Special Summon 1 "Genshin" monster from your Deck. 
function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
-- Filter for fusion
function s.fusionfilter1(c,e,tp)
    return c:IsSetCard(0x700) and c:IsCanBeFusionMaterial() -- Assuming 0x700 is the "Genshin" archetype set code
end

-- Condition: Control 2 or more "Genshin" monsters
function s.fusioncondition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetMatchingGroupCount(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,0x700)>=2
end
