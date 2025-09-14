--Lumine Fusion
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon 1 "Genshin" Fusion Monster
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

-- Opponent’s monsters are treated as "Genshin" monsters (for elemental slot)
function s.fcheck(tp,sg,fc)
	-- must contain exactly 1 monster you control + 1 monster opponent controls
	return sg:IsExists(Card.IsControler,1,nil,tp)
	   and sg:IsExists(Card.IsControler,1,nil,1-tp)
end

-- Extra material pool = opponent’s face-up monsters
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil),s.fcheck
end

-- Allowed Fusion Monsters
-- Furina: Fontaine + WATER
-- Kusanali: Sumeru + LIGHT
-- Raiden Shogun: Inazuma + DARK
-- Barbatos: Mondstadt + WIND
-- Rex Lapis: Liyue + EARTH
function s.matfilter(c)
	return c:IsSetCard(0x700) -- all are "Genshin"
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_EXTRA,0,1,nil,TYPE_FUSION)
			and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg1=Duel.GetFusionMaterial(tp)
	-- add opponent’s face-up monsters as possible extra materials
	local mg2=s.fextra(e,tp,mg1)
	mg1:Merge(mg2)
	local sg=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_EXTRA,0,nil,TYPE_FUSION)
	if #sg==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=sg:Select(tp,1,1,nil):GetFirst()
	if not tc then return end
	local mat1=Duel.SelectFusionMaterial(tp,tc,mg1,nil,tp)
	if not mat1 then return end
	tc:SetMaterial(mat1)
	Duel.SendtoGrave(mat1,REASON_MATERIAL+REASON_FUSION)
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end
