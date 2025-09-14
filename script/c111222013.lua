-- Lumine Fusion
local s,id=GetID()
function s.initial_effect(c)
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

-- Fusion Recipes
s.fusion_recipes = {
	-- FusionMonster = {your_origin, opponent_element}
	[FusionMonsterFurinaID] = {"Fontaine","WATER"},
	[FusionMonsterKusanaliID] = {"Sumeru","LIGHT"},
	[FusionMonsterRaidenID] = {"Inazuma","DARK"},
	[FusionMonsterBarbatosID] = {"Mondstadt","WIND"},
	[FusionMonsterRexLapisID] = {"Liyue","EARTH"},
}

-- Check if materials are valid
function s.valid_materials(tp,fc)
	local mats1=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local mats2=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	for _,recipe in pairs(s.fusion_recipes) do
		for mc1 in aux.Next(mats1) do
			for mc2 in aux.Next(mats2) do
				if mc1.origin==recipe[1] and mc2.element==recipe[2] then
					return true
				end
			end
		end
	end
	return false
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_EXTRA,0,1,nil,TYPE_FUSION)
		and s.valid_materials(tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local fusion_candidates=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_EXTRA,0,nil,TYPE_FUSION)
	local mats1=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local mats2=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	local valid_fc=nil

	-- find a fusion monster that can be summoned
	for fc in aux.Next(fusion_candidates) do
		local recipe=s.fusion_recipes[fc:GetCode()]
		if recipe then
			for mc1 in aux.Next(mats1) do
				for mc2 in aux.Next(mats2) do
					if mc1.origin==recipe[1] and mc2.element==recipe[2] then
						valid_fc=fc
						goto found
					end
				end
			end
		end
	end
	::found::
	if not valid_fc then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local mat1=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	local mat2=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil):GetFirst()

	valid_fc:SetMaterial(Group.FromCards(mat1,mat2))
	Duel.SendtoGrave(Group.FromCards(mat1,mat2),REASON_MATERIAL+REASON_FUSION)
	Duel.SpecialSummon(valid_fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	valid_fc:CompleteProcedure()
end
