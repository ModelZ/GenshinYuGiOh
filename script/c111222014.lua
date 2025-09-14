--My Brother's
--Scripted by [Your Name]
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon fusion materials when a "Genshin" Fusion leaves by opponent
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_LEAVE_FIELD)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x700} --"Genshin"

--Check condition: your "Genshin" Fusion monster left by opponent's effect
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	while tc do
		if tc:IsPreviousLocation(LOCATION_MZONE) and tc:IsType(TYPE_FUSION)
			and tc:IsSetCard(0x700) and tc:IsControler(tp)
			and rp==1-tp and (r&REASON_EFFECT)~=0 then
			-- Store the materials that were actually used
			local mat=tc:GetMaterial()
			if #mat>0 then
				e:SetLabelObject(mat:Clone()) -- clone to preserve group
				return true
			end
		end
		tc=eg:GetNext()
	end
	return false
end

--Filter: can this specific material be summoned?
function s.spfilter(c,e,tp,code)
	return c:IsCode(code) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Target check
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local mat=e:GetLabelObject()
	if chk==0 then
		if not mat then return false end
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<#mat then return false end
		--Make sure every material is summonable from at least one zone
		for mc in aux.Next(mat) do
			if not Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp,mc:GetCode()) then
				return false
			end
		end
		return true
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,#mat,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

--Activate: summon those exact materials
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local mat=e:GetLabelObject()
	if not mat then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<#mat then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end

	local g=Group.CreateGroup()
	for mc in aux.Next(mat) do
		-- search for 1 copy of that exact material (priority: GY > Banished > Hand > Deck)
		local locs={LOCATION_GRAVE,LOCATION_REMOVED,LOCATION_HAND,LOCATION_DECK}
		local chosen=nil
		for _,loc in ipairs(locs) do
			local cand=Duel.GetFirstMatchingCard(s.spfilter,tp,loc,0,nil,e,tp,mc:GetCode())
			if cand then
				chosen=cand
				break
			end
		end
		if chosen then g:AddCard(chosen) end
	end

	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		if g:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then
			Duel.ShuffleDeck(tp)
		end
	end
end
