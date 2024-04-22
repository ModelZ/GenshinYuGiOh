-- Furina De Fontaine
local s,id=GetID()
function s.initial_effect(c)
	-- 1 "Fontaine" monster + 1 "Genshin" WATER monster
	Fusion.AddProcMix(c,true,true,s.fusionfilter1,s.fusionfilter2)
	--When this card is fusion Summoned: You can send 1 opponent's monster from field to hand, also, Place 1 Lullaby Counter on this card.
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_COUNTER) -- effect categories for other effect to trigger
	e1:SetType(EFFECT_TYPE_TRIGGER_O) -- type of activaing effect
	e1:SetCode(EVENT_SPSUMMON_SUCCESS) -- event of this effect
	e1:SetCondition(s.condition) -- condition of effect to activate
	e1:SetOperation(s.activate) -- effect resolve
	c:RegisterEffect(e1)
end
s.listed_series={0x5003}

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return e1:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,0,1,1,e:GetHandler())
	Duel.SendtoHand(g,REASON_EFFECT)
end


function s.fusionfilter2(c)
	return c:ListsArchetype(0x3) and c:IsAttribute(ATTRIBUTE_WATER)
end

function s.fusionfilter1(c)
	return c:ListsArchetype(0x5003)