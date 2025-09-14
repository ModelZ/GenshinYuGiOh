--My Brother's
--Scripted by ModelZ
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon fusion materials when Genshin Fusion monster leaves field
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_LEAVE_FIELD)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={0x700} --"Genshin" archetype code

--Check if a "Genshin" Fusion monster left the field by opponent's card effect
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	--Check if there's a card that left the field
	local tc=eg:GetFirst()
	while tc do
		--Must be your "Genshin" Fusion monster
		if tc:IsControler(tp) 
			and tc:IsSetCard(0x700) 
			and tc:IsType(TYPE_FUSION)
			and tc:IsPreviousLocation(LOCATION_MZONE)
			--Must be removed by opponent's card effect
			and (r&REASON_EFFECT)~=0
			and rp==1-tp then
			--Store the materials for later use
			local mat=tc:GetMaterial()
			if mat and mat:GetCount()>0 then
				e:SetLabelObject(mat)
				return true
			end
		end
		tc=eg:GetNext()
	end
	return false
end

--Target: Check if we can Special Summon the materials
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mat=e:GetLabelObject()
		if not mat then return false end
		
		--Check if we can summon at least one material
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 then return false end
		
		--Check if any materials can be Special Summoned
		for tc in aux.Next(mat) do
			if s.spfilter(tc,e,tp) then
				return true
			end
		end
		return false
	end
	
	local mat=e:GetLabelObject()
	local ct=math.min(mat:GetCount(),Duel.GetLocationCount(tp,LOCATION_MZONE))
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,ct,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

--Filter for materials that can be Special Summoned
function s.spfilter(c,e,tp)
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_DECK) 
		or c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_REMOVED))
end

--Operation: Special Summon the fusion materials
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local mat=e:GetLabelObject()
	if not mat then return end
	
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	
	--Find materials that can be summoned from all zones
	local summonable=Group.CreateGroup()
	for tc in aux.Next(mat) do
		--Search in Hand
		local hg=Duel.GetMatchingGroup(function(c) return c:GetCode()==tc:GetCode() and s.spfilter(c,e,tp) end,tp,LOCATION_HAND,0,nil)
		if hg:GetCount()>0 then summonable:Merge(hg) end
		
		--Search in Deck
		local dg=Duel.GetMatchingGroup(function(c) return c:GetCode()==tc:GetCode() and s.spfilter(c,e,tp) end,tp,LOCATION_DECK,0,nil)
		if dg:GetCount()>0 then summonable:Merge(dg) end
		
		--Search in Graveyard
		local gg=Duel.GetMatchingGroup(function(c) return c:GetCode()==tc:GetCode() and s.spfilter(c,e,tp) end,tp,LOCATION_GRAVE,0,nil)
		if gg:GetCount()>0 then summonable:Merge(gg) end
		
		--Search in Banished Zone
		local rg=Duel.GetMatchingGroup(function(c) return c:GetCode()==tc:GetCode() and s.spfilter(c,e,tp) end,tp,LOCATION_REMOVED,0,nil)
		if rg:GetCount()>0 then summonable:Merge(rg) end
	end
	
	if summonable:GetCount()>0 then
		local ct=math.min(ft,summonable:GetCount())
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=summonable:Select(tp,1,ct,nil)
		
		if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)>0 then
			--Shuffle deck if we summoned from deck
			local deck_summoned=sg:Filter(Card.IsLocation,nil,LOCATION_DECK)
			if deck_summoned:GetCount()>0 then
				Duel.ShuffleDeck(tp)
			end
		end
	end
end