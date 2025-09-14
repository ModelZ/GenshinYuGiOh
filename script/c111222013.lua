-- Lumine Fusion
-- Quick Spell
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon using your "Genshin" monster + opponent's monster
	local params={nil, Fusion.CheckWithHandler(s.fcheck), s.fextra, s.fusfilter, Fusion.ForcedHandler}
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(Fusion.SummonEffTG(table.unpack(params)))
	e1:SetOperation(Fusion.SummonEffOP(table.unpack(params)))
	c:RegisterEffect(e1)
end

-- Extra fusion material from opponent's monsters
function s.fextra(e,tp,mg)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	return g, s.fcheck  -- Return the extra material group and the checker function
end

-- Fusion check: must have at least 1 of your "Genshin" monsters
function s.fcheck(tp,sg,fc)
	if not sg then return false end
	return sg:FilterCount(function(c) return c:IsSetCard(0x700) and c:IsControler(tp) end, nil) >= 1
end

-- Fusion filter: enforce your recipe rules
function s.fusfilter(c,e,tp,mg,f,chkf)
	if not c:IsSetCard(0x700) or not c:IsType(TYPE_FUSION) or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) then return false end
	-- Check recipes
	local mats=c.material
	local has_my_genshin=false
	local has_oppo=false
	for _,mc in ipairs(mats) do
		if mc:IsControler(tp) and mc:IsSetCard(0x700) then has_my_genshin=true end
		if mc:IsControler(1-tp) then has_oppo=true end
	end
	return has_my_genshin and has_oppo
end
