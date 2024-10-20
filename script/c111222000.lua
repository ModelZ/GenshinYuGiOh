-- Furina De Fontaine
local s,id=GetID()
function s.initial_effect(c)
	c:EnableCounterPermit(0x300) --Can Place Counter 
	c:EnableReviveLimit() --Limit monster revive
	-- 1 "Fontaine" monster + 1 "Genshin" WATER monster
	Fusion.AddProcMix(c,true,true,s.fusionfilter1,s.fusionfilter2)
	--When this card is fusion Summoned: You can return 1 opponent's monster on the field to the hand, also, Place 1 Lullaby Counter on this card.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND) -- effect categories for other effect to trigger
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O) -- type of activaing effect
	e1:SetCode(EVENT_SPSUMMON_SUCCESS) -- event of this effect
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.condition) -- condition of effect to activate
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate) -- effect resolve
	c:RegisterEffect(e1)
	
	--When your opponent adds a card, place 1 Lullaby Counter on this card.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.chainreg)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_COUNTER)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_CHAIN_SOLVED)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.acop) --add 1 Lullaby counter
	c:RegisterEffect(e3)

	--When your opponent's monster(s) would be Summoned: remove 1 Lullaby Counter; negate the Summon, and if you do, return it to the hand.
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_SUMMON)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL+EFFECT_FLAG_NO_TURN_RESET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.condition1)
	e4:SetCost(s.cost1)
	e4:SetTarget(s.target1)
	e4:SetOperation(s.activate1)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_FLIP_SUMMON)
	c:RegisterEffect(e5)
	local e6=e4:Clone()
	e6:SetCode(EVENT_SPSUMMON)
	c:RegisterEffect(e6)

end
s.listed_series={0x5003}
s.listed_names={id}
Debug.Message("debug active")

function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	--Debug.Message("s.activate1 active")
	Duel.NegateSummon(eg)
	Duel.SendtoHand(eg,nil,REASON_EFFECT)
end

function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	--Debug.Message("s.target1 active")
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,#eg,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,eg,#eg,0,0)
end

function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	--Debug.Message("s.cost1 active")
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x300,1,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,0x300,1,REASON_COST)
end

function s.condition1(e,tp,eg,ep,ev,re,r,rp)
	--Debug.Message("s.condition1 active")
	return Duel.GetCurrentChain(true)==0
end

function s.acop(e,tp,eg,ep,ev,re,r,rp)
	--Debug.Message("s.acop active")
	if re:IsHasCategory(CATEGORY_DRAW) or re:IsHasCategory(CATEGORY_SEARCH) then
		e:GetHandler():AddCounter(0x300,1)
	end

end

function s.tgfilter(c)
	--Debug.Message("s.tgfilter active")
	return c:IsMonster() and c:IsAbleToHand()
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	--Debug.Message("s.condition active")
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chkc then Debug.Message("chkc active") end
	if chk == 0 then 
	--Debug.Message("chk == 0 active")
	--return Duel.IsExistingMatchingCard(s.tgfilter,tp,0,LOCATION_MZONE,1,nil)
	return true --always add at least Counter
	end

	--Debug.Message("s.target active")
	--local tg=Duel.SelectMatchingCard(tp,s.tgfilter,tp,0,LOCATION_MZONE,1,1,nil)
	--Debug.Message(tg)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--Debug.Message("s.activate active")
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local tg=Duel.SelectMatchingCard(tp,s.tgfilter,tp,0,LOCATION_MZONE,1,1,nil)
	--Debug.Message(tg)
	Duel.SendtoHand(tg,nil,REASON_EFFECT) -- return to hand
	e:GetHandler():AddCounter(0x300,1) -- add 1 Lullaby Counter
end

function s.fusionfilter1(c)
	return c:IsSetCard(0x5700)
end

function s.fusionfilter2(c)
	return c:IsSetCard(0x700) and c:IsAttribute(ATTRIBUTE_WATER)
end
