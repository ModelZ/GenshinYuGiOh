-- Furina De Fontaine
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit() --Limit monster revive
	-- 1 "Fontaine" monster + 1 "Genshin" WATER monster
	Fusion.AddProcMix(c,true,true,s.fusionfilter1,s.fusionfilter2)
	--When this card is fusion Summoned: You can return 1 opponent's monster on the field to the hand, also, Place 1 Lullaby Counter on this card.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND) -- effect categories for other effect to trigger
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O) -- type of activaing effect
	e1:SetCode(EVENT_SPSUMMON_SUCCESS) -- event of this effect
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.condition) -- condition of effect to activate
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate) -- effect resolve
	c:RegisterEffect(e1)
end
s.listed_series={0x5003}
Debug.Message("debug active")
function s.tgfilter(c)
	Debug.Message("s.tgfilter active")
	return c:IsMonster() and c:IsAbleToHand()
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	Debug.Message("s.condition active")
	return e1:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.target(e,tp,eg,ep,ev,re,r,rp)
	if chk == 0 then 
	Debug.Message("chk == 0 active")
	return Duel.IsExistingMatchingCard(s.tgfilter,tp,0,LOCATION_MZONE,1,nil)
	end

	Debug.Message("s.target active")
	local tg=Duel.SelectMatchingCard(tp,s.tgfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Debug.Message("tg = "+tg)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,tg,1,1-tp,LOCATION_MZONE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Debug.Message("s.activate active")
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SendtoHand(g,REASON_EFFECT)
end

function s.fusionfilter1(c)
	return aux.FilterBoolFunctionEx(Card.IsSetCard,0x5003)
end

function s.fusionfilter2(c)
	return aux.FilterBoolFunctionEx(Card.IsSetCard,0x3) and c:IsAttribute(ATTRIBUTE_WATER)
end
