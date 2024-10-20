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
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_CHAIN_SOLVED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.condition1)
	e3:SetTarget(s.target1)
	e3:SetOperation(s.activate1)
	c:RegisterEffect(e3)
end
s.listed_series={0x3700}
s.listed_names={id}
function s.filter(c)
	return c:IsSetCard(0x700) and c:IsAbleToHand()
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
-- If other "Genshin" Monster effect is activated
function s.condition1(e,tp,eg,ep,ev,re,r,rp)
	Debug.Message("s.condition1 active")
	return re:IsActiveType(TYPE_MONSTER) and c:IsSetCard(0x700)
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