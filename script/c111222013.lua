--Lumine Fusion
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon using 1 "Genshin" you control + 1 opponent's monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)
end
s.listed_series={0x700}

--Fusion Summon filter
function s.fusfilter(c,e,tp,mg,chkf)
	return c:IsSetCard(0x700) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,chkf)
end

--Target
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		-- Must pick exactly 1 Genshin monster you control + 1 opponent monster
		local mg1=Duel.GetMatchingGroup(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,0x700)
		local mg2=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
		if #mg1<1 or #mg2<1 then return false end
		local mg=mg1:Clone()
		mg:Merge(mg2)
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--Operation
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg1=Duel.GetMatchingGroup(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,0x700)
	local mg2=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
	if #mg1<1 or #mg2<1 then return end
	local mg=mg1:Clone()
	mg:Merge(mg2)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg,chkf)
	local tc=sg:GetFirst()
	if not tc then return end

	-- Must pick exactly 1 of each
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local g1=mg1:Select(tp,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local g2=mg2:Select(tp,1,1,nil)
	g1:Merge(g2)

	tc:SetMaterial(g1)
	Duel.SendtoGrave(g1,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end
