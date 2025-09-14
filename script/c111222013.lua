--Lumine Fusion
--Scripted by [Your Name]
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={0x700} --"Genshin" archetype code

--Filter for "Genshin" monsters on your field
function s.filter1(c,e)
	return c:IsSetCard(0x700) and c:IsOnField() and c:IsAbleToRemove() and not c:IsImmuneToEffect(e)
end

--Filter for opponent's monsters on field (will be treated as "Genshin")
function s.filter2(c,e)
	return c:IsOnField() and c:IsAbleToRemove() and not c:IsImmuneToEffect(e)
end

--Filter for "Genshin" Fusion monsters in Extra Deck
function s.spfilter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x700) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

--Check specific fusion requirements for each boss monster
function s.fusioncheck(fc,sg,tp)
	local g1=sg:Filter(Card.IsControler,nil,tp) --Your monsters
	local g2=sg:Filter(Card.IsControler,nil,1-tp) --Opponent's monsters
	
	if g1:GetCount()~=1 or g2:GetCount()~=1 then return false end
	if not g1:IsExists(Card.IsSetCard,1,nil,0x700) then return false end
	
	local code=fc:GetCode()
	local mymon=g1:GetFirst()
	local oppmon=g2:GetFirst()
	
	--Furina De Fontaine: My "Fontaine" monster + opponent monster with WATER attribute
	if code==12345001 then
		return mymon:IsSetCard(0x5700) and oppmon:IsAttribute(ATTRIBUTE_WATER)
	end
	
	--Lesser Lord Kusanali: My "Sumeru" monster + opponent monster with LIGHT attribute  
	if code==111222007 then
		return mymon:IsSetCard(0x4700) and oppmon:IsAttribute(ATTRIBUTE_LIGHT)
	end
	
	--Raiden Shogun: My "Inazuma" monster + opponent monster with DARK attribute
	if code==111222009 then
		return mymon:IsSetCard(0x3700) and oppmon:IsAttribute(ATTRIBUTE_DARK)
	end
	
	--Barbatos: My "Mondstadt" monster + opponent monster with WIND attribute
	if code==111222006 then
		return mymon:IsSetCard(0x1700) and oppmon:IsAttribute(ATTRIBUTE_WIND)
	end
	
	--Rex Lapis: My "Liyue" monster + opponent monster with EARTH attribute
	if code==111222008 then
		return mymon:IsSetCard(0x2700) and oppmon:IsAttribute(ATTRIBUTE_EARTH)
	end
	
	--Default check for any "Genshin" Fusion
	return true
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ownmg=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_MZONE,0,nil,e)
		local oppmg=Duel.GetMatchingGroup(s.filter2,tp,0,LOCATION_MZONE,nil,e)
		if #ownmg==0 or #oppmg==0 then return false end
		
		--Check if any valid fusion exists
		local exg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp,nil,nil,tp)
		for tc in aux.Next(exg) do
			--Check all combinations of my monsters + opponent monsters
			for mymon in aux.Next(ownmg) do
				for oppmon in aux.Next(oppmg) do
					local sg=Group.CreateGroup()
					sg:AddCard(mymon)
					sg:AddCard(oppmon)
					if s.fusioncheck(tc,sg,tp) then
						return true
					end
				end
			end
		end
		return false
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ownmg=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_MZONE,0,nil,e)
	local oppmg=Duel.GetMatchingGroup(s.filter2,tp,0,LOCATION_MZONE,nil,e)
	if #ownmg==0 or #oppmg==0 then return end
	
	local exg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp,nil,nil,tp)
	if #exg==0 then return end
	
	--Select fusion target
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=exg:Select(tp,1,1,nil):GetFirst()
	
	--Find valid material combinations for selected fusion monster
	local validcombos={}
	for mymon in aux.Next(ownmg) do
		for oppmon in aux.Next(oppmg) do
			local sg=Group.CreateGroup()
			sg:AddCard(mymon)
			sg:AddCard(oppmon)
			if s.fusioncheck(tc,sg,tp) then
				table.insert(validcombos,sg)
			end
		end
	end
	
	if #validcombos==0 then return end
	
	--Select materials
	local selected_group
	if #validcombos==1 then
		selected_group=validcombos[1]
	else
		--Let player choose materials manually
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local g1=ownmg:Select(tp,1,1,nil)
		local g2=oppmg:Select(tp,1,1,nil)
		selected_group=Group.CreateGroup()
		selected_group:Merge(g1)
		selected_group:Merge(g2)
		
		--Verify selection is valid
		if not s.fusioncheck(tc,selected_group,tp) then 
			return 
		end
	end
	
	--Perform fusion summon
	tc:SetMaterial(selected_group)
	Duel.Remove(selected_group,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
		tc:CompleteProcedure()
	end
end