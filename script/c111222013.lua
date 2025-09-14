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

s.listed_series={0x700} --Replace with actual "Genshin" archetype code

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
		and c:CheckFusionMaterial(m,nil,chkf)
end

--Check specific fusion requirements for each boss monster
function s.fusioncheck(fc,sg,tp)
	local g1=sg:Filter(Card.IsControler,nil,tp) --Your monsters
	local g2=sg:Filter(Card.IsControler,nil,1-tp) --Opponent's monsters
	
	if g1:GetCount()~=1 or g2:GetCount()~=1 then return false end
	if not g1:IsExists(Card.IsSetCard,1,nil,0x700) then return false end
	
	local tc=fc
	local code=tc:GetCode()
	
	--Furina De Fontaine: 1 "Fontaine" + 1 "Genshin" WATER
	if code==12345001 then --Replace with actual card code
		return (g1:IsExists(Card.IsSetCard,1,nil,0x5700) or g2:IsExists(Card.IsSetCard,1,nil,0x5700)) --Fontaine archetype
			and (g1:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_WATER) or g2:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_WATER))
	end
	
	--Lesser Lord Kusanali: 1 "Sumeru" + 1 "Genshin" LIGHT  
	if code==111222007 then --Replace with actual card code
		return (g1:IsExists(Card.IsSetCard,1,nil,0x4700) or g2:IsExists(Card.IsSetCard,1,nil,0x4700)) --Sumeru archetype
			and (g1:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_LIGHT) or g2:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_LIGHT))
	end
	
	--Raiden Shogun: 1 "Inazuma" + 1 "Genshin" DARK
	if code==111222009 then --Replace with actual card code
		return (g1:IsExists(Card.IsSetCard,1,nil,0x3700) or g2:IsExists(Card.IsSetCard,1,nil,0x3700)) --Inazuma archetype
			and (g1:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_DARK) or g2:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_DARK))
	end
	
	--Barbatos: 1 "Mondstadt" + 1 "Genshin" WIND
	if code==111222006 then --Replace with actual card code
		return (g1:IsExists(Card.IsSetCard,1,nil,0x1700) or g2:IsExists(Card.IsSetCard,1,nil,0x1700)) --Mondstadt archetype
			and (g1:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_WIND) or g2:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_WIND))
	end
	
	--Rex Lapis: 1 "Liyue" + 1 "Genshin" EARTH
	if code==111222008 then --Replace with actual card code
		return (g1:IsExists(Card.IsSetCard,1,nil,0x2700) or g2:IsExists(Card.IsSetCard,1,nil,0x2700)) --Liyue archetype
			and (g1:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_EARTH) or g2:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_EARTH))
	end
	
	--Default check for any "Genshin" Fusion
	return true
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local ownmg=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_MZONE,0,nil,e)
		local oppmg=Duel.GetMatchingGroup(s.filter2,tp,0,LOCATION_MZONE,nil,e)
		if #ownmg==0 or #oppmg==0 then return false end
		
		--Create combined material group
		local mg=Group.CreateGroup()
		mg:Merge(ownmg)
		mg:Merge(oppmg)
		
		--Check if any valid fusion target exists
		local exg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,nil,chkf)
		for tc in aux.Next(exg) do
			local fmat=mg:Filter(Card.CheckFusionMaterial,nil,tc,nil,chkf)
			if fmat:GetCount()>=2 then
				local res=false
				for i=1,fmat:GetCount()-1 do
					local sg=fmat:Select(tp,2,2,nil,0)
					if sg and s.fusioncheck(tc,sg,tp) then
						res=true
						break
					end
				end
				if res then return true end
			end
		end
		return false
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local ownmg=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_MZONE,0,nil,e)
	local oppmg=Duel.GetMatchingGroup(s.filter2,tp,0,LOCATION_MZONE,nil,e)
	if #ownmg==0 or #oppmg==0 then return end
	
	local mg=Group.CreateGroup()
	mg:Merge(ownmg)
	mg:Merge(oppmg)
	
	local exg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,nil,chkf)
	if #exg==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=exg:Select(tp,1,1,nil):GetFirst()
	
	--Select materials with specific requirements
	local fmat=mg:Filter(Card.CheckFusionMaterial,nil,tc,nil,chkf)
	local validgroups={}
	
	--Find all valid 2-card combinations
	for i=1,fmat:GetCount()-1 do
		for j=i+1,fmat:GetCount() do
			local sg=Group.CreateGroup()
			sg:AddCard(fmat:GetCardByIndex(i-1))
			sg:AddCard(fmat:GetCardByIndex(j-1))
			if s.fusioncheck(tc,sg,tp) then
				table.insert(validgroups,sg)
			end
		end
	end
	
	if #validgroups==0 then return end
	
	--Let player choose from valid combinations
	local selected_group
	if #validgroups==1 then
		selected_group=validgroups[1]
	else
		--Manual selection if multiple valid combinations
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local g1=ownmg:Select(tp,1,1,nil)
		local g2=oppmg:Select(tp,1,1,nil)
		selected_group=Group.CreateGroup()
		selected_group:Merge(g1)
		selected_group:Merge(g2)
		if not s.fusioncheck(tc,selected_group,tp) then return end
	end
	
	--Perform fusion summon
	tc:SetMaterial(selected_group)
	Duel.Remove(selected_group,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
		tc:CompleteProcedure()
	end
end